/// Mapbox Directions API'da ishlatiladigan marshrut profillari.
enum DirectionsProfile {
  /// Avtomobil.
  driving('driving'),

  /// Avtomobil, tirbandlik hisobga olingan holda.
  drivingTraffic('driving-traffic'),

  /// Piyoda.
  walking('walking'),

  /// Velosiped.
  cycling('cycling');

  const DirectionsProfile(this.path);

  /// So'rov manzilidagi profil nomi.
  final String path;
}
