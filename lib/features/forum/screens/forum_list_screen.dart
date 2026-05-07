import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cybershield_forum/core/theme.dart';
import 'package:cybershield_forum/features/forum/provider.dart';

class ForumListScreen extends ConsumerStatefulWidget {
  final int categoryId;
  final String categoryName;

  const ForumListScreen({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  ConsumerState<ForumListScreen> createState() => _ForumListScreenState();
}

class _ForumListScreenState extends ConsumerState<ForumListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(postsProvider(widget.categoryId));

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
          widget.categoryName,
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            color: CyberTheme.textPrimary,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: CyberTheme.primary,
          unselectedLabelColor: CyberTheme.textMuted,
          indicatorColor: CyberTheme.primary,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(text: 'For You'),
            Tab(text: 'Following'),
            Tab(text: 'Trending'),
            Tab(text: 'Latest'),
          ],
        ),
      ),
      body: postsAsync.when(
        data: (posts) {
          return Column(
            children: [
              // Mockup: "What's on your mind?" Input Bar at top of Feed
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: const Color(0xFFEFEDED)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: CyberTheme.background,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.sentiment_satisfied_alt_rounded, color: CyberTheme.textMuted, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "What's on your mind?",
                        style: GoogleFonts.inter(
                          color: CyberTheme.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Material(
                      color: CyberTheme.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => context.push('/create-post/${widget.categoryId}'),
                        borderRadius: BorderRadius.circular(99),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.add_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: posts.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: CyberTheme.primary.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: CyberTheme.primary),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'NO ACTIVE DISCUSSIONS',
                                style: GoogleFonts.spaceGrotesk(
                                  color: CyberTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Be the first sentinel to initiate a discussion thread here.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(color: CyberTheme.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          
                          // High-fidelity tags/chips generator based on title/category
                          final List<String> chips = [
                            'AI',
                            'Prevention',
                            'Cybersecurity'
                          ];

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
                                onTap: () => context.push('/post-detail/${post.id}'),
                                borderRadius: BorderRadius.circular(24),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Author Header
                                      Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
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
                                                errorBuilder: (context, _, __) => const Icon(Icons.person, size: 20),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  post.isAnonymous ? 'CyberGuardian' : post.authorName,
                                                  style: GoogleFonts.spaceGrotesk(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    color: CyberTheme.textPrimary,
                                                  ),
                                                ),
                                                Text(
                                                  post.isAnonymous ? 'Incognito' : post.authorRank,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    color: CyberTheme.textMuted,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            DateFormat('MMM d, HH:mm').format(post.createdAt),
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: CyberTheme.textMuted,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Title
                                      Text(
                                        post.title,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: CyberTheme.textPrimary,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      
                                      // Content snippet
                                      Text(
                                        post.content,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: CyberTheme.textSecondary,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Chips/Tags Row
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: chips.map((tag) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: CyberTheme.primary.withOpacity(0.06),
                                            borderRadius: BorderRadius.circular(99),
                                          ),
                                          child: Text(
                                            tag,
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: CyberTheme.primary,
                                            ),
                                          ),
                                        )).toList(),
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      const Divider(color: Color(0xFFEFEDED), height: 1),
                                      const SizedBox(height: 12),
                                      
                                      // Metrics Row
                                      Row(
                                        children: [
                                          _postMetric(Icons.thumb_up_alt_outlined, post.likesCount.toString(), CyberTheme.textMuted),
                                          const SizedBox(width: 20),
                                          _postMetric(Icons.chat_bubble_outline_rounded, post.commentsCount.toString(), CyberTheme.textMuted),
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
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: CyberTheme.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: CyberTheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_comment_rounded),
        onPressed: () {
          context.push('/create-post/${widget.categoryId}');
        },
      ),
    );
  }

  Widget _postMetric(IconData icon, String val, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          val,
          style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold, color: CyberTheme.textPrimary),
        ),
      ],
    );
  }
}
