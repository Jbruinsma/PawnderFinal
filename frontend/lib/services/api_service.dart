import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:8000/api/v1';
  static const String _tokenKey = 'auth_token';

  static final Dio _dio = Dio(BaseOptions(baseUrl: _baseUrl));
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  // ── Token helpers ──────────────────────────────────────────
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // ── Authenticated GET ──────────────────────────────────────
  static Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    final token = await getToken();
    return _dio.get(
      path,
      queryParameters: params,
      options: Options(
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      ),
    );
  }

  // ── Authenticated POST ─────────────────────────────────────
  static Future<Response> post(String path, Map<String, dynamic> body) async {
    final token = await getToken();
    return _dio.post(
      path,
      data: body,
      options: Options(
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      ),
    );
  }

  // ── Public POST (no token needed) ─────────────────────────
  static Future<Response> postPublic(String path, Map<String, dynamic> body) async {
    return _dio.post(path, data: body);
  }
}