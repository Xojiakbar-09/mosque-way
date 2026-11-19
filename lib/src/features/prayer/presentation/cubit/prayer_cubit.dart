import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repository/prayer_location.dart';
import '../../repository/prayer_location_service.dart';
import '../../repository/prayer_repository.dart';
import '../../repository/prayer_schedule.dart';
import '../../../settings/repository/app_settings.dart';

class PrayerState {
  const PrayerState({
    this.schedule,
    this.loading = false,
    this.fromCache = false,
    this.locationConfirmed = false,
    this.message,
  });
  final PrayerSchedule? schedule;
  final bool loading, fromCache, locationConfirmed;
  final String? message;
}

class PrayerCubit extends Cubit<PrayerState> {
  PrayerCubit(this.repository, {PrayerLocationService? locationService})
    : locationService = locationService ?? PrayerLocationService(),
      super(const PrayerState());
  final PrayerRepository repository;
  final PrayerLocationService locationService;
  int _generation = 0;
  bool get isLoading => state.loading;
  Future<void> load(AppSettings settings, {bool force = false}) async {
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
      if (isClosed || generation != _generation) return;
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
      final result = await repository.load(
        location,
        madhhab,
        settings.calculationMethod,
        force: force,
      );
      if (isClosed || generation != _generation) return;
      emit(
        PrayerState(
          schedule: result.schedule,
          fromCache: result.fromCache,
          locationConfirmed: true,
          message: result.saveFailed ? 'notCached' : null,
        ),
      );
    } catch (error) {
      if (isClosed || generation != _generation) return;
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

  Future<void> clearCache() async {
    ++_generation;
    await repository.clear();
    if (!isClosed) emit(const PrayerState());
  }

  @override
  Future<void> close() {
    ++_generation;
    repository.dispose();
    return super.close();
  }
}
