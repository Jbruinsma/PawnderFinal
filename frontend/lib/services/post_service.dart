import 'package:pawnder_app/models/community_post.dart';
import 'package:pawnder_app/services/api_client.dart';

class PostService {
  PostService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<CommunityPost>> getCommunityPosts({
    required String communityId,
    int limit = 10,
    int offset = 1,
  }) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/v1/community/posts',
      queryParameters: {
        'community_id': communityId,
        'limit': limit,
        'offset': offset,
      },
    );

    final posts = response.data?['posts'] as List<dynamic>? ?? const [];

    return posts
        .map((json) => CommunityPost.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<CommunityPost>> getGeoFeed({
    double radiusKm = 8,
    List<String>? tags,
  }) async {
    final response = await _apiClient.dio.get<List<dynamic>>(
      '/api/v1/geo/feed',
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
    final response = await _apiClient.dio.get<List<dynamic>>(
      '/api/v1/geo/search',
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

  Future<String> createPost(CreatePostRequest request) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/v1/community/posts',
      data: request.toJson(),
    );

    return response.data?['post_id']?.toString() ?? '';
  }
}
