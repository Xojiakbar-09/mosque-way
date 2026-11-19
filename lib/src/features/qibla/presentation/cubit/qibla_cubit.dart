import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../repository/qibla_math.dart';
import '../../repository/qibla_repository.dart';

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

class QiblaCubit extends Cubit<QiblaState> {
  QiblaCubit({
    QiblaRepository? repository,
    this.sensorTimeout = const Duration(seconds: 6),
    this.recoveryDelay = const Duration(seconds: 1),
  }) : repository = repository ?? QiblaRepository(),
       super(const QiblaState());

  final QiblaRepository repository;
  final Duration sensorTimeout, recoveryDelay;
  StreamSubscription<QiblaReading>? _subscription;
  Timer? _watchdog, _retry;
  Future<void> _operations = Future<void>.value();
  int _generation = 0, _recoveries = 0;
  bool _closing = false;

  bool _active(int generation) =>
      !isClosed && !_closing && generation == _generation;

  // Native EventChannel cancellation must finish before the next subscription.
  // Generation checks alone do not protect the global platform sensor listener.
  Future<void> _enqueue(Future<void> Function() action) {
    final next = _operations.then((_) => action());
    _operations = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {
        debugPrint('Qibla operation: $error\n$stack');
      },
    );
    return next;
  }

  void _cancelTimers() {
    _watchdog?.cancel();
    _watchdog = null;
    _retry?.cancel();
    _retry = null;
  }

  Future<void> _stopSensor() async {
    _watchdog?.cancel();
    _watchdog = null;
    final subscription = _subscription;
    _subscription = null;
    try {
      await subscription?.cancel();
    } catch (error) {
      debugPrint('Qibla sensor cleanup: $error');
    }
  }

  Future<void> start() {
    if (_closing || isClosed) return Future<void>.value();
    final generation = ++_generation;
    _recoveries = 0;
    _cancelTimers();
    emit(const QiblaState(loading: true));
    return _enqueue(() async {
      await _stopSensor();
      if (!_active(generation)) return;
      try {
        final position = await repository.currentPosition();
        if (!_active(generation)) return;
        final bearing = QiblaMath.bearing(
          position.latitude,
          position.longitude,
        );
        final hasCompass = await repository.hasCompassSensor();
        if (!_active(generation)) return;
        if (hasCompass) {
          _openSensor(position, bearing, generation);
        } else {
          _openFallback(bearing, generation);
        }
      } catch (error, stack) {
        debugPrint('Qibla location: $error\n$stack');
        if (_active(generation)) {
          emit(
            QiblaState(
              message: error is QiblaLocationException
                  ? error.message
                  : 'qiblaLocationError',
            ),
          );
        }
      }
    });
  }

  void _openSensor(Position position, double bearing, int generation) {
    if (!_active(generation)) return;
    emit(QiblaState(loading: true, bearing: bearing));
    void armWatchdog() {
      _watchdog?.cancel();
      _watchdog = Timer(
        sensorTimeout,
        () => _sensorFailed(
          position,
          bearing,
          generation,
          const QiblaSensorException(),
        ),
      );
    }

    armWatchdog();
    try {
      _subscription = repository
          .headings(position)
          .listen(
            (sample) {
              if (!_active(generation) || !sample.heading.isFinite) return;
              armWatchdog();
              _emitReading(
                bearing,
                QiblaMath.normalize(sample.heading),
                calibrate: sample.calibrate,
              );
            },
            onError: (Object error, StackTrace stack) {
              debugPrint('Qibla sensor: $error\n$stack');
              _sensorFailed(position, bearing, generation, error);
            },
            onDone: () {
              _sensorFailed(
                position,
                bearing,
                generation,
                const QiblaSensorException(),
              );
            },
          );
    } catch (error, stack) {
      debugPrint('Qibla sensor setup: $error\n$stack');
      _sensorFailed(position, bearing, generation, error);
    }
  }

  /// Device has no compass sensor: fall back to the GPS course while moving.
  ///
  /// There is no watchdog or retry here — a missing sensor cannot recover, so
  /// the informational message stays visible and samples are simply ignored
  /// until the user moves.
  void _openFallback(double bearing, int generation) {
    if (!_active(generation)) return;
    emit(QiblaState(bearing: bearing, message: 'compassUnsupported'));
    try {
      _subscription = repository.gpsHeadings().listen(
        (sample) {
          if (!_active(generation) || !sample.heading.isFinite) return;
          _emitReading(
            bearing,
            QiblaMath.normalize(sample.heading),
            approximate: true,
            message: 'compassUnsupported',
          );
        },
        onError: (Object error, StackTrace stack) {
          debugPrint('Qibla GPS fallback: $error\n$stack');
        },
      );
    } catch (error, stack) {
      debugPrint('Qibla GPS fallback setup: $error\n$stack');
    }
  }

  /// Emits a reading, rotating the needle/dial along the shortest arc so the
  /// pointer never makes a full turn when crossing north.
  void _emitReading(
    double bearing,
    double heading, {
    bool calibrate = false,
    bool approximate = false,
    String? message,
  }) {
    final relative = QiblaMath.delta(heading, bearing);
    emit(
      QiblaState(
        bearing: bearing,
        heading: heading,
        needleDegrees: state.heading == null
            ? relative
            : state.needleDegrees +
                  QiblaMath.delta(state.needleDegrees, relative),
        dialDegrees: state.heading == null
            ? -heading
            : state.dialDegrees - QiblaMath.delta(state.heading!, heading),
        calibrate: calibrate,
        approximate: approximate,
        message: message,
      ),
    );
  }

  void _sensorFailed(
    Position position,
    double bearing,
    int generation,
    Object error,
  ) {
    if (!_active(generation)) return;
    final nextGeneration = ++_generation;
    _cancelTimers();
    final unsupported = error is QiblaSensorException && error.unsupported;
    // Remove the stale arrow immediately, rather than leaving a frozen reading.
    emit(
      QiblaState(
        bearing: bearing,
        message: unsupported ? 'compassUnsupported' : 'compassUnavailable',
      ),
    );
    final reconnect = !unsupported && _recoveries < 2;
    if (reconnect) _recoveries++;
    unawaited(
      _enqueue(() async {
        await _stopSensor();
        if (!_active(nextGeneration) || !reconnect) return;
        _retry = Timer(recoveryDelay, () {
          unawaited(
            _enqueue(() async {
              if (_active(nextGeneration)) {
                _openSensor(position, bearing, nextGeneration);
              }
            }),
          );
        });
      }),
    );
  }

  Future<void> pause() {
    if (_closing || isClosed) return Future<void>.value();
    ++_generation;
    _cancelTimers();
    emit(QiblaState(bearing: state.bearing, loading: true));
    return _enqueue(_stopSensor);
  }

  @override
  Future<void> close() async {
    if (_closing) return;
    _closing = true;
    ++_generation;
    _cancelTimers();
    await _enqueue(_stopSensor);
    await repository.dispose();
    await super.close();
  }
}
