import 'package:flutter/material.dart';

import '../../../../core/consts/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/utils/formatters/route_formatter.dart';
import '../../../../core/widgets/entrance_transition.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../repository/directions_route.dart';
import '../../repository/mosque.dart';

/// Xaritaning pastida tanlangan masjid haqidagi ixcham panel.
///
/// Bosilganda batafsil ma'lumot oynasi ochiladi.
class SelectedMosqueBar extends StatelessWidget {
  const SelectedMosqueBar({
    super.key,
    required this.mosque,
    required this.route,
    required this.onTap,
  });

  final Mosque mosque;

  /// Hisoblangan marshrut; `null` bo'lsa taklif matni ko'rsatiladi.
  final DirectionsRoute? route;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final route = this.route;

    return EntranceTransition(
      child: GlassPanel(
        radius: 24,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 8,
          ),
          leading: const Icon(Icons.near_me_rounded, color: AppColors.primary),
          title: Text(
            mosque.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            route == null
                ? AppStrings.of(context)('Ma’lumot va marshrut')
                : '${formatRouteDistance(route.distance)} · '
                      '${formatRouteDuration(route.duration)} · ${AppStrings.of(context)('approx')}',
          ),
          trailing: const Icon(Icons.keyboard_arrow_up_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}
