import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class VoiceLoungeScreen extends StatefulWidget {
  @override
  _VoiceLoungeScreenState createState() => _VoiceLoungeScreenState();
}

class _VoiceLoungeScreenState extends State<VoiceLoungeScreen> {
  final String _roomName = "InnviktaVoiceLounge";

  Future<void> _joinMeeting() async {
    final Uri url = Uri.parse("https://meet.jit.si/$_roomName");
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open voice lounge: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'INNVIKTA LOUNGE',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Beautiful minimalist orange-and-white styled circle
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.15),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic,
                  size: 80,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Global Voice Chat Room',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Connect with other security professionals and learn in real-time. Completely free, unlimited, and P2P-powered voice calls.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _joinMeeting,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 3,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.headset_mic, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'Join Live Audio Lounge',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
