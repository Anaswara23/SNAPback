import 'dart:math' as math;

import 'package:flutter/material.dart';

BoxDecoration glassCardDecoration(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: dark
          ? [
              Colors.white.withValues(alpha: 0.08),
              Colors.white.withValues(alpha: 0.03),
            ]
          : [
              Colors.white.withValues(alpha: 0.94),
              Colors.white.withValues(alpha: 0.7),
            ],
      transform: GradientRotation(math.pi / 12),
    ),
    border: Border.all(
      color: dark ? Colors.white.withValues(alpha: 0.14) : Colors.white,
    ),
    boxShadow: [
      BoxShadow(
        color: dark
            ? Colors.black.withValues(alpha: 0.35)
            : const Color(0x14000000),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: glassCardDecoration(context),
      padding: padding,
      child: child,
    );
  }
}
