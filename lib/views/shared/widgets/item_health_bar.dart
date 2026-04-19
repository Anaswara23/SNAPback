import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/trip_item.dart';

class ItemHealthBar extends StatelessWidget {
  const ItemHealthBar({super.key, required this.item});

  final TripItem item;

  @override
  Widget build(BuildContext context) {
    final score = item.healthScore;
    final cs = Theme.of(context).colorScheme;
    final barColor = score >= 4
        ? AppTheme.deepGreen
        : score >= 2
            ? AppTheme.warningAmber
            : AppTheme.lossRed;

    final earnedCash = item.cashbackEarned;
    final qtyStr = item.quantity % 1 == 0
        ? item.quantity.toStringAsFixed(0)
        : item.quantity.toStringAsFixed(2);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (item.isCultural) ...[
                          const SizedBox(width: 6),
                          _Pill(
                            label: 'cultural',
                            color: AppTheme.deepGreen,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$qtyStr ${item.unit} · \$${item.unitPrice.toStringAsFixed(2)} ea · '
                      '\$${item.totalPrice.toStringAsFixed(2)} total',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...List.generate(
                        5,
                        (index) => Icon(
                          index < score ? Icons.star : Icons.star_border,
                          color: barColor,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$score/5',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    earnedCash > 0
                        ? '+\$${earnedCash.toStringAsFixed(2)}'
                        : 'No cashback',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: earnedCash > 0
                          ? AppTheme.neonGreen
                          : cs.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: score / 5,
              minHeight: 6,
              valueColor: AlwaysStoppedAnimation(barColor),
              backgroundColor: barColor.withValues(alpha: 0.14),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
