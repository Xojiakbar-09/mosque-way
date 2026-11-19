import 'package:flutter/material.dart';

import '../../../../core/widgets/entrance_transition.dart';
import '../map_light_preset.dart';
import 'map_controls.dart';
import 'map_theme_button.dart';

/// Xaritaning o'ng tomonidagi boshqaruv paneli:
/// yorug'lik rejimi tanlagichi va zoom / 2D-3D / GPS tugmalari.
class MapSideControls extends StatelessWidget {
  const MapSideControls({
    super.key,
    required this.preset,
    required this.onPresetSelected,
    required this.is3D,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onToggle3D,
    required this.onMyLocation,
  });

  final MapLightPreset preset;
  final ValueChanged<MapLightPreset> onPresetSelected;
  final bool is3D;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onToggle3D;
  final VoidCallback onMyLocation;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: EntranceTransition(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MapThemeButton(preset: preset, onSelected: onPresetSelected),
            const SizedBox(height: 12),
            MapControls(
              is3D: is3D,
              onZoomIn: onZoomIn,
              onZoomOut: onZoomOut,
              onToggle3D: onToggle3D,
              onMyLocation: onMyLocation,
            ),
          ],
        ),
      ),
    );
  }
}
