import 'package:flutter/material.dart';
import 'package:pawnder_app/models/message_thread.dart';
import 'package:pawnder_app/screens/home/message_thread_screen.dart';
import 'package:pawnder_app/services/auth_service.dart';
import 'package:pawnder_app/services/post_service.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/pet_image.dart';

class MissingPostDetailsScreen extends StatefulWidget {
  final Map<String, String> post;

  const MissingPostDetailsScreen({super.key, required this.post});

  @override
  State<MissingPostDetailsScreen> createState() =>
      _MissingPostDetailsScreenState();
}

class _MissingPostDetailsScreenState extends State<MissingPostDetailsScreen> {
  final _authService = AuthService();
  final _postService = PostService();
  bool _isBookmarked = false;
  bool _isBookmarking = false;
  bool _isCheckingBookmark = true;

  @override
  void initState() {
    super.initState();
    _checkIfBookmarked();
  }

  Future<void> _checkIfBookmarked() async {
    try {
      final user = await _authService.getCurrentUser();
      final bookmarked = await _postService.isPostBookmarked(
        postId: widget.post['id'] ?? '',
        userId: user.id,
      );
      if (mounted) setState(() => _isBookmarked = bookmarked);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isCheckingBookmark = false);
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isBookmarking) return;
    setState(() => _isBookmarking = true);
    try {
      final user = await _authService.getCurrentUser();
      if (_isBookmarked) {
        await _postService.removeBookmark(
          postId: widget.post['id'] ?? '',
          userId: user.id,
        );
        if (mounted) {
          setState(() => _isBookmarked = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bookmark removed'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        await _postService.bookmarkPost(
          postId: widget.post['id'] ?? '',
          userId: user.id,
        );
        if (mounted) {
          setState(() => _isBookmarked = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post bookmarked'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update bookmark'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBookmarking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final theme = Theme.of(context);
    final author = post['author'] ?? 'Pet Owner';
    final firstName =
        author.trim().isEmpty ? 'Owner' : author.split(' ').first;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: PetImage(
              image: post['image'],
              height: double.infinity,
              width: double.infinity,
              fit: BoxFit.cover,
              seed: post['id'] ?? post['title'] ?? '',
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.12),
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.62),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                children: [
                  _GlassIcon(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  if (_isCheckingBookmark)
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.76),
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(11),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (_isBookmarking)
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.76),
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(11),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    _GlassIcon(
                      icon: _isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      onTap: _toggleBookmark,
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 18,
            top: MediaQuery.paddingOf(context).top + 64,
            child: _HighlightBadge(
              label: (post['section'] ?? '') == 'found' ? 'Found' : 'Lost',
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.46,
            minChildSize: 0.38,
            maxChildSize: 0.88,
            builder: (context, scrollController) {
              return _PostInfoSheet(
                post: post,
                author: author,
                firstName: firstName,
                scrollController: scrollController,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PostInfoSheet extends StatelessWidget {
  final Map<String, String> post;
  final String author;
  final String firstName;
  final ScrollController scrollController;

  const _PostInfoSheet({
    required this.post,
    required this.author,
    required this.firstName,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tags = (post['tags'] ?? '')
        .split('|')
        .where((tag) => tag.trim().isNotEmpty)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 5,
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: theme.scaffoldBackgroundColor,
                      child: Text(
                        author.trim().isEmpty
                            ? 'P'
                            : author.trim()[0].toUpperCase(),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Posted ${post['posted'] ?? 'recently'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  post['title'] ?? 'Help me find my pet',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 30,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((tag) => _TagChip(tag: tag)).toList(),
                ),
                const SizedBox(height: 18),
                Text(
                  post['description'] ??
                      'Our pet has gone missing. If you see them, please contact us right away.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 16,
                    height: 1.42,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.darkElevated
                          : theme.colorScheme.primary,
                      foregroundColor: isDark
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MessageThreadScreen(
                          thread: MessageThread(
                            id: 'post-${post['id'] ?? firstName}',
                            participantId: post['authorId'],
                            participantName: author,
                            title: post['title'] ?? 'Pet post conversation',
                            subtitle: 'Community contact thread',
                            unreadCount: 0,
                            lastUpdatedLabel: 'Just now',
                            messages: [
                              ThreadMessage(
                                text:
                                    'Hi! I saw your post and wanted to reach out about ${post['title'] ?? 'your pet'}.',
                                isMine: true,
                                timestamp: 'Just now',
                              ),
                              const ThreadMessage(
                                text:
                                    'Thank you so much for messaging. Let me know what details you need.',
                                isMine: false,
                                timestamp: 'Just now',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    child: Text(
                      'Contact $firstName',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
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

class _TagChip extends StatelessWidget {
  final String tag;

  const _TagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : const Color(0xFFEDEFF1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _HighlightBadge extends StatelessWidget {
  final String label;

  const _HighlightBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _GlassIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.72)
              : Colors.white.withValues(alpha: 0.76),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: theme.colorScheme.onSurface, size: 22),
      ),
    );
  }
}