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
  final ValueChanged<CommunityPost> onPostTap;
  final VoidCallback onAddListingTap;

  const CommunityPostsScreen({
    super.key,
    required this.title,
    required this.posts,
    required this.onPostTap,
    required this.onAddListingTap,
  });

  @override
  State<CommunityPostsScreen> createState() => _CommunityPostsScreenState();
}

class _CommunityPostsScreenState extends State<CommunityPostsScreen> {
  String _searchQuery = '';
  final _postService = PostService();
  final _apiClient = ApiClient();
  late List<CommunityPost> _posts;
  final Map<String, List<PostComment>> _commentsByPostId = {};

  @override
  void initState() {
    super.initState();
    _posts = List<CommunityPost>.from(widget.posts);
    for (final post in _posts) {
      _commentsByPostId[post.id] = List<PostComment>.from(post.comments);
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
            _posts[index] = CommunityPost(
              id: currentPost.id,
              authorId: currentPost.authorId,
              postType: currentPost.postType,
              title: currentPost.title,
              description: currentPost.description,
              status: currentPost.status,
              createdAt: currentPost.createdAt,
              location: currentPost.location,
              tags: currentPost.tags,
              likeCount: currentPost.likeCount,
              commentCount: currentPost.commentCount + 1,
              comments: _commentsByPostId[post.id] ?? currentPost.comments,
              communityId: currentPost.communityId,
              authorName: currentPost.authorName,
              imageUrl: currentPost.imageUrl,
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
  String? _errorMessage;
  String? _currentUserId;
  List<PostComment> _comments = const [];

  @override
  void initState() {
    super.initState();
    _comments = List<PostComment>.from(widget.initialComments);
    _loadCurrentUser();
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      );
      if (!mounted) {
        return;
      }
      _controller.clear();
      setState(() {
        _errorMessage = null;
        _comments = [..._comments, comment];
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

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
                        itemCount: _comments.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return _CommentCard(
                            comment: comment,
                            currentUserId: _currentUserId,
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Row(
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
                          decoration: const InputDecoration(
                            hintText: 'Write a comment...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send'),
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

  const _CommentCard({required this.comment, this.currentUserId});

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
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
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
        ],
      ),
    );
  }
}
