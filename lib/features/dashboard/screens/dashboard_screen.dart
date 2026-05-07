import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cybershield_forum/core/theme.dart';
import 'package:cybershield_forum/core/hive_box.dart';
import 'package:cybershield_forum/features/auth/provider.dart';
import 'package:cybershield_forum/features/forum/provider.dart';
import 'package:cybershield_forum/features/reports/provider.dart';
import 'package:cybershield_forum/features/forum/screens/post_detail_screen.dart';


class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Synchronize latest user profile stats on launch
    Future.microtask(() => ref.read(authProvider.notifier).fetchProfile());
  }

  Widget _buildDrawerGridItem({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        setState(() => _currentIndex = index);
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.12),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSelected ? color : CyberTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> subViews = [
      _HomeFeedView(onNavigate: (index) => setState(() => _currentIndex = index)),
      const _ThreatCenterView(),
      const _CyberArcadeView(),
      const _LeaderboardView(),
      const _AgentProfileView(),
    ];

    final List<String> titles = [
      'Innvikta Feed',
      'Forums Explorer',
      'Cyber Arcade',
      'Global Leaderboard',
      'Agent Profile',
    ];

    return Scaffold(
      backgroundColor: CyberTheme.background,
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            (() {
              final profile = ref.watch(authProvider).userProfile;
              final username = profile?['username'] ?? 'User';
              final email = profile?['email'] ?? 'user@cybershield.org';

              return UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [CyberTheme.primary, Color(0xFFFF8B3D)],
                  ),
                ),
                currentAccountPicture: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: Image.network(
                      'https://api.dicebear.com/7.x/adventurer/png?seed=${profile?['avatar'] ?? username}&backgroundColor=ffd5b4',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                accountName: Text(
                  username,
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                accountEmail: Text(
                  email,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                ),
              );
            })(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'DASHBOARD NAVIGATION',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade500,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildDrawerGridItem(
                    context: context,
                    label: 'Feed',
                    icon: Icons.feed_outlined,
                    color: CyberTheme.primary,
                    index: 0,
                  ),
                  _buildDrawerGridItem(
                    context: context,
                    label: 'Forums',
                    icon: Icons.forum_outlined,
                    color: Colors.purple.shade600,
                    index: 1,
                  ),
                  _buildDrawerGridItem(
                    context: context,
                    label: 'Arcade',
                    icon: Icons.sports_esports_outlined,
                    color: Colors.blue.shade600,
                    index: 2,
                  ),
                  _buildDrawerGridItem(
                    context: context,
                    label: 'Leaderboard',
                    icon: Icons.leaderboard_outlined,
                    color: Colors.amber.shade800,
                    index: 3,
                  ),
                  _buildDrawerGridItem(
                    context: context,
                    label: 'Profile',
                    icon: Icons.person_outline_rounded,
                    color: Colors.teal.shade600,
                    index: 4,
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFFEFEDED), height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: CyberTheme.danger),
              title: Text('Logout', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: CyberTheme.danger, fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: _currentIndex == 0
            ? Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.api_rounded, color: CyberTheme.primary, size: 24),
                    const SizedBox(width: 6),
                    Text(
                      'INNVIKTA',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: CyberTheme.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              )
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: CyberTheme.textPrimary),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        leadingWidth: _currentIndex == 0 ? 180 : 56,
        title: _currentIndex == 0
            ? const SizedBox.shrink()
            : Text(
                titles[_currentIndex],
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.bold,
                  color: CyberTheme.textPrimary,
                  fontSize: 18,
                  letterSpacing: -0.5,
                ),
              ),
        centerTitle: _currentIndex != 0,
        actions: [
          if (_currentIndex == 0 || _currentIndex == 1) ...[
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: CyberTheme.textPrimary),
                  onPressed: () => _showNotificationsDialog(context),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: CyberTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (_currentIndex == 4) ...[
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: CyberTheme.textPrimary),
              onPressed: () {
                final user = ref.read(authProvider).userProfile;
                if (user != null) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => EditProfileSheet(user: user),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: CyberTheme.danger),
              onPressed: () {
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.power_settings_new_rounded, color: CyberTheme.danger),
              onPressed: () {
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: subViews[_currentIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE5E7EB),
              blurRadius: 12,
              offset: const Offset(4, 4),
            ),
            const BoxShadow(
              color: Colors.white,
              blurRadius: 12,
              offset: Offset(-4, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: const Color(0xFFF9FAFB),
            selectedItemColor: CyberTheme.primary,
            unselectedItemColor: CyberTheme.textMuted,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w500),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home, color: CyberTheme.primary),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.explore_outlined),
                activeIcon: Icon(Icons.explore, color: CyberTheme.primary),
                label: 'Forums',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.sports_esports_outlined),
                activeIcon: Icon(Icons.sports_esports, color: CyberTheme.primary),
                label: 'Games',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events_outlined),
                activeIcon: Icon(Icons.emoji_events, color: CyberTheme.primary),
                label: 'Ranks',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person, color: CyberTheme.primary),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined, color: CyberTheme.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Notifications',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: CyberTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _notifItem('Security Clearance Upgraded', 'Your rank has been elevated to WhiteHat Trainee. Keep active in community reporting!', 'achievement'),
                        _notifItem('New Threat Report Recorded', 'Scam alert "Delivery Fake URL" successfully written to community ledger.', 'report_status'),
                        _notifItem('Reputation Point Received', 'Your recent post "Ransomware Defense Checklist" received +15 reputation XP.', 'like'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CyberTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                  ),
                  child: Text(
                    'DISMISS',
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _notifItem(String title, String body, String type) {
    IconData icon = Icons.info_outline_rounded;
    Color color = CyberTheme.primary;
    if (type == 'achievement') {
      icon = Icons.emoji_events_outlined;
      color = Colors.orange;
    } else if (type == 'report_status') {
      icon = Icons.gavel_rounded;
      color = Colors.deepOrange;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEDED)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
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
                    fontSize: 13,
                    color: CyberTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.inter(
                    fontSize: 11,
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
}

// ===================== NEW VIEW: HOME FEED (High-Fidelity Screen 2) =====================
class _HomeFeedView extends ConsumerStatefulWidget {
  final Function(int)? onNavigate;
  const _HomeFeedView({Key? key, this.onNavigate}) : super(key: key);

  @override
  ConsumerState<_HomeFeedView> createState() => _HomeFeedViewState();
}

class _HomeFeedViewState extends ConsumerState<_HomeFeedView> {
  int _selectedTab = 0;
  final List<String> _tabs = ['For You', 'Following', 'Trending', 'Latest'];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Cyber Arcade Game state
  String? _activeGame; // null, 'patrol', 'trivia'
  int _gameRound = 0;
  int _gameScore = 0;
  bool _gameFinished = false;
  int? _selectedAnswerIndex; // for trivia option tapping
  bool _answeredThisRound = false;

  final List<Map<String, dynamic>> _patrolRounds = [
    {
      'sender': 'security@paypal-verification-alert.com',
      'message': 'URGENT: Your account has been suspended due to suspicious login activity. Click here to verify your identity immediately: http://paypal-verify-user.net/login_session',
      'isPhishing': true,
      'explanation': 'Phishing! The domain "paypal-verify-user.net" is an unofficial impersonation link designed to steal credentials.',
    },
    {
      'sender': 'support@github.com',
      'message': 'Security Alert: A new SSH key was added to your account from IP address 192.168.1.1. If this was you, no action is needed.',
      'isPhishing': false,
      'explanation': 'Safe! This is a standard security notification sent from Github\'s official support email.',
    },
    {
      'sender': 'hr-benefits@yourcompany-benefits.com',
      'message': 'Employee Perks: Click this link to download the updated Q3 salary appraisal sheet: http://benefits-dl-auth.ru/appraisals/q3_spreadsheet.exe',
      'isPhishing': true,
      'explanation': 'Phishing! Downloading files with executable extension (.exe) hosted on unofficial domains is highly dangerous.',
    }
  ];

  final List<Map<String, dynamic>> _triviaRounds = [
    {
      'question': 'What is the most secure authentication method?',
      'options': [
        'SMS-based OTP',
        'Hardware Security Key (e.g., YubiKey)',
        'Personal Security Questions',
        'Static Passwords'
      ],
      'correctIndex': 1,
      'explanation': 'Hardware keys are immune to session hijacking and traditional credential phishing attacks.',
    },
    {
      'question': 'Which protocol encrypts web traffic to ensure confidentiality?',
      'options': [
        'HTTP',
        'FTP',
        'HTTPS',
        'SMTP'
      ],
      'correctIndex': 2,
      'explanation': 'HTTPS uses TLS/SSL to encrypt HTTP communications, protecting data from eavesdroppers.',
    },
    {
      'question': 'What is "Vishing"?',
      'options': [
        'Phishing via malicious PDF files',
        'Voice-based phishing over phone calls',
        'Scanning open ports on a server',
        'Encrypting a victim\'s files for ransom'
      ],
      'correctIndex': 1,
      'explanation': 'Vishing stands for Voice Phishing, where attackers use fraudulent phone calls to extract details.',
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.background,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // PREMIUM INNVIKTA HERO SECTION WITH HERO IMAGE
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9F5), // Soft peach/cream background matching the design system
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD4B2).withOpacity(0.45),
                    blurRadius: 14,
                    offset: const Offset(6, 6),
                  ),
                  const BoxShadow(
                    color: Colors.white,
                    blurRadius: 14,
                    offset: Offset(-6, -6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  clipBehavior: Clip.antiAlias,
                  children: [
                    Positioned(
                      right: -55,
                      top: -5,
                      bottom: -5,
                      child: Image.asset(
                        'assets/images/innvikta_hero.png',
                        height: 85,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 24, top: 24, bottom: 24, right: 105.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Connect. Share.',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: CyberTheme.textPrimary,
                            height: 1.15,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Learn. Grow.',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: CyberTheme.primary,
                            height: 1.15,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Join a community of thinkers and level up every day.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: CyberTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: () {
                            if (widget.onNavigate != null) {
                              widget.onNavigate!(1); // Switch to Forums Explorer
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CyberTheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                            elevation: 1,
                          ),
                          child: Text(
                            'Explore Now',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
            const SizedBox(height: 12),
            // CAROUSEL PAGE DOTS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 16,
                  height: 6,
                  decoration: BoxDecoration(
                    color: CyberTheme.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCD9D7),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCD9D7),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // QUICK ACTIONS HEADING
            Text(
              'Quick Actions',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: CyberTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            // FOUR ROW ITEM CARDS
            Row(
              children: [
                _buildQuickActionCard(
                  title: 'Forums',
                  subtitle: 'Discuss',
                  icon: Icons.forum_outlined,
                  onTap: () {
                    if (widget.onNavigate != null) widget.onNavigate!(1);
                  },
                ),
                _buildQuickActionCard(
                  title: 'Blogs',
                  subtitle: 'Read',
                  icon: Icons.menu_book_outlined,
                  onTap: () {
                    if (widget.onNavigate != null) widget.onNavigate!(1);
                  },
                ),
                _buildQuickActionCard(
                  title: 'Games',
                  subtitle: 'Play',
                  icon: Icons.sports_esports_outlined,
                  onTap: () {
                    if (widget.onNavigate != null) widget.onNavigate!(2);
                  },
                ),

              ],
            ),
            const SizedBox(height: 28),

            // TRENDING DISCUSSIONS HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trending Discussions',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: CyberTheme.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (widget.onNavigate != null) widget.onNavigate!(1);
                  },
                  child: Text(
                    'View all',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: CyberTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // THREE DISCUSSIONS CARDS
            ..._buildFilteredDiscussions(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFilteredDiscussions() {
    final List<Map<String, dynamic>> allDiscussions = [
      {
        'title': "What's the biggest cybersecurity threat in 2024?",
        'author': 'CyberNinja',
        'time': '2h ago',
        'comments': 32,
        'icon': Icons.shield_outlined,
      },
      {
        'title': "Best tools for network monitoring?",
        'author': 'SecureMind',
        'time': '5h ago',
        'comments': 18,
        'icon': Icons.analytics_outlined,
      },
      {
        'title': "How do you stay ahead of phishing attacks?",
        'author': 'ThreatHunter',
        'time': '1d ago',
        'comments': 27,
        'icon': Icons.gavel_rounded,
      },
    ];

    final List<Map<String, dynamic>> allPeople = [
      {
        'name': 'CyberNinja',
        'role': 'Ethical Hacker',
        'avatar': 'CyberNinja',
        'pts': '2.4k pts',
      },
      {
        'name': 'SecureMind',
        'role': 'Security Analyst',
        'avatar': 'SecureMind',
        'pts': '1.8k pts',
      },
      {
        'name': 'ThreatHunter',
        'role': 'IR Lead',
        'avatar': 'ThreatHunter',
        'pts': '1.5k pts',
      },
      {
        'name': 'WhiteHat_Dev',
        'role': 'Reverse Eng',
        'avatar': 'WhiteHat_Dev',
        'pts': '950 pts',
      },
    ];

    final query = _searchQuery.toLowerCase();

    final filteredDiscussions = allDiscussions.where((item) {
      final title = item['title'].toString().toLowerCase();
      final author = item['author'].toString().toLowerCase();
      return title.contains(query) || author.contains(query);
    }).toList();

    final filteredPeople = allPeople.where((item) {
      final name = item['name'].toString().toLowerCase();
      final role = item['role'].toString().toLowerCase();
      return name.contains(query) || role.contains(query);
    }).toList();

    final List<Widget> results = [];

    if (query.isNotEmpty && filteredPeople.isNotEmpty) {
      results.add(
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Matching Agents & People',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: CyberTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 95,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredPeople.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, idx) {
                    final p = filteredPeople[idx];
                    return Container(
                      width: 155,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEFEDED)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(shape: BoxShape.circle),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: Image.network(
                                    'https://api.dicebear.com/7.x/adventurer/png?seed=${p['avatar']}&backgroundColor=ffd5b4',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      p['name'] as String,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: CyberTheme.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      p['role'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        color: CyberTheme.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                p['pts'] as String,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: CyberTheme.primary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: CyberTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Follow',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: CyberTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (filteredDiscussions.isNotEmpty) ...[
                Text(
                  'Matching Discussions',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: CyberTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      );
    }

    if (filteredDiscussions.isEmpty && filteredPeople.isEmpty) {
      results.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Center(
            child: Text(
              'No matching discussions or people found.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: CyberTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
      return results;
    }

    results.addAll(
      filteredDiscussions.map((item) {
        return _buildDiscussionItem(
          title: item['title'] as String,
          author: item['author'] as String,
          time: item['time'] as String,
          comments: item['comments'] as int,
          icon: item['icon'] as IconData,
          onTap: () {},
        );
      }),
    );

    return results;
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE5E7EB),
                blurRadius: 8,
                offset: const Offset(4, 4),
              ),
              const BoxShadow(
                color: Colors.white,
                blurRadius: 8,
                offset: Offset(-4, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CyberTheme.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: CyberTheme.primary, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: CyberTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: CyberTheme.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscussionItem({
    required String title,
    required String author,
    required String time,
    required int comments,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5E7EB),
            blurRadius: 8,
            offset: const Offset(4, 4),
          ),
          const BoxShadow(
            color: Colors.white,
            blurRadius: 8,
            offset: Offset(-4, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CyberTheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: CyberTheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: CyberTheme.textPrimary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'by $author • $time',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: CyberTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, color: CyberTheme.textMuted, size: 16),
              const SizedBox(width: 4),
              Text(
                '$comments',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: CyberTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCyberArcadeView() {
    if (_gameFinished) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B1C1C), Color(0xFF2E2E2E)],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: CyberTheme.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: CyberTheme.primary, size: 48),
                ),
                const SizedBox(height: 24),
                Text(
                  'TRAINING COMPLETE',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _activeGame == 'patrol' ? 'Phishing Patrol Module' : 'Cyber Trivia Hack Module',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: CyberTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(color: Colors.white12, height: 40),
                Text(
                  'SCORE ACCUMULATED',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white38,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '+$_gameScore XP',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You got ${_gameScore ~/ 10} out of 3 correct answers!',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final success = await ref.read(authProvider.notifier).addReputationPoints(_gameScore);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'SCORE SUBMITTED! +$_gameScore XP reflected on Global Leaderboard.',
                      style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                );
                setState(() {
                  _activeGame = null;
                  _gameFinished = false;
                });
              }
            },
            icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
            label: Text(
              'SUBMIT SCORE TO LEADERBOARD',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: CyberTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => setState(() {
              _activeGame = null;
              _gameFinished = false;
            }),
            child: Text(
              'CHOOSE ANOTHER MODULE',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: CyberTheme.textPrimary, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              side: const BorderSide(color: Color(0xFFEFEDED), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
            ),
          ),
        ],
      );
    }

    if (_activeGame == 'patrol') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: CyberTheme.textPrimary),
                onPressed: () => setState(() => _activeGame = null),
              ),
              Text(
                'PHISHING PATROL',
                style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: CyberTheme.textPrimary),
              ),
              const Spacer(),
              Text(
                'ROUND ${_gameRound + 1} OF 3',
                style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1C1C),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.alternate_email_rounded, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'SENDER: ${_patrolRounds[_gameRound]['sender']}',
                        style: GoogleFonts.spaceGrotesk(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 24),
                Text(
                  _patrolRounds[_gameRound]['message'],
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 12.5, height: 1.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (!_answeredThisRound) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      final isCorrect = _patrolRounds[_gameRound]['isPhishing'] == false;
                      setState(() {
                        _answeredThisRound = true;
                        if (isCorrect) _gameScore += 10;
                      });
                    },
                    child: Text(
                      'SAFE MESSAGE',
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: const BorderSide(color: Colors.green, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final isCorrect = _patrolRounds[_gameRound]['isPhishing'] == true;
                      setState(() {
                        _answeredThisRound = true;
                        if (isCorrect) _gameScore += 10;
                      });
                    },
                    child: Text(
                      'PHISHING PAYLOAD',
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: CyberTheme.danger,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEFEDED)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _patrolRounds[_gameRound]['isPhishing'] == true ? Icons.gavel_rounded : Icons.verified_user_rounded,
                        color: _patrolRounds[_gameRound]['isPhishing'] == true ? CyberTheme.danger : Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _patrolRounds[_gameRound]['isPhishing'] == true ? 'PHISHING CONFIRMED' : 'SAFE SOURCE VERIFIED',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _patrolRounds[_gameRound]['isPhishing'] == true ? CyberTheme.danger : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _patrolRounds[_gameRound]['explanation'],
                    style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textSecondary, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_gameRound < 2) {
                  setState(() {
                    _gameRound++;
                    _answeredThisRound = false;
                  });
                } else {
                  setState(() {
                    _gameFinished = true;
                  });
                }
              },
              child: Text(
                _gameRound < 2 ? 'CONTINUE ➔' : 'FINISH TRAINING ➔',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: CyberTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
              ),
            ),
          ],
        ],
      );
    }

    if (_activeGame == 'trivia') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: CyberTheme.textPrimary),
                onPressed: () => setState(() => _activeGame = null),
              ),
              Text(
                'TRIVIA HACK',
                style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: CyberTheme.textPrimary),
              ),
              const Spacer(),
              Text(
                'ROUND ${_gameRound + 1} OF 3',
                style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1C1C),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
            ),
            child: Text(
              _triviaRounds[_gameRound]['question'],
              style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, height: 1.45),
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(4, (index) {
            final isSelected = _selectedAnswerIndex == index;
            final isCorrect = index == _triviaRounds[_gameRound]['correctIndex'];
            
            Color cardBorder = const Color(0xFFEFEDED);
            Color cardBg = Colors.white;
            Color textCol = CyberTheme.textPrimary;

            if (_answeredThisRound) {
              if (isCorrect) {
                cardBorder = Colors.green;
                cardBg = Colors.green.withOpacity(0.04);
                textCol = Colors.green;
              } else if (isSelected) {
                cardBorder = CyberTheme.danger;
                cardBg = CyberTheme.danger.withOpacity(0.04);
                textCol = CyberTheme.danger;
              }
            } else if (isSelected) {
              cardBorder = CyberTheme.primary;
              cardBg = CyberTheme.primary.withOpacity(0.04);
              textCol = CyberTheme.primary;
            }

            return GestureDetector(
              onTap: _answeredThisRound
                  ? null
                  : () {
                      setState(() {
                        _selectedAnswerIndex = index;
                        _answeredThisRound = true;
                        if (isCorrect) _gameScore += 10;
                      });
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: cardBorder, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        String.fromCharCode(65 + index),
                        style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold, color: textCol),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _triviaRounds[_gameRound]['options'][index],
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: textCol),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          if (_answeredThisRound) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEFEDED)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.purple, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'EXPLANATION',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _triviaRounds[_gameRound]['explanation'],
                    style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textSecondary, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_gameRound < 2) {
                  setState(() {
                    _gameRound++;
                    _selectedAnswerIndex = null;
                    _answeredThisRound = false;
                  });
                } else {
                  setState(() {
                    _gameFinished = true;
                  });
                }
              },
              child: Text(
                _gameRound < 2 ? 'CONTINUE ➔' : 'FINISH TRAINING ➔',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: CyberTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'SELECT SECURITY MODULE',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: CyberTheme.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),

        // Game Card 1: Phishing Patrol
        GestureDetector(
          onTap: () => setState(() {
            _activeGame = 'patrol';
            _gameRound = 0;
            _gameScore = 0;
            _gameFinished = false;
            _answeredThisRound = false;
          }),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFEFEDED)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.radar_rounded, color: Colors.orange, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Module 01: Phishing Patrol',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: CyberTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '+10 XP / Rd',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Inspect simulated message headers, payloads and domains. Identify credential harvest scripts, malicious executables and impersonations in real-time.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CyberTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Difficulty: MEDIUM',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: CyberTheme.textMuted,
                      ),
                    ),
                    Text(
                      'LAUNCH MODULE ➔',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: CyberTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Game Card 2: Trivia challenge
        GestureDetector(
          onTap: () => setState(() {
            _activeGame = 'trivia';
            _gameRound = 0;
            _gameScore = 0;
            _gameFinished = false;
            _selectedAnswerIndex = null;
            _answeredThisRound = false;
          }),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFEFEDED)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Colors.purple, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Module 02: Cyber Trivia Hack',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: CyberTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '+10 XP / Rd',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Hack your way through challenging technical questions on security architectures, decryption algorithms, secure communication protocols, and attack surfaces.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CyberTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Difficulty: HARD',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: CyberTheme.textMuted,
                      ),
                    ),
                    Text(
                      'LAUNCH MODULE ➔',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: CyberTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showUserProfileSheet(BuildContext context, WidgetRef ref, int userId, String username, String rank) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UserProfileSheet(userId: userId, username: username, rank: rank),
    );
  }

  Widget _buildPostCard({

    required String author,
    required String rank,
    required String time,
    required String title,
    required String content,
    required List<String> tags,
    required int likes,
    required int comments,
    required VoidCallback onLike,
    required VoidCallback onTap,
    VoidCallback? onAuthorTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEFEDED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: onAuthorTap,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: CyberTheme.primary.withOpacity(0.1),
                        backgroundImage: NetworkImage(
                          'https://api.dicebear.com/7.x/adventurer/png?seed=$author&backgroundColor=ffd5b4',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: onAuthorTap,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  author,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: CyberTheme.primary,
                                    decoration: onAuthorTap != null ? TextDecoration.underline : null,
                                    decorationColor: CyberTheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: CyberTheme.surfaceLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    rank,
                                    style: GoogleFonts.inter(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: CyberTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              time,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: CyberTheme.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_horiz_rounded, color: CyberTheme.textMuted),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: CyberTheme.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CyberTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: CyberTheme.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '#$tag',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: CyberTheme.primary,
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFEFEDED), height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _AnimatedLikeButton(
                      initialLikes: likes,
                      onLike: onLike,
                    ),
                    const SizedBox(width: 24),
                    Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, color: CyberTheme.textMuted, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '$comments',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: CyberTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.share_outlined, color: CyberTheme.textMuted, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===================== USER PROFILE SHEET =====================
class _UserProfileSheet extends ConsumerStatefulWidget {
  final int userId;
  final String username;
  final String rank;
  const _UserProfileSheet({required this.userId, required this.username, required this.rank});

  @override
  ConsumerState<_UserProfileSheet> createState() => _UserProfileSheetState();
}

class _UserProfileSheetState extends ConsumerState<_UserProfileSheet> {
  bool _isFollowing = false;
  bool _followLoading = false;

  Future<void> _toggleFollow() async {
    setState(() => _followLoading = true);
    bool ok;
    if (_isFollowing) {
      ok = await ref.read(forumOperationsProvider.notifier).unfollowUser(widget.userId);
    } else {
      ok = await ref.read(forumOperationsProvider.notifier).followUser(widget.userId);
    }
    if (mounted) {
      setState(() {
        _followLoading = false;
        if (ok) _isFollowing = !_isFollowing;
      });
      if (!ok) {
        // Optimistic local toggle even if server fails (no account required)
        setState(() => _isFollowing = !_isFollowing);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(userPostsByIdProvider(widget.userId));
    final profileAsync = ref.watch(userProfileByIdProvider(widget.userId));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFEFEDED), borderRadius: BorderRadius.circular(99)),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar + name + follow
                    Row(children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: CyberTheme.primary.withOpacity(0.1),
                        backgroundImage: NetworkImage(
                          'https://api.dicebear.com/7.x/adventurer/png?seed=${widget.username}&backgroundColor=ffd5b4',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.username, style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.bold, color: CyberTheme.textPrimary)),
                          const SizedBox(height: 4),
                          profileAsync.when(
                            data: (profile) => Text(
                              profile?['rank']?.toString() ?? widget.rank,
                              style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textMuted, fontWeight: FontWeight.w600),
                            ),
                            loading: () => Text(widget.rank, style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textMuted, fontWeight: FontWeight.w600)),
                            error: (_, __) => Text(widget.rank, style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textMuted, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      )),
                      // Follow Button
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _followLoading
                          ? const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 2, color: CyberTheme.primary))
                          : GestureDetector(
                              key: ValueKey(_isFollowing),
                              onTap: _toggleFollow,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _isFollowing ? Colors.white : CyberTheme.primary,
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(color: CyberTheme.primary, width: 1.5),
                                ),
                                child: Text(
                                  _isFollowing ? 'Following' : 'Follow',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _isFollowing ? CyberTheme.primary : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // Stats row
                    profileAsync.when(
                      data: (profile) {
                        final rep = profile?['reputation_points']?.toString() ?? '0';
                        final posts = profile?['posts_count']?.toString() ?? '0';
                        final followers = profile?['followers_count']?.toString() ?? '0';
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(color: CyberTheme.background, borderRadius: BorderRadius.circular(20)),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                            _statChip(posts, 'Posts'),
                            Container(width: 1, height: 24, color: const Color(0xFFEFEDED)),
                            _statChip(followers, 'Followers'),
                            Container(width: 1, height: 24, color: const Color(0xFFEFEDED)),
                            _statChip(rep, 'XP'),
                          ]),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator(color: CyberTheme.primary, strokeWidth: 2)),
                      error: (_, __) => postsAsync.when(
                        data: (posts) => Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(color: CyberTheme.background, borderRadius: BorderRadius.circular(20)),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                            _statChip(posts.length.toString(), 'Posts'),
                            Container(width: 1, height: 24, color: const Color(0xFFEFEDED)),
                            _statChip('—', 'Followers'),
                            Container(width: 1, height: 24, color: const Color(0xFFEFEDED)),
                            _statChip('—', 'XP'),
                          ]),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Recent Posts
                    Text('Recent Posts', style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.bold, color: CyberTheme.textPrimary)),
                    const SizedBox(height: 12),
                    postsAsync.when(
                      data: (posts) {
                        if (posts.isEmpty) {
                          return Center(child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(children: [
                              const Icon(Icons.article_outlined, size: 40, color: CyberTheme.textMuted),
                              const SizedBox(height: 8),
                              Text('No posts yet', style: GoogleFonts.spaceGrotesk(color: CyberTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
                            ]),
                          ));
                        }
                        return Column(
                          children: posts.take(5).map((post) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFEFEDED)),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(post.title, style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: CyberTheme.textPrimary)),
                              const SizedBox(height: 6),
                              Text(post.content, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 11, color: CyberTheme.textSecondary, height: 1.4)),
                              const SizedBox(height: 10),
                              Row(children: [
                                const Icon(Icons.favorite_border_rounded, size: 13, color: CyberTheme.textMuted),
                                const SizedBox(width: 4),
                                Text('${post.likesCount}', style: GoogleFonts.inter(fontSize: 11, color: CyberTheme.textMuted, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 14),
                                const Icon(Icons.chat_bubble_outline_rounded, size: 13, color: CyberTheme.textMuted),
                                const SizedBox(width: 4),
                                Text('${post.commentsCount}', style: GoogleFonts.inter(fontSize: 11, color: CyberTheme.textMuted, fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: CyberTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(99)),
                                  child: Text(post.categoryName, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: CyberTheme.primary)),
                                ),
                              ]),
                            ]),
                          )).toList(),
                        );
                      },
                      loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: CyberTheme.primary, strokeWidth: 2))),
                      error: (_, __) => Center(child: Text('Could not load posts', style: GoogleFonts.inter(color: CyberTheme.textMuted, fontSize: 12))),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String value, String label) {
    return Column(children: [
      Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 17, fontWeight: FontWeight.bold, color: CyberTheme.textPrimary)),
      const SizedBox(height: 2),
      Text(label, style: GoogleFonts.inter(fontSize: 10, color: CyberTheme.textMuted, fontWeight: FontWeight.w600)),
    ]);
  }
}

