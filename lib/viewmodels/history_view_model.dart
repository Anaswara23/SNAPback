import 'dart:async';

import 'package:flutter/material.dart';

import '../core/utils/app_logger.dart';
import '../core/utils/month_utils.dart';
import '../models/trip_summary.dart';
import '../models/user_profile.dart';
import '../models/user_stats.dart';
import '../services/trips_service.dart';
import 'session_view_model.dart';

class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel({
    TripsService? tripsService,
    SessionViewModel? session,
  })  : _tripsService = tripsService ?? TripsService(),
        _session = session {
    _selectedMonth = MonthUtils.startOfMonth(DateTime.now());
    _subscribe();
    _session?.addListener(_onSessionChanged);
  }

  final TripsService _tripsService;
  final SessionViewModel? _session;
  StreamSubscription<List<TripSummary>>? _historySub;

  bool isLoading = true;
  List<TripSummary> _allTrips = const [];
  UserStats? stats;
  String? errorMessage;

  late DateTime _selectedMonth;
  DateTime get selectedMonth => _selectedMonth;

  bool get isViewingCurrentMonth =>
      MonthUtils.sameMonth(_selectedMonth, DateTime.now());

  /// Trips matching the selected month filter (newest first).
  List<TripSummary> get trips => _allTrips
      .where((t) => MonthUtils.sameMonth(t.processedAt, _selectedMonth))
      .toList();

  /// All months that contain at least one trip, newest → oldest.
  List<DateTime> get availableMonths {
    final set = <DateTime>{
      MonthUtils.startOfMonth(DateTime.now()),
      ..._allTrips.map((t) => MonthUtils.startOfMonth(t.processedAt)),
    };
    final list = set.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  // ── Cashback / cap / health (always for the CURRENT calendar month) ──────

  double get currentMonthEarned {
    final now = DateTime.now();
    return _allTrips
        .where((t) => MonthUtils.sameMonth(t.processedAt, now))
        .fold<double>(0, (a, t) => a + t.credit);
  }

  double get monthlyCap {
    final profile = _session?.profile ?? UserProfile.empty();
    final snapTier = profile.snapAmount * 0.10;
    final familyTier = 25.0 * profile.familySize;
    final cap = snapTier < familyTier ? snapTier : familyTier;
    return cap < 5 ? 5 : cap;
  }

  double get monthlyRemaining {
    final remaining = monthlyCap - currentMonthEarned;
    return remaining < 0 ? 0 : remaining;
  }

  double get monthlyProgressRatio {
    if (monthlyCap <= 0) return 0;
    return (currentMonthEarned / monthlyCap).clamp(0, 1);
  }

  int get daysUntilReset => MonthUtils.daysUntilReset();

  /// Item-weighted avg health score for the CURRENT month, on a 0–5 scale.
  double get currentMonthAvgHealthScore {
    final now = DateTime.now();
    final monthTrips = _allTrips
        .where((t) => MonthUtils.sameMonth(t.processedAt, now))
        .toList();
    if (monthTrips.isEmpty) return 0;
    var weightedSum = 0;
    var totalItems = 0;
    for (final t in monthTrips) {
      final items = t.itemCount > 0 ? t.itemCount : 1;
      // Trip score is 0–100 (avg item health × 20). Convert back to 0–5.
      weightedSum += t.score * items;
      totalItems += items;
    }
    if (totalItems == 0) return 0;
    return (weightedSum / totalItems) / 20.0;
  }

  double get redemptionThreshold => 4.0;

  bool get isRedeemable =>
      currentMonthEarned > 0 &&
      currentMonthAvgHealthScore >= redemptionThreshold;

  /// Earned in the *previous* month (for the trend chart).
  double get previousMonthCredit {
    final now = DateTime.now();
    final prev = DateTime(now.year, now.month - 1, 1);
    return _allTrips
        .where((t) => MonthUtils.sameMonth(t.processedAt, prev))
        .fold<double>(0, (a, t) => a + t.credit);
  }

  // Backwards-compat alias used by older widgets.
  double get currentMonthCredit => currentMonthEarned;

  void selectMonth(DateTime month) {
    _selectedMonth = MonthUtils.startOfMonth(month);
    AppLogger.info('History month filter changed -> $_selectedMonth');
    notifyListeners();
  }

  void _subscribe() {
    AppLogger.info('HistoryViewModel subscribing to trips stream');
    isLoading = true;
    notifyListeners();
    _historySub?.cancel();
    _historySub = _tripsService.watchHistory().listen(
      (history) {
        _allTrips = history;
        stats = _statsFor(history);
        AppLogger.data('History stream tick', {
          'tripCount': _allTrips.length,
          'monthlyEarned': currentMonthEarned,
          'monthlyCap': monthlyCap,
          'monthAvgHealth': currentMonthAvgHealthScore,
          'redeemable': isRedeemable,
        });
        errorMessage = null;
        isLoading = false;
        notifyListeners();
      },
      onError: (Object e, StackTrace st) {
        AppLogger.error('HistoryViewModel stream error', e, st);
        errorMessage = '$e';
        isLoading = false;
        notifyListeners();
      },
    );
  }

  void _onSessionChanged() {
    notifyListeners();
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
    final credit = monthTrips.fold<double>(0, (a, t) => a + t.credit);
    var weightedSum = 0;
    var totalItems = 0;
    for (final t in monthTrips) {
      final items = t.itemCount > 0 ? t.itemCount : 1;
      weightedSum += t.score * items;
      totalItems += items;
    }
    final avg = totalItems > 0 ? (weightedSum / totalItems).round() : 0;
    return UserStats(
      monthlyCredit: credit,
      monthlyTripCount: monthTrips.length,
      monthlyAvgHealthScore: avg,
    );
  }

  Future<void> refresh() async {
    AppLogger.info('HistoryViewModel refresh requested (re-subscribing)');
    _subscribe();
  }

  Future<void> deleteTrip(String tripId) async {
    AppLogger.info('HistoryViewModel deleteTrip requested id=$tripId');
    await _tripsService.deleteTrip(tripId);
  }

  @override
  void dispose() {
    _historySub?.cancel();
    _session?.removeListener(_onSessionChanged);
    super.dispose();
  }
}
