import 'package:hive_ce/hive.dart';

class DeviceLanguageStore {
  DeviceLanguageStore(this.box);
  final Box<String> box;
  static const supported = ['uz', 'ru', 'en'];
  String get language {
    final value = box.get('device_language');
    return supported.contains(value) ? value! : 'uz';
  }

  Future<void> save(String language) {
    if (!supported.contains(language)) {
      throw ArgumentError.value(language, 'language');
    }
    return box.put('device_language', language);
  }
}
