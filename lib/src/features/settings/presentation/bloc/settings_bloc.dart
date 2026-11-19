import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/cache/cache_maintenance.dart';
import '../../repository/app_settings.dart';
import '../../repository/settings_repository.dart';
part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc(this.repository, this.uid)
    : super(SettingsState.from(repository.read(uid))) {
    on<SettingsEvent>((event, emit) async {
      // Serialize ALL settings commands, including cache clearing and selection.
      if (event is SettingsMadhhabSelected) {
        emit(_state(selected: event.madhhab));
        return;
      }
      emit(_state(saving: true));
      try {
        if (event is SettingsUpdateRequested) {
          await repository.save(uid, event.settings);
          if (!emit.isDone) emit(_state(settings: event.settings));
          if (!event.completion.isCompleted) event.completion.complete();
        } else if (event is SettingsCachesClearRequested) {
          await CacheMaintenance.clearDownloadedData();
          if (!emit.isDone) {
            emit(_state(cacheRevision: state.cacheRevision + 1));
          }
        }
      } catch (error, stack) {
        if (!emit.isDone) emit(_state(error: 'saveError'));
        if (event is SettingsUpdateRequested && !event.completion.isCompleted) {
          event.completion.completeError(error, stack);
        }
      }
    }, transformer: (events, mapper) => events.asyncExpand(mapper));
  }
  final SettingsRepository repository;
  final String uid;
  SettingsState _state({
    AppSettings? settings,
    bool saving = false,
    String? error,
    Madhhab? selected,
    int? cacheRevision,
  }) => SettingsState.from(
    settings ?? state,
    saving: saving,
    errorKey: error,
    selectedMadhhab: selected ?? state.selectedMadhhab,
    cacheRevision: cacheRevision ?? state.cacheRevision,
  );
}
