import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'firebase_options.dart';
import 'src/app.dart';
import 'src/core/cache/cache_lifecycle.dart';
import 'src/core/cache/cache_maintenance.dart';
import 'src/features/settings/repository/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await Hive.initFlutter();
  await Hive.openBox<String>('liked_hadiths_v1');
  final settings = await Hive.openBox<String>('app_settings_v1');
  final prayers = await Hive.openBox<String>('prayer_calendars_v1');
  try {
    await CacheMaintenance.pruneAll();
  } catch (error) {
    debugPrint('Initial cache cleanup failed: $error');
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  const token = String.fromEnvironment('ACCESS_TOKEN');
  MapboxOptions.setAccessToken(token);
  runApp(
    CacheLifecycle(
      child: MosqueApp(
        settingsRepository: SettingsRepository(settings),
        prayerBox: prayers,
      ),
    ),
  );
}
