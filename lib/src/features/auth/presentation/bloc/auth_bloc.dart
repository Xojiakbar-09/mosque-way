import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../repository/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this.repository) : super(AuthState(user: repository.currentUser)) {
    on<_AuthUserChanged>(
      (event, emit) => emit(
        AuthState(
          user: event.user,
          busy: state.busy,
          resetRevision: state.resetRevision,
        ),
      ),
    );
    on<AuthErrorCleared>(
      (event, emit) => emit(
        AuthState(
          user: state.user,
          busy: state.busy,
          resetRevision: state.resetRevision,
        ),
      ),
    );
    on<AuthGoogleRequested>(
      (event, emit) => _run(emit, () async {
        final user = await repository.google();
        if (user == null) {
          throw FirebaseAuthException(code: 'invalid-credential');
        }
      }),
    );
    on<AuthGitHubRequested>(
      (event, emit) => _run(emit, () async {
        await repository.github();
      }),
    );
    on<AuthEmailRequested>(
      (event, emit) => _run(emit, () async {
        await repository.email(
          event.email,
          event.password,
          register: event.register,
        );
      }),
    );
    on<AuthResetRequested>(
      (event, emit) =>
          _run(emit, () => repository.reset(event.email), reset: true),
    );
    on<AuthSignOutRequested>((event, emit) => _run(emit, repository.signOut));
    _subscription = repository.watch().listen(
      (user) {
        if (!isClosed) add(_AuthUserChanged(user));
      },
      onError: (Object error) {
        // Individual operations surface actionable errors; keep the last session.
      },
    );
  }
  final AuthRepository repository;
  StreamSubscription<User?>? _subscription;

  Future<void> _run(
    Emitter<AuthState> emit,
    Future<void> Function() operation, {
    bool reset = false,
  }) async {
    // Shared guard also protects operations of different event types.
    if (state.busy) return;
    emit(
      AuthState(
        user: state.user,
        busy: true,
        resetRevision: state.resetRevision,
      ),
    );
    String? errorKey;
    bool succeeded = false;
    try {
      await operation();
      succeeded = true;
    } on FirebaseAuthException catch (error) {
      if (![
        'web-context-cancelled',
        'popup-closed-by-user',
        'cancelled-popup-request',
      ].contains(error.code)) {
        errorKey = switch (error.code) {
          'invalid-email' => 'authInvalidEmail',
          'invalid-credential' ||
          'user-not-found' ||
          'wrong-password' => 'authInvalidCredentials',
          'email-already-in-use' ||
          'credential-already-in-use' ||
          'account-exists-with-different-credential' => 'authAccountExists',
          'weak-password' => 'authWeakPassword',
          'network-request-failed' => 'networkError',
          'too-many-requests' => 'authTooManyRequests',
          'operation-not-allowed' => 'authProviderDisabled',
          'user-disabled' => 'authUserDisabled',
          _ => 'authFailed',
        };
      }
    } on GoogleSignInException catch (error) {
      if (error.code.name != 'canceled') errorKey = 'authGoogleFailed';
    } catch (_) {
      errorKey = 'authFailed';
    }
    if (!emit.isDone) {
      emit(
        AuthState(
          user: repository.currentUser,
          errorKey: errorKey,
          resetRevision: state.resetRevision + (reset && succeeded ? 1 : 0),
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
