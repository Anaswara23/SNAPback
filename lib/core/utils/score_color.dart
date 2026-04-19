import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Maps a 0-100 health score to a brand color used across charts/cards.
Color scoreColor(double score) {
  if (score <= 25) return AppTheme.lossRed;
  if (score <= 50) return AppTheme.warningAmber;
  if (score <= 75) return Colors.green;
  return AppTheme.deepGreen;
}
