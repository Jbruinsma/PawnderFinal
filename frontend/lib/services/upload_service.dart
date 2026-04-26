import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:pawnder_app/services/api_client.dart';

enum UploadPurpose { post, community }

extension UploadPurposeWire on UploadPurpose {
  String get wireValue {
    switch (this) {
      case UploadPurpose.post:
        return 'post';
      case UploadPurpose.community:
        return 'community';
    }
  }
}

class UploadService {
  UploadService({ApiClient? apiClient, Dio? uploadDio})
      : _apiClient = apiClient ?? ApiClient(),
        _uploadDio = uploadDio ?? Dio();

  final ApiClient _apiClient;
  final Dio _uploadDio;

  Future<String> uploadImage({
    required Uint8List bytes,
    required String contentType,
    required UploadPurpose purpose,
  }) async {
    final signResponse = await _apiClient.post<Map<String, dynamic>>(
      '/auth/uploads/sign',
      data: {
        'content_type': contentType,
        'purpose': purpose.wireValue,
      },
    );

    final data = signResponse.data ?? const <String, dynamic>{};
    final uploadUrl = data['upload_url'] as String?;
    final publicUrl = data['public_url'] as String?;

    if (uploadUrl == null || publicUrl == null) {
      throw Exception('Server did not return a usable upload URL.');
    }

    await _uploadDio.put<void>(
      uploadUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          Headers.contentTypeHeader: contentType,
          Headers.contentLengthHeader: bytes.length,
        },
      ),
    );

    return publicUrl;
  }
}
