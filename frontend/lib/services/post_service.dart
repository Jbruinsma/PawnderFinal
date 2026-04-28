import 'package:pawnder_app/models/community_post.dart';
import 'package:pawnder_app/services/api_client.dart';

class PostService {
  PostService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<int> _extractLikeCount({
    required String path,
    required bool shouldLike,
  }) async {
    final response = shouldLike
        ? await _apiClient.post<Map<String, dynamic>>(path)
        : await _apiClient.delete<Map<String, dynamic>>(path);

    if (response.data == null) return 0;
    return (response.data!['new_like_count'] as num?)?.toInt() ?? 0;
  }

  Future<List<CommunityPost>> getCommunityPosts({
    required String communityId,
    int limit = 10,
    int offset = 1,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      'community/posts',
      queryParameters: {
        'community_id': communityId,
        'limit': limit,
        'offset': offset,
      },
    );

    if (response.data == null || !response.data!.containsKey('posts')) {
      return const [];
    }

    final posts = response.data!['posts'];
    if (posts is! List) return const [];

    return posts
        .map((json) => CommunityPost.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<CommunityPost>> getGeoFeed({
    double radiusKm = 8,
    List<String>? tags,
  }) async {
    final response = await _apiClient.get<List<dynamic>>(
      'geo/feed',
      queryParameters: {
        'radius_km': radiusKm,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
      },
    );

    final posts = response.data ?? const [];
    return posts
        .map((json) => CommunityPost.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<CommunityPost>> searchPostsByRadius({
    required double latitude,
    required double longitude,
    double radiusKm = 5,
    List<String>? tags,
  }) async {
    final response = await _apiClient.get<List<dynamic>>(
      'geo/search',
      queryParameters: {
        'lat': latitude,
        'lon': longitude,
        'radius_km': radiusKm,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
      },
    );

    final posts = response.data ?? const [];
    return posts
        .map((json) => CommunityPost.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> deletePost({required String postId}) async {
    await _apiClient.delete<void>('community/posts/$postId');
  }

  Future<String> createPost(CreatePostRequest request) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      'community/posts',
      data: request.toJson(),
    );

    if (response.data == null) return '';
    return response.data!['post_id']?.toString() ?? '';
  }

  Future<List<PostComment>> getPostComments({
    required String postId,
    int limit = 25,
    int offset = 1,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      'community/posts/$postId/comments',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );

    if (response.data == null || !response.data!.containsKey('comments')) {
      return const [];
    }

    final rawComments = response.data!['comments'];
    if (rawComments is! List) return const [];

    return rawComments
        .map((json) => PostComment.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<PostComment> addComment({
    required String postId,
    required String content,
    String? replyingToId,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      'community/posts/$postId/comments',
      data: {
        'content': content,
        if (replyingToId != null) 'replying_to_id': replyingToId,
      },
    );

    return PostComment.fromJson(response.data ?? const {});
  }

  Future<int> setCommentLike({
    required String postId,
    required String commentId,
    required bool shouldLike,
  }) {
    return _extractLikeCount(
      path: 'community/posts/$postId/comments/$commentId/like',
      shouldLike: shouldLike,
    );
  }

  Future<int> setPostLike({required String postId, required bool shouldLike}) {
    return _extractLikeCount(
      path: 'community/posts/$postId/like',
      shouldLike: shouldLike,
    );
  }

  Future<List<CommunityPost>> getUserPosts({required String userId}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      'community/users/$userId/posts',
    );

    if (response.data == null || !response.data!.containsKey('posts')) {
      return const [];
    }

    final posts = response.data!['posts'];
    if (posts is! List) return const [];

    return posts
        .map((json) => CommunityPost.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<CommunityPost>> getUserBookmarks({String? userId}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      'community/bookmarks',
    );

    if (response.data == null || !response.data!.containsKey('posts')) {
      return const [];
    }

    final posts = response.data!['posts'];
    if (posts is! List) return const [];

    return posts
        .map((json) => CommunityPost.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> bookmarkPost({
    required String postId,
    String? userId,
  }) async {
    await _apiClient.post<void>('community/posts/$postId/bookmark');
  }

  Future<bool> isPostBookmarked({
    required String postId,
    String? userId,
  }) async {
    try {
      final bookmarks = await getUserBookmarks();
      return bookmarks.any((post) => post.id == postId);
    } catch (_) {
      return false;
    }
  }

  Future<void> removeBookmark({
    required String postId,
    String? userId,
  }) async {
    await _apiClient.delete<void>('community/posts/$postId/bookmark');
  }
}