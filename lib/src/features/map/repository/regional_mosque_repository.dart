import '../../../core/cache/cache_policy.dart';
import '../../../core/cache/cache_maintenance.dart';
import 'mosque.dart';
import 'mosque_catalog.dart';
import 'mosque_cache.dart';
import 'mosque_search.dart';
import 'overpass_service.dart';

class RegionalMosqueRepository {
  RegionalMosqueRepository({required this._service, required this._cache});
  final OverpassService _service;
  final MosqueCache _cache;
  MosqueCatalog? _current;
  int _generation = 0;
  bool _disposed = false;
  double? _resolvedLatitude, _resolvedLongitude;
  String? _resolvedRegionKey;
  MosqueCatalog? get currentCatalog {
    if (_current != null && !CachePolicy.isFresh(_current!.savedAt)) {
      _current = null;
    }
    return _current;
  }

  void invalidate() {
    ++_generation;
    _current = null;
    _resolvedLatitude = null;
    _resolvedLongitude = null;
    _resolvedRegionKey = null;
  }

  void dispose() {
    _disposed = true;
    ++_generation;
    _service.dispose();
  }

  Future<MosqueCatalog?> restoreLast() async {
    final generation = _generation;
    try {
      final catalog = await _cache.readLast();
      if (_disposed || generation != _generation || _current != null) {
        return _current;
      }
      if (catalog != null && !CachePolicy.isFresh(catalog.savedAt)) return null;
      return _current = catalog?.cached(
        locationConfirmed: false,
        notice: 'regionRestored',
      );
    } catch (_) {
      return null;
    }
  }

  Future<MosqueCatalog> loadForLocation({
    required double latitude,
    required double longitude,
    bool forceRefresh = false,
    void Function(MosqueCatalog catalog)? onCached,
  }) async {
    final cacheEpoch = CacheMaintenance.epoch;
    final current = currentCatalog;
    // Reuse only a previously confirmed GPS fix (about a few metres), and
    // never extend savedAt: the seven-day expiry still applies.
    if (!forceRefresh &&
        !_disposed &&
        current != null &&
        current.region.key == _resolvedRegionKey &&
        _resolvedLatitude != null &&
        _resolvedLongitude != null &&
        (latitude - _resolvedLatitude!).abs() < 0.00005 &&
        (longitude - _resolvedLongitude!).abs() < 0.00005) {
      return current.cached();
    }
    final generation = ++_generation;
    void publish(MosqueCatalog catalog, {bool cached = false}) {
      if (_disposed || generation != _generation) return;
      _current = catalog;
      if (cached) onCached?.call(catalog);
    }

    var storageWarning = false;
    List<MosqueCatalog> stored;
    try {
      stored = List<MosqueCatalog>.of(await _cache.readAll());
    } catch (_) {
      stored = [];
    }
    if (_disposed || generation != _generation) {
      throw const OverpassException('requestCancelled');
    }
    stored.removeWhere((c) => !CachePolicy.isFresh(c.savedAt));
    if (currentCatalog case final current?) {
      if (!stored.any((c) => c.region.key == current.region.key)) {
        stored.add(current);
      }
    }
    final containing =
        stored
            .where(
              (c) =>
                  c.boundary.isUsable &&
                  c.boundary.contains(latitude, longitude),
            )
            .toList()
          ..sort((a, b) {
            if (a.region.isCity != b.region.isCity) {
              return a.region.isCity ? -1 : 1;
            }
            return b.savedAt.compareTo(a.savedAt);
          });
    final provisional = containing.isEmpty ? null : containing.first;
    if (provisional != null) {
      publish(
        provisional.cached(
          locationConfirmed: provisional.region.isCity,
          notice: provisional.region.isCity ? null : 'regionBoundaryChecking',
        ),
        cached: true,
      );
      if (!forceRefresh &&
          provisional.region.isCity &&
          provisional.mosques.isNotEmpty) {
        final result = provisional.cached();
        publish(result);
        try {
          await _cache.markLast(result.region.key);
        } catch (_) {}
        return result;
      }
    }
    MosqueCatalog? confirmedCache;
    try {
      final region = await _service.resolveRegion(latitude, longitude);
      if (_disposed || generation != _generation) {
        throw const OverpassException('requestCancelled');
      }
      _resolvedLatitude = latitude;
      _resolvedLongitude = longitude;
      _resolvedRegionKey = region.key;
      final matching = stored.where((c) => c.region.key == region.key).toList();
      final existing = matching.isEmpty ? null : matching.first;
      confirmedCache = existing;
      if (!forceRefresh && existing != null && existing.mosques.isNotEmpty) {
        final result = existing.cached();
        publish(result);
        try {
          await _cache.markLast(region.key);
        } catch (_) {}
        return result;
      }
      if (existing != null) publish(existing.cached(), cached: true);
      final fresh = await _service.fetchMosques(region);
      if (_disposed || generation != _generation) {
        throw const OverpassException('requestCancelled');
      }
      try {
        if (cacheEpoch != CacheMaintenance.epoch) {
          throw StateError('Cache cleared');
        }
        await _cache.save(fresh);
      } catch (_) {
        storageWarning = true;
      }
      final result = storageWarning
          ? MosqueCatalog(
              region: fresh.region,
              mosques: fresh.mosques,
              boundary: fresh.boundary,
              savedAt: fresh.savedAt,
              notice: 'regionSaveError',
            )
          : fresh;
      publish(result);
      return result;
    } catch (error) {
      if (_disposed || generation != _generation) rethrow;
      final fallback = [confirmedCache, provisional, currentCatalog]
          .whereType<MosqueCatalog>()
          .where((c) => CachePolicy.isFresh(c.savedAt))
          .firstOrNull;
      if (fallback == null) rethrow;

      final result = fallback.cached(
        locationConfirmed:
            confirmedCache != null || (provisional?.region.isCity ?? false),
        notice: 'regionOffline',
      );
      publish(result);
      return result;
    }
  }

  Future<List<Mosque>> getMosques() async =>
      currentCatalog?.mosques ?? const [];
  Future<List<Mosque>> searchMosques(String query, {int limit = 20}) async =>
      MosqueSearch.find(await getMosques(), query, limit: limit);
}
