part of 'prayer_bloc.dart';

sealed class PrayerEvent {
  const PrayerEvent();
}

final class PrayerLoadRequested extends PrayerEvent {
  PrayerLoadRequested(this.settings, {this.force = false});
  final AppSettings settings;
  final bool force;
  // Errors are handled by PrayerState; callers may await refresh completion.
  final Completer<void> completion = Completer<void>();
  Future<void> get done => completion.future;
}

final class PrayerCacheClearRequested extends PrayerEvent {
  PrayerCacheClearRequested();
  final Completer<void> completion = Completer<void>();
  Future<void> get done => completion.future;
}

final class PrayerClockTicked extends PrayerEvent {
  const PrayerClockTicked(this.now);
  final DateTime now;
}

final class _PrayerCachesCleared extends PrayerEvent {
  const _PrayerCachesCleared();
}
