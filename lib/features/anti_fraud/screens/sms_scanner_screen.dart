import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cybershield_forum/core/theme.dart';
import 'package:cybershield_forum/core/hive_box.dart';
import 'package:cybershield_forum/features/anti_fraud/services/gemini_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cybershield_forum/features/reports/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';

class SmsScannerScreen extends ConsumerStatefulWidget {
  const SmsScannerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SmsScannerScreen> createState() => _SmsScannerScreenState();
}

class _SmsScannerScreenState extends ConsumerState<SmsScannerScreen> {
  final SmsQuery _query = SmsQuery();
  List<SmsMessage> _messages = [];
  bool _isLoading = false;
  bool _hasPermission = false;
  final GeminiService _geminiService = GeminiService();
  
  // Cache for analysis results
  final Map<int, Map<String, dynamic>> _analysisResults = {};

  // For screenshot scan
  PlatformFile? _screenshotFile;
  Uint8List? _screenshotBytes;
  bool _isAnalyzingScreenshot = false;
  Map<String, dynamic>? _screenshotResult;
  String? _screenshotError;
  bool _isReportingScreenshot = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.sms.status;
    setState(() {
      _hasPermission = status.isGranted;
    });
    if (_hasPermission) {
      _fetchMessages();
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.sms.request();
    if (status.isGranted) {
      setState(() => _hasPermission = true);
      _fetchMessages();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SMS permission denied.')),
      );
    }
  }

  Future<void> _fetchMessages() async {
    setState(() => _isLoading = true);
    try {
      final messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 20, // Load recent 20 messages
      );
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading SMS: $e')),
      );
    }
  }

  Future<void> _analyzeMessage(int index, SmsMessage msg) async {
    setState(() {
      _analysisResults[index] = {'loading': true};
    });

    final body = msg.body ?? '';
    final sender = msg.address ?? 'Unknown';
    
    final result = await _geminiService.analyzeSms(body, sender);
    try {
      await HiveBoxHelper.incrementScanCount('sms');
    } catch (_) {}
    
    setState(() {
      _analysisResults[index] = result;
      _analysisResults[index]!['loading'] = false;
    });
  }

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
      
      final result = await _geminiService.analyzeSmsScreenshot(_screenshotBytes!, mimeType);
      try {
        await HiveBoxHelper.incrementScanCount('sms');
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

  Future<void> _reportSmsToCommunity() async {
    if (_screenshotResult == null) return;

    setState(() => _isReportingScreenshot = true);

    final score = _screenshotResult!['score'] ?? 0;
    final sender = _screenshotResult!['extractedSender'] ?? 'Unknown';
    final message = _screenshotResult!['extractedMessage'] ?? '';
    final explanation = _screenshotResult!['explanation'] ?? '';

    final description = 'Threat Score: $score/100\nSender: $sender\nMessage Content:\n$message\n\nSecurity Audit:\n$explanation';

    final success = await ref.read(threatOpsProvider.notifier).submitReport(
      title: 'Phishing SMS from: "$sender"',
      description: description,
      scamType: 'SMS Phishing',
    );

    setState(() => _isReportingScreenshot = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phishing threat logged in the community database! +10 XP')),
      );
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
          title: Text(
            'SMS Phishing Scanner',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              color: CyberTheme.textPrimary,
            ),
          ),
          iconTheme: const IconThemeData(color: CyberTheme.textPrimary),
          elevation: 0.5,
          bottom: TabBar(
            labelColor: CyberTheme.primary,
            unselectedLabelColor: CyberTheme.textMuted,
            indicatorColor: CyberTheme.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: const [
              Tab(text: 'Inbox Messages', icon: Icon(Icons.message_outlined, size: 20)),
              Tab(text: 'Scan Screenshot', icon: Icon(Icons.add_photo_alternate_outlined, size: 20)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInboxTab(),
            _buildScreenshotTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildInboxTab() {
    if (!_hasPermission) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sms_failed_outlined, size: 64, color: CyberTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              'Permission Required',
              style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'To detect phishing attempts directly, Innvikta needs permission to read your SMS inbox.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: CyberTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _requestPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: CyberTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Grant Permission',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: CyberTheme.primary));
    }

    if (_messages.isEmpty) {
      return const Center(child: Text('No SMS messages found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final analysis = _analysisResults[index];
        final isAnalyzed = analysis != null && analysis['loading'] != true;
        final isLoading = analysis != null && analysis['loading'] == true;
        
        bool isPhishing = false;
        Color borderColor = const Color(0xFFEFEDED);
        
        if (isAnalyzed) {
          isPhishing = analysis['isPhishing'] == true;
          borderColor = isPhishing ? CyberTheme.danger : CyberTheme.success;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: isAnalyzed ? 2 : 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ]
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        msg.address ?? 'Unknown Sender',
                        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    if (isAnalyzed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPhishing ? CyberTheme.danger.withOpacity(0.1) : CyberTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isPhishing ? "PHISHING (Score: ${analysis['score']})" : "SAFE (Score: ${analysis['score']})",
                          style: GoogleFonts.spaceGrotesk(
                            color: isPhishing ? CyberTheme.danger : CyberTheme.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  msg.body ?? '',
                  style: GoogleFonts.inter(color: CyberTheme.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 12),
                
                if (isAnalyzed) ...[
                  const Divider(),
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
                          analysis['explanation'] ?? '',
                          style: GoogleFonts.inter(
                            color: isPhishing ? CyberTheme.danger : CyberTheme.success,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      )
                    ],
                  ),
                ],
                
                if (!isAnalyzed && !isLoading)
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => _analyzeMessage(index, msg),
                      icon: const Icon(Icons.analytics_outlined, size: 16, color: CyberTheme.primary),
                      label: Text(
                        'Scan Message',
                        style: GoogleFonts.spaceGrotesk(color: CyberTheme.primary, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: CyberTheme.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  
                if (isLoading)
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: CyberTheme.primary)
                      ),
                    ),
                  )
              ],
            ),
          ),
        );
      },
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
                        _screenshotResult!['explanation'] ?? 'This image does not appear to contain a valid SMS message. Please upload a valid screenshot.',
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
              const SizedBox(height: 24),
              
              // Community reporting
              ElevatedButton.icon(
                onPressed: _isReportingScreenshot ? null : _reportSmsToCommunity,
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
    final sender = _screenshotResult!['extractedSender'] ?? 'Unknown';
    final message = _screenshotResult!['extractedMessage'] ?? '';

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
          _buildInfoRow('Sender', sender),
          const SizedBox(height: 8),
          Text(
            'Extracted Message:',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: CyberTheme.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CyberTheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEFEDED)),
            ),
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: CyberTheme.textPrimary,
              ),
            ),
          ),
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
}
