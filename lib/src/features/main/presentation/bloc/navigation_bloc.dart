import 'package:bloc/bloc.dart';

class NavigationTabSelected {
  const NavigationTabSelected(this.index);
  final int index;
}

class NavigationState {
  const NavigationState({
    this.index = 0,
    this.mapOpened = false,
    this.hadithOpened = false,
  });
  final int index;
  final bool mapOpened, hadithOpened;
}

class NavigationBloc extends Bloc<NavigationTabSelected, NavigationState> {
  NavigationBloc() : super(const NavigationState()) {
    on<NavigationTabSelected>((event, emit) {
      if (event.index < 0 || event.index > 3) return;
      emit(
        NavigationState(
          index: event.index,
          mapOpened: state.mapOpened || event.index == 1,
          hadithOpened: state.hadithOpened || event.index == 2,
        ),
      );
    });
  }
}
