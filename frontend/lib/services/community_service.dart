import 'api_service.dart';

class CommunityService {
  /// Fetches posts for a given community_id.
  /// Returns a list of post maps matching the shape home_screen expects.
  static Future<List<Map<String, String>>> getPosts(String communityId) async {
    final response = await ApiService.get(
      '/community/posts',
      params: {'community_id': communityId, 'offset': 1, 'limit': 20},
    );

    final List<dynamic> raw = response.data['posts'] ?? [];

    return raw.map<Map<String, String>>((post) {
      final location = post['location'] as Map<String, dynamic>? ?? {};
      final tags = (post['tags'] as List<dynamic>?)?.join('|') ?? '';

      return {
        'id': post['post_id']?.toString() ?? '',
        'section': (post['post_type'] ?? '').toLowerCase().contains('lost')
            ? 'recent'
            : 'found',
        'title': post['title']?.toString() ?? '',
        'author': post['author_username']?.toString() ?? 'Unknown',
        'location':
            '${location['latitude'] ?? ''}, ${location['longitude'] ?? ''}',
        'posted': post['created_at']?.toString() ?? '',
        'tags': tags,
        'image': 'assets/images/animals.jpg', // placeholder until image_url is wired
        'description': post['description']?.toString() ?? '',
      };
    }).toList();
  }

  /// Fetches all neighborhoods sorted by proximity.
  static Future<List<Map<String, String>>> getNeighborhoods({
    double latitude = 40.7128,
    double longitude = -74.0060,
  }) async {
    final response = await ApiService.get(
      '/community/neighborhoods',
      params: {'latitude': latitude, 'longitude': longitude},
    );

    final List<dynamic> raw = response.data['neighborhoods'] ?? [];
    return raw.map<Map<String, String>>((n) => {
      'id': n['id']?.toString() ?? '',
      'name': n['name']?.toString() ?? '',
      'description': n['description']?.toString() ?? '',
    }).toList();
  }
}