// ===================== VIEW 2: FORUMS EXPLORER (Screen 5 Grid) =====================
class _ThreatCenterView extends ConsumerWidget {
  const _ThreatCenterView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFEFEDED)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CyberTheme.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_outlined, color: CyberTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Sentinel Forums',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: CyberTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Join active community forums to learn the latest vectors, share threats, and coordinate defenses.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CyberTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Explore Topics',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: CyberTheme.textPrimary,
                ),
              ),
              Text(
                'View all',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: CyberTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          categoriesAsync.when(
            data: (categories) {
              final List<String> memberStats = [
                '8.2k members',
                '4.7k members',
                '6.1k members',
                '3.9k members',
                '5.3k members',
                '4.0k members'
              ];

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.15,
                ),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final statText = index < memberStats.length ? memberStats[index] : '1.2k members';

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFEFEDED)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          context.push('/forum/${category.id}/${Uri.encodeComponent(category.name)}');
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: CyberTheme.primary.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getCategoryIcon(category.icon), 
                                  color: CyberTheme.primary, 
                                  size: 20
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: CyberTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    statText,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: CyberTheme.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: CyberTheme.primary)),
            error: (e, _) => Center(child: Text('Error loading categories: $e')),
          ),
          
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trending Topics',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: CyberTheme.textPrimary,
                ),
              ),
              Text(
                'View all',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: CyberTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _trendingItem('# Ransomware', '12.3k posts'),
          _trendingItem('# Bug Bounty Tips', '8.7k posts'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _trendingItem(String hashtag, String countText) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEDED)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tag_rounded, color: CyberTheme.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            hashtag,
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: CyberTheme.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            countText,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: CyberTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'alternate_email': return Icons.alternate_email_rounded;
      case 'security_update_warning': return Icons.gavel_rounded;
      case 'gavel': return Icons.gavel_rounded;
      case 'forum': return Icons.chat_bubble_outline_rounded;
      case 'fact_check': return Icons.fact_check_outlined;
      default: return Icons.shield_outlined;
    }
  }
}

