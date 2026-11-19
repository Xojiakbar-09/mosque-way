import 'package:flutter/material.dart';

import '../consts/app_colors.dart';

class LocationHalo extends StatelessWidget {
  const LocationHalo({super.key, required this.child, this.size = 150});
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 1100),
    curve: Curves.easeOutCubic,
    child: child,
    builder: (context, value, child) => SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final factor in [1.0, 0.77])
            Transform.scale(
              scale: .8 + .2 * value,
              child: Container(
                width: size * factor,
                height: size * factor,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: .035),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: .10),
                  ),
                ),
              ),
            ),
          Transform.scale(scale: .94 + .06 * value, child: child),
        ],
      ),
    ),
  );
}
