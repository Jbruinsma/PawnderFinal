import 'package:pawnder_app/models/community.dart';
import 'package:pawnder_app/services/api_client.dart';

class CommunityService {
  CommunityService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Community>> getNeighborhoods({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      'community/neighborhoods',
      queryParameters: {'latitude': latitude, 'longitude': longitude},
    );

    final neighborhoods =
        response.data?['neighborhoods'] as List<dynamic>? ?? const [];

    return neighborhoods
        .map((json) => Community.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Community>> getMyNeighborhoods() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      'community/my-neighborhoods',
    );

    final neighborhoods =
        response.data?['neighborhoods'] as List<dynamic>? ?? const [];

    return neighborhoods
        .map((json) => Community.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> joinNeighborhood({required String communityId}) async {
    await _apiClient.dio.post<void>(
      'community/neighborhoods/$communityId/join',
    );
  }

  Future<Community> createNeighborhood({
    required String name,
    required String description,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'community/neighborhoods',
      data: {
        'name': name,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
      },
    );

    final communityJson =
        response.data?['community'] as Map<String, dynamic>? ?? const {};
    return Community.fromJson(communityJson);
  }
}
