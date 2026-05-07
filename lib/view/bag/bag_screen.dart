import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../utils/constants.dart';

class MyBagScreen extends StatefulWidget {
  const MyBagScreen({Key? key}) : super(key: key);

  @override
  State<MyBagScreen> createState() => _MyBagScreenState();
}

class _MyBagScreenState extends State<MyBagScreen> {
  bool _showFlappyGame = false;

  // Quiz State
  int _currentIndex = 0;
  int _score = 0;
  bool _isAnswered = false;
  bool _wasCorrect = false;

  final List<Map<String, dynamic>> _simulations = [
    {
      "type": "Email",
      "sender": "support-verification@netfIix-billing.com",
      "subject": "Urgent: Subscription Suspension Notice",
      "body": "Dear Subscriber,\n\nWe were unable to process your monthly membership payment. To prevent immediate suspension of your streaming access, please update your billing credentials using the link below within 24 hours.",
      "buttonText": "Update Payment Method",
      "isPhish": true,
      "explanation": "This is a PHISHING email! Look at these massive red flags:\n"
          "• Look-alike domain: 'netfIix' uses a capital 'I' instead of 'l' (netfIix-billing.com).\n"
          "• Severe urgency: 'terminating in 24 hours' is a classic stress tactic to make you act fast.\n"
          "• Deceptive link: 'Update Payment Method' redirects to a fake portal.",
    },
    {
      "type": "Email",
      "sender": "no-reply@accounts.google.com",
      "subject": "Security Alert: New Sign-In Detected",
      "body": "A new sign-in was detected on your Google Account from a Windows 11 PC in Berlin, Germany. If this was you, no action is required. If this wasn't you, please review your device list to secure your account.",
      "buttonText": "Check Activity",
      "isPhish": false,
      "explanation": "This is a LEGITIMATE email!\n"
          "• Genuine domain: Sent from '@accounts.google.com', which is Google's verified domain.\n"
          "• No pressure: It does not ask you to enter sensitive bank details or passwords directly over email.\n"
          "• Informational: Simply informs you of login details and guides you securely inside your account.",
    },
    {
      "type": "SMS",
      "sender": "+1 (888) 542-9901",
      "subject": "Post Office Delivery Alert",
      "body": "USPS ALERT: Your parcel has arrived at our warehouse but is on hold due to an incomplete address. Please complete your street address at: https://usps-address-update.info/redelivery.",
      "buttonText": "Verify Address",
      "isPhish": true,
      "explanation": "This is a PHISHING text (Smishing)!\n"
          "• Unofficial domain: USPS uses '.com', never '.info'.\n"
          "• Fake number: Sent from a generic toll-free number rather than the official USPS shortcode.\n"
          "• Generic scam: Delivery holding scams are extremely common ways to harvest credit cards.",
    }
  ];

  // Pixel-Perfect Audited Flappy Game State Variables
  double birdY = 180;
  double birdVelocity = 0;
  final double gravity = 0.45;
  final double jumpStrength = -7.5;
  
  bool gameHasStarted = false;
  bool gameIsOver = false;
  int flappyScore = 0;
  int flappyHighScore = 0;

  // Barrier layout
  double barrierX = 320;
  final double barrierWidth = 70;
  final double gapHeight = 140;
  double gapYCenter = 200; // Center offset of the gap inside gameBoardHeight

  String currentBarrierText = "HTTPS";
  bool currentBarrierIsSafe = true;

  Timer? gameTimer;

  void _handleChoice(bool userGuessedPhish) {
    if (_isAnswered) return;

    bool correctChoice = (_simulations[_currentIndex]["isPhish"] == userGuessedPhish);

    setState(() {
      _isAnswered = true;
      _wasCorrect = correctChoice;
      if (correctChoice) {
        _score++;
      }
    });
  }

