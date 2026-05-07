import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cybershield_forum/core/theme.dart';
import 'package:cybershield_forum/core/hive_box.dart';
import 'package:cybershield_forum/features/forum/provider.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final int postId;

  const PostDetailScreen({
    Key? key,
    required this.postId,
  }) : super(key: key);

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _isAnonymous = false;

  void _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final success = await ref.read(forumOperationsProvider.notifier).createComment(
      widget.postId,
      _commentController.text.trim(),
      _isAnonymous,
    );

    if (success && mounted) {
      _commentController.clear();
      ref.invalidate(commentsProvider(widget.postId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Comment posted successfully. Reward: +5 XP.', 
            style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)
          ),
          backgroundColor: CyberTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }

  void _toggleLike() async {
    await HiveBoxHelper.toggleSavedPostId(widget.postId);
    final success = await ref.read(forumOperationsProvider.notifier).toggleLike(widget.postId);
    if (success) {
      ref.invalidate(postsProvider(null));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Post like status updated.', 
            style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)
          ),
          backgroundColor: CyberTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(postsProvider(null));
    final commentsAsync = ref.watch(commentsProvider(widget.postId));

    return Scaffold(
      backgroundColor: CyberTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: CyberTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Thread Details',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            color: CyberTheme.textPrimary,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: postsAsync.when(
        data: (posts) {
          final post = posts.firstWhere(
            (p) => p.id == widget.postId,
            orElse: () => Post(
              id: widget.postId,
              userId: 0,
              categoryId: 0,
              title: 'Unknown Thread',
              content: 'The requested thread details could not be parsed or was deleted.',
              isAnonymous: false,
              likesCount: 0,
              commentsCount: 0,
              authorName: 'Grid System',
              authorAvatar: '',
              authorRank: 'Secure Kernel',
              categoryName: 'General Talk',
              createdAt: DateTime.now(),
            ),
          );

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Screen 3 "Blog Detail": Large orange shield hero graphic card
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: CyberTheme.primary,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: CyberTheme.primary.withOpacity(0.24),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Soft concentric circle decorations for premium vibe
                            Positioned(
                              right: -40,
                              top: -40,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.04),
                                ),
                              ),
                            ),
                            Positioned(
                              left: -30,
                              bottom: -30,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.04),
                                ),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.shield_outlined, 
                                  color: Colors.white, 
                                  size: 64
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    'CYBERSECURITY BRIEFING',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Category Tag matching Screen 3
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: CyberTheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              post.categoryName.toUpperCase(),
                              style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: CyberTheme.primary,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Title
                      Text(
                        post.title,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: CyberTheme.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Author Profile Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFEFEDED)),
                        ),
                        child: InkWell(
                          onTap: post.isAnonymous ? null : () => _showUserProfile(post.userId, post.authorName, post.authorRank),
                          borderRadius: BorderRadius.circular(24),
                          child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFEFEDED)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                  child: Image.network(
                                    post.isAnonymous 
                                        ? 'https://api.dicebear.com/7.x/bottts/png?seed=anonymous'
                                        : 'https://api.dicebear.com/7.x/adventurer/png?seed=${post.authorName}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, _, __) => const Icon(Icons.person, size: 24),
                                  ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.isAnonymous ? 'CyberGuardian' : post.authorName,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: post.isAnonymous ? CyberTheme.textPrimary : CyberTheme.primary,
                                      decoration: post.isAnonymous ? null : TextDecoration.underline,
                                      decorationColor: CyberTheme.primary,
                                    ),
                                  ),
                                  Text(
                                    post.isAnonymous ? 'Incognito' : post.authorRank,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: CyberTheme.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              DateFormat('MMM d, yy').format(post.createdAt),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: CyberTheme.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Main Briefing Body Text
                      Text(
                        post.content,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: CyberTheme.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Screen 3 "Key Takeaways" Checklists
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
                            Text(
                              'Key Takeaways',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: CyberTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _takeawayItem('Verify sender identity rigorously.'),
                            _takeawayItem('Never click unvalidated payload URLs.'),
                            _takeawayItem('Assume breach and audit endpoint logs.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Interactions metric row
                      Row(
                        children: [
                          InkWell(
                            onTap: _toggleLike,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: CyberTheme.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.thumb_up_alt_outlined, size: 18, color: CyberTheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${post.likesCount} Likes',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 13, 
                                      color: CyberTheme.primary, 
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFEDED),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: CyberTheme.textSecondary),
                                const SizedBox(width: 8),
                                Text(
                                  '${post.commentsCount} Comments',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13, 
                                    color: CyberTheme.textSecondary, 
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      Text(
                        'Community Responses',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: CyberTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      commentsAsync.when(
                        data: (comments) {
                          if (comments.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 32.0),
                                child: Text(
                                  'No responses yet. Be the first to reply below.', 
                                  style: GoogleFonts.inter(color: CyberTheme.textMuted, fontSize: 13)
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
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
                                        GestureDetector(
                                          onTap: comment.isAnonymous ? null : () => _showUserProfile(comment.userId, comment.authorName, comment.authorRank),
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(color: const Color(0xFFEFEDED)),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(99),
                                               child: Image.network(
                                                 comment.isAnonymous 
                                                     ? 'https://api.dicebear.com/7.x/bottts/png?seed=anonymous'
                                                     : 'https://api.dicebear.com/7.x/adventurer/png?seed=${comment.authorName}',
                                                 fit: BoxFit.cover,
                                                 errorBuilder: (context, _, __) => const Icon(Icons.person, size: 14),
                                               ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: comment.isAnonymous ? null : () => _showUserProfile(comment.userId, comment.authorName, comment.authorRank),
                                          child: Text(
                                            comment.isAnonymous ? 'CyberGuardian' : comment.authorName,
                                            style: GoogleFonts.spaceGrotesk(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: comment.isAnonymous ? CyberTheme.textPrimary : CyberTheme.primary,
                                              decoration: comment.isAnonymous ? null : TextDecoration.underline,
                                              decorationColor: CyberTheme.primary,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          DateFormat('MMM d, HH:mm').format(comment.createdAt),
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: CyberTheme.textMuted,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      comment.content,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: CyberTheme.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator(color: CyberTheme.primary)),
                        error: (e, _) => Center(child: Text('Error loading comments: $e')),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom commenting dock
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFEFEDED), width: 1)),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _isAnonymous,
                            activeColor: CyberTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (v) => setState(() => _isAnonymous = v!),
                          ),
                          Text(
                            'Post Anonymously (Incognito)',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12, 
                              fontWeight: FontWeight.bold, 
                              color: CyberTheme.textSecondary
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              style: GoogleFonts.inter(color: CyberTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                hintText: 'Share your perspective...',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                fillColor: CyberTheme.background,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(99),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Material(
                            color: CyberTheme.primary,
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: _submitComment,
                              borderRadius: BorderRadius.circular(99),
                              child: const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Icon(Icons.send_rounded, color: Colors.white, size: 18),
                              ),
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
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: CyberTheme.primary))),
        error: (e, _) => Scaffold(
          backgroundColor: CyberTheme.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: CyberTheme.textPrimary),
              onPressed: () => context.pop(),
            ),
            title: Text('Thread Details', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: CyberTheme.textPrimary, fontSize: 18)),
            centerTitle: true,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20)]),
                    child: const Icon(Icons.wifi_off_rounded, size: 52, color: CyberTheme.textMuted),
                  ),
                  const SizedBox(height: 24),
                  Text('No Connection', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.bold, color: CyberTheme.textPrimary)),
                  const SizedBox(height: 10),
                  Text(
                    'Could not reach the server.\nCheck your internet connection and try again.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 13, color: CyberTheme.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(postsProvider(null));
                      ref.invalidate(commentsProvider(widget.postId));
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text('Retry', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CyberTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showUserProfile(int userId, String username, String rank) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserProfileSheetContent(
        userId: userId,
        username: username,
        rank: rank,
      ),
    );
  }

  Widget _takeawayItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check_box_rounded, color: CyberTheme.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12, 
                fontWeight: FontWeight.w600, 
                color: CyberTheme.textPrimary
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared User Profile Bottom Sheet ───────────────────────────────────────
class _UserProfileSheetContent extends ConsumerStatefulWidget {
  final int userId;
  final String username;
  final String rank;
  const _UserProfileSheetContent({required this.userId, required this.username, required this.rank});

  @override
  ConsumerState<_UserProfileSheetContent> createState() => _UserProfileSheetContentState();
}

class _UserProfileSheetContentState extends ConsumerState<_UserProfileSheetContent> {
  bool _loading = false;
  int? _localFollowerCount; // tracks optimistic count

  Future<void> _toggle() async {
    setState(() => _loading = true);
    final wasFollowing = ref.read(followedUsersProvider).contains(widget.userId);
    
    // Optimistic update immediately
    if (wasFollowing) {
      ref.read(followedUsersProvider.notifier).unfollow(widget.userId);
    } else {
      ref.read(followedUsersProvider.notifier).follow(widget.userId);
    }
    
    setState(() {
      _localFollowerCount = (_localFollowerCount ?? 0) + (wasFollowing ? -1 : 1);
      if (_localFollowerCount! < 0) _localFollowerCount = 0;
    });

    final ok = wasFollowing
        ? await ref.read(forumOperationsProvider.notifier).unfollowUser(widget.userId)
        : await ref.read(forumOperationsProvider.notifier).followUser(widget.userId);

    if (mounted) {
      setState(() => _loading = false);
      final myId = HiveBoxHelper.getUserId() ?? 999;
      ref.invalidate(userProfileByIdProvider(widget.userId));
      ref.invalidate(userProfileByIdProvider(myId));
      ref.invalidate(followersListProvider(widget.userId));
      ref.invalidate(followingListProvider(myId));
      if (!ok) {
        // Revert if server failed
        if (wasFollowing) {
          ref.read(followedUsersProvider.notifier).follow(widget.userId);
        } else {
          ref.read(followedUsersProvider.notifier).unfollow(widget.userId);
        }
        setState(() {
          _localFollowerCount = (_localFollowerCount ?? 0) + (wasFollowing ? 1 : -1);
        });
      }
    }
  }

  void _showUserList(BuildContext ctx, String title, int userId, bool isFollowers) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UserListSheet(userId: userId, title: title, isFollowers: isFollowers),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(userPostsByIdProvider(widget.userId));
    final profileAsync = ref.watch(userProfileByIdProvider(widget.userId));

    // Seed _localFollowerCount from API on first load
    profileAsync.whenData((p) {
      if (_localFollowerCount == null && p != null) {
        _localFollowerCount = int.tryParse(p['followers_count']?.toString() ?? '0') ?? 0;
      }
    });

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (ctx, sc) => Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFEFEDED), borderRadius: BorderRadius.circular(99)),
          ),
          Expanded(child: SingleChildScrollView(
            controller: sc,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // Avatar + name + follow
              Row(children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: CyberTheme.primary.withOpacity(0.1),
                  backgroundImage: NetworkImage('https://api.dicebear.com/7.x/adventurer/png?seed=${widget.username}&backgroundColor=ffd5b4'),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.username, style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: CyberTheme.textPrimary)),
                  const SizedBox(height: 3),
                  profileAsync.when(
                    data: (p) => Text(p?['rank']?.toString() ?? widget.rank, style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textMuted, fontWeight: FontWeight.w600)),
                    loading: () => Text(widget.rank, style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textMuted)),
                    error: (_, __) => Text(widget.rank, style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textMuted)),
                  ),
                ])),
                _loading
                  ? const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 2, color: CyberTheme.primary))
                  : GestureDetector(
                      onTap: _toggle,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          color: ref.watch(followedUsersProvider).contains(widget.userId) ? Colors.white : CyberTheme.primary,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: CyberTheme.primary, width: 1.5),
                        ),
                        child: Text(
                          ref.watch(followedUsersProvider).contains(widget.userId) ? 'Following' : 'Follow',
                          style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold,
                            color: ref.watch(followedUsersProvider).contains(widget.userId) ? CyberTheme.primary : Colors.white),
                        ),
                      ),
                    ),
              ]),
              const SizedBox(height: 20),

              // Stats row — followers count is live, chips are tappable
              profileAsync.when(
                data: (p) {
                  final pc = p?['posts_count']?.toString() ?? postsAsync.maybeWhen(data: (posts) => posts.length.toString(), orElse: () => '0');
                  final fc = (_localFollowerCount ?? int.tryParse(p?['followers_count']?.toString() ?? '0') ?? 0).toString();
                  final fwc = p?['following_count']?.toString() ?? '0';
                  final xp = p?['reputation_points']?.toString() ?? '0';
                  return _statsRow(ctx, pc.toString(), fc, fwc, xp);
                },
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: CyberTheme.primary)),
                error: (_, __) {
                  final fc = (_localFollowerCount ?? 0).toString();
                  return postsAsync.maybeWhen(
                    data: (posts) => _statsRow(ctx, posts.length.toString(), fc, '—', '—'),
                    orElse: () => _statsRow(ctx, '0', fc, '—', '—'),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Recent Posts
              Text('Recent Posts', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.bold, color: CyberTheme.textPrimary)),
              const SizedBox(height: 12),
              postsAsync.when(
                data: (posts) {
                  if (posts.isEmpty) return Center(child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      const Icon(Icons.article_outlined, size: 36, color: CyberTheme.textMuted),
                      const SizedBox(height: 8),
                      Text('No posts yet', style: GoogleFonts.spaceGrotesk(color: CyberTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
                    ]),
                  ));
                  return Column(children: posts.take(5).map((p) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFEFEDED))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.title, style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold, color: CyberTheme.textPrimary)),
                      const SizedBox(height: 5),
                      Text(p.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 11, color: CyberTheme.textSecondary, height: 1.4)),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.favorite_border_rounded, size: 12, color: CyberTheme.textMuted),
                        const SizedBox(width: 3),
                        Text('${p.likesCount}', style: GoogleFonts.inter(fontSize: 10, color: CyberTheme.textMuted, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        const Icon(Icons.chat_bubble_outline_rounded, size: 12, color: CyberTheme.textMuted),
                        const SizedBox(width: 3),
                        Text('${p.commentsCount}', style: GoogleFonts.inter(fontSize: 10, color: CyberTheme.textMuted, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: CyberTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(99)),
                          child: Text(p.categoryName, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: CyberTheme.primary)),
                        ),
                      ]),
                    ]),
                  )).toList());
                },
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: CyberTheme.primary, strokeWidth: 2))),
                error: (_, __) => Center(child: Text('Could not load posts', style: GoogleFonts.inter(color: CyberTheme.textMuted, fontSize: 12))),
              ),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _statsRow(BuildContext ctx, String posts, String followers, String following, String xp) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(color: CyberTheme.background, borderRadius: BorderRadius.circular(18)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _chip(posts, 'Posts', null),
      Container(width: 1, height: 22, color: const Color(0xFFEFEDED)),
      _chip(followers, 'Followers', () => _showUserList(ctx, 'Followers', widget.userId, true)),
      Container(width: 1, height: 22, color: const Color(0xFFEFEDED)),
      _chip(following, 'Following', () => _showUserList(ctx, 'Following', widget.userId, false)),
      Container(width: 1, height: 22, color: const Color(0xFFEFEDED)),
      _chip(xp, 'XP', null),
    ]),
  );

  Widget _chip(String v, String l, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: Column(children: [
      Text(v, style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.bold,
        color: onTap != null ? CyberTheme.primary : CyberTheme.textPrimary)),
      const SizedBox(height: 2),
      Text(l, style: GoogleFonts.inter(fontSize: 10, color: CyberTheme.textMuted, fontWeight: FontWeight.w600,
        decoration: onTap != null ? TextDecoration.underline : null)),
    ]),
  );
}

