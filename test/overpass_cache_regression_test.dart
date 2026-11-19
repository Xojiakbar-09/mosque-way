import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:maps/src/features/map/repository/overpass_service.dart';
import 'package:maps/src/features/map/repository/regional_mosque_repository.dart';
import 'package:maps/src/features/map/repository/mosque_cache.dart';
import 'package:maps/src/features/map/repository/mosque_catalog.dart';
import 'package:maps/src/features/map/repository/mosque_region.dart';
import 'package:maps/src/features/map/repository/mosque.dart';

final primary = Uri.parse('https://primary.test/interpreter');
final backup = Uri.parse('https://backup.test/interpreter');
http.Response ok() => http.Response(
  jsonEncode({
    'elements': [
      {
        'type': 'area',
        'id': 3600000001,
        'tags': {'name': 'Toshkent viloyati', 'admin_level': '4'},
      },
    ],
  }),
  200,
);
void main() {
  test('429 switches server and respects endpoint cooldown', () async {
    final hosts = <String>[];
    final service = OverpassService(
      endpoint: primary,
      fallbackEndpoints: [backup],
      client: MockClient((request) async {
        hosts.add(request.url.host);
        return request.url == primary
            ? http.Response('', 429, headers: {'retry-after': '120'})
            : ok();
      }),
    );
    expect((await service.resolveRegion(41, 69)).isCity, false);
    await service.resolveRegion(41, 69);
    expect(hosts, ['primary.test', 'backup.test', 'backup.test']);
  });
  test('identical concurrent requests share one HTTP call', () async {
    var calls = 0;
    final service = OverpassService(
      endpoint: primary,
      client: MockClient((r) async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return ok();
      }),
    );
    await Future.wait([
      service.resolveRegion(41, 69),
      service.resolveRegion(41, 69),
    ]);
    expect(calls, 1);
  });
  test('distinct queries are serialized', () async {
    var active = 0, maximum = 0;
    final service = OverpassService(
      endpoint: primary,
      client: MockClient((r) async {
        active++;
        if (active > maximum) maximum = active;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        active--;
        return ok();
      }),
    );
    await Future.wait([
      service.resolveRegion(41, 69),
      service.resolveRegion(42, 70),
    ]);
    expect(maximum, 1);
  });
  test('HTTP 200 partial data is rejected and backup is used', () async {
    var calls = 0;
    final service = OverpassService(
      endpoint: primary,
      fallbackEndpoints: [backup],
      client: MockClient((r) async {
        calls++;
        return r.url == primary
            ? http.Response(
                '{"elements":[],"remark":"runtime error: timeout"}',
                200,
              )
            : ok();
      }),
    );
    expect((await service.resolveRegion(41, 69)).name, 'Toshkent viloyati');
    expect(calls, 2);
  });
  test('all busy servers stop repeated calls during cooldown', () async {
    var calls = 0;
    final service = OverpassService(
      endpoint: primary,
      fallbackEndpoints: [backup],
      client: MockClient((r) async {
        calls++;
        return http.Response('', 503);
      }),
    );
    await expectLater(
      service.resolveRegion(41, 69),
      throwsA(isA<OverpassException>()),
    );
    await expectLater(
      service.resolveRegion(41, 69),
      throwsA(isA<OverpassException>()),
    );
    expect(calls, 2);
  });
  test('invalid coordinates never make a request', () async {
    var calls = 0;
    final service = OverpassService(
      endpoint: primary,
      client: MockClient((r) async {
        calls++;
        return ok();
      }),
    );
    await expectLater(
      service.resolveRegion(100, 69),
      throwsA(isA<OverpassException>()),
    );
    expect(calls, 0);
  });
  test('unchanged GPS reuses a confirmed province without network', () async {
    final service = FakeService();
    final cache = MemoryCache();
    final repo = RegionalMosqueRepository(service: service, cache: cache);
    final first = await repo.loadForLocation(latitude: 41, longitude: 69);
    final again = await repo.loadForLocation(latitude: 41.00001, longitude: 69);
    expect(again.fromCache, true);
    expect(again.savedAt, first.savedAt);
    expect(service.resolves, 1);
    expect(service.fetches, 1);
    await repo.loadForLocation(latitude: 41, longitude: 69, forceRefresh: true);
    expect(service.resolves, 2);
    expect(service.fetches, 2);
    await repo.loadForLocation(latitude: 42, longitude: 70);
    expect(service.resolves, 3);
    repo.dispose();
  });
  test(
    'failed forced refresh retains fresh cache and saved timestamp',
    () async {
      final service = FakeService();
      final repo = RegionalMosqueRepository(
        service: service,
        cache: MemoryCache(),
      );
      final first = await repo.loadForLocation(latitude: 41, longitude: 69);
      service.fail = true;
      final result = await repo.loadForLocation(
        latitude: 41,
        longitude: 69,
        forceRefresh: true,
      );
      expect(result.savedAt, first.savedAt);
      expect(result.fromCache, true);
      expect(result.notice, 'regionOffline');
      expect(result.mosques.length, 1);
      repo.dispose();
    },
  );
  test('expired cache is never used as outage fallback', () async {
    final service = FakeService()..fail = true;
    final cache = MemoryCache()
      ..items = [catalog(DateTime.now().subtract(const Duration(days: 8)))];
    final repo = RegionalMosqueRepository(service: service, cache: cache);
    await expectLater(
      repo.loadForLocation(latitude: 41, longitude: 69),
      throwsA(isA<OverpassException>()),
    );
    repo.dispose();
  });
}

const region = MosqueRegion(
  id: 3600000001,
  name: 'Toshkent viloyati',
  isCity: false,
  adminLevel: 4,
);
MosqueCatalog catalog(DateTime time) => MosqueCatalog(
  region: region,
  mosques: const [Mosque(name: 'Masjid', latitude: 41, longitude: 69)],
  boundary: const RegionBoundary([]),
  savedAt: time,
);

class FakeService extends OverpassService {
  int resolves = 0, fetches = 0;
  bool fail = false;
  @override
  Future<MosqueRegion> resolveRegion(double lat, double lon) async {
    resolves++;
    if (fail) throw const OverpassException('Server busy');
    return region;
  }

  @override
  Future<MosqueCatalog> fetchMosques(MosqueRegion r) async {
    fetches++;
    return catalog(DateTime.now());
  }
}

class MemoryCache implements MosqueCache {
  List<MosqueCatalog> items = [];
  @override
  Future<List<MosqueCatalog>> readAll() async => items;
  @override
  Future<MosqueCatalog?> readLast() async => items.firstOrNull;
  @override
  Future<void> markLast(String key) async {}
  @override
  Future<void> save(MosqueCatalog c) async {
    items = [c];
  }
}
