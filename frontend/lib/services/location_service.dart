import 'package:geolocator/geolocator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pawnder_app/models/community_post.dart';
import 'package:pawnder_app/services/auth_service.dart';

class LocationService {
  LocationService({AuthService? authService, FlutterSecureStorage? storage})
    : _authService = authService ?? AuthService(),
      _storage = storage ?? const FlutterSecureStorage();

  final AuthService _authService;
  final FlutterSecureStorage _storage;

  static const _homeLocationPromptKeyPrefix = 'home_location_prompt_seen_';

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
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    final location = PostLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    await _authService.updateLocation(location);
    return location;
  }
}