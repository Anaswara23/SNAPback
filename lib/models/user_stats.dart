/// Aggregated stats shown on the home dashboard for the CURRENT calendar month.
class UserStats {
  const UserStats({
    required this.monthlyCredit,
    required this.monthlyTripCount,
    required this.monthlyAvgHealthScore,
  });

  /// Cashback dollars earned this month so far.
  final double monthlyCredit;

  /// Number of trips logged this month.
  final int monthlyTripCount;

  /// Average item-weighted health score this month, on a 0–100 scale (so it
  /// renders directly in the score ring). 0 when no trips yet.
  final int monthlyAvgHealthScore;
}
