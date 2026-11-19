/// Marshrut chizig'idagi bitta nuqta.
class RoutePoint {
  const RoutePoint({required this.latitude, required this.longitude});

  /// Kenglik.
  final double latitude;

  /// Uzunlik.
  final double longitude;
}

/// Mapbox Directions API qaytargan marshrut (polyline).
class DirectionsRoute {
  const DirectionsRoute({
    required this.points,
    required this.distance,
    required this.duration,
  });

  /// Chiziq nuqtalari (borish tartibida).
  final List<RoutePoint> points;

  /// Umumiy masofa, metrda.
  final double distance;

  /// Taxminiy vaqt, sekundda.
  final double duration;
}
