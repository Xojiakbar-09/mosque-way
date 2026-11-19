import 'package:flutter/material.dart';

import '../../../../core/localization/app_strings.dart';

/// Shown while the location or the first compass sample is being awaited.
class QiblaLoadingIndicator extends StatelessWidget {
  const QiblaLoadingIndicator({super.key, required this.messageKey});

  /// `AppStrings` key for the hint text below the spinner.
  final String messageKey;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return Column(
      children: [
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 12),
        Text(t(messageKey), textAlign: TextAlign.center),
      ],
    );
  }
}
