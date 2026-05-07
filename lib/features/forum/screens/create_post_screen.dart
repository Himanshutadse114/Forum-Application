import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cybershield_forum/core/theme.dart';
import 'package:cybershield_forum/features/forum/provider.dart';
import 'package:cybershield_forum/features/auth/provider.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  final int categoryId;

  const CreatePostScreen({
    Key? key,
    required this.categoryId,
  }) : super(key: key);

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isAnonymous = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submitPost() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in both the title and content fields.',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: CyberTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final error = await ref.read(forumOperationsProvider.notifier).createPost(
      widget.categoryId,
      _titleController.text.trim(),
      _contentController.text.trim(),
      _isAnonymous,
    );

    setState(() => _isLoading = false);

    if (error == null && mounted) {
      // Invalidate posts list to reload in real-time
      ref.invalidate(postsProvider(widget.categoryId));
      ref.invalidate(postsProvider(null));
      ref.read(authProvider.notifier).fetchProfile(); // Refresh XP

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'THREAD BROADCAST SUCCESSFUL. Reputation: +15 XP.',
            style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: CyberTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ?? 'Failed to publish post. Please try again.',
            style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: CyberTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.userProfile;
    final categoriesAsync = ref.watch(categoriesProvider);

    // Find category name based on widget.categoryId
    String categoryName = 'General Discussion';
    categoriesAsync.whenData((categories) {
      final match = categories.firstWhere(
        (c) => c.id == widget.categoryId,
        orElse: () => Category(id: widget.categoryId, name: 'General Discussion', description: '', icon: ''),
      );
      categoryName = match.name;
    });

    final username = user?['username']?.toString() ?? 'CyberGuardian';

    return Scaffold(
      backgroundColor: CyberTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: CyberTheme.textPrimary, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Create Post',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            color: CyberTheme.textPrimary,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: CyberTheme.primary),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Center(
                child: ElevatedButton(
                  onPressed: _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CyberTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(99),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Post',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Info & Status Badges Row matching mockup
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: CyberTheme.primary.withOpacity(0.1),
                        backgroundImage: NetworkImage(
                          _isAnonymous 
                            ? 'https://api.dicebear.com/7.x/bottts/png?seed=ghost&backgroundColor=efeded'
                            : 'https://api.dicebear.com/7.x/adventurer/png?seed=$username&backgroundColor=ffd5b4',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isAnonymous ? 'Ghost Sentinel' : username,
                              style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: CyberTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              children: [
                                // Category badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: CyberTheme.primary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    categoryName,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: CyberTheme.primary,
                                    ),
                                  ),
                                ),
                                // Visibility/Protocol Badge
                                GestureDetector(
                                  onTap: () => setState(() => _isAnonymous = !_isAnonymous),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _isAnonymous ? Colors.black : const Color(0xFFEFEDED),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _isAnonymous ? Icons.security : Icons.public_rounded,
                                          size: 10,
                                          color: _isAnonymous ? Colors.white : CyberTheme.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _isAnonymous ? 'Ghost Protocol' : 'Public Feed',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: _isAnonymous ? Colors.white : CyberTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Title Text Field
                  TextField(
                    controller: _titleController,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: CyberTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: "What's the thread topic?",
                      hintStyle: GoogleFonts.spaceGrotesk(
                        color: CyberTheme.textMuted,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFEFEDED), height: 1),
                  const SizedBox(height: 16),

                  // Content Text Field
                  TextField(
                    controller: _contentController,
                    maxLines: null,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: CyberTheme.textSecondary,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: "Share suspicious indicators of compromise, dynamic phishing details, or security best practices...",
                      hintStyle: GoogleFonts.inter(
                        color: CyberTheme.textMuted,
                        fontSize: 14,
                      ),
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Pinned Info Banner & Toolbar Pinned above keyboard
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(
                top: BorderSide(color: Color(0xFFEFEDED)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Minimalist information bar
                Container(
                  color: CyberTheme.primary.withOpacity(0.04),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: CyberTheme.primary, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sharing verified insights rewards you +15 reputation XP instantly.',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: CyberTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Attachment icons toolbar matching mockup exactly
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      _toolbarIcon(Icons.image_outlined, 'Image'),
                      _toolbarIcon(Icons.poll_outlined, 'Poll'),
                      _toolbarIcon(Icons.link_rounded, 'Link'),
                      _toolbarIcon(Icons.videocam_outlined, 'Video'),
                      _toolbarIcon(Icons.more_horiz_rounded, 'More'),
                      const Spacer(),
                      // Ghost mode quick indicator button
                      IconButton(
                        icon: Icon(
                          _isAnonymous ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: _isAnonymous ? CyberTheme.primary : CyberTheme.textMuted,
                        ),
                        onPressed: () {
                          setState(() => _isAnonymous = !_isAnonymous);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbarIcon(IconData icon, String tooltip) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: CyberTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: CyberTheme.primary, size: 20),
        onPressed: () {
          // Decorative tap response
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$tooltip attachment feature coming soon in next arcade update!',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
              ),
              duration: const Duration(seconds: 1),
              backgroundColor: CyberTheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
        },
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(),
      ),
    );
  }
}
