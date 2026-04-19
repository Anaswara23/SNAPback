/// Lightweight projection of a single trip used in lists and history views.
class TripSummary {
  const TripSummary({
    required this.id,
    required this.date,
    required this.processedAt,
    required this.score,
    required this.credit,
    required this.itemCount,
    this.storeName = '',
  });

  final String id;
  final String date;
  final DateTime processedAt;

  /// 0–100 health score for the trip (avg item health × 20).
  final int score;

  /// Cashback dollars contributed by this trip.
  final double credit;

  /// Number of (edible) items in the trip — used for item-weighted month avgs.
  final int itemCount;

  final String storeName;
}
