import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cybershield_forum/core/theme.dart';
import 'package:cybershield_forum/core/hive_box.dart';
import 'package:cybershield_forum/features/anti_fraud/services/gemini_service.dart';
import 'package:cybershield_forum/features/reports/provider.dart';

class SentinelCoachScreen extends ConsumerStatefulWidget {
  const SentinelCoachScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SentinelCoachScreen> createState() => _SentinelCoachScreenState();
}

class _SentinelCoachScreenState extends ConsumerState<SentinelCoachScreen> with TickerProviderStateMixin {
  final GeminiService _geminiService = GeminiService();
  
  bool _isLoading = false;
  Map<String, dynamic>? _briefingData;
  String? _error;
  // Live task statuses always read directly from Hive — never from cache
  List<Map<String, dynamic>> _liveTaskStatuses = [];
  
  late final AnimationController _avatarController;
  late final Animation<double> _avatarAnimation;

  /// Computes task statuses fresh from local storage every time
  List<Map<String, dynamic>> _computeLiveTaskStatuses() {
    final scanResults = HiveBoxHelper.getScanResults();
    // Count saved audit results (apps audited from installed list)
    final savedAuditCount = scanResults.values
        .where((v) => v['isOffline'] != true)
        .length;
    // Also check the counter (tracks search-tab audits + all new audits)
    final counterAuditCount = HiveBoxHelper.getScanCount('app');
    // Use whichever is larger — avoids undercounting from either source
    final appAuditCount = savedAuditCount > counterAuditCount
        ? savedAuditCount
        : counterAuditCount;

    final smsScanCount = HiveBoxHelper.getScanCount('sms');
    final emailScanCount = HiveBoxHelper.getScanCount('email');
    final linkScanCount = HiveBoxHelper.getScanCount('link');

    return [
      {
        'task': 'App Reputation Audits',
        'status': appAuditCount > 0 ? 'COMPLETED' : 'PENDING',
        'detail': appAuditCount > 0
            ? '$appAuditCount app(s) audited'
            : 'No apps audited yet',
      },
      {
        'task': 'SMS Phishing Scan',
        'status': smsScanCount > 0 ? 'COMPLETED' : 'PENDING',
        'detail': smsScanCount > 0 ? '$smsScanCount scan(s) completed' : 'No SMS scans run yet',
      },
      {
        'task': 'Email Security Scan',
        'status': emailScanCount > 0 ? 'COMPLETED' : 'PENDING',
        'detail': emailScanCount > 0 ? '$emailScanCount scan(s) completed' : 'No email scans run yet',
      },
      {
        'task': 'Link / URL Verification',
        'status': linkScanCount > 0 ? 'COMPLETED' : 'PENDING',
        'detail': linkScanCount > 0 ? '$linkScanCount link(s) verified' : 'No links verified yet',
      },
    ];
  }
  