// ─── Followers / Following List Sheet ────────────────────────────────────────
class UserListSheet extends ConsumerWidget {
  final int userId;
  final String title;
  final bool isFollowers;
  const UserListSheet({required this.userId, required this.title, required this.isFollowers});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = isFollowers
        ? ref.watch(followersListProvider(userId))
        : ref.watch(followingListProvider(userId));

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.90,
        minChildSize: 0.3,
        builder: (_, sc) => Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFEFEDED), borderRadius: BorderRadius.circular(99)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 17, fontWeight: FontWeight.bold, color: CyberTheme.textPrimary)),
          ),
          const Divider(height: 1),
          Expanded(
            child: listAsync.when(
              data: (users) {
                if (users.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.people_outline_rounded, size: 48, color: CyberTheme.textMuted),
                  const SizedBox(height: 12),
                  Text('No ${title.toLowerCase()} yet', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.bold, color: CyberTheme.textMuted)),
                ]));
                return ListView.separated(
                  controller: sc,
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final u = users[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFEFEDED)),
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: CyberTheme.primary.withOpacity(0.1),
                          backgroundImage: NetworkImage('https://api.dicebear.com/7.x/adventurer/png?seed=${u.username}&backgroundColor=ffd5b4'),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(u.username, style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.bold, color: CyberTheme.textPrimary)),
                          Text(u.rank, style: GoogleFonts.inter(fontSize: 11, color: CyberTheme.textMuted, fontWeight: FontWeight.w500)),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: CyberTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(99)),
                          child: Text('${u.reputationPoints} XP', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold, color: CyberTheme.primary)),
                        ),
                      ]),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: CyberTheme.primary)),
              error: (_, __) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.wifi_off_rounded, size: 40, color: CyberTheme.textMuted),
                const SizedBox(height: 12),
                Text('Could not load list', style: GoogleFonts.inter(color: CyberTheme.textMuted, fontSize: 13)),
              ])),
            ),
          ),
        ]),
      ),
    );
  }
}


