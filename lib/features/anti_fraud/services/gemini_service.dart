import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'dart:typed_data';

class GeminiService {
  // Replace with actual API key, or keep it parameterized.
  // In a real app, this should be fetched securely, not hardcoded.
  static const String _apiKey = 'AIzaSyDM31C6vuVj9kEeHxmWXVfaytjpXtm_-7g';
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );
  }

  /// Fetches live news articles using NewsAPI.ai / Event Registry API
  Future<List<Map<String, dynamic>>> fetchNewsFromApi(String appName) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      
      final String encodedName = Uri.encodeComponent(appName);
      final url = 'https://eventregistry.org/api/v1/article/getArticles'
          '?action=getArticles'
          '&keyword=$encodedName'
          '&apiKey=3419a8cb-0571-4d15-b2e0-fb24e76db7e8'
          '&articlesCount=10'
          '&articlesSortBy=date'
          '&lang=eng';

      final response = await dio.get(url);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map) {
          final results = data['articles']?['results'] as List?;
          if (results != null) {
            return results.map((item) {
              final map = Map<String, dynamic>.from(item as Map);
              return {
                'title': map['title']?.toString() ?? '',
                'body': map['body']?.toString() ?? '',
                'date': map['date']?.toString() ?? '',
                'url': map['url']?.toString() ?? '',
                'source': map['source']?['title']?.toString() ?? '',
              };
            }).toList();
          }
        }
      }
    } catch (e) {
      // Return empty list on network or API failure
      print('Error fetching news from Event Registry: $e');
    }
    return [];
  }

  /// Performs an offline heuristic check for scam keywords and URL patterns
  Map<String, dynamic>? checkLocalHeuristics(String messageBody, String sender) {
    final text = messageBody.toLowerCase();
    
    // 1. Phishing keywords lists
    final urgencyKeywords = ['urgent', 'immediately', 'act now', 'expires', 'limited time', 'suspicious login', 'verify your account', 'locked', 'suspended'];
    final financialKeywords = ['claim', 'lottery', 'prize', 'inheritance', 'win', 'bank details', 'crypto', 'upi', 'pay to', 'reward', 'refund', 'invoice'];
    final callToActionKeywords = ['click here', 'verify your identity', 'login to', 'update your password', 'reset password', 'link below'];
    
    int urgencyMatches = urgencyKeywords.where((k) => text.contains(k)).length;
    int financialMatches = financialKeywords.where((k) => text.contains(k)).length;
    int callToActionMatches = callToActionKeywords.where((k) => text.contains(k)).length;

    // 2. URL detection
    final urlRegex = RegExp(r'https?://[^\s]+');
    final hasUrl = urlRegex.hasMatch(text);
    
    // Check for suspicious URL patterns (e.g., http instead of https, numeric IP addresses, or subdomains trying to look official)
    bool hasSuspiciousUrl = false;
    if (hasUrl) {
      final matches = urlRegex.allMatches(text);
      for (final match in matches) {
        final url = match.group(0) ?? '';
        if (url.startsWith('http://')) {
          hasSuspiciousUrl = true;
        }
        // Check for numeric IP addresses in host
        if (RegExp(r'https?://\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}').hasMatch(url)) {
          hasSuspiciousUrl = true;
        }
      }
    }

    // Heuristics Score calculation
    int score = 0;
    List<String> triggers = [];
    
    if (urgencyMatches > 0) {
      score += 25;
      triggers.add('Urgency context');
    }
    if (financialMatches > 0) {
      score += 25;
      triggers.add('Financial offer');
    }
    if (callToActionMatches > 0) {
      score += 30;
      triggers.add('Verification link requested');
    }
    if (hasSuspiciousUrl) {
      score += 40;
      triggers.add('Suspicious unencrypted URL');
    } else if (hasUrl) {
      score += 15;
      triggers.add('Web link');
    }

    if (score >= 50) {
      return {
        'score': score > 100 ? 100 : score,
        'isPhishing': score >= 60,
        'explanation': 'Offline Scan: Flagged suspicious indicators (${triggers.join(", ")}). Treat with caution.',
        'offline': true,
      };
    }
    
    return null;
  }

  /// Analyzes an SMS message for phishing and returns a map with 'score' and 'explanation'
  Future<Map<String, dynamic>> analyzeSms(String messageBody, String sender) async {
    // 1. Run local heuristics first
    final localResult = checkLocalHeuristics(messageBody, sender);
    
    // Only return local heuristics result early if API key is not configured
    final bool hasApiKey = _apiKey != 'YOUR_GEMINI_API_KEY' && _apiKey.isNotEmpty;
    if (!hasApiKey && localResult != null && localResult['score'] >= 70) {
      return localResult;
    }

    // 2. Call Gemini API if configured
    try {
      if (!hasApiKey) {
        // Fall back to local check if API key is not configured
        return localResult ?? {
          'score': 20,
          'explanation': 'Offline Scan: API key not configured. Minimal keywords detected. Proceed with caution.',
          'isPhishing': false,
          'offline': true,
        };
      }

      final prompt = '''
You are a cybersecurity expert analyzing an SMS for phishing, fraud, or spam.
Sender: $sender
Message: $messageBody

PRACTICAL JUDGMENT GUIDELINES:
1. TRANSACTIONAL MESSAGES & OTPs: Standard OTPs (One-Time Passwords), login verification codes, bank transactions (debits/credits/ATM alerts), package delivery notifications (from Amazon, DHL, FedEx, USPS, etc.), and billing statements are extremely common and safe. Unless they contain suspicious unofficial/phishing links, request sensitive details, or urge suspicious immediate actions, they MUST be classified as safe with a score between 0 and 15.
2. SUSPICIOUS INDICATORS: Assign a high risk score (>60) only for clear phishing or scam attempts, such as:
   - Requesting sensitive info (PIN, password, CVV, OTP).
   - Deceptive lookalike domains or suspicious links (e.g., 'http://secure-login-bank.xyz').
   - High-urgency threats ('Your account will be suspended/closed in 24 hours if you don't click here').
   - Unsolicited lottery wins, crypto investment schemes, or job offers.
   - Senders impersonating official brands using lookalike names or unofficial numbers.

Analyze the message and return ONLY a valid JSON object with the following structure, nothing else:
{
  "score": (a number from 0 to 100, where 0-20 is safe/clean, 21-59 is suspicious/low risk, and 60-100 is highly dangerous/phishing),
  "isPhishing": (boolean true if score > 60, else false),
  "explanation": "(A practical 2-sentence explanation of why the message is safe or what specific scam indicators/psychological tricks were detected)"
}
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      String responseText = response.text ?? '{}';
      
      // Clean up markdown formatting if Gemini returns it
      responseText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      
      final result = jsonDecode(responseText);
      return result;
    } catch (e) {
      // Fallback to local heuristics on network error
      return localResult ?? {
        'score': 30,
        'explanation': 'Offline Scan (Network Error): Unable to contact server. No major triggers identified.',
        'isPhishing': false,
        'offline': true,
      };
    }
  }

  /// Analyzes a raw EML content for email phishing, domain spoofing, and header verification
  Future<Map<String, dynamic>> analyzeEml(String emlContent) async {
    try {
      if (_apiKey == 'YOUR_GEMINI_API_KEY' || _apiKey.isEmpty) {
        return {
          'score': 0,
          'explanation': 'Gemini API Key is not configured. Cannot perform EML analysis.',
          'isPhishing': false,
          'subject': 'Unknown',
          'from': 'Unknown',
          'to': 'Unknown',
          'date': 'Unknown',
          'spf': 'UNKNOWN',
          'dkim': 'UNKNOWN',
          'dmarc': 'UNKNOWN',
          'suspiciousLinks': [],
          'suspiciousAttachments': [],
        };
      }

      final prompt = '''
You are an expert email security auditor. Analyze the following raw EML file content (containing SMTP headers and message bodies) for phishing, spoofing, and malware indicators.

EML CONTENT:
$emlContent

Analyze the headers (look closely at Authentication-Results, SPF, DKIM, Received chains, Return-Path vs From alignments) and the body (look at links and text context).
Return ONLY a valid JSON object matching the following structure, nothing else:
{
  "score": (number from 0 to 100, where 100 is highly malicious),
  "isPhishing": (boolean true if score > 60, else false),
  "subject": "(extracted subject or 'No Subject')",
  "from": "(extracted sender email address)",
  "to": "(extracted recipient email address)",
  "date": "(extracted date)",
  "spf": "(PASS / FAIL / SOFTFAIL / NONE / UNKNOWN)",
  "dkim": "(PASS / FAIL / NONE / UNKNOWN)",
  "dmarc": "(PASS / FAIL / NONE / UNKNOWN)",
  "explanation": "(A concise 2-sentence summary of your security assessment)",
  "suspiciousLinks": [
    {"url": "url_here", "reason": "reason_here (e.g. Unofficial domain, HTTP link)"}
  ],
  "suspiciousAttachments": [
    {"name": "name_here", "reason": "reason_here (e.g. Executable extension, hidden file)"}
  ]
}
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      String responseText = response.text ?? '{}';
      responseText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      
      final result = jsonDecode(responseText);
      return result;
    } catch (e) {
      return {
        'score': 0,
        'explanation': 'Error conducting EML audit: $e',
        'isPhishing': false,
        'subject': 'Unknown',
        'from': 'Unknown',
        'to': 'Unknown',
        'date': 'Unknown',
        'spf': 'UNKNOWN',
        'dkim': 'UNKNOWN',
        'dmarc': 'UNKNOWN',
        'suspiciousLinks': [],
        'suspiciousAttachments': [],
      };
    }
  }

  /// Analyzes a URL for phishing, malware, and threat indicators using Gemini AI
  Future<Map<String, dynamic>> analyzeUrl(String url) async {
    // Quick offline heuristics first
    final heuristicFlags = <String>[];
    try {
      final uri = Uri.parse(url);
      if (uri.scheme == 'http') heuristicFlags.add('Unencrypted HTTP connection');
      if (RegExp(r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}').hasMatch(uri.host)) {
        heuristicFlags.add('IP address used instead of domain name');
      }
      final suspiciousTlds = ['.xyz', '.ru', '.tk', '.ml', '.ga', '.cf', '.gq', '.top'];
      if (suspiciousTlds.any((tld) => uri.host.endsWith(tld))) {
        heuristicFlags.add('High-risk top-level domain (${uri.host.split('.').last})');
      }
      // Lookalike brand detection
      final brands = ['paypal', 'apple', 'google', 'microsoft', 'amazon', 'netflix', 'facebook', 'instagram', 'bank', 'secure'];
      for (final brand in brands) {
        if (uri.host.contains(brand) && !uri.host.endsWith('$brand.com') && !uri.host.endsWith('$brand.co.uk')) {
          heuristicFlags.add('Possible brand impersonation: "$brand" in domain');
          break;
        }
      }
      final suspiciousParams = ['login', 'verify', 'account', 'password', 'token', 'confirm', 'secure'];
      final queryString = uri.query.toLowerCase();
      for (final param in suspiciousParams) {
        if (queryString.contains(param)) {
          heuristicFlags.add('Sensitive query parameter: "$param"');
          break;
        }
      }
    } catch (_) {
      heuristicFlags.add('Malformed or unparseable URL');
    }

    try {
      final prompt = '''
You are a cybersecurity threat intelligence expert analyzing a URL for potential threats.

URL TO ANALYZE: $url

Perform a thorough security analysis covering:
1. Domain reputation and age signals (typosquatting, lookalike domains, brand impersonation)
2. Protocol and connection security (HTTP vs HTTPS, mixed content)
3. URL structure red flags (excessive subdomains, deceptive paths, encoded characters)
4. Query parameters that suggest credential harvesting or tracking
5. Known phishing kit patterns and malware delivery paths
6. Any redirect warnings based on URL structure

Return ONLY a valid JSON object with the following structure, nothing else:
{
  "score": (number 0-100, where 100 = highly dangerous),
  "isPhishing": (boolean, true if score > 60),
  "verdict": "(Safe / Suspicious / Dangerous)",
  "explanation": "(2-3 sentence summary of the threat assessment)",
  "domainInfo": {
    "protocol": "(http or https)",
    "host": "(the domain/host)",
    "path": "(the URL path)",
    "hasSuspiciousTld": (boolean),
    "isIpAddress": (boolean)
  },
  "riskFactors": [
    {"label": "(short factor title)", "description": "(why this is risky)", "severity": "(low/medium/high)"}
  ],
  "redirectWarning": "(null or a string warning about likely redirect chains based on URL structure)",
  "recommendation": "(One clear action the user should take)"
}
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      String responseText = response.text ?? '{}';
      responseText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();

      final result = Map<String, dynamic>.from(jsonDecode(responseText));

      // Merge offline heuristic flags into riskFactors if present
      if (heuristicFlags.isNotEmpty) {
        final existing = List<Map<String, dynamic>>.from(result['riskFactors'] ?? []);
        for (final flag in heuristicFlags) {
          if (!existing.any((f) => f['label'].toString().toLowerCase().contains(flag.toLowerCase().substring(0, 5)))) {
            existing.insert(0, {'label': 'Heuristic Flag', 'description': flag, 'severity': 'medium'});
          }
        }
        result['riskFactors'] = existing;
      }

      return result;
    } catch (e) {
      // Fallback to heuristic-only result
      return {
        'score': heuristicFlags.isNotEmpty ? 45 : 10,
        'isPhishing': false,
        'verdict': heuristicFlags.isNotEmpty ? 'Suspicious' : 'Safe',
        'explanation': heuristicFlags.isNotEmpty
            ? 'Offline scan detected ${heuristicFlags.length} risk indicator(s). AI scan unavailable: $e'
            : 'Offline scan found no major indicators. AI analysis unavailable.',
        'domainInfo': {'protocol': url.startsWith('https') ? 'https' : 'http', 'host': url, 'path': '', 'hasSuspiciousTld': false, 'isIpAddress': false},
        'riskFactors': heuristicFlags.map((f) => {'label': 'Heuristic Flag', 'description': f, 'severity': 'medium'}).toList(),
        'redirectWarning': null,
        'recommendation': 'Proceed with caution. Verify the URL source before clicking.',
      };
    }
  }

  /// Analyzes extracted APK metadata for potential threats using Gemini AI
  Future<Map<String, dynamic>> analyzeApk(Map<String, dynamic> apkMetadata) async {
    try {
      final prompt = '''
You are a mobile security expert performing static analysis on an Android APK file.

APK METADATA EXTRACTED:
${jsonEncode(apkMetadata)}

PRACTICAL JUDGMENT GUIDELINES:
1. SYSTEM AND REPUTABLE APPS: Apps with package names starting with 'com.google.', 'com.android.', 'com.sec.', 'com.samsung.', 'com.xiaomi.', 'com.huawei.', or well-known commercial apps like 'com.whatsapp', 'com.facebook.', 'com.instagram.', 'com.spotify.', 'org.mozilla.', etc., are highly reputable system or official apps. Unless they have a debug certificate or are clearly tampered with, they MUST be classified as "Clean" with a score between 0 and 15.
2. PERMISSION CONTEXT: Evaluate permissions based on the app's purpose and name. It is practical and expected for a messaging app (e.g., WhatsApp) to request SMS, contacts, and microphone; for a camera app to request camera; and for a maps/navigation app to request location. Do NOT flag standard permissions for their appropriate app types. Only flag permissions as "high" or "critical" risk if they are completely unrelated and unnecessary for the app's function (e.g., a simple calculator or flashlight app requesting SMS, contacts, or background location).
3. MODERN APP STANDARDS: Do not treat standard optimization practices as malicious. Multiple DEX files, code obfuscation, and standard native libraries are standard for almost all modern Android applications to optimize and protect intellectual property. Only flag obfuscation as suspicious if combined with other high-risk signals in a non-commercial, unknown app.
4. SIGNING CERTIFICATES: Debug certificates (e.g. debug.keystore) in user-installed apps from third-party sources can be suspicious, but for system apps, they are typically properly signed.

Return ONLY a valid JSON object with this structure, nothing else:
{
  "score": (a number 0-100. 0-20 for clean, 21-59 for suspicious/low risk, 60-100 only for clearly dangerous/malicious threats),
  "verdict": "(Clean / Suspicious / Dangerous / Malicious)",
  "ismalicious": (boolean, true if score > 60),
  "explanation": "(A practical 2-sentence threat summary justifying the score. E.g. 'This is an official Google system application and is completely safe.' or 'This app requests sensitive SMS and Contacts permissions which are unnecessary for a utility app.')",
  "threatCategory": "(Clean / Spyware / Adware / Trojan / Ransomware / PUA)",
  "riskFlags": [
    {"flag": "(short title)", "detail": "(explanation)", "severity": "(low/medium/high/critical)"}
  ],
  "suspiciousPermissions": ["list of the most dangerous permissions found that do not match the app's purpose"],
  "positiveIndicators": ["reasons for safety, e.g. 'Official package from Google/Samsung', 'Appropriate permissions for app category'"],
  "recommendation": "(One clear practical recommendation for the user)"
}
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      String responseText = response.text ?? '{}';
      responseText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      return Map<String, dynamic>.from(jsonDecode(responseText));
    } catch (e) {
      return {
        'score': 0,
        'verdict': 'Unknown',
        'ismalicious': false,
        'explanation': 'AI analysis failed: $e. Review extracted metadata manually.',
        'threatCategory': 'Unknown',
        'riskFlags': [],
        'suspiciousPermissions': [],
        'positiveIndicators': [],
        'recommendation': 'Unable to assess. Exercise caution.',
      };
    }
  }

  /// Audits an app's security reputation, breach history, and recent updates using live NewsAPI.ai and Gemini AI
  Future<Map<String, dynamic>> auditAppReputation(String appName, {String? packageName}) async {
    // 1. Fetch live news articles first
    final List<Map<String, dynamic>> articles = await fetchNewsFromApi(appName);
    final String articlesJson = jsonEncode(articles);

    try {
      final prompt = '''
You are a global cybersecurity threat intelligence analyst.
Analyze the security reputation, breach history, recent updates, privacy considerations, and latest news of the following application:
App Name: $appName
${packageName != null ? 'Package Name: $packageName' : ''}

LIVE NEWS ARTICLES FOUND:
$articlesJson

Provide a detailed security reputation report.
- If LIVE NEWS ARTICLES FOUND is not empty, prioritize analyzing these real news articles to extract actual updates, news, and safety/security/privacy cautions.
- If LIVE NEWS ARTICLES FOUND is empty, rely on your cybersecurity knowledge to provide the latest general updates, news, and privacy cautions for this application.

CRITICAL INSTRUCTIONS:
- Do NOT classify the app as "Safe" or "Unsafe". Do NOT provide any verdict or threat classifications.
- Do NOT output any threat score, security score, or risk levels.
- Focus purely on presenting neutral latest news/updates, security/privacy cautions, and recommendations.
- Avoid generic "no news" messages. If there is no negative news, provide recent updates, official version news, or standard security advisory tips for the application.

Return ONLY a valid JSON object matching the following structure, nothing else:
{
  "explanation": "(A practical 2-sentence summary of the app's recent news, security updates, and general privacy cautions)",
  "newsAndCautions": [
    {
      "title": "(A short descriptive title, e.g., 'Recent Version Update', 'Data Sharing Caution', or '2024 Server Breach')",
      "date": "(Approximate date/year or 'Recent')",
      "description": "(1-2 sentence description of the news event or caution details)",
      "isCaution": (boolean, true if it is a security/privacy caution/warning, false if it is standard news or general update)
    }
  ],
  "privacyCautions": [
    "(List of specific data privacy cautions, e.g., 'Collects usage data for service optimization', 'Requests camera permission for scanning')"
  ],
  "recommendation": "(One clear, practical advisory recommendation for using this app responsibly. Do not use words like 'safe' or 'unsafe' to rate the app.)"
}
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      String responseText = response.text ?? '{}';
      responseText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      return Map<String, dynamic>.from(jsonDecode(responseText));
    } catch (e) {
      return {
        'explanation': 'AI reputation audit failed: $e. Verify app reputation manually.',
        'newsAndCautions': [
          {
            'title': 'Audit Interrupted',
            'date': 'Recent',
            'description': 'Could not verify latest news via AI analysis.',
            'isCaution': true
          }
        ],
        'privacyCautions': [
          'Unable to verify privacy track record'
        ],
        'recommendation': 'Exercise caution when installing third-party applications.'
      };
    }
  }

  /// Fetches global cybersecurity fraud and brand-specific device security news
  Future<List<Map<String, dynamic>>> fetchFraudAndDeviceNews({String? deviceBrand}) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      
      String keywordQuery = 'mobile security';
      if (deviceBrand != null && deviceBrand != 'Android' && deviceBrand.isNotEmpty) {
        keywordQuery = '$deviceBrand security';
      }
      
      final url = 'https://eventregistry.org/api/v1/article/getArticles'
          '?action=getArticles'
          '&keyword=${Uri.encodeComponent(keywordQuery)}'
          '&apiKey=3419a8cb-0571-4d15-b2e0-fb24e76db7e8'
          '&articlesCount=20'
          '&articlesSortBy=date'
          '&lang=eng';

      final response = await dio.get(url);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map) {
          final results = data['articles']?['results'] as List?;
          if (results != null) {
            return results.map((item) {
              final map = Map<String, dynamic>.from(item as Map);
              return {
                'title': map['title']?.toString() ?? '',
                'body': map['body']?.toString() ?? '',
                'date': map['date']?.toString() ?? '',
                'url': map['url']?.toString() ?? '',
                'source': map['source']?['title']?.toString() ?? '',
              };
            }).toList();
          }
        }
      }
    } catch (e) {
      print('Error fetching general fraud news: $e');
    }
    return [];
  }

  /// Explains a security news article and provides safety steps using Gemini AI
  Future<Map<String, dynamic>> explainSecurityArticle(String title, String body) async {
    try {
      final prompt = '''
You are a cybersecurity educator.
Explain the following security/fraud news article to a non-technical user.

Article Title: $title
Article Snippet: $body

Provide a practical cybersecurity breakdown.
Do NOT output any scores or safe/unsafe rating verdicts.
Focus entirely on explaining the threat and advising the user on how to protect themselves.

Return ONLY a valid JSON object matching the following structure, nothing else:
{
  "threatExplanation": "(A clear 2-sentence explanation of what the security threat or fraud scheme is in simple terms)",
  "userImpact": "(1 sentence on how this could affect the user's daily mobile device usage)",
  "safetySteps": [
    "(List of 2-3 specific, actionable steps the user should take to protect themselves against this threat)"
  ]
}
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      String responseText = response.text ?? '{}';
      responseText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      return Map<String, dynamic>.from(jsonDecode(responseText));
    } catch (e) {
      return {
        'threatExplanation': 'Could not analyze article details via AI.',
        'userImpact': 'Possible mobile security concerns.',
        'safetySteps': [
          'Be cautious of unsolicited messages or links.',
          'Keep your device and apps updated to the latest version.'
        ]
      };
    }
  }

  /// Analyzes a screenshot of an SMS message for phishing and extracts contents
  Future<Map<String, dynamic>> analyzeSmsScreenshot(Uint8List imageBytes, String mimeType) async {
    try {
      if (_apiKey == 'YOUR_GEMINI_API_KEY' || _apiKey.isEmpty) {
        return {
          'score': 0,
          'explanation': 'Gemini API Key is not configured. Cannot perform SMS screenshot analysis.',
          'isPhishing': false,
          'extractedSender': 'Unknown',
          'extractedMessage': '',
        };
      }

      final prompt = '''
You are a cybersecurity expert analyzing a screenshot of an SMS message for phishing, fraud, or spam.
Identify the sender and the message text from the screenshot.

VALIDATION REQUIREMENT:
You must determine if the image is a screenshot of an SMS message, chat conversation, or text message bubble.
If the image does NOT show a valid SMS message or text conversation, you MUST set "isValidImage" to false.

PRACTICAL JUDGMENT GUIDELINES:
1. TRANSACTIONAL MESSAGES & OTPs: Standard OTPs (One-Time Passwords), login verification codes, bank transactions (debits/credits/ATM alerts), package delivery notifications (from Amazon, DHL, FedEx, USPS, etc.), and billing statements are extremely common and safe. Unless they contain suspicious unofficial/phishing links, request sensitive details, or urge suspicious immediate actions, they MUST be classified as safe with a score between 0 and 15.
2. SUSPICIOUS INDICATORS: Assign a high risk score (>60) only for clear phishing or scam attempts, such as:
   - Requesting sensitive info (PIN, password, CVV, OTP).
   - Deceptive lookalike domains or suspicious links (e.g., 'http://secure-login-bank.xyz').
   - High-urgency threats ('Your account will be suspended/closed in 24 hours if you don't click here').
   - Unsolicited lottery wins, crypto investment schemes, or job offers.
   - Senders impersonating official brands using lookalike names or unofficial numbers.

Analyze the screenshot and return ONLY a valid JSON object with the following structure, nothing else:
{
  "isValidImage": (boolean true if the image is a screenshot of an SMS/text message or conversation, false otherwise),
  "score": (a number from 0 to 100, where 0-20 is safe/clean, 21-59 is suspicious/low risk, and 60-100 is highly dangerous/phishing. Set to 0 if isValidImage is false),
  "isPhishing": (boolean true if score > 60, else false),
  "extractedSender": "(the extracted sender name or number, or 'Unknown' if not visible or if isValidImage is false)",
  "extractedMessage": "(the exact text of the SMS message extracted from the image, or empty if isValidImage is false)",
  "explanation": "(A practical 2-sentence explanation of why the message is safe or what specific scam indicators/psychological tricks were detected. If isValidImage is false, explain that the uploaded image does not appear to be a valid SMS screenshot and ask the user to upload a valid one)"
}
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, imageBytes),
        ])
      ];
      final response = await _model.generateContent(content);
      
      String responseText = response.text ?? '{}';
      responseText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      
      final result = jsonDecode(responseText);
      return result;
    } catch (e) {
      return {
        'score': 0,
        'explanation': 'AI analysis failed: $e. Make sure you selected a clear image of an SMS message.',
        'isPhishing': false,
        'extractedSender': 'Unknown',
        'extractedMessage': '',
      };
    }
  }

  /// Analyzes a screenshot of an Email for phishing and extracts contents
  Future<Map<String, dynamic>> analyzeEmlScreenshot(Uint8List imageBytes, String mimeType) async {
    try {
      if (_apiKey == 'YOUR_GEMINI_API_KEY' || _apiKey.isEmpty) {
        return {
          'score': 0,
          'explanation': 'Gemini API Key is not configured. Cannot perform Email screenshot analysis.',
          'isPhishing': false,
          'subject': 'Unknown',
          'from': 'Unknown',
          'to': 'Unknown',
          'date': 'Unknown',
          'spf': 'NOT_APPLICABLE',
          'dkim': 'NOT_APPLICABLE',
          'dmarc': 'NOT_APPLICABLE',
          'suspiciousLinks': [],
          'suspiciousAttachments': [],
        };
      }

      final prompt = '''
You are an expert email security auditor. Analyze the following screenshot of an email for phishing, spoofing, and malware indicators.
Extract the visible subject, from, to, date, and body content, then check for phishing cues.

VALIDATION REQUIREMENT:
You must determine if the image is a screenshot of an email client, an email message, inbox view, or mail composer.
If the image does NOT show a valid email, you MUST set "isValidImage" to false.

Analyze the visual information (look closely at details like the sender's display name vs actual email if visible, grammatical errors, high-urgency language, or suspicious links shown in the text).
Return ONLY a valid JSON object matching the following structure, nothing else:
{
  "isValidImage": (boolean true if the image is a screenshot of an email, false otherwise),
  "score": (number from 0 to 100, where 100 is highly malicious. Set to 0 if isValidImage is false),
  "isPhishing": (boolean true if score > 60, else false),
  "subject": "(extracted subject or 'No Subject')",
  "from": "(extracted sender email address or name)",
  "to": "(extracted recipient email address or 'Unknown')",
  "date": "(extracted date/time or 'Unknown')",
  "spf": "NOT_APPLICABLE",
  "dkim": "NOT_APPLICABLE",
  "dmarc": "NOT_APPLICABLE",
  "explanation": "(A concise 2-sentence summary of your security assessment of the screenshot. If isValidImage is false, explain that the uploaded image does not appear to be a valid email screenshot and ask the user to upload a valid one)",
  "suspiciousLinks": [
    {"url": "url_here", "reason": "reason_here (e.g. Unofficial domain, HTTP link)"}
  ],
  "suspiciousAttachments": [
    {"name": "name_here", "reason": "reason_here (e.g. Executable file icon shown, suspicious file extension)"}
  ]
}
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, imageBytes),
        ])
      ];
      final response = await _model.generateContent(content);
      
      String responseText = response.text ?? '{}';
      responseText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      
      final result = jsonDecode(responseText);
      return result;
    } catch (e) {
      return {
        'score': 0,
        'explanation': 'AI analysis failed: $e. Make sure you selected a clear image of an email.',
        'isPhishing': false,
        'subject': 'Unknown',
        'from': 'Unknown',
        'to': 'Unknown',
        'date': 'Unknown',
        'spf': 'NOT_APPLICABLE',
        'dkim': 'NOT_APPLICABLE',
        'dmarc': 'NOT_APPLICABLE',
        'suspiciousLinks': [],
        'suspiciousAttachments': [],
      };
    }
  }

  /// Generates a personalized cybersecurity status briefing based on user device metrics
  Future<Map<String, dynamic>> generateSentinelBriefing({
    required String deviceBrand,
    required int auditedAppsCount,
    required int totalAppsCount,
    required int suspiciousAppsCount,
    required int smsScanCount,
    required int emailScanCount,
    required int linkScanCount,
    required List<String> communityThreats,
  }) async {
    // Build task completion statuses
    final List<Map<String, dynamic>> fallbackTaskStatuses = [
      {
        'task': 'App Reputation Audits',
        'status': auditedAppsCount > 0 ? 'COMPLETED' : 'PENDING',
        'detail': '$auditedAppsCount of $totalAppsCount apps audited',
      },
      {
        'task': 'SMS Phishing Scan',
        'status': smsScanCount > 0 ? 'COMPLETED' : 'PENDING',
        'detail': smsScanCount > 0 ? '$smsScanCount scan(s) completed' : 'No SMS scans run yet',
      },
      {
        'task': 'Email Security Scan',
        'status': emailScanCount > 0 ? 'COMPLETED' : 'PENDING',
        'detail': emailScanCount > 0 ? '$emailScanCount scan(s) completed' : 'No email scans run yet',
      },
      {
        'task': 'Link / URL Verification',
        'status': linkScanCount > 0 ? 'COMPLETED' : 'PENDING',
        'detail': linkScanCount > 0 ? '$linkScanCount link(s) verified' : 'No links verified yet',
      },
    ];

    final fallbackBriefing = 'Offline Briefing: Your $deviceBrand device has completed $auditedAppsCount of $totalAppsCount app audits, $smsScanCount SMS scans, $emailScanCount email scans, and $linkScanCount link verifications. Connect to the network to receive your full AI-powered coaching analysis.';

    final List<Map<String, dynamic>> fallbackRecs = [];
    if (totalAppsCount - auditedAppsCount > 0) {
      fallbackRecs.add({
        'title': 'Audit Pending Applications',
        'description': 'Run reputation audits on your remaining ${totalAppsCount - auditedAppsCount} third-party applications to complete this task.',
        'priority': 'MEDIUM',
      });
    }
    if (suspiciousAppsCount > 0) {
      fallbackRecs.add({
        'title': 'Review Flagged Applications',
        'description': '$suspiciousAppsCount application(s) have triggered advisory flags during audits. Review their permissions and recent news in the App Auditor.',
        'priority': 'HIGH',
      });
    }
    if (smsScanCount == 0) {
      fallbackRecs.add({
        'title': 'Complete SMS Scan Task',
        'description': 'Open the SMS Scanner and analyse your recent inbox to complete this security task.',
        'priority': 'MEDIUM',
      });
    }
    if (emailScanCount == 0) {
      fallbackRecs.add({
        'title': 'Complete Email Scan Task',
        'description': 'Open the Email Scanner to analyse a suspicious email and complete this security task.',
        'priority': 'MEDIUM',
      });
    }
    if (linkScanCount == 0) {
      fallbackRecs.add({
        'title': 'Complete Link Verification Task',
        'description': 'Verify at least one URL using the Link Scanner to complete this security task.',
        'priority': 'LOW',
      });
    }
    fallbackRecs.add({
      'title': 'Enable Google Play Protect',
      'description': 'Confirm Google Play Protect background app scanning is active in your device settings.',
      'priority': 'HIGH',
    });

    final Map<String, dynamic> fallbackResult = {
      'taskStatuses': fallbackTaskStatuses,
      'briefing': fallbackBriefing,
      'recommendations': fallbackRecs.take(3).toList(),
      'offline': true,
    };

    final bool hasApiKey = _apiKey != 'YOUR_GEMINI_API_KEY' && _apiKey.isNotEmpty;
    if (!hasApiKey) {
      return fallbackResult;
    }

    try {
      final prompt = '''
You are "Sentinel Coach", an expert mobile security briefing synthesizer.
Generate a personalized security task overview based on the user's local security activity.

LOCAL PARAMETERS:
- Device Brand/Manufacturer: $deviceBrand
- Audited Apps Count: $auditedAppsCount
- Total Third-Party Apps: $totalAppsCount
- Apps with Advisory Flags: $suspiciousAppsCount
- SMS Phishing Scans Done: $smsScanCount
- Email Phishing Scans Done: $emailScanCount
- Link/URL Scans Done: $linkScanCount
- Latest Community Threat Titles: ${communityThreats.join(", ")}

CRITICAL INSTRUCTIONS:
- Do NOT generate any numeric security score or risk score.
- Do NOT tell the user to uninstall any application. If apps have advisory flags, suggest they review them in the App Auditor.
- Do NOT use the terms "safe", "unsafe", "malicious", or "infected" to describe apps.
- Instead, express the device state through TASK COMPLETION STATUS for each security action.

GUIDELINES:
1. TASK STATUSES (for each security task, determine if it is COMPLETED or PENDING based on the counts above):
   - App Audits: COMPLETED if auditedAppsCount > 0
   - SMS Scan: COMPLETED if smsScanCount > 0
   - Email Scan: COMPLETED if emailScanCount > 0
   - Link Verification: COMPLETED if linkScanCount > 0
2. BRIEFING (A concise, motivational 3-sentence summary):
   - Mention the device brand and how many security tasks have been completed.
   - Reference at least one item from the community threat titles if any exist.
   - Encourage the user to complete any pending tasks.
3. RECOMMENDATIONS (Provide exactly 3 actionable tasks):
   - Prioritize tasks that are PENDING.
   - For apps with advisory flags, recommend reviewing their details in the App Auditor, not uninstalling.
   - Each recommendation must have a title, description, and priority (HIGH, MEDIUM, or LOW).

Return ONLY a valid JSON object matching the following structure, nothing else:
{
  "taskStatuses": [
    {"task": "App Reputation Audits", "status": "COMPLETED or PENDING", "detail": "(e.g. 5 of 12 apps audited)"},
    {"task": "SMS Phishing Scan", "status": "COMPLETED or PENDING", "detail": "(e.g. 2 scans completed)"},
    {"task": "Email Security Scan", "status": "COMPLETED or PENDING", "detail": "(e.g. No scans run yet)"},
    {"task": "Link / URL Verification", "status": "COMPLETED or PENDING", "detail": "(e.g. 3 links verified)"}
  ],
  "briefing": "(3-sentence personalized motivational briefing)",
  "recommendations": [
    {
      "title": "(Clear short task action)",
      "description": "(1-sentence description of what the user should do next)",
      "priority": "(HIGH / MEDIUM / LOW)"
    }
  ]
}
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      String responseText = response.text ?? '{}';
      responseText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      
      final result = jsonDecode(responseText);
      if (result is Map && result.containsKey('briefing')) {
        return Map<String, dynamic>.from(result);
      }
      return fallbackResult;
    } catch (e) {
      print('Error generating Sentinel briefing: $e');
      return fallbackResult;
    }
  }

  /// Interactive Q&A with Sentinel Coach keeping conversation history context
  Future<String> chatWithSentinelCoach(String userPrompt, List<Content> history) async {
    try {
      final bool hasApiKey = _apiKey != 'YOUR_GEMINI_API_KEY' && _apiKey.isNotEmpty;
      if (!hasApiKey) {
        return "Offline Mode: Gemini API Key is not configured. Please check your connectivity or settings to resume conversation with Sentinel Coach.";
      }

      final chat = _model.startChat(
        history: history,
        generationConfig: GenerationConfig(maxOutputTokens: 250),
      );

      final response = await chat.sendMessage(Content.text(
        "System Instruction: You are Sentinel Coach, the user's friendly AI security advisor. Answer the following user query concisely (2-3 paragraphs max). Keep your tone informative, cyber-focused, reassuring, and direct. Do not use markdown bullet lists, write in clean readable prose.\n\nUser: $userPrompt"
      ));

      return response.text ?? "No response received.";
    } catch (e) {
      return "Unable to connect to Sentinel Coach: $e";
    }
  }
}

