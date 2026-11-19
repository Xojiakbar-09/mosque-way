part of 'settings_bloc.dart';

class SettingsState extends AppSettings {
  SettingsState.from(
    AppSettings s, {
    this.saving = false,
    this.errorKey,
    this.selectedMadhhab,
    this.cacheRevision = 0,
  }) : super(
         madhhab: s.madhhab,
         language: s.language,
         themeMode: s.themeMode,
         mapPreset: s.mapPreset,
         map3D: s.map3D,
         routeProfile: s.routeProfile,
         calculationMethod: s.calculationMethod,
       );
  final bool saving;
  final String? errorKey;
  final Madhhab? selectedMadhhab;
  final int cacheRevision;
}
