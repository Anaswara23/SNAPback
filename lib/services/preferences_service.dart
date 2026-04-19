import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

/// Persists local-only state (cached profile, theme mode, etc).
class PreferencesService {
  static const _kDisplayName = 'display_name';
  static const _kLanguage = 'language';
  static const _kSnapAmount = 'snap_amount';
  static const _kFamilySize = 'family_size';
  static const _kCulturalPrefs = 'cultural_prefs';
  static const _kHouseholdCaseId = 'household_case_id';
  static const _kOnboardingComplete = 'onboarding_complete';
  static const _kThemeMode = 'theme_mode';

  Future<UserProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return UserProfile(
      displayName: prefs.getString(_kDisplayName) ?? '',
      language: prefs.getString(_kLanguage) ?? 'English',
      snapAmount: prefs.getDouble(_kSnapAmount) ?? 480,
      familySize: prefs.getInt(_kFamilySize) ?? 3,
      culturalPrefs: (prefs.getStringList(_kCulturalPrefs) ?? const []).toSet(),
      householdCaseId: prefs.getString(_kHouseholdCaseId) ?? '',
      onboardingComplete: prefs.getBool(_kOnboardingComplete) ?? false,
    );
  }

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDisplayName, profile.displayName);
    await prefs.setString(_kLanguage, profile.language);
    await prefs.setDouble(_kSnapAmount, profile.snapAmount);
    await prefs.setInt(_kFamilySize, profile.familySize);
    await prefs.setStringList(_kCulturalPrefs, profile.culturalPrefs.toList());
    await prefs.setString(_kHouseholdCaseId, profile.householdCaseId);
    await prefs.setBool(_kOnboardingComplete, profile.onboardingComplete);
  }

  Future<String?> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kThemeMode);
  }

  Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeMode, mode);
  }
}
