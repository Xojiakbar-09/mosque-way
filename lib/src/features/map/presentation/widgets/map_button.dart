import 'package:flutter/material.dart';

import '../../../../core/consts/app_colors.dart';
import '../../../../core/widgets/glass_panel.dart';

/// Xarita harakatlari uchun qayta ishlatiladigan minimal tugma.
class MapButton extends StatelessWidget {
  const MapButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.selected = false,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool selected;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 18,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: selected
              ? AppColors.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
        iconSize: 23,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      ),
    );
  }
}
