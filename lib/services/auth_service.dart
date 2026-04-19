import 'package:firebase_auth/firebase_auth.dart';

import '../core/utils/app_logger.dart';

/// Wraps Firebase Authentication — email/password only for Phase 2.
class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Emits the UID whenever auth state changes (null = signed out).
  Stream<String?> authStateChanges() {
    AppLogger.info('Subscribing to Firebase authStateChanges stream');
    return _auth.authStateChanges().map((u) {
      AppLogger.info('authStateChanges emitted uid=${u?.uid}');
      return u?.uid;
    });
  }

  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserEmail => _auth.currentUser?.email;

  Future<void> signInWithEmail(String email, String password) async {
    AppLogger.info('Attempting sign-in for $email');
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    AppLogger.info('Sign-in successful uid=${cred.user?.uid}');
  }

  Future<void> signUpWithEmail(String email, String password) async {
    AppLogger.info('Attempting sign-up for $email');
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    AppLogger.info('Sign-up successful uid=${cred.user?.uid}');
  }

  Future<void> signOut() {
    AppLogger.info('Signing out current user');
    return _auth.signOut();
  }
}
