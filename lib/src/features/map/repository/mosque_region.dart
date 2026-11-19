/// OSM hudud identifikatori; hudud nomi hech qachon query ichiga qo'yilmaydi.
class MosqueRegion {
  const MosqueRegion({
    required this.id,
    required this.name,
    required this.isCity,
    required this.adminLevel,
    this.sourceType = 'area',
  });
  final int id;
  final String name;
  final bool isCity;
  final int adminLevel;
  final String sourceType;
  String get key => '$sourceType:$id';
  String get label => isCity ? 'Shahar' : 'Viloyat';
  String get selector => sourceType == 'way'
      ? 'way($id);map_to_area->.region;'
      : 'area($id)->.region;';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isCity': isCity,
    'adminLevel': adminLevel,
    'sourceType': sourceType,
  };
  factory MosqueRegion.fromJson(Map<String, dynamic> json) => MosqueRegion(
    id: json['id'] as int,
    name: json['name'] as String,
    isCity: json['isCity'] as bool,
    adminLevel: json['adminLevel'] as int,
    sourceType: json['sourceType'] as String,
  );

  static MosqueRegion? choose(List<Map<String, dynamic>> elements) {
    final regions = <MosqueRegion>[];
    for (final e in elements) {
      final tags = e['tags'] as Map? ?? {};
      final id = e['id'];
      if (id is! int || id <= 0 || !['area', 'way'].contains(e['type'])) {
        continue;
      }
      final rawName = tags['name:uz'] ?? tags['name'] ?? tags['name:en'];
      if (rawName is! String || rawName.trim().isEmpty) continue;
      final level = int.tryParse('${tags['admin_level']}') ?? 0;
      final name = rawName.trim();
      final lower = name.toLowerCase();
      final city =
          ['city', 'town'].contains(tags['place']) ||
          ['city', 'town'].contains(tags['border_type']) ||
          (level >= 3 &&
              level <= 7 &&
              RegExp(r'(shahri?|шаҳри?|город|city|sh\.)$').hasMatch(lower));
      // Uzbekistan's mahallas/districts must not be treated as cities merely
      // because their admin_level is 6 or 8.
      if (!city && level != 4) continue;
      regions.add(
        MosqueRegion(
          id: id,
          name: name,
          isCity: city,
          adminLevel: level,
          sourceType: e['type'] as String,
        ),
      );
    }
    regions.sort((a, b) {
      if (a.isCity != b.isCity) return a.isCity ? -1 : 1;
      final level = b.adminLevel.compareTo(a.adminLevel);
      return level != 0 ? level : a.id.compareTo(b.id);
    });
    return regions.isEmpty ? null : regions.first;
  }
}

/// Boundary pieces are stored without joining ways: ray intersections over all
/// closed boundary edges correctly handle multiple outers and inner holes.
class RegionBoundary {
  const RegionBoundary(this.pieces);
  final List<List<({double lat, double lon})>> pieces;
  bool get isUsable => pieces.isNotEmpty;

  bool contains(double latitude, double longitude) {
    var inside = false;
    for (final piece in pieces) {
      for (var i = 1; i < piece.length; i++) {
        final a = piece[i - 1];
        final b = piece[i];
        final cross =
            (longitude - a.lon) * (b.lat - a.lat) -
            (latitude - a.lat) * (b.lon - a.lon);
        if (cross.abs() < 1e-10 &&
            longitude >= (a.lon < b.lon ? a.lon : b.lon) &&
            longitude <= (a.lon > b.lon ? a.lon : b.lon) &&
            latitude >= (a.lat < b.lat ? a.lat : b.lat) &&
            latitude <= (a.lat > b.lat ? a.lat : b.lat)) {
          return true;
        }
        if ((a.lat > latitude) != (b.lat > latitude) &&
            longitude <
                (b.lon - a.lon) * (latitude - a.lat) / (b.lat - a.lat) +
                    a.lon) {
          inside = !inside;
        }
      }
    }
    return inside;
  }

  List<dynamic> toJson() => [
    for (final p in pieces)
      [
        for (final c in p) [c.lat, c.lon],
      ],
  ];
  factory RegionBoundary.fromJson(List<dynamic> json) => RegionBoundary([
    for (final piece in json)
      [
        for (final c in piece as List)
          (lat: (c[0] as num).toDouble(), lon: (c[1] as num).toDouble()),
      ],
  ]);

  static RegionBoundary fromOsm(
    MosqueRegion region,
    List<Map<String, dynamic>> elements,
  ) {
    final pieces = <List<({double lat, double lon})>>[];
    final sourceId = region.sourceType == 'way'
        ? region.id
        : region.id - 3600000000;
    for (final e in elements) {
      if (e['id'] != sourceId ||
          e['type'] != (region.sourceType == 'way' ? 'way' : 'relation')) {
        continue;
      }
      final geometries = <List>[];
      if (e['type'] == 'way') {
        if (e['geometry'] is List) geometries.add(e['geometry'] as List);
      } else {
        for (final m in e['members'] as List? ?? []) {
          if (!['outer', 'inner', ''].contains(m['role'])) continue;
          if (m['type'] == 'relation') return const RegionBoundary([]);
          if (m['type'] != 'way') continue;
          if (m['geometry'] is! List) return const RegionBoundary([]);
          geometries.add(m['geometry'] as List);
        }
      }
      for (final geometry in geometries) {
        final piece = <({double lat, double lon})>[];
        for (final point in geometry) {
          if (point is! Map || point['lat'] is! num || point['lon'] is! num) {
            return const RegionBoundary([]);
          }
          piece.add((
            lat: (point['lat'] as num).toDouble(),
            lon: (point['lon'] as num).toDouble(),
          ));
        }
        if (piece.length >= 2) pieces.add(piece);
      }
    }
    // Missing/open boundary fragments cannot safely identify an offline region.
    final endpoints = <String, int>{};
    for (final piece in pieces) {
      for (final p in [piece.first, piece.last]) {
        final key = '${p.lat.toStringAsFixed(7)},${p.lon.toStringAsFixed(7)}';
        endpoints[key] = (endpoints[key] ?? 0) + 1;
      }
    }
    if (endpoints.values.any((count) => count.isOdd)) {
      return const RegionBoundary([]);
    }
    return RegionBoundary(pieces);
  }
}
