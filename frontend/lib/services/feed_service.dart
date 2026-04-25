import 'package:pawnder_app/models/community.dart';
import 'package:pawnder_app/models/community_post.dart';
import 'api_client.dart';

class FeedService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getNewFeed({required double latitude, required double longitude}) async {
    final response = await _apiClient.get(
      'community/new-feed',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
      },
    );

    final data = response.data as Map<String, dynamic>;

    final communities = (data['communities'] as List)
        .map((c) => Community.fromJson(c as Map<String, dynamic>))
        .toList();

    final posts = (data['posts'] as List)
        .map((p) => CommunityPost.fromJson(p as Map<String, dynamic>))
        .toList();

    final tags = (data['applicable_tags'] as List?)?.cast<String>() ?? [];

    return {
      'communities': communities,
      'posts': posts,
      'applicable_tags': tags,
    };
  }
}