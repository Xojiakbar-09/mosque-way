import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/localization/app_strings.dart';
import '../bloc/qibla_bloc.dart';

class CompassDial extends StatelessWidget {
  const CompassDial({super.key, required this.state});

  final QiblaState state;

  static const double _maxSize = 320;
  static const double _centerCircleRatio = 0.44;
  static const double _needleSizeRatio = 0.36;
  static const double _mosqueBottomRatio = 0.19;
  static const double _needlePlaceholderSize = 64;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final t = AppStrings.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(_maxSize, constraints.maxWidth);
        return Center(
          child: SizedBox.square(
            dimension: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: AnimatedRotation(
                    turns: state.dialDegrees / 360,
                    duration: disableAnimations
                        ? Duration.zero
                        : const Duration(milliseconds: 80),
                    curve: Curves.linear,
                    child: CustomPaint(
                      painter: _DialPainter(
                        color: colors.onSurfaceVariant,
                        labels: [t('north'), t('east'), t('south'), t('west')],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  child: Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 34,
                    color: colors.primary,
                  ),
                ),
                Container(
                  width: size * _centerCircleRatio,
                  height: size * _centerCircleRatio,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primaryContainer.withValues(alpha: .5),
                  ),
                ),
                if (state.heading != null)
                  AnimatedRotation(
                    turns: state.needleDegrees / 360,
                    duration: disableAnimations
                        ? Duration.zero
                        : const Duration(milliseconds: 80),
                    curve: Curves.linear,
                    child: Icon(
                      Icons.navigation_rounded,
                      size: size * _needleSizeRatio,
                      color: state.aligned
                          ? colors.primary
                          : colors.onPrimaryContainer,
                    ),
                  )
                else
                  Icon(
                    Icons.explore_outlined,
                    size: _needlePlaceholderSize,
                    color: colors.outline,
                  ),
                Positioned(
                  bottom: size * _mosqueBottomRatio,
                  child: Icon(
                    Icons.mosque_outlined,
                    size: 24,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({required this.color, required this.labels});
  final Color color;
  final List<String> labels;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    final paint = Paint()
      ..color = color.withValues(alpha: .35)
      ..strokeWidth = 1.5;
    for (var i = 0; i < 72; i++) {
      final angle = i * math.pi / 36;
      final length = i % 6 == 0 ? 12.0 : 5.0;
      Offset point(double r) =>
          center + Offset(math.sin(angle) * r, -math.cos(angle) * r);
      canvas.drawLine(point(radius), point(radius - length), paint);
    }
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final text = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final point =
          center +
          Offset(
            math.sin(angle) * (radius - 30),
            -math.cos(angle) * (radius - 30),
          );
      text.paint(canvas, point - Offset(text.width / 2, text.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) =>
      old.color != color || old.labels.join() != labels.join();
}
