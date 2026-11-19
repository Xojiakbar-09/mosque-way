import 'package:flutter/material.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/glass_panel.dart';

/// Zoom, 2D/3D va GPS tugmalari. Faqat UI; logika MapPage'da.
class MapControls extends StatelessWidget {
  const MapControls({
    super.key,
    required this.is3D,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onToggle3D,
    required this.onMyLocation,
  });

  final bool is3D;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onToggle3D;
  final VoidCallback onMyLocation;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return GlassPanel(
      radius: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _action(context, Icons.add, t('zoomIn'), onZoomIn),
          _divider,
          _action(context, Icons.remove, t('zoomOut'), onZoomOut),
          _divider,
          _action(
            context,
            Icons.layers_outlined,
            '2D / 3D',
            onToggle3D,
            selected: is3D,
          ),
          _divider,
          _action(
            context,
            Icons.near_me_outlined,
            t('myLocation'),
            onMyLocation,
          ),
        ],
      ),
    );
  }

  static const _divider = SizedBox(
    width: 30,
    child: Divider(height: 1, thickness: 0.5),
  );

  Widget _action(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool selected = false,
  }) {
    return IconButton(
      tooltip: label,
      isSelected: selected,
      onPressed: onTap,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      icon: Icon(
        icon,
        size: 22,
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
