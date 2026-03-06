import 'package:flutter/material.dart';
import 'dart:math' as math;

class TurkishFlag extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const TurkishFlag({
    super.key,
    this.width = 44,
    this.height = 28,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE30A17), // Turkish Red
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CustomPaint(
          size: Size(width, height),
          painter: _TurkishFlagPainter(),
        ),
      ),
    );
  }
}

class _TurkishFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE30A17)
      ..style = PaintingStyle.fill;

    // Background Red
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Outer Crescent Circle (White)
    final outerCircleCenter = Offset(size.width * 0.35, size.height * 0.5);
    final outerCircleRadius = size.height * 0.3;
    paint.color = Colors.white;
    canvas.drawCircle(outerCircleCenter, outerCircleRadius, paint);

    // Inner Crescent Circle (Red)
    final innerCircleCenter = Offset(size.width * 0.42, size.height * 0.5);
    final innerCircleRadius = size.height * 0.24;
    paint.color = const Color(0xFFE30A17);
    canvas.drawCircle(innerCircleCenter, innerCircleRadius, paint);

    // Star
    paint.color = Colors.white;
    final starCenter = Offset(size.width * 0.65, size.height * 0.5);
    final starOuterRadius = size.height * 0.14;
    final starInnerRadius = size.height * 0.055;

    final path = Path();
    const numPoints = 5;
    // Rotate the star so one point points towards the crescent (left)
    double angle = math.pi;

    for (int i = 0; i < numPoints * 2; i++) {
      final radius = i.isEven ? starOuterRadius : starInnerRadius;
      final x = starCenter.dx + radius * math.cos(angle);
      final y = starCenter.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      angle += math.pi / numPoints;
    }
    path.close();

    // Rotate the star a bit to make it look exactly like the Turkish flag
    canvas.save();
    canvas.translate(starCenter.dx, starCenter.dy);
    canvas.rotate(math.pi / 10);
    canvas.translate(-starCenter.dx, -starCenter.dy);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
