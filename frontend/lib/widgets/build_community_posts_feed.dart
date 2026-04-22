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

  final recentPosts = visiblePosts
      .where((post) => post['section'] == 'recent')
      .toList();
  final foundPosts = visiblePosts
      .where((post) => post['section'] == 'found')
      .toList();

  return ListView(
    padding: const EdgeInsets.only(bottom: 92),
    children: [
      if (recentPosts.isNotEmpty)
        _PostSection(
          title: 'Recent Posts',
          posts: recentPosts,
          onPostTap: onPostTap,
        ),
      if (foundPosts.isNotEmpty) ...[
        const SizedBox(height: 24),
        _PostSection(
          title: 'Found Pets',
          posts: foundPosts,
          onPostTap: onPostTap,
        ),
      ],
    ],
  );
}

class _PostSection extends StatelessWidget {
  final String title;
  final List<Map<String, String>> posts;
  final ValueChanged<Map<String, String>> onPostTap;

  const _PostSection({
    required this.title,
    required this.posts,
    required this.onPostTap,
  });

  @override
  Widget build(BuildContext context) {
    final useWideCardsLayout = posts.length <= 2;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            height: 1,
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        if (useWideCardsLayout)
          Row(
            children: [
              for (var i = 0; i < posts.length; i++) ...[
                Expanded(
                  child: _PostCard(
                    post: posts[i],
                    onTap: () => onPostTap(posts[i]),
                    useWideLayout: true,
                  ),
                ),
                if (i < posts.length - 1) const SizedBox(width: 14),
              ],
            ],
          )
        else
          SizedBox(
            height: 258,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: posts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final post = posts[index];
                return _PostCard(
                  post: post,
                  onTap: () => onPostTap(post),
                  useWideLayout: false,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _PostCard extends StatelessWidget {
  final Map<String, String> post;
  final VoidCallback onTap;
  final bool useWideLayout;

  const _PostCard({
    required this.post,
    required this.onTap,
    required this.useWideLayout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tags = (post['tags'] ?? '')
        .split('|')
        .where((tag) => tag.trim().isNotEmpty)
        .toList();

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: SizedBox(
        width: useWideLayout ? null : 184,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : theme.cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
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
                      Positioned(
                        left: 8,
                        top: 8,
                        child: _StatusBadge(
                          label: (post['section'] ?? '') == 'found'
                              ? 'Found'
                              : 'Lost',
                        ),
                      ),
                      const Positioned(
                        right: 8,
                        top: 8,
                        child: _RoundCardAction(
                          icon: Icons.favorite_border_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 4),
            Text(
              post['title'] ?? 'Missing pet post',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 17,
                height: 1.12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags.take(2).map((tag) => _TagChip(tag: tag)).toList(),
            ),
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
