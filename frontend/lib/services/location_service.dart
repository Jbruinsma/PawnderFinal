import 'package:geolocator/geolocator.dart';
import 'package:pawnder_app/models/community_post.dart';
import 'package:pawnder_app/services/auth_service.dart';

class LocationService {
  LocationService({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

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
