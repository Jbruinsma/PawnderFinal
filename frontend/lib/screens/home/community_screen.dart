import 'package:flutter/material.dart';
import 'package:pawnder_app/widgets/build_community_posts_feed.dart';
import 'package:pawnder_app/widgets/build_header.dart';

class CommunityScreen extends StatelessWidget {
  final List<Map<String, String>> posts;
  final bool isLoading;
  final ValueChanged<Map<String, String>> onPostTap;
  final VoidCallback onAddListingTap;
  final ValueChanged<CommunityDefinition> onCommunityTap;
  final Future<void> Function()? onRefresh;

  const CommunityScreen({
    super.key,
    required this.posts,
    this.isLoading = false,
    required this.onPostTap,
    required this.onAddListingTap,
    required this.onCommunityTap,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      child: Container(
        decoration: const BoxDecoration(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HomeHeader(
                title: 'Communities',
                subtitle: 'Neighborhood groups and pet alerts',
                icon: Icons.travel_explore_rounded,
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < _communities.length; i++) ...[
                    Expanded(
                      child: _CommunityTile(
                        label: _communities[i].label,
                        icon: _communities[i].icon,
                        onTap: () => onCommunityTap(_communities[i]),
                      ),
                    ),
                    if (i < _communities.length - 1) const SizedBox(width: 10),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Explore More\nCommunities',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _SearchBar(onTap: () {}),
              const SizedBox(height: 14),
              Container(height: 2, color: theme.dividerColor),
              const SizedBox(height: 12),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: onRefresh ?? () async {},
                  child: Stack(
                    children: [
                      buildCommunityPostsFeed(
                        posts: posts,
                        searchQuery: '',
                        onPostTap: onPostTap,
                      ),
                      if (isLoading)
                        const Positioned(
                          left: 0,
                          right: 0,
                          top: 8,
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: onAddListingTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.cardColor,
                      foregroundColor: theme.colorScheme.onSurface,
                      elevation: theme.brightness == Brightness.dark ? 0 : 2,
                      shadowColor: const Color(0x18000000),
                      side: BorderSide(color: theme.dividerColor),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Add listing here +',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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
  final IconData icon;
  final VoidCallback onTap;

  const _CommunityTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                border: Border.all(color: theme.dividerColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: ColoredBox(
                  color: theme.cardColor,
                  child: Icon(
                    icon,
                    color: theme.colorScheme.onSurface,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.1,
              color: theme.colorScheme.onSurface,
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
  final IconData icon;

  const CommunityDefinition({
    required this.label,
    required this.title,
    required this.icon,
  });
}

const List<CommunityDefinition> _communities = [
  CommunityDefinition(
    label: 'Lost\nCritters',
    title: 'Lost Critters',
    icon: Icons.search_rounded,
  ),
  CommunityDefinition(
    label: 'Bird\nLovers',
    title: 'Bird Lovers',
    icon: Icons.flutter_dash_rounded,
  ),
  CommunityDefinition(
    label: 'Brooklyn',
    title: 'Brooklyn',
    icon: Icons.location_city_rounded,
  ),
];

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Search for communities...',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_rounded,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
