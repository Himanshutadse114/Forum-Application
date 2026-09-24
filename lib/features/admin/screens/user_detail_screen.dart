import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cybershield_forum/core/theme.dart';
import 'package:cybershield_forum/features/admin/provider.dart';
import 'package:intl/intl.dart';

class UserDetailScreen extends ConsumerStatefulWidget {
  final int userId;
  
  const UserDetailScreen({super.key, required this.userId});

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminProvider.notifier).fetchUserDetail(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);
    final userDetail = state.userDetail;

    return Scaffold(
      backgroundColor: CyberTheme.background,
      appBar: AppBar(
        title: Text('Agent Dossier', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: CyberTheme.primary)),
        backgroundColor: CyberTheme.surface,
        iconTheme: const IconThemeData(color: CyberTheme.primary),
        elevation: 0.5,
      ),
      body: state.isLoading || userDetail == null
          ? const Center(child: CircularProgressIndicator(color: CyberTheme.primary))
          : RefreshIndicator(
              color: CyberTheme.primary,
              onRefresh: () => ref.read(adminProvider.notifier).fetchUserDetail(widget.userId),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfileHeader(userDetail['profile']),
                    const SizedBox(height: 24),
                    _buildProgressSection(userDetail['profile']),
                    const SizedBox(height: 24),
                    _buildGameScoresSection(userDetail['game_scores'] ?? []),
                    const SizedBox(height: 24),
                    _buildAchievementsSection(userDetail['achievements'] ?? []),
                    const SizedBox(height: 24),
                    _buildRecentPostsSection(userDetail['recent_posts'] ?? []),
                    _buildCommentsSection(userDetail['comments'] ?? []),
                    _buildLikesSection(userDetail['likes'] ?? []),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> profile) {
    final joinedDate = DateTime.tryParse(profile['created_at'].toString()) ?? DateTime.now();
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: CyberTheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: CyberTheme.primary, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: Image.network(
              'https://api.dicebear.com/7.x/adventurer/png?seed=${profile['avatar'] ?? profile['username']}&backgroundColor=ffd5b4',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile['username'],
                style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.bold, color: CyberTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                profile['email'],
                style: GoogleFonts.inter(fontSize: 14, color: CyberTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CyberTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CyberTheme.accent.withOpacity(0.3)),
                ),
                child: Text(
                  'Joined: ${DateFormat('MMM yyyy').format(joinedDate)}',
                  style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold, color: CyberTheme.accent),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(Map<String, dynamic> profile) {
    final rep = int.tryParse(profile['reputation_points'].toString()) ?? 0;
    final maxRep = rep < 250 ? 250 : (rep < 500 ? 500 : (rep < 1000 ? 1000 : 5000));
    final progress = (rep / maxRep).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: CyberTheme.neonGlowDecoration(color: CyberTheme.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Rank', style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Text(profile['rank'] ?? 'Recruit', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: CyberTheme.textPrimary)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Reputation XP', style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Text('$rep / $maxRep', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: CyberTheme.primary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: CyberTheme.primary.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(CyberTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameScoresSection(List<dynamic> scores) {
    if (scores.isEmpty) return const SizedBox.shrink();

    // Grouping scores by game_id for simple visualization
    final Map<String, List<int>> gameStats = {};
    for (var s in scores) {
      final id = s['game_id'].toString();
      final score = int.tryParse(s['score'].toString()) ?? 0;
      gameStats.putIfAbsent(id, () => []).add(score);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Arcade Analytics', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: CyberTheme.textPrimary)),
        const SizedBox(height: 12),
        ...gameStats.entries.map((e) {
          final maxScore = e.value.reduce((a, b) => a > b ? a : b);
          final totalPlays = e.value.length;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CyberTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEFEDED)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CyberTheme.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.sports_esports, color: CyberTheme.warning),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.key.replaceAll('_', ' ').toUpperCase(), style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Sessions Played: $totalPlays', style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Best Score', style: GoogleFonts.inter(fontSize: 10, color: CyberTheme.textSecondary)),
                    Text('$maxScore', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.bold, color: CyberTheme.textPrimary)),
                  ],
                )
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAchievementsSection(List<dynamic> achievements) {
    if (achievements.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Badges Unlocked', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: CyberTheme.textPrimary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: achievements.map((badge) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.military_tech, color: Colors.purple.shade600, size: 18),
                  const SizedBox(width: 6),
                  Text(badge['badge_name'], style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.purple.shade800)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentPostsSection(List<dynamic> posts) {
    if (posts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Intel (Posts)', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: CyberTheme.textPrimary)),
        const SizedBox(height: 12),
        ...posts.map((post) {
          final date = DateTime.tryParse(post['created_at'].toString()) ?? DateTime.now();
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CyberTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEFEDED)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post['title'], style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.bold, color: CyberTheme.textPrimary)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('MMM d, yyyy').format(date), style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textSecondary)),
                    Row(
                      children: [
                        const Icon(Icons.thumb_up_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${post['likes_count']}'),
                        const SizedBox(width: 12),
                        const Icon(Icons.comment_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${post['comments_count']}'),
                      ],
                    )
                  ],
                )
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCommentsSection(List<dynamic> comments) {
    if (comments.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text('Recent Comments', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: CyberTheme.textPrimary)),
        const SizedBox(height: 12),
        ...comments.map((comment) {
          final date = DateTime.tryParse(comment['created_at'].toString()) ?? DateTime.now();
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CyberTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEFEDED)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comment['content'], style: GoogleFonts.inter(fontSize: 14, color: CyberTheme.textPrimary)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('On: ${comment['post_title']}', style: GoogleFonts.spaceGrotesk(fontSize: 12, color: CyberTheme.primary, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ),
                    Text(DateFormat('MMM d, yyyy').format(date), style: GoogleFonts.inter(fontSize: 11, color: CyberTheme.textSecondary)),
                  ],
                )
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildLikesSection(List<dynamic> likes) {
    if (likes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text('Liked Posts', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: CyberTheme.textPrimary)),
        const SizedBox(height: 12),
        ...likes.map((like) {
          final date = DateTime.tryParse(like['created_at'].toString()) ?? DateTime.now();
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CyberTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEFEDED)),
            ),
            child: Row(
              children: [
                const Icon(Icons.thumb_up, color: CyberTheme.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(like['post_title'], style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.bold, color: CyberTheme.textPrimary)),
                ),
                Text(DateFormat('MMM d, yyyy').format(date), style: GoogleFonts.inter(fontSize: 11, color: CyberTheme.textSecondary)),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
