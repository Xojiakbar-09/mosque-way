import 'dart:async';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:true_compass/true_compass.dart';

import '../../../core/utils/service/location_service.dart';

/// One compass sample delivered to the bloc.
class QiblaReading {
  const QiblaReading({
    required this.heading,
    this.calibrate = false,
    this.approximate = false,
  });

  /// True-north heading in degrees, normalized to `[0, 360)`.
  final double heading;

  /// Whether the magnetometer needs calibration.
  final bool calibrate;

  /// `true` when the heading comes from the GPS course instead of a real
  /// compass sensor, so it only reflects the direction of travel while moving.
  final bool approximate;
}

/// Provides the user's location and a stream of true-north compass headings.
///
/// Uses `true_compass` which fuses the rotation vector (or accelerometer +
/// magnetometer fallback), corrects the screen rotation, applies the WMM2025
/// magnetic declination and smooths the output. Unlike `flutter_compass` it
/// does not freeze when the rotation vector sensor is present but silent.
class QiblaRepository {
  QiblaRepository({CompassOptions? options})
    : _options = options ?? const CompassOptions();

  final CompassOptions _options;
  TrueCompass? _compass;

  TrueCompass get _ensureCompass => _compass ??= TrueCompass(options: _options);

  Future<Position> currentPosition() async {
    final permission = await const LocationService().checkPermission();
    if (permission == LocationPermissionStatus.serviceDisabled) {
      throw const QiblaLocationException('qiblaLocationError');
    }
    if (permission != LocationPermissionStatus.granted) {
      throw const QiblaLocationException('permissionError');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  /// True-north compass headings. The native sensor starts on the first
  /// listener and stops when the last one cancels, so pause/resume works
  /// automatically.
  Stream<QiblaReading> headings(Position position) {
    final compass = _ensureCompass;
    compass.setLocation(
      CompassLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        altitudeMeters: position.altitude.isFinite ? position.altitude : 0,
      ),
    );
    return compass.headings
        .map(
          (sample) => QiblaReading(
            heading: sample.bestHeading,
            calibrate: sample.needsCalibration,
          ),
        )
        .handleError(_mapSensorError);
  }

  /// Whether this device has a usable compass (magnetometer / rotation vector).
  Future<bool> hasCompassSensor() async {
    try {
      return await _ensureCompass.checkAvailability() ==
          CompassAvailability.available;
    } catch (_) {
      // A missing platform implementation also means "no live sensor".
      return false;
    }
  }

  /// Fallback for devices without a compass: the GPS course over ground.
  ///
  /// Course is only meaningful while the user is moving, so stationary fixes
  /// are dropped and every sample is marked [QiblaReading.approximate].
  Stream<QiblaReading> gpsHeadings() =>
      Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 1,
            ),
          )
          .where(
            (position) => position.speed > 0.7 && position.heading.isFinite,
          )
          .map(
            (position) =>
                QiblaReading(heading: position.heading, approximate: true),
          );

  static Never _mapSensorError(Object error) {
    final unsupported = error is PlatformException && error.code == 'no_sensor';
    throw QiblaSensorException(unsupported: unsupported);
  }

  Future<void> dispose() async {
    await _compass?.dispose();
    _compass = null;
  }
}

class QiblaSensorException implements Exception {
  const QiblaSensorException({this.unsupported = false});
  final bool unsupported;
}

class QiblaLocationException implements Exception {
  const QiblaLocationException([this.message = 'permissionError']);
  final String message;
}
