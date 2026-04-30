import 'package:pawnder_app/models/current_user.dart';
import 'package:pawnder_app/models/community_post.dart';
import 'package:pawnder_app/services/api_client.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService({ApiClient? apiClient}) {
    return _instance;
  }

  AuthService._internal({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  CurrentUser? _cachedUser;
  Future<CurrentUser>? _userFetchFuture;

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String role = 'Community User',
  }) async {
    await _apiClient.post(
      '/auth/register',
      data: {
        'role': role,
        'email': email,
        'full_name': fullName,
        'password': password,
      },
    );
  }

  Future<void> login({required String identifier, required String password}) async {
    final payload = identifier.contains('@')
        ? {'email': identifier, 'password': password}
        : {'username': identifier, 'password': password};

    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/login',
      data: payload,
    );

    final token = response.data?['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Login response did not include an access token.');
    }

    await _apiClient.saveToken(token);
  }

  Future<CurrentUser> getCurrentUser({bool forceRefresh = false}) async {
    if (_cachedUser != null && !forceRefresh) {
      return _cachedUser!;
    }

    if (_userFetchFuture != null && !forceRefresh) {
      return await _userFetchFuture!;
    }

    _userFetchFuture = _fetchAndCacheUser();
    return await _userFetchFuture!;
  }

  Future<CurrentUser> _fetchAndCacheUser() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/auth/me');

      if (response.data == null) {
        throw Exception('Failed to load user profile data.');
      }

      _cachedUser = CurrentUser.fromJson(response.data!);
      return _cachedUser!;
    } finally {
      _userFetchFuture = null;
    }
  }

  Future<void> updateLocation(PostLocation location) async {
    await _apiClient.dio.put(
      '/auth/me/location',
      data: location.toJson(),
    );
  }

  Future<String?> getToken() {
    return _apiClient.getToken();
  }

  Future<void> logout() async {
    _cachedUser = null;
    _userFetchFuture = null;
    return _apiClient.clearToken();
  }

  String messageForError(Object error) {
    return _apiClient.messageForError(error);
  }
}