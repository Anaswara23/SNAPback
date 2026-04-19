/// A single line item parsed from a receipt.
class TripItem {
  const TripItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalPrice,
    required this.healthScore,
    required this.category,
    this.isCultural = false,
    this.cashbackEarned = 0,
  });

  final String name;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double totalPrice;
  final int healthScore;
  final String category;

  /// Whether the item is associated with a specific cuisine tradition
  /// (used for the +1pp cultural cashback bonus).
  final bool isCultural;

  /// Per-item cashback in dollars contributed by this line.
  final double cashbackEarned;

  factory TripItem.fromCloud(Map<String, dynamic> json) {
    final quantity = (json['quantity'] as num?)?.toDouble() ?? 1;
    final unitPrice =
        (json['unitPrice'] as num?)?.toDouble() ??
        (json['price'] as num?)?.toDouble() ??
        0;
    final totalPrice =
        (json['totalPrice'] as num?)?.toDouble() ?? (quantity * unitPrice);
    return TripItem(
      name: (json['name'] ?? 'Unknown item').toString(),
      quantity: quantity,
      unit: (json['unit'] ?? 'ea').toString(),
      unitPrice: unitPrice,
      totalPrice: totalPrice,
      healthScore: ((json['healthScore'] as num?)?.toInt() ?? 0).clamp(0, 5),
      category: (json['category'] ?? 'uncategorized').toString(),
      isCultural: json['isCultural'] == true,
      cashbackEarned:
          (json['cashbackEarned'] as num?)?.toDouble() ??
          (json['cashback'] as num?)?.toDouble() ??
          0,
    );
  }
}
