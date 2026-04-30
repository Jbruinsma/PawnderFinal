import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:pawnder_app/models/community.dart';
import 'package:pawnder_app/models/community_post.dart';
import 'package:pawnder_app/screens/home/unified_post_detail_screen.dart';
import 'package:pawnder_app/services/auth_service.dart';
import 'package:pawnder_app/services/api_client.dart';
import 'package:pawnder_app/services/community_service.dart';
import 'package:pawnder_app/services/post_service.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/build_community_posts_feed.dart';

class CommunityPostsScreen extends StatefulWidget {
  final Community community;
  final List<CommunityPost> posts;
  final VoidCallback onAddListingTap;
  final ValueChanged<String>? onPostDelete;

  const CommunityPostsScreen({
    super.key,
    required this.community,
    required this.posts,
    required this.onAddListingTap,
    this.onPostDelete,
  });

  @override
  State<CommunityPostsScreen> createState() => _CommunityPostsScreenState();
}

class _CommunityPostsScreenState extends State<CommunityPostsScreen> {
  final _postService = PostService();
  final _apiClient = ApiClient();
  final _authService = AuthService();
  final _communityService = CommunityService();

  late Community _community;
  late List<CommunityPost> _posts;
  final Map<String, List<PostComment>> _commentsByPostId = {};
  Timer? _pollTimer;
  String? _currentUserId;

  bool? _isJoined;
  bool _isJoining = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _community = widget.community;
    _posts = List<CommunityPost>.from(widget.posts);
    for (final post in _posts) {
      _commentsByPostId[post.id] = List<PostComment>.from(post.comments);
    }
    _loadCurrentUserId();
    _checkIfJoined();

    _refreshPosts(isSilent: true);

