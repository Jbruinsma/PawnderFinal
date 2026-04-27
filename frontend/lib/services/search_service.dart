import 'package:dio/dio.dart';
import 'package:pawnder_app/models/community.dart';
import 'package:pawnder_app/models/community_post.dart';
import 'package:pawnder_app/services/api_client.dart';

class SearchAllResults {
  const SearchAllResults({required this.communities, required this.posts});

  final List<Community> communities;
  final List<CommunityPost> posts;

  bool get isEmpty => communities.isEmpty && posts.isEmpty;

  static const empty = SearchAllResults(communities: [], posts: []);

  SearchAllResults copyWith({
    List<Community>? communities,
    List<CommunityPost>? posts,
  }) {
    return SearchAllResults(
      communities: communities ?? this.communities,
      posts: posts ?? this.posts,
    );
  }
}

class SearchService {
  SearchService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<SearchAllResults> searchAll({
    required String query,
    CancelToken? cancelToken,
  }) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/search/all',
      queryParameters: {'q': query},
      cancelToken: cancelToken,
    );

    final data = response.data ?? const {};
    final rawCommunities = data['communities'] as List<dynamic>? ?? const [];
    final rawPosts = data['posts'] as List<dynamic>? ?? const [];

    return SearchAllResults(
      communities: rawCommunities
          .map((json) => Community.fromJson(json as Map<String, dynamic>))
          .toList(),
      posts: rawPosts
          .map((json) => CommunityPost.fromJson(json as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<Community>> searchCommunities({
    required String query,
    int limit = 20,
    int offset = 0,
    CancelToken? cancelToken,
  }) async {
    final response = await _apiClient.dio.get<List<dynamic>>(
      '/search/communities',
      queryParameters: {'q': query, 'limit': limit, 'offset': offset},
      cancelToken: cancelToken,
    );

    final raw = response.data ?? const [];
    return raw
        .map((json) => Community.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}