// ===================== NEW VIEW: DEDICATED CYBER ARCADE VIEW =====================
class _CyberArcadeView extends ConsumerStatefulWidget {
  const _CyberArcadeView({Key? key}) : super(key: key);

  @override
  ConsumerState<_CyberArcadeView> createState() => _CyberArcadeViewState();
}

class _CyberArcadeViewState extends ConsumerState<_CyberArcadeView> {
  String? _activeGame; // null, 'patrol', 'trivia', 'flappy', 'password'
  int _gameRound = 0;
  int _gameScore = 0;
  bool _gameFinished = false;
  int? _selectedAnswerIndex;
  bool _answeredThisRound = false;
  // Flappy Drone
  double _droneY = 0.0;
  double _droneVelocity = 0.0;
  double _barrierX = 1.0;
  double _gapTop = -0.2;
  Timer? _flappyTimer;
  bool _flappyStarted = false;
  bool _flappyDead = false;
  int _flappyScore = 0;
  // Password Cracker
  int _passwordLevel = 0;
  String? _passwordSelected;
  bool _passwordAnswered = false;

  final List<Map<String, dynamic>> _patrolRounds = [
    {
      'sender': 'security@paypal-verification-alert.com',
      'message': 'URGENT: Your account has been suspended due to suspicious login activity. Click here to verify your identity immediately: http://paypal-verify-user.net/login_session',
      'isPhishing': true,
      'explanation': 'Phishing! The domain "paypal-verify-user.net" is an unofficial impersonation link designed to steal credentials.',
    },
    {
      'sender': 'support@github.com',
      'message': 'Security Alert: A new SSH key was added to your account from IP address 192.168.1.1. If this was you, no action is needed.',
      'isPhishing': false,
      'explanation': 'Safe! This is a standard security notification sent from Github\'s official support email.',
    },
    {
      'sender': 'hr-benefits@yourcompany-benefits.com',
      'message': 'Employee Perks: Click this link to download the updated Q3 salary appraisal sheet: http://benefits-dl-auth.ru/appraisals/q3_spreadsheet.exe',
      'isPhishing': true,
      'explanation': 'Phishing! Downloading files with executable extension (.exe) hosted on unofficial domains is highly dangerous.',
    }
  ];

