import 'package:flutter/material.dart';
import 'package:pawnder_app/widgets/build_community_posts_feed.dart';
import 'package:pawnder_app/widgets/build_header.dart';
import 'package:pawnder_app/services/community_service.dart';
import 'package:pawnder_app/models/community.dart';

class CommunityScreen extends StatefulWidget {
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
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _searchQuery = '';
  List<Community> _allNeighborhoods = [];
  bool _loadingNeighborhoods = false;

  @override
  void initState() {
    super.initState();
    _loadNeighborhoods();
  }

  Future<void> _loadNeighborhoods() async {
    setState(() => _loadingNeighborhoods = true);
    try {
      final service = CommunityService();
      final results = await service.getNeighborhoods(
        latitude: 40.7128,
        longitude: -74.0060,
      );
      if (mounted) setState(() => _allNeighborhoods = results);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingNeighborhoods = false);
    }
  }

  void _showAllNeighborhoods() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        if (_loadingNeighborhoods) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (_allNeighborhoods.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('No neighborhoods found')),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: _allNeighborhoods.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final n = _allNeighborhoods[i];
            return ListTile(
              title: Text(
                n.name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              subtitle: Text(n.description),
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.location_on, color: Colors.white, size: 18),
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onCommunityTap(CommunityDefinition(
                  label: n.name,
                  title: n.name,
                  icon: Icons.location_city_rounded,
                ));
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < _communities.length; i++) ...[
                Expanded(
                  child: _CommunityTile(
                    label: _communities[i].label,
                    icon: _communities[i].icon,
                    onTap: () => widget.onCommunityTap(_communities[i]),
                  ),
                ),
                if (i < _communities.length - 1) const SizedBox(width: 10),
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
                      left: 0, right: 0, top: 8,
                      child: Center(
                        child: SizedBox(
                          width: 24, height: 24,
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
              child: FilledButton(
                onPressed: widget.onAddListingTap,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.cardColor,
                  foregroundColor: theme.colorScheme.onSurface,
                  elevation: theme.brightness == Brightness.dark ? 0 : 2,
                  shadowColor: const Color(0x18000000),
                  side: BorderSide(color: theme.dividerColor),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: const StadiumBorder(),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Add listing here +',
                    maxLines: 1,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ),
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
                  child: Icon(icon, color: theme.colorScheme.onSurface, size: 30),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14, height: 1.1,
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
          Icon(Icons.search_rounded, size: 18,
              color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}