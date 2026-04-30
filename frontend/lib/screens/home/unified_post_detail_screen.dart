import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:pawnder_app/models/community.dart';
import 'package:pawnder_app/models/community_post.dart';
import 'package:pawnder_app/screens/home/community_posts_screen.dart';
import 'package:pawnder_app/screens/home/listing_screen.dart';
import 'package:pawnder_app/screens/home/message_thread_screen.dart';
import 'package:pawnder_app/services/auth_service.dart';
import 'package:pawnder_app/services/community_service.dart';
import 'package:pawnder_app/services/message_service.dart';
import 'package:pawnder_app/services/post_service.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/pet_image.dart';

class UnifiedPostDetailScreen extends StatefulWidget {
  final Map<String, String> post;

  const UnifiedPostDetailScreen({super.key, required this.post});

  @override
  State<UnifiedPostDetailScreen> createState() =>
      _UnifiedPostDetailScreenState();
}

class _UnifiedPostDetailScreenState extends State<UnifiedPostDetailScreen> {
  final _authService = AuthService();
  final _messageService = MessageService();
  final _postService = PostService();
  final _communityService = CommunityService();
  final _commentController = TextEditingController();

  bool _isBookmarked = false;
  bool _isBookmarking = false;
  bool _isCheckingBookmark = true;

  late int _likeCount;
  late int _commentCount;
  late bool _youLiked;
  late bool _edited;

  List<PostComment> _comments = const [];
  bool _isLoadingComments = true;
  bool _isSubmittingComment = false;
  String? _currentUserId;
  String? _replyingToCommentId;
  Community? _community;

