// Run with: dart run test/overpass_core_check.dart
// Real repository/service/cache code; fake HTTP only. No Flutter engine needed.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hive_ce/hive.dart';
import 'package:maps/src/features/map/repository/mosque.dart';
import 'package:maps/src/features/map/repository/mosque_region.dart';
import 'package:maps/src/features/map/repository/mosque_catalog.dart';
import 'package:maps/src/features/map/repository/mosque_cache.dart';
import 'package:maps/src/features/map/repository/hive_mosque_cache.dart';
import 'package:maps/src/features/map/repository/mosque_search.dart';
import 'package:maps/src/features/map/repository/overpass_service.dart';
import 'package:maps/src/features/map/repository/regional_mosque_repository.dart';

class MemoryCache implements MosqueCache {
  final entries = <String, MosqueCatalog>{};
  String? last;
  int saves = 0;
  bool fail = false;
  @override
  Future<List<MosqueCatalog>> readAll() async => entries.values.toList();
  @override
  Future<MosqueCatalog?> readLast() async => entries[last];
  @override
  Future<void> markLast(String key) async {
    last = key;
  }

  @override
  Future<void> save(MosqueCatalog catalog) async {
    if (fail) throw StateError('disk full');
    saves++;
    entries[catalog.region.key] = catalog;
    last = catalog.region.key;
  }
}

