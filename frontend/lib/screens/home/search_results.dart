import 'dart:math';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:pawnder_app/models/community.dart';
import 'package:pawnder_app/models/community_post.dart';
import 'package:pawnder_app/services/post_service.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/community_card.dart';
import 'package:pawnder_app/widgets/pet_image.dart';

import '../../services/search_service.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/search_status.dart';
import 'community_posts_screen.dart';
import 'unified_post_detail_screen.dart';

class SearchResultsPage extends StatefulWidget {
  final String? currentUserId;
  final bool isCommunitiesOnly;

  const SearchResultsPage({
    super.key,
    this.currentUserId,
    this.isCommunitiesOnly = false,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  CancelToken? _cancelToken;
  final FocusNode _searchFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isNavigating = false;
  late PageController _pageController;
  final PostService _postService = PostService();
  String _query = '';
  SearchAllResults _results = SearchAllResults.empty;
  late final SearchService _searchService;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: theme.colorScheme.onSurface,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GlassmorphicSearchBar(
                            focusNode: _searchFocusNode,
                            isLoading: _isLoading,
                            onChanged: _performSearch,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isLoading && _results.isEmpty)
                  const SliverFillRemaining(
                    child: SearchStatus.loading(),
                  )
                else if (_query.isNotEmpty && _results.isEmpty)
                  const SliverFillRemaining(
                    child: Padding(
                      padding: EdgeInsets.all(22.0),
                      child: SearchStatus(
                        icon: Icons.search_off_rounded,
                        subtitle: 'Try adjusting your search terms',
                        title: 'No results found',
                      ),
                    ),
                  )
                else if (_results.communities.isNotEmpty || _results.posts.isNotEmpty)
                  ..._buildResults(isDark, theme),
              ],
            ),
            if (_isNavigating)
              Container(
                color: Colors.black.withValues(alpha: 0.2),
                child: Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    _pageController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _searchService = SearchService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  Widget _buildSectionHeader(String label, int count, ThemeData theme, bool isDark) {
    final headerTextColor = isDark ? const Color(0xFFE5E4E2) : AppColors.seaBlue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 24.0, right: 24.0, top: 12.0),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: headerTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Text(
              '$count',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildResults(bool isDark, ThemeData theme) {
    if (widget.isCommunitiesOnly) {
      return [
        if (_results.communities.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _buildSectionHeader('Communities', _results.communities.length, theme, isDark),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14.0),
                    child: CommunityCard(
                      community: _results.communities[index],
                      onTap: () => _handleCommunityTap(_results.communities[index]),
                    ),
                  );
                },
                childCount: _results.communities.length,
              ),
            ),
          ),
        ],
      ];
    }

    return [
      if (_results.communities.isNotEmpty)
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Communities', _results.communities.length, theme, isDark),
              SizedBox(
                height: 330,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _results.communities.length,
                  itemBuilder: (context, index) {
                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        double value = 1.0;
                        if (_pageController.position.haveDimensions) {
                          value = _pageController.page! - index;
                          value = (1 - (value.abs() * 0.04)).clamp(0.92, 1.0);
                        }
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 12.0),
                        child: CommunityCard(
                          community: _results.communities[index],
                          onTap: () => _handleCommunityTap(_results.communities[index]),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      if (_results.posts.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: _buildSectionHeader('Posts', _results.posts.length, theme, isDark),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final post = _results.posts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: _SearchStackedPostCard(
                    onTap: () => _handlePostTap(post),
                    post: post.toFeedMap(),
                  ),
                );
              },
              childCount: _results.posts.length,
            ),
          ),
        ),
      ],
    ];
  }

  Future<void> _handleCommunityTap(Community community) async {
    setState(() {
      _isNavigating = true;
      _searchFocusNode.unfocus();
    });

    try {
      final communityPosts = await _postService.getCommunityPosts(
        communityId: community.id,
        limit: 50,
      );

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CommunityPostsScreen(
            community: community,
            onAddListingTap: () {},
            posts: communityPosts,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }

  Future<void> _handlePostTap(CommunityPost post) async {
    _searchFocusNode.unfocus();

    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => UnifiedPostDetailScreen(post: post.toFeedMap()),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        final searchPosts = List<CommunityPost>.from(_results.posts);
        final searchIndex = searchPosts.indexWhere((p) => p.id == result['id']);
        if (searchIndex != -1) {
          searchPosts[searchIndex] = searchPosts[searchIndex].copyWith(
            title: result['title'],
            description: result['description'],
            postType: result['postType'],
            imageUrl: result['image'],
            tags: result['tags']?.split('|').where((t) => t.isNotEmpty).toList(),
            commentCount: int.tryParse(result['commentCount'] ?? '0') ?? 0,
            likeCount: int.tryParse(result['likeCount'] ?? '0') ?? 0,
            youLiked: result['youLiked'] == 'true',
            edited: result['edited'] == 'true',
          );
          _results = _results.copyWith(posts: searchPosts);
        }
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isLoading = false;
        _query = '';
        _results = SearchAllResults.empty;
      });
      return;
    }

    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    setState(() {
      _isLoading = true;
      _query = query;
    });

    try {
      if (widget.isCommunitiesOnly) {
        final communities = await _searchService.searchCommunities(
          cancelToken: _cancelToken,
          query: query,
        );
        if (mounted) {
          setState(() {
            _isLoading = false;
            _results = SearchAllResults(communities: communities, posts: const []);
          });
        }
      } else {
        final results = await _searchService.searchAll(
          cancelToken: _cancelToken,
          query: query,
        );
        if (mounted) {
          setState(() {
            _isLoading = false;
            _results = results;
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _SearchStackedPostCard extends StatelessWidget {
  final VoidCallback onTap;
  final Map<String, String> post;

  const _SearchStackedPostCard({
    required this.onTap,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final youLiked = post['youLiked'] == 'true';
    final hasImage = (post['image'] ?? '').trim().isNotEmpty;
    final tags = (post['tags'] ?? '')
        .split('|')
        .where((tag) => tag.trim().isNotEmpty)
        .toList();

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(20),
          color: isDark ? AppColors.darkBackground : theme.cardColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: AspectRatio(
                  aspectRatio: 1.55,
                  child: PetImage(
                    height: double.infinity,
                    image: post['image'],
                    preserveSubject: true,
                    seed: post['id'] ?? post['title'] ?? '',
                    width: double.infinity,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text(
                              post['title'] ?? 'Untitled',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _RoundCardAction(
                            icon: youLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            iconColor: youLiked
                                ? Colors.redAccent
                                : theme.colorScheme.onSurface,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if ((post['description'] ?? '').trim().isNotEmpty) ...[
                    Text(
                      post['description'] ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 6,
                    spacing: 6,
                    children: [
                      _StatusBadge(
                        label: post['postType'] ?? 'Post',
                      ),
                      ...tags.take(3).map((tag) => _TagChip(tag: tag)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Posted ${post['posted'] ?? 'Recently'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _InlineMeta(
                        icon: Icons.mode_comment_outlined,
                        label: post['commentCount'] ?? '0',
                      ),
                      const SizedBox(width: 12),
                      _InlineMeta(
                        icon: youLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        iconColor: youLiked ? Colors.redAccent : null,
                        label: post['likeCount'] ?? '0',
                      ),
                    ],
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

class _InlineMeta extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;

  const _InlineMeta({required this.icon, this.iconColor, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: iconColor ?? theme.colorScheme.onSurfaceVariant,
          size: 15,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RoundCardAction extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _RoundCardAction({required this.icon, this.iconColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            shape: BoxShape.circle,
          ),
          height: 36,
          width: 36,
          child: Icon(
            icon,
            color: iconColor ?? theme.colorScheme.onSurface,
            size: 19,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;

  const _StatusBadge({required this.label});

  Color _getTextColor(String type, ThemeData theme) {
    final t = type.toLowerCase();
    if (t == 'lost pet') return Colors.redAccent;
    if (t == 'report') return Colors.orangeAccent;
    if (t == 'found pet') return Colors.green;
    if (t == 'adoption') return Colors.deepPurpleAccent;
    if (t == 'discussion') return Colors.blueAccent;
    return theme.colorScheme.onSurface;
  }

  Color _getBgColor(String type, ThemeData theme) {
    final t = type.toLowerCase();
    final isDark = theme.brightness == Brightness.dark;

    if (t == 'lost pet') return Colors.redAccent.withValues(alpha: 0.12);
    if (t == 'report') return Colors.orangeAccent.withValues(alpha: 0.12);
    if (t == 'found pet') return Colors.green.withValues(alpha: 0.12);
    if (t == 'adoption') return Colors.deepPurpleAccent.withValues(alpha: 0.12);
    if (t == 'discussion') return Colors.blueAccent.withValues(alpha: 0.12);

    return isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        color: _getBgColor(label, theme),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      child: Text(
        label,
        style: TextStyle(
          color: _getTextColor(label, theme),
          fontSize: 11,
          fontWeight: FontWeight.w900,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: isDark ? AppColors.darkElevated : const Color(0xFFEDEFF1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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