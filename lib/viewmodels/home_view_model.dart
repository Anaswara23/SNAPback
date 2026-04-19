import 'dart:async';

import 'package:flutter/material.dart';

import '../core/utils/app_logger.dart';
import '../core/utils/month_utils.dart';
import '../models/trip_summary.dart';
import '../models/user_stats.dart';
import '../services/trips_service.dart';
import 'session_view_model.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required SessionViewModel session,
    TripsService? tripsService,
  })  : _session = session,
        _tripsService = tripsService ?? TripsService() {
    _subscribe();
  }

  final SessionViewModel _session;
  final TripsService _tripsService;
  StreamSubscription<List<TripSummary>>? _historySub;

  bool isLoading = true;
  UserStats? stats;
  String? errorMessage;
  String latestHighlights =
      'No processed trips yet. Scan a receipt to see insights.';

  /// Cap = min(10% × SNAP, $25 × household). Floor at $5.
  double get monthlyCap {
    final p = _session.profile;
    final snapTier = p.snapAmount * 0.10;
    final familyTier = 25.0 * p.familySize;
    final cap = snapTier < familyTier ? snapTier : familyTier;
    return cap < 5 ? 5 : cap;
  }

  double get monthlyEarned => stats?.monthlyCredit ?? 0;

  double get monthlyRemaining {
    final r = monthlyCap - monthlyEarned;
    return r < 0 ? 0 : r;
  }

  double get monthlyProgressRatio {
    if (monthlyCap <= 0) return 0;
    return (monthlyEarned / monthlyCap).clamp(0, 1);
  }

  int get daysUntilReset => MonthUtils.daysUntilReset();

  /// 0–5 average health score across this month's items.
  double get monthlyAvgHealthScore =>
      (stats?.monthlyAvgHealthScore ?? 0) / 20.0;

  /// Threshold (out of 5) the user must hit by month-end to redeem cashback.
  double get redemptionThreshold => 4.0;

  /// True if the user has earned cashback AND maintained the health threshold.
  bool get isRedeemable =>
      monthlyEarned > 0 && monthlyAvgHealthScore >= redemptionThreshold;

  String get greetingName {
    final name = _session.profile.displayName.trim();
    return name.isEmpty ? 'Champion' : name;
  }

  void _subscribe() {
    AppLogger.info('HomeViewModel subscribing to trips stream');
    isLoading = true;
    notifyListeners();
    _historySub?.cancel();
    _historySub = _tripsService.watchHistory().listen(
      (history) async {
        try {
          stats = _statsFor(history);
          if (history.isNotEmpty) {
            try {
              final latestTrip =
                  await _tripsService.fetchTrip(history.first.id);
              if (latestTrip.tripItems.isNotEmpty) {
                final top = latestTrip.tripItems
                    .take(3)
                    .map((e) => e.name)
                    .join(', ');
                latestHighlights = 'Last trip highlights: $top';
              }
            } catch (e) {
              AppLogger.warn('Could not load latest trip details: $e');
            }
          } else {
            latestHighlights =
                'No processed trips yet. Scan a receipt to see insights.';
          }
          errorMessage = null;
        } catch (e) {
          AppLogger.error('HomeViewModel stream handler failed', e);
          errorMessage = '$e';
        } finally {
          isLoading = false;
          notifyListeners();
        }
      },
      onError: (Object e, StackTrace st) {
        AppLogger.error('HomeViewModel stream error', e, st);
        errorMessage = '$e';
        isLoading = false;
        notifyListeners();
      },
    );
  }

  UserStats _statsFor(List<TripSummary> history) {
    final now = DateTime.now();
    final monthTrips = history
        .where((t) => MonthUtils.sameMonth(t.processedAt, now))
        .toList();
    if (monthTrips.isEmpty) {
      return const UserStats(
        monthlyCredit: 0,
        monthlyTripCount: 0,
        monthlyAvgHealthScore: 0,
      );
    }
    final monthlyCredit =
        monthTrips.fold<double>(0, (a, t) => a + t.credit);
    // Item-weighted avg score: each trip's 0–100 score weighted by item count.
    var weightedSum = 0;
    var totalItems = 0;
    for (final t in monthTrips) {
      final items = t.itemCount > 0 ? t.itemCount : 1;
      weightedSum += t.score * items;
      totalItems += items;
    }
    final avg = totalItems > 0 ? (weightedSum / totalItems).round() : 0;
    return UserStats(
      monthlyCredit: monthlyCredit,
      monthlyTripCount: monthTrips.length,
      monthlyAvgHealthScore: avg,
    );
  }

  Future<void> refresh() async {
    AppLogger.info('HomeViewModel refresh requested (re-subscribing)');
    _subscribe();
  }

  @override
  void dispose() {
    _historySub?.cancel();
    super.dispose();
  }
}
