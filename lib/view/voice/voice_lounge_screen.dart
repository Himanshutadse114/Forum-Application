import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class VoiceLoungeScreen extends StatefulWidget {
  @override
  _VoiceLoungeScreenState createState() => _VoiceLoungeScreenState();
}

class _VoiceLoungeScreenState extends State<VoiceLoungeScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _connectedChannel;

  // Discord Palette
  final Color _discordDarkBg = const Color(0xFF1E1F22);
  final Color _discordChannelBg = const Color(0xFF2B2D31);
  final Color _discordBlurple = const Color(0xFF5865F2);
  final Color _discordGreen = const Color(0xFF23A55A);
  final Color _discordRed = const Color(0xFFF23F43);

  final List<Map<String, String>> _channels = [
    {
      "name": "cybersecurity-lounge",
      "room": "InnviktaCybersecurityLounge",
      "topic": "General chit-chat about ethical hacking"
    },
    {
      "name": "threat-intel",
      "room": "InnviktaThreatIntelSharing",
      "topic": "Live discussion on active phishing targets"
    },
    {
      "name": "phishing-discussions",
      "room": "InnviktaPhishingDiscussions",
      "topic": "Solving capture-the-flag rooms together"
    },
  ];

  @override
  void initState() {
    super.initState();
    _initWebViewController();
  }

  void _initWebViewController() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserActionForPlayback: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(_discordDarkBg)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("WebView Error: ${error.description}");
          },
        ),
      );

    // CRITICAL: Automatically grant microphone & audio permission requests inside the Android WebView!
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController).setPermissionRequestHandler(
        (AndroidWebViewPermissionRequest request) async {
          return AndroidWebViewPermissionDecision.grant;
        },
      );
    }

    _controller = controller;
  }

  void _joinChannel(String channelName, String roomName) {
    setState(() {
      _connectedChannel = channelName;
      _isLoading = true;
    });

    // Generate real audio-only, direct Jitsi room link with no landing page
    final String cleanUrl = "https://meet.jit.si/$roomName"
        "#config.startWithVideoMuted=true"
        "&config.startWithAudioMuted=false"
        "&config.prejoinPageEnabled=false"
        "&config.welcomePageEnabled=false"
        "&config.toolbarButtons=[\"microphone\",\"hangup\",\"tileview\"]";

    _controller.loadRequest(Uri.parse(cleanUrl));
  }

  void _disconnect() {
    _controller.loadRequest(Uri.parse("about:blank"));
    setState(() {
      _connectedChannel = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _discordDarkBg,
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.discord, color: _discordBlurple, size: 28),
              const SizedBox(width: 10),
              Text(
                _connectedChannel != null
                    ? '#$_connectedChannel'
                    : 'CYBERSHIELD LOUNGE',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: _discordChannelBg,
        elevation: 4,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            _disconnect();
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Connection Status Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: _connectedChannel != null ? _discordGreen.withOpacity(0.1) : Colors.black12,
            child: Center(
              child: Text(
                _connectedChannel != null
                    ? 'Connected Real-Time to #$_connectedChannel'
                    : 'Select a Voice Channel to talk to real users',
                style: TextStyle(
                  color: _connectedChannel != null ? _discordGreen : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          // Main View (Lobby vs Real Call Webview)
          Expanded(
            child: _connectedChannel == null
                ? _buildChannelLobby()
                : _buildActiveCallWebview(),
          ),
        ],
      ),
    );
  }

  // Lobby - Select Channel Screen
  Widget _buildChannelLobby() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ACTIVE REAL-TIME CHANNELS',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
          ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _channels.length,
              itemBuilder: (context, index) {
                final channel = _channels[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    onTap: () => _joinChannel(channel['name']!, channel['room']!),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _discordChannelBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _discordBlurple.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.volume_up_rounded, color: _discordBlurple, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '#${channel['name']!}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  channel['topic']!,
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Active Call Real Webview View
  Widget _buildActiveCallWebview() {
    return Stack(
      children: [
        // The real WebRTC audio call webpage
        WebViewWidget(controller: _controller),

        // Beautiful loading indicator
        if (_isLoading)
          Container(
            color: _discordDarkBg,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _discordBlurple),
                  const SizedBox(height: 16),
                  const Text(
                    "Connecting to Real-Time Voice Channel...",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

        // Beautiful Discord floating disconnect panel
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _discordChannelBg,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Connected Live',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: _disconnect,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _discordRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.call_end, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
