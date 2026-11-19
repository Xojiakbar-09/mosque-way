import 'package:geolocator/geolocator.dart';

import 'mosque.dart';
import 'mosque_catalog.dart';
import 'mosque_cache.dart';
import 'hive_mosque_cache.dart';
import 'regional_mosque_repository.dart';
import 'overpass_service.dart';

abstract class MapRepository {
  MosqueCatalog? get currentCatalog;
  Future<Position> getCurrentPosition();
  Future<MosqueCatalog?> restoreLast();
  Future<MosqueCatalog> loadForLocation({
    required double latitude,
    required double longitude,
    bool forceRefresh = false,
    void Function(MosqueCatalog catalog)? onCached,
  });
  Future<List<Mosque>> getMosques();
  Future<List<Mosque>> getNearestMosques({
    required double latitude,
    required double longitude,
    int? limit,
  });
  Future<List<Mosque>> searchMosques(String query, {int limit = 20});
  void invalidate();
  void dispose();
}

class MapRepositoryImpl extends RegionalMosqueRepository
    implements MapRepository {
  MapRepositoryImpl({OverpassService? service, MosqueCache? cache})
    : super(
        service: service ?? OverpassService(),
        cache: cache ?? HiveMosqueCache(),
      );
  @override
  Future<Position> getCurrentPosition() => Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 20),
    ),
  );
  @override
  Future<List<Mosque>> getNearestMosques({
    required double latitude,
    required double longitude,
    int? limit,
  }) async {
    final mosques = List<Mosque>.of(await getMosques());
    mosques.sort(
      (a, b) =>
          Geolocator.distanceBetween(
            latitude,
            longitude,
            a.latitude,
            a.longitude,
          ).compareTo(
            Geolocator.distanceBetween(
              latitude,
              longitude,
              b.latitude,
              b.longitude,
            ),
          ),
    );
    return limit == null
        ? mosques
        : mosques.take(limit < 0 ? 0 : limit).toList(growable: false);
  }
}
