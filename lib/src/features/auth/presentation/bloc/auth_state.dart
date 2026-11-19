part of 'auth_bloc.dart';

class AuthState {
  const AuthState({
    this.user,
    this.busy = false,
    this.errorKey,
    this.resetRevision = 0,
  });
  final User? user;
  final bool busy;
  final String? errorKey;
  final int resetRevision;
}