  @override
  void initState() {
    super.initState();
    
    // Avatar breathing pulse
    _avatarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _avatarAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _avatarController, curve: Curves.easeInOut),
    );

    // Compute live task statuses immediately from Hive (always fresh)
    _liveTaskStatuses = _computeLiveTaskStatuses();

    // Load cached briefing text/recommendations for instant display
    final cached = HiveBoxHelper.getLatestBriefing();
    if (cached != null) {
      _briefingData = cached;
    }
    // Always refresh in background so counts stay up to date
    Future.microtask(() => _fetchBriefing());
  }
  
  @override
  void dispose() {
    _avatarController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchBriefing() async {
    // Refresh live task statuses immediately before any async call
    if (mounted) {
      setState(() {
        _liveTaskStatuses = _computeLiveTaskStatuses();
        _isLoading = true;
        _error = null;
      });
    }
    
    try {
      // 1. Gather stats — use max of saved results vs counter for accuracy
      final scanResults = HiveBoxHelper.getScanResults();
      final savedAuditCount = scanResults.values
          .where((v) => v['isOffline'] != true)
          .length;
      final counterAuditCount = HiveBoxHelper.getScanCount('app');
      final appAuditCount = savedAuditCount > counterAuditCount
          ? savedAuditCount
          : counterAuditCount;
      final suspiciousAppsCount = scanResults.values
          .where((v) => v['isOffline'] != true && v['verdict'] != 'Clean')
          .length;

      final smsScanCount = HiveBoxHelper.getScanCount('sms');
      final emailScanCount = HiveBoxHelper.getScanCount('email');
      final linkScanCount = HiveBoxHelper.getScanCount('link');
      
      // 2. Gather threats ledger items
      final threatFeed = ref.read(threatFeedProvider);
      final threats = threatFeed.value?.map((e) => e.title).toList() ?? [
        'GoldPickaxe Android Trojan active',
        'WebRTC protocol zero-day vulnerability patched',
        'Fake postal delivery SMS scams rising'
      ];
      
      // 3. Call Gemini
      final response = await _geminiService.generateSentinelBriefing(
        deviceBrand: 'Samsung / Android',
        auditedAppsCount: appAuditCount,
        totalAppsCount: appAuditCount,
        suspiciousAppsCount: suspiciousAppsCount,
        smsScanCount: smsScanCount,
        emailScanCount: emailScanCount,
        linkScanCount: linkScanCount,
        communityThreats: threats.take(3).toList(),
      );
      
      // 4. Cache and update UI
      await HiveBoxHelper.saveLatestBriefing(response);
      
      if (mounted) {
        setState(() {
          _briefingData = response;
          // Also refresh live task statuses after Gemini responds
          _liveTaskStatuses = _computeLiveTaskStatuses();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load safety briefing: $e';
          _isLoading = false;
        });
      }
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return CyberTheme.danger;
      case 'MEDIUM':
        return CyberTheme.warning;
      default:
        return CyberTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final briefingText = _briefingData?['briefing']?.toString() ?? 'Gathering system parameters and local telemetry... Tap refresh to run AI security check.';
    final recommendations = List<Map<String, dynamic>>.from(
      (_briefingData?['recommendations'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? []
    );
    // Always use _liveTaskStatuses (computed fresh from Hive) — never from stale cache
    final taskStatuses = _liveTaskStatuses;
    final themeColor = CyberTheme.primary;

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
          'Sentinel Coach AI',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: CyberTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: CyberTheme.textPrimary),
            onPressed: _isLoading ? null : _fetchBriefing,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _isLoading && _briefingData == null
            ? const Center(child: CircularProgressIndicator(color: CyberTheme.primary))
            : _error != null && _briefingData == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: CyberTheme.danger, size: 48),
                          const SizedBox(height: 16),
                          Text(_error!, style: GoogleFonts.inter(color: CyberTheme.textSecondary, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _fetchBriefing,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mascot pulser
                    Center(
                      child: ScaleTransition(
                        scale: _avatarAnimation,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [themeColor, themeColor.withOpacity(0.5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: themeColor.withOpacity(0.3),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'SENTINEL SHIELD-V1',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: themeColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Task completion checklist
                    if (taskStatuses.isNotEmpty) ...[_buildTaskStatusGrid(taskStatuses), const SizedBox(height: 18)],

                    // Safety Briefing Typewriter Console
                    _buildConsoleTerminal(briefingText),
                    const SizedBox(height: 20),

                    // Recommendations Section
                    Text(
                      'Sentinel Recommendations',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: CyberTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (recommendations.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: CyberTheme.neonGlowDecoration(color: CyberTheme.success),
                        child: Text(
                          'All localized checks clean. No actions required. Keep scanning regularly!',
                          style: GoogleFonts.inter(fontSize: 13, color: CyberTheme.textSecondary),
                        ),
                      )
                    else
                      ...recommendations.map((rec) => _buildRecommendationItem(rec)).toList(),
                    
                    const SizedBox(height: 60), // Space for FAB
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openConsultingChat(context),
        backgroundColor: themeColor,
        elevation: 6,
        icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
        label: Text(
          'Consult AI Coach',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTaskStatusGrid(List<Map<String, dynamic>> statuses) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFEDED)),
        boxShadow: [BoxShadow(color: const Color(0xFFE5E7EB).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.task_alt_rounded, color: CyberTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Security Task Progress',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 14, color: CyberTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Track which security actions you have completed on your device.',
            style: GoogleFonts.inter(fontSize: 11, color: CyberTheme.textMuted, height: 1.4),
          ),
          const Divider(height: 20),
          ...statuses.map((s) {
            final isPending = (s['status']?.toString().toUpperCase() ?? 'PENDING') == 'PENDING';
            final statusColor = isPending ? CyberTheme.warning : CyberTheme.success;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPending ? Icons.radio_button_unchecked_rounded : Icons.check_circle_rounded,
                      color: statusColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['task']?.toString() ?? '',
                          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 13, color: CyberTheme.textPrimary),
                        ),
                        Text(
                          s['detail']?.toString() ?? '',
                          style: GoogleFonts.inter(fontSize: 11, color: CyberTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isPending ? 'PENDING' : 'DONE',
                      style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildConsoleTerminal(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberTheme.secondary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Text(
                'ai_briefing.sh',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isLoading)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                ),
            ],
          ),
          const Divider(color: Colors.white10, height: 16),
          const SizedBox(height: 4),
          TypewriterText(
            text: text,
            style: GoogleFonts.spaceGrotesk(
              color: const Color(0xFF00FF66), // Retro console green
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(Map<String, dynamic> rec) {
    final title = rec['title']?.toString() ?? 'Action required';
    final desc = rec['description']?.toString() ?? '';
    final priority = rec['priority']?.toString() ?? 'LOW';
    final pColor = _getPriorityColor(priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEDED)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: pColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_outlined,
              color: pColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: CyberTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CyberTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: pColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              priority,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: pColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openConsultingChat(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SentinelConsultingChat(),
    );
  }
}

// ── Typewriter Terminal Animation ──────────────────────────────────────────
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;

  const TypewriterText({
    Key? key,
    required this.text,
    required this.style,
    this.duration = const Duration(milliseconds: 15),
  }) : super(key: key);

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayedText = '';
  int _currentIndex = 0;
  Timer? _timer;
  bool _cursorVisible = true;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    _startTyping();
    _startCursorBlink();
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _timer?.cancel();
      _displayedText = '';
      _currentIndex = 0;
      _startTyping();
    }
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.duration, (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayedText += widget.text[_currentIndex];
          _currentIndex++;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  void _startCursorBlink() {
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _cursorVisible = !_cursorVisible;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDone = _currentIndex >= widget.text.length;
    return RichText(
      text: TextSpan(
        style: widget.style,
        children: [
          TextSpan(text: _displayedText),
          if (!isDone)
            TextSpan(
              text: _cursorVisible ? ' █' : '  ',
              style: widget.style.copyWith(color: const Color(0xFF00FF66)),
            ),
        ],
      ),
    );
  }
}

// ── Consulting Q&A Chat Modal ───────────────────────────────────────────────
class SentinelConsultingChat extends ConsumerStatefulWidget {
  const SentinelConsultingChat({Key? key}) : super(key: key);

  @override
  ConsumerState<SentinelConsultingChat> createState() => _SentinelConsultingChatState();
}

class _SentinelConsultingChatState extends ConsumerState<SentinelConsultingChat> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();
  
  final List<Content> _conversation = [
    Content.model([TextPart('Greetings Agent. I am Sentinel Coach. How can I assist you with your mobile security or digital protection today?')])
  ];
  
  bool _isReplying = false;

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isReplying) return;

    _messageController.clear();
    setState(() {
      _conversation.add(Content.text(text));
      _isReplying = true;
    });
    
    _scrollToBottom();

    // Call Gemini
    final reply = await _geminiService.chatWithSentinelCoach(text, List<Content>.from(_conversation));
    
    if (mounted) {
      setState(() {
        _conversation.add(Content.model([TextPart(reply)]));
        _isReplying = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.psychology_outlined, color: CyberTheme.primary, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Sentinel Advisory Chat',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: CyberTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Ask any security questions: phishing signs, device warnings, or app settings.',
              style: GoogleFonts.inter(fontSize: 11.5, color: CyberTheme.textMuted),
            ),
            const Divider(height: 24),
            
            // Conversation Scroll Area
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).viewInsets.bottom > 0
                    ? MediaQuery.of(context).size.height * 0.20
                    : MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                controller: _scrollController,
                itemCount: _conversation.length,
                itemBuilder: (context, idx) {
                  final content = _conversation[idx];
                  final isUser = content.role == 'user';
                  final parts = content.parts;
                  final text = parts.isNotEmpty && parts.first is TextPart
                      ? (parts.first as TextPart).text
                      : '';

                  // Clean prepended system instructions from display if user bubble
                  String displayText = text;
                  if (isUser && displayText.contains('System Instruction:')) {
                    final split = displayText.split('User:');
                    if (split.length > 1) {
                      displayText = split[1].trim();
                    }
                  }

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isUser ? CyberTheme.primary : CyberTheme.surfaceLight,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                          bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                        ),
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      child: Text(
                        displayText,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isUser ? Colors.white : CyberTheme.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_isReplying)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: CyberTheme.primary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sentinel is processing response...',
                      style: GoogleFonts.inter(fontSize: 11, color: CyberTheme.textMuted, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),

            // Input Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: CyberTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: 'Type your question here...',
                        hintStyle: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textMuted),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: CyberTheme.primary,
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
