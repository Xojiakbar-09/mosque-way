import 'package:flutter_test/flutter_test.dart';
import 'package:maps/src/features/map/repository/map_repository.dart';
import 'package:maps/src/features/map/repository/mosque.dart';
import 'package:maps/src/features/map/repository/mosque_cache.dart';
import 'package:maps/src/features/map/repository/mosque_catalog.dart';
import 'package:maps/src/features/map/repository/mosque_region.dart';

void main() {
  test('nearest mosques are sorted without changing the cached catalog', () async {
    const far = Mosque(name: 'Uzoq', latitude: 41.5, longitude: 69.5);
    const near = Mosque(
      name: 'Yaqin',
      latitude: 41.3,
      longitude: 69.2,
      address: 'Sinov manzili',
    );
    final repository = MapRepositoryImpl(
      cache: _Cache(
        MosqueCatalog(
          region: const MosqueRegion(
            id: 1,
            name: 'Toshkent',
            isCity: true,
            adminLevel: 6,
          ),
          mosques: const [far, near],
          boundary: const RegionBoundary([]),
          savedAt: DateTime.now(),
        ),
      ),
    );
    addTearDown(repository.dispose);

    await repository.restoreLast();
    final nearest = await repository.getNearestMosques(
      latitude: 41.3,
      longitude: 69.2,
      limit: 1,
    );
    expect(nearest, [near]);
    expect(nearest.single.address, 'Sinov manzili');
    expect((await repository.getMosques()).map((item) => item.address),
        [null, 'Sinov manzili']);
    expect(await repository.getMosques(), [far, near]);
  });
}

class _Cache implements MosqueCache {
  _Cache(this.catalog);
  final MosqueCatalog catalog;

  @override
  Future<List<MosqueCatalog>> readAll() async => [catalog];

  @override
  Future<MosqueCatalog?> readLast() async => catalog;

  @override
  Future<void> markLast(String key) async {}

  @override
  Future<void> save(MosqueCatalog catalog) async {}
}
