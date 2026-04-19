import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../core/utils/app_logger.dart';
import '../models/trip_result.dart';
import '../models/trip_summary.dart';
import '../models/user_stats.dart';

class TripsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      AppLogger.warn('TripsService requested without authenticated user');
      throw StateError('Not authenticated.');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _userTrips =>
      _firestore.collection('users').doc(_uid).collection('trips');

  Future<UserStats> fetchStats() async {
    AppLogger.info('TripsService.fetchStats started');
    final history = await fetchHistory();
    return _computeStats(history);
  }

  UserStats _computeStats(List<TripSummary> history) {
    final now = DateTime.now();
    final monthTrips = history.where((t) {
      return t.processedAt.year == now.year && t.processedAt.month == now.month;
    }).toList();

    if (monthTrips.isEmpty) {
      AppLogger.info('No trips this month; returning zero stats');
      return const UserStats(
        monthlyCredit: 0,
        monthlyTripCount: 0,
        monthlyAvgHealthScore: 0,
      );
    }

    final monthlyCredit =
        monthTrips.fold<double>(0, (acc, trip) => acc + trip.credit);
    var weightedSum = 0;
    var totalItems = 0;
    for (final t in monthTrips) {
      final items = t.itemCount > 0 ? t.itemCount : 1;
      weightedSum += t.score * items;
      totalItems += items;
    }
    final avgHealth =
        totalItems > 0 ? (weightedSum / totalItems).round() : 0;

    final stats = UserStats(
      monthlyCredit: monthlyCredit,
      monthlyTripCount: monthTrips.length,
      monthlyAvgHealthScore: avgHealth,
    );
    AppLogger.data('Computed stats', {
      'monthlyCredit': stats.monthlyCredit,
      'monthlyTripCount': stats.monthlyTripCount,
      'monthlyAvgHealthScore': stats.monthlyAvgHealthScore,
    });
    return stats;
  }

  Future<List<TripSummary>> fetchHistory() async {
    AppLogger.info('TripsService.fetchHistory started for uid=$_uid');
    final snap = await _userTrips.orderBy('updatedAt', descending: true).get();
    return _summariesFromSnapshot(snap);
  }

  /// Live stream of completed trips, ordered newest first.
  /// Emits whenever any trip doc under /users/{uid}/trips changes.
  Stream<List<TripSummary>> watchHistory() {
    AppLogger.info('TripsService.watchHistory subscribed for uid=$_uid');
    return _userTrips
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(_summariesFromSnapshot);
  }

  /// Live stats stream derived from the history stream.
  Stream<UserStats> watchStats() {
    return watchHistory().map(_computeStats);
  }

  List<TripSummary> _summariesFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    AppLogger.info('Trip docs fetched: ${snap.docs.length}');
    final summaries = <TripSummary>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      if (!_hasFinalResult(data)) {
        AppLogger.info('Skipping non-final trip doc: ${doc.id}');
        continue;
      }
      final result = _extractResultPayload(data);
      final trip = TripResult.fromCloud(id: doc.id, json: result);
      summaries.add(
        TripSummary(
          id: trip.id,
          date: _formatDate(trip.processedAt),
          processedAt: trip.processedAt,
          score: trip.tripScore,
          credit: trip.contributionValue,
          itemCount: trip.tripItems.length,
          storeName: trip.storeName,
        ),
      );
      AppLogger.data('History summary item ${doc.id}', {
        'score': trip.tripScore,
        'itemCount': trip.tripItems.length,
        'credit': trip.contributionValue,
      });
    }
    AppLogger.info('Final history count: ${summaries.length}');
    return summaries;
  }

  Future<TripResult> fetchTrip(String id) async {
    AppLogger.info('TripsService.fetchTrip started id=$id');
    final doc = await _userTrips.doc(id).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      if (_hasFinalResult(data)) {
        final payload = _extractResultPayload(data);
        AppLogger.data('Trip payload from user trip doc', payload);
        return TripResult.fromCloud(id: id, json: payload);
      }
      AppLogger.info('Trip $id still processing in /users/{uid}/trips');
      throw StateError('Trip is still processing.');
    }

    // Optional backend fallback if function writes to top-level /trips.
    final globalDoc = await _firestore.collection('trips').doc(id).get();
    if (globalDoc.exists && globalDoc.data() != null) {
      final data = globalDoc.data()!;
      if (_hasFinalResult(data)) {
        final payload = _extractResultPayload(data);
        AppLogger.data('Trip payload from /trips fallback', payload);
        return TripResult.fromCloud(id: id, json: payload);
      }
      AppLogger.info('Trip $id still processing in top-level /trips');
      throw StateError('Trip is still processing.');
    }

    AppLogger.warn('Trip $id not found in known collections');
    throw StateError('Trip not found yet.');
  }

  /// Permanently removes a trip document and its receipt image (if any).
  Future<void> deleteTrip(String id) async {
    AppLogger.info('TripsService.deleteTrip started id=$id');
    final docRef = _userTrips.doc(id);
    final doc = await docRef.get();

    String? receiptPath;
    if (doc.exists) {
      final data = doc.data();
      receiptPath = data?['receiptPath'] as String?;
    }

    await docRef.delete();
    AppLogger.info('Deleted Firestore trip doc users/$_uid/trips/$id');

    if (receiptPath != null && receiptPath.isNotEmpty) {
      try {
        await _storage.ref(receiptPath).delete();
        AppLogger.info('Deleted Storage receipt at $receiptPath');
      } catch (e) {
        AppLogger.warn('Could not delete Storage object $receiptPath: $e');
      }
    }
  }

  bool _hasFinalResult(Map<String, dynamic> data) {
    final hasItems = data['tripItems'] is List;
    final hasCap =
        data['monthlyCap'] != null || data['monthlyTarget'] != null;
    if (hasItems && hasCap) return true;
    final result = data['result'];
    if (result is Map<String, dynamic>) {
      final r = result;
      return (r['tripItems'] is List) &&
          (r['monthlyCap'] != null || r['monthlyTarget'] != null);
    }
    return false;
  }

  Map<String, dynamic> _extractResultPayload(Map<String, dynamic> data) {
    final nested = data['result'];
    final base = nested is Map ? Map<String, dynamic>.from(nested) : data;

    // Convert Firestore Timestamps to DateTime for the model layer.
    DateTime? extractTs(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is Timestamp) return value.toDate();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return null;
    }

    final processedAt =
        extractTs(base['processedAt']) ?? extractTs(base['updatedAt']);
    if (processedAt != null) {
      base['processedAt'] = processedAt;
    }
    return base;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
