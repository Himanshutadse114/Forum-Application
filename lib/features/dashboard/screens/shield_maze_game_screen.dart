import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cybershield_forum/core/theme.dart';
import 'package:cybershield_forum/features/auth/provider.dart';

class ShieldMazeGameScreen extends ConsumerStatefulWidget {
  const ShieldMazeGameScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ShieldMazeGameScreen> createState() => _ShieldMazeGameScreenState();
}

class _ShieldMazeGameScreenState extends ConsumerState<ShieldMazeGameScreen> {
  late final WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFBF9F8)) // Matches the bright off-white theme
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // SCORM API is now injected directly in index.html to ensure it's available immediately.
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
      );

    _loadGameAssets();
  }

  Future<void> _loadGameAssets() async {
    try {
      await _webViewController.loadFlutterAsset('assets/shieldmaze/index.html');
    } catch (e) {
      debugPrint('Error loading Shield Maze asset: $e');
    }
  }

  Future<void> _handleGameMessage(String messageJson) async {
    try {
      final Map<String, dynamic> data = jsonDecode(messageJson);
      final action = data['action'];

      if (action == 'submitScore') {
        final score = int.tryParse(data['score'].toString()) ?? 0;
        if (score > 0) {
          final success = await ref.read(authProvider.notifier).submitGameScore('shield_maze', score);
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
      }
    } catch (e) {
      debugPrint('Error parsing shield maze channel message: $e');
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
                    'SHIELD MAZE SCORE RECORDED!',
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
        backgroundColor: const Color(0xFFFF6B00),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _webViewController),
            
            // Floating Close Button (Arcade style)
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.close_rounded,
                      color: Color(0xFF1B1C1C),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),

            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF6B00), // Primary vibrant orange
                ),
              ),
          ],
        ),
      ),
    );
  }
}
