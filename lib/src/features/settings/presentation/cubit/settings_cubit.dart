import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repository/app_settings.dart';
import '../../repository/settings_repository.dart';

class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit(this.repository, this.uid) : super(repository.read(uid));
  final SettingsRepository repository;
  final String uid;

  /// Update only after successful persistence; failures can be shown by the UI.
  Future<void> update(AppSettings settings) async {
    await repository.save(uid, settings);
    if (!isClosed) emit(settings);
  }
}
