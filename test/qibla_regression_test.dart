import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:true_compass/true_compass.dart';

import 'package:maps/src/features/qibla/presentation/bloc/qibla_bloc.dart';
import 'package:maps/src/features/qibla/presentation/widgets/compass_dial.dart';
import 'package:maps/src/features/qibla/repository/qibla_math.dart';
import 'package:maps/src/features/qibla/repository/qibla_repository.dart';

/// Scriptable `true_compass` platform for tests.
class _FakeTrueCompassPlatform extends TrueCompassPlatform
    with MockPlatformInterfaceMixin {
  final List<StreamController<Map<String, Object?>>> controllers = [];
  int listens = 0;
  int cancels = 0;

  void send(Map<String, Object?> event) {
    for (final c in controllers) {
      if (!c.isClosed) c.add(event);
    }
  }

  /// Flat device whose top edge points at [magneticHeading] degrees.
  void sendFlat(double magneticHeading, {int rotation = 0}) {
    final matrix = OrientationMath.rotationMatrixFromEuler(
      -magneticHeading,
      0,
      0,
    );
    send({'kind': 'matrix', 'matrix': matrix, 'screenRotation': rotation});
  }

  @override
  Future<CompassAvailability> checkAvailability() async =>
      CompassAvailability.available;

  @override
  Stream<Map<String, Object?>> rawEvents(RawSensorConfig config) {
    listens++;
    final controller = StreamController<Map<String, Object?>>(
      onCancel: () => cancels++,
    );
    controllers.add(controller);
    return controller.stream;
  }
}

