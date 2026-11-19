import 'mosque.dart';
import 'mosque_region.dart';

class MosqueCatalog {
  const MosqueCatalog({
    required this.region,
    required this.mosques,
    required this.boundary,
    required this.savedAt,
    this.fromCache = false,
    this.notice,
    this.locationConfirmed = true,
  });
  final MosqueRegion region;
  final List<Mosque> mosques;
  final RegionBoundary boundary;
  final DateTime savedAt;
  final bool fromCache;
  final String? notice;

  /// False only when showing the last downloaded region without confirming GPS.
  final bool locationConfirmed;

  MosqueCatalog cached({String? notice, bool locationConfirmed = true}) =>
      MosqueCatalog(
        region: region,
        mosques: mosques,
        boundary: boundary,
        savedAt: savedAt,
        fromCache: true,
        notice: notice,
        locationConfirmed: locationConfirmed,
      );

  Map<String, dynamic> toJson() => {
    'version': 1,
    'region': region.toJson(),
    'mosques': [for (final mosque in mosques) mosque.toJson()],
    'boundary': boundary.toJson(),
    'savedAt': savedAt.toUtc().toIso8601String(),
  };
  factory MosqueCatalog.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) throw const FormatException('Unsupported cache');
    return MosqueCatalog(
      region: MosqueRegion.fromJson(
        Map<String, dynamic>.from(json['region'] as Map),
      ),
      mosques: List.unmodifiable(
        (json['mosques'] as List).map(
          (e) => Mosque.fromJson(Map<String, dynamic>.from(e as Map)),
        ),
      ),
      boundary: RegionBoundary.fromJson(json['boundary'] as List),
      savedAt: DateTime.parse(json['savedAt'] as String),
      fromCache: true,
    );
  }
}
