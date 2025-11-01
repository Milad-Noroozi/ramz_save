import 'package:flutter/material.dart';
import 'dart:math';

import 'package:ramz_save/config/app_colors.dart';

class SafetyScoreGauge extends StatelessWidget {
  final double percentage;
  final String label;

  const SafetyScoreGauge({
    Key? key,
    required this.percentage,
    this.label = 'Safety Score',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 180,
      child: CustomPaint(
        painter: GaugePainter(
          percentage: percentage,
          backgroundColor: Color(0xFF2D3748),
          gradientColors: [
            Color(0xFF5C50F3), // Blue
            AppColors.green, // Green
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              Text(
                '${percentage.toInt()}%',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GaugePainter extends CustomPainter {
  final double percentage;
  final Color backgroundColor;
  final List<Color> gradientColors;

  GaugePainter({
    required this.percentage,
    required this.backgroundColor,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 40);
    final radius = size.width / 2 - 10;
    final strokeWidth = 14.0;

    // نیم دایره داخلی (زیر نیم دایره اصلی)
    final innerRadius = radius - 30;
    final innerStrokeWidth = 20.0;
    
    final innerPaint = Paint()
      ..color = AppColors.darkBgTertiary // رنگ یکپارچه
      ..style = PaintingStyle.stroke
      ..strokeWidth = innerStrokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      pi, // شروع از سمت چپ
      pi, // رسم 180 درجه
      false,
      innerPaint,
    );

    // Background arc (نیم دایره اصلی)
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi, // شروع از سمت چپ
      pi, // رسم 180 درجه
      false,
      backgroundPaint,
    );

    // Progress arc with gradient
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
  bool shouldRepaint(GaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}