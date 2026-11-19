import 'package:flutter/material.dart';

/// Google "G" belgisini 48 birlikli to'r ustida to'rt bo'lakda chizadi.
class GoogleMarkPainter extends CustomPainter {
  const GoogleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48, size.height / 48);
    final paint = Paint();

    void section(Color color, Path path) =>
        canvas.drawPath(path, paint..color = color);

    section(
      const Color(0xff4285f4),
      Path()
        ..moveTo(43.6, 24.5)
        ..relativeQuadraticBezierTo(0, -2, -.4, -4)
        ..lineTo(24, 20.5)
        ..lineTo(24, 28.3)
        ..lineTo(35, 28.3)
        ..quadraticBezierTo(34, 32.7, 30.8, 34.8)
        ..lineTo(37.2, 39.7)
        ..quadraticBezierTo(43.6, 34, 43.6, 24.5)
        ..close(),
    );
    section(
      const Color(0xff34a853),
      Path()
        ..moveTo(24, 44)
        ..quadraticBezierTo(31.8, 44, 37.2, 39.7)
        ..lineTo(30.8, 34.8)
        ..quadraticBezierTo(28, 36.5, 24, 36.5)
        ..quadraticBezierTo(16, 36.5, 12.4, 28.4)
        ..lineTo(5.8, 33.5)
        ..quadraticBezierTo(12, 44, 24, 44)
        ..close(),
    );
    section(
      const Color(0xfffbbc05),
      Path()
        ..moveTo(12.4, 28.4)
        ..quadraticBezierTo(10.8, 24, 12.4, 19.6)
        ..lineTo(5.8, 14.5)
        ..quadraticBezierTo(1.3, 24, 5.8, 33.5)
        ..close(),
    );
    section(
      const Color(0xffea4335),
      Path()
        ..moveTo(24, 11.5)
        ..quadraticBezierTo(28.5, 11.5, 31.8, 14.5)
        ..lineTo(37.6, 8.8)
        ..quadraticBezierTo(32, 4, 24, 4)
        ..quadraticBezierTo(12, 4, 5.8, 14.5)
        ..lineTo(12.4, 19.6)
        ..quadraticBezierTo(16, 11.5, 24, 11.5)
        ..close(),
    );
  }

  @override
  bool shouldRepaint(GoogleMarkPainter oldDelegate) => false;
}
