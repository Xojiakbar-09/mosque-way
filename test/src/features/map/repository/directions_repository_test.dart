import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maps/src/features/map/repository/directions_profile.dart';
import 'package:maps/src/features/map/repository/directions_repository.dart';

/// Directions API javobining namunasi: uch nuqtali chiziq.
const String _responseBody = '''
{
  "routes": [
    {
      "geometry": {
        "type": "LineString",
        "coordinates": [[69.24, 41.31], [69.245, 41.315], [69.25, 41.32]]
      },
      "distance": 1234.5,
      "duration": 321.0
    }
  ],
  "code": "Ok"
}
''';

Future<void> _requestRoute(DirectionsRepository repository) async {
  await repository.getRoute(
    profile: DirectionsProfile.driving,
    fromLatitude: 41.31,
    fromLongitude: 69.24,
    toLatitude: 41.32,
    toLongitude: 69.25,
  );
}

void main() {
  group('DirectionsRepositoryImpl', () {
    test("marshrut nuqtalari, masofa va vaqtni o'qiydi", () async {
      final repository = DirectionsRepositoryImpl(
        accessToken: 'token',
        client: MockClient((_) async => http.Response(_responseBody, 200)),
      );

      final route = await repository.getRoute(
        profile: DirectionsProfile.driving,
        fromLatitude: 41.31,
        fromLongitude: 69.24,
        toLatitude: 41.32,
        toLongitude: 69.25,
      );

      expect(route, isNotNull);
      expect(route!.points, hasLength(3));
      expect(route.points.first.latitude, 41.31);
      expect(route.points.first.longitude, 69.24);
      expect(route.points.last.latitude, 41.32);
      expect(route.points.last.longitude, 69.25);
      expect(route.distance, 1234.5);
      expect(route.duration, 321.0);
    });

    test(
      "so'rovni avtomobil profili va uzunlik,kenglik tartibida yuboradi",
      () async {
        late Uri requestedUrl;
        final repository = DirectionsRepositoryImpl(
          accessToken: 'token',
          client: MockClient((request) async {
            requestedUrl = request.url;
            return http.Response(_responseBody, 200);
          }),
        );

        await _requestRoute(repository);

        expect(
          requestedUrl.path,
          '/directions/v5/mapbox/driving/69.24,41.31;69.25,41.32',
        );
        expect(requestedUrl.queryParameters['geometries'], 'geojson');
        expect(requestedUrl.queryParameters['overview'], 'full');
        expect(requestedUrl.queryParameters['access_token'], 'token');
      },
    );

    test('tanlangan profil manzilga qo\'shiladi', () async {
      late Uri requestedUrl;
      final repository = DirectionsRepositoryImpl(
        accessToken: 'token',
        client: MockClient((request) async {
          requestedUrl = request.url;
          return http.Response(_responseBody, 200);
        }),
      );

      await repository.getRoute(
        profile: DirectionsProfile.drivingTraffic,
        fromLatitude: 41.31,
        fromLongitude: 69.24,
        toLatitude: 41.32,
        toLongitude: 69.25,
      );

      expect(
        requestedUrl.path,
        '/directions/v5/mapbox/driving-traffic/69.24,41.31;69.25,41.32',
      );
    });

    test('xato javobda null qaytaradi', () async {
      final repository = DirectionsRepositoryImpl(
        accessToken: 'token',
        client: MockClient((_) async => http.Response('{}', 500)),
      );

      final route = await repository.getRoute(
        profile: DirectionsProfile.driving,
        fromLatitude: 41.31,
        fromLongitude: 69.24,
        toLatitude: 41.32,
        toLongitude: 69.25,
      );

      expect(route, isNull);
    });

    test("marshrut topilmasa null qaytaradi", () async {
      final repository = DirectionsRepositoryImpl(
        accessToken: 'token',
        client: MockClient(
          (_) async => http.Response(jsonEncode({'routes': []}), 200),
        ),
      );

      final route = await repository.getRoute(
        profile: DirectionsProfile.driving,
        fromLatitude: 41.31,
        fromLongitude: 69.24,
        toLatitude: 41.32,
        toLongitude: 69.25,
      );

      expect(route, isNull);
    });

    test("token bo'lmasa so'rov yubormaydi", () async {
      var isCalled = false;
      final repository = DirectionsRepositoryImpl(
        accessToken: '',
        client: MockClient((_) async {
          isCalled = true;
          return http.Response(_responseBody, 200);
        }),
      );

      await _requestRoute(repository);

      expect(isCalled, isFalse);
    });
  });
}
