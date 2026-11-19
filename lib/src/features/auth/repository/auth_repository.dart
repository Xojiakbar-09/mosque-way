import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/utils/service/google_auth_service.dart';

class AuthRepository {
  User? get currentUser => GoogleAuthService.currentUser;
  Stream<User?> watch() => GoogleAuthService.authStateChanges();
  Future<User?> google() => GoogleAuthService.signInWithGoogle();
  Future<User?> github() => GoogleAuthService.signInWithGitHub();
  Future<User?> email(
    String email,
    String password, {
    required bool register,
  }) => register
      ? GoogleAuthService.registerWithEmail(email: email, password: password)
      : GoogleAuthService.signInWithEmail(email: email, password: password);
  Future<void> reset(String email) => GoogleAuthService.resetPassword(email);
  Future<void> signOut() => GoogleAuthService.signOut();
}
