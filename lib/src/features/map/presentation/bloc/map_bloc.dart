import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/cache/cache_policy.dart';
import '../../../../core/cache/cache_maintenance.dart';
import '../../../../core/utils/service/location_service.dart';
import '../../../settings/repository/app_settings.dart';
import '../../repository/directions_profile.dart';
import '../../repository/directions_repository.dart';
import '../../repository/directions_route.dart';
import '../../repository/map_repository.dart';
import '../../repository/mosque.dart';
import '../../repository/mosque_catalog.dart';
import '../../repository/overpass_service.dart';
import '../../repository/mosque_search.dart';
import '../map_light_preset.dart';

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  MapBloc({
    required AppSettings defaults,
    MapRepository? repository,
    DirectionsRepository? directions,
    LocationService? locationService,
  }) : repository = repository ?? MapRepositoryImpl(),
       directions = directions ?? DirectionsRepositoryImpl(),
       locationService = locationService ?? const LocationService(),
       super(
         MapState(
           profile: defaults.routeProfile,
           preset: defaults.mapPreset,
           is3D: defaults.map3D,
         ),
       ) {
    _cacheSubscription = CacheMaintenance.cleared.listen((_) {
      if (!isClosed) add(const _MapCachesCleared());
    });
    on<_MapCachesCleared>((event, emit) {
      ++_regionGeneration;
      ++_locationGeneration;
      ++_routeGeneration;
      this.repository.invalidate();
      emit(
        state.copyWith(
          catalog: null,
          selected: null,
          route: null,
          results: [],
          showResults: false,
          locationLoading: false,
          regionLoading: false,
          routeLoading: false,
          errorKey: null,
        ),
      );
    });
    on<MapStarted>((event, emit) async {
      _timer ??= Timer.periodic(const Duration(minutes: 1), (_) {
        if (!isClosed) add(const _MapCacheChecked());
      });
      final generation = _regionGeneration;
      final cached = await this.repository.restoreLast();
      if (emit.isDone ||
          generation != _regionGeneration ||
          state.catalog != null ||
          cached == null) {
        return;
      }
      emit(state.copyWith(catalog: cached));
    });
    on<MapLocateRequested>(_locate);
    on<MapRegionRefreshRequested>((event, emit) async {
      final position = state.position;
      if (position == null) {
        add(MapLocateRequested(force: event.force));
        return;
      }
      if (state.regionLoading) return;
      await _loadRegion(position, emit, force: event.force);
    });
    on<_MapCatalogReceived>((event, emit) {
      if (event.generation != _regionGeneration || !state.regionLoading) return;
      _publishCatalog(event.catalog, emit);
    });
    on<MapSearchChanged>((event, emit) => _search(event.query, emit));
    on<MapMosqueSelected>((event, emit) {
      ++_routeGeneration;
      emit(
        state.copyWith(
          selected: event.mosque,
          route: null,
          query: event.mosque.name,
          results: [],
          showResults: false,
          searchLoading: false,
          routeLoading: false,
          cameraRevision: state.cameraRevision + 1,
        ),
      );
    });
    on<MapProfileChanged>((event, emit) {
      if (event.profile == state.profile) return;
      ++_routeGeneration;
      emit(
        state.copyWith(
          profile: event.profile,
          route: null,
          routeLoading: false,
          routeErrorKey: null,
        ),
      );
    });
    on<MapPresetChanged>(
      (event, emit) => emit(state.copyWith(preset: event.preset)),
    );
    on<Map3DChanged>(
      (event, emit) => emit(state.copyWith(is3D: event.enabled)),
    );
    on<MapDefaultsChanged>((event, emit) {
      final s = event.settings;
      if (s.routeProfile != state.profile) ++_routeGeneration;
      emit(
        state.copyWith(
          profile: s.routeProfile,
          preset: s.mapPreset,
          is3D: s.map3D,
          route: s.routeProfile != state.profile ? null : state.route,
          routeLoading: s.routeProfile != state.profile
              ? false
              : state.routeLoading,
        ),
      );
    });
    on<MapRouteRequested>(_route);
    on<_MapCacheChecked>((event, emit) {
      final catalog = state.catalog;
      if (catalog == null || CachePolicy.isFresh(catalog.savedAt)) return;
      ++_routeGeneration;
      emit(
        state.copyWith(
          catalog: null,
          selected: null,
          route: null,
          routeLoading: false,
          results: [],
        ),
      );
      add(const MapRegionRefreshRequested(force: false));
    });
  }

  final MapRepository repository;
  final DirectionsRepository directions;
  final LocationService locationService;
  Timer? _timer;
  StreamSubscription<void>? _cacheSubscription;
  int _regionGeneration = 0, _locationGeneration = 0, _routeGeneration = 0;
  final Set<Completer<DirectionsRoute?>> _routeRequests = {};

  Future<Position> _position() async {
    final permission = await locationService.checkPermission();
    if (permission != LocationPermissionStatus.granted) {
      throw _MapLocationFailure(switch (permission) {
        LocationPermissionStatus.serviceDisabled => 'gpsDisabled',
        LocationPermissionStatus.deniedForever => 'locationPermanentlyDenied',
        _ => 'permissionError',
      });
    }
    return repository.getCurrentPosition();
  }

  Future<void> _locate(MapLocateRequested event, Emitter<MapState> emit) async {
    if (state.locationLoading) return;
    final generation = ++_locationGeneration;
    ++_routeGeneration;
    emit(
      state.copyWith(
        locationLoading: true,
        selected: null,
        route: null,
        routeLoading: false,
        query: '',
        results: [],
        showResults: false,
        errorKey: null,
        searchErrorKey: null,
      ),
    );
    try {
      final position = await _position();
      if (emit.isDone || generation != _locationGeneration) return;
      emit(
        state.copyWith(
          position: position,
          locationLoading: false,
          cameraRevision: state.cameraRevision + 1,
        ),
      );
      await _loadRegion(position, emit, force: event.force);
    } catch (error) {
      if (!emit.isDone && generation == _locationGeneration) {
        emit(
          state.copyWith(
            locationLoading: false,
            errorKey: error is _MapLocationFailure
                ? error.key
                : 'locationLoadError',
          ),
        );
      }
    }
  }

  Future<void> _loadRegion(
    Position position,
    Emitter<MapState> emit, {
    required bool force,
  }) async {
    final generation = ++_regionGeneration;
    emit(state.copyWith(regionLoading: true, errorKey: null));
    try {
      final catalog = await repository.loadForLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        forceRefresh: force,
        onCached: (cached) {
          if (!isClosed) add(_MapCatalogReceived(cached, generation));
        },
      );
      if (emit.isDone || generation != _regionGeneration) return;
      _publishCatalog(catalog, emit);
      emit(state.copyWith(regionLoading: false));
    } catch (error) {
      if (!emit.isDone && generation == _regionGeneration) {
        emit(
          state.copyWith(
            regionLoading: false,
            errorKey: error is OverpassException
                ? error.message
                : 'mosqueLoadError',
          ),
        );
      }
    }
  }

  void _publishCatalog(MosqueCatalog catalog, Emitter<MapState> emit) {
    final changed = state.catalog?.region.key != catalog.region.key;
    if (changed) ++_routeGeneration;
    emit(
      state.copyWith(
        catalog: catalog,
        errorKey: null,
        selected: changed ? null : state.selected,
        route: changed ? null : state.route,
        routeLoading: changed ? false : state.routeLoading,
      ),
    );
    if (state.showResults) _search(state.query, emit);
  }

  void _search(String query, Emitter<MapState> emit) {
    final catalog = state.catalog;
    final hasQuery = query.trim().isNotEmpty;
    emit(
      state.copyWith(
        query: query,
        showResults: hasQuery,
        searchLoading: false,
        results: hasQuery && catalog != null
            ? MosqueSearch.find(catalog.mosques, query)
            : [],
        searchErrorKey: hasQuery && catalog == null
            ? (state.regionLoading ? 'regionLoading' : 'mosqueLoadError')
            : null,
      ),
    );
  }

  Future<void> _route(MapRouteRequested event, Emitter<MapState> emit) async {
    _routeRequests.add(event.completion);
    DirectionsRoute? result;
    final generation = ++_routeGeneration;
    emit(
      state.copyWith(
        routeLoading: true,
        routeErrorKey: null,
        route: null,
        profile: event.profile,
      ),
    );
    try {
      final position = await _position();
      if (emit.isDone || generation != _routeGeneration) return;
      final route = await directions.getRoute(
        profile: event.profile,
        fromLatitude: position.latitude,
        fromLongitude: position.longitude,
        toLatitude: event.mosque.latitude,
        toLongitude: event.mosque.longitude,
      );
      if (emit.isDone || generation != _routeGeneration) return;
      result = route;
      emit(
        state.copyWith(
          position: position,
          route: route,
          routeLoading: false,
          routeErrorKey: route == null ? 'routeError' : null,
        ),
      );
    } catch (_) {
      if (!emit.isDone && generation == _routeGeneration) {
        emit(state.copyWith(routeLoading: false, routeErrorKey: 'routeError'));
      }
    } finally {
      if (!event.completion.isCompleted) event.completion.complete(result);
      _routeRequests.remove(event.completion);
    }
  }

  @override
  Future<void> close() async {
    ++_locationGeneration;
    ++_regionGeneration;
    ++_routeGeneration;
    _timer?.cancel();
    await _cacheSubscription?.cancel();
    for (final completion in _routeRequests) {
      if (!completion.isCompleted) completion.complete(null);
    }
    repository.dispose();
    directions.dispose();
    return super.close();
  }
}

class _MapLocationFailure implements Exception {
  const _MapLocationFailure(this.key);
  final String key;
}
