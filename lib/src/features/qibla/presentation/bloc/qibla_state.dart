part of 'qibla_bloc.dart';

class QiblaState {
  const QiblaState({
    this.loading = false,
    this.bearing,
    this.heading,
    this.needleDegrees = 0,
    this.dialDegrees = 0,
    this.calibrate = false,
    this.approximate = false,
    this.message,
  });
  final bool loading, calibrate;

  /// `true` when [heading] comes from the GPS course (no compass sensor).
  final bool approximate;
  final double? bearing, heading;
  final double needleDegrees, dialDegrees;
  final String? message;
  bool get aligned =>
      !approximate &&
      bearing != null &&
      heading != null &&
      !calibrate &&
      QiblaMath.delta(heading!, bearing!).abs() <= 5;
}
