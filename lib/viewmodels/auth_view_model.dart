import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/utils/app_logger.dart';
import '../services/auth_service.dart';
import 'session_view_model.dart';

enum AuthMode { login, signup }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required SessionViewModel session, AuthService? authService})
    : _session = session,
      _auth = authService ?? session.authService;

  final SessionViewModel _session;
  final AuthService _auth;

  AuthMode mode = AuthMode.login;
  bool isBusy = false;
  String? errorMessage;

  void toggleMode() {
    AppLogger.info('Auth mode toggled: $mode');
    mode = mode == AuthMode.login ? AuthMode.signup : AuthMode.login;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> submit({required String email, required String password}) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      errorMessage = 'Please enter your email and password.';
      notifyListeners();
      return;
    }
    await _run(() async {
      if (mode == AuthMode.login) {
        AppLogger.info('Submitting login');
        await _auth.signInWithEmail(email.trim(), password.trim());
      } else {
        AppLogger.info('Submitting signup');
        await _auth.signUpWithEmail(email.trim(), password.trim());
      }
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      isBusy = true;
      errorMessage = null;
      notifyListeners();
      await action();
    } on FirebaseAuthException catch (e) {
      AppLogger.warn('Firebase auth exception: ${e.code}');
      errorMessage = _readable(e.code);
    } catch (e, st) {
      AppLogger.error('Unexpected auth failure', e, st);
      errorMessage = 'Something went wrong. Please try again.';
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  String _readable(String code) => switch (code) {
    'user-not-found' => 'No account found for this email.',
    'wrong-password' => 'Incorrect password.',
    'email-already-in-use' => 'An account already exists for this email.',
    'weak-password' => 'Password should be at least 6 characters.',
    'invalid-email' => 'Please enter a valid email address.',
    'too-many-requests' => 'Too many attempts. Please try again later.',
    'network-request-failed' => 'No internet connection.',
    _ => 'Authentication failed. Please try again.',
  };

  // ignore: unused_element
  void _signOut() => _session.signOut();
}
