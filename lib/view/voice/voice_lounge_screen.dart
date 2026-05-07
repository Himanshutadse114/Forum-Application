import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

class VoiceLoungeScreen extends StatefulWidget {
  @override
  _VoiceLoungeScreenState createState() => _VoiceLoungeScreenState();
}

class _VoiceLoungeScreenState extends State<VoiceLoungeScreen> {
  final JitsiMeet _jitsiMeet = JitsiMeet();
  final String _roomName = "Innvikta_Secure_Voice_Lounge_Room";

  void _joinMeeting() {
    var options = JitsiMeetConferenceOptions(
      serverURL: "https://meet.jit.si",
      room: _roomName,
      configOverrides: {
        "startWithAudioMuted": false,
        "startWithVideoMuted": true,
        "prejoinPageEnabled": false,
        "videoMuted": true,
      },
      featureFlags: {
        "unsaferoomwarning.enabled": false,
        "chat.enabled": false,
        "video-share.enabled": false,
        "invite.enabled": false,
      },
      userInfo: JitsiMeetUserInfo(
        displayName: "Innvikta User",
      ),
    );

    _jitsiMeet.join(options);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
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
                child: Icon(
                  Icons.mic,
                  size: 80,
                  color: Colors.orange,
                ),
              ),
              SizedBox(height: 40),
              Text(
                'Global Voice Chat Room',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Connect with other security professionals and learn in real-time. Completely free, unlimited, and P2P-powered voice calls.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 48),
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
                    children: [
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
