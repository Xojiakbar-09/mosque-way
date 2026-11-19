import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maps/src/core/utils/service/location_service.dart';

import '../../repository/promision_repository.dart';
import 'promision_event.dart';
import 'promision_state.dart';

class PromisionBloc extends Bloc<PromisionEvent, PromisionState> {
  PromisionBloc() : super(const PromisionState()) {
    on<PromisionCheckRequested>(_onCheckRequested);
  }

  final PromisionRepository _repository = PromisionRepositoryImpl();

  Future<void> _onCheckRequested(
    PromisionCheckRequested event,
    Emitter<PromisionState> emit,
  ) async {
    // Tekshirish boshlandi (message va natijalar tozalanadi).
    emit(const PromisionState());

    try {
      final status = await _repository.checkPermission();
      if (emit.isDone) return;

      switch (status) {
        case LocationPermissionStatus.serviceDisabled:
          emit(
            state.copyWith(
              status: PromisionStatus.error,
              message: "Telefoningizda GPS o'chirilgan. GPSni yoqing.",
            ),
          );
          return;
        case LocationPermissionStatus.denied:
          emit(
            state.copyWith(
              status: PromisionStatus.error,
              message: "Joylashuvga ruxsat berilmadi.",
            ),
          );
          return;
        case LocationPermissionStatus.deniedForever:
          emit(
            state.copyWith(
              status: PromisionStatus.error,
              message: "Ilova sozlamalaridan GPS ruxsatini yoqing.",
            ),
          );
          return;
        case LocationPermissionStatus.granted:
          break;
      }

      final position = await _repository.getCurrentPosition();
      PlaceInfo place;
      try {
        place = await _repository
            .getPlaceInfo(position)
            .timeout(const Duration(seconds: 8));
      } catch (_) {
        place = const PlaceInfo(country: '', city: '');
      }
      if (emit.isDone) return;

      emit(
        state.copyWith(
          status: PromisionStatus.granted,
          country: place.country,
          city: place.city,
        ),
      );
    } catch (_) {
      if (emit.isDone) return;
      emit(
        state.copyWith(
          status: PromisionStatus.error,
          message: "Joylashuvni aniqlab bo'lmadi. GPSni tekshiring.",
        ),
      );
    }
  }
}
