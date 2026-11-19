import 'dart:convert';

import 'package:http/http.dart' as http;

import 'directions_profile.dart';
import 'directions_route.dart';

/// Mapbox Directions API bilan ishlash qatlami.
///
/// Faqat tarmoq so'rovi va javobni o'qish bilan shug'ullanadi —
/// chizish va boshqa UI ishlari bu qatlamda yo'q.
abstract class DirectionsRepository {
  void dispose();

  /// Ikki nuqta orasidagi marshrutni tanlangan profil bo'yicha oladi.
  /// Marshrut topilmasa `null` qaytaradi.
  Future<DirectionsRoute?> getRoute({
    required DirectionsProfile profile,
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  });
}

class DirectionsRepositoryImpl implements DirectionsRepository {
  DirectionsRepositoryImpl({http.Client? client, String? accessToken})
    : _client = client ?? http.Client(),
      _ownsClient = client == null,
      _accessToken = accessToken ?? _defaultAccessToken;

  /// Build vaqtida beriladigan Mapbox tokeni.
  static const String _defaultAccessToken = String.fromEnvironment(
    'ACCESS_TOKEN',
  );

  static const String _baseUrl = 'https://api.mapbox.com/directions/v5/mapbox';

  final http.Client _client;
  final bool _ownsClient;
  @override
  void dispose() {
    if (_ownsClient) _client.close();
  }

  final String _accessToken;

  @override
  Future<DirectionsRoute?> getRoute({
    required DirectionsProfile profile,
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) async {
    if (_accessToken.isEmpty) return null;

    final uri = _buildUri(
      profile: profile,
      fromLatitude: fromLatitude,
      fromLongitude: fromLongitude,
      toLatitude: toLatitude,
      toLongitude: toLongitude,
    );

    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return null;

      return _parseRoute(response.body);
    } catch (_) {
      return null;
    }
  }

  Uri _buildUri({
    required DirectionsProfile profile,
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) {
    // Directions API koordinatani "uzunlik,kenglik" tartibida kutadi.
    final coordinates = '$fromLongitude,$fromLatitude;$toLongitude,$toLatitude';

    return Uri.parse('$_baseUrl/${profile.path}/$coordinates').replace(
      queryParameters: {
        'geometries': 'geojson',
        'overview': 'full',
        'access_token': _accessToken,
      },
    );
  }

  /// Javob tanasini [DirectionsRoute]ga aylantiradi.
  DirectionsRoute? _parseRoute(String body) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    final routes = data['routes'] as List<dynamic>? ?? const [];
    if (routes.isEmpty) return null;

    final route = routes.first as Map<String, dynamic>;
    final geometry = route['geometry'] as Map<String, dynamic>?;
    final coordinates = geometry?['coordinates'] as List<dynamic>? ?? const [];

    final points = <RoutePoint>[
      for (final coordinate in coordinates) ?_pointFromCoordinate(coordinate),
    ];
    if (points.isEmpty) return null;

    return DirectionsRoute(
      points: points,
      distance: (route['distance'] as num?)?.toDouble() ?? 0,
      duration: (route['duration'] as num?)?.toDouble() ?? 0,
    );
  }

  /// GeoJSON koordinatasi `[uzunlik, kenglik]` ko'rinishida keladi.
  RoutePoint? _pointFromCoordinate(dynamic coordinate) {
    if (coordinate is! List || coordinate.length < 2) return null;

    final longitude = coordinate[0];
    final latitude = coordinate[1];
    if (latitude is! num || longitude is! num) return null;

    return RoutePoint(
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
    );
  }
}
