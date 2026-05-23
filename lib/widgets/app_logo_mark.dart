import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Vector-style logo mark for Flood Guard AI (no image asset required).
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({
    super.key,
    this.size = 88,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Flood Guard AI logo',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(size * 0.22),
          border: Border.all(color: AppColors.divider),
        ),
        child: CustomPaint(
          painter: _LogoPainter(foreground: AppColors.ctaBackground),
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({required this.foreground});

  final Color foreground;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final shieldPath = Path()
      ..moveTo(w * 0.5, h * 0.18)
      ..quadraticBezierTo(w * 0.82, h * 0.32, w * 0.82, h * 0.52)
      ..quadraticBezierTo(w * 0.82, h * 0.78, w * 0.5, h * 0.88)
      ..quadraticBezierTo(w * 0.18, h * 0.78, w * 0.18, h * 0.52)
      ..quadraticBezierTo(w * 0.18, h * 0.32, w * 0.5, h * 0.18)
      ..close();

    final shieldPaint = Paint()
      ..color = AppColors.divider
      ..style = PaintingStyle.fill;
    canvas.drawPath(shieldPath, shieldPaint);

    final stroke = Paint()
      ..color = foreground
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(shieldPath, stroke);

    final dropPath = Path()
      ..moveTo(w * 0.5, h * 0.36)
      ..quadraticBezierTo(w * 0.66, h * 0.52, w * 0.5, h * 0.68)
      ..quadraticBezierTo(w * 0.34, h * 0.52, w * 0.5, h * 0.36)
      ..close();

    final dropPaint = Paint()
      ..color = foreground
      ..style = PaintingStyle.fill;
    canvas.drawPath(dropPath, dropPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