  @override
  void initState() {
    super.initState();
    _likeCount = int.tryParse(widget.post['likeCount'] ?? '0') ?? 0;
    _commentCount = int.tryParse(widget.post['commentCount'] ?? '0') ?? 0;
    _youLiked = widget.post['youLiked'] == 'true';
    _edited = widget.post['edited'] == 'true';

    _initializeData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      final user = await _authService.getCurrentUser();
      if (mounted) {
        setState(() => _currentUserId = user.id);
      }

      final commId = widget.post['communityId'];
      if (commId != null && commId.isNotEmpty) {
        _fetchCommunity(commId);
      }

      await Future.wait([
        _checkIfBookmarked(user.id),
        _loadComments(),
      ]);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingBookmark = false;
          _isLoadingComments = false;
        });
      }
    }
  }

  Future<void> _fetchCommunity(String commId) async {
    try {
      final comm = await _communityService.getCommunityById(communityId: commId);
      if (mounted) {
        setState(() => _community = comm);
      }
    } catch (_) {}
  }

  Future<void> _checkIfBookmarked(String userId) async {
    try {
      final bookmarked = await _postService.isPostBookmarked(
        postId: widget.post['id'] ?? '',
        userId: userId,
      );
      if (mounted) setState(() => _isBookmarked = bookmarked);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isCheckingBookmark = false);
    }
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _postService.getPostComments(
        postId: widget.post['id'] ?? '',
      );
      if (mounted) {
        setState(() {
          _comments = comments;
          _commentCount = comments.length;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isBookmarking) return;
    setState(() => _isBookmarking = true);

    try {
      final user = await _authService.getCurrentUser();
      if (_isBookmarked) {
        await _postService.removeBookmark(
          postId: widget.post['id'] ?? '',
          userId: user.id,
        );
        if (mounted) setState(() => _isBookmarked = false);
      } else {
        await _postService.bookmarkPost(
          postId: widget.post['id'] ?? '',
          userId: user.id,
        );
        if (mounted) setState(() => _isBookmarked = true);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isBookmarking = false);
    }
  }

  Future<void> _togglePostLike() async {
    final shouldLike = !_youLiked;
    final postId = widget.post['id'];
    if (postId == null) return;

    setState(() {
      _youLiked = shouldLike;
      _likeCount += shouldLike ? 1 : -1;
    });

    try {
      final newCount = await _postService.setPostLike(
        postId: postId,
        shouldLike: shouldLike,
      );
      if (mounted && newCount > 0) {
        setState(() => _likeCount = newCount);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _youLiked = !shouldLike;
          _likeCount += !shouldLike ? 1 : -1;
        });
      }
    }
  }

  Future<void> _toggleCommentLike(PostComment comment) async {
    final shouldLike = !comment.youLiked;
    final postId = widget.post['id'];
    if (postId == null) return;

    setState(() {
      _comments = _comments.map((c) {
        if (c.commentId == comment.commentId) {
          return c.copyWith(
            youLiked: shouldLike,
            likeCount: c.likeCount + (shouldLike ? 1 : -1),
          );
        }
        return c;
      }).toList();
    });

    try {
      final newCount = await _postService.setCommentLike(
        postId: postId,
        commentId: comment.commentId,
        shouldLike: shouldLike,
      );
      if (mounted && newCount > 0) {
        setState(() {
          _comments = _comments.map((c) {
            if (c.commentId == comment.commentId) {
              return c.copyWith(likeCount: newCount);
            }
            return c;
          }).toList();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _comments = _comments.map((c) {
            if (c.commentId == comment.commentId) {
              return c.copyWith(
                youLiked: !shouldLike,
                likeCount: c.likeCount + (!shouldLike ? 1 : -1),
              );
            }
            return c;
          }).toList();
        });
      }
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    final postId = widget.post['id'];

    if (content.isEmpty || _isSubmittingComment || postId == null) return;

    setState(() => _isSubmittingComment = true);

    try {
      final newComment = await _postService.addComment(
        postId: postId,
        content: content,
        replyingToId: _replyingToCommentId,
      );
      if (mounted) {
        setState(() {
          _comments = [..._comments, newComment];
          _commentCount += 1;
          _commentController.clear();
          _replyingToCommentId = null;
        });
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isSubmittingComment = false);
    }
  }

  Future<void> _openConversation() async {
    final participantId = widget.post['authorId'];
    if (participantId == null || participantId.isEmpty) return;

    final author = widget.post['author'] ?? 'Pet Owner';
    final thread = _messageService.buildDirectThread(
      participantId: participantId,
      participantName: author,
      title: widget.post['title'] ?? 'Pet post conversation',
      subtitle: 'Community contact thread',
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MessageThreadScreen(thread: thread)),
      );
    }
  }

  Future<void> _navigateToEdit() async {
    final didUpdate = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ListingScreen(
          authorId: widget.post['authorId'],
          communityId: widget.post['communityId'],
          existingPost: widget.post,
        ),
      ),
    );

    if (didUpdate == true && mounted) {
      final updatedPost = Map<String, String>.from(widget.post);
      updatedPost['action'] = 'refresh';
      Navigator.pop(context, updatedPost);
    }
  }

  void _startReply(PostComment comment) {
    setState(() => _replyingToCommentId = comment.commentId);
  }

  void _cancelReply() {
    setState(() => _replyingToCommentId = null);
  }

  void _handleBack() {
    final updatedPost = Map<String, String>.from(widget.post);
    updatedPost['likeCount'] = _likeCount.toString();
    updatedPost['youLiked'] = _youLiked.toString();
    updatedPost['commentCount'] = _commentCount.toString();
    Navigator.pop(context, updatedPost);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final post = widget.post;
    final hasImage = (post['image'] ?? '').trim().isNotEmpty;
    final tags = (post['tags'] ?? '')
        .split('|')
        .where((tag) => tag.trim().isNotEmpty)
        .toList();

    final rootComments = _comments.where((c) => c.replyingToId == null || c.replyingToId!.isEmpty).toList();
    final repliesByParentId = <String, List<PostComment>>{};
    for (final c in _comments.where((c) => c.replyingToId != null && c.replyingToId!.isNotEmpty)) {
      repliesByParentId.putIfAbsent(c.replyingToId!, () => []).add(c);
    }

    String? replyingToName;
    if (_replyingToCommentId != null) {
      final target = _comments.where((c) => c.commentId == _replyingToCommentId).firstOrNull;
      if (target != null) {
        replyingToName = target.userId == _currentUserId ? 'You' : target.authorName;
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadComments,
                color: theme.colorScheme.primary,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      expandedHeight: hasImage ? MediaQuery.sizeOf(context).height * 0.45 : null,
                      pinned: true,
                      backgroundColor: theme.scaffoldBackgroundColor,
                      leading: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _GlassIconButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: _handleBack,
                        ),
                      ),
                      actions: [
                        if (_currentUserId != null && _currentUserId == post['authorId'])
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: _GlassIconButton(
                              icon: Icons.edit_rounded,
                              onTap: _navigateToEdit,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _isCheckingBookmark || _isBookmarking
                              ? Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.black.withValues(alpha: 0.7)
                                        : Colors.white.withValues(alpha: 0.8),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: const CircularProgressIndicator(strokeWidth: 2),
                                )
                              : _GlassIconButton(
                                  icon: _isBookmarked
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                  onTap: _toggleBookmark,
                                ),
                        ),
                      ],
                      flexibleSpace: hasImage
                          ? FlexibleSpaceBar(
                              background: Stack(
                                fit: StackFit.expand,
                                children: [
                                  PetImage(
                                    image: post['image'],
                                    height: double.infinity,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    seed: post['id'] ?? post['title'] ?? '',
                                  ),
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
                                  Positioned(
                                    left: 18,
                                    bottom: 24,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _StatusBadge.getBgColor(post['postType'] ?? 'Post', theme).withValues(alpha: isDark ? 0.3 : 0.6),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: _StatusBadge.getTextColor(post['postType'] ?? 'Post', theme).withValues(alpha: 0.5),
                                            ),
                                          ),
                                          child: Text(
                                            post['postType'] ?? 'Post',
                                            style: TextStyle(
                                              color: _StatusBadge.getTextColor(post['postType'] ?? 'Post', theme),
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : null,
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_community != null) ...[
                              GestureDetector(
                                onTap: () async {
                                  final community = _community;
                                  if (community == null) return;
                                  final posts = await _postService.getCommunityPosts(communityId: community.id, limit: 50);
                                  if (!mounted) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CommunityPostsScreen(
                                        community: community,
                                        posts: posts,
                                        onAddListingTap: () async {
                                          if (_currentUserId == null) return;
                                          final didCreate = await Navigator.push<bool>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ListingScreen(
                                                authorId: _currentUserId!,
                                                communities: [community],
                                                initialCommunityId: community.id,
                                              ),
                                            ),
                                          );
                                          if (didCreate == true && mounted) {
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on_rounded, size: 14, color: theme.colorScheme.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Posted in ${_community!.name}',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.chevron_right_rounded, size: 16, color: theme.colorScheme.primary),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  child: Text(
                                    (post['author'] ?? 'P').trim()[0].toUpperCase(),
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post['author'] ?? 'Pet Owner',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            'Posted ${post['posted'] ?? 'recently'}',
                                            style: TextStyle(
                                              color: theme.colorScheme.onSurfaceVariant,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (_edited) ...[
                                            const SizedBox(width: 4),
                                            Text(
                                              '(edited)',
                                              style: TextStyle(
                                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                                fontSize: 11,
                                                fontStyle: FontStyle.italic,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              post['title'] ?? '',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 26,
                                height: 1.15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (tags.isNotEmpty || !hasImage) ...[
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (!hasImage)
                                    _StatusBadge(
                                      label: post['postType'] ?? 'Post',
                                    ),
                                  ...tags.map((tag) => ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isDark
                                            ? Colors.white.withValues(alpha: 0.05)
                                            : Colors.black.withValues(alpha: 0.03),
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(color: theme.dividerColor),
                                        ),
                                        child: Text(
                                          tag,
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )).toList(),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            Text(
                              post['description'] ?? '',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 16,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_currentUserId != null && _currentUserId != post['authorId']) ...[
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: isDark ? AppColors.darkSurface : theme.colorScheme.primary,
                                    foregroundColor: isDark ? theme.colorScheme.onSurface : theme.colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: _openConversation,
                                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                                  label: const Text(
                                    'Message this user',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          Divider(height: 1, color: theme.dividerColor),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            child: Row(
                              children: [
                                _InteractionButton(
                                  icon: _youLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  label: '$_likeCount',
                                  color: _youLiked ? Colors.redAccent : theme.colorScheme.onSurfaceVariant,
                                  onTap: _togglePostLike,
                                ),
                                const SizedBox(width: 24),
                                _InteractionButton(
                                  icon: Icons.mode_comment_outlined,
                                  label: '$_commentCount',
                                  color: theme.colorScheme.onSurfaceVariant,
                                  onTap: () {},
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: theme.dividerColor),
                        ],
                      ),
                    ),
                    if (_isLoadingComments)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      )
                    else if (_comments.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Center(
                            child: Text(
                              'No comments yet. Start the discussion.',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final comment = rootComments[index];
                            final replies = repliesByParentId[comment.commentId] ?? const [];

                            return Padding(
                              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _UnifiedCommentCard(
                                    comment: comment,
                                    currentUserId: _currentUserId,
                                    onReplyTap: () => _startReply(comment),
                                    onLikeTap: () => _toggleCommentLike(comment),
                                  ),
                                  if (replies.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 16, top: 12),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            left: BorderSide(
                                              color: theme.dividerColor,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          children: replies.map((reply) => Padding(
                                            padding: const EdgeInsets.only(left: 16, bottom: 12),
                                            child: _UnifiedCommentCard(
                                              comment: reply,
                                              currentUserId: _currentUserId,
                                              onLikeTap: () => _toggleCommentLike(reply),
                                              isReply: true,
                                            ),
                                          )).toList(),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                          childCount: rootComments.length,
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
              ),
            ),
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.8),
                    border: Border(top: BorderSide(color: theme.dividerColor)),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (replyingToName != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Replying to $replyingToName',
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _cancelReply,
                                    child: Icon(Icons.close_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkBackground : theme.scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: theme.dividerColor),
                                  ),
                                  child: TextField(
                                    controller: _commentController,
                                    minLines: 1,
                                    maxLines: 4,
                                    textCapitalization: TextCapitalization.sentences,
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: replyingToName == null ? 'Add a comment...' : 'Write a reply...',
                                      hintStyle: TextStyle(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                height: 44,
                                width: 44,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  onPressed: _isSubmittingComment ? null : _submitComment,
                                  icon: _isSubmittingComment
                                      ? SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: theme.colorScheme.onPrimary,
                                          ),
                                        )
                                      : Icon(Icons.arrow_upward_rounded, color: theme.colorScheme.onPrimary),
                                ),
                              ),
                            ],
                          ),
                        ],
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

class _InteractionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _InteractionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnifiedCommentCard extends StatelessWidget {
  final PostComment comment;
  final String? currentUserId;
  final VoidCallback? onReplyTap;
  final VoidCallback onLikeTap;
  final bool isReply;

  const _UnifiedCommentCard({
    required this.comment,
    this.onReplyTap,
    required this.onLikeTap,
    this.currentUserId,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authorLabel = comment.userId == currentUserId ? 'You' : comment.authorName;

    return Container(
      width: double.infinity,
      padding: isReply ? const EdgeInsets.all(12) : const EdgeInsets.all(0),
      decoration: isReply
          ? BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                child: Text(
                  authorLabel.isEmpty ? 'M' : authorLabel[0].toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      authorLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.relativeCreatedAt,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 36, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.content,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onLikeTap,
                      child: Row(
                        children: [
                          Icon(
                            comment.youLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 16,
                            color: comment.youLiked ? Colors.redAccent : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${comment.likeCount}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (!isReply && onReplyTap != null)
                      GestureDetector(
                        onTap: onReplyTap,
                        child: Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: theme.colorScheme.onSurface, size: 20),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;

  const _StatusBadge({required this.label});

  static Color getTextColor(String type, ThemeData theme) {
    final t = type.toLowerCase();
    if (t == 'lost pet') return Colors.redAccent;
    if (t == 'report') return Colors.orangeAccent;
    if (t == 'found pet') return Colors.green;
    if (t == 'adoption') return Colors.deepPurpleAccent;
    if (t == 'discussion') return Colors.blueAccent;
    return theme.colorScheme.onSurface;
  }

  static Color getBgColor(String type, ThemeData theme) {
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: getBgColor(label, theme),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: getTextColor(label, theme),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}