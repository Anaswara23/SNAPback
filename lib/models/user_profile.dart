import 'dart:math' as math;

/// Domain model representing a user's saved SNAPback profile.
class UserProfile {
  const UserProfile({
    required this.displayName,
    required this.language,
    required this.snapAmount,
    required this.familySize,
    required this.culturalPrefs,
    required this.householdCaseId,
    required this.onboardingComplete,
  });

  factory UserProfile.empty() => const UserProfile(
        displayName: '',
        language: 'English',
        snapAmount: 480,
        familySize: 3,
        culturalPrefs: <String>{},
        householdCaseId: '',
        onboardingComplete: false,
      );

  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    return UserProfile(
      displayName: (data['displayName'] as String?) ?? '',
      language: _languageFromCode((data['language'] as String?) ?? 'en'),
      snapAmount: ((data['snapAmount'] as num?) ?? 480).toDouble(),
      familySize: ((data['familySize'] as num?) ?? 3).toInt(),
      culturalPrefs: (data['culturalPrefs'] as List<dynamic>? ?? const [])
          .map((item) => '$item')
          .toSet(),
      householdCaseId: (data['householdCaseId'] as String?) ?? '',
      onboardingComplete: (data['onboardingComplete'] as bool?) ?? false,
    );
  }

  final String displayName;
  final String language;
  final double snapAmount;
  final int familySize;
  final Set<String> culturalPrefs;

  /// SNAP "case" identifier for the household. One household = one case ID.
  /// Auto-assigned on signup. Format: `SNAP-XXXX-XXXX-XXXX` (12 hex chars).
  final String householdCaseId;

  /// Explicit flag set ONLY when the onboarding wizard's final step is
  /// confirmed. Never inferred from data presence — that caused users to
  /// skip into the dashboard the moment they tapped a single chip.
  final bool onboardingComplete;

  /// Convenience: does the profile contain enough data to be considered
  /// minimally valid? Used by the wizard's final-step validator.
  bool get hasMinimumData =>
      displayName.trim().isNotEmpty && culturalPrefs.isNotEmpty;

  UserProfile copyWith({
    String? displayName,
    String? language,
    double? snapAmount,
    int? familySize,
    Set<String>? culturalPrefs,
    String? householdCaseId,
    bool? onboardingComplete,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      language: language ?? this.language,
      snapAmount: snapAmount ?? this.snapAmount,
      familySize: familySize ?? this.familySize,
      culturalPrefs: culturalPrefs ?? this.culturalPrefs,
      householdCaseId: householdCaseId ?? this.householdCaseId,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'displayName': displayName,
        'language': languageCode,
        'snapAmount': snapAmount,
        'familySize': familySize,
        'culturalPrefs': culturalPrefs.toList(),
        'householdCaseId': householdCaseId,
        'onboardingComplete': onboardingComplete,
      };

  String get languageCode => switch (language) {
        'Español' => 'es',
        '中文' => 'zh',
        _ => 'en',
      };

  static String _languageFromCode(String code) => switch (code) {
        'es' => 'Español',
        'zh' => '中文',
        _ => 'English',
      };

  /// Generates a fresh random household case ID like `SNAP-A1B2-C3D4-E5F6`.
  /// 12 hex chars = ~2.8 × 10^14 combinations → collisions are negligible.
  static String generateHouseholdCaseId() {
    final rng = math.Random.secure();
    String chunk() => List.generate(
          4,
          (_) => rng.nextInt(16).toRadixString(16).toUpperCase(),
        ).join();
    return 'SNAP-${chunk()}-${chunk()}-${chunk()}';
  }
}
