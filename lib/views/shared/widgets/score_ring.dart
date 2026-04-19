import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/score_color.dart';
import 'glass_card.dart';

class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.score,
    this.label = 'Health Score (this month)',
    this.sublabel,
  });

  final double score;
  final String label;
  final String? sublabel;

  @override
  Widget build(BuildContext context) {
    final value = score.clamp(0, 100).toDouble();
    final color = scoreColor(value);
    final semanticsLabel = sublabel == null
        ? '$label, ${value.toStringAsFixed(0)} out of 100'
        : '$label, ${value.toStringAsFixed(0)} out of 100. $sublabel';
    return Semantics(
      container: true,
      label: semanticsLabel,
      child: Container(
      height: 240,
      decoration: glassCardDecoration(context),
      padding: const EdgeInsets.all(20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 0,
              centerSpaceRadius: 70,
              sections: [
                PieChartSectionData(
                  value: value,
                  color: color,
                  radius: 22,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: 100 - value,
                  color: color.withValues(alpha: 0.12),
                  radius: 22,
                  showTitle: false,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 128,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 900),
                  tween: Tween(begin: 0, end: value),
                  builder: (context, animated, child) => Text(
                    animated.toStringAsFixed(0),
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(fontWeight: FontWeight.w800, height: 1.0),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        letterSpacing: 0.2,
                      ),
                ),
                if (sublabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sublabel!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
