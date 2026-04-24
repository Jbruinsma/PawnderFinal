import 'package:flutter/material.dart';
import 'package:pawnder_app/models/community.dart';
import 'package:pawnder_app/widgets/build_community_posts_feed.dart';
import 'package:pawnder_app/widgets/build_header.dart';

class CommunityScreen extends StatefulWidget {
  final List<Community> communities;
  final String? selectedCommunityName;
  final List<Map<String, String>> posts;
  final bool isLoading;
  final ValueChanged<Map<String, String>> onPostTap;
  final VoidCallback onCreateCommunityTap;
  final ValueChanged<Community> onCommunityTap;
  final Future<void> Function()? onRefresh;

  const CommunityScreen({
    super.key,
    required this.communities,
    this.selectedCommunityName,
    required this.posts,
    this.isLoading = false,
    required this.onPostTap,
    required this.onCreateCommunityTap,
    required this.onCommunityTap,
    this.onRefresh,
  });

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _searchQuery = '';

  void _showAllNeighborhoods() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        if (widget.isLoading && widget.communities.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (widget.communities.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('No neighborhoods found')),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: widget.communities.length,
          separatorBuilder: (_, separatorIndex) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final n = widget.communities[i];
            return ListTile(
              title: Text(
                n.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(n.description),
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onCommunityTap(n);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final featuredCommunities = widget.communities.take(3).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeHeader(
            title: 'Communities',
            subtitle: 'Neighborhood groups and pet alerts',
            icon: Icons.travel_explore_rounded,
          ),
          const SizedBox(height: 18),
          if (featuredCommunities.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Text(
                widget.isLoading
                    ? 'Loading nearby neighborhoods...'
                    : 'No neighborhoods are available yet.',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < featuredCommunities.length; i++) ...[
                  Expanded(
                    child: _CommunityTile(
                      label: featuredCommunities[i].name,
                      icon: Icons.location_city_rounded,
                      isSelected:
                          featuredCommunities[i].name ==
                          widget.selectedCommunityName,
                      onTap: () =>
                          widget.onCommunityTap(featuredCommunities[i]),
                    ),
                  ),
                  if (i < featuredCommunities.length - 1)
                    const SizedBox(width: 10),
                ],
              ],
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _showAllNeighborhoods,
              child: Text(
                'Explore More\nCommunities',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _SearchBar(
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 14),
          Container(height: 2, color: theme.dividerColor),
          const SizedBox(height: 12),
          if (widget.selectedCommunityName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Showing posts for ${widget.selectedCommunityName}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: widget.onRefresh ?? () async {},
              child: Stack(
                children: [
                  buildCommunityPostsFeed(
                    posts: widget.posts,
                    searchQuery: _searchQuery,
                    onPostTap: widget.onPostTap,
                  ),
                  if (widget.isLoading)
                    const Positioned(
                      left: 0,
                      right: 0,
                      top: 8,
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
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
              child: IconButton.filled(
                onPressed: widget.onCreateCommunityTap,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: theme.brightness == Brightness.dark ? 0 : 2,
                  shadowColor: const Color(0x18000000),
                  padding: const EdgeInsets.all(14),
                ),
                icon: const Icon(Icons.add_rounded, size: 26),
                tooltip: 'Create community',
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
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CommunityTile({
    required this.label,
    required this.icon,
    required this.isSelected,
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
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.dividerColor,
                  width: isSelected ? 2 : 1,
                ),
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
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.12)
                      : theme.cardColor,
                  child: Icon(
                    icon,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
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
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
            child: TextField(
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Search posts...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Icon(
            Icons.search_rounded,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