  void _nextSimulation() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _simulations.length;
      _isAnswered = false;
    });
  }

  void _resetQuiz() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _isAnswered = false;
    });
  }

  // Audited Flappy Engine Logic
  void startFlappyGame() {
    if (gameIsOver) {
      resetFlappy();
    }
    setState(() {
      gameHasStarted = true;
      gameIsOver = false;
    });

    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      setState(() {
        // 1. Gravity physics
        birdVelocity += gravity;
        birdY += birdVelocity;

        // 2. Obstacle movement
        barrierX -= 3.2;

        // 3. Recycle obstacle
        if (barrierX < -barrierWidth) {
          barrierX = 340;
          flappyScore++;
          _randomizeBarrier();
        }

        // 4. Floor/Ceiling bounds collision check (400px height board)
        if (birdY < 0 || birdY > 364) {
          _endFlappyGame();
        }

        // 5. Precise bounding box collision check
        // Bird X is fixed at 50px, width is 36px (ranges 50 to 86)
        if (barrierX >= 16 && barrierX <= 86) {
          double gapTop = gapYCenter - gapHeight / 2;
          double gapBottom = gapYCenter + gapHeight / 2;
          
          if (birdY < gapTop || (birdY + 36) > gapBottom) {
            _endFlappyGame();
          }
        }
      });
    });
  }

  void _endFlappyGame() {
    gameTimer?.cancel();
    setState(() {
      gameIsOver = true;
      gameHasStarted = false;
      if (flappyScore > flappyHighScore) {
        flappyHighScore = flappyScore;
      }
    });
  }

  void jump() {
    setState(() {
      birdVelocity = jumpStrength;
    });
  }

  void _randomizeBarrier() {
    final rand = Random();
    // Choose random gap center (bounds between 100 and 300)
    gapYCenter = 100 + rand.nextDouble() * 200;

    // Alternate safe and malicious gateways
    final labels = [
      {"text": "HTTPS", "safe": true},
      {"text": "MFA SECURE", "safe": true},
      {"text": "HTTP OPEN", "safe": false},
      {"text": "PHISH LINK", "safe": false},
      {"text": "STRONG PASS", "safe": true},
      {"text": "MALWARE", "safe": false},
    ];

    final chosen = labels[rand.nextInt(labels.length)];
    currentBarrierText = chosen["text"] as String;
    currentBarrierIsSafe = chosen["safe"] as bool;
  }

  void resetFlappy() {
    setState(() {
      birdY = 180;
      birdVelocity = 0;
      barrierX = 320;
      gapYCenter = 200;
      currentBarrierText = "HTTPS";
      currentBarrierIsSafe = true;
      gameHasStarted = false;
      gameIsOver = false;
      flappyScore = 0;
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstantsColor.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Icon(
              _showFlappyGame ? CupertinoIcons.gamecontroller_fill : CupertinoIcons.shield_fill,
              color: AppConstantsColor.primaryColor,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              _showFlappyGame ? "Cyber Flap" : "Phish Simulator",
              style: const TextStyle(
                fontFamily: 'Quicksand',
                color: AppConstantsColor.darkTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showFlappyGame = !_showFlappyGame;
                if (!_showFlappyGame) {
                  gameTimer?.cancel();
                  resetFlappy();
                }
              });
            },
            icon: Icon(
              _showFlappyGame ? CupertinoIcons.square_list_fill : CupertinoIcons.gamecontroller_fill,
              color: AppConstantsColor.primaryColor,
              size: 20,
            ),
            label: Text(
              _showFlappyGame ? "Quiz Mode" : "Flappy Mode",
              style: const TextStyle(
                color: AppConstantsColor.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: _showFlappyGame ? _buildFlappyGameView() : _buildQuizView(),
    );
  }

  // Quiz View (Without Emojis)
  Widget _buildQuizView() {
    final sim = _simulations[_currentIndex];
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Simulation Scenario ${_currentIndex + 1}",
                style: const TextStyle(
                  color: AppConstantsColor.darkTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstantsColor.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppConstantsColor.primaryColor, width: 1),
                ),
                child: Text(
                  "Score: $_score/${_simulations.length}",
                  style: const TextStyle(
                    color: AppConstantsColor.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Inspect the message below. Decide if it is phishing or legitimate.",
            style: TextStyle(
              color: AppConstantsColor.lightTextColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          // Message Mockup Box
          Container(
            decoration: BoxDecoration(
              color: AppConstantsColor.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppConstantsColor.unSelectedTextColor,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mock Headers
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppConstantsColor.unSelectedTextColor.withOpacity(0.2),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            sim["type"] == "Email" ? CupertinoIcons.mail_solid : CupertinoIcons.chat_bubble_fill,
                            size: 14,
                            color: AppConstantsColor.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            sim["type"].toUpperCase(),
                            style: const TextStyle(
                              color: AppConstantsColor.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(fontFamily: 'Quicksand', fontSize: 13),
                          children: [
                            const TextSpan(
                              text: "From: ",
                              style: TextStyle(color: AppConstantsColor.lightTextColor, fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: sim["sender"],
                              style: const TextStyle(color: AppConstantsColor.darkTextColor),
                            ),
                          ],
                        ),
                      ),
                      if (sim["type"] == "Email") ...[
                        const SizedBox(height: 6),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(fontFamily: 'Quicksand', fontSize: 13),
                            children: [
                              const TextSpan(
                                text: "Subject: ",
                                style: TextStyle(color: AppConstantsColor.lightTextColor, fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: sim["subject"],
                                style: const TextStyle(color: AppConstantsColor.darkTextColor, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Message Body
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sim["body"],
                        style: const TextStyle(
                          color: AppConstantsColor.darkTextColor,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppConstantsColor.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppConstantsColor.primaryColor.withOpacity(0.5), width: 1),
                          ),
                          child: Center(
                            child: Text(
                              sim["buttonText"],
                              style: const TextStyle(
                                color: AppConstantsColor.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // User Choices or Results Explanations
          if (!_isAnswered) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleChoice(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstantsColor.dangerColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 18),
                    label: const Text(
                      "Report Phish",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleChoice(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstantsColor.secondaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(CupertinoIcons.checkmark_circle_fill, size: 18),
                    label: const Text(
                      "Legit Message",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _wasCorrect
                    ? AppConstantsColor.secondaryColor.withOpacity(0.1)
                    : AppConstantsColor.dangerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _wasCorrect ? AppConstantsColor.secondaryColor : AppConstantsColor.dangerColor,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        _wasCorrect ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.xmark_circle_fill,
                        color: _wasCorrect ? AppConstantsColor.secondaryColor : AppConstantsColor.dangerColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _wasCorrect ? "Correct Choice" : "Incorrect Choice",
                        style: TextStyle(
                          color: _wasCorrect ? AppConstantsColor.secondaryColor : AppConstantsColor.dangerColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    sim["explanation"],
                    style: const TextStyle(
                      color: AppConstantsColor.darkTextColor,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_currentIndex == _simulations.length - 1) ...[
                        TextButton.icon(
                          onPressed: _resetQuiz,
                          icon: const Icon(CupertinoIcons.refresh_bold, color: AppConstantsColor.primaryColor, size: 16),
                          label: const Text(
                            "Restart Quiz",
                            style: TextStyle(color: AppConstantsColor.primaryColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ] else ...[
                        ElevatedButton.icon(
                          onPressed: _nextSimulation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstantsColor.primaryColor,
                            foregroundColor: AppConstantsColor.backgroundColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          icon: const Icon(CupertinoIcons.arrow_right, size: 16),
                          label: const Text(
                            "Next Scenario",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Audited Pixel-Perfect Flappy Game Board
  Widget _buildFlappyGameView() {
    return Column(
      children: [
        // Live Scoreboard
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          color: AppConstantsColor.cardColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Score: $flappyScore",
                style: const TextStyle(color: AppConstantsColor.darkTextColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                "High Score: $flappyHighScore",
                style: const TextStyle(color: AppConstantsColor.primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),

        // Game Area Layout Board (Exactly 400px fixed playable canvas for consistent hitboxes)
        Expanded(
          child: Center(
            child: Container(
              width: double.infinity,
              height: 400,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstantsColor.cardColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppConstantsColor.unSelectedTextColor.withOpacity(0.5)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) {
                    if (gameIsOver) {
                      resetFlappy();
                    } else if (!gameHasStarted) {
                      startFlappyGame();
                      jump();
                    } else {
                      jump();
                    }
                  },
                  child: Stack(
                    children: [
                      // Render Barriers (Gates) using precise layout variables
                      // Upper Barrier
                      Positioned(
                        left: barrierX,
                        top: 0,
                        child: _buildPixelBarrier(gapYCenter - gapHeight / 2, currentBarrierIsSafe ? AppConstantsColor.primaryColor : AppConstantsColor.dangerColor, currentBarrierText, true),
                      ),
                      // Lower Barrier
                      Positioned(
                        left: barrierX,
                        top: gapYCenter + gapHeight / 2,
                        child: _buildPixelBarrier(400 - (gapYCenter + gapHeight / 2), currentBarrierIsSafe ? AppConstantsColor.primaryColor : AppConstantsColor.dangerColor, currentBarrierIsSafe ? "SAFE GATE" : "MALICIOUS", false),
                      ),

                      // Render Bird (Security Shield) - Fixed X at 50px, width/height is 36px
                      Positioned(
                        left: 50,
                        top: birdY,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: currentBarrierIsSafe ? AppConstantsColor.primaryColor : AppConstantsColor.warningColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppConstantsColor.primaryColor.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.shield_fill,
                            color: AppConstantsColor.backgroundColor,
                            size: 20,
                          ),
                        ),
                      ),

                      // Pre-game instructional tap-overlay
                      if (!gameHasStarted && !gameIsOver)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.symmetric(horizontal: 32),
                            decoration: BoxDecoration(
                              color: AppConstantsColor.cardColor.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppConstantsColor.primaryColor.withOpacity(0.3)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(CupertinoIcons.gamecontroller, color: AppConstantsColor.primaryColor, size: 36),
                                const SizedBox(height: 8),
                                const Text(
                                  "Tap to Fly",
                                  style: TextStyle(
                                    color: AppConstantsColor.darkTextColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Fly through secure gates and avoid red malicious domains to survive",
                                  style: TextStyle(
                                    color: AppConstantsColor.lightTextColor,
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Crash Game Over Sheet
                      if (gameIsOver)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: AppConstantsColor.cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppConstantsColor.dangerColor, width: 1.5),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(CupertinoIcons.xmark_circle_fill, color: AppConstantsColor.dangerColor, size: 24),
                                    SizedBox(width: 8),
                                    Text(
                                      "Security Breached",
                                      style: TextStyle(
                                        color: AppConstantsColor.dangerColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Lesson Learned:\n"
                                  "Avoid unencrypted protocols like HTTP and suspicious domains. "
                                  "Secure protocols like HTTPS and Multi-Factor Authentication (MFA) keep your credentials safe from sniffing attacks.",
                                  style: TextStyle(
                                    color: AppConstantsColor.darkTextColor,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: startFlappyGame,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppConstantsColor.primaryColor,
                                    foregroundColor: AppConstantsColor.backgroundColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  icon: const Icon(CupertinoIcons.refresh, size: 16),
                                  label: const Text("Tap to Try Again", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Render precise barrier shapes with exact bounding pixels
  Widget _buildPixelBarrier(double height, Color color, String label, bool isTop) {
    return Container(
      width: barrierWidth,
      height: height,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.only(
          bottomLeft: isTop ? const Radius.circular(8) : Radius.zero,
          bottomRight: isTop ? const Radius.circular(8) : Radius.zero,
          topLeft: !isTop ? const Radius.circular(8) : Radius.zero,
          topRight: !isTop ? const Radius.circular(8) : Radius.zero,
        ),
      ),
      child: Center(
        child: RotatedBox(
          quarterTurns: 1,
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
