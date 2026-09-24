import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cybershield_forum/core/theme.dart';
import 'package:cybershield_forum/core/hive_box.dart';
import 'package:cybershield_forum/features/anti_fraud/services/gemini_service.dart';

class LinkScannerScreen extends StatefulWidget {
  final String? initialUrl;
  const LinkScannerScreen({super.key, this.initialUrl});

  @override
  State<LinkScannerScreen> createState() => _LinkScannerScreenState();
}

class _LinkScannerScreenState extends State<LinkScannerScreen> with TickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  final GeminiService _geminiService = GeminiService();

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _result;

  late final AnimationController _pulseController;
  late final AnimationController _resultController;
  late final Animation<double> _resultFade;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _resultFade = CurvedAnimation(parent: _resultController, curve: Curves.easeOut);

    // Pre-fill URL if shared from Chrome or passed via navigation
    if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      _urlController.text = widget.initialUrl!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scanUrl();
      });
    }

    // Try to read URL from Android Share intent (app just opened via share)
    _readSharedIntent();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _resultController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  /// Reads the shared text from Android's share intent via MethodChannel
  Future<void> _readSharedIntent() async {
    if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) return;
    try {
      const channel = MethodChannel('app.channel.shared.data');
      final sharedUrl = await channel.invokeMethod<String>('getSharedText');
      if (sharedUrl != null && sharedUrl.isNotEmpty && mounted) {
        setState(() => _urlController.text = sharedUrl.trim());
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          _scanUrl();
        }
      }
    } catch (_) {
      // No shared data — user will type manually
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && mounted) {
      setState(() => _urlController.text = data!.text!.trim());
    }
  }

  Future<void> _scanUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Please enter a URL to scan.');
      return;
    }

    // Auto-prepend https:// if missing scheme
    final scanUrl = (url.startsWith('http://') || url.startsWith('https://')) ? url : 'https://$url';

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });
    _resultController.reset();

    try {
      final result = await _geminiService.analyzeUrl(scanUrl);
      try {
        await HiveBoxHelper.incrementScanCount('link');
      } catch (_) {}
      
      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
        _resultController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Scan failed: $e';
          _isLoading = false;
        });
      }
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Color _scoreColor(int score) {
    if (score < 35) return CyberTheme.success;
    if (score < 65) return CyberTheme.warning;
    return CyberTheme.danger;
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return CyberTheme.danger;
      case 'medium':
        return CyberTheme.warning;
      default:
        return CyberTheme.success;
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Icons.error_outline_rounded;
      case 'medium':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _verdictLabel(Map<String, dynamic> result) =>
      result['verdict']?.toString() ?? (result['isPhishing'] == true ? 'Dangerous' : 'Safe');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.background,
      appBar: AppBar(
        backgroundColor: CyberTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: CyberTheme.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Link Scanner',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: CyberTheme.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeroHeader(),
              const SizedBox(height: 24),
              _buildUrlInputCard(),
              const SizedBox(height: 16),
              _buildScanButton(),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _buildErrorBanner(),
              ],
              if (_isLoading) ...[
                const SizedBox(height: 32),
                _buildLoadingState(),
              ],
              if (_result != null && !_isLoading) ...[
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _resultFade,
                  child: _buildResultCard(),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CyberTheme.primary.withValues(alpha: 0.08),
            CyberTheme.warning.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CyberTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CyberTheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.link_rounded, color: CyberTheme.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'URL Threat Analysis',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: CyberTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Paste or share a link from Chrome to scan it for phishing, malware, and domain threats.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CyberTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlInputCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFEDED)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5E7EB).withValues(alpha: 0.6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          const Icon(Icons.link_rounded, color: CyberTheme.textMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: CyberTheme.textPrimary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'https://example.com/path?query=value',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: CyberTheme.textMuted,
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _scanUrl(),
            ),
          ),
          // Paste button
          InkWell(
            onTap: _pasteFromClipboard,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: CyberTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.content_paste_rounded, size: 14, color: CyberTheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Paste',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CyberTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Clear button
          if (_urlController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded, size: 18, color: CyberTheme.textMuted),
              onPressed: () => setState(() {
                _urlController.clear();
                _result = null;
                _error = null;
              }),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _scanUrl,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [CyberTheme.primary, const Color(0xFFFF8C42)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: CyberTheme.primary.withValues(
                    alpha: _isLoading ? 0.2 : (0.3 + 0.15 * _pulseController.value),
                  ),
                  blurRadius: _isLoading ? 8 : (14 + 6 * _pulseController.value),
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Scan for Threats',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) => Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CyberTheme.primary.withValues(alpha: 0.08 + 0.06 * _pulseController.value),
            ),
            child: const Icon(Icons.radar_rounded, color: CyberTheme.primary, size: 32),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Analyzing URL…',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: CyberTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Checking domain reputation, structure,\nand threat indicators with Gemini AI.',
          style: GoogleFonts.inter(fontSize: 13, color: CyberTheme.textMuted, height: 1.5),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CyberTheme.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CyberTheme.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: CyberTheme.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: GoogleFonts.inter(fontSize: 13, color: CyberTheme.danger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final result = _result!;
    final score = (result['score'] as num?)?.toInt() ?? 0;
    final isPhishing = result['isPhishing'] == true;
    final verdict = _verdictLabel(result);
    final scoreColor = _scoreColor(score);
    final riskFactors = List<Map<String, dynamic>>.from(result['riskFactors'] ?? []);
    final domainInfo = result['domainInfo'] as Map<String, dynamic>?;
    final explanation = result['explanation']?.toString() ?? '';
    final recommendation = result['recommendation']?.toString() ?? '';
    final redirectWarning = result['redirectWarning']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Score Card ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scoreColor.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: scoreColor.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Verdict badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPhishing ? Icons.dangerous_rounded : score > 35 ? Icons.warning_rounded : Icons.verified_rounded,
                      color: scoreColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      verdict.toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: scoreColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Score ring
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 10,
                      backgroundColor: scoreColor.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '$score',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.bold,
                          fontSize: 34,
                          color: scoreColor,
                        ),
                      ),
                      Text(
                        'Risk Score',
                        style: GoogleFonts.inter(fontSize: 11, color: CyberTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Explanation
              Text(
                explanation,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: CyberTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // ── Domain Info ──────────────────────────────────────
        if (domainInfo != null) ...[
          const SizedBox(height: 16),
          _buildSection(
            icon: Icons.language_rounded,
            title: 'Domain Breakdown',
            child: Column(
              children: [
                _buildInfoRow('Protocol', domainInfo['protocol']?.toString() ?? '—',
                    domainInfo['protocol'] == 'https' ? CyberTheme.success : CyberTheme.danger),
                _buildInfoRow('Host', domainInfo['host']?.toString() ?? '—', CyberTheme.textPrimary),
                if ((domainInfo['path']?.toString() ?? '').isNotEmpty)
                  _buildInfoRow('Path', domainInfo['path'].toString(), CyberTheme.textSecondary),
                if (domainInfo['isIpAddress'] == true)
                  _buildInfoRow('IP Address', 'Yes — suspicious', CyberTheme.danger),
              ],
            ),
          ),
        ],

        // ── Redirect Warning ─────────────────────────────────
        if (redirectWarning != null && redirectWarning.isNotEmpty && redirectWarning != 'null') ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CyberTheme.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CyberTheme.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.swap_horiz_rounded, color: CyberTheme.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Redirect Warning',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: CyberTheme.warning,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        redirectWarning,
                        style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── Risk Factors ─────────────────────────────────────
        if (riskFactors.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSection(
            icon: Icons.flag_rounded,
            title: 'Risk Factors (${riskFactors.length})',
            child: Column(
              children: riskFactors.map((factor) {
                final severity = factor['severity']?.toString() ?? 'low';
                final color = _severityColor(severity);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(_severityIcon(severity), color: color, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              factor['label']?.toString() ?? '',
                              style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: CyberTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              factor['description']?.toString() ?? '',
                              style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textSecondary, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          severity.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: color,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        // ── Recommendation ───────────────────────────────────
        if (recommendation.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CyberTheme.secondary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEFEDED)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, color: CyberTheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommendation',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: CyberTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recommendation,
                        style: GoogleFonts.inter(fontSize: 13, color: CyberTheme.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── Scan Another Button ──────────────────────────────
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _result = null;
              _error = null;
              _urlController.clear();
            });
            _resultController.reset();
          },
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: Text(
            'Scan Another URL',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: CyberTheme.primary,
            side: const BorderSide(color: CyberTheme.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({required IconData icon, required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFEDED)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5E7EB).withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: CyberTheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: CyberTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textMuted),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