  final List<Map<String, dynamic>> _triviaRounds = [
    {
      'question': 'What is the most secure authentication method?',
      'options': [
        'SMS-based OTP',
        'Hardware Security Key (e.g., YubiKey)',
        'Personal Security Questions',
        'Static Passwords'
      ],
      'correctIndex': 1,
      'explanation': 'Hardware keys are immune to session hijacking and traditional credential phishing attacks.',
    },
    {
      'question': 'Which protocol encrypts web traffic to ensure confidentiality?',
      'options': [
        'HTTP',
        'FTP',
        'HTTPS',
        'SMTP'
      ],
      'correctIndex': 2,
      'explanation': 'HTTPS encrypts transport-layer data using TLS, preventing eavesdropping and tampering.',
    },
    {
      'question': 'What is "Social Engineering" primarily based on?',
      'options': [
        'Exploiting software firewalls',
        'Manipulating human psychology',
        'Brute-forcing dynamic database keys',
        'Decryption of system hashes'
      ],
      'correctIndex': 1,
      'explanation': 'Social Engineering manipulates human trust, fear, or urgency to bypass security protocols.',
    }
  ];

  final List<Map<String, dynamic>> _passwordLevels = [
    {
      'scenario': 'A hacker is running a dictionary attack. Which password survives?',
      'options': ['password123', 'fluffy2020', 'Tr0ub4dor&3', 'abc123'],
      'correctIndex': 2,
      'explanation': '"Tr0ub4dor&3" uses mixed case, numbers and symbols — resistant to dictionary attacks.',
    },
    {
      'scenario': 'You find a login page with NO HTTPS padlock. What do you do?',
      'options': ['Log in quickly', 'Use incognito mode', 'Leave the page immediately', 'Disable cookies'],
      'correctIndex': 2,
      'explanation': 'Without HTTPS, credentials are transmitted in plaintext — never log in on HTTP pages.',
    },
    {
      'scenario': 'A pop-up says "Your PC is infected! Call 1-800-SUPPORT NOW!" What is this?',
      'options': ['Legitimate antivirus alert', 'Scareware / Tech Support Scam', 'Windows Defender warning', 'System crash report'],
      'correctIndex': 1,
      'explanation': 'This is Scareware — a social engineering tactic designed to frighten users into calling fake support lines.',
    },
  ];

