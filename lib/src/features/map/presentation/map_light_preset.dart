import 'package:flutter/material.dart';

/// Mapbox Standard style'ining yorug'lik rejimlari.
///
/// `lightPreset` xususiyati orqali xaritaning kun vaqtiga mos
/// ko'rinishi tanlanadi.
enum MapLightPreset {
  /// Kunduzgi.
  day('day', 'Kunduzgi', Icons.wb_sunny_outlined),

  /// Tonggi.
  dawn('dawn', 'Tonggi', Icons.wb_twilight_rounded),

  /// Kechqurun.
  dusk('dusk', 'Kechqurun', Icons.wb_twilight_rounded),

  /// Tungi.
  night('night', 'Tungi', Icons.nightlight_outlined);

  const MapLightPreset(this.value, this.label, this.icon);

  /// Mapbox style konfiguratsiyasidagi qiymat.
  final String value;

  /// Foydalanuvchiga ko'rsatiladigan nomi.
  final String label;

  /// Rejimni bildiruvchi ikonka.
  final IconData icon;
}
