import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/cache/cache_maintenance.dart';
import '../../../../core/cache/cache_policy.dart';

import '../../repository/prayer_location.dart';
import '../../repository/prayer_location_service.dart';
import '../../repository/prayer_repository.dart';
import '../../repository/prayer_schedule.dart';
import '../../../settings/repository/app_settings.dart';

part 'prayer_event.dart';
part 'prayer_state.dart';

class PrayerBloc extends Bloc<PrayerEvent, PrayerState> {
  PrayerBloc(this.repository, {PrayerLocationService? locationService})
    : locationService = locationService ?? PrayerLocationService(),
      super(const PrayerState()) {
    on<PrayerLoadRequested>(_onLoad);
    on<PrayerClockTicked>((event, emit) {
      final schedule = state.schedule;
      final settings = _settings;
      if (settings != null &&
          schedule != null &&
          !state.loading &&
          (!CachePolicy.isFresh(schedule.savedAt, now: event.now) ||
              schedule.dayAt(event.now) == null)) {
        add(PrayerLoadRequested(settings));
      }
    });
    on<_PrayerCachesCleared>((event, emit) {
      ++_generation;
      emit(const PrayerState());
    });
    _cacheSubscription = CacheMaintenance.cleared.listen((_) {
      if (!isClosed) add(const _PrayerCachesCleared());
    });
    on<PrayerCacheClearRequested>(_onClear);
  }
  final PrayerRepository repository;
  final PrayerLocationService locationService;
  int _generation = 0;
  AppSettings? _settings;
  StreamSubscription<void>? _cacheSubscription;
  StreamSubscription<Position>? _positions;
  DateTime? _lastLocationRefresh;
  void _watchLocation() {
    if (_positions != null) return;
    _positions =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            distanceFilter: 2000,
          ),
        ).listen((position) {
          final last = state.schedule?.location;
          final settings = _settings;
          if (isClosed || state.loading || last == null || settings == null) {
            return;
          }
          final now = DateTime.now();
          if (_lastLocationRefresh != null &&
              now.difference(_lastLocationRefresh!) <
                  const Duration(seconds: 30)) {
            return;
          }
          if (Geolocator.distanceBetween(
                last.latitude,
                last.longitude,
                position.latitude,
                position.longitude,
              ) >
              2000) {
            _lastLocationRefresh = now;
            add(PrayerLoadRequested(settings));
          }
        }, onError: (Object _) {});
  }

  bool get isLoading => state.loading;
  Future<void> _onLoad(
    PrayerLoadRequested event,
    Emitter<PrayerState> emit,
  ) async {
    try {
      await _load(event.settings, emit, force: event.force);
      event.completion.complete();
    } catch (_) {
      if (!emit.isDone) emit(const PrayerState(message: 'networkError'));
      event.completion.complete();
    }
  }

  Future<void> _load(
    AppSettings settings,
    Emitter<PrayerState> emit, {
    bool force = false,
  }) async {
    _settings = settings;
    final madhhab = settings.madhhab;
    if (madhhab == null || isClosed) return;
    final generation = ++_generation;
    final restored = repository.cached(madhhab, settings.calculationMethod);
    emit(
      PrayerState(
        schedule: restored,
        loading: true,
        fromCache: restored != null,
      ),
    );
    PrayerLocation? location;
    try {
      location = await locationService.current();
      if (isClosed || emit.isDone || generation != _generation) return;
      final matching = repository.cached(
        madhhab,
        settings.calculationMethod,
        location: location,
      );
      // Immediately remove a calendar belonging to a previous city.
      emit(
        PrayerState(
          schedule: matching,
          loading: true,
          fromCache: matching != null,
          locationConfirmed: true,
        ),
      );
      _watchLocation();
      final result = await repository.load(
        location,
        madhhab,
        settings.calculationMethod,
        force: force,
      );
      if (isClosed || emit.isDone || generation != _generation) return;
      emit(
        PrayerState(
          schedule: result.schedule,
          fromCache: result.fromCache,
          locationConfirmed: true,
          message: result.saveFailed ? 'notCached' : null,
        ),
      );
    } catch (error) {
      if (isClosed || emit.isDone || generation != _generation) return;
      final fallback = location == null
          ? restored
          : repository.cached(
              madhhab,
              settings.calculationMethod,
              location: location,
            );
      emit(
        PrayerState(
          schedule: fallback,
          fromCache: fallback != null,
          locationConfirmed: location != null,
          message: location == null ? 'permissionError' : 'networkError',
        ),
      );
    }
  }

  Future<void> _onClear(
    PrayerCacheClearRequested event,
    Emitter<PrayerState> emit,
  ) async {
    final generation = ++_generation;
    try {
      await repository.clear();
      if (!emit.isDone && generation == _generation) emit(const PrayerState());
      event.completion.complete();
    } catch (error, stack) {
      event.completion.completeError(error, stack);
    }
  }

  @override
  Future<void> close() async {
    ++_generation;
    await _cacheSubscription?.cancel();
    await _positions?.cancel();
    repository.dispose();
    return super.close();
  }
}
