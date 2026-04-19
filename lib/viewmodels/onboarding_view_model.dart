import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/app_logger.dart';
import '../models/user_profile.dart';
import 'session_view_model.dart';

class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel({required SessionViewModel session}) : _session = session;

  final SessionViewModel _session;

  int currentStep = 0;
  bool isSubmitting = false;
  String? errorMessage;

  UserProfile get profile => _session.profile;

  void setDisplayName(String value) {
    _session.updateProfile(profile.copyWith(displayName: value));
    notifyListeners();
  }

  void setLanguage(String value) {
    _session.updateProfile(profile.copyWith(language: value));
    notifyListeners();
  }

  void setSnapAmount(double value) {
    _session.updateProfile(profile.copyWith(snapAmount: value));
    notifyListeners();
  }

  void setFamilySize(int value) {
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
    _session.updateProfile(profile.copyWith(culturalPrefs: updated));
    notifyListeners();
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        return profile.displayName.trim().isNotEmpty;
      case 1:
        return profile.snapAmount >= AppConstants.minSnapAmount &&
            profile.snapAmount <= AppConstants.maxSnapAmount;
      case 2:
        return profile.culturalPrefs.isNotEmpty;
    }
    return true;
  }

  /// Returns true when the user has completed onboarding and the data is saved.
  Future<bool> advance() async {
    AppLogger.info('Onboarding advance tapped at step=$currentStep');
    if (!_validateStep(currentStep)) {
      errorMessage = 'Please complete all required fields.';
      AppLogger.warn('Onboarding validation failed at step=$currentStep');
      notifyListeners();
      return false;
    }
    errorMessage = null;
    if (currentStep < 2) {
      currentStep += 1;
      AppLogger.info('Onboarding moved to step=$currentStep');
      notifyListeners();
      return false;
    }
    try {
      isSubmitting = true;
      notifyListeners();
      // Mark onboarding as explicitly complete only on the final step.
      _session.updateProfile(profile.copyWith(onboardingComplete: true));
      await _session.persistProfile(includeCreatedAt: true);
      AppLogger.info('Onboarding completed successfully');
      return true;
    } catch (e) {
      AppLogger.error('Onboarding completion failed', e);
      errorMessage = 'Could not save profile: $e';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  void onPageChanged(int index) {
    currentStep = index;
    notifyListeners();
  }
}
