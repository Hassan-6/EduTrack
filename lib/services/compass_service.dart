import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class CompassService {
  static const double PI = 3.14159265359;

  /// Get compass heading stream
  static Stream<double> getCompassHeading() {
    return magnetometerEvents.map((MagnetometerEvent event) {
      double heading = _calculateHeading(event.x, event.y);
      return heading;
    });
  }

  /// Calculate heading from magnetometer data
  static double _calculateHeading(double x, double y) {
    double heading = (180 * atan2(y, x) / PI).toAbsoluteValue();
    return (heading + 90) % 360; // Adjust for phone orientation
  }

  /// Convert heading to compass direction (N, NE, E, SE, S, SW, W, NW)
  static String getCompassDirection(double heading) {
    const directions = [
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'
    ];
    
    // Normalize heading to 0-360
    final normalizedHeading = ((heading % 360) + 360) % 360;
    
    // Each direction covers 22.5 degrees (360 / 16)
    final index = ((normalizedHeading + 11.25) / 22.5).toInt() % 16;
    return directions[index];
  }

  /// Format heading for display (e.g., "45° NE")
  static String formatHeading(double heading) {
    final direction = getCompassDirection(heading);
    return '${heading.toStringAsFixed(0)}° $direction';
  }
}

extension AbsoluteValue on double {
  double toAbsoluteValue() {
    return this < 0 ? this * -1 : this;
  }
}
