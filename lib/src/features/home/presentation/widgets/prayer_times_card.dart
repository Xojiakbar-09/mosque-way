import 'package:flutter/material.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../prayer/repository/prayer_schedule.dart';

class PrayerTimesCard extends StatelessWidget {
  const PrayerTimesCard({super.key, required this.day, this.nextKey});
  final PrayerDay day;
  final String? nextKey;
  static const icons = [
    Icons.wb_twilight_rounded,
    Icons.wb_sunny_outlined,
    Icons.light_mode_outlined,
    Icons.sunny_snowing,
    Icons.wb_twilight_outlined,
    Icons.nights_stay_outlined,
  ];
  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return GlassPanel(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          for (var i = 0; i < displayedPrayerKeys.length; i++)
            Builder(
              builder: (context) {
                final key = displayedPrayerKeys[i];
                final highlighted = key == nextKey;
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: highlighted ? primary.withValues(alpha: 0.1) : null,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListTile(
                    leading: Icon(
                      icons[i],
                      color: highlighted ? primary : null,
                    ),
                    title: Text(
                      t(key),
                      style: TextStyle(
                        fontWeight: highlighted
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: Text(
                      day.clock(key),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: highlighted ? primary : null,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
