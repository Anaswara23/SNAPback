/// Domain constants surfaced to the UI/onboarding flows.
class AppConstants {
  AppConstants._();

  /// Languages users can set on their profile. We currently render English
  /// throughout the app; the other locales are kept selectable so households
  /// can declare their preferred language for upcoming localized releases.
  static const supportedLanguages = <String>['English', 'Español', '中文'];

  /// User-facing labels for [supportedLanguages]. The non-English options are
  /// flagged "coming soon" so households know the in-app strings are still
  /// English-only while we ship full ARB localization.
  static const Map<String, String> languageLabels = {
    'English': 'English',
    'Español': 'Español (coming soon)',
    '中文': '中文 (coming soon)',
  };

  /// Cuisine preferences. Used during onboarding and on the profile screen,
  /// and fed back to the AI as personalization signal so the cultural-bonus
  /// reward tier (and recipe suggestions) align with what the household
  /// actually cooks at home.
  ///
  /// Keep this list grouped by region — the UI shows it as a chip wrap and
  /// users may pick multiple.
  static const culturalPreferences = <String>[
    // Americas
    'Caribbean',
    'Mexican',
    'Central American',
    'South American',
    'Soul Food / Southern',
    'Cajun & Creole',
    // South & Southeast Asia
    'Indian / South Asian',
    'Filipino',
    'Vietnamese',
    'Thai',
    'Indonesian / Malaysian',
    // East Asia
    'Chinese',
    'Japanese',
    'Korean',
    // Africa
    'West African',
    'East African',
    'North African',
    // Middle East & Mediterranean
    'Middle Eastern',
    'Persian',
    'Turkish',
    'Mediterranean',
    // Europe
    'Eastern European',
    'Italian',
    'Other',
  ];

  static const minSnapAmount = 50.0;
  static const maxSnapAmount = 2000.0;
}
