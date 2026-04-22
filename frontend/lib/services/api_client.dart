import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  ApiClient({Dio? dio, FlutterSecureStorage? storage})
    : storage = storage ?? const FlutterSecureStorage(),
      dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl)) {
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await this.storage.read(key: accessTokenKey);

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            await clearToken();
          }
          handler.next(e);
        },
      ),
    );
  }

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const accessTokenKey = 'access_token';

  final Dio dio;
  final FlutterSecureStorage storage;

  Future<String?> getToken() {
    return storage.read(key: accessTokenKey);
  }

  Future<void> saveToken(String token) {
    return storage.write(key: accessTokenKey, value: token);
  }

  Future<void> clearToken() {
    return storage.delete(key: accessTokenKey);
  }

  String messageForError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['detail'] != null) {
        return data['detail'].toString();
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Could not connect to the backend at $baseUrl.';
      }
    }

    return 'Something went wrong. Please try again.';
  }
}