import 'dart:async';
import 'package:bloc/bloc.dart';

class ClockTicked {
  const ClockTicked(this.now);
  final DateTime now;
}

class ClockBloc extends Bloc<ClockTicked, DateTime> {
  ClockBloc() : super(DateTime.now()) {
    on<ClockTicked>((event, emit) => emit(event.now));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isClosed) add(ClockTicked(DateTime.now()));
    });
  }
  Timer? _timer;
  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
