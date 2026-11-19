import 'package:flutter/material.dart';

import '../../../../core/localization/app_strings.dart';

/// Hint shown when the magnetometer needs calibration.
class QiblaCalibrationHint extends StatelessWidget {
  const QiblaCalibrationHint({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Text(t('qiblaCalibration'), textAlign: TextAlign.center),
    );
  }
}
