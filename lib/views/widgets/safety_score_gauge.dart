import 'dart:math';

import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_strings.dart';
import '../../config/app_text_styles.dart';
import '../../utils/app_helper.dart';

/// The half-circle safety score on the home screen.
///
/// The arc fills from the start edge, which in Persian means it grows from the
/// right — a bar that fills leftward reads as *draining* to an RTL user.
class SafetyScoreGauge extends StatelessWidget {
  final double percentage;
  final String label;
  final double width;

  const SafetyScoreGauge({
    required this.percentage,
    this.label = AppStrings.safetyScore,
    this.width = 250,
    super.key,
  });

  /// Green when healthy, amber in the middle, red when most entries are at
  /// risk — the number and the colour should not disagree.
  Color get _endColor {
    if (percentage >= 75) return AppColors.green;
    if (percentage >= 45) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return SizedBox(
      width: width,
      height: width * 0.72,
      child: CustomPaint(
        painter: _GaugePainter(
          percentage: percentage.clamp(0, 100),
          trackColor: AppColors.inputBg,
          innerColor: AppColors.darkBgTertiary,
          gradientColors: [AppColors.purple, _endColor],
          mirror: rtl,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: width * 0.16),
              Text(
                AppHelper.percent(percentage),
                style: AppTextStyles.h1.copyWith(fontSize: 40),
              ),
              const SizedBox(height: 2),
              Text(label, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double percentage;
  final Color trackColor;
  final Color innerColor;
  final List<Color> gradientColors;

  /// Mirrors the whole drawing horizontally for RTL.
  ///
  /// Flipping the canvas rather than recomputing angles keeps one set of
  /// geometry: the sweep, the gradient and the rounded cap all mirror together
  /// and cannot drift out of agreement.
  final bool mirror;

  _GaugePainter({
    required this.percentage,
    required this.trackColor,
    required this.innerColor,
    required this.gradientColors,
    required this.mirror,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (mirror) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    final center = Offset(size.width / 2, size.height * 0.78);
    final radius = size.width / 2 - 10;
    const strokeWidth = 14.0;

    final innerPaint = Paint()
      ..color = innerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 30),
      pi,
      pi,
      false,
      innerPaint,
    );

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      trackPaint,
    );

    if (percentage <= 0) return;

    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: gradientColors,
        startAngle: pi,
        endAngle: pi * 2,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi * percentage / 100,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.percentage != percentage ||
      old.mirror != mirror ||
      old.gradientColors.last != gradientColors.last;
}
