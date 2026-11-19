part of 'auth_bloc.dart';

sealed class AuthEvent {
  const AuthEvent();
}

final class _AuthUserChanged extends AuthEvent {
  const _AuthUserChanged(this.user);
  final User? user;
}

final class AuthGoogleRequested extends AuthEvent {
  const AuthGoogleRequested();
}

final class AuthGitHubRequested extends AuthEvent {
  const AuthGitHubRequested();
}

final class AuthEmailRequested extends AuthEvent {
  const AuthEmailRequested(this.email, this.password, {this.register = false});
  final String email, password;
  final bool register;
}

final class AuthResetRequested extends AuthEvent {
  const AuthResetRequested(this.email);
  final String email;
}

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

final class AuthErrorCleared extends AuthEvent {
  const AuthErrorCleared();
}
