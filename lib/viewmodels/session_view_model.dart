import 'dart:async';

import 'package:flutter/material.dart';

import '../core/utils/app_logger.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firebase_bootstrap_service.dart';
import '../services/preferences_service.dart';
import '../services/profile_service.dart';

/// Single source of truth: bootstrap state, auth, and active user profile.
class SessionViewModel extends ChangeNotifier {
  SessionViewModel({
    required FirebaseBootstrapService bootstrapService,
    required AuthService authService,
    required ProfileService profileService,
    required PreferencesService preferencesService,
  }) : _bootstrap = bootstrapService,
       _auth = authService,
       _profileService = profileService,
       _preferences = preferencesService;

  final FirebaseBootstrapService _bootstrap;
  final AuthService _auth;
  final ProfileService _profileService;
  final PreferencesService _preferences;

  bool _isInitialized = false;
  bool _firebaseEnabled = false;
  bool _isAuthLoading = true;
  String? _uid;
  UserProfile _profile = UserProfile.empty();

  StreamSubscription<String?>? _authSub;
  StreamSubscription<UserProfile?>? _profileSub;

  // ── Getters ──────────────────────────────────────────────────────────────

  bool get isInitialized => _isInitialized;
  bool get firebaseEnabled => _firebaseEnabled;
  bool get isReady => _isInitialized && !_isAuthLoading;
  bool get isAuthenticated => _uid != null;
  bool get onboardingComplete => _profile.onboardingComplete;
  String? get uid => _uid;
  String? get email => _firebaseEnabled ? _auth.currentUserEmail : null;
  UserProfile get profile => _profile;

  Locale get locale => switch (_profile.language) {
    'Español' => const Locale('es'),
    '中文' => const Locale('zh'),
    _ => const Locale('en'),
  };

  // ── Boot ─────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    AppLogger.info('Session initialize started');
    _profile = await _preferences.loadProfile();
    AppLogger.data('Profile loaded from preferences', _profile.toFirestore());
    _firebaseEnabled = await _bootstrap.initialize();
    AppLogger.info('Firebase enabled: $_firebaseEnabled');

    if (_firebaseEnabled) {
      _authSub = _auth.authStateChanges().listen((uid) {
        _onAuthChanged(uid);
      });
    } else {
      _isAuthLoading = false;
    }

    _isInitialized = true;
    AppLogger.info('Session initialize complete');
    notifyListeners();
  }

  Future<void> _onAuthChanged(String? uid) async {
    AppLogger.info('Auth state changed. uid=$uid');
    await _profileSub?.cancel();
    _profileSub = null;
    _uid = uid;
    if (uid == null) {
      _isAuthLoading = false;
      notifyListeners();
      return;
    }

    _isAuthLoading = true;
    notifyListeners();

    try {
      if (_firebaseEnabled) {
        // Ensure user exists in /users (auto-seeds householdCaseId if needed),
        // then hydrate profile from Firestore.
        final ensured = await _profileService.ensureUserDocument(
          uid: uid,
          email: _auth.currentUserEmail,
          profile: _profile,
        );
        // Adopt any case-ID that was generated server-side immediately,
        // so the rest of the load uses the right value.
        if (ensured.householdCaseId.isNotEmpty &&
            _profile.householdCaseId.isEmpty) {
          _profile = _profile.copyWith(
            householdCaseId: ensured.householdCaseId,
          );
        }

        final remote = await _profileService.fetchProfile(uid);
        if (remote != null) {
          _profile = remote;
          await _preferences.saveProfile(remote);
          AppLogger.info(
            'Hydrated profile from Firestore for uid=$uid '
            '(caseId=${remote.householdCaseId})',
          );
        }

        _profileSub = _profileService.watchProfile(uid).listen((remote) async {
          if (remote == null) return;
          _profile = remote;
          await _preferences.saveProfile(remote);
          notifyListeners();
        });
      }
    } catch (e, st) {
      AppLogger.error('Failed to hydrate profile on auth change', e, st);
      // Keep local profile fallback from preferences.
    } finally {
      _isAuthLoading = false;
      notifyListeners();
    }
  }

  // ── Profile ──────────────────────────────────────────────────────────────

  void updateProfile(UserProfile next) {
    _profile = next;
    AppLogger.data('Session profile updated in memory', _profile.toFirestore());
    notifyListeners();
  }

  Future<void> persistProfile({bool includeCreatedAt = false}) async {
    AppLogger.info(
      'Persisting profile (firebase=$_firebaseEnabled, uid=$_uid)',
    );
    await _preferences.saveProfile(_profile);
    AppLogger.info('Profile saved to SharedPreferences');
    if (_firebaseEnabled && _uid != null) {
      await _profileService.upsertProfile(
        uid: _uid!,
        profile: _profile,
        email: _auth.currentUserEmail,
        includeCreatedAt: includeCreatedAt,
      );
    }
    notifyListeners();
  }

  // ── Auth ─────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    AppLogger.info('Session signOut requested');
    if (_firebaseEnabled) {
      await _auth.signOut();
    } else {
      _uid = null;
      notifyListeners();
    }
  }

  AuthService get authService => _auth;

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
