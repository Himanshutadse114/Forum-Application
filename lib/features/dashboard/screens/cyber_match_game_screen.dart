import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cybershield_forum/core/theme.dart';
import 'package:cybershield_forum/features/auth/provider.dart';

class CyberMatchGameScreen extends ConsumerStatefulWidget {
  const CyberMatchGameScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CyberMatchGameScreen> createState() => _CyberMatchGameScreenState();
}

class _CyberMatchGameScreenState extends ConsumerState<CyberMatchGameScreen> {
  late final WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(CyberTheme.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterGameChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _handleGameMessage(message.message);
        },
      )
      ..loadFlutterAsset('assets/matcher-game/index.html');
  }

  Future<void> _handleGameMessage(String messageJson) async {
    try {
      final Map<String, dynamic> data = jsonDecode(messageJson);
      final action = data['action'];

      if (action == 'submitScore') {
        final score = int.tryParse(data['score'].toString()) ?? 0;
        if (score > 0) {
          final success = await ref.read(authProvider.notifier).submitGameScore('cyber_match', score);
          if (success) {
            _showScoreSnackbar(score);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to save score to database!'), backgroundColor: Colors.red),
              );
            }
          }
        }
      } else if (action == 'closeGame') {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      }
    } catch (e) {
      debugPrint('Error parsing game channel message: $e');
    }
  }

  void _showScoreSnackbar(int score) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SECURITY SCORE RECORDED!',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '+$score Reputation XP added to your profile.',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _webViewController),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: CyberTheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
