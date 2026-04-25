import 'package:flutter/material.dart';
import 'package:pawnder_app/models/community_post.dart';
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

  List<PostComment> _comments = const [];
  bool _isLoadingComments = true;
  bool _isSubmittingComment = false;
  String? _currentUserId;
  String? _replyingToCommentId;
  String? _communityName;

  @override
  void initState() {
    super.initState();
    _likeCount = int.tryParse(widget.post['likeCount'] ?? '0') ?? 0;
    _commentCount = int.tryParse(widget.post['commentCount'] ?? '0') ?? 0;
    _youLiked = widget.post['youLiked'] == 'true';

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
        _fetchCommunityName(commId);
      }

      await Future.wait([
        _checkIfBookmarked(user.id),
        _loadComments(),
      ]);
    } catch (e) {
      debugPrint('Error initializing detail screen: $e');
      if (mounted) {
        setState(() {
          _isCheckingBookmark = false;
          _isLoadingComments = false;
        });
      }
    }
  }

  Future<void> _fetchCommunityName(String commId) async {
    try {
      final comm = await _communityService.getCommunityById(communityId: commId);
      if (mounted) {
        setState(() => _communityName = comm.name);
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
      debugPrint('Error mapping comments: $e');
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
      if (mounted) {
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
      if (mounted) {
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
      debugPrint('Error submitting comment: $e');
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

  void _startReply(PostComment comment) {
    setState(() => _replyingToCommentId = comment.commentId);
  }

  void _cancelReply() {
    setState(() => _replyingToCommentId = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final post = widget.post;
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: MediaQuery.sizeOf(context).height * 0.45,
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
                      child: _isCheckingBookmark || _isBookmarking
                          ? Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black.withOpacity(0.7)
                                    : Colors.white.withOpacity(0.8),
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
                  flexibleSpace: FlexibleSpaceBar(
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
                                Colors.black.withOpacity(0.4),
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withOpacity(0.8)
                                  : Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              (post['section'] ?? '') == 'found' ? 'Found' : 'Lost',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_communityName != null) ...[
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, size: 14, color: theme.colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Posted in $_communityName',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
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
                                  Text(
                                    'Posted ${post['posted'] ?? 'recently'}',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
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
                        if (tags.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: tags.map((tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkElevated : const Color(0xFFEDEFF1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            )).toList(),
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
                              label: '$_likeCount Likes',
                              color: _youLiked ? Colors.redAccent : theme.colorScheme.onSurfaceVariant,
                              onTap: _togglePostLike,
                            ),
                            const SizedBox(width: 24),
                            _InteractionButton(
                              icon: Icons.mode_comment_outlined,
                              label: '$_commentCount Comments',
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
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
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
                          color: theme.scaffoldBackgroundColor,
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
        ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
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
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withOpacity(0.6)
              : Colors.white.withOpacity(0.75),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: theme.colorScheme.onSurface, size: 20),
      ),
    );
  }
}