import 'package:flutter/material.dart';

import '../../../../core/consts/app_colors.dart';

/// Kirish ekranidagi bezak xarita rasmi (foydalanuvchi joylashuviga bog'liq emas).
class MapArtworkPainter extends CustomPainter {
  const MapArtworkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 360, size.height / 230);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 360, 230),
      Paint()..color = const Color(0xFFE9F0EC),
    );

    final block = Paint()..color = const Color(0xFFD1E3D5);
    for (final rect in const [
      Rect.fromLTWH(20, 12, 70, 65),
      Rect.fromLTWH(250, 145, 100, 70),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(18)),
        block,
      );
    }

    final river = Path()
      ..moveTo(320, -10)
      ..cubicTo(255, 75, 360, 110, 290, 240);
    canvas.drawPath(
      river,
      Paint()
        ..color = const Color(0xFFB5DCEB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 30,
    );

    final streets = Path()
      ..moveTo(-10, 125)
      ..lineTo(370, 55)
      ..moveTo(100, -10)
      ..lineTo(180, 240)
      ..moveTo(-10, 210)
      ..lineTo(370, 140);
    canvas.drawPath(
      streets,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14,
    );

    final route = Path()
      ..moveTo(105, 185)
      ..lineTo(156, 175)
      ..quadraticBezierTo(165, 174, 161, 162)
      ..lineTo(142, 98)
      ..lineTo(206, 86);
    canvas.drawPath(
      route,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawCircle(
      const Offset(105, 185),
      7,
      Paint()..color = AppColors.primary,
    );
    canvas.drawCircle(const Offset(105, 185), 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(MapArtworkPainter oldDelegate) => false;
}
