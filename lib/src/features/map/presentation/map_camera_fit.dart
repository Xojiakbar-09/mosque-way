import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import '../repository/directions_route.dart';

/// Marshrutni ekranga sig'diruvchi kamera: markaz va zoom.
typedef RouteCameraFit = ({mb.Point center, double zoom});

/// Web Mercator proyeksiyasi bo'yicha marshrutning barcha nuqtalarini
/// ko'rinadigan maydonga sig'diradigan kamera holatini hisoblaydi.
///
/// Nuqtalar bo'lmasa `null` qaytaradi.
RouteCameraFit? fitRouteCamera({
  required List<RoutePoint> points,
  required Size viewSize,
  double horizontalPadding = 130,
  double verticalPadding = 330,
}) {
  if (points.isEmpty) return null;

  final xs = points.map((point) => (point.longitude + 180) / 360);
  final ys = points.map((point) => _mercatorY(point.latitude));
  final minX = xs.reduce(math.min);
  final maxX = xs.reduce(math.max);
  final minY = ys.reduce(math.min);
  final maxY = ys.reduce(math.max);

  final spanX = math.max(maxX - minX, 0.00001);
  final spanY = math.max(maxY - minY, 0.00001);
  final width = math.max(viewSize.width - horizontalPadding, 100.0);
  final height = math.max(viewSize.height - verticalPadding, 100.0);

  final zoom =
      math.min(
        math.log(width / (512 * spanX)),
        math.log(height / (512 * spanY)),
      ) /
      math.ln2;

  final centerY = (minY + maxY) / 2;
  final latitude = _latitudeOf(centerY);

  return (
    center: mb.Point(
      coordinates: mb.Position((minX + maxX) * 180 - 180, latitude),
    ),
    zoom: zoom.clamp(2.0, 17.0).toDouble(),
  );
}

/// Kenglikni Web Mercator Y qiymatiga (0..1) aylantiradi.
double _mercatorY(double latitude) {
  final radians = latitude.clamp(-85.0, 85.0) * math.pi / 180;
  return (1 - math.log(math.tan(math.pi / 4 + radians / 2)) / math.pi) / 2;
}

/// Web Mercator Y qiymatidan kenglikka qaytaradi.
double _latitudeOf(double y) =>
    (2 * math.atan(math.exp(math.pi * (1 - 2 * y))) - math.pi / 2) *
    180 /
    math.pi;
