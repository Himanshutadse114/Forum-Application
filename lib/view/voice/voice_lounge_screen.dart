import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class VoiceLoungeScreen extends StatefulWidget {
  @override
  _VoiceLoungeScreenState createState() => _VoiceLoungeScreenState();
}

class _VoiceLoungeScreenState extends State<VoiceLoungeScreen> with TickerProviderStateMixin {
  // Navigation & Voice States
  String? _connectedChannel;
  bool _isMuted = false;
  bool _isDeafened = false;
  bool _isSpeakerOn = true;
  String _connectionStatus = "Disconnected";
  int _ping = 24;

  // Active Users list
  final List<Map<String, dynamic>> _channelUsers = [
    {"name": "Himanshu (You)", "avatar": "H", "color": Colors.purple, "isSpeaking": false, "isMuted": false},
    {"name": "Alex_Sec", "avatar": "A", "color": Colors.orange, "isSpeaking": true, "isMuted": false},
    {"name": "Sarah_Ethical", "avatar": "S", "color": Colors.teal, "isSpeaking": false, "isMuted": false},
    {"name": "Root_Admin", "avatar": "R", "color": Colors.red, "isSpeaking": false, "isMuted": true},
    {"name": "Cyber_Ghost", "avatar": "G", "color": Colors.indigo, "isSpeaking": false, "isMuted": false},
  ];

  // Animation Controllers for visualizer & pulsing avatars
  late AnimationController _waveController;
  Timer? _speakingTimer;
  Timer? _pingTimer;

