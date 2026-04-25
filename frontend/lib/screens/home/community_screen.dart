import 'package:flutter/material.dart';
import 'package:pawnder_app/models/community.dart';
import 'package:pawnder_app/widgets/build_header.dart';

class CommunityScreen extends StatefulWidget {
  final List<Community> communities;
  final String? selectedCommunityName;
  final bool isLoading;
  final VoidCallback onCreateCommunityTap;
  final VoidCallback onCreatePostTap;
  final ValueChanged<Community> onCommunityTap;

  const CommunityScreen({
    super.key,
    required this.communities,
    this.selectedCommunityName,
    this.isLoading = false,
    required this.onCreateCommunityTap,
    required this.onCreatePostTap,
    required this.onCommunityTap,
  });

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  bool _isCreateMenuExpanded = false;

  void _toggleCreateMenu() {
    setState(() {
      _isCreateMenuExpanded = !_isCreateMenuExpanded;
    });
  }

  void _handleNewPostTap() {
    setState(() => _isCreateMenuExpanded = false);
    widget.onCreatePostTap();
  }

  void _handleNewCommunityTap() {
    setState(() => _isCreateMenuExpanded = false);
    widget.onCreateCommunityTap();
  }

  void _showAllNeighborhoods() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        if (widget.isLoading && widget.communities.isEmpty) {
          return const SizedBox(
            height: 260,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (widget.communities.isEmpty) {
          return const SizedBox(
            height: 260,
            child: Center(child: Text('No neighborhoods found')),
          );
        }
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Communities',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: widget.communities.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final community = widget.communities[index];
                      return _CommunityCard(
                        community: community,
                        isSelected:
                            community.name == widget.selectedCommunityName,
                        onTap: () {
                          Navigator.pop(context);
                          widget.onCommunityTap(community);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
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
          if (widget.communities.isEmpty)
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
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 148),
                itemCount: widget.communities.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final community = widget.communities[index];
                  return _CommunityCard(
                    community: community,
                    isSelected: community.name == widget.selectedCommunityName,
                    onTap: () => widget.onCommunityTap(community),
                  );
                },
              ),
            ),
          if (widget.communities.isNotEmpty) ...[
            const SizedBox(height: 10),
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
          ],
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: !_isCreateMenuExpanded
                        ? const SizedBox.shrink()
                        : Column(
                            key: const ValueKey('community-create-menu'),
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              FilledButton.icon(
                                onPressed: _handleNewPostTap,
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  elevation: theme.brightness == Brightness.dark
                                      ? 0
                                      : 2,
                                  shadowColor: const Color(0x18000000),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                icon: const Icon(Icons.post_add_rounded),
                                label: const Text(
                                  'NEW POST',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              FilledButton.tonalIcon(
                                onPressed: _handleNewCommunityTap,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                icon: const Icon(Icons.group_add_rounded),
                                label: const Text(
                                  'NEW COMMUNITY',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                  ),
                  IconButton.filled(
                    onPressed: _toggleCreateMenu,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: theme.brightness == Brightness.dark ? 0 : 2,
                      shadowColor: const Color(0x18000000),
                      padding: const EdgeInsets.all(14),
                    ),
                    icon: Icon(
                      _isCreateMenuExpanded
                          ? Icons.close_rounded
                          : Icons.add_rounded,
                      size: 26,
                    ),
                    tooltip: _isCreateMenuExpanded
                        ? 'Close create menu'
                        : 'Open create menu',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  final Community community;
  final bool isSelected;
  final VoidCallback onTap;

  const _CommunityCard({
    required this.community,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconBase = isSelected
        ? theme.colorScheme.primary.withValues(alpha: 0.14)
        : theme.scaffoldBackgroundColor.withValues(alpha: isDark ? 0.72 : 0.98);
    final iconAccent = isSelected
        ? theme.colorScheme.primary.withValues(alpha: 0.22)
        : theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.7);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.10)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [iconBase, iconAccent],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -10,
                    right: -8,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.surface.withValues(
                          alpha: 0.18,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -12,
                    left: 10,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.surface.withValues(
                          alpha: 0.14,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 28,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.82,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    community.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    community.description.isEmpty
                        ? 'Neighborhood pet alerts and local community posts.'
                        : community.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _StatPill(
                        icon: Icons.article_outlined,
                        label: '${community.postCount} posts',
                        isSelected: isSelected,
                      ),
                      _StatPill(
                        icon: Icons.group_outlined,
                        label: '${community.memberCount} members',
                        isSelected: isSelected,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : theme.scaffoldBackgroundColor.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
