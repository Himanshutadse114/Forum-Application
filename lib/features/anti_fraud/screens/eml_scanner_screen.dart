import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cybershield_forum/core/theme.dart';
import 'package:cybershield_forum/core/hive_box.dart';
import 'package:cybershield_forum/features/anti_fraud/services/gemini_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cybershield_forum/features/reports/provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:cybershield_forum/features/anti_fraud/services/gmail_api_service.dart';

class EmlScannerScreen extends ConsumerStatefulWidget {
  const EmlScannerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EmlScannerScreen> createState() => _EmlScannerScreenState();
}

class _EmlScannerScreenState extends ConsumerState<EmlScannerScreen> {
  final GeminiService _geminiService = GeminiService();
  
  PlatformFile? _selectedFile;
  String? _emlContent;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  String? _error;
  bool _isReporting = false;

  // For screenshot scan
  PlatformFile? _screenshotFile;
  Uint8List? _screenshotBytes;
  bool _isAnalyzingScreenshot = false;
  Map<String, dynamic>? _screenshotResult;
  String? _screenshotError;
  bool _isReportingScreenshot = false;

  Future<void> _pickEmlFile() async {
    setState(() {
      _error = null;
      _analysisResult = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['eml'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        String? content;

        if (file.bytes != null) {
          content = String.fromCharCodes(file.bytes!);
        } else if (file.path != null) {
          final ioFile = File(file.path!);
          content = await ioFile.readAsString();
        }

        if (content == null || content.trim().isEmpty) {
          setState(() {
            _error = "The selected file is empty or could not be read.";
          });
          return;
        }

        setState(() {
          _selectedFile = file;
          _emlContent = content;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Failed to load file: $e";
      });
    }
  }

  bool _isGmailLoading = false;

  Future<void> _importFromGmail() async {
    setState(() {
      _error = null;
      _analysisResult = null;
    });

    try {
      // 1. Sign in
      var account = await GmailApiService.currentUser;
      account ??= await GmailApiService.signIn();

      if (account == null) {
        setState(() {
          _error = "Google authentication was cancelled.";
        });
        return;
      }

      final userEmail = account.email;

      // 2. Fetch emails
      setState(() => _isGmailLoading = true);
      final recentEmails = await GmailApiService.fetchRecentEmails();
      setState(() => _isGmailLoading = false);

      if (recentEmails.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No emails found in your primary inbox.')),
        );
        return;
      }

      // 3. Show picker list sheet
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Email to Scan',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: CyberTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Signed in as: $userEmail',
                  style: GoogleFonts.inter(fontSize: 11, color: CyberTheme.textMuted),
                  textAlign: TextAlign.center,
                ),
                const Divider(height: 24),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: recentEmails.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, idx) {
                      final item = recentEmails[idx];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFEECE0),
                          child: Icon(Icons.email_outlined, color: CyberTheme.primary, size: 18),
                        ),
                        title: Text(
                          item.subject,
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From: ${item.from}',
                              style: GoogleFonts.inter(fontSize: 10.5, color: CyberTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.snippet,
                              style: GoogleFonts.inter(fontSize: 10, color: CyberTheme.textMuted),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 16),
                        onTap: () async {
                          Navigator.pop(context); // Close sheet
                          _loadGmailEmail(item);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isGmailLoading = false;
        _error = "Gmail Fetch Error: $e";
      });
    }
  }

  Future<void> _loadGmailEmail(GmailEmailItem item) async {
    setState(() {
      _isAnalyzing = true;
      _error = null;
      _analysisResult = null;
    });

    try {
      final rawContent = await GmailApiService.fetchRawEmailContent(item.id);
      
      setState(() {
        _selectedFile = PlatformFile(
          name: '${item.subject.replaceAll(RegExp(r"[\\/:*?<>|]"), '_')}.eml',
          size: rawContent.length,
        );
        _emlContent = rawContent;
        _isAnalyzing = false;
      });

      // Prompt automatically to analyze
      _analyzeEml();
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _error = "Failed to retrieve raw content from Gmail: $e";
      });
    }
  }

  Future<void> _analyzeEml() async {
    if (_emlContent == null) return;

    setState(() {
      _isAnalyzing = true;
      _error = null;
      _analysisResult = null;
    });

    try {
      final result = await _geminiService.analyzeEml(_emlContent!);
      try {
        await HiveBoxHelper.incrementScanCount('email');
      } catch (_) {}
      
      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _error = "AI Scan failed: $e";
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _reportToCommunity() async {
    if (_analysisResult == null) return;
    
    setState(() => _isReporting = true);
    
    final score = _analysisResult!['score'] ?? 0;
    final subject = _analysisResult!['subject'] ?? 'Suspicious Email';
    final from = _analysisResult!['from'] ?? 'Unknown';
    final explanation = _analysisResult!['explanation'] ?? '';

    final description = 'Threat Score: $score/100\nFrom: $from\n\nSecurity Audit:\n$explanation';

    final success = await ref.read(threatOpsProvider.notifier).submitReport(
      title: 'Phishing Email: "$subject"',
      description: description,
      scamType: 'Email Phishing',
    );

    setState(() => _isReporting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phishing threat logged in the community database! +10 XP')),
      );
      // Refresh the feed
      ref.invalidate(threatFeedProvider);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit report. Please try again.')),
      );
    }
  }

  // Screenshot scanner handlers
  Future<void> _pickScreenshot() async {
    setState(() {
      _screenshotError = null;
      _screenshotResult = null;
      _screenshotFile = null;
      _screenshotBytes = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        Uint8List? bytes;

        if (file.bytes != null) {
          bytes = file.bytes;
        } else if (file.path != null) {
          final ioFile = File(file.path!);
          bytes = await ioFile.readAsBytes();
        }

        if (bytes == null || bytes.isEmpty) {
          setState(() {
            _screenshotError = "The selected image is empty or could not be read.";
          });
          return;
        }

        setState(() {
          _screenshotFile = file;
          _screenshotBytes = bytes;
        });
      }
    } catch (e) {
      setState(() {
        _screenshotError = "Failed to load image: $e";
      });
    }
  }

  Future<void> _analyzeScreenshot() async {
    if (_screenshotBytes == null || _screenshotFile == null) return;

    setState(() {
      _isAnalyzingScreenshot = true;
      _screenshotError = null;
      _screenshotResult = null;
    });

    try {
      final ext = _screenshotFile!.extension?.toLowerCase() ?? 
                  (_screenshotFile!.name.contains('.') ? _screenshotFile!.name.split('.').last.toLowerCase() : 'png');
      final mimeType = ext == 'jpg' || ext == 'jpeg' ? 'image/jpeg' : 'image/png';
      
      final result = await _geminiService.analyzeEmlScreenshot(_screenshotBytes!, mimeType);
      try {
        await HiveBoxHelper.incrementScanCount('email');
      } catch (_) {}
      
      setState(() {
        _screenshotResult = result;
        _isAnalyzingScreenshot = false;
      });
    } catch (e) {
      setState(() {
        _screenshotError = "AI Scan failed: $e";
        _isAnalyzingScreenshot = false;
      });
    }
  }

  Future<void> _reportScreenshotToCommunity() async {
    if (_screenshotResult == null) return;
    
    setState(() => _isReportingScreenshot = true);
    
    final score = _screenshotResult!['score'] ?? 0;
    final subject = _screenshotResult!['subject'] ?? 'Suspicious Email';
    final from = _screenshotResult!['from'] ?? 'Unknown';
    final explanation = _screenshotResult!['explanation'] ?? '';

    final description = 'Threat Score: $score/100\nFrom: $from\n\nSecurity Audit:\n$explanation';

    final success = await ref.read(threatOpsProvider.notifier).submitReport(
      title: 'Phishing Email: "$subject"',
      description: description,
      scamType: 'Email Phishing',
    );

    setState(() => _isReportingScreenshot = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phishing threat logged in the community database! +10 XP')),
      );
      // Refresh the feed
      ref.invalidate(threatFeedProvider);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit report. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: CyberTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          iconTheme: const IconThemeData(color: CyberTheme.textPrimary),
          title: Text(
            'Email Inspector',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              color: CyberTheme.textPrimary,
            ),
          ),
          bottom: TabBar(
            labelColor: CyberTheme.primary,
            unselectedLabelColor: CyberTheme.textMuted,
            indicatorColor: CyberTheme.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: const [
              Tab(text: 'Eml / Gmail Inspector', icon: Icon(Icons.mark_as_unread_outlined, size: 20)),
              Tab(text: 'Scan Screenshot', icon: Icon(Icons.add_photo_alternate_outlined, size: 20)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildEmlTab(),
            _buildScreenshotTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmlTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // EML Selection Box
          Container(
            padding: const EdgeInsets.all(24),
            decoration: CyberTheme.neonGlowDecoration(),
            child: Column(
              children: [
                Icon(
                  Icons.mark_as_unread_outlined,
                  size: 48,
                  color: _selectedFile != null ? CyberTheme.primary : CyberTheme.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedFile != null ? _selectedFile!.name : 'No file selected',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: CyberTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_selectedFile != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Size: ${(_selectedFile!.size / 1024).toStringAsFixed(2)} KB',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: CyberTheme.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickEmlFile,
                      icon: const Icon(Icons.file_open_outlined, size: 16, color: Colors.white),
                      label: Text(
                        _selectedFile != null ? 'Change File' : 'Pick .eml File',
                        style: GoogleFonts.spaceGrotesk(color: Colors.white),
                      ),
                    ),
                    if (_selectedFile == null)
                      ElevatedButton.icon(
                        onPressed: _isGmailLoading ? null : _importFromGmail,
                        icon: _isGmailLoading 
                            ? const SizedBox(
                                width: 14, 
                                height: 14, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              )
                            : const Icon(Icons.mail_outline, size: 16, color: Colors.white),
                        label: Text(
                          'Import from Gmail',
                          style: GoogleFonts.spaceGrotesk(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.shade700,
                        ),
                      ),
                    if (_selectedFile != null)
                      OutlinedButton.icon(
                        onPressed: _isAnalyzing ? null : _analyzeEml,
                        icon: const Icon(Icons.security, size: 16, color: CyberTheme.primary),
                        label: Text(
                          'Analyze EML',
                          style: GoogleFonts.spaceGrotesk(
                            color: CyberTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: CyberTheme.primary, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(99),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (_isAnalyzing)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: CyberTheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Deconstructing raw headers & body metadata...',
                      style: GoogleFonts.spaceGrotesk(
                        color: CyberTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CyberTheme.danger.withOpacity(0.05),
                border: Border.all(color: CyberTheme.danger.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: CyberTheme.danger),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: GoogleFonts.inter(
                        color: CyberTheme.danger,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_analysisResult != null && !_isAnalyzing) ...[
            _buildAuditOverviewCard(),
            const SizedBox(height: 20),
            _buildAuthHeaderCard(),
            const SizedBox(height: 20),
            _buildSuspiciousLinksCard(),
            const SizedBox(height: 20),
            _buildSuspiciousAttachmentsCard(),
            const SizedBox(height: 24),
            
            // Community reporting
            ElevatedButton.icon(
              onPressed: _isReporting ? null : _reportToCommunity,
              icon: const Icon(Icons.campaign_outlined, size: 20, color: Colors.white),
              label: _isReporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'REPORT AS PHISHING TO COMMUNITY LEDGER',
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: CyberTheme.danger,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 20),
          ]
        ],
      ),
    );
  }

  Widget _buildScreenshotTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Select Screenshot Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: CyberTheme.neonGlowDecoration(),
            child: Column(
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 48,
                  color: _screenshotBytes != null ? CyberTheme.primary : CyberTheme.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  _screenshotFile != null ? _screenshotFile!.name : 'No screenshot selected',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: CyberTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_screenshotBytes != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Size: ${(_screenshotBytes!.length / 1024).toStringAsFixed(2)} KB',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: CyberTheme.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickScreenshot,
                      icon: const Icon(Icons.photo_library_outlined, size: 16, color: Colors.white),
                      label: Text(
                        _screenshotFile != null ? 'Change Image' : 'Pick Screenshot',
                        style: GoogleFonts.spaceGrotesk(color: Colors.white),
                      ),
                    ),
                    if (_screenshotBytes != null)
                      OutlinedButton.icon(
                        onPressed: _isAnalyzingScreenshot ? null : _analyzeScreenshot,
                        icon: const Icon(Icons.security, size: 16, color: CyberTheme.primary),
                        label: Text(
                          'Analyze Screenshot',
                          style: GoogleFonts.spaceGrotesk(
                            color: CyberTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: CyberTheme.primary, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(99),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (_isAnalyzingScreenshot)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: CyberTheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Analyzing screenshot details via Gemini AI...',
                      style: GoogleFonts.spaceGrotesk(
                        color: CyberTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_screenshotError != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CyberTheme.danger.withOpacity(0.05),
                border: Border.all(color: CyberTheme.danger.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: CyberTheme.danger),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _screenshotError!,
                      style: GoogleFonts.inter(
                        color: CyberTheme.danger,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_screenshotResult != null && !_isAnalyzingScreenshot) ...[
            if (_screenshotResult!['isValidImage'] == false)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CyberTheme.warning.withOpacity(0.05),
                  border: Border.all(color: CyberTheme.warning.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: CyberTheme.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _screenshotResult!['explanation'] ?? 'This image does not appear to contain a valid email message. Please upload a valid screenshot.',
                        style: GoogleFonts.inter(
                          color: CyberTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              _buildScreenshotOverviewCard(),
              const SizedBox(height: 20),
              _buildScreenshotAuthHeaderCard(),
              const SizedBox(height: 20),
              _buildScreenshotSuspiciousLinksCard(),
              const SizedBox(height: 20),
              _buildScreenshotSuspiciousAttachmentsCard(),
              const SizedBox(height: 24),
              
              // Community reporting
              ElevatedButton.icon(
                onPressed: _isReportingScreenshot ? null : _reportScreenshotToCommunity,
                icon: const Icon(Icons.campaign_outlined, size: 20, color: Colors.white),
                label: _isReportingScreenshot
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'REPORT AS PHISHING TO COMMUNITY LEDGER',
                        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CyberTheme.danger,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ]
        ],
      ),
    );
  }

  Widget _buildScreenshotOverviewCard() {
    final score = _screenshotResult!['score'] ?? 0;
    final isPhishing = _screenshotResult!['isPhishing'] == true;
    final explanation = _screenshotResult!['explanation'] ?? '';
    final subject = _screenshotResult!['subject'] ?? 'No Subject';
    final from = _screenshotResult!['from'] ?? 'Unknown';
    final date = _screenshotResult!['date'] ?? 'Unknown';

    Color scoreColor = CyberTheme.success;
    if (score >= 70) {
      scoreColor = CyberTheme.danger;
    } else if (score >= 40) {
      scoreColor = CyberTheme.warning;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isPhishing ? CyberTheme.danger : CyberTheme.success, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Screenshot AI Assessment',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: CyberTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'Risk Score: $score/100',
                  style: GoogleFonts.spaceGrotesk(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              )
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow('Subject', subject),
          _buildInfoRow('Sender', from),
          _buildInfoRow('Date', date),
          const Divider(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isPhishing ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                color: isPhishing ? CyberTheme.danger : CyberTheme.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  explanation,
                  style: GoogleFonts.inter(
                    color: isPhishing ? CyberTheme.danger : CyberTheme.success,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildScreenshotAuthHeaderCard() {
    final spf = _screenshotResult!['spf'] ?? 'NOT_APPLICABLE';
    final dkim = _screenshotResult!['dkim'] ?? 'NOT_APPLICABLE';
    final dmarc = _screenshotResult!['dmarc'] ?? 'NOT_APPLICABLE';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEFEDED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Header Authentication Audits',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: CyberTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Authentication headers cannot be verified from a screenshot. Gemini analyzed visual traits instead.',
            style: GoogleFonts.inter(fontSize: 11, color: CyberTheme.textMuted),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAuthStatusBadge('SPF', spf),
              _buildAuthStatusBadge('DKIM', dkim),
              _buildAuthStatusBadge('DMARC', dmarc),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildScreenshotSuspiciousLinksCard() {
    final links = _screenshotResult!['suspiciousLinks'] as List? ?? [];
    if (links.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEFEDED)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: CyberTheme.success),
            const SizedBox(width: 12),
            Text(
              'No suspicious URLs detected in screenshot text.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: CyberTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEFEDED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suspicious Links Detected (${links.length})',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: CyberTheme.danger,
            ),
          ),
          const SizedBox(height: 12),
          ...links.map((link) {
            final url = link['url'] ?? '';
            final reason = link['reason'] ?? '';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CyberTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CyberTheme.danger.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    url,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: CyberTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reason: $reason',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: CyberTheme.danger,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildScreenshotSuspiciousAttachmentsCard() {
    final attachments = _screenshotResult!['suspiciousAttachments'] as List? ?? [];
    if (attachments.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEFEDED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'High-Risk Attachments Found (${attachments.length})',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: CyberTheme.danger,
            ),
          ),
          const SizedBox(height: 12),
          ...attachments.map((file) {
            final name = file['name'] ?? '';
            final reason = file['reason'] ?? '';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CyberTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CyberTheme.danger.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.file_present_outlined, color: CyberTheme.danger, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: CyberTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          reason,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: CyberTheme.danger,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAuditOverviewCard() {
    final score = _analysisResult!['score'] ?? 0;
    final isPhishing = _analysisResult!['isPhishing'] == true;
    final explanation = _analysisResult!['explanation'] ?? '';
    final subject = _analysisResult!['subject'] ?? 'No Subject';
    final from = _analysisResult!['from'] ?? 'Unknown';
    final date = _analysisResult!['date'] ?? 'Unknown';

    Color scoreColor = CyberTheme.success;
    if (score >= 70) {
      scoreColor = CyberTheme.danger;
    } else if (score >= 40) {
      scoreColor = CyberTheme.warning;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEFEDED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Deep AI Assessment',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: CyberTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'Risk Score: $score/100',
                  style: GoogleFonts.spaceGrotesk(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              )
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow('Subject', subject),
          _buildInfoRow('Sender', from),
          _buildInfoRow('Date', date),
          const Divider(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isPhishing ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                color: isPhishing ? CyberTheme.danger : CyberTheme.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  explanation,
                  style: GoogleFonts.inter(
                    color: isPhishing ? CyberTheme.danger : CyberTheme.success,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: CyberTheme.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: CyberTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAuthHeaderCard() {
    final spf = _analysisResult!['spf'] ?? 'UNKNOWN';
    final dkim = _analysisResult!['dkim'] ?? 'UNKNOWN';
    final dmarc = _analysisResult!['dmarc'] ?? 'UNKNOWN';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEFEDED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Header Authentication Audits',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: CyberTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAuthStatusBadge('SPF', spf),
              _buildAuthStatusBadge('DKIM', dkim),
              _buildAuthStatusBadge('DMARC', dmarc),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAuthStatusBadge(String type, String status) {
    final cleanStatus = status.toUpperCase().trim();
    Color statusColor = CyberTheme.textMuted;
    if (cleanStatus == 'PASS') {
      statusColor = CyberTheme.success;
    } else if (cleanStatus == 'FAIL') {
      statusColor = CyberTheme.danger;
    } else if (cleanStatus == 'SOFTFAIL' || cleanStatus == 'NONE') {
      statusColor = CyberTheme.warning;
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: CyberTheme.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEFEDED)),
        ),
        child: Column(
          children: [
            Text(
              type,
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: CyberTheme.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                cleanStatus,
                style: GoogleFonts.spaceGrotesk(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSuspiciousLinksCard() {
    final links = _analysisResult!['suspiciousLinks'] as List? ?? [];
    if (links.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEFEDED)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: CyberTheme.success),
            const SizedBox(width: 12),
            Text(
              'No suspicious URLs found in email body.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: CyberTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEFEDED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suspicious Links Detected (${links.length})',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: CyberTheme.danger,
            ),
          ),
          const SizedBox(height: 12),
          ...links.map((link) {
            final url = link['url'] ?? '';
            final reason = link['reason'] ?? '';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CyberTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CyberTheme.danger.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    url,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: CyberTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reason: $reason',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: CyberTheme.danger,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSuspiciousAttachmentsCard() {
    final attachments = _analysisResult!['suspiciousAttachments'] as List? ?? [];
    if (attachments.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEFEDED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'High-Risk Attachments Found (${attachments.length})',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: CyberTheme.danger,
            ),
          ),
          const SizedBox(height: 12),
          ...attachments.map((file) {
            final name = file['name'] ?? '';
            final reason = file['reason'] ?? '';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CyberTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CyberTheme.danger.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.file_present_outlined, color: CyberTheme.danger, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: CyberTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          reason,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: CyberTheme.danger,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