  // Discord Color Palette
  final Color _discordDarkBg = const Color(0xFF1E1F22);
  final Color _discordChannelBg = const Color(0xFF2B2D31);
  final Color _discordCardBg = const Color(0xFF313338);
  final Color _discordBlurple = const Color(0xFF5865F2);
  final Color _discordGreen = const Color(0xFF23A55A);
  final Color _discordRed = const Color(0xFFF23F43);

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Start simulated speaking updates
    _speakingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_connectedChannel != null && !_isDeafened) {
        setState(() {
          final random = Random();
          // Update who is currently speaking
          for (var i = 1; i < _channelUsers.length; i++) {
            if (!_channelUsers[i]['isMuted']!) {
              _channelUsers[i]['isSpeaking'] = random.nextBool();
            }
          }
          // User speaking logic
          _channelUsers[0]['isSpeaking'] = !_isMuted && random.nextBool();
        });
      }
    });

    // Simulated ping fluctuations
    _pingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_connectedChannel != null) {
        setState(() {
          _ping = 18 + Random().nextInt(15);
        });
      }
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _speakingTimer?.cancel();
    _pingTimer?.cancel();
    super.dispose();
  }

  void _joinChannel(String channelName) {
    setState(() {
      _connectionStatus = "Connecting...";
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _connectedChannel = channelName;
        _connectionStatus = "RTC Connected";
        _channelUsers[0]['isMuted'] = _isMuted;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Joined $channelName voice channel'),
          backgroundColor: _discordGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  void _disconnect() {
    if (_connectedChannel == null) return;
    final oldChannel = _connectedChannel;
    setState(() {
      _connectedChannel = null;
      _connectionStatus = "Disconnected";
      for (var user in _channelUsers) {
        user['isSpeaking'] = false;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Left $oldChannel'),
        backgroundColor: _discordRed,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _discordDarkBg,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.discord, color: _discordBlurple, size: 28),
            const SizedBox(width: 10),
            const Text(
              'CYBERSHIELD CHAT',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.1,
              ),
            ),
          ],
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
        actions: [
          if (_connectedChannel != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _discordGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _discordGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _discordGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_ping}ms',
                      style: TextStyle(
                        color: _discordGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
                    ? 'Connected to $_connectedChannel'
                    : 'Select a Voice Channel to Join',
                style: TextStyle(
                  color: _connectedChannel != null ? _discordGreen : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          // Main Content
          Expanded(
            child: _connectedChannel == null ? _buildChannelLobby() : _buildActiveVoiceRoom(),
          ),

          // Custom Discord Bottom Control Deck
          if (_connectedChannel != null) _buildBottomControlDeck(),
        ],
      ),
    );
  }

  // Lobby - Select Channel Screen
  Widget _buildChannelLobby() {
    final channels = [
      {"name": "Cybersecurity Lounge", "topic": "General chit-chat about ethical hacking", "count": 4},
      {"name": "Threat Intel Sharing", "topic": "Live discussion on active phishing targets", "count": 2},
      {"name": "CTF Walkthroughs", "topic": "Solving capture-the-flag rooms together", "count": 0},
      {"name": "Incident Response", "topic": "Urgent security response room", "count": 1},
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ACTIVE VOICE CHANNELS',
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
              itemCount: channels.length,
              itemBuilder: (context, index) {
                final channel = channels[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    onTap: () => _joinChannel(channel['name'] as String),
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
                                  channel['name'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  channel['topic'] as String,
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.people_alt, color: Colors.grey, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${channel['count']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
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

  // Active Discord Voice Call View
  Widget _buildActiveVoiceRoom() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Grid layout of active users in call
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.9,
              ),
              itemCount: _channelUsers.length,
              itemBuilder: (context, index) {
                final user = _channelUsers[index];
                final bool isSpeaking = user['isSpeaking'] && !_isDeafened;
                final bool isMuted = user['isMuted'];

                return Container(
                  decoration: BoxDecoration(
                    color: _discordChannelBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSpeaking ? _discordGreen : Colors.white10,
                      width: isSpeaking ? 3 : 1,
                    ),
                    boxShadow: isSpeaking
                        ? [
                            BoxShadow(
                              color: _discordGreen.withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      // Avatar & Pulsing Glow centered
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.all(isSpeaking ? 4 : 0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSpeaking ? _discordGreen : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 36,
                                backgroundColor: user['color'] as Color,
                                child: Text(
                                  user['avatar'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              user['name'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // User status icon (speaking / muted)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Row(
                          children: [
                            if (isMuted)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _discordRed,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.mic_off, color: Colors.white, size: 14),
                              ),
                            if (isSpeaking)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _discordGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.volume_up, color: Colors.white, size: 14),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Real-time Sound Wave simulation
          if (!_isMuted && !_isDeafened)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(8, (index) {
                  return AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      final waveValue = sin((_waveController.value * 2 * pi) + (index * 0.5));
                      final height = 10 + (waveValue.abs() * 25);
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 4,
                        height: height,
                        decoration: BoxDecoration(
                          color: _discordGreen,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  // Discord control bar deck
  Widget _buildBottomControlDeck() {
    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 36, top: 20),
      decoration: BoxDecoration(
        color: _discordChannelBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute Button
          _buildDeckButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            label: _isMuted ? 'Unmute' : 'Mute',
            color: _isMuted ? _discordRed : _discordCardBg,
            iconColor: Colors.white,
            onTap: () {
              setState(() {
                _isMuted = !_isMuted;
                _channelUsers[0]['isMuted'] = _isMuted;
              });
            },
          ),

          // Deafen Button
          _buildDeckButton(
            icon: _isDeafened ? Icons.headset_off : Icons.headset,
            label: _isDeafened ? 'Undeafen' : 'Deafen',
            color: _isDeafened ? _discordRed : _discordCardBg,
            iconColor: Colors.white,
            onTap: () {
              setState(() {
                _isDeafened = !_isDeafened;
              });
            },
          ),

          // Speaker Button
          _buildDeckButton(
            icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
            label: 'Speaker',
            color: _isSpeakerOn ? _discordBlurple : _discordCardBg,
            iconColor: Colors.white,
            onTap: () {
              setState(() {
                _isSpeakerOn = !_isSpeakerOn;
              });
            },
          ),

          // Red End Call Button
          _buildDeckButton(
            icon: Icons.call_end,
            label: 'Disconnect',
            color: _discordRed,
            iconColor: Colors.white,
            onTap: _disconnect,
          ),
        ],
      ),
    );
  }

  Widget _buildDeckButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
