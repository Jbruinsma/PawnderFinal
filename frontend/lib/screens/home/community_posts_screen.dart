import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pawnder_app/models/community_post.dart';
import 'package:pawnder_app/services/auth_service.dart';
import 'package:pawnder_app/services/api_client.dart';
import 'package:pawnder_app/services/post_service.dart';
import 'package:pawnder_app/widgets/build_community_posts_feed.dart';
import 'package:pawnder_app/widgets/build_header.dart';

class CommunityPostsScreen extends StatefulWidget {
  final String title;
  final List<CommunityPost> posts;
  final String? communityId;
  final ValueChanged<CommunityPost> onPostTap;
  final VoidCallback onAddListingTap;
  final ValueChanged<String>? onPostDelete;

  const CommunityPostsScreen({
    super.key,
    required this.title,
    required this.posts,
    required this.onPostTap,
    required this.onAddListingTap,
    this.communityId,
    this.onPostDelete,
  });

  @override
  State<CommunityPostsScreen> createState() => _CommunityPostsScreenState();
}

class _CommunityPostsScreenState extends State<CommunityPostsScreen> {
  String _searchQuery = '';
  final _postService = PostService();
  final _apiClient = ApiClient();
  final _authService = AuthService();
  late List<CommunityPost> _posts;
  final Map<String, List<PostComment>> _commentsByPostId = {};
  Timer? _pollTimer;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _posts = List<CommunityPost>.from(widget.posts);
    for (final post in _posts) {
      _commentsByPostId[post.id] = List<PostComment>.from(post.comments);
    }
    _loadCurrentUserId();
    if (widget.communityId != null) {
      _pollTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _refreshPosts(),
      );
    }
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

  Future<void> _refreshPosts() async {
    final communityId = widget.communityId;
    if (communityId == null) return;
    try {
      final fresh = await _postService.getCommunityPosts(
        communityId: communityId,
        limit: 50,
      );
      if (!mounted) return;
      setState(() {
        _posts = fresh;
        for (final post in _posts) {
          _commentsByPostId.putIfAbsent(
            post.id,
            () => List<PostComment>.from(post.comments),
          );
        }
      });
    } catch (_) {}
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

  Future<void> _openCommentsSheet(Map<String, String> postMap) async {
    final postId = postMap['id'];
    if (postId == null) {
      return;
    }

    final postIndex = _posts.indexWhere((item) => item.id == postId);
    if (postIndex == -1) {
      return;
    }
    final post = _posts[postIndex];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(
        postId: post.id,
        initialComments: _commentsByPostId[post.id] ?? post.comments,
        postService: _postService,
        apiClient: _apiClient,
        onCommentsLoaded: (comments) {
          _commentsByPostId[post.id] = comments;
        },
        onCommentAdded: () {
          final index = _posts.indexWhere((item) => item.id == post.id);
          if (index == -1) {
            return;
          }
          final currentPost = _posts[index];
          setState(() {
            _posts[index] = currentPost.copyWith(
              commentCount: currentPost.commentCount + 1,
              comments: _commentsByPostId[post.id] ?? currentPost.comments,
            );
          });
        },
        onCommentCreated: (comment) {
          final existing = _commentsByPostId[post.id] ?? const [];
          _commentsByPostId[post.id] = [...existing, comment];
        },
      ),
    );
  }

  Future<void> _togglePostLike(Map<String, String> postMap) async {
    final postId = postMap['id'];
    if (postId == null) {
      return;
    }

    final index = _posts.indexWhere((item) => item.id == postId);
    if (index == -1) {
      return;
    }

    final post = _posts[index];
    final shouldLike = !post.youLiked;

    try {
      final newLikeCount = await _postService.setPostLike(
        postId: postId,
        shouldLike: shouldLike,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _posts[index] = post.copyWith(
          likeCount: newLikeCount,
          youLiked: shouldLike,
        );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_apiClient.messageForError(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postMaps = _posts.map((post) => post.toFeedMap()).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeHeader(
                title: 'RECENT POSTS',
                subtitle: widget.title,
                icon: Icons.groups_2_outlined,
                trailing: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search for pets...',
                          border: InputBorder.none,
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.filter_alt_outlined,
                      size: 20,
                      color: theme.colorScheme.onSurface,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: buildCommunityPostsFeed(
                  posts: postMaps,
                  searchQuery: _searchQuery,
                  currentUserId: _currentUserId,
                  onPostTap: (postMap) {
                    final postId = postMap['id'];
                    if (postId == null) {
                      return;
                    }
                    final selectedIndex = _posts.indexWhere(
                      (item) => item.id == postId,
                    );
                    if (selectedIndex != -1) {
                      widget.onPostTap(_posts[selectedIndex]);
                    }
                  },
                  onCommentTap: _openCommentsSheet,
                  onLikeTap: _togglePostLike,
                  onDeleteTap: (postMap) async {
                    final postId = postMap['id'];
                    if (postId == null) return;
                    final index = _posts.indexWhere(
                      (item) => item.id == postId,
                    );
                    if (index == -1) return;
                    await _confirmDeletePost(_posts[index]);
                  },
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

class _CommentsSheet extends StatefulWidget {
  final String postId;
  final List<PostComment> initialComments;
  final PostService postService;
  final ApiClient apiClient;
  final ValueChanged<List<PostComment>> onCommentsLoaded;
  final VoidCallback onCommentAdded;
  final ValueChanged<PostComment> onCommentCreated;

  const _CommentsSheet({
    required this.postId,
    required this.initialComments,
    required this.postService,
    required this.apiClient,
    required this.onCommentsLoaded,
    required this.onCommentAdded,
    required this.onCommentCreated,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _controller = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _replyingToCommentId;
  String? _errorMessage;
  String? _currentUserId;
  List<PostComment> _comments = const [];
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _comments = List<PostComment>.from(widget.initialComments);
    _loadCurrentUser();
    _loadComments();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _pollComments(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pollComments() async {
    if (_isSubmitting) return;
    try {
      final comments = await widget.postService.getPostComments(
        postId: widget.postId,
      );
      if (!mounted) return;
      setState(() => _comments = comments);
      widget.onCommentsLoaded(comments);
    } catch (_) {}
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (!mounted) {
        return;
      }
      setState(() => _currentUserId = user.id);
    } catch (_) {}
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final comments = await widget.postService.getPostComments(
        postId: widget.postId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _comments = comments;
        _errorMessage = null;
      });
      widget.onCommentsLoaded(comments);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (_comments.isEmpty) {
          _errorMessage = widget.apiClient.messageForError(error);
        } else {
          _errorMessage = null;
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final comment = await widget.postService.addComment(
        postId: widget.postId,
        content: content,
        replyingToId: _replyingToCommentId,
      );
      if (!mounted) {
        return;
      }
      _controller.clear();
      setState(() {
        _errorMessage = null;
        _comments = [..._comments, comment];
        _replyingToCommentId = null;
      });
      widget.onCommentCreated(comment);
      widget.onCommentAdded();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.apiClient.messageForError(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _toggleCommentLike(PostComment comment) async {
    final shouldLike = !comment.youLiked;

    try {
      final newLikeCount = await widget.postService.setCommentLike(
        postId: widget.postId,
        commentId: comment.commentId,
        shouldLike: shouldLike,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _comments = _comments
            .map(
              (item) => item.commentId == comment.commentId
                  ? item.copyWith(likeCount: newLikeCount, youLiked: shouldLike)
                  : item,
            )
            .toList();
      });
      widget.onCommentsLoaded(_comments);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.apiClient.messageForError(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _startReply(PostComment comment) {
    setState(() => _replyingToCommentId = comment.commentId);
  }

  void _cancelReply() {
    setState(() => _replyingToCommentId = null);
  }

  String? _authorNameForComment(String? commentId) {
    if (commentId == null) {
      return null;
    }

    for (final comment in _comments) {
      if (comment.commentId == commentId) {
        return comment.userId == _currentUserId ? 'You' : comment.authorName;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final replyingToName = _authorNameForComment(_replyingToCommentId);
    final rootComments = _comments
        .where((comment) => comment.replyingToId == null)
        .toList();
    final repliesByParentId = <String, List<PostComment>>{};
    for (final comment in _comments.where(
      (comment) => comment.replyingToId != null,
    )) {
      repliesByParentId
          .putIfAbsent(comment.replyingToId!, () => [])
          .add(comment);
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(top: 80, bottom: bottomInset),
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        'Comments',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                width: double.infinity,
                color: theme.dividerColor,
              ),
              Expanded(
                child: _isLoading && _comments.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    : _comments.isEmpty
                    ? Center(
                        child: Text(
                          'No comments yet. Start the conversation.',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                        itemCount: rootComments.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final comment = rootComments[index];
                          final replies =
                              repliesByParentId[comment.commentId] ?? const [];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _CommentCard(
                                comment: comment,
                                currentUserId: _currentUserId,
                                onReplyTap: () => _startReply(comment),
                                onLikeTap: () => _toggleCommentLike(comment),
                              ),
                              if (replies.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.only(left: 18),
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(
                                      14,
                                      12,
                                      0,
                                      2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border(
                                        left: BorderSide(
                                          color: theme.colorScheme.primary,
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          children: replies
                                              .map(
                                                (reply) => Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 10,
                                                      ),
                                                  child: _CommentCard(
                                                    comment: reply,
                                                    currentUserId:
                                                        _currentUserId,
                                                    onLikeTap: () =>
                                                        _toggleCommentLike(
                                                          reply,
                                                        ),
                                                    isReply: true,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (replyingToName != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Replying to $replyingToName',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _cancelReply,
                              child: const Text('Cancel'),
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
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: TextField(
                              controller: _controller,
                              minLines: 1,
                              maxLines: 4,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: replyingToName == null
                                    ? 'Write a comment...'
                                    : 'Write a reply...',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: _isSubmitting ? null : _submitComment,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(replyingToName == null ? 'Send' : 'Reply'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final PostComment comment;
  final String? currentUserId;
  final VoidCallback? onReplyTap;
  final VoidCallback onLikeTap;
  final bool isReply;

  const _CommentCard({
    required this.comment,
    this.onReplyTap,
    required this.onLikeTap,
    this.currentUserId,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authorLabel = comment.userId == currentUserId
        ? 'You'
        : comment.authorName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isReply
            ? theme.colorScheme.primary.withValues(alpha: 0.05)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isReply ? theme.colorScheme.primary : theme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  authorLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                comment.relativeCreatedAt,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.content,
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onLikeTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 2,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        comment.youLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 18,
                        color: comment.youLiked
                            ? Colors.redAccent
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${comment.likeCount}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              if (!isReply && onReplyTap != null)
                TextButton(
                  onPressed: onReplyTap,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Reply'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
