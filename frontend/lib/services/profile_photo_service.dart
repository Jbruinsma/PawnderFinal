import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfilePhotoService {
  ProfilePhotoService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  String _storageKey(String userId) => 'profile_photo_path_$userId';

  Future<void> savePhotoPath({
    required String userId,
    required String path,
  }) async {
    await _storage.write(key: _storageKey(userId), value: path);
  }

  Future<String?> getPhotoPath(String userId) async {
    final path = await _storage.read(key: _storageKey(userId));
    if (path == null || path.isEmpty) {
      return null;
    }

    final file = File(path);
    if (!await file.exists()) {
      await clearPhotoPath(userId);
      return null;
    }

    return path;
  }

  Future<void> clearPhotoPath(String userId) async {
    await _storage.delete(key: _storageKey(userId));
  }
}