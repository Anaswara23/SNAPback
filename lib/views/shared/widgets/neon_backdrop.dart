import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class NeonBackdrop extends StatelessWidget {
  const NeonBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: -90,
          top: -50,
          child: _Orb(color: AppTheme.neonGreen.withValues(alpha: 0.2)),
        ),
        Positioned(
          right: -80,
          bottom: -60,
          child: _Orb(color: AppTheme.neonBlue.withValues(alpha: 0.2)),
        ),
        child,
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.color});

  final Color color;
  static const double size = 220;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 80, spreadRadius: 30),
          ],
        ),
      ),
    );
  }
}