const city = MosqueRegion(
  id: 3600000011,
  name: 'Test shahar',
  isCity: true,
  adminLevel: 6,
);
const province = MosqueRegion(
  id: 3600000022,
  name: 'Test viloyati',
  isCity: false,
  adminLevel: 4,
);
const otherCity = MosqueRegion(
  id: 3600000033,
  name: 'Boshqa shahar',
  isCity: true,
  adminLevel: 6,
);
RegionBoundary square(double x) => RegionBoundary([
  [
    (lat: 0.0, lon: x),
    (lat: 0.0, lon: x + 10),
    (lat: 10.0, lon: x + 10),
    (lat: 10.0, lon: x),
    (lat: 0.0, lon: x),
  ],
]);
MosqueCatalog catalog(MosqueRegion region, {double x = 0}) => MosqueCatalog(
  region: region,
  boundary: square(x),
  savedAt: DateTime.now().toUtc(),
  mosques: const [
    Mosque(
      name: 'Ko‘kcha masjidi',
      latitude: 5,
      longitude: 5,
      address: 'Toshkent, Farobiy',
    ),
  ],
);
Map<String, dynamic> area(MosqueRegion region) => {
  'type': 'area',
  'id': region.id,
  'tags': {
    'boundary': 'administrative',
    'admin_level': '${region.adminLevel}',
    'name': region.name,
    if (region.isCity) 'place': 'city',
  },
};
Map<String, dynamic> mosque({String name = 'Minor', int id = 1}) => {
  'type': 'node',
  'id': id,
  'lat': 5.0,
  'lon': 5.0,
  'tags': {
    'name': name,
    'amenity': 'place_of_worship',
    'religion': 'muslim',
    'addr:street': 'Farobiy',
    'addr:city': 'Toshkent',
    'contact:phone': '+998000',
    'website': 'https://example.org',
    'opening_hours': '24/7',
  },
};
Map<String, dynamic> boundary(MosqueRegion region) => {
  'type': 'relation',
  'id': region.id - 3600000000,
  'tags': {'boundary': 'administrative'},
  'members': [
    {
      'type': 'way',
      'role': 'outer',
      'geometry': [
        {'lat': 0, 'lon': 0},
        {'lat': 0, 'lon': 10},
        {'lat': 10, 'lon': 10},
        {'lat': 10, 'lon': 0},
        {'lat': 0, 'lon': 0},
      ],
    },
  ],
};
http.Response response(List<Map<String, dynamic>> elements) => http.Response(
  jsonEncode({'elements': elements}),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
int passed = 0;
void check(bool value, String label) {
  if (!value) throw StateError(label);
}

Future<void> test(String label, FutureOr<void> Function() body) async {
  await body();
  passed++;
  stdout.writeln('PASS $label');
}

Future<void> expectError(Future<dynamic> Function() action) async {
  var threw = false;
  try {
    await action();
  } on OverpassException {
    threw = true;
  }
  check(threw, 'Expected OverpassException');
}

Future<void> main() async {
  await test('city wins over province and mahalla is excluded', () {
    final chosen = MosqueRegion.choose([
      area(province),
      area(city),
      {
        'type': 'area',
        'id': 3600000044,
        'tags': {'admin_level': '8', 'name': 'Mahalla'},
      },
    ]);
    check(chosen?.key == city.key, 'wrong region');
    check(
      MosqueRegion.choose([area(province)])?.key == province.key,
      'fallback',
    );
  });
  await test(
    'unnamed and invalid coordinates are excluded; node/way parsing',
    () {
      check(Mosque.fromOsm(mosque(name: '')) == null, 'unnamed');
      check(
        Mosque.fromOsm({...mosque(), 'lat': 95}) == null,
        'invalid latitude',
      );
      final m = Mosque.fromOsm({
        ...mosque(),
        'type': 'way',
        'center': {'lat': 7, 'lon': 8},
      })!;
      check(
        m.latitude == 7 &&
            m.longitude == 8 &&
            m.phone == '+998000' &&
            m.openingHours == '24/7',
        'metadata',
      );
    },
  );
  await test('local search handles apostrophes, addresses and Cyrillic', () {
    final data = catalog(city).mosques;
    for (final q in ["ko'kcha", '  KOʻKCHA  ', 'кўкча', 'farobiy toshkent']) {
      check(MosqueSearch.find(data, q).length == 1, q);
    }
    check(MosqueSearch.find(data, 'missing').isEmpty, 'no match');
  });
  await test('boundary fragments and inner holes are handled', () {
    final shape = RegionBoundary([
      ...square(0).pieces,
      [
        (lat: 3.0, lon: 3.0),
        (lat: 3.0, lon: 7.0),
        (lat: 7.0, lon: 7.0),
        (lat: 7.0, lon: 3.0),
        (lat: 3.0, lon: 3.0),
      ],
    ]);
    check(
      shape.contains(1, 1) && !shape.contains(5, 5) && !shape.contains(20, 20),
      'polygon',
    );
    check(
      RegionBoundary.fromOsm(city, [boundary(city)]).contains(5, 5),
      'parsed boundary',
    );
    final open = boundary(city);
    (open['members'][0]['geometry'] as List).removeLast();
    check(
      !RegionBoundary.fromOsm(city, [open]).isUsable,
      'open geometry must be rejected',
    );
  });
  await test('catalog JSON round-trip preserves fields and geometry', () {
    final restored = MosqueCatalog.fromJson(
      jsonDecode(jsonEncode(catalog(city).toJson())),
    );
    check(
      restored.region.key == city.key &&
          restored.boundary.contains(5, 5) &&
          restored.mosques.single.name == 'Ko‘kcha masjidi',
      'roundtrip',
    );
  });
  await test('first load resolves region, downloads once, and saves', () async {
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      final query = request.bodyFields['data']!;
      check(!query.contains('\\u0024'), 'invalid regex escape');
      return response(
        query.contains('is_in(')
            ? [area(province), area(city)]
            : [mosque(), mosque(), mosque(name: '', id: 2), boundary(city)],
      );
    });
    final cache = MemoryCache();
    final repo = RegionalMosqueRepository(
      service: OverpassService(client: client),
      cache: cache,
    );
    final result = await repo.loadForLocation(latitude: 5, longitude: 5);
    check(
      requests == 2 &&
          cache.saves == 1 &&
          result.mosques.length == 1 &&
          result.boundary.isUsable,
      'initial load',
    );
    await repo.searchMosques('minor');
    check(requests == 2, 'search must not call API');
    repo.dispose();
    client.close();
  });
  await test('fresh city cache avoids automatic downloads', () async {
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      throw http.ClientException('offline');
    });
    final cache = MemoryCache();
    await cache.save(catalog(city));
    final repo = RegionalMosqueRepository(
      service: OverpassService(client: client),
      cache: cache,
    );
    var cacheShown = false;
    final result = await repo.loadForLocation(
      latitude: 5,
      longitude: 5,
      onCached: (_) => cacheShown = true,
    );
    check(
      cacheShown &&
          result.fromCache &&
          requests == 0 &&
          result.locationConfirmed,
      'manual-only cache',
    );
    repo.dispose();
    client.close();
  });
  await test('manual refresh fetches new data and replaces cache', () async {
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      return response(
        request.bodyFields['data']!.contains('is_in(')
            ? [area(city)]
            : [mosque(name: 'Yangilangan'), boundary(city)],
      );
    });
    final cache = MemoryCache();
    await cache.save(catalog(city));
    final repo = RegionalMosqueRepository(
      service: OverpassService(client: client),
      cache: cache,
    );
    final result = await repo.loadForLocation(
      latitude: 5,
      longitude: 5,
      forceRefresh: true,
    );
    check(
      !result.fromCache &&
          result.mosques.single.name == 'Yangilangan' &&
          requests == 2 &&
          cache.saves == 2,
      'manual refresh',
    );
    repo.dispose();
    client.close();
  });
  await test(
    'failed refresh retains previous data without overwriting disk',
    () async {
      final client = MockClient(
        (request) async => request.bodyFields['data']!.contains('is_in(')
            ? response([area(city)])
            : http.Response(
                '{"elements":[],"remark":"runtime error: timed out"}',
                200,
              ),
      );
      final cache = MemoryCache();
      await cache.save(catalog(city));
      final repo = RegionalMosqueRepository(
        service: OverpassService(client: client),
        cache: cache,
      );
      final result = await repo.loadForLocation(
        latitude: 5,
        longitude: 5,
        forceRefresh: true,
      );
      check(
        result.fromCache &&
            result.notice != null &&
            result.mosques.isNotEmpty &&
            cache.saves == 1,
        'retain cache',
      );
      repo.dispose();
      client.close();
    },
  );
  await test(
    'province cache checks for a city, but does not refetch same province',
    () async {
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return response([area(province)]);
      });
      final cache = MemoryCache();
      await cache.save(catalog(province));
      final repo = RegionalMosqueRepository(
        service: OverpassService(client: client),
        cache: cache,
      );
      final result = await repo.loadForLocation(latitude: 5, longitude: 5);
      check(
        requests == 1 && result.region.key == province.key && result.fromCache,
        'province cache',
      );
      repo.dispose();
      client.close();
    },
  );
  await test(
    'moving to a new city downloads and keeps separate cache',
    () async {
      final client = MockClient(
        (request) async => response(
          request.bodyFields['data']!.contains('is_in(')
              ? [area(otherCity)]
              : [mosque(name: 'Boshqa masjid'), boundary(otherCity)],
        ),
      );
      final cache = MemoryCache();
      await cache.save(catalog(city));
      final repo = RegionalMosqueRepository(
        service: OverpassService(client: client),
        cache: cache,
      );
      final result = await repo.loadForLocation(latitude: 50, longitude: 50);
      check(
        result.region.key == otherCity.key && cache.entries.length == 2,
        'new region',
      );
      repo.dispose();
      client.close();
    },
  );
  await test('offline relocation labels last region as unconfirmed', () async {
    final client = MockClient(
      (_) async => throw http.ClientException('offline'),
    );
    final cache = MemoryCache();
    await cache.save(catalog(city));
    final repo = RegionalMosqueRepository(
      service: OverpassService(client: client),
      cache: cache,
    );
    await repo.restoreLast();
    final result = await repo.loadForLocation(latitude: 50, longitude: 50);
    check(
      !result.locationConfirmed &&
          result.notice != null &&
          result.region.key == city.key,
      'wrong-city fallback',
    );
    repo.dispose();
    client.close();
  });
  await test(
    '429 applies cooldown and prevents immediate repeated requests',
    () async {
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return http.Response('busy', 429);
      });
      final service = OverpassService(
        client: client,
        fallbackEndpoints: const [],
      );
      await expectError(() => service.resolveRegion(5, 5));
      await expectError(() => service.resolveRegion(5, 5));
      check(requests == 1, 'cooldown bypassed');
      client.close();
    },
  );
  await test(
    'no data and no internet returns error rather than fake empty cache',
    () async {
      final client = MockClient(
        (_) async => throw http.ClientException('offline'),
      );
      final cache = MemoryCache();
      final repo = RegionalMosqueRepository(
        service: OverpassService(client: client),
        cache: cache,
      );
      await expectError(() => repo.loadForLocation(latitude: 5, longitude: 5));
      check(cache.saves == 0, 'fake empty cache');
      repo.dispose();
      client.close();
    },
  );
  await test('disk write failure retains live data and shows notice', () async {
    final client = MockClient(
      (request) async => response(
        request.bodyFields['data']!.contains('is_in(')
            ? [area(city)]
            : [mosque(), boundary(city)],
      ),
    );
    final cache = MemoryCache()..fail = true;
    final repo = RegionalMosqueRepository(
      service: OverpassService(client: client),
      cache: cache,
    );
    final result = await repo.loadForLocation(latitude: 5, longitude: 5);
    check(result.mosques.length == 1 && result.notice != null, 'disk failure');
    repo.dispose();
    client.close();
  });
  await test('Hive writes survive closing and reopening the box', () async {
    final directory = await Directory.systemTemp.createTemp(
      'mosque-cache-test-',
    );
    try {
      Hive.init(directory.path);
      final cache = HiveMosqueCache();
      await cache.save(catalog(city));
      await Hive.close();
      final restored = await HiveMosqueCache().readLast();
      check(
        restored?.region.key == city.key && restored!.boundary.contains(5, 5),
        'disk persistence',
      );
      await Hive.close();
    } finally {
      await directory.delete(recursive: true);
    }
  });
  stdout.writeln('$passed checks passed.');
}