  void _startFlappy() {
    _droneY = 0.0;
    _droneVelocity = 0.0;
    _barrierX = 1.0;
    _gapTop = -0.3; // Center-aligned start
    _flappyScore = 0;
    _flappyStarted = true;
    _flappyDead = false;
    _flappyTimer?.cancel();
    _flappyTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!mounted) return;
      setState(() {
        _droneVelocity += 0.009; // Ultra-smooth low gravity (Easy mode!)
        _droneY += _droneVelocity;
        _barrierX -= 0.015; // Slower, comfortable packet movement speed
        if (_barrierX < -1.2) {
          _barrierX = 1.2;
          _gapTop = ((_flappyScore % 3) - 1) * 0.25; // Balanced vertical positions
          _flappyScore++;
        }
        if (_droneY > 0.95 || _droneY < -0.95) {
          _flappyDead = true;
          _flappyTimer?.cancel();
          _gameScore += _flappyScore * 5;
        }
        const double droneCenterX = -0.1;
        if ((_barrierX - droneCenterX).abs() < 0.08) { // Fair, forgiving hitboxes!
          final double gapBottom = _gapTop + 0.72; // Much wider, generous gap size
          if (_droneY < _gapTop || _droneY > gapBottom) {
            _flappyDead = true;
            _flappyTimer?.cancel();
            _gameScore += _flappyScore * 5;
          }
        }
      });
    });
  }

  void _flapDrone() {
    if (!_flappyStarted || _flappyDead) return;
    setState(() => _droneVelocity = -0.065); // Soft hover glide thrust
  }

  @override
  void dispose() {
    _flappyTimer?.cancel();
    super.dispose();
  }

  static const List<Map<String, dynamic>> _games = [
    {'id': 'patrol',   'title': 'Phishing\nPatrol',   'subtitle': 'Spot the threat',     'xp': '+10 XP/Rd', 'icon': Icons.radar_rounded,    'g1': Color(0xFFFF6B35), 'g2': Color(0xFFFF8B3D), 'diff': 'MEDIUM'},
    {'id': 'trivia',   'title': 'Cyber\nTrivia',      'subtitle': 'Security quiz',        'xp': '+10 XP/Rd', 'icon': Icons.bolt_rounded,     'g1': Color(0xFF7B2FBE), 'g2': Color(0xFF9B4FDE), 'diff': 'HARD'},
    {'id': 'flappy',   'title': 'Firewall\nDrone',    'subtitle': 'Dodge data packets',   'xp': '+5 XP/pt',  'icon': Icons.flight_rounded,   'g1': Color(0xFF0EA5E9), 'g2': Color(0xFF38BDF8), 'diff': 'EASY'},
    {'id': 'password', 'title': 'Password\nCracker',  'subtitle': 'Pick the safe key',    'xp': '+10 XP/Rd', 'icon': Icons.lock_rounded,     'g1': Color(0xFF059669), 'g2': Color(0xFF34D399), 'diff': 'MEDIUM'},
  ];

  Widget _buildModuleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('GAME LIBRARY', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold, color: CyberTheme.textPrimary, letterSpacing: 0.8)),
        const SizedBox(height: 4),
        Text('Earn XP and climb the leaderboard', style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textSecondary)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 1.0,
          ),
          itemCount: _games.length,
          itemBuilder: (context, i) {
            final g = _games[i];
            final c1 = g['g1'] as Color;
            final c2 = g['g2'] as Color;
            return GestureDetector(
              onTap: () => setState(() {
                _activeGame = g['id'] as String;
                _gameRound = 0; _gameScore = 0; _gameFinished = false;
                _answeredThisRound = false; _selectedAnswerIndex = null;
                _passwordLevel = 0; _passwordSelected = null; _passwordAnswered = false;
                _flappyStarted = false; _flappyDead = false;
              }),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [c1, c2], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: c1.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: Stack(children: [
                  Positioned(right: -16, bottom: -16, child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
                  )),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: Icon(g['icon'] as IconData, color: Colors.white, size: 22),
                      ),
                      const Spacer(),
                      Text(g['title'] as String, style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
                      const SizedBox(height: 4),
                      Text(g['subtitle'] as String, style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(0.8))),
                      const SizedBox(height: 8),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(99)),
                          child: Text(g['xp'] as String, style: GoogleFonts.spaceGrotesk(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        const Spacer(),
                        Text(g['diff'] as String, style: GoogleFonts.spaceGrotesk(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.7))),
                      ]),
                    ]),
                  ),
                ]),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActiveGameView() {
    if (_gameFinished) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B1C1C), Color(0xFF2E2E2E)],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: CyberTheme.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: CyberTheme.primary, size: 48),
                ),
                const SizedBox(height: 24),
                Text(
                  'TRAINING COMPLETE',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _activeGame == 'patrol' ? 'Phishing Patrol Module' : 'Cyber Trivia Hack Module',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: CyberTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(color: Colors.white12, height: 40),
                Text(
                  'SCORE ACCUMULATED',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white38,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '+$_gameScore XP',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You got ${_gameScore ~/ 10} out of 3 correct answers!',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final success = await ref.read(authProvider.notifier).addReputationPoints(_gameScore);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'SCORE SUBMITTED! +$_gameScore XP reflected on Global Leaderboard.',
                      style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                );
                setState(() {
                  _activeGame = null;
                  _gameFinished = false;
                });
              }
            },
            icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
            label: Text(
              'SUBMIT SCORE TO LEADERBOARD',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: CyberTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => setState(() {
              _activeGame = null;
              _gameFinished = false;
            }),
            child: Text(
              'CHOOSE ANOTHER MODULE',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: CyberTheme.textPrimary, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              side: const BorderSide(color: Color(0xFFEFEDED), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
            ),
          ),
        ],
      );
    }

    if (_activeGame == 'patrol') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: CyberTheme.textPrimary),
                onPressed: () => setState(() => _activeGame = null),
              ),
              Text(
                'PHISHING PATROL',
                style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: CyberTheme.textPrimary),
              ),
              const Spacer(),
              Text(
                'ROUND ${_gameRound + 1} OF 3',
                style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1C1C),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.alternate_email_rounded, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'SENDER: ${_patrolRounds[_gameRound]['sender']}',
                        style: GoogleFonts.spaceGrotesk(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 24),
                Text(
                  _patrolRounds[_gameRound]['message'],
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 12.5, height: 1.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (!_answeredThisRound) ...[
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _answeredThisRound = true;
                  final isPhishing = _patrolRounds[_gameRound]['isPhishing'];
                  if (isPhishing) _gameScore += 10;
                });
              },
              icon: const Icon(Icons.gavel_rounded, color: Colors.white),
              label: Text(
                'FLAG AS PHISHING CAMPAIGN',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _answeredThisRound = true;
                  final isPhishing = _patrolRounds[_gameRound]['isPhishing'];
                  if (!isPhishing) _gameScore += 10;
                });
              },
              icon: const Icon(Icons.verified_user_outlined, color: Colors.green),
              label: Text(
                'APPROVE AS LEGITIMATE TRAFFIC',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                side: const BorderSide(color: Colors.green, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEFEDED)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'EXPLANATION',
                        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.orange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _patrolRounds[_gameRound]['explanation'],
                    style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textSecondary, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_gameRound < 2) {
                  setState(() {
                    _gameRound++;
                    _answeredThisRound = false;
                  });
                } else {
                  setState(() {
                    _gameFinished = true;
                  });
                }
              },
              child: Text(
                _gameRound < 2 ? 'CONTINUE ➔' : 'FINISH TRAINING ➔',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: CyberTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
              ),
            ),
          ],
        ],
      );
    }

    if (_activeGame == 'trivia') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: CyberTheme.textPrimary),
                onPressed: () => setState(() => _activeGame = null),
              ),
              Text(
                'TRIVIA HACK',
                style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: CyberTheme.textPrimary),
              ),
              const Spacer(),
              Text(
                'ROUND ${_gameRound + 1} OF 3',
                style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1C1C),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
            ),
            child: Text(
              _triviaRounds[_gameRound]['question'],
              style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, height: 1.45),
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(4, (index) {
            final isSelected = _selectedAnswerIndex == index;
            final isCorrect = index == _triviaRounds[_gameRound]['correctIndex'];
            
            Color cardBorder = const Color(0xFFEFEDED);
            Color cardBg = Colors.white;
            Color textCol = CyberTheme.textPrimary;

            if (_answeredThisRound) {
              if (isCorrect) {
                cardBorder = Colors.green;
                cardBg = Colors.green.withOpacity(0.04);
                textCol = Colors.green;
              } else if (isSelected) {
                cardBorder = CyberTheme.danger;
                cardBg = CyberTheme.danger.withOpacity(0.04);
                textCol = CyberTheme.danger;
              }
            } else if (isSelected) {
              cardBorder = CyberTheme.primary;
              cardBg = CyberTheme.primary.withOpacity(0.04);
              textCol = CyberTheme.primary;
            }

            return GestureDetector(
              onTap: _answeredThisRound
                  ? null
                  : () {
                      setState(() {
                        _selectedAnswerIndex = index;
                        _answeredThisRound = true;
                        if (isCorrect) _gameScore += 10;
                      });
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: cardBorder, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        String.fromCharCode(65 + index),
                        style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold, color: textCol),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _triviaRounds[_gameRound]['options'][index],
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: textCol),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          if (_answeredThisRound) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEFEDED)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.purple, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'EXPLANATION',
                        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.purple),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _triviaRounds[_gameRound]['explanation'],
                    style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textSecondary, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_gameRound < 2) {
                  setState(() {
                    _gameRound++;
                    _selectedAnswerIndex = null;
                    _answeredThisRound = false;
                  });
                } else {
                  setState(() {
                    _gameFinished = true;
                  });
                }
              },
              child: Text(
                _gameRound < 2 ? 'CONTINUE ➔' : 'FINISH TRAINING ➔',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: CyberTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
              ),
            ),
          ],
        ],
      );
    }

    if (_activeGame == 'flappy') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back_rounded, color: CyberTheme.textPrimary), onPressed: () { _flappyTimer?.cancel(); setState(() => _activeGame = null); }),
            Text('FIREWALL DRONE', style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: CyberTheme.textPrimary)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF0EA5E9).withOpacity(0.1), borderRadius: BorderRadius.circular(99)),
              child: Text('SCORE: $_flappyScore', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0EA5E9))),
            ),
          ]),
          const SizedBox(height: 12),
          Container(
            height: (MediaQuery.of(context).size.height - 240).clamp(360.0, 580.0),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1628),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF0EA5E9).withOpacity(0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: GestureDetector(
                onTap: () {
                  if (!_flappyStarted || _flappyDead) {
                    _startFlappy();
                  } else {
                    _flapDrone();
                  }
                },
                child: Stack(children: [
                  // Background grid lines
                  Positioned.fill(
                    child: CustomPaint(painter: _GridPainter()),
                  ),
                  
                  // Responsive Barrier Layout Builder (Easy Mode!)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double totalHeight = constraints.maxHeight;
                      final double topBarrierHeight = (totalHeight * (_gapTop + 1.0) / 2).clamp(0.0, totalHeight);
                      final double bottomBarrierHeight = (totalHeight * (0.28 - _gapTop) / 2).clamp(0.0, totalHeight);

                      return Stack(
                        children: [
                          // Top Barrier
                          Align(
                            alignment: Alignment(_barrierX, -1.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 32, height: topBarrierHeight, color: const Color(0xFF0EA5E9).withOpacity(0.7)),
                                Container(width: 32, height: 8, decoration: BoxDecoration(color: const Color(0xFF0EA5E9), borderRadius: BorderRadius.circular(4))),
                              ],
                            ),
                          ),
                          // Bottom Barrier
                          Align(
                            alignment: Alignment(_barrierX, 1.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 32, height: 8, decoration: BoxDecoration(color: const Color(0xFF0EA5E9), borderRadius: BorderRadius.circular(4))),
                                Container(width: 32, height: bottomBarrierHeight, color: const Color(0xFF0EA5E9).withOpacity(0.7)),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // Drone
                  Align(
                    alignment: Alignment(-0.1, _droneY),
                    child: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: const Color(0xFFFF6B35).withOpacity(0.5), blurRadius: 8)],
                      ),
                      child: const Icon(Icons.flight_rounded, color: Colors.white, size: 20),
                    ),
                  ),

                  // Start / Dead overlay
                  if (!_flappyStarted || _flappyDead)
                    Container(
                      color: Colors.black.withOpacity(0.65),
                      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_flappyDead ? Icons.broken_image_rounded : Icons.play_circle_fill_rounded, color: const Color(0xFF0EA5E9), size: 64),
                        const SizedBox(height: 16),
                        Text(_flappyDead ? 'DRONE CRASHED!\nTap to Restart' : 'Tap to Launch Drone', textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 12),
                        if (_flappyDead) ...[
                          Text('Packets dodged: $_flappyScore  |  XP earned: ${_flappyScore * 5}',
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                          const SizedBox(height: 16),
                        ],
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'HOW TO PLAY: Tap anywhere inside the screen to thrust your Drone upward. Guide it through the gaps in the firewall data packets to dodge them. Each packet earns +5 XP!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 11, color: Colors.white60, height: 1.4),
                          ),
                        ),
                      ])),
                    ),
                ]),
              ),
            ),
          ),

          if (_flappyDead && _gameScore > 0) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final success = await ref.read(authProvider.notifier).addReputationPoints(_gameScore);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('SCORE SUBMITTED! +$_gameScore XP on Leaderboard.', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.green, behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ));
                  setState(() { _activeGame = null; _gameScore = 0; });
                }
              },
              icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
              label: Text('SUBMIT +$_gameScore XP TO LEADERBOARD', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), backgroundColor: const Color(0xFF0EA5E9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99))),
            ),
          ],
        ],
      );
    }

    if (_activeGame == 'password') {
      if (_gameFinished) {
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF34D399)]), borderRadius: BorderRadius.circular(28)),
            child: Column(children: [
              const Icon(Icons.lock_open_rounded, color: Colors.white, size: 56),
              const SizedBox(height: 16),
              Text('VAULT UNLOCKED!', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0)),
              const SizedBox(height: 8),
              Text('+$_gameScore XP', style: GoogleFonts.spaceGrotesk(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
            ]),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              final success = await ref.read(authProvider.notifier).addReputationPoints(_gameScore);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('SCORE SUBMITTED! +$_gameScore XP on Leaderboard.', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.green, behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ));
                setState(() { _activeGame = null; _gameFinished = false; });
              }
            },
            icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
            label: Text('SUBMIT SCORE TO LEADERBOARD', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), backgroundColor: CyberTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99))),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => setState(() { _activeGame = null; _gameFinished = false; }),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), side: const BorderSide(color: Color(0xFFEFEDED), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99))),
            child: Text('CHOOSE ANOTHER MODULE', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: CyberTheme.textPrimary, fontSize: 13)),
          ),
        ]);
      }
      final level = _passwordLevels[_passwordLevel];
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back_rounded, color: CyberTheme.textPrimary), onPressed: () => setState(() => _activeGame = null)),
          Text('PASSWORD CRACKER', style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: CyberTheme.textPrimary)),
          const Spacer(),
          Text('LEVEL ${_passwordLevel + 1}/3', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF059669))),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF1B1C1C), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF059669).withOpacity(0.3))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Icon(Icons.lock_rounded, color: Color(0xFF34D399), size: 16), const SizedBox(width: 8), Text('SECURITY SCENARIO', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 10))]),
            const Divider(color: Colors.white10, height: 20),
            Text(level['scenario'] as String, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, height: 1.45)),
          ]),
        ),
        const SizedBox(height: 20),
        ...List.generate(4, (i) {
          final opts = level['options'] as List;
          final isCorrect = i == level['correctIndex'];
          final isSelected = _passwordSelected == opts[i];
          Color bg = Colors.white;
          Color border = const Color(0xFFEFEDED);
          Color txt = CyberTheme.textPrimary;
          if (_passwordAnswered) {
            if (isCorrect) { bg = Colors.green.withOpacity(0.05); border = Colors.green; txt = Colors.green; }
            else if (isSelected) { bg = CyberTheme.danger.withOpacity(0.05); border = CyberTheme.danger; txt = CyberTheme.danger; }
          } else if (isSelected) { bg = CyberTheme.primary.withOpacity(0.05); border = CyberTheme.primary; txt = CyberTheme.primary; }
          return GestureDetector(
            onTap: _passwordAnswered ? null : () => setState(() { _passwordSelected = opts[i] as String; _passwordAnswered = true; if (isCorrect) _gameScore += 10; }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: border, width: 1.5)),
              child: Row(children: [
                Container(width: 22, height: 22, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: border, width: 1.5)), alignment: Alignment.center,
                  child: Text(String.fromCharCode(65 + i), style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold, color: txt))),
                const SizedBox(width: 14),
                Expanded(child: Text(opts[i] as String, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: txt))),
              ]),
            ),
          );
        }),
        if (_passwordAnswered) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFEFEDED))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const Icon(Icons.info_outline_rounded, color: Color(0xFF059669), size: 16), const SizedBox(width: 8), Text('EXPLANATION', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 10, color: const Color(0xFF059669)))]),
              const SizedBox(height: 6),
              Text(level['explanation'] as String, style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textSecondary, height: 1.45)),
            ]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {
              if (_passwordLevel < 2) { _passwordLevel++; _passwordSelected = null; _passwordAnswered = false; }
              else { _gameFinished = true; }
            }),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), backgroundColor: const Color(0xFF059669), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99))),
            child: Text(_passwordLevel < 2 ? 'NEXT LEVEL ➔' : 'FINISH ➔', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
          ),
        ],
      ]);
    }

    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_activeGame == null) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [CyberTheme.primary, Color(0xFFFF8B3D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: CyberTheme.primary.withOpacity(0.24),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CYBER ARCADE',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Challenge your cybersecurity reflexes with interactive simulations to build ultimate human defense matrices.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _buildModuleSelection(),
          ] else ...[
            _buildActiveGameView(),
          ],
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || !size.width.isFinite || !size.height.isFinite) {
      return;
    }
    final paint = Paint()
      ..color = const Color(0xFF0EA5E9).withOpacity(0.08)
      ..strokeWidth = 0.5;
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(_GridPainter old) => false;
}

