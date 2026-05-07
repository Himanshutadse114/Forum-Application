import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../utils/constants.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isScanning = false;
  String? _scanResult;
  bool _isResultPhish = false;
  String _threatExplanation = "";

  void _performScan() {
    final input = _urlController.text.trim().toLowerCase();
    if (input.isEmpty) return;

    setState(() {
      _isScanning = true;
      _scanResult = null;
    });

    Timer(const Duration(seconds: 1), () {
      setState(() {
        _isScanning = false;
        
        bool isPhish = false;
        List<String> reasons = [];

        // 1. IP Address instead of domain
        final ipPattern = RegExp(r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}');
        if (ipPattern.hasMatch(input)) {
          isPhish = true;
          reasons.add("Uses an IP address instead of a secure domain name");
        }

        // 2. Suspicious Top-Level Domains (TLDs)
        final suspiciousTlds = ['.info', '.xyz', '.club', '.top', '.tk', '.cc', '.live', '.support', '.work', '.gq', '.cf', '.ml', '.ga', '.fit', '.gdn'];
        for (var tld in suspiciousTlds) {
          if (input.contains(tld)) {
            isPhish = true;
            reasons.add("Uses a suspicious Top-Level Domain ($tld) frequently linked with scams");
            break;
          }
        }

        // 3. Brand Squatting & Misspellings (e.g., netfiix, paypa1, g00gle)
        final lookalikes = {
          'Netflix': ['netfiix', 'netflx', 'netf1ix', 'netf-'],
          'PayPal': ['paypa1', 'payp1', 'paypai', 'payp-'],
          'Google': ['g00g', 'go0g', 'g0og', 'goog1e'],
          'Microsoft': ['micros0ft', 'micr0soft', 'microsof-'],
        };
        
        lookalikes.forEach((brand, typos) {
          for (var typo in typos) {
            if (input.contains(typo)) {
              isPhish = true;
              reasons.add("Deceptive brand-spoofing / misspelling of '$brand' detected");
              break;
            }
          }
        });

        // 4. Common Phishing Action Keywords
        final phishKeywords = [
          'login', 'secure', 'bank', 'paypal', 'netflix', 'verify', 'signin', 
          'update', 'billing', 'refund', 'urgent', 'suspend', 'alert', 
          'account', 'free', 'prize', 'gift', 'claim', 'bonus', 'support'
        ];

        // Whitelist safe domains
        final trustedDomains = ['google.com', 'netflix.com', 'paypal.com', 'microsoft.com', 'apple.com', 'flutter.dev', 'github.com'];
        bool isTrusted = false;
        for (var domain in trustedDomains) {
          if (input.endsWith(domain) || input.contains('//' + domain) || input == domain) {
            isTrusted = true;
          }
        }

        if (!isTrusted) {
          int matchCount = 0;
          List<String> matchedKeywords = [];
          for (var keyword in phishKeywords) {
            if (input.contains(keyword)) {
              matchCount++;
              matchedKeywords.add(keyword);
            }
          }
          if (matchCount >= 1) {
            isPhish = true;
            reasons.add("Contains high-risk phishing keywords: ${matchedKeywords.join(', ')}");
          }
          
          if (!input.contains('https://') && (input.startsWith('http://') || input.contains('http:'))) {
            isPhish = true;
            reasons.add("Lacks secure HTTPS encryption (uses unencrypted HTTP)");
          }
          
          if (!input.contains('.')) {
            isPhish = true;
            reasons.add("Invalid domain format or generic redirect code");
          }
        } else {
          isPhish = false;
        }

        if (isPhish) {
          _isResultPhish = true;
          _scanResult = "CRITICAL THREAT DETECTED";
          _threatExplanation = "Our advanced heuristics flagged this URL:\n" + 
              reasons.map((r) => "• $r").join("\n");
        } else {
          _isResultPhish = false;
          _scanResult = "SECURE & VERIFIED DOMAIN";
          _threatExplanation = "This URL belongs to a verified trusted host or passed all standard heuristic safety audits. Safe to browse.";
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstantsColor.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Icon(CupertinoIcons.shield_fill, color: AppConstantsColor.primaryColor, size: 28),
            const SizedBox(width: 8),
            Text(
              "Innvikta",
              style: TextStyle(
                fontFamily: 'Quicksand',
                color: AppConstantsColor.darkTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.bell_fill, color: AppConstantsColor.primaryColor),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Text(
              "Defender Dashboard",
              style: TextStyle(
                color: AppConstantsColor.darkTextColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Train yourself to spot and block malicious scams",
              style: TextStyle(
                color: AppConstantsColor.lightTextColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),

            // Security Score Circular Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstantsColor.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppConstantsColor.primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: 0.85,
                          strokeWidth: 8,
                          backgroundColor: AppConstantsColor.unSelectedTextColor,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppConstantsColor.secondaryColor,
                          ),
                        ),
                      ),
                      const Text(
                        "85%",
                        style: TextStyle(
                          color: AppConstantsColor.darkTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Safety Status: Safe",
                          style: TextStyle(
                            color: AppConstantsColor.secondaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "You've spotted 12 of 14 phishing simulations correctly. Outstanding work!",
                          style: TextStyle(
                            color: AppConstantsColor.lightTextColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),



            // URL Scanner Card
            Text(
              "URL Threat Investigator",
              style: TextStyle(
                color: AppConstantsColor.darkTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstantsColor.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppConstantsColor.unSelectedTextColor,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _urlController,
                    style: const TextStyle(color: AppConstantsColor.darkTextColor),
                    decoration: InputDecoration(
                      hintText: "Paste or type a suspicious link to scan...",
                      hintStyle: const TextStyle(color: AppConstantsColor.lightTextColor),
                      filled: true,
                      fillColor: AppConstantsColor.backgroundColor,
                      prefixIcon: const Icon(CupertinoIcons.link, color: AppConstantsColor.primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isScanning ? null : _performScan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstantsColor.primaryColor,
                      foregroundColor: AppConstantsColor.backgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isScanning
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppConstantsColor.backgroundColor),
                            ),
                          )
                        : const Text(
                            "Scan Link",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                  if (_scanResult != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isResultPhish
                            ? AppConstantsColor.dangerColor.withOpacity(0.1)
                            : AppConstantsColor.secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isResultPhish ? AppConstantsColor.dangerColor : AppConstantsColor.secondaryColor,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _scanResult!,
                            style: TextStyle(
                              color: _isResultPhish ? AppConstantsColor.dangerColor : AppConstantsColor.secondaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _threatExplanation,
                            style: const TextStyle(
                              color: AppConstantsColor.darkTextColor,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Daily Threat Tip Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppConstantsColor.cardColor,
                    AppConstantsColor.primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppConstantsColor.primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(CupertinoIcons.lightbulb_fill, color: AppConstantsColor.warningColor, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        "Tip of the Day",
                        style: TextStyle(
                          color: AppConstantsColor.warningColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Be extremely cautious of domain-spoofing! Attackers often create look-alike domains by swapping letters (e.g., swapping lower-case 'l' with upper-case 'I', resulting in 'netfIix.com'). Always double check spelling before signing in.",
                    style: TextStyle(
                      color: AppConstantsColor.darkTextColor,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Learn Section
            Text(
              "Security Quick Guides",
              style: TextStyle(
                color: AppConstantsColor.darkTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildQuickGuideCard(
                  CupertinoIcons.padlock_solid,
                  "Password Safety",
                  "Keep secrets safe",
                  AppConstantsColor.primaryColor,
                ),
                _buildQuickGuideCard(
                  CupertinoIcons.eye_solid,
                  "Spotting Phish",
                  "Identify fake links",
                  AppConstantsColor.secondaryColor,
                ),
                _buildQuickGuideCard(
                  CupertinoIcons.device_phone_portrait,
                  "2FA Setup",
                  "Double key protection",
                  AppConstantsColor.warningColor,
                ),
                _buildQuickGuideCard(
                  CupertinoIcons.person_3_fill,
                  "Social Scams",
                  "Block chat requests",
                  AppConstantsColor.dangerColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickGuideCard(IconData icon, String title, String subtitle, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstantsColor.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstantsColor.unSelectedTextColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: accentColor, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppConstantsColor.darkTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppConstantsColor.lightTextColor,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
