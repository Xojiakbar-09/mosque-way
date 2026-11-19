import 'package:flutter/material.dart';

import '../../../../core/consts/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/glass_panel.dart';

/// GPS yuklanayotgan paytda ixcham holat belgisi.
class LocationLoadingBanner extends StatelessWidget {
  const LocationLoadingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 12),
            Flexible(
              child: Text(
                AppStrings.of(context)('locating'),
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
