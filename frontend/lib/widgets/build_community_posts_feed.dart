import 'package:flutter/material.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/pet_image.dart';

Widget buildCommunityPostsFeed({
  required List<Map<String, String>> posts,
  required String searchQuery,
  required ValueChanged<Map<String, String>> onPostTap,
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
      return _StackedPostCard(post: post, onTap: () => onPostTap(post));
    },
  );
}

class _StackedPostCard extends StatelessWidget {
  final Map<String, String> post;
  final VoidCallback onTap;

  const _StackedPostCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
                children: [
                  AspectRatio(
                    aspectRatio: 1.55,
                    child: PetImage(
                      image: post['image'],
                      height: double.infinity,
                      width: double.infinity,
                      preserveSubject: true,
                      seed: post['id'] ?? post['title'] ?? '',
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
                  const Positioned(
                    right: 12,
                    top: 12,
                    child: _RoundCardAction(
                      icon: Icons.favorite_border_rounded,
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
                ],
              ),
            ),
          ],
        ),
      ),
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

  const _RoundCardAction({required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.72)
            : Colors.white.withValues(alpha: 0.94),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: theme.colorScheme.onSurface, size: 19),
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
