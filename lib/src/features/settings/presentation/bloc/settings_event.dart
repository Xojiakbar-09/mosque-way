part of 'settings_bloc.dart';

sealed class SettingsEvent {
  const SettingsEvent();
}

final class SettingsUpdateRequested extends SettingsEvent {
  SettingsUpdateRequested(this.settings);
  final AppSettings settings;
  final Completer<void> completion = Completer<void>();
  Future<void> get done => completion.future;
}

final class SettingsMadhhabSelected extends SettingsEvent {
  const SettingsMadhhabSelected(this.madhhab);
  final Madhhab madhhab;
}

final class SettingsCachesClearRequested extends SettingsEvent {
  const SettingsCachesClearRequested();
}
