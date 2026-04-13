import 'package:flutter/material.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/build_community_posts_feed.dart';
import 'package:pawnder_app/widgets/image_fallback.dart';

class CommunityScreen extends StatelessWidget {
  final List<Map<String, String>> posts;
  final ValueChanged<Map<String, String>> onPostTap;
  final VoidCallback onAddListingTap;
  final ValueChanged<CommunityDefinition> onCommunityTap;

  const CommunityScreen({
    super.key,
    required this.posts,
    required this.onPostTap,
    required this.onAddListingTap,
    required this.onCommunityTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
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
                        errorBuilder: (context, error, stackTrace) =>
                            const ImageFallback(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'EXPLORE COMMUNITIES',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: AppColors.seaBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < _communities.length; i++) ...[
                    Expanded(
                      child: _CommunityTile(
                        label: _communities[i].label,
                        onTap: () => onCommunityTap(_communities[i]),
                      ),
                    ),
                    if (i < _communities.length - 1) const SizedBox(width: 10),
                  ],
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
              const SizedBox(height: 12),
              Expanded(
                child: buildCommunityPostsFeed(
                  posts: posts,
                  searchQuery: '',
                  onPostTap: onPostTap,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: onAddListingTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1C1C1C),
                      elevation: 2,
                      shadowColor: const Color(0x22000000),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Add listing here +',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CommunityTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
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

class CommunityDefinition {
  final String label;
  final String title;

  const CommunityDefinition({
    required this.label,
    required this.title,
  });
}

const List<CommunityDefinition> _communities = [
  CommunityDefinition(
    label: 'Lost\nCritters',
    title: 'Lost Critters',
  ),
  CommunityDefinition(
    label: 'Bird\nLovers',
    title: 'Bird Lovers',
  ),
  CommunityDefinition(
    label: 'Brooklyn',
    title: 'Brooklyn',
  ),
];

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
