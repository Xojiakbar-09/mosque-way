import 'package:flutter/material.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/glass_panel.dart';

/// Glass card that shows the Qibla bearing from true north.
class QiblaBearingCard extends StatelessWidget {
  const QiblaBearingCard({super.key, required this.bearing});

  final double bearing;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return GlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(t('qiblaBearing'), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            '${bearing.toStringAsFixed(1)}°',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }
}
