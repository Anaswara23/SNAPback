import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// A modern, classy animated loader used across the app.
///
/// Two concentric arcs counter-rotate around a soft glowing core.
/// Designed to feel premium without being distracting — same vibe as
/// the rest of SNAPback's neon/glass aesthetic.
class SnapbackLoader extends StatefulWidget {
  const SnapbackLoader({
    super.key,
    this.size = 56,
    this.label,
    this.compact = false,
  });

  /// Outer diameter in logical pixels.
  final double size;

  /// Optional caption shown below the loader.
  final String? label;

  /// When true, removes vertical padding — useful inline (buttons, list rows).
  final bool compact;

  @override
  State<SnapbackLoader> createState() => _SnapbackLoaderState();
}

class _SnapbackLoaderState extends State<SnapbackLoader>
    with TickerProviderStateMixin {
  late final AnimationController _spinOuter;
  late final AnimationController _spinInner;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _spinOuter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _spinInner = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _spinOuter.dispose();
    _spinInner.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.neonGreen : AppTheme.deepGreen;
    final secondary = AppTheme.neonBlue;
    final cs = Theme.of(context).colorScheme;

    final loader = SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_spinOuter, _spinInner, _pulse]),
        builder: (context, _) {
          return CustomPaint(
            painter: _LoaderPainter(
              outerProgress: _spinOuter.value,
              innerProgress: _spinInner.value,
              pulse: _pulse.value,
              accent: accent,
              secondary: secondary,
              trackColor: cs.onSurface.withValues(alpha: isDark ? 0.06 : 0.08),
            ),
          );
        },
      ),
    );

    if (widget.label == null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: widget.compact ? 0 : 12),
        child: Center(child: loader),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: widget.compact ? 0 : 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loader,
          const SizedBox(height: 14),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: 0.5 + 0.5 * _pulse.value,
            child: Text(
              widget.label!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoaderPainter extends CustomPainter {
  _LoaderPainter({
    required this.outerProgress,
    required this.innerProgress,
    required this.pulse,
    required this.accent,
    required this.secondary,
    required this.trackColor,
  });

  final double outerProgress;
  final double innerProgress;
  final double pulse;
  final Color accent;
  final Color secondary;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerRadius = size.width / 2 - 3;
    final innerRadius = outerRadius * 0.62;
    final stroke = math.max(2.5, size.width * 0.07);

    // Faint background tracks.
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = trackColor;
    canvas.drawCircle(center, outerRadius, trackPaint);
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke * 0.75
        ..color = trackColor,
    );

    // Outer arc — sweeps clockwise with a comet gradient.
    final outerStart = outerProgress * 2 * math.pi;
    const outerSweep = math.pi * 1.2;
    final outerRect = Rect.fromCircle(center: center, radius: outerRadius);
    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        colors: [
          accent.withValues(alpha: 0.0),
          accent.withValues(alpha: 0.85),
          accent,
        ],
        stops: const [0.0, 0.7, 1.0],
        transform: GradientRotation(outerStart),
      ).createShader(outerRect);
    canvas.drawArc(outerRect, outerStart, outerSweep, false, outerPaint);

    // Inner arc — counter-rotates with a cooler accent.
    final innerStart = -innerProgress * 2 * math.pi;
    const innerSweep = math.pi * 0.85;
    final innerRect = Rect.fromCircle(center: center, radius: innerRadius);
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke * 0.75
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        colors: [
          secondary.withValues(alpha: 0.0),
          secondary.withValues(alpha: 0.7),
          secondary,
        ],
        stops: const [0.0, 0.7, 1.0],
        transform: GradientRotation(innerStart),
      ).createShader(innerRect);
    canvas.drawArc(innerRect, innerStart, innerSweep, false, innerPaint);

    // Soft pulsing core dot.
    final coreRadius = innerRadius * (0.30 + 0.06 * pulse);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withValues(alpha: 0.45 + 0.25 * pulse),
          accent.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: coreRadius * 2.2));
    canvas.drawCircle(center, coreRadius * 2.2, glowPaint);
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()..color = accent.withValues(alpha: 0.95),
    );
  }

  @override
  bool shouldRepaint(covariant _LoaderPainter oldDelegate) {
    return oldDelegate.outerProgress != outerProgress ||
        oldDelegate.innerProgress != innerProgress ||
        oldDelegate.pulse != pulse;
  }
}
