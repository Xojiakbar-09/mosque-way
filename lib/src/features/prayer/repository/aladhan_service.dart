import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;

import '../../settings/repository/madhhab.dart';
import 'calculation_methods.dart';
import 'prayer_location.dart';
import 'prayer_schedule.dart';

class AladhanService {
  AladhanService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  Future<dynamic> _get(String path, Map<String, String> query) async {
    final response = await _client
        .get(Uri.https('api.aladhan.com', '/v1/$path', query))
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw const FormatException('Prayer API HTTP error');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['code'] != 200 || body['data'] == null) {
      throw const FormatException('Prayer API error');
    }
    return body['data'];
  }

  Future<PrayerSchedule> fetch(
    PrayerLocation location,
    Madhhab madhhab,
    int? requestedMethod,
  ) async {
    final method =
        requestedMethod ?? CalculationMethods.forCountry(location.countryCode);
    final query = {
      'latitude': '${location.latitude}',
      'longitude': '${location.longitude}',
      'school': '${madhhab.school}',
      'method': '$method',
      'iso8601': 'true',
    };
    // Resolve the destination timezone before choosing the calendar month.
    final current = Map<String, dynamic>.from(
      await _get(
            'timings/${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
            query,
          )
          as Map,
    );
    final meta = Map<String, dynamic>.from(current['meta'] as Map);
    if ((meta['method'] as Map)['id'] != method) {
      throw const FormatException('Unexpected calculation method');
    }
    final zone = meta['timezone'] as String;
    final now = tz.TZDateTime.now(tz.getLocation(zone));
    final raw = await _get('calendar/${now.year}/${now.month}', query) as List;
    final days = raw
        .map((d) => PrayerDay.fromApi(Map<String, dynamic>.from(d as Map)))
        .toList();
    if (days.length != DateTime(now.year, now.month + 1, 0).day ||
        days.map((day) => day.date).toSet().length != days.length ||
        !days.any((d) => d.date == PrayerSchedule.dateKey(now))) {
      throw const FormatException('Incomplete calendar');
    }
    // Cache next month's first day at a month boundary for an accurate next Fajr.
    if (now.day == DateTime(now.year, now.month + 1, 0).day) {
      final next = DateTime(now.year, now.month, now.day + 1);
      try {
        days.add(
          PrayerDay.fromApi(
            Map<String, dynamic>.from(
              await _get('timings/${PrayerSchedule.dateKey(next)}', query)
                  as Map,
            ),
          ),
        );
      } catch (_) {
        /* Today's complete calendar remains usable. */
      }
    }
    return PrayerSchedule(
      location: location,
      madhhab: madhhab,
      method: method,
      requestedMethod: requestedMethod,
      methodName: (meta['method'] as Map)['name'] as String,
      timezone: zone,
      savedAt: DateTime.now(),
      days: List.unmodifiable(days),
    );
  }

  void dispose() => _client.close();
}
