import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class SnapbackLogo extends StatelessWidget {
  const SnapbackLogo({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [AppTheme.deepGreen, AppTheme.neonGreen],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonGreen.withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(Icons.eco, color: Colors.white, size: size * 0.55),
    );
  }
}