/*
class _LegacyScaffold {
              unselectedLabelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 11.5, letterSpacing: 0.5),
              tabs: const [
                Tab(text: 'HEURISTIC SCANNER'),
                Tab(text: 'REPORT FRAUD'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // SCANNER TAB
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B1C1C), Color(0xFF2E2E2E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.bolt_rounded, color: Colors.orange, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Neural Intelligent Core',
                                style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'HEURISTIC SCANNER INSTANCE',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Feed malicious payloads, URL domains, or raw email text into the scanner. Our AI-driven sentinel parses syntax elements and checks against global fraud models instantly.',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: Colors.white70,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                Text(
                  'PASTE RAW PAYLOAD',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: CyberTheme.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFEFEDED)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.01),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: TextField(
                    controller: _contentController,
                    maxLines: 5,
                    style: GoogleFonts.inter(color: CyberTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Enter suspicious link, phishing mail copy or text here...',
                      border: InputBorder.none,
                      hintStyle: GoogleFonts.inter(color: CyberTheme.textMuted, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                if (isLoading)
                  const Center(child: CircularProgressIndicator(color: CyberTheme.primary))
                else
                  ElevatedButton.icon(
                    onPressed: _analyzeContent,
                    icon: const Icon(Icons.radar_rounded, size: 18, color: Colors.white),
                    label: Text(
                      'EXECUTE NEURAL DIAGNOSIS',
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: CyberTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                      elevation: 4,
                      shadowColor: CyberTheme.primary.withOpacity(0.3),
                    ),
                  ),
                
                if (_result != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1C1C),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: _result!.score >= 70 ? CyberTheme.danger : Colors.amber,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_result!.score >= 70 ? CyberTheme.danger : Colors.amber).withOpacity(0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (_result!.score >= 70 ? CyberTheme.danger : Colors.amber).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: _result!.score >= 70 ? CyberTheme.danger : Colors.amber,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'STATUS: ${_result!.threatLevel.toUpperCase()}',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: _result!.score >= 70 ? CyberTheme.danger : Colors.amber,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${_result!.score}% Threat Score',
                              style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.bold,
                                color: _result!.score >= 70 ? CyberTheme.danger : Colors.amber,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'NEURAL ANALYSIS SUMMARY',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SCANNER: ${_result!.analyzerName} | CONFIDENCE: ${_result!.confidence}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.white38,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Divider(color: Colors.white12, height: 24),
                        if (_result!.indicators.isNotEmpty) ...[
                          Text(
                            'SUSPICIOUS SIGNATURES FOUND:',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._result!.indicators.map((ind) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: CyberTheme.danger, size: 14),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    ind,
                                    style: GoogleFonts.inter(fontSize: 11.5, color: Colors.white.withOpacity(0.9)),
                                  ),
                                ),
                              ],
                            ),
                          )),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          'RECOMMENDED ACTION PLAN:',
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._result!.recommendations.map((rec) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 14),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  rec,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white70,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),

          // REPORT TAB
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [CyberTheme.primary, Color(0xFFFF8B3D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: CyberTheme.primary.withOpacity(0.24),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Global Threat Ledger',
                              style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Every threat you broadcast protects thousands of peers. Validated entries instantly earn you +30 reputation XP.',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: Colors.white.withOpacity(0.9),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                
                Text(
                  'SCAM TITLE',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: CyberTheme.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEFEDED)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: TextField(
                    controller: _titleController,
                    style: GoogleFonts.inter(color: CyberTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'e.g., Fake Tax Refund Email Campaign',
                      border: InputBorder.none,
                      hintStyle: GoogleFonts.inter(color: CyberTheme.textMuted, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                Text(
                  'CLASSIFICATION TAGS',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: CyberTheme.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildClassificationPill('phishing', 'Email Phishing', Icons.alternate_email_rounded),
                    _buildClassificationPill('vishing', 'Voice Call (Vishing)', Icons.phone_callback_rounded),
                    _buildClassificationPill('impersonation', 'Impersonation', Icons.people_outline_rounded),
                    _buildClassificationPill('crypto_scam', 'Crypto Scam', Icons.currency_bitcoin_rounded),
                    _buildClassificationPill('malware', 'Malware Dist', Icons.bug_report_outlined),
                  ],
                ),
                const SizedBox(height: 24),
                
                Text(
                  'DETAILED THREAT DESCRIPTION',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: CyberTheme.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEFEDED)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: TextField(
                    controller: _descController,
                    maxLines: 4,
                    style: GoogleFonts.inter(color: CyberTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Include sender details, dynamic link URLs, numbers, payloads, etc...',
                      border: InputBorder.none,
                      hintStyle: GoogleFonts.inter(color: CyberTheme.textMuted, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                Text(
                  'EVIDENCE URL (OPTIONAL)',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: CyberTheme.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEFEDED)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: TextField(
                    controller: _evidenceController,
                    style: GoogleFonts.inter(color: CyberTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Paste screenshot or threat URL link',
                      border: InputBorder.none,
                      hintStyle: GoogleFonts.inter(color: CyberTheme.textMuted, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                
                if (isLoading)
                  const Center(child: CircularProgressIndicator(color: CyberTheme.primary))
                else
                  ElevatedButton.icon(
                    onPressed: _submitReport,
                    icon: const Icon(Icons.campaign_outlined, size: 18, color: Colors.white),
                    label: Text(
                      'BROADCAST THREAT TO GRID',
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: CyberTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                      elevation: 4,
                      shadowColor: CyberTheme.primary.withOpacity(0.3),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
      ),
    );
  }
}
*/

