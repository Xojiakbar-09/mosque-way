import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'mosque.dart';
import 'mosque_region.dart';
import 'mosque_catalog.dart';

class OverpassException implements Exception {
  const OverpassException(this.message, {this.retryable = false});
  final bool retryable;
  final String message;
  @override
  String toString() => message;
}

class OverpassService {
  OverpassService({
    http.Client? client,
    Uri? endpoint,
    List<Uri>? fallbackEndpoints,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _endpoints = [
         endpoint ??
             Uri.parse(
               _configuredEndpoint.isEmpty
                   ? 'https://overpass-api.de/api/interpreter'
                   : _configuredEndpoint,
             ),
         ...?fallbackEndpoints,
         if (fallbackEndpoints == null &&
             endpoint == null &&
             _configuredEndpoint.isEmpty)
           Uri.parse('https://overpass.private.coffee/api/interpreter'),
       ];
  static const _configuredEndpoint = String.fromEnvironment(
    'OVERPASS_ENDPOINT',
  );
  final http.Client _client;
  final bool _ownsClient;
  final List<Uri> _endpoints;
  final Map<Uri, DateTime> _retryAfter = {};
  final Map<String, Future<List<Map<String, dynamic>>>> _pending = {};
  Future<void> _queue = Future<void>.value();
  bool _disposed = false;

  void dispose() {
    _disposed = true;
    if (_ownsClient) _client.close();
  }

  Future<List<Map<String, dynamic>>> _query(String query) {
    final existing = _pending[query];
    if (existing != null) return existing;
    late final Future<List<Map<String, dynamic>>> task;
    task = _queue.then((_) => _queryWithFallback(query)).whenComplete(() {
      if (identical(_pending[query], task)) _pending.remove(query);
    });
    _pending[query] = task;
    // Serialize requests even after a failed request; identical callers share it.
    _queue = task.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return task;
  }

  Future<List<Map<String, dynamic>>> _queryWithFallback(String query) async {
    OverpassException? lastError;
    for (final endpoint in _endpoints.toSet()) {
      if (_disposed) throw const OverpassException('requestCancelled');
      if (endpoint.scheme != 'https' || endpoint.host.isEmpty) {
        throw const OverpassException('serverConfigurationError');
      }
      final retryAfter = _retryAfter[endpoint];
      if (retryAfter != null && DateTime.now().isBefore(retryAfter)) continue;
      _retryAfter.remove(endpoint);
      try {
        final result = await _request(endpoint, query);
        _retryAfter.remove(endpoint);
        return result;
      } on OverpassException catch (error) {
        if (!error.retryable) rethrow;
        lastError = error;
        _retryAfter.putIfAbsent(
          endpoint,
          () => DateTime.now().add(const Duration(seconds: 30)),
        );
      }
    }
    throw lastError ?? const OverpassException('serverBusy', retryable: true);
  }

  Future<List<Map<String, dynamic>>> _request(
    Uri endpoint,
    String query,
  ) async {
    try {
      final response = await _client
          .post(
            endpoint,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'MasjidMap/1.0 (Flutter; regional mosque lookup)',
            },
            body: {'data': query},
          )
          .timeout(const Duration(seconds: 55));
      if (_disposed) throw const OverpassException('requestCancelled');
      if (response.statusCode == 429 ||
          response.statusCode == 406 ||
          response.statusCode >= 500) {
        _retryAfter[endpoint] = DateTime.now().add(
          _retryDelay(response.headers['retry-after']),
        );
        throw const OverpassException('serverBusy', retryable: true);
      }
      if (response.statusCode != 200) {
        throw const OverpassException('mosqueLoadError');
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map ||
          data['elements'] is! List ||
          (data['remark'] is String &&
              (data['remark'] as String).trim().isNotEmpty)) {
        // A successful HTTP code may still carry an incomplete Overpass result.
        throw const OverpassException('serverIncomplete', retryable: true);
      }
      return (data['elements'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on TimeoutException {
      throw const OverpassException('serverTimeout', retryable: true);
    } on http.ClientException {
      throw const OverpassException('networkError', retryable: true);
    } on FormatException {
      throw const OverpassException('serverIncomplete', retryable: true);
    }
  }

  Duration _retryDelay(String? value) {
    final seconds = int.tryParse(value ?? '');
    if (seconds != null) return Duration(seconds: seconds < 30 ? 30 : seconds);
    // Retry-After also accepts IMF-fixdate (HTTP date); avoid dart:io for web.
    if (value != null) {
      final match = RegExp(
        r'^\w{3}, (\d{2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT$',
      ).firstMatch(value.trim());
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      if (match != null && months.contains(match[2])) {
        final date = DateTime.utc(
          int.parse(match[3]!),
          months.indexOf(match[2]!) + 1,
          int.parse(match[1]!),
          int.parse(match[4]!),
          int.parse(match[5]!),
          int.parse(match[6]!),
        );
        final delay = date.difference(DateTime.now().toUtc());
        return delay < const Duration(seconds: 30)
            ? const Duration(seconds: 30)
            : delay;
      }
    }
    return const Duration(seconds: 30);
  }

  Future<MosqueRegion> resolveRegion(double latitude, double longitude) async {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180) {
      throw const OverpassException('invalidLocation');
    }
    final elements = await _query('''[out:json][timeout:20];
is_in($latitude,$longitude)->.a;
(area.a["boundary"="administrative"]["admin_level"~"^[3-8]\$"];
 area.a["place"~"^(city|town)\$"];);
out tags;''');
    final region = MosqueRegion.choose(elements);
    if (region == null) {
      throw const OverpassException('regionNotFound');
    }
    return region;
  }

  Future<MosqueCatalog> fetchMosques(MosqueRegion region) async {
    final elements = await _query('''[out:json][timeout:45][maxsize:33554432];
${region.selector}
(nwr["amenity"="place_of_worship"]["religion"="muslim"](area.region);
 nwr["amenity"="place_of_worship"]["building"="mosque"](area.region););
out center;
(way(pivot.region);rel(pivot.region););
out geom;''');
    final mosques = <Mosque>[];
    final seen = <String>{};
    for (final element in elements) {
      final mosque = Mosque.fromOsm(element);
      if (mosque == null || !seen.add(mosque.osmId!)) continue;
      mosques.add(mosque);
    }
    mosques.sort((a, b) => a.name.compareTo(b.name));
    return MosqueCatalog(
      region: region,
      mosques: List.unmodifiable(mosques),
      boundary: RegionBoundary.fromOsm(region, elements),
      savedAt: DateTime.now(),
    );
  }
}
