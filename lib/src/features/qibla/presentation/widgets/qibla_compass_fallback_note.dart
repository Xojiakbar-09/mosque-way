import 'package:flutter/material.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/glass_panel.dart';

/// Informational panel for devices without a compass sensor.
///
/// Unlike an error it is not retryable: the hardware is missing, so it
/// explains the situation and, while no GPS course is available yet, asks the
/// user to move so the fallback can produce a direction.
class QiblaCompassFallbackNote extends StatelessWidget {
  const QiblaCompassFallbackNote({super.key, required this.showMoveHint});

  /// Whether to add the "keep moving" hint (no GPS course received yet).
  final bool showMoveHint;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: GlassPanel(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              t('compassUnsupported'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (showMoveHint) ...[
              const SizedBox(height: 6),
              Text(
                t('qiblaMoveForHeading'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
