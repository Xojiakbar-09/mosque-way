/// OpenStreetMap'dan olingan masjid. Mavjud bo'lmagan ma'lumot to'qilmaydi.
class Mosque {
  const Mosque({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.osmId,
    this.phone,
    this.website,
    this.openingHours,
  });

  final String name;
  final double latitude;
  final double longitude;
  final String? address;
  final String? osmId;
  final String? phone;
  final String? website;
  final String? openingHours;

  Map<String, dynamic> toJson() => {
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'osmId': osmId,
    'phone': phone,
    'website': website,
    'openingHours': openingHours,
  };

  factory Mosque.fromJson(Map<String, dynamic> json) => Mosque(
    name: json['name'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    address: json['address'] as String?,
    osmId: json['osmId'] as String?,
    phone: json['phone'] as String?,
    website: json['website'] as String?,
    openingHours: json['openingHours'] as String?,
  );

  static Mosque? fromOsm(Map<String, dynamic> element) {
    final tags = Map<String, dynamic>.from(element['tags'] as Map? ?? {});
    String? text(String key) {
      final value = tags[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    if (text('amenity') != 'place_of_worship' ||
        (text('religion') != 'muslim' &&
            !(text('religion') == null && text('building') == 'mosque'))) {
      return null;
    }
    final name =
        text('name:uz') ??
        text('name') ??
        text('name:ru') ??
        text('official_name');
    final center = element['center'] as Map?;
    final latitude = center?['lat'] ?? element['lat'];
    final longitude = center?['lon'] ?? element['lon'];
    if (name == null ||
        latitude is! num ||
        longitude is! num ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }
    final street = text('addr:street') ?? text('addr:place');
    final number = text('addr:housenumber');
    final address =
        text('addr:full') ??
        [
          ?text('addr:city'),
          if (street != null) [street, ?number].join(', '),
        ].join(', ');
    return Mosque(
      name: name,
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      address: address.isEmpty ? null : address,
      osmId: '${element['type']}/${element['id']}',
      phone: text('contact:phone') ?? text('phone'),
      website: text('contact:website') ?? text('website'),
      openingHours: text('opening_hours'),
    );
  }
}
