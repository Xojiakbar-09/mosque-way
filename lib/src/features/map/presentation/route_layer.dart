import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import 'package:maps/src/core/consts/app_colors.dart';

import '../repository/directions_route.dart';

/// Marshrutni xaritaga chiziq (polyline) sifatida chizadi.
///
/// Faqat ko'rsatish bilan shug'ullanadi — marshrutni qayerdan olish
/// [DirectionsRepository] zimmasida.
class RouteLayer {
  RouteLayer({
    this.color = AppColors.primary,
    this.width = 9,
    this.borderColor = Colors.white,
  });

  /// Chiziq rangi.
  final Color color;

  /// Chiziq qalinligi.
  final double width;

  /// Chiziq atrofidagi hoshiya rangi.
  final Color borderColor;

  mb.PolylineAnnotationManager? _manager;
  Future<void> _pending = Future<void>.value();

  // Native chizish/tozalash amallari tartibini saqlaydi.
  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _pending.then((_) => operation());
    _pending = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  /// Marshrutni xaritada ko'rsatadi.
  Future<void> show(mb.MapboxMap map, DirectionsRoute route) =>
      _enqueue(() async {
        if (route.points.length < 2) return;

        final manager = _manager ??= await map.annotations
            .createPolylineAnnotationManager();

        await manager.deleteAll();
        await manager.create(
          mb.PolylineAnnotationOptions(
            geometry: mb.LineString(
              coordinates: [
                for (final point in route.points)
                  mb.Position(point.longitude, point.latitude),
              ],
            ),
            lineColor: color.toARGB32(),
            lineWidth: width,
            lineBorderColor: borderColor.toARGB32(),
            lineBorderWidth: width * 0.35,
            lineJoin: mb.LineJoin.ROUND,
          ),
        );
      });

  /// Chizilgan marshrutni o'chiradi.
  Future<void> clear() => _enqueue(() async {
    await _manager?.deleteAll();
  });
}
