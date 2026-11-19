import 'dart:convert';
import 'dart:async';
import 'package:hive_ce/hive.dart';
import 'cache_policy.dart';

/// Deletes only downloaded calendars and regional catalogs. Auth/preferences
/// live in another box and are never touched by cache maintenance.
class CacheMaintenance {
  static final _cleared = StreamController<void>.broadcast();
  static Stream<void> get cleared => _cleared.stream;
  static int epoch = 0;
  static Future<void> clearDownloadedData() async {
    ++epoch;
    final prayers = await Hive.openBox<String>('prayer_calendars_v1');
    final mosques = await Hive.openBox<String>('mosque_regions_v1');
    await prayers.clear();
    await mosques.clear();
    _cleared.add(null);
  }

  static Future<void> pruneBox(
    Box<String> box, {
    bool regional = false,
    DateTime? now,
  }) async {
    final expired = <dynamic, String>{};
    for (final key in box.keys.toList()) {
      if (regional && (key is! String || !key.startsWith('region:'))) continue;
      final raw = box.get(key);
      if (raw == null) continue;
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        if (CachePolicy.isFresh(
          DateTime.parse(data['savedAt'] as String),
          now: now,
        )) {
          continue;
        }
      } catch (_) {
        /* Malformed cache data is also disposable. */
      }
      expired[key] = raw;
    }
    for (final entry in expired.entries) {
      // Do not remove a fresh replacement written while pruning was running.
      if (box.get(entry.key) == entry.value) await box.delete(entry.key);
    }
    if (regional) {
      final last = box.get('last_region');
      if (last != null && !box.containsKey('region:$last')) {
        await box.delete('last_region');
      }
    }
  }

  static Future<void> pruneAll() async {
    final prayers = await Hive.openBox<String>('prayer_calendars_v1');
    final mosques = await Hive.openBox<String>('mosque_regions_v1');
    await pruneBox(prayers);
    await pruneBox(mosques, regional: true);
  }
}
