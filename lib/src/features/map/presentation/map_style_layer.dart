import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import 'map_light_preset.dart';

/// Xarita fon (basemap) uslubini boshqaradi.
///
/// Faqat ko'rsatish bilan shug'ullanadi — hech qanday ma'lumot olmaydi.
class MapStyleLayer {
  /// Standard style'dagi basemap import nomi.
  static const String _basemapImportId = 'basemap';

  /// Yorug'lik rejimi sozlamasining nomi.
  static const String _lightPresetConfig = 'lightPreset';

  /// Tanlangan yorug'lik rejimini qo'llaydi.
  Future<void> applyLightPreset(mb.MapboxMap map, MapLightPreset preset) async {
    await map.setStyleImportConfigProperty(
      _basemapImportId,
      _lightPresetConfig,
      preset.value,
    );
  }
}
