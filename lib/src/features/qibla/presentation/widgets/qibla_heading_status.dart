import 'package:flutter/material.dart';

import '../../../../core/localization/app_strings.dart';

/// Displays the turn/aligned instruction and the current phone heading.
class QiblaHeadingStatus extends StatelessWidget {
  const QiblaHeadingStatus({
    super.key,
    required this.heading,
    required this.aligned,
    this.approximate = false,
  });

  final double heading;
  final bool aligned;

  /// `true` when the heading is a GPS-based approximation, not a real compass.
  final bool approximate;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          t(
            approximate
                ? 'qiblaTurn'
                : (aligned ? 'qiblaAligned' : 'qiblaTurn'),
          ),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${t('qiblaPhoneHeading')}: ${heading.toStringAsFixed(1)}°',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        if (approximate) ...[
          const SizedBox(height: 6),
          Text(
            t('qiblaApproximate'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
