import 'api_service.dart';

class CommunityService {
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
        'id': post['postId']?.toString() ?? '',
        'section': (post['postType'] ?? '').toLowerCase().contains('lost')
            ? 'recent'
            : 'found',
        'title': post['title']?.toString() ?? '',
        'author': post['authorUsername']?.toString() ?? 'Unknown',
        'location': '${location['latitude'] ?? ''}, ${location['longitude'] ?? ''}',
        'posted': post['createdAt']?.toString() ?? '',
        'tags': tags,
        'image': 'assets/images/animals.jpg',
        'description': post['description']?.toString() ?? '',
      };
    }).toList();
  }

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