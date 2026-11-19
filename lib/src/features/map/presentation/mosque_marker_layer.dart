import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import '../repository/mosque.dart';
import 'mosque_marker_payload.dart';

/// Masjidlarni xaritaga rasm ikonka bilan joylashtiradi.
class MosqueMarkerLayer {
  MosqueMarkerLayer({required this.onMosqueTap});

  /// Ikonka asset yo'li.
  static const String iconAsset = 'assets/icon/mosque_marker.png';

  /// Ikonka qanday piksel o'lchamda tayyorlanadi.
  static const double _rasterSize = 96;

  /// Masjidlar zoom darajasidan qat'i nazar doim ko'rsatiladi.
  static const double minVisibleZoom = 0;

  /// Ikonka xaritada taxminan 34px ko'rinadi.
  static const double _iconSize = 0.35;

  /// Marker bosilganda chaqiriladi (bosilgan masjid bilan).
  final void Function(Mosque mosque) onMosqueTap;

  mb.PointAnnotationManager? _manager;
  mb.MapboxMap? _map;
  mb.Cancelable? _tapSubscription;
  List<Mosque> _mosques = const [];
  Mosque? _selectedMosque;
  bool _isVisible = false;
  bool _isUpdating = false;
  bool _requestedVisibility = false;
  int _dataRevision = 0;
  int _renderedRevision = -1;
  bool _disposed = false;
  final Map<String, Mosque> _byKey = {};
  Uint8List? _iconBytes;

  /// Masjidlar ro'yxatini saqlaydi va joriy zoom uchun markerlarni yangilaydi.
  Future<void> setMosques(
    mb.MapboxMap map,
    List<Mosque> mosques, {
    required double zoom,
    Mosque? selectedMosque,
  }) async {
    if (_disposed) return;
    _map = map;
    _mosques = mosques;
    _selectedMosque = selectedMosque;
    ++_dataRevision;
    await updateZoom(zoom);
  }

  /// Reconcile marker visibility and data without overlapping native updates.
  Future<void> updateZoom(double zoom) async {
    if (_disposed) return;

    _requestedVisibility = _mosques.isNotEmpty && zoom >= minVisibleZoom;
    if (_isUpdating) return;

    _isUpdating = true;
    try {
      while (!_disposed &&
          (_isVisible != _requestedVisibility ||
              (_requestedVisibility && _renderedRevision != _dataRevision))) {
        final shouldShow = _requestedVisibility;
        final revision = _dataRevision;
        if (shouldShow) {
          await _showMarkers();
        } else {
          await _manager?.deleteAll();
        }
        _isVisible = shouldShow;
        _renderedRevision = revision;
      }
    } finally {
      _isUpdating = false;
    }
  }

  Future<void> _showMarkers() async {
    if (_disposed || _mosques.isEmpty) return;
    final mosques = List<Mosque>.of(_mosques);

    final map = _map;
    if (map == null) return;

    final image = _iconBytes ??= await _loadIconImage();

    final manager = _manager ??= await map.annotations
        .createPointAnnotationManager();

    if (_disposed) return;

    // Keep mosque pins visible even where Mapbox basemap labels overlap them.
    await manager.setIconAllowOverlap(true);
    await manager.setIconIgnorePlacement(true);

    _tapSubscription?.cancel();
    _tapSubscription = manager.tapEvents(
      onTap: (annotation) {
        final mosque = _byKey[annotation.customData?['mosqueKey']];
        if (mosque != null) onMosqueTap(mosque);
      },
    );

    _byKey
      ..clear()
      ..addEntries(mosques.map((m) => MapEntry(mosqueMarkerKey(m), m)));
    await manager.deleteAll();
    final created = await manager.createMulti([
      for (final mosque in mosques)
        mb.PointAnnotationOptions(
          geometry: mb.Point(
            coordinates: mb.Position(mosque.longitude, mosque.latitude),
          ),
          image: image,
          iconAnchor: mb.IconAnchor.BOTTOM,
          iconSize: _isSelected(mosque) ? 0.55 : _iconSize,
          customData: mosqueMarkerPayload(mosque),
        ),
    ]);
    if (created.whereType<mb.PointAnnotation>().length != mosques.length) {
      throw StateError('Some mosque annotations were not created');
    }
  }

  /// A style reload invalidates native annotation managers and their images.
  void resetStyle() {
    _tapSubscription?.cancel();
    _tapSubscription = null;
    _manager = null;
    _isVisible = false;
    _renderedRevision = -1;
    ++_dataRevision;
  }

  bool _isSelected(Mosque mosque) {
    final selected = _selectedMosque;
    return selected != null &&
        selected.latitude == mosque.latitude &&
        selected.longitude == mosque.longitude;
  }

  /// Resurslarni bo'shatadi.
  void dispose() {
    _disposed = true;
    _tapSubscription?.cancel();
  }

  /// Ikonka asset'ini o'qib, kerakli piksel o'lchamga keltiradi.
  ///
  /// Asset SVG emas, oddiy rasm (JPEG/PNG) bo'lgani uchun `rootBundle`
  /// orqali o'qib, `ui` kodek bilan o'lchamga keltiriladi.
  Future<Uint8List> _loadIconImage() async {
    Uint8List data;
    try {
      data = (await rootBundle.load(iconAsset)).buffer.asUint8List();
    } catch (_) {
      return _fallbackIcon();
    }

    final codec = await ui.instantiateImageCodec(
      data,
      targetWidth: _rasterSize.toInt(),
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    codec.dispose();

    if (byteData == null) return _fallbackIcon();
    return byteData.buffer.asUint8List();
  }

  Future<Uint8List> _fallbackIcon() async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawCircle(
      const ui.Offset(48, 48),
      42,
      ui.Paint()..color = const ui.Color(0xFF157A58),
    );
    canvas.drawCircle(
      const ui.Offset(48, 48),
      34,
      ui.Paint()
        ..color = const ui.Color(0xFFFFFFFF)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(96, 96);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    if (bytes == null) throw StateError('Could not create mosque marker image');
    return bytes.buffer.asUint8List();
  }
}
