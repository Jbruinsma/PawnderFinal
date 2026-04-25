import 'package:flutter/material.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/pet_image.dart';

Widget buildCommunityPostsFeed({
  required List<Map<String, String>> posts,
  required String searchQuery,
  required ValueChanged<Map<String, String>> onPostTap,
  Future<void> Function(Map<String, String> post)? onCommentTap,
  Future<void> Function(Map<String, String> post)? onLikeTap,
  Future<void> Function(Map<String, String> post)? onDeleteTap,
  String? currentUserId,
}) {
  final query = searchQuery.trim().toLowerCase();

  final visiblePosts = query.isEmpty
      ? posts
      : posts.where((post) {
          final title = (post['title'] ?? '').toLowerCase();
          final description = (post['description'] ?? '').toLowerCase();
          final author = (post['author'] ?? '').toLowerCase();
          final location = (post['location'] ?? '').toLowerCase();
          return title.contains(query) ||
              description.contains(query) ||
              author.contains(query) ||
              location.contains(query);
        }).toList();

  if (visiblePosts.isEmpty) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Center(
          child: Text(
            'No posts found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }

  return ListView.separated(
    padding: const EdgeInsets.only(bottom: 92),
    itemCount: visiblePosts.length,
    separatorBuilder: (context, index) => const SizedBox(height: 14),
    itemBuilder: (context, index) {
      final post = visiblePosts[index];
      final isAuthor =
          currentUserId != null && post['authorId'] == currentUserId;
      return _StackedPostCard(
        post: post,
        onTap: () => onPostTap(post),
        onCommentTap: onCommentTap == null ? null : () => onCommentTap(post),
        onLikeTap: onLikeTap == null ? null : () => onLikeTap(post),
        onDeleteTap: (onDeleteTap == null || !isAuthor)
            ? null
            : () => onDeleteTap(post),
      );
    },
  );
}

class _StackedPostCard extends StatelessWidget {
  final Map<String, String> post;
  final VoidCallback onTap;
  final VoidCallback? onCommentTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onDeleteTap;

  const _StackedPostCard({
    required this.post,
    required this.onTap,
    this.onCommentTap,
    this.onLikeTap,
    this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final youLiked = post['youLiked'] == 'true';
    final tags = (post['tags'] ?? '')
        .split('|')
        .where((tag) => tag.trim().isNotEmpty)
        .toList();

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AspectRatio(
                    aspectRatio: 1.55,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned(
                          left: -3,
                          top: -3,
                          right: -3,
                          bottom: -3,
                          child: PetImage(
                            image: post['image'],
                            height: double.infinity,
                            width: double.infinity,
                            preserveSubject: true,
                            seed: post['id'] ?? post['title'] ?? '',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _StatusBadge(
                      label: (post['section'] ?? '') == 'found'
                          ? 'Found'
                          : 'Lost',
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Row(
                      children: [
                        if (onDeleteTap != null) ...[
                          _RoundCardAction(
                            icon: Icons.delete_outline_rounded,
                            iconColor: Colors.redAccent,
                            onTap: onDeleteTap,
                          ),
                          const SizedBox(width: 8),
                        ],
                        _RoundCardAction(
                          icon: youLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          iconColor: youLiked
                              ? Colors.redAccent
                              : theme.colorScheme.onSurface,
                          onTap: onLikeTap,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (post['section'] ?? '') == 'found'
                        ? 'Found nearby'
                        : 'Missing pet',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post['title'] ?? 'Missing pet post',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 19,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post['description'] ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tags
                        .take(3)
                        .map((tag) => _TagChip(tag: tag))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Posted ${post['posted'] ?? 'March 10th, 2026'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _InlineMeta(
                        icon: Icons.mode_comment_outlined,
                        label: '${post['commentCount'] ?? '0'} comments',
                      ),
                      const SizedBox(width: 12),
                      _InlineMeta(
                        icon: youLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        label: '${post['likeCount'] ?? '0'} likes',
                        iconColor: youLiked ? Colors.redAccent : null,
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: onCommentTap,
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text('Comment'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineMeta extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;

  const _InlineMeta({required this.icon, required this.label, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: iconColor ?? theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;

  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.78)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RoundCardAction extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _RoundCardAction({required this.icon, this.iconColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.72)
                : Colors.white.withValues(alpha: 0.94),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor ?? theme.colorScheme.onSurface,
            size: 19,
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : const Color(0xFFEDEFF1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
