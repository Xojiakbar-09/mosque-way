import 'package:bloc/bloc.dart';

sealed class AuthFormEvent {
  const AuthFormEvent();
}

final class AuthFormModeToggled extends AuthFormEvent {
  const AuthFormModeToggled();
}

final class AuthPasswordVisibilityToggled extends AuthFormEvent {
  const AuthPasswordVisibilityToggled();
}

class AuthFormState {
  const AuthFormState({this.register = false, this.hidePassword = true});
  final bool register, hidePassword;
}

class AuthFormBloc extends Bloc<AuthFormEvent, AuthFormState> {
  AuthFormBloc() : super(const AuthFormState()) {
    on<AuthFormModeToggled>(
      (event, emit) => emit(
        AuthFormState(
          register: !state.register,
          hidePassword: state.hidePassword,
        ),
      ),
    );
    on<AuthPasswordVisibilityToggled>(
      (event, emit) => emit(
        AuthFormState(
          register: state.register,
          hidePassword: !state.hidePassword,
        ),
      ),
    );
  }
}
