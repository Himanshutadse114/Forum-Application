import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:cybershield_forum/core/theme.dart';
import 'package:cybershield_forum/core/router.dart';
import 'package:cybershield_forum/features/anti_fraud/services/local_apk_scanner.dart';

class GlobalChannelHandler {
  static const _channel = MethodChannel('app.channel.shared.data');
  static bool _isInitialized = false;

  static void init() {
    if (_isInitialized) return;
    _isInitialized = true;

    // Listen to all MethodChannel calls globally
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'packageAdded':
          final String? packageName = call.arguments as String?;
          if (packageName != null) {
            _handleAutoScan(packageName);
          }
          break;
        case 'sharedTextReceived':
          final String? sharedText = call.arguments as String?;
          if (sharedText != null && sharedText.isNotEmpty) {
            _handleSharedText(sharedText);
          }
          break;
      }
      return null;
    });

    // Check for startup shared URL after GoRouter finishes initialization
    Future.delayed(const Duration(milliseconds: 800), () async {
      try {
        final sharedText = await _channel.invokeMethod<String>('getSharedText');
        if (sharedText != null && sharedText.isNotEmpty) {
          _handleSharedText(sharedText);
        }
      } catch (e) {
        debugPrint('Global failed to check startup shared text: $e');
      }
    });
  }

  static void _handleSharedText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final urlRegex = RegExp(
      r'(https?:\/\/[^\s]+)',
      caseSensitive: false,
    );
    final match = urlRegex.firstMatch(trimmed);
    String? url;
    if (match != null) {
      url = match.group(0);
    } else {
      final domainRegex = RegExp(
        r'^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(\/[^\s]*)?$',
        caseSensitive: false,
      );
      if (domainRegex.hasMatch(trimmed)) {
        url = trimmed;
      }
    }

    if (url != null) {
      // Use the global navigator context to navigate
      final context = cyberNavigatorKey.currentContext;
      if (context != null) {
        GoRouter.of(context).push('/link-scanner?url=${Uri.encodeComponent(url)}');
      }
    }
  }

  static Future<void> _handleAutoScan(String packageName) async {
    try {
      final appInfo = await InstalledApps.getAppInfo(packageName, BuiltWith.native_or_others);
      if (appInfo == null) return;
      final appName = appInfo.name ?? packageName;
      final iconBytes = appInfo.icon;

      final String? apkPath = await _channel.invokeMethod<String>(
        'getApkPath',
        {'packageName': packageName},
      );
      if (apkPath == null || apkPath.isEmpty) return;

      final meta = await LocalApkScanner.parseApk(apkPath);
      final scanResult = LocalApkScanner.scanMetadata(meta);

      final context = cyberNavigatorKey.currentContext;
      if (context != null) {
        _showAdvisoryAlert(context, appName, packageName, scanResult, iconBytes);
      }
    } catch (e) {
      debugPrint('Global auto-scan failed: $e');
    }
  }

  static void _showAdvisoryAlert(
    BuildContext context,
    String appName,
    String packageName,
    Map<String, dynamic> result,
    Uint8List? iconBytes,
  ) {
    final score = (result['score'] as num?)?.toInt() ?? 0;
    final hasFlags = score >= 20;
    final riskFlags = List<Map<String, dynamic>>.from(result['riskFlags'] ?? []);
    final recommendation = result['recommendation']?.toString() ?? '';

    // Only show the dialog if there are structural flags worth noting
    if (!hasFlags) return;

    final Color alertColor = score >= 60 ? CyberTheme.danger : CyberTheme.warning;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ────────────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: alertColor.withOpacity(0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.security_rounded, color: alertColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Security Advisory',
                              style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: CyberTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Newly installed app detected',
                              style: GoogleFonts.inter(fontSize: 11, color: CyberTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── App identity card ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: CyberTheme.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEFEDED)),
                    ),
                    child: Row(
                      children: [
                        if (iconBytes != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(iconBytes, width: 42, height: 42, fit: BoxFit.contain),
                          )
                        else
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: alertColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.android_rounded, color: alertColor, size: 24),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appName,
                                style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: CyberTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                packageName,
                                style: GoogleFonts.inter(fontSize: 10, color: CyberTheme.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Notice banner ─────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: alertColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: alertColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: alertColor, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Structural Characteristics Detected',
                              style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: CyberTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'A quick scan found ${riskFlags.length} structural characteristic(s) worth reviewing in this app. This is based on code structure only and does not confirm any threat.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: CyberTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Top flags (max 2) ──────────────────────────────────────
                  if (riskFlags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...riskFlags.take(2).map((flag) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.chevron_right_rounded,
                                color: CyberTheme.textMuted, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                flag['flag']?.toString() ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: CyberTheme.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  // ── Advisory tip ──────────────────────────────────────────
                  if (recommendation.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CyberTheme.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEFEDED)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_outline_rounded,
                              color: CyberTheme.primary, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              recommendation,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: CyberTheme.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── Buttons: Dismiss + Open Auditor (NO uninstall) ─────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: CyberTheme.textSecondary,
                            side: const BorderSide(color: Color(0xFFEFEDED)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Dismiss',
                            style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            GoRouter.of(context).push('/apk-scanner');
                          },
                          icon: const Icon(Icons.search_rounded,
                              size: 16, color: Colors.white),
                          label: Text(
                            'Open Auditor',
                            style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CyberTheme.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
