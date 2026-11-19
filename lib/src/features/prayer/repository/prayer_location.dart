import 'dart:math' as math;

class PrayerLocation {
  const PrayerLocation({
    required this.latitude,
    required this.longitude,
    this.city = '',
    this.country = '',
    this.countryCode = '',
  });
  final double latitude, longitude;
  final String city, country, countryCode;
  String get label => [city, country].where((s) => s.isNotEmpty).join(', ');
  bool near(PrayerLocation other) {
    if (countryCode.isNotEmpty &&
        other.countryCode.isNotEmpty &&
        countryCode != other.countryCode) {
      return false;
    }
    const radians = math.pi / 180;
    final dLat = (other.latitude - latitude) * radians;
    final dLon = (other.longitude - longitude) * radians;
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(latitude * radians) *
            math.cos(other.latitude * radians) *
            math.pow(math.sin(dLon / 2), 2);
    return 6371000 * 2 * math.asin(math.sqrt(a.clamp(0, 1))) <= 2000;
  }

  Map<String, dynamic> toJson() => {
    'lat': latitude,
    'lon': longitude,
    'city': city,
    'country': country,
    'code': countryCode,
  };
  factory PrayerLocation.fromJson(Map<String, dynamic> json) => PrayerLocation(
    latitude: (json['lat'] as num).toDouble(),
    longitude: (json['lon'] as num).toDouble(),
    city: json['city'] as String,
    country: json['country'] as String,
    countryCode: json['code'] as String,
  );
}
