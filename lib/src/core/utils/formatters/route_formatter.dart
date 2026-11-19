/// Masofani metr yoki kilometrda beradi.
String formatRouteDistance(double meters) => meters < 1000
    ? '${meters.round()} m'
    : '${(meters / 1000).toStringAsFixed(1)} km';

/// Vaqtni daqiqa yoki soatda beradi.
String formatRouteDuration(double seconds) {
  final minutes = (seconds / 60).ceil().clamp(1, 1000000);
  return minutes < 60
      ? '$minutes daq'
      : '${minutes ~/ 60} soat ${minutes % 60} daq';
}
