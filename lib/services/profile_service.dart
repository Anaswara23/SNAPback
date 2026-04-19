import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/app_logger.dart';
import '../models/user_profile.dart';

/// Syncs user profile documents under `/users/{uid}`.
class ProfileService {
  CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection('users');

  Stream<UserProfile?> watchProfile(String uid) {
    AppLogger.info('Watching profile stream for /users/$uid');
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      AppLogger.data('Profile stream payload /users/$uid', data);
      return UserProfile.fromFirestore(data);
    });
  }

  Future<UserProfile?> fetchProfile(String uid) async {
    AppLogger.info('Fetching profile from /users/$uid');
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    AppLogger.data('Fetched profile payload /users/$uid', data);
    return UserProfile.fromFirestore(data);
  }

  /// Ensures `/users/{uid}` exists. Creates the doc on first sign-up,
  /// always assigning a fresh `householdCaseId` if the profile/doc lacks one.
  /// For existing docs that pre-date the case-ID field, it backfills the ID
  /// in-place (single household = single case).
  Future<UserProfile> ensureUserDocument({
    required String uid,
    required UserProfile profile,
    String? email,
  }) async {
    final ref = _users.doc(uid);
    final existing = await ref.get();

    if (!existing.exists) {
      final caseId = profile.householdCaseId.isNotEmpty
          ? profile.householdCaseId
          : UserProfile.generateHouseholdCaseId();
      final seeded = profile.copyWith(householdCaseId: caseId);
      AppLogger.info(
        'Creating initial /users/$uid document with caseId=$caseId',
      );
      final payload = {
        'uid': uid,
        'email': email,
        ...seeded.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      AppLogger.data('Initial user doc payload', payload);
      await ref.set(payload);
      return seeded;
    }

    final data = existing.data() ?? {};
    final remoteCaseId = (data['householdCaseId'] as String?) ?? '';
    if (remoteCaseId.isEmpty) {
      final caseId = UserProfile.generateHouseholdCaseId();
      AppLogger.info('Backfilling householdCaseId for /users/$uid: $caseId');
      await ref.set({
        'householdCaseId': caseId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    return UserProfile.fromFirestore({
      ...data,
      if (remoteCaseId.isEmpty)
        'householdCaseId':
            (data['householdCaseId'] as String?) ?? UserProfile.empty().householdCaseId,
    });
  }

  Future<void> upsertProfile({
    required String uid,
    required UserProfile profile,
    String? email,
    bool includeCreatedAt = false,
  }) async {
    final payload = <String, dynamic>{
      'uid': uid,
      if (email != null && email.isNotEmpty) 'email': email,
      ...profile.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (includeCreatedAt) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }

    AppLogger.info(
      'Upserting /users/$uid (onboardingComplete=${profile.onboardingComplete})',
    );
    AppLogger.data('Profile upsert payload', payload);
    await _users.doc(uid).set(payload, SetOptions(merge: true));
  }
}
