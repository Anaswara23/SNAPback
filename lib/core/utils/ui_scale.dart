import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Responsive spacing helpers using 390x844 as design baseline.
extension UiScale on BuildContext {
  double _sw(double value) => MediaQuery.sizeOf(this).width / 390.0 * value;

  double _sh(double value) => MediaQuery.sizeOf(this).height / 844.0 * value;

  double rs(double value) {
    final scaled = (_sw(value) + _sh(value)) / 2;
    return scaled.clamp(value * 0.85, value * 1.25);
  }

  EdgeInsets rPad({
    double horizontal = 0,
    double vertical = 0,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return EdgeInsets.only(
      left: rs(left ?? horizontal),
      top: rs(top ?? vertical),
      right: rs(right ?? horizontal),
      bottom: rs(bottom ?? vertical),
    );
  }

  double rGap(double value) => rs(value);
}

double minScreenSide(BuildContext context) => math.min(
  MediaQuery.sizeOf(context).width,
  MediaQuery.sizeOf(context).height,
);