// ===================== NEW VIEW: LEADERBOARD PODIUM SCREEN (High-Fidelity) =====================
class _LeaderboardView extends ConsumerStatefulWidget {
  const _LeaderboardView({Key? key}) : super(key: key);

  @override
  ConsumerState<_LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends ConsumerState<_LeaderboardView> {
  int _selectedLeaderboardTab = 0;
  final List<String> _tabs = ['Global', 'This Month', 'Friends'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tabs Bar Labeled Global / Monthly / Friends
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedLeaderboardTab == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedLeaderboardTab = index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected ? CyberTheme.primary : Colors.white,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: isSelected ? CyberTheme.primary : const Color(0xFFEFEDED),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _tabs[index],
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isSelected ? Colors.white : CyberTheme.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),

            // Extruded 3D Podium Layout matching Leaderboard Design exactly
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 2ND PLACE PODIUM (Left)
                Expanded(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFC0C0C0), width: 3),
                              image: const DecorationImage(
                                image: NetworkImage('https://api.dicebear.com/7.x/adventurer/png?seed=SecureMind'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFC0C0C0),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '2',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'SecureMind',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: CyberTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '9,450 Pts',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: CyberTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          border: Border.all(color: const Color(0xFFEFEDED)),
                        ),
                        child: Center(
                          child: Text(
                            '2nd',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFC0C0C0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // 1ST PLACE PODIUM (Center)
                Expanded(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: CyberTheme.primary, width: 4),
                              image: const DecorationImage(
                                image: NetworkImage('https://api.dicebear.com/7.x/adventurer/png?seed=CyberNinja'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: CyberTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '1',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'CyberNinja',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: CyberTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '12,840 Pts',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: CyberTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          border: Border.all(color: CyberTheme.primary.withOpacity(0.3), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: CyberTheme.primary.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '1st',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: CyberTheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // 3RD PLACE PODIUM (Right)
                Expanded(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFCD7F32), width: 3),
                              image: const DecorationImage(
                                image: NetworkImage('https://api.dicebear.com/7.x/adventurer/png?seed=HackPro'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFCD7F32),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '3',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'HackPro',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: CyberTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '8,210 Pts',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: CyberTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          border: Border.all(color: const Color(0xFFEFEDED)),
                        ),
                        child: Center(
                          child: Text(
                            '3rd',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFCD7F32),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Ranked List View of other players
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE5E7EB),
                    blurRadius: 8,
                    offset: const Offset(4, 4),
                  ),
                  const BoxShadow(
                    color: Colors.white,
                    blurRadius: 8,
                    offset: Offset(-4, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _leaderboardItem(4, 'ThreatHunter', '7,650 Pts', 'ThreatHunter'),
                  const Divider(color: Color(0xFFEFEDED), height: 1),
                  _leaderboardItem(5, 'NetWarrior', '6,920 Pts', 'NetWarrior'),
                  const Divider(color: Color(0xFFEFEDED), height: 1),
                  _leaderboardItem(6, 'SecurityFirst', '5,430 Pts', 'SecurityFirst'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Highlighted current user ranking card matching mockup exactly
            (() {
              final profile = ref.watch(authProvider).userProfile;
              final username = profile?['username'] ?? 'User';
              final rep = profile?['reputation_points'] ?? 10;
              final userRank = profile?['rank'] ?? 'WhiteHat Trainee';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9F5), // Brand-tinted highlighted background
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD4B2).withOpacity(0.45),
                      blurRadius: 10,
                      offset: const Offset(4, 4),
                    ),
                    const BoxShadow(
                      color: Colors.white,
                      blurRadius: 10,
                      offset: Offset(-4, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      '#12',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: CyberTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: CyberTheme.primary.withOpacity(0.1),
                      backgroundImage: NetworkImage(
                        'https://api.dicebear.com/7.x/adventurer/png?seed=$username&backgroundColor=ffd5b4',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You ($username)',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: CyberTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            userRank,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: CyberTheme.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$rep Pts',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: CyberTheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            })(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _leaderboardItem(int rank, String name, String pts, String seed) {
    return ListTile(
      leading: SizedBox(
        width: 80,
        child: Row(
          children: [
            Text(
              '$rank',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: CyberTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://api.dicebear.com/7.x/adventurer/png?seed=$seed'),
            ),
          ],
        ),
      ),
      title: Text(
        name,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: CyberTheme.textPrimary,
        ),
      ),
      trailing: Text(
        pts,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: CyberTheme.textSecondary,
        ),
      ),
    );
  }
}

// ===================== VIEW 4: AGENT PROFILE (High-Fidelity Screen 8 & 6) =====================
class _AgentProfileView extends ConsumerWidget {
  const _AgentProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.userProfile;
    final postsAsync = ref.watch(postsProvider(null));

    if (user == null) {
      return const Center(child: CircularProgressIndicator(color: CyberTheme.primary));
    }

    final myId = int.tryParse(user['id']?.toString() ?? '0') ?? 0;
    final followersAsync = ref.watch(followersListProvider(myId));
    final myFollowersCount = followersAsync.maybeWhen(
      data: (list) => list.length.toString(),
      orElse: () => user['followers_count']?.toString() ?? '3',
    );

    final followingAsync = ref.watch(followingListProvider(myId));
    final myFollowingCount = followingAsync.maybeWhen(
      data: (list) => list.length.toString(),
      orElse: () => user['following_count']?.toString() ?? '0',
    );

    final myPostsCount = postsAsync.maybeWhen(
      data: (posts) => posts.where((p) => p.userId == myId).length.toString(),
      orElse: () => '0',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Avatar & Bio Card
          Column(
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: Image.network(
                          'https://api.dicebear.com/7.x/adventurer/png?seed=${user['avatar'] ?? user['username']}&backgroundColor=ffd5b4',
                          fit: BoxFit.cover,
                          errorBuilder: (context, _, __) => const Icon(Icons.person, size: 50, color: CyberTheme.primary),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: CyberTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user['username']?.toString() ?? 'CyberGuardian',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: CyberTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user['rank']?.toString() ?? 'Cyber Recruit',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: CyberTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  '${user['email'] ?? ''} • Member of CyberShield community',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CyberTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Gamified Games XP Progress card from Innvikta Screen 6
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFEFEDED)),
            ),
            child: Builder(builder: (context) {
              final rep = int.tryParse(user['reputation_points']?.toString() ?? '0') ?? 0;
              final nextLevel = ((rep ~/ 500) + 1) * 500;
              final progress = (rep % 500) / 500.0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Arcade XP Progress',
                        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 13, color: CyberTheme.textPrimary),
                      ),
                      Text(
                        '$rep / $nextLevel XP',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: CyberTheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: CyberTheme.surfaceLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(CyberTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: CyberTheme.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      const Icon(Icons.videogame_asset_outlined, color: CyberTheme.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Keep playing games to earn more XP and climb the leaderboard!',
                        style: GoogleFonts.inter(fontSize: 11, color: CyberTheme.textSecondary, fontWeight: FontWeight.bold))),
                      const Icon(Icons.arrow_forward_rounded, color: CyberTheme.primary, size: 16),
                    ]),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 24),
          
          // Stats Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE5E7EB),
                  blurRadius: 8,
                  offset: const Offset(4, 4),
                ),
                const BoxShadow(
                  color: Colors.white,
                  blurRadius: 8,
                  offset: Offset(-4, -4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _profileStatItem(myPostsCount, 'Posts'),
                Container(width: 1, height: 24, color: const Color(0xFFEFEDED)),
                _profileStatItem(
                  myFollowingCount, 
                  'Following',
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => UserListSheet(userId: myId, title: 'Following', isFollowers: false),
                    );
                  },
                ),
                Container(width: 1, height: 24, color: const Color(0xFFEFEDED)),
                _profileStatItem(
                  myFollowersCount, 
                  'Followers',
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => UserListSheet(userId: myId, title: 'Followers', isFollowers: true),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Text(
                'Gamified Stats',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: CyberTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
            ),
            children: [
              _gamifiedStatCard(user['badges_count']?.toString() ?? '0', 'Badges', Icons.stars_rounded, Colors.orange),
              _gamifiedStatCard(user['challenges_count']?.toString() ?? '0', 'Challenges', Icons.offline_bolt_rounded, Colors.blue),
              _gamifiedStatCard(user['reputation_points']?.toString() ?? '0', 'XP Points', Icons.emoji_events_rounded, Colors.amber),
              _gamifiedStatCard(user['streak_days']?.toString() ?? '0', 'Streak', Icons.local_fire_department_rounded, Colors.red),
            ],
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Text(
                'My Activity',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: CyberTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE5E7EB),
                  blurRadius: 8,
                  offset: const Offset(4, 4),
                ),
                const BoxShadow(
                  color: Colors.white,
                  blurRadius: 8,
                  offset: Offset(-4, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                _activityLinkItem(context, ref, user, 'My Posts', Icons.chat_bubble_outline_rounded),
                const Divider(color: Color(0xFFEFEDED), height: 1),
                _activityLinkItem(context, ref, user, 'Saved Posts', Icons.bookmark_outline_rounded),
                const Divider(color: Color(0xFFEFEDED), height: 1),
                _activityLinkItem(context, ref, user, 'My Discussions', Icons.forum_outlined),
                const Divider(color: Color(0xFFEFEDED), height: 1),
                _activityLinkItem(context, ref, user, 'Achievements', Icons.military_tech_outlined),
                const Divider(color: Color(0xFFEFEDED), height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CyberTheme.danger.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.logout_rounded, color: CyberTheme.danger, size: 18),
                  ),
                  title: Text(
                    'Sign Out',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: CyberTheme.danger,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: CyberTheme.textMuted),
                  onTap: () {
                    ref.read(authProvider.notifier).logout();
                    context.go('/login');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _profileStatItem(String count, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(
            count,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: onTap != null ? CyberTheme.primary : CyberTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: CyberTheme.textMuted,
              fontWeight: FontWeight.w600,
              decoration: onTap != null ? TextDecoration.underline : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gamifiedStatCard(String val, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5E7EB),
            blurRadius: 8,
            offset: const Offset(4, 4),
          ),
          const BoxShadow(
            color: Colors.white,
            blurRadius: 8,
            offset: Offset(-4, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                val,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: CyberTheme.textPrimary,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: CyberTheme.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityLinkItem(BuildContext context, WidgetRef ref, Map<String, dynamic> user, String title, IconData icon) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: CyberTheme.primary.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: CyberTheme.primary, size: 18),
      ),
      title: Text(
        title,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: CyberTheme.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: CyberTheme.textMuted),
      onTap: () {
        if (title == 'My Posts' || title == 'Saved Posts' || title == 'My Discussions') {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            builder: (context) => Consumer(
              builder: (context, ref, child) {
                final postsAsync = ref.watch(postsProvider(null));

                return Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: CyberTheme.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xFFEFEDED), height: 24),
                      const SizedBox(height: 12),
                      Expanded(
                        child: postsAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator(color: CyberTheme.primary)),
                          error: (err, stack) => Center(
                            child: Text(
                              'Error loading posts: $err',
                              style: GoogleFonts.spaceGrotesk(color: CyberTheme.danger, fontWeight: FontWeight.bold),
                            ),
                          ),
                          data: (posts) {
                            final savedIds = HiveBoxHelper.getSavedPostIds();
                            final myId = int.tryParse(user['id'].toString()) ?? -1;
                            final myUsername = user['username']?.toString().toLowerCase() ?? '';
                            final filtered = posts.where((post) {
                              if (title == 'My Posts') {
                                return post.userId == myId || post.authorName.toLowerCase() == myUsername;
                              } else if (title == 'Saved Posts') {
                                return savedIds.contains(post.id);
                              } else {
                                // My Discussions: posts I authored
                                return post.userId == myId || post.authorName.toLowerCase() == myUsername;
                              }
                            }).toList();

                            if (filtered.isEmpty) {
                              return Center(
                                child: Text(
                                  'No posts found.',
                                  style: GoogleFonts.spaceGrotesk(color: CyberTheme.textMuted, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final post = filtered[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: CyberTheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.shield_outlined, color: CyberTheme.primary, size: 20),
                                  ),
                                  title: Text(
                                    post.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    '${post.categoryName} • ${post.likesCount} likes • ${post.commentsCount} comments',
                                    style: GoogleFonts.inter(fontSize: 11, color: CyberTheme.textMuted),
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                                  onTap: () {
                                    Navigator.pop(context);
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                        title: Text(
                                          post.title,
                                          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: CyberTheme.textPrimary),
                                        ),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              Text(
                                                post.content,
                                                style: GoogleFonts.inter(fontSize: 13, color: CyberTheme.textSecondary, height: 1.5),
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'By: ${post.authorName} (${post.authorRank})',
                                                style: GoogleFonts.inter(fontSize: 11, color: CyberTheme.textMuted, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: Text('Close', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: CyberTheme.primary)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }
            ),
          );
        } else if (title == 'Achievements') {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: Text(
                'My Achievements',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: CyberTheme.textPrimary),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBadgeRow('Sentinel Officer', 'Earned for reporting 10+ valid threats.', Icons.verified_user_rounded, Colors.orange),
                  const SizedBox(height: 12),
                  _buildBadgeRow('Phishing Buster', 'Completed Arcade training with 100% score.', Icons.verified_rounded, Colors.blue),
                  const SizedBox(height: 12),
                  _buildBadgeRow('Top Contributor', 'Rewarded for community forum activity.', Icons.emoji_events_rounded, Colors.amber),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close', style: GoogleFonts.spaceGrotesk(color: CyberTheme.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildBadgeRow(String badgeTitle, String badgeDesc, IconData badgeIcon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(badgeIcon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                badgeTitle,
                style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                badgeDesc,
                style: GoogleFonts.inter(fontSize: 10, color: CyberTheme.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedLikeButton extends StatefulWidget {
  final int initialLikes;
  final VoidCallback? onLike;

  const _AnimatedLikeButton({
    Key? key,
    required this.initialLikes,
    this.onLike,
  }) : super(key: key);

  @override
  State<_AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<_AnimatedLikeButton> with SingleTickerProviderStateMixin {
  late int _likes;
  bool _isLiked = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _likes = widget.initialLikes;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likes++;
        _controller.forward().then((_) => _controller.reverse());
      } else {
        _likes--;
      }
    });
    if (widget.onLike != null) {
      widget.onLike!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(99),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(
                _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _isLiked ? CyberTheme.primary : CyberTheme.textMuted,
                size: 18,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$_likes',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _isLiked ? CyberTheme.primary : CyberTheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditProfileSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;
  const EditProfileSheet({Key? key, required this.user}) : super(key: key);

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  late TextEditingController _nameController;
  late String _avatarSeed;
  bool _isLoading = false;

  final List<String> _presetSeeds = [
    'Amos', 'Aria', 'Bailey', 'Cody', 'Dusty', 'Harlow', 'Jude', 'Leo', 'Milo', 'Oliver', 'Remi', 'Teddy'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['username']?.toString() ?? '');
    _avatarSeed = widget.user['avatar']?.toString() ?? widget.user['username']?.toString() ?? 'Amos';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFEFEDED),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Edit Profile Settings',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CyberTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Avatar Preview
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: CyberTheme.primary.withOpacity(0.2), width: 3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: Image.network(
                      'https://api.dicebear.com/7.x/adventurer/png?seed=$_avatarSeed&backgroundColor=ffd5b4',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final randomIdx = DateTime.now().millisecond % _presetSeeds.length;
                    setState(() {
                      _avatarSeed = _presetSeeds[randomIdx];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: CyberTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap the button to cycle avatar seeds',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: CyberTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),

          // Name Field Label
          Text(
            'AGENT USERNAME',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: CyberTheme.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFBFBF8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEFEDED)),
            ),
            child: TextField(
              controller: _nameController,
              readOnly: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Username',
                suffixIcon: Icon(Icons.lock_outline, size: 16, color: CyberTheme.textMuted),
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: CyberTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFEFEDED)),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: CyberTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    setState(() => _isLoading = true);
                    
                    final success = await ref.read(authProvider.notifier).updateProfile(
                      widget.user['username']?.toString() ?? '',
                      _avatarSeed,
                    );
                    
                    if (mounted) {
                      setState(() => _isLoading = false);
                      if (success) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Profile updated successfully!',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CyberTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Save Changes',
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
