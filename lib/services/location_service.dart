import 'package:geolocator/geolocator.dart';

class LocationResult {
  final Position? position;
  final String? error;
  const LocationResult({this.position, this.error});
}

class LocationService {
  /// Asks for permission if needed and returns the phone's real GPS position.
  static Future<LocationResult> getCurrent() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        return const LocationResult(
            error: 'Please turn on Location (GPS) on your phone.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult(error: 'Location permission was denied.');
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
            error:
                'Location permission is blocked. Enable it in phone Settings > Apps > SafeCircle.');
      }
      final position = await Geolocator.getCurrentPosition();
      return LocationResult(position: position);
    } catch (e) {
      return const LocationResult(error: 'Could not get your location.');
    }
  }
}