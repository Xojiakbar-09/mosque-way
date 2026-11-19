import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import '../../../core/widgets/entrance_transition.dart';
import '../repository/directions_route.dart';
import '../repository/mosque.dart';
import '../repository/mosque_catalog.dart';
import 'map_camera_fit.dart';
import 'map_light_preset.dart';
import 'map_style_layer.dart';
import 'mosque_marker_layer.dart';
import 'route_layer.dart';
import 'widgets/location_loading_banner.dart';
import 'widgets/map_side_controls.dart';
import 'widgets/mosque_info_sheet.dart';
import 'widgets/mosque_search_bar.dart';
import '../../settings/repository/app_settings.dart';
import '../../../core/localization/app_strings.dart';
import 'widgets/selected_mosque_bar.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/map_bloc.dart';

class MapPage extends StatelessWidget {
  const MapPage({
    super.key,
    this.defaults = const AppSettings(),
    this.active = true,
    this.locationKey,
  });
  final AppSettings defaults;
  final bool active;
  final String? locationKey;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => MapBloc(defaults: defaults)..add(const MapStarted()),
    child: _MapView(
      defaults: defaults,
      active: active,
      locationKey: locationKey,
    ),
  );
}

class _MapView extends StatefulWidget {
  const _MapView({
    required this.defaults,
    required this.active,
    this.locationKey,
  });
  final AppSettings defaults;
  final bool active;
  final String? locationKey;
  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  static final mb.Point _initialCenter = mb.Point(
    coordinates: mb.Position(69.2401, 41.2995),
  );
  final mb.ViewportController _viewportController = mb.ViewportController();
  final TextEditingController _searchController = TextEditingController();
  final MapStyleLayer _mapStyleLayer = MapStyleLayer();
  late final MosqueMarkerLayer _mosqueMarkers = MosqueMarkerLayer(
    onMosqueTap: _selectMosque,
  );
  final RouteLayer _routeLayer = RouteLayer();
  mb.MapboxMap? _mapboxMap;
  bool _mapStyleLoaded = false, _sheetOpen = false;
  int _renderGeneration = 0;
  Future<void> _renderQueue = Future<void>.value();
  MapState? _rendered;
  MapBloc get _bloc => context.read<MapBloc>();
  MapState get _state => _bloc.state;
  bool get _is3D => _state.is3D;
  bool get _isLoadingLocation => _state.locationLoading;
  bool get _isRegionLoading => _state.regionLoading;
  bool get _showSearchResults => _state.showResults;
  bool get _isSearchLoading => _state.searchLoading;
  String get _searchQuery => _state.query;
  String? get _searchError => _state.searchErrorKey == null
      ? null
      : AppStrings.of(context)(_state.searchErrorKey!);
  String? get _regionError =>
      _state.errorKey == null ? null : AppStrings.of(context)(_state.errorKey!);
  List<Mosque> get _searchResults => _state.results;
  Mosque? get _selectedMosque => _state.selected;
  DirectionsRoute? get _activeRoute => _state.route;
  MosqueCatalog? get _catalog => _state.catalog;
  MapLightPreset get _lightPreset => _state.preset;