    _pollTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _refreshPosts(isSilent: true),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final user = await _authService.getCurrentUser();
      if (!mounted) return;
      setState(() => _currentUserId = user.id);
    } catch (_) {}
  }

  Future<void> _checkIfJoined() async {
    try {
      final myCommunities = await _communityService.getMyNeighborhoods();
      if (!mounted) return;
      setState(() {
        _isJoined = myCommunities.any((c) => c.id == _community.id);
      });
    } catch (_) {
      if (mounted) setState(() => _isJoined = false);
    }
  }

  Future<void> _joinCommunity() async {
    if (_isJoining) return;
    setState(() => _isJoining = true);

    try {
      await _communityService.joinNeighborhood(communityId: _community.id);
      if (!mounted) return;
      setState(() {
        _isJoined = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome to ${_community.name}!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_apiClient.messageForError(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  Future<void> _refreshPosts({bool isSilent = false}) async {
    if (!isSilent) {
      setState(() => _isRefreshing = true);
    }
    try {
      final freshCommunity = await _communityService.getCommunityById(communityId: _community.id);
      final freshPosts = await _postService.getCommunityPosts(
        communityId: _community.id,
        limit: 50,
      );
      if (!mounted) return;
      setState(() {
        _community = freshCommunity;
        _posts = freshPosts;
        for (final post in _posts) {
          _commentsByPostId.putIfAbsent(
            post.id,
            () => List<PostComment>.from(post.comments),
          );
        }
      });
    } catch (_) {
    } finally {
      if (mounted && !isSilent) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _handlePostUpdate(Map<String, String>? updatedPost) {
    if (updatedPost == null || !mounted) return;

    setState(() {
      final postId = updatedPost['id'];
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index] = _posts[index].copyWith(
          title: updatedPost['title'],
          description: updatedPost['description'],
          postType: updatedPost['postType'],
          imageUrl: updatedPost['image'],
          tags: updatedPost['tags']?.split('|').where((t) => t.isNotEmpty).toList(),
          likeCount: int.tryParse(updatedPost['likeCount'] ?? '0') ?? 0,
          commentCount: int.tryParse(updatedPost['commentCount'] ?? '0') ?? 0,
          youLiked: updatedPost['youLiked'] == 'true',
          edited: updatedPost['edited'] == 'true',
        );
      }
    });
  }

  Future<void> _confirmDeletePost(CommunityPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete listing?'),
        content: const Text('This listing will be removed for everyone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _postService.deletePost(postId: post.id);
      if (!mounted) return;
      setState(() {
        _posts = _posts.where((p) => p.id != post.id).toList();
      });
      widget.onPostDelete?.call(post.id);
      _refreshPosts(isSilent: true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_apiClient.messageForError(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _togglePostLike(Map<String, String> postMap) async {
    final postId = postMap['id'];
    if (postId == null) return;

    final index = _posts.indexWhere((item) => item.id == postId);
    if (index == -1) return;

    final post = _posts[index];
    final shouldLike = !post.youLiked;

    setState(() {
      _posts[index] = post.copyWith(
        likeCount: post.likeCount + (shouldLike ? 1 : -1),
        youLiked: shouldLike,
      );
    });

    try {
      final newLikeCount = await _postService.setPostLike(
        postId: postId,
        shouldLike: shouldLike,
      );
      if (!mounted) return;
      if (newLikeCount >= 0) {
        setState(() {
          _posts[index] = _posts[index].copyWith(likeCount: newLikeCount);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _posts[index] = post.copyWith(
            likeCount: post.likeCount,
            youLiked: post.youLiked,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final postMaps = _posts.map((post) => post.toFeedMap()).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () => _refreshPosts(isSilent: false),
        color: theme.colorScheme.primary,
        child: NestedScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: theme.scaffoldBackgroundColor,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _GlassIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _isRefreshing
                        ? Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.6)
                            : Colors.white.withValues(alpha: 0.75),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                        : _GlassIconButton(
                      icon: Icons.refresh_rounded,
                      onTap: () => _refreshPosts(isSilent: false),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_community.bannerUrl != null &&
                          _community.bannerUrl!.isNotEmpty)
                        Image.network(
                          _community.bannerUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildFallbackGradient(theme),
                        )
                      else
                        _buildFallbackGradient(theme),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.transparent,
                              theme.scaffoldBackgroundColor,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _community.name,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _community.description.isEmpty
                            ? 'Neighborhood pet alerts and local community posts.'
                            : _community.description,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _StatPill(
                            icon: Icons.article_outlined,
                            label: '${_community.postCount} posts',
                          ),
                          _StatPill(
                            icon: Icons.group_outlined,
                            label: '${_community.memberCount} members',
                          ),
                          if (_isJoined == false)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: FilledButton.tonalIcon(
                                  onPressed: _isJoining ? null : _joinCommunity,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                                    foregroundColor: theme.colorScheme.primary,
                                    minimumSize: const Size(0, 36),
                                  ),
                                  icon: _isJoining
                                      ? SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.colorScheme.primary,
                                    ),
                                  )
                                      : const Icon(Icons.add_rounded, size: 18),
                                  label: const Text(
                                    'Join',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHeaderDelegate(
                  height: 54,
                  postCount: _community.postCount,
                ),
              ),
            ];
          },
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: buildCommunityPostsFeed(
              posts: postMaps,
              searchQuery: '',
              currentUserId: _currentUserId,
              onPostTap: (postMap) async {
                final result = await Navigator.push<Map<String, String>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UnifiedPostDetailScreen(post: postMap),
                  ),
                );
                _handlePostUpdate(result);
              },
              onCommentTap: (postMap) async {
                final result = await Navigator.push<Map<String, String>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UnifiedPostDetailScreen(post: postMap),
                  ),
                );
                _handlePostUpdate(result);
              },
              onLikeTap: _togglePostLike,
              onDeleteTap: (postMap) async {
                final postId = postMap['id'];
                if (postId == null) return;
                final index = _posts.indexWhere((item) => item.id == postId);
                if (index == -1) return;
                await _confirmDeletePost(_posts[index]);
              },
            ),
          ),
        ),
      ),
      floatingActionButton: IconButton.filled(
        onPressed: widget.onAddListingTap,
        style: FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: isDark ? 0 : 4,
          shadowColor: const Color(0x28000000),
          padding: const EdgeInsets.all(16),
        ),
        icon: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  Widget _buildFallbackGradient(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.15),
            theme.colorScheme.primary.withValues(alpha: 0.05),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : theme.cardColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final int postCount;

  _StickyHeaderDelegate({required this.height, required this.postCount});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.65)
                : Colors.white.withValues(alpha: 0.85),
            border: Border(
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            'POSTS • $postCount',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.postCount != postCount || oldDelegate.height != height;
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.75),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: theme.colorScheme.onSurface, size: 20),
      ),
    );
  }
}