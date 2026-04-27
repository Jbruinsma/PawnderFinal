import 'package:pawnder_app/models/community.dart';
import 'package:pawnder_app/services/api_client.dart';

class CreateCommunityRequest {
  const CreateCommunityRequest({
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
  });

  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String? imageUrl;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }
}

class CommunityService {
  CommunityService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Community>> getNeighborhoods({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/community/neighborhoods',
      queryParameters: {'latitude': latitude, 'longitude': longitude},
    );

    final neighborhoods =
        response.data?['neighborhoods'] as List<dynamic>? ?? const [];

    return neighborhoods
        .map((json) => Community.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Community>> getMyNeighborhoods() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/community/my-neighborhoods',
    );

    final neighborhoods =
        response.data?['neighborhoods'] as List<dynamic>? ?? const [];

    return neighborhoods
        .map((json) => Community.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Community> getCommunityById({required String communityId}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/community/neighborhoods/$communityId',
    );
    final communityJson =
        response.data?['community'] as Map<String, dynamic>? ??
        response.data ??
        const {};
    return Community.fromJson(communityJson);
  }

  Future<void> joinNeighborhood({required String communityId}) async {
    await _apiClient.post<void>('/community/neighborhoods/$communityId/join');
  }

  Future<Community> createNeighborhood(CreateCommunityRequest request) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/community/neighborhoods',
      data: request.toJson(),
    );

    final communityJson =
        response.data?['community'] as Map<String, dynamic>? ?? const {};
    return Community.fromJson(communityJson);
  }
}