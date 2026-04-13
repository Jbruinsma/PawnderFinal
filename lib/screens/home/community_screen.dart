import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/image_fallback.dart';

class CommunityScreen extends StatelessWidget {
  final List<Map<String, String>> posts;
  final ValueChanged<Map<String, String>> onPostTap;
  final VoidCallback onAddListingTap;

  const CommunityScreen({
    super.key,
    required this.posts,
    required this.onPostTap,
    required this.onAddListingTap,
  });

  @override
  Widget build(BuildContext context) {
    final recentPosts = posts.where((post) => post['section'] == 'recent').toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/animals.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const ImageFallback(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'EXPLORE COMMUNITIES',
                style: GoogleFonts.lilitaOne(
                  fontSize: 28,
                  color: AppColors.seaBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CommunityTile(label: 'Black Pet\nOwners'),
              const SizedBox(width: 10),
              _CommunityTile(label: 'Cat Lovers'),
              const SizedBox(width: 10),
              _CommunityTile(label: 'Brooklyn'),
            ],
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Explore More\nCommunities',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF2A3440),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _SearchBar(
            onTap: () {},
          ),
          const SizedBox(height: 14),
          Container(height: 2, color: AppColors.seaBlue),
          const SizedBox(height: 8),
          Text(
            'RECENT POSTS:',
            style: GoogleFonts.lilitaOne(
              fontSize: 30,
              color: AppColors.seaBlue,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(bottom: 86),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.88,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: recentPosts.length,
              itemBuilder: (context, index) {
                final post = recentPosts[index];
                return _CommunityPostCard(
                  post: post,
                  onTap: () => onPostTap(post),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onAddListingTap,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1C1C1C),
                elevation: 2,
                shadowColor: const Color(0x22000000),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'Add listing here +',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityTile extends StatelessWidget {
  final String label;

  const _CommunityTile({required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/animals.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const ImageFallback(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.1,
              color: Color(0xFF1D232B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Search for communities...',
                style: TextStyle(
                  color: Color(0xFFB1B8C0),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityPostCard extends StatelessWidget {
  final Map<String, String> post;
  final VoidCallback onTap;

  const _CommunityPostCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.seaBlue,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                post['image'] ?? 'assets/images/animals.jpg',
                height: 78,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 78,
                  child: ImageFallback(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              post['title'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: (post['tags'] ?? '')
                  .split('|')
                  .where((tag) => tag.trim().isNotEmpty)
                  .take(2)
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8F1F5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: AppColors.seaBlue,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
