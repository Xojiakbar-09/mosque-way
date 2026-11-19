part of 'qibla_bloc.dart';

sealed class QiblaEvent {
  const QiblaEvent();
}

final class QiblaStarted extends QiblaEvent {
  const QiblaStarted();
}

final class QiblaPaused extends QiblaEvent {
  const QiblaPaused();
}

final class _QiblaStateChanged extends QiblaEvent {
  const _QiblaStateChanged(this.value, this.generation);
  final QiblaState value;
  final int generation;
}

final class _QiblaReadingReceived extends QiblaEvent {
  const _QiblaReadingReceived(
    this.bearing,
    this.heading,
    this.generation, {
    this.calibrate = false,
    this.approximate = false,
    this.message,
  });
  final double bearing, heading;
  final int generation;
  final bool calibrate, approximate;
  final String? message;
}
