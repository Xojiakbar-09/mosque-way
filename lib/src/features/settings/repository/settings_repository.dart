import '../../../core/localization/device_language_store.dart';
import 'dart:convert';

import 'package:hive_ce/hive.dart';

import 'app_settings.dart';

class SettingsRepository {
  SettingsRepository(this.box);
  final Box<String> box;
  String get deviceLanguage => DeviceLanguageStore(box).language;

  AppSettings read(String uid) {
    try {
      return AppSettings.fromJson(
        jsonDecode(box.get(uid) ?? '{}') as Map<String, dynamic>,
      ).copyWith(language: deviceLanguage);
    } catch (_) {
      return AppSettings(language: deviceLanguage);
    }
  }

  Future<void> save(String uid, AppSettings settings) async {
    await box.put(uid, jsonEncode(settings.toJson()));
    await DeviceLanguageStore(box).save(settings.language);
  }
}
