part of 'prayer_bloc.dart';

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
