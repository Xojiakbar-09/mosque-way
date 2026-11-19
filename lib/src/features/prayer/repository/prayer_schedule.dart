import 'package:timezone/timezone.dart' as tz;

import '../../settings/repository/madhhab.dart';
import 'prayer_location.dart';

const prayerKeys = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
const displayedPrayerKeys = [
  'Fajr',
  'Sunrise',
  'Dhuhr',
  'Asr',
  'Maghrib',
  'Isha',
];

class PrayerDay {
  const PrayerDay({
    required this.date,
    required this.hijri,
    required this.times,
  });
  final String date, hijri;
  String hijriFor(String language) {
    const months = <String, List<String>>{
      'Muharram': ['Muharram', 'Мухаррам'],
      'Safar': ['Safar', 'Сафар'],
      'Rabīʿ al-awwal': ['Rabiul avval', 'Раби аль-авваль'],
      'Rabīʿ al-thānī': ['Rabius soniy', 'Раби ас-сани'],
      'Jumādá al-ūlá': ['Jumodul avval', 'Джумада аль-уля'],
      'Jumādá al-ākhirah': ['Jumodus soniy', 'Джумада аль-ахира'],
      'Rajab': ['Rajab', 'Раджаб'],
      'Shaʿbān': ['Sha’bon', 'Шаабан'],
      'Ramaḍān': ['Ramazon', 'Рамадан'],
      'Shawwāl': ['Shavvol', 'Шавваль'],
      'Dhū al-Qaʿdah': ['Zulqa’da', 'Зуль-каада'],
      'Dhū al-Ḥijjah': ['Zulhijja', 'Зуль-хиджа'],
    };
    if (language == 'en') return hijri;
    var result = hijri;
    for (final entry in months.entries) {
      result = result.replaceAll(
        entry.key,
        entry.value[language == 'ru' ? 1 : 0],
      );
    }
    return result;
  }

  /// ISO 8601 strings retain destination UTC offset, independent of phone timezone.
  final Map<String, String> times;
  DateTime instant(String key) => DateTime.parse(times[key]!);
  String clock(String key) => times[key]!.substring(11, 16);
  factory PrayerDay.fromApi(Map<String, dynamic> data) {
    final raw = Map<String, dynamic>.from(data['timings'] as Map);
    final times = <String, String>{};
    for (final key in displayedPrayerKeys) {
      final value = raw[key] as String;
      if (!RegExp(
        r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z|[+-]\d{2}:\d{2})$',
      ).hasMatch(value)) {
        throw const FormatException(
          'Expected ISO prayer timestamp with UTC offset',
        );
      }
      DateTime.parse(value);
      times[key] = value;
    }
    final date = Map<String, dynamic>.from(data['date'] as Map);
    final hijri = Map<String, dynamic>.from(date['hijri'] as Map);
    final month = Map<String, dynamic>.from(hijri['month'] as Map);
    return PrayerDay(
      date: (date['gregorian'] as Map)['date'] as String,
      hijri: '${hijri['day']} ${month['en']} ${hijri['year']}',
      times: times,
    );
  }
  Map<String, dynamic> toJson() => {
    'date': date,
    'hijri': hijri,
    'times': times,
  };
  factory PrayerDay.fromJson(Map<String, dynamic> json) => PrayerDay(
    date: json['date'] as String,
    hijri: json['hijri'] as String,
    times: Map<String, String>.from(json['times'] as Map),
  );
}

class PrayerSchedule {
  const PrayerSchedule({
    required this.location,
    required this.madhhab,
    required this.method,
    required this.methodName,
    required this.timezone,
    required this.savedAt,
    required this.days,
    this.requestedMethod,
  });
  final PrayerLocation location;
  final Madhhab madhhab;
  final int method;
  final int? requestedMethod;
  final String methodName, timezone;
  final DateTime savedAt;
  final List<PrayerDay> days;
  DateTime localNow(DateTime now) =>
      tz.TZDateTime.from(now, tz.getLocation(timezone));
  static String dateKey(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  PrayerDay? dayAt(DateTime now) {
    final key = dateKey(localNow(now));
    return days.where((d) => d.date == key).firstOrNull;
  }

  ({String key, DateTime instant, String clock, bool tomorrow})? next(
    DateTime now,
  ) {
    final local = localNow(now);
    final todayKey = dateKey(local);
    final tomorrowKey = dateKey(
      DateTime(local.year, local.month, local.day + 1),
    );
    final candidates =
        <({String key, DateTime instant, String clock, bool tomorrow})>[];
    for (final day in days.where(
      (d) => d.date == todayKey || d.date == tomorrowKey,
    )) {
      for (final key in prayerKeys) {
        final instant = day.instant(key);
        if (instant.isAfter(now)) {
          candidates.add((
            key: key,
            instant: instant,
            clock: day.clock(key),
            tomorrow: day.date != todayKey,
          ));
        }
      }
    }
    candidates.sort((a, b) => a.instant.compareTo(b.instant));
    return candidates.firstOrNull;
  }

  Map<String, dynamic> toJson() => {
    'location': location.toJson(),
    'madhhab': madhhab.name,
    'method': method,
    'requestedMethod': requestedMethod,
    'methodName': methodName,
    'timezone': timezone,
    'savedAt': savedAt.toIso8601String(),
    'days': days.map((d) => d.toJson()).toList(),
  };
  factory PrayerSchedule.fromJson(Map<String, dynamic> json) => PrayerSchedule(
    location: PrayerLocation.fromJson(
      Map<String, dynamic>.from(json['location'] as Map),
    ),
    madhhab: Madhhab.values.byName(json['madhhab'] as String),
    method: json['method'] as int,
    requestedMethod: json['requestedMethod'] as int?,
    methodName: json['methodName'] as String,
    timezone: json['timezone'] as String,
    savedAt: DateTime.parse(json['savedAt'] as String),
    days: (json['days'] as List)
        .map((d) => PrayerDay.fromJson(Map<String, dynamic>.from(d as Map)))
        .toList(),
  );
}
