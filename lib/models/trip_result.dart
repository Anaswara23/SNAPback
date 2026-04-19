import 'recipe_suggestion.dart';
import 'trip_item.dart';

/// Full structured result for a single trip after analysis.
class TripResult {
  const TripResult({
    required this.id,
    required this.monthlyCap,
    required this.monthlyEarned,
    required this.contributionValue,
    required this.tripScore,
    required this.tripAvgHealthScore,
    required this.monthlyAvgHealthScore,
    required this.redeemable,
    required this.redemptionThreshold,
    required this.tripItems,
    required this.processedAt,
    required this.storeName,
    required this.totalAmount,
    required this.recipes,
  });

  final String id;

  /// Maximum dollars the household can earn in cashback this month.
  final double monthlyCap;

  /// Cumulative cashback earned this month, including this trip.
  final double monthlyEarned;

  /// Cashback dollars earned by THIS trip.
  final double contributionValue;

  /// 0–100 trip health score (avg item health × 20).
  final int tripScore;

  /// 0–5 average item health for THIS trip.
  final double tripAvgHealthScore;

  /// 0–5 weighted average item health across the household for THIS month
  /// (server-computed, item-weighted across all completed trips).
  final double monthlyAvgHealthScore;

  /// Whether the household's cashback can be paid out at month end.
  /// True iff the monthly avg health score meets the threshold.
  final bool redeemable;

  /// The avg-health threshold (0–5) required to unlock redemption.
  final double redemptionThreshold;

  final List<TripItem> tripItems;
  final DateTime processedAt;

  /// Store + total context (display only).
  final String storeName;
  final double totalAmount;

  /// Optional recipe suggestions generated from purchased items.
  final List<RecipeSuggestion> recipes;

  /// True when [monthlyEarned] meets or exceeds [monthlyCap].
  bool get capReached => monthlyCap > 0 && monthlyEarned >= monthlyCap;

  /// Remaining headroom for the month (never negative).
  double get monthlyRemaining {
    if (monthlyCap <= 0) return 0;
    final remaining = monthlyCap - monthlyEarned;
    return remaining < 0 ? 0 : remaining;
  }

  double get progressRatio {
    if (monthlyCap <= 0) return 0;
    return (monthlyEarned / monthlyCap).clamp(0, 1);
  }

  factory TripResult.fromCloud({
    required String id,
    required Map<String, dynamic> json,
  }) {
    final rawItems = (json['tripItems'] as List?) ?? const [];
    final items = rawItems
        .whereType<Map>()
        .map((item) => TripItem.fromCloud(Map<String, dynamic>.from(item)))
        .toList();

    final processedTs = json['processedAt'] ?? json['updatedAt'];
    DateTime processedAt;
    if (processedTs is DateTime) {
      processedAt = processedTs;
    } else if (processedTs is int) {
      processedAt = DateTime.fromMillisecondsSinceEpoch(processedTs);
    } else if (processedTs is String) {
      processedAt = DateTime.tryParse(processedTs) ?? DateTime.now();
    } else {
      try {
        // ignore: avoid_dynamic_calls
        processedAt = (processedTs as dynamic).toDate() as DateTime;
      } catch (_) {
        processedAt = DateTime.now();
      }
    }

    final monthlyCap =
        ((json['monthlyCap'] as num?) ?? (json['monthlyTarget'] as num?) ?? 0)
            .toDouble();
    final contribution =
        ((json['contributionValue'] as num?) ?? 0).toDouble();
    final monthlyEarned =
        ((json['monthlyEarned'] as num?) ??
                (json['newMonthlyProgress'] as num?) ??
                contribution)
            .toDouble();

    final tripAvgFromItems = items.isEmpty
        ? 0.0
        : items.map((i) => i.healthScore).reduce((a, b) => a + b) /
            items.length;
    final tripAvgHealthScore =
        ((json['tripAvgHealthScore'] as num?)?.toDouble() ?? tripAvgFromItems);
    final tripScore = (tripAvgHealthScore * 20).round().clamp(0, 100);

    final monthlyAvg =
        ((json['monthlyAvgHealthScore'] as num?)?.toDouble() ??
            tripAvgHealthScore);
    final threshold =
        ((json['redemptionThreshold'] as num?)?.toDouble() ?? 4.0);
    final explicitRedeemable = json['redeemable'];
    final redeemable = explicitRedeemable is bool
        ? explicitRedeemable
        : (monthlyEarned > 0 && monthlyAvg >= threshold);

    return TripResult(
      id: id,
      monthlyCap: monthlyCap,
      monthlyEarned: monthlyEarned,
      contributionValue: contribution,
      tripScore: tripScore,
      tripAvgHealthScore: tripAvgHealthScore,
      monthlyAvgHealthScore: monthlyAvg,
      redeemable: redeemable,
      redemptionThreshold: threshold,
      tripItems: items,
      processedAt: processedAt,
      storeName: (json['storeName'] ?? '').toString(),
      totalAmount: ((json['totalAmount'] as num?) ?? 0).toDouble(),
      recipes: ((json['suggestedRecipes'] as List?) ?? const [])
          .whereType<Map>()
          .map((r) =>
              RecipeSuggestion.fromCloud(Map<String, dynamic>.from(r)))
          .toList(),
    );
  }
}
