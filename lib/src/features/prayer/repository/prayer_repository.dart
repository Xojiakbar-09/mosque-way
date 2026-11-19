import 'dart:convert';

import 'package:hive_ce/hive.dart';

import '../../settings/repository/madhhab.dart';
import '../../../core/cache/cache_maintenance.dart';
import '../../../core/cache/cache_policy.dart';
import 'aladhan_service.dart';
import 'prayer_location.dart';
import 'prayer_schedule.dart';

class PrayerLoadResult {
  const PrayerLoadResult(
    this.schedule, {
    this.fromCache = false,
    this.saveFailed = false,
  });
  final PrayerSchedule schedule;
  final bool fromCache, saveFailed;
}

class PrayerRepository {
  PrayerRepository(this.box, {AladhanService? service})
    : service = service ?? AladhanService();
  final Box<String> box;
  final AladhanService service;
  int _epoch = 0;
  bool _disposed = false;
  PrayerSchedule? cached(
    Madhhab madhhab,
    int? method, {
    PrayerLocation? location,
  }) {
    final entries = <PrayerSchedule>[];
    for (final raw in box.values) {
      try {
        final entry = PrayerSchedule.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        if (CachePolicy.isFresh(entry.savedAt) &&
            entry.madhhab == madhhab &&
            entry.requestedMethod == method &&
            (location == null || entry.location.near(location)) &&
            entry.dayAt(DateTime.now()) != null) {
          entries.add(entry);
        }
      } catch (_) {
        /* Ignore malformed entries and older cache schemas. */
      }
    }
    entries.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return entries.firstOrNull;
  }

  Future<PrayerLoadResult> load(
    PrayerLocation location,
    Madhhab madhhab,
    int? method, {
    bool force = false,
  }) async {
    final epoch = _epoch;
    final cacheEpoch = CacheMaintenance.epoch;
    await CacheMaintenance.pruneBox(box);
    final stored = cached(madhhab, method, location: location);
    var needsTomorrow = false;
    if (stored != null) {
      final local = stored.localNow(DateTime.now());
      final tomorrow = DateTime(local.year, local.month, local.day + 1);
      needsTomorrow =
          local.month != tomorrow.month &&
          !stored.days.any((d) => d.date == PrayerSchedule.dateKey(tomorrow));
    }
    if (!force && stored != null && !needsTomorrow) {
      return PrayerLoadResult(stored, fromCache: true);
    }
    final fresh = await service.fetch(location, madhhab, method);
    if (_disposed || epoch != _epoch || cacheEpoch != CacheMaintenance.epoch) {
      throw StateError('Prayer request superseded');
    }
    var saveFailed = false;
    try {
      final key =
          '${location.latitude.toStringAsFixed(3)}:${location.longitude.toStringAsFixed(3)}:${madhhab.name}:$method:${fresh.days.first.date}';
      // Bound storage; the box contains only prayer calendars.
      if (box.length >= 12 && !box.containsKey(key)) {
        await box.delete(box.keys.first);
      }
      if (_disposed ||
          epoch != _epoch ||
          cacheEpoch != CacheMaintenance.epoch) {
        throw StateError('Prayer request superseded');
      }
      await box.put(key, jsonEncode(fresh.toJson()));
    } catch (_) {
      saveFailed = true;
    }
    return PrayerLoadResult(fresh, saveFailed: saveFailed);
  }

  Future<void> clear() async {
    ++_epoch;
    await CacheMaintenance.clearDownloadedData();
  }

  void dispose() {
    _disposed = true;
    ++_epoch;
    service.dispose();
  }
}
