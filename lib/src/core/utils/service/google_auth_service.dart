import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool _initialized = false;

  /// Hozir tizimga kirgan foydalanuvchi (bo'lmasa `null`).
  static User? get currentUser => _auth.currentUser;

  static Stream<User?> authStateChanges() => _auth.authStateChanges();

  static Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return result.user;
  }

  static Future<User?> registerWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );
    final current = _auth.currentUser;
    final result = current != null && current.isAnonymous
        ? await current.linkWithCredential(credential)
        : await _auth.createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
    return result.user;
  }

  static Future<User?> signInWithGitHub() async {
    final provider = GithubAuthProvider();
    final result = await _auth.signInWithProvider(provider);
    return result.user;
  }

  static Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  /// Google Sign In'ni faqat bir marta ishga tushiradi.
  static Future<void> _ensureInitialized() async {
    if (_initialized) return;

    await _googleSignIn.initialize();
    _initialized = true;
  }

  /// Google akkaunt orqali kiradi.
  ///
  /// Authentication errors and cancellation propagate to AuthBloc.
  static Future<User?> signInWithGoogle() async {
    await _ensureInitialized();
    final googleUser = await _googleSignIn.authenticate();
    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final current = _auth.currentUser;
    final userCredential = current != null && current.isAnonymous
        ? await current.linkWithCredential(credential)
        : await _auth.signInWithCredential(credential);
    return userCredential.user;
  }

  /// Tizimdan chiqadi.
  static Future<void> signOut() async {
    await _auth.signOut();
    if (_initialized) {
      try {
        await _googleSignIn.signOut();
      } catch (error) {
        if (kDebugMode) debugPrint('Google sign out failed: $error');
      }
    }
  }
}
