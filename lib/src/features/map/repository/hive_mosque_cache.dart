import 'dart:convert';

import 'package:hive_ce/hive.dart';

import '../../../core/cache/cache_maintenance.dart';
import '../../../core/cache/cache_policy.dart';
import 'mosque_catalog.dart';
import 'mosque_cache.dart';

/// Stores primitive JSON strings, so no adapters or build_runner are needed.
class HiveMosqueCache implements MosqueCache {
  static Future<Box<String>>? _opening;
  static Future<Box<String>> _open() async {
    final pending = _opening ??= _initialize();
    try {
      final box = await pending;
      if (!box.isOpen) {
        if (identical(_opening, pending)) _opening = null;
        return await _open();
      }
      return box;
    } catch (_) {
      if (identical(_opening, pending)) _opening = null;
      rethrow;
    }
  }

  static Future<Box<String>> _initialize() async {
    return Hive.openBox<String>('mosque_regions_v1');
  }

  MosqueCatalog? _decode(String? raw) {
    if (raw == null) return null;
    try {
      final catalog = MosqueCatalog.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      return CachePolicy.isFresh(catalog.savedAt) ? catalog : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<MosqueCatalog>> readAll() async {
    final box = await _open();
    await CacheMaintenance.pruneBox(box, regional: true);
    return [
      for (final key in box.keys)
        if (key is String && key.startsWith('region:')) ?_decode(box.get(key)),
    ];
  }

  @override
  Future<MosqueCatalog?> readLast() async {
    final box = await _open();
    await CacheMaintenance.pruneBox(box, regional: true);
    final key = box.get('last_region');
    return key == null ? null : _decode(box.get('region:$key'));
  }

  @override
  Future<void> markLast(String key) async =>
      (await _open()).put('last_region', key);
  @override
  Future<void> save(MosqueCatalog catalog) async {
    final box = await _open();
    await CacheMaintenance.pruneBox(box, regional: true);
    // One atomic entry holds data + region + date + boundary.
    await box.put('region:${catalog.region.key}', jsonEncode(catalog.toJson()));
    await box.put('last_region', catalog.region.key);
  }
}
