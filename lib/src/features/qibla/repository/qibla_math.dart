import 'dart:math' as math;

class QiblaMath {
  static const kaabaLatitude = 21.422487;
  static const kaabaLongitude = 39.826206;
  static double normalize(double degrees) => (degrees % 360 + 360) % 360;

  /// Shortest clockwise-positive rotation, safe at the 359° -> 0° boundary.
  static double delta(double from, double to) =>
      (normalize(to) - normalize(from) + 540) % 360 - 180;
  static double bearing(double latitude, double longitude) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180) {
      throw ArgumentError('Invalid coordinates');
    }
    final lat = latitude * math.pi / 180;
    final target = kaabaLatitude * math.pi / 180;
    final difference = (kaabaLongitude - longitude) * math.pi / 180;
    final y = math.sin(difference) * math.cos(target);
    final x =
        math.cos(lat) * math.sin(target) -
        math.sin(lat) * math.cos(target) * math.cos(difference);
    if (x.abs() < 1e-12 && y.abs() < 1e-12) {
      throw StateError('Qibla bearing is undefined at this location');
    }
    return normalize(math.atan2(y, x) * 180 / math.pi);
  }
}
