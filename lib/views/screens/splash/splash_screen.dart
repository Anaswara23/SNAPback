import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/neon_backdrop.dart';
import '../../shared/widgets/snapback_loader.dart';
import '../../shared/widgets/snapback_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeonBackdrop(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SnapbackLogo(size: 96),
              const SizedBox(height: 24),
              Text(
                'SNAPback',
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.deepGreen),
              ),
              const SizedBox(height: 24),
              const SnapbackLoader(size: 56, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}
