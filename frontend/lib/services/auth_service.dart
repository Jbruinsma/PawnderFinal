import 'package:pawnder_app/models/current_user.dart';
import 'package:pawnder_app/models/community_post.dart';
import 'package:pawnder_app/services/api_client.dart';

class AuthService {
  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String role = 'Community User',
  }) async {
    await _apiClient.dio.post(
      '/api/v1/auth/register',
      data: {
        'role': role,
        'email': email,
        'full_name': fullName,
        'password': password,
      },
    );
  }

  Future<void> login({required String email, required String password}) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/v1/auth/login',
      data: {'email': email, 'password': password},
    );

    final token = response.data?['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Login response did not include an access token.');
    }

    await _apiClient.saveToken(token);
  }

  Future<CurrentUser> getCurrentUser() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/v1/auth/me',
    );

    return CurrentUser.fromJson(response.data ?? const {});
  }

  Future<void> updateLocation(PostLocation location) async {
    await _apiClient.dio.put(
      '/api/v1/auth/me/location',
      data: location.toJson(),
    );
  }

  Future<String?> getToken() {
    return _apiClient.getToken();
  }

  Future<void> logout() {
    return _apiClient.clearToken();
  }

  String messageForError(Object error) {
    return _apiClient.messageForError(error);
  }
}
