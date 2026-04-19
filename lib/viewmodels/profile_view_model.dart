import 'package:flutter/material.dart';

import '../core/utils/app_logger.dart';
import '../models/user_profile.dart';
import 'session_view_model.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({required SessionViewModel session}) : _session = session;

  final SessionViewModel _session;

  bool isSaving = false;
  String? statusMessage;

  UserProfile get profile => _session.profile;

  void setDisplayName(String value) {
    AppLogger.info('Profile display name changed');
    _session.updateProfile(profile.copyWith(displayName: value));
    notifyListeners();
  }

  void setLanguage(String value) {
    AppLogger.info('Profile language changed: $value');
    _session.updateProfile(profile.copyWith(language: value));
    notifyListeners();
  }

  void setSnapAmount(double value) {
    AppLogger.info('Profile snap amount changed: $value');
    _session.updateProfile(profile.copyWith(snapAmount: value));
    notifyListeners();
  }

  void setFamilySize(int value) {
    AppLogger.info('Profile family size changed: $value');
    _session.updateProfile(profile.copyWith(familySize: value));
    notifyListeners();
  }

  void togglePreference(String value, bool selected) {
    final updated = {...profile.culturalPrefs};
    if (selected) {
      updated.add(value);
    } else {
      updated.remove(value);
    }
    AppLogger.info('Profile preference toggle: $value => $selected');
    _session.updateProfile(profile.copyWith(culturalPrefs: updated));
    notifyListeners();
  }

  Future<void> save() async {
    try {
      AppLogger.info('Saving profile from ProfileViewModel');
      isSaving = true;
      statusMessage = null;
      notifyListeners();
      await _session.persistProfile();
      statusMessage = 'Saved.';
    } catch (e, st) {
      AppLogger.error('Profile save failed', e, st);
      statusMessage = 'Could not save: $e';
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> signOut() {
    AppLogger.info('Profile screen sign-out tapped');
    return _session.signOut();
  }
}
