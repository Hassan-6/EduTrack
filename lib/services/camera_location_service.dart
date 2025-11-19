import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class CameraLocationData {
  final double latitude;
  final double longitude;
  final double altitude;
  final String address;
  final double accuracy;

  CameraLocationData({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.address,
    required this.accuracy,
  });
}

class CameraLocationService {
  /// Request location permissions
  static Future<bool> requestLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final result = await Geolocator.requestPermission();
      return result == LocationPermission.whileInUse ||
          result == LocationPermission.always;
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Get current location with address via reverse geocoding
  static Future<CameraLocationData?> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        print('Location permission not granted');
        return null;
      }

      // Get current position with high accuracy
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      // Reverse geocode to get address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String address = 'Unknown Location';
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        address = '${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}'
            .replaceAll(RegExp(r',\s*,'), ',')
            .replaceAll(RegExp(r'^,\s*'), '')
            .replaceAll(RegExp(r',\s*$'), '');
      }

      return CameraLocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        address: address,
        accuracy: position.accuracy,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Format coordinates for display
  static String formatCoordinates(double latitude, double longitude) {
    return '$latitude, $longitude';
  }

  /// Format altitude for display
  static String formatAltitude(double altitude) {
    return '${altitude.toStringAsFixed(1)} m';
  }
}