final position = Position(
  latitude: 41.2995,
  longitude: 69.2401,
  timestamp: DateTime(2026),
  accuracy: 5,
  altitude: 450,
  altitudeAccuracy: 5,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

/// Repository that always returns a fixed position; uses the real
/// `TrueCompass` sensor pipeline through the injected platform.
class _FixedLocationRepository extends QiblaRepository {
  _FixedLocationRepository()
    : super(
        options: const CompassOptions(
          updateInterval: Duration.zero,
          smoothing: CompassSmoothing.none(),
        ),
      );

  @override
  Future<Position> currentPosition() async => position;
}

class FakeQiblaRepository extends QiblaRepository {
  final channels = <StreamController<QiblaReading>>[];
  Future<void>? cancelBarrier;
  Completer<Position>? pendingLocation;
  Object? locationError;
  int locationCalls = 0, active = 0, maximumActive = 0;
  bool compassAvailable = true;

  @override
  Future<bool> hasCompassSensor() async => compassAvailable;

  @override
  Future<Position> currentPosition() async {
    locationCalls++;
    if (locationError != null) throw locationError!;
    return pendingLocation == null ? position : await pendingLocation!.future;
  }

  @override
  Stream<QiblaReading> headings(Position position) {
    late final StreamController<QiblaReading> channel;
    channel = StreamController<QiblaReading>(
      onListen: () {
        active++;
        if (active > maximumActive) maximumActive = active;
      },
      onCancel: () async {
        await cancelBarrier;
        active--;
      },
    );
    channels.add(channel);
    return channel.stream;
  }

  @override
  Stream<QiblaReading> gpsHeadings() => headings(position);

  void sample(double heading, {bool calibrate = false}) =>
      channels.last.add(QiblaReading(heading: heading, calibrate: calibrate));
}

Future<void> drain(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

Future<void> closeBloc(WidgetTester tester, QiblaBloc bloc) async {
  final closing = bloc.close();
  await drain(tester);
  await closing;
}

void main() {
  test('native sensor samples flow through repository and bloc', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final fake = _FakeTrueCompassPlatform();
    final original = TrueCompassPlatform.instance;
    addTearDown(() => TrueCompassPlatform.instance = original);
    TrueCompassPlatform.instance = fake;

    final repository = _FixedLocationRepository();
    final bloc = QiblaBloc(repository: repository);
    bloc.add(const QiblaStarted());
    await Future<void>.delayed(Duration.zero);

    final declination = MagneticDeclination.at(
      latitude: position.latitude,
      longitude: position.longitude,
      altitudeMeters: position.altitude,
    );

    fake.sendFlat(10);
    await Future<void>.delayed(Duration.zero);
    expect(
      bloc.state.heading,
      closeTo(QiblaMath.normalize(10 + declination), .001),
    );

    final needle = bloc.state.needleDegrees;
    fake.sendFlat(80);
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.needleDegrees - needle, closeTo(-70, .001));

    await bloc.close();
    expect(fake.cancels, greaterThanOrEqualTo(1));
  });
  testWidgets('each sensor reading updates heading and arrow', (tester) async {
    final repo = FakeQiblaRepository();
    final bloc = QiblaBloc(repository: repo);
    bloc.add(const QiblaStarted());
    await drain(tester);
    repo.sample(10);
    await drain(tester);
    final first = bloc.state.needleDegrees;
    repo.sample(100);
    await drain(tester);
    expect(bloc.state.heading, 100);
    expect(bloc.state.needleDegrees - first, closeTo(-90, 0.001));
    expect(bloc.state.dialDegrees, -100);
    expect(bloc.state.bearing, closeTo(240, 2));
    await closeBloc(tester, bloc);
  });
  testWidgets('crossing north follows two degrees instead of a full turn', (
    tester,
  ) async {
    final repo = FakeQiblaRepository();
    final bloc = QiblaBloc(repository: repo);
    bloc.add(const QiblaStarted());
    await drain(tester);
    repo.sample(359);
    await drain(tester);
    final needle = bloc.state.needleDegrees, dial = bloc.state.dialDegrees;
    repo.sample(1);
    await drain(tester);
    expect(bloc.state.dialDegrees - dial, closeTo(-2, .001));
    expect(bloc.state.needleDegrees - needle, closeTo(-2, .001));
    await closeBloc(tester, bloc);
  });
  testWidgets('calibration status does not stop the moving arrow', (
    tester,
  ) async {
    final repo = FakeQiblaRepository();
    final bloc = QiblaBloc(repository: repo);
    bloc.add(const QiblaStarted());
    await drain(tester);
    repo.sample(20, calibrate: true);
    await drain(tester);
    repo.sample(80, calibrate: true);
    await drain(tester);
    expect(bloc.state.heading, 80);
    expect(bloc.state.calibrate, true);
    expect(bloc.state.aligned, false);
    await closeBloc(tester, bloc);
  });
  testWidgets(
    'missing events clear stale heading then automatically reconnect',
    (tester) async {
      final repo = FakeQiblaRepository();
      final bloc = QiblaBloc(repository: repo);
      bloc.add(const QiblaStarted());
      await drain(tester);
      repo.sample(30);
      await drain(tester);
      await tester.pump(const Duration(seconds: 6));
      await drain(tester);
      expect(bloc.state.heading, isNull);
      expect(bloc.state.message, 'compassUnavailable');
      await tester.pump(const Duration(seconds: 1));
      await drain(tester);
      expect(repo.channels.length, 2);
      expect(repo.locationCalls, 1);
      repo.sample(80);
      await drain(tester);
      expect(bloc.state.heading, 80);
      expect(bloc.state.message, isNull);
      expect(repo.maximumActive, 1);
      await closeBloc(tester, bloc);
    },
  );
  testWidgets('NaN readings cannot keep a dead sensor alive', (tester) async {
    final repo = FakeQiblaRepository();
    final bloc = QiblaBloc(repository: repo);
    bloc.add(const QiblaStarted());
    await drain(tester);
    repo.sample(double.nan);
    await drain(tester);
    await tester.pump(const Duration(seconds: 6));
    await drain(tester);
    expect(bloc.state.message, 'compassUnavailable');
    await closeBloc(tester, bloc);
  });
  testWidgets('unsupported sensor stops instead of endlessly restarting', (
    tester,
  ) async {
    final repo = FakeQiblaRepository();
    final bloc = QiblaBloc(repository: repo);
    bloc.add(const QiblaStarted());
    await drain(tester);
    repo.channels.last.addError(const QiblaSensorException(unsupported: true));
    await drain(tester);
    await tester.pump(const Duration(seconds: 30));
    expect(bloc.state.message, 'compassUnsupported');
    expect(repo.channels.length, 1);
    expect(repo.active, 0);
    await closeBloc(tester, bloc);
  });
  testWidgets('device without a compass uses the GPS course fallback', (
    tester,
  ) async {
    final repo = FakeQiblaRepository()..compassAvailable = false;
    final bloc = QiblaBloc(repository: repo);
    bloc.add(const QiblaStarted());
    await drain(tester);
    await drain(tester);
    expect(bloc.state.message, 'compassUnsupported');
    expect(bloc.state.heading, isNull);
    repo.sample(100);
    await drain(tester);
    expect(bloc.state.heading, 100);
    expect(bloc.state.approximate, true);
    expect(bloc.state.message, 'compassUnsupported');
    expect(bloc.state.aligned, false);
    // A missing sensor is permanent: no watchdog retry should restart it.
    await tester.pump(const Duration(seconds: 30));
    await drain(tester);
    expect(repo.channels.length, 1);
    await closeBloc(tester, bloc);
  });
  testWidgets('recovery attempts have a fixed limit', (tester) async {
    final repo = FakeQiblaRepository();
    final bloc = QiblaBloc(repository: repo);
    bloc.add(const QiblaStarted());
    await drain(tester);
    for (var i = 0; i < 3; i++) {
      repo.channels.last.addError(StateError('temporary sensor failure'));
      await drain(tester);
      await tester.pump(const Duration(seconds: 1));
      await drain(tester);
    }
    expect(repo.channels.length, 3);
    expect(repo.active, 0);
    expect(bloc.state.heading, isNull);
    await closeBloc(tester, bloc);
  });
  testWidgets('pause cancels pending automatic recovery', (tester) async {
    final repo = FakeQiblaRepository();
    final bloc = QiblaBloc(repository: repo);
    bloc.add(const QiblaStarted());
    await drain(tester);
    repo.channels.last.addError(StateError('failed'));
    await drain(tester);
    bloc.add(const QiblaPaused());
    await drain(tester);
    await tester.pump(const Duration(seconds: 10));
    await drain(tester);
    expect(repo.channels.length, 1);
    expect(repo.active, 0);
    await closeBloc(tester, bloc);
  });
  testWidgets('native cancellation completes before a new subscription', (
    tester,
  ) async {
    final repo = FakeQiblaRepository();
    final bloc = QiblaBloc(repository: repo);
    bloc.add(const QiblaStarted());
    await drain(tester);
    final barrier = Completer<void>();
    repo.cancelBarrier = barrier.future;
    bloc.add(const QiblaPaused());
    bloc.add(const QiblaStarted());
    await drain(tester);
    expect(repo.channels.length, 1);
    barrier.complete();
    await drain(tester);
    expect(repo.channels.length, 2);
    expect(repo.maximumActive, 1);
    await closeBloc(tester, bloc);
  });
  testWidgets('resume during pending GPS does not create two sensor sessions', (
    tester,
  ) async {
    final repo = FakeQiblaRepository()..pendingLocation = Completer<Position>();
    final bloc = QiblaBloc(repository: repo);
    bloc.add(const QiblaStarted());
    await drain(tester);
    bloc.add(const QiblaPaused());
    bloc.add(const QiblaStarted());
    await drain(tester);
    repo.pendingLocation!.complete(position);
    await drain(tester);
    expect(repo.channels.length, 1);
    expect(repo.maximumActive, 1);
    await closeBloc(tester, bloc);
  });
  testWidgets('closing during recovery leaves no sensor or timer running', (
    tester,
  ) async {
    final repo = FakeQiblaRepository();
    final bloc = QiblaBloc(repository: repo);
    bloc.add(const QiblaStarted());
    await drain(tester);
    repo.channels.last.addError(StateError('failed'));
    await drain(tester);
    await closeBloc(tester, bloc);
    await tester.pump(const Duration(seconds: 30));
    expect(repo.channels.length, 1);
    expect(repo.active, 0);
  });
  testWidgets('permission failure and GPS failure have different messages', (
    tester,
  ) async {
    final repo = FakeQiblaRepository()
      ..locationError = const QiblaLocationException();
    final bloc = QiblaBloc(repository: repo);
    bloc.add(const QiblaStarted());
    await drain(tester);
    expect(bloc.state.message, 'permissionError');
    repo.locationError = TimeoutException('GPS timeout');
    bloc.add(const QiblaStarted());
    await drain(tester);
    expect(bloc.state.message, 'qiblaLocationError');
    await closeBloc(tester, bloc);
  });
  testWidgets('dial and arrow both animate to the latest sample', (
    tester,
  ) async {
    Future<void> show(QiblaState state) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CompassDial(state: state)),
      ),
    );
    await show(
      const QiblaState(
        bearing: 240,
        heading: 359,
        dialDegrees: -359,
        needleDegrees: -119,
      ),
    );
    await show(
      const QiblaState(
        bearing: 240,
        heading: 1,
        dialDegrees: -361,
        needleDegrees: -121,
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final rotations = tester
        .widgetList<AnimatedRotation>(find.byType(AnimatedRotation))
        .toList();
    expect(rotations.length, 2);
    expect(rotations[0].turns, closeTo(-361 / 360, .00001));
    expect(rotations[1].turns, closeTo(-121 / 360, .00001));
    expect(tester.takeException(), isNull);
  });
  test('Qibla bearing stays constant when only the phone rotates', () {
    final bearing = QiblaMath.bearing(41.2995, 69.2401);
    expect(bearing, closeTo(240, 2));
    expect(QiblaMath.delta(10, bearing), isNot(QiblaMath.delta(100, bearing)));
  });
}
