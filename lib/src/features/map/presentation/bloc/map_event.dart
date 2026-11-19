part of 'map_bloc.dart';

sealed class MapEvent {
  const MapEvent();
}

final class MapStarted extends MapEvent {
  const MapStarted();
}

final class MapLocateRequested extends MapEvent {
  const MapLocateRequested({this.force = false});
  final bool force;
}

final class MapRegionRefreshRequested extends MapEvent {
  const MapRegionRefreshRequested({this.force = true});
  final bool force;
}

final class MapSearchChanged extends MapEvent {
  const MapSearchChanged(this.query);
  final String query;
}

final class MapMosqueSelected extends MapEvent {
  const MapMosqueSelected(this.mosque);
  final Mosque mosque;
}

final class MapProfileChanged extends MapEvent {
  const MapProfileChanged(this.profile);
  final DirectionsProfile profile;
}

final class MapPresetChanged extends MapEvent {
  const MapPresetChanged(this.preset);
  final MapLightPreset preset;
}

final class Map3DChanged extends MapEvent {
  const Map3DChanged(this.enabled);
  final bool enabled;
}

final class MapRouteRequested extends MapEvent {
  MapRouteRequested(this.mosque, this.profile);
  final Mosque mosque;
  final DirectionsProfile profile;
  final Completer<DirectionsRoute?> completion = Completer<DirectionsRoute?>();
  Future<DirectionsRoute?> get done => completion.future;
}

final class MapDefaultsChanged extends MapEvent {
  const MapDefaultsChanged(this.settings);
  final AppSettings settings;
}

final class _MapCacheChecked extends MapEvent {
  const _MapCacheChecked();
}

final class _MapCatalogReceived extends MapEvent {
  const _MapCatalogReceived(this.catalog, this.generation);
  final MosqueCatalog catalog;
  final int generation;
}

final class _MapCachesCleared extends MapEvent {
  const _MapCachesCleared();
}
