import 'package:flutter/material.dart';

import '../../map/presentation/map_light_preset.dart';
import '../../map/repository/directions_profile.dart';

import 'madhhab.dart';

export 'madhhab.dart';

/// Personal choices are persisted per Firebase UID, never in the prayer cache.
class AppSettings {
  const AppSettings({
    this.madhhab,
    this.language = 'uz',
    this.themeMode = ThemeMode.system,
    this.mapPreset = MapLightPreset.day,
    this.map3D = false,
    this.routeProfile = DirectionsProfile.driving,
    this.calculationMethod,
  });
  final Madhhab? madhhab;
  final String language;
  final ThemeMode themeMode;
  final MapLightPreset mapPreset;
  final bool map3D;
  final DirectionsProfile routeProfile;
  final int? calculationMethod;

  AppSettings copyWith({
    Madhhab? madhhab,
    String? language,
    ThemeMode? themeMode,
    MapLightPreset? mapPreset,
    bool? map3D,
    DirectionsProfile? routeProfile,
    int? calculationMethod,
    bool automaticMethod = false,
  }) => AppSettings(
    madhhab: madhhab ?? this.madhhab,
    language: language ?? this.language,
    themeMode: themeMode ?? this.themeMode,
    mapPreset: mapPreset ?? this.mapPreset,
    map3D: map3D ?? this.map3D,
    routeProfile: routeProfile ?? this.routeProfile,
    calculationMethod: automaticMethod
        ? null
        : calculationMethod ?? this.calculationMethod,
  );
  Map<String, dynamic> toJson() => {
    'madhhab': madhhab?.name,
    'language': language,
    'theme': themeMode.name,
    'mapPreset': mapPreset.name,
    'map3D': map3D,
    'routeProfile': routeProfile.name,
    'method': calculationMethod,
  };
  factory AppSettings.fromJson(Map<String, dynamic> data) {
    T value<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.where((e) => e.name == name).firstOrNull ?? fallback;
    return AppSettings(
      madhhab: Madhhab.values
          .where((e) => e.name == data['madhhab'])
          .firstOrNull,
      language: ['uz', 'ru', 'en'].contains(data['language'])
          ? data['language'] as String
          : 'uz',
      themeMode: value(ThemeMode.values, data['theme'], ThemeMode.system),
      mapPreset: value(
        MapLightPreset.values,
        data['mapPreset'],
        MapLightPreset.day,
      ),
      map3D: data['map3D'] == true,
      routeProfile: value(
        DirectionsProfile.values,
        data['routeProfile'],
        DirectionsProfile.driving,
      ),
      calculationMethod:
          [
            1,
            2,
            3,
            4,
            5,
            7,
            9,
            10,
            11,
            13,
            14,
            16,
            17,
            20,
          ].contains(data['method'])
          ? data['method'] as int
          : null,
    );
  }
}
