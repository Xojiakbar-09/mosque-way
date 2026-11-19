part of 'map_bloc.dart';

const _keep = Object();

class MapState {
  const MapState({
    this.catalog,
    this.position,
    this.selected,
    this.route,
    this.profile = DirectionsProfile.driving,
    this.preset = MapLightPreset.day,
    this.is3D = false,
    this.query = '',
    this.results = const [],
    this.showResults = false,
    this.locationLoading = false,
    this.regionLoading = false,
    this.searchLoading = false,
    this.routeLoading = false,
    this.errorKey,
    this.searchErrorKey,
    this.routeErrorKey,
    this.cameraRevision = 0,
  });
  final MosqueCatalog? catalog;
  final Position? position;
  final Mosque? selected;
  final DirectionsRoute? route;
  final DirectionsProfile profile;
  final MapLightPreset preset;
  final bool is3D,
      showResults,
      locationLoading,
      regionLoading,
      searchLoading,
      routeLoading;
  final String query;
  final List<Mosque> results;
  final String? errorKey, searchErrorKey, routeErrorKey;
  final int cameraRevision;

  MapState copyWith({
    Object? catalog = _keep,
    Position? position,
    Object? selected = _keep,
    Object? route = _keep,
    DirectionsProfile? profile,
    MapLightPreset? preset,
    bool? is3D,
    String? query,
    List<Mosque>? results,
    bool? showResults,
    bool? locationLoading,
    bool? regionLoading,
    bool? searchLoading,
    bool? routeLoading,
    Object? errorKey = _keep,
    Object? searchErrorKey = _keep,
    Object? routeErrorKey = _keep,
    int? cameraRevision,
  }) => MapState(
    catalog: identical(catalog, _keep)
        ? this.catalog
        : catalog as MosqueCatalog?,
    position: position ?? this.position,
    selected: identical(selected, _keep) ? this.selected : selected as Mosque?,
    route: identical(route, _keep) ? this.route : route as DirectionsRoute?,
    profile: profile ?? this.profile,
    preset: preset ?? this.preset,
    is3D: is3D ?? this.is3D,
    query: query ?? this.query,
    results: List.unmodifiable(results ?? this.results),
    showResults: showResults ?? this.showResults,
    locationLoading: locationLoading ?? this.locationLoading,
    regionLoading: regionLoading ?? this.regionLoading,
    searchLoading: searchLoading ?? this.searchLoading,
    routeLoading: routeLoading ?? this.routeLoading,
    errorKey: identical(errorKey, _keep) ? this.errorKey : errorKey as String?,
    searchErrorKey: identical(searchErrorKey, _keep)
        ? this.searchErrorKey
        : searchErrorKey as String?,
    routeErrorKey: identical(routeErrorKey, _keep)
        ? this.routeErrorKey
        : routeErrorKey as String?,
    cameraRevision: cameraRevision ?? this.cameraRevision,
  );
}
