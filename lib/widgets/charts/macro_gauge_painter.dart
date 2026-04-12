import 'dart:math';
import 'package:flutter/material.dart';

/// CustomPainter that draws a semicircle gauge with 5 colored segments
/// and a needle pointing to the current risk level.
///
/// Segments (left→right): BEARISH(red) → CAUTIOUS(orange) → NEUTRAL(grey)
///                         → POSITIVE(green) → BULLISH(blue)
class MacroGaugePainter extends CustomPainter {
  final String? riskLevel;
  final Color needleColor;
  final Color innerDotColor;

  MacroGaugePainter({
    required this.riskLevel,
    required this.needleColor,
    required this.innerDotColor,
  });

  // 5 segments, each 36° of the 180° semicircle
  static const _segments = [
    ('BEARISH', Color(0xFFF44336)),   // red — matches MarketLensColors.lossColor
    ('CAUTIOUS', Color(0xFFFB8C00)),  // orange
    ('NEUTRAL', Color(0xFF9E9E9E)),   // grey — matches MarketLensColors.neutralColor
    ('POSITIVE', Color(0xFF4CAF50)),  // green — matches MarketLensColors.gainColor
    ('BULLISH', Color(0xFF1E88E5)),   // blue
  ];

  /// Map riskLevel to needle angle (radians from left = π)
  double _needleAngle() {
    // Default to center (NEUTRAL)
    const mapping = {
      'BEARISH': 18.0,
      'CRITICAL': 18.0,
      'CAUTIOUS': 54.0,
      'WARNING': 54.0,
      'NEUTRAL': 90.0,
      'NORMAL': 90.0,
      'POSITIVE': 126.0,
      'BULLISH': 162.0,
    };
    final degrees = mapping[riskLevel] ?? 90.0;
    // Convert: 0° = leftmost (π radians), 180° = rightmost (0 radians)
    return pi - (degrees * pi / 180);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.78; // push center down so arc fits nicely
    final radius = min(centerX, size.height * 0.72);
    final arcWidth = radius * 0.18;

    final center = Offset(centerX, centerY);
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    // Draw 5 arc segments
    const segmentSweep = pi / 5; // 36°
    for (int i = 0; i < _segments.length; i++) {
      final paint = Paint()
        ..color = _segments[i].$2.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = arcWidth
        ..strokeCap = i == 0
            ? StrokeCap.round
            : i == _segments.length - 1
                ? StrokeCap.round
                : StrokeCap.butt;

      // Start from π (left), sweep clockwise through top to right (upward arc)
      final startAngle = pi + (i * segmentSweep);
      canvas.drawArc(arcRect, startAngle, segmentSweep, false, paint);
    }

    // Draw needle
    final angle = _needleAngle();
    final needleLength = radius * 0.72;
    final needleEnd = Offset(
      centerX + needleLength * cos(angle),
      centerY - needleLength * sin(angle),
    );

    // Needle line
    final needlePaint = Paint()
      ..color = needleColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needlePaint);

    // Needle center dot
    final dotPaint = Paint()
      ..color = needleColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, dotPaint);

    // Inner dot (accent)
    final innerDotPaint = Paint()
      ..color = innerDotColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2, innerDotPaint);
  }

  @override
  bool shouldRepaint(covariant MacroGaugePainter oldDelegate) {
    return oldDelegate.riskLevel != riskLevel ||
        oldDelegate.needleColor != needleColor ||
        oldDelegate.innerDotColor != innerDotColor;
  }
}
