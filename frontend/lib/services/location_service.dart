import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pawnder_app/models/community_post.dart';
import 'package:pawnder_app/services/auth_service.dart';

class LocationService {
  LocationService({AuthService? authService, FlutterSecureStorage? storage})
      : _authService = authService ?? AuthService(),
        _storage = storage ?? const FlutterSecureStorage();

  final AuthService _authService;
  final FlutterSecureStorage _storage;

  static const _homeLocationPromptKeyPrefix = 'home_location_prompt_seen_';

  Future<LocationPermission> checkPermissionStatus() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationPermission.denied;
      }
      return await Geolocator.checkPermission();
    } catch (_) {
      return LocationPermission.denied;
    }
  }

  Future<bool> openDeviceSettings() async {
    return await Geolocator.openAppSettings();
  }

  Future<bool> shouldPromptForFirstHomeLaunch({required String userId}) async {
    final stored = await _storage.read(
      key: '$_homeLocationPromptKeyPrefix$userId',
    );
    return stored != 'true';
  }

  Future<void> markHomeLocationPromptSeen({required String userId}) {
    return _storage.write(
      key: '$_homeLocationPromptKeyPrefix$userId',
      value: 'true',
    );
  }

  Future<PostLocation?> requestAndSaveCurrentLocation() async {
    final LocationPermission permission;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return null;
      }

      var current = await Geolocator.checkPermission();
      if (current == LocationPermission.denied) {
        current = await Geolocator.requestPermission();
      }
      permission = current;
    } catch (_) {
      return null;
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await _resolvePosition();
    if (position == null) {
      return null;
    }

    final location = PostLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    try {
      await _authService.updateLocation(location);
    } catch (_) {
    }

    return location;
  }

  Future<Position?> _resolvePosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
    }

    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }
}