import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/consts/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../repository/directions_profile.dart';

/// Marshrut qanday hisoblanishini tanlash (piyoda, velosiped, avtomobil).
class RouteProfileSelector extends StatelessWidget {
  const RouteProfileSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  /// Har bir profil uchun ikonka va nom.
  static const Map<DirectionsProfile, (IconData, String)> _options = {
    DirectionsProfile.walking: (Icons.directions_walk_rounded, 'Piyoda'),
    DirectionsProfile.cycling: (Icons.directions_bike_rounded, 'Velosiped'),
    DirectionsProfile.driving: (Icons.directions_car_rounded, 'Avtomobil'),
    DirectionsProfile.drivingTraffic: (Icons.traffic_rounded, 'Tirbandlik'),
  };

  final DirectionsProfile selected;
  final ValueChanged<DirectionsProfile> onSelected;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 26,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 3, 8, 7),
              child: Text(
                '${AppStrings.of(context)('Marshrut')} · ${AppStrings.of(context)(selected.name)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            CupertinoSlidingSegmentedControl<DirectionsProfile>(
              groupValue: selected,
              children: {
                for (final entry in _options.entries)
                  entry.key: Tooltip(
                    message: AppStrings.of(context)(entry.key.name),
                    child: SizedBox(
                      height: 40,
                      child: Icon(
                        entry.value.$1,
                        size: 20,
                        color: entry.key == selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
              },
              onValueChanged: (profile) {
                if (profile != null) onSelected(profile);
              },
            ),
          ],
        ),
      ),
    );
  }
}
