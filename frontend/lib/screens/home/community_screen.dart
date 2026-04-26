import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pawnder_app/models/community.dart';
import 'package:pawnder_app/services/search_service.dart';
import 'package:pawnder_app/widgets/build_header.dart';
import 'package:pawnder_app/widgets/community_card.dart';
import 'package:pawnder_app/widgets/search_bar.dart';
import 'package:pawnder_app/widgets/search_status.dart';

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
  final SearchService _searchService = SearchService();

  bool _isCreateMenuExpanded = false;
  String _searchQuery = '';
  Timer? _debounce;
  CancelToken? _cancelToken;
  int _searchSeq = 0;

  bool _isSearching = false;
  String? _searchError;
  List<Community> _searchResults = const [];

  static const Duration _debounceDuration = Duration(milliseconds: 300);

  bool get _hasActiveQuery => _searchQuery.trim().isNotEmpty;

  @override
  void dispose() {
    _debounce?.cancel();
    _cancelToken?.cancel('disposed');
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });

    _debounce?.cancel();

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      _cancelToken?.cancel('cleared');
      _cancelToken = null;
      setState(() {
        _isSearching = false;
        _searchError = null;
        _searchResults = const [];
      });
      return;
    }

    _debounce = Timer(_debounceDuration, () => _performSearch(trimmed));
  }

  Future<void> _performSearch(String query) async {
    _cancelToken?.cancel('superseded');
    final token = CancelToken();
    _cancelToken = token;
    final seq = ++_searchSeq;

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final results = await _searchService.searchCommunities(
        query: query,
        cancelToken: token,
      );

      if (!mounted || seq != _searchSeq) return;

      setState(() {
        _isSearching = false;
        _searchResults = results;
      });
    } catch (error) {
      if (error is DioException && CancelToken.isCancel(error)) {
        return;
      }
      if (!mounted || seq != _searchSeq) return;

      setState(() {
        _isSearching = false;
        _searchError = 'Couldn\'t search right now.';
      });
    }
  }

  void _retrySearch() {
    final trimmed = _searchQuery.trim();
    if (trimmed.isEmpty) return;
    _performSearch(trimmed);
  }

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
      backgroundColor: Colors.transparent,
      builder: (_) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final visibleCommunities = _hasActiveQuery
            ? _searchResults
            : widget.communities;

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.65)
                  : Colors.white.withValues(alpha: 0.85),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'All Communities',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (widget.isLoading && visibleCommunities.isEmpty)
                        const SizedBox(
                          height: 260,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (visibleCommunities.isEmpty)
                        SizedBox(
                          height: 260,
                          child: Center(
                            child: Text(
                              _hasActiveQuery
                                  ? 'No communities match "${_searchQuery.trim()}"'
                                  : 'No neighborhoods found',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: visibleCommunities.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final community = visibleCommunities[index];
                              return CommunityCard(
                                community: community,
                                isSelected:
                                    community.name ==
                                    widget.selectedCommunityName,
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
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          GlassmorphicSearchBar(
            onChanged: _onSearchChanged,
            isLoading: _isSearching,
            hintText: 'Search communities...',
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildBody()),
          if (!_hasActiveQuery && widget.communities.isNotEmpty) ...[
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
                                  elevation:
                                      theme.brightness == Brightness.dark
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
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 8,
                                    sigmaY: 8,
                                  ),
                                  child: FilledButton.tonalIcon(
                                    onPressed: _handleNewCommunityTap,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: isDark
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                      foregroundColor:
                                          theme.colorScheme.onSurface,
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_hasActiveQuery) {
      if (_isSearching && _searchResults.isEmpty) {
        return SearchStatus.loading();
      }
      if (_searchError != null) {
        return SearchStatus(
          icon: Icons.cloud_off_rounded,
          title: 'Couldn\'t search right now',
          subtitle: 'Check your connection and try again.',
          onRetry: _retrySearch,
        );
      }
      if (_searchResults.isEmpty) {
        return SearchStatus(
          icon: Icons.search_off_rounded,
          title: 'No results for "${_searchQuery.trim()}"',
          subtitle: 'Try a different keyword or community name.',
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _searchResults.length,
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final community = _searchResults[index];
          return CommunityCard(
            community: community,
            isSelected: community.name == widget.selectedCommunityName,
            onTap: () => widget.onCommunityTap(community),
          );
        },
      );
    }

    if (widget.communities.isEmpty) {
      return SearchStatus(
        icon: widget.isLoading ? Icons.travel_explore_rounded : Icons.groups_outlined,
        title: widget.isLoading
            ? 'Loading nearby neighborhoods...'
            : 'No neighborhoods are available yet.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 148),
      itemCount: widget.communities.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final community = widget.communities[index];
        return CommunityCard(
          community: community,
          isSelected: community.name == widget.selectedCommunityName,
          onTap: () => widget.onCommunityTap(community),
        );
      },
    );
  }
}