import 'package:flutter/material.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/image_fallback.dart';

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
    return const Center(
      child: Text(
        'No posts found',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.bodyText,
        ),
      ),
    );
  }

  final recentPosts = visiblePosts
      .where((post) => post['section'] == 'recent')
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 38,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
            color: const Color(0xFF131313),
          ),
        ),
        const SizedBox(height: 8),
        if (useWideCardsLayout)
          SizedBox(
            height: 238,
            child: Row(
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
            ),
          )
        else
          SizedBox(
            height: 238,
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
    final tags = (post['tags'] ?? '')
        .split('|')
        .where((tag) => tag.trim().isNotEmpty)
        .toList();

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: useWideLayout ? null : 170,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.seaBlue,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                post['image'] ?? 'assets/images/animals.jpg',
                height: 92,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox(height: 92, child: ImageFallback()),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              post['title'] ?? 'Missing pet post',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags.take(3).map((tag) => _TagChip(tag: tag)).toList(),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x22000000),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                height: 12,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Posted ${post['posted'] ?? 'March 10th, 2026'}',
                      style: const TextStyle(
                        color: Color(0xFFD7F3F7),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFD8F1F5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: AppColors.seaBlue,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