  @override
  void didUpdateWidget(covariant _MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.defaults.mapPreset != widget.defaults.mapPreset ||
        oldWidget.defaults.routeProfile != widget.defaults.routeProfile ||
        oldWidget.defaults.map3D != widget.defaults.map3D) {
      _bloc.add(MapDefaultsChanged(widget.defaults));
    }
    if (widget.active &&
        (!oldWidget.active || widget.locationKey != oldWidget.locationKey)) {
      _goToMyLocation();
    }
  }

  @override
  void dispose() {
    ++_renderGeneration;
    _mosqueMarkers.dispose();
    _viewportController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onMapCreated(mb.MapboxMap map) {
    _mapboxMap = map;
    _goToMyLocation();
  }

  void _onStyleLoaded(mb.StyleLoadedEventData event) {
    _mosqueMarkers.resetStyle();
    _mapStyleLoaded = true;
    _rendered = null;
    _queueRender(_state);
  }

  // Native map updates are serialized. Stale queued states cannot redraw old routes.
  void _queueRender(MapState state) {
    final generation = ++_renderGeneration;
    _renderQueue = _renderQueue
        .then((_) async {
          if (!mounted || generation != _renderGeneration || !_mapStyleLoaded) {
            return;
          }
          final map = _mapboxMap;
          if (map == null) return;
          final previous = _rendered;
          if (_sheetOpen &&
              previous?.selected != null &&
              state.selected == null) {
            Navigator.of(context).pop();
          }
          if (_searchController.text != state.query) {
            _searchController.value = TextEditingValue(
              text: state.query,
              selection: TextSelection.collapsed(offset: state.query.length),
            );
          }
          if (previous?.preset != state.preset) {
            await _mapStyleLayer.applyLightPreset(map, state.preset);
          }
          if (!mounted || generation != _renderGeneration) return;
          if (previous?.catalog != state.catalog ||
              previous?.selected != state.selected) {
            final camera = await map.getCameraState();
            await _mosqueMarkers.setMosques(
              map,
              state.catalog?.mosques ?? [],
              zoom: camera.zoom,
              selectedMosque: state.selected,
            );
          }
          if (!mounted || generation != _renderGeneration) return;
          if (previous == null || previous.route != state.route) {
            if (state.route == null) {
              await _routeLayer.clear();
            } else {
              await _routeLayer.show(map, state.route!);
              if (!_sheetOpen) _fitRoute(state.route!);
            }
          }
          if (!mounted || generation != _renderGeneration) return;
          if (previous?.cameraRevision != state.cameraRevision &&
              state.cameraRevision > 0) {
            final mosque = state.selected;
            final position = state.position;
            if (mosque != null || position != null) {
              if (position != null) {
                await map.location.updateSettings(
                  mb.LocationComponentSettings(
                    enabled: true,
                    pulsingEnabled: true,
                    showAccuracyRing: true,
                  ),
                );
              }
              if (!mounted || generation != _renderGeneration) return;
              _moveCamera(
                center: mb.Point(
                  coordinates: mb.Position(
                    mosque?.longitude ?? position!.longitude,
                    mosque?.latitude ?? position!.latitude,
                  ),
                ),
                zoom: mosque == null ? 16 : 17,
                pitch: state.is3D ? 60 : 0,
                transition: const mb.FlyViewportTransition(
                  duration: Duration(milliseconds: 1200),
                ),
              );
            }
          } else if (previous?.is3D != state.is3D) {
            final camera = await map.getCameraState();
            if (!mounted || generation != _renderGeneration) return;
            _moveCamera(
              center: camera.center,
              zoom: state.is3D && camera.zoom < 16 ? 16 : camera.zoom,
              pitch: state.is3D ? 60 : 0,
              bearing: camera.bearing,
            );
          }
          _rendered = state;
        })
        .catchError((Object error) {
          debugPrint('Map render: $error');
          if (mounted) _showMessage(AppStrings.of(context)('markerError'));
        });
  }

  void _onCameraChanged(mb.CameraChangedEventData event) {
    _mosqueMarkers.updateZoom(event.cameraState.zoom).catchError((
      Object error,
    ) {
      debugPrint('Marker zoom: $error');
    });
  }

  void _onSearchChanged(String query) => _bloc.add(MapSearchChanged(query));
  void _loadRegionalData({bool forceRefresh = false}) =>
      _bloc.add(MapRegionRefreshRequested(force: forceRefresh));
  void _goToMyLocation({bool forceRefresh = false}) =>
      _bloc.add(MapLocateRequested(force: forceRefresh));
  void _onPresetSelected(MapLightPreset preset) =>
      _bloc.add(MapPresetChanged(preset));
  void _toggle3D() => _bloc.add(Map3DChanged(!_state.is3D));

  Future<void> _selectMosque(Mosque mosque) async {
    if (_sheetOpen) return;
    FocusScope.of(context).unfocus();
    _bloc.add(MapMosqueSelected(mosque));
    await _showMosqueInfo(mosque);
  }

  Future<void> _showMosqueInfo(Mosque mosque) async {
    if (!mounted || _sheetOpen) return;
    _sheetOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => BlocProvider.value(
          value: _bloc,
          child: MosqueInfoSheet(mosque: mosque),
        ),
      );
    } finally {
      _sheetOpen = false;
      if (mounted && _activeRoute != null) _fitRoute(_activeRoute!);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _moveCamera({
    required mb.Point center,
    required double zoom,
    required double pitch,
    double bearing = 0,
    mb.ViewportTransition transition = const mb.EasingViewportTransition(
      duration: Duration(milliseconds: 350),
    ),
  }) {
    _viewportController.moveTo(
      mb.CameraViewportState(
        center: center,
        zoom: zoom,
        pitch: pitch,
        bearing: bearing,
      ),
      transition: transition,
    );
  }

  void _fitRoute(DirectionsRoute route) {
    final fit = fitRouteCamera(
      points: route.points,
      viewSize: MediaQuery.sizeOf(context),
    );
    if (fit == null) return;

    _moveCamera(center: fit.center, zoom: fit.zoom, pitch: 0);
    if (_state.is3D) _bloc.add(const Map3DChanged(false));
  }

  Future<void> _changeZoom(double change) async {
    final camera = await _mapboxMap?.getCameraState();
    if (camera == null || !mounted) return;

    _moveCamera(
      center: camera.center,
      zoom: (camera.zoom + change).clamp(0.0, 22.0).toDouble(),
      pitch: camera.pitch,
      bearing: camera.bearing,
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<MapBloc>();
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final showOverlays = !keyboardOpen && !_showSearchResults;
    final selectedMosque = _selectedMosque;

    return BlocListener<MapBloc, MapState>(
      listener: (_, state) => _queueRender(state),
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Positioned.fill(
                  child: mb.MapWidget(
                    key: const ValueKey("mainMap"),
                    styleUri: mb.MapboxStyles.STANDARD,
                    viewport: mb.CameraViewportState(
                      center: _initialCenter,
                      zoom: 12,
                      pitch: _is3D ? 60 : 0,
                    ),
                    viewportController: _viewportController,
                    onMapCreated: _onMapCreated,
                    onStyleLoadedListener: _onStyleLoaded,
                    onCameraChangeListener: _onCameraChanged,
                  ),
                ),
                if (showOverlays)
                  Positioned(
                    right: 16,
                    top: 92,
                    bottom: 100,
                    child: MapSideControls(
                      preset: _lightPreset,
                      onPresetSelected: _onPresetSelected,
                      is3D: _is3D,
                      onZoomIn: () => _changeZoom(1),
                      onZoomOut: () => _changeZoom(-1),
                      onToggle3D: _toggle3D,
                      onMyLocation: () => _goToMyLocation(),
                    ),
                  ),
                if (_isLoadingLocation && showOverlays)
                  const Positioned(
                    top: 92,
                    left: 16,
                    right: 86,
                    child: LocationLoadingBanner(),
                  ),
                if (showOverlays &&
                    !_isLoadingLocation &&
                    (_regionError != null || _catalog?.notice != null))
                  Positioned(
                    top: 92,
                    left: 16,
                    right: 86,
                    child: Material(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: .95),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                AppStrings.of(context)(
                                  _regionError ?? _catalog!.notice!,
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            IconButton(
                              tooltip: AppStrings.of(context)('retry'),
                              onPressed: _isRegionLoading
                                  ? null
                                  : () => _loadRegionalData(forceRefresh: true),
                              icon: const Icon(Icons.refresh_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (selectedMosque != null && showOverlays)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 28,
                    child: SelectedMosqueBar(
                      mosque: selectedMosque,
                      route: _activeRoute,
                      onTap: () => _showMosqueInfo(selectedMosque),
                    ),
                  ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 12,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: math.max(0, constraints.maxHeight - 24),
                    ),
                    child: EntranceTransition(
                      child: MosqueSearchBar(
                        controller: _searchController,
                        error: _searchError,
                        onTap: () {
                          if (_searchController.text.trim().isNotEmpty &&
                              !_showSearchResults) {
                            _onSearchChanged(_searchController.text);
                          }
                        },
                        query: _searchQuery,
                        results: _searchResults,
                        showResults: _showSearchResults,
                        isLoading: _isSearchLoading,
                        onChanged: _onSearchChanged,
                        onSelected: _selectMosque,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
