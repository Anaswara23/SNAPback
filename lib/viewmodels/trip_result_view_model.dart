import 'package:flutter/material.dart';

import '../core/utils/app_logger.dart';
import '../models/trip_result.dart';
import '../services/trips_service.dart';

class TripResultViewModel extends ChangeNotifier {
  TripResultViewModel({required this.tripId, TripsService? tripsService})
    : _tripsService = tripsService ?? TripsService() {
    _load();
  }

  final String tripId;
  final TripsService _tripsService;

  bool isLoading = true;
  bool isDeleting = false;
  TripResult? trip;
  String? errorMessage;

  double get score => (trip?.tripScore ?? 0).toDouble();
  double get tripAvgHealthScore => trip?.tripAvgHealthScore ?? 0;
  double get monthlyAvgHealthScore => trip?.monthlyAvgHealthScore ?? 0;
  double get redemptionThreshold => trip?.redemptionThreshold ?? 4.0;
  bool get isRedeemable => trip?.redeemable ?? false;
  double get earnedCredit => trip?.contributionValue ?? 0;
  double get monthlyEarned => trip?.monthlyEarned ?? 0;
  double get monthlyCap => trip?.monthlyCap ?? 0;
  double get monthlyRemaining => trip?.monthlyRemaining ?? 0;
  double get progressRatio => trip?.progressRatio ?? 0;
  bool get capReached => trip?.capReached ?? false;

  Future<void> _load() async {
    const maxAttempts = 45;
    const retryDelay = Duration(seconds: 2);
    try {
      AppLogger.info('TripResultViewModel load started tripId=$tripId');
      if (tripId.isEmpty) {
        throw StateError('Missing trip id.');
      }
      isLoading = true;
      notifyListeners();
      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        try {
          AppLogger.info('Trip fetch attempt ${attempt + 1}/$maxAttempts');
          trip = await _tripsService.fetchTrip(tripId);
          errorMessage = null;
          AppLogger.info('Trip result loaded successfully tripId=$tripId');
          AppLogger.data('Trip result summary', {
            'tripAvgHealth': trip?.tripAvgHealthScore,
            'monthlyAvgHealth': trip?.monthlyAvgHealthScore,
            'redeemable': trip?.redeemable,
            'monthlyCap': trip?.monthlyCap,
            'monthlyEarned': trip?.monthlyEarned,
            'tripItemsCount': trip?.tripItems.length,
            'capReached': trip?.capReached,
            'recipeCount': trip?.recipes.length,
          });
          return;
        } on StateError catch (e) {
          final message = e.message;
          if (message.contains('processing') || message.contains('not found')) {
            AppLogger.info('Trip still processing/not found: $message');
            errorMessage = 'Processing receipt...';
            notifyListeners();
            await Future<void>.delayed(retryDelay);
            continue;
          }
          rethrow;
        }
      }
      errorMessage =
          'Receipt processing is taking longer than expected. Please try again shortly.';
      AppLogger.warn('Trip processing timeout reached for tripId=$tripId');
    } catch (e) {
      AppLogger.error('TripResultViewModel load failed', e);
      errorMessage = '$e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Deletes this trip (Firestore doc + receipt image).
  /// Throws on failure so the caller can show an error.
  Future<void> deleteTrip() async {
    if (isDeleting) return;
    AppLogger.info('TripResultViewModel deleteTrip requested tripId=$tripId');
    isDeleting = true;
    notifyListeners();
    try {
      await _tripsService.deleteTrip(tripId);
      AppLogger.info('Trip deleted successfully tripId=$tripId');
    } catch (e, st) {
      AppLogger.error('TripResultViewModel deleteTrip failed', e, st);
      isDeleting = false;
      notifyListeners();
      rethrow;
    }
  }
}
