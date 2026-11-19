import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/map_bloc.dart';

import '../../../../core/consts/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/utils/formatters/route_formatter.dart';
import '../../../../core/widgets/mosque_icon.dart';
import '../../repository/mosque.dart';
import 'route_profile_selector.dart';

class MosqueInfoSheet extends StatelessWidget {
  const MosqueInfoSheet({super.key, required this.mosque});
  final Mosque mosque;

  @override
  Widget build(BuildContext context) => BlocBuilder<MapBloc, MapState>(
    builder: (context, state) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0DCD4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const MosqueIcon(size: 58),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.of(context)('MASJID'),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            mosque.name,
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      tooltip: AppStrings.of(context)('Yopish'),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.of(context)('Manzil'),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mosque.address ??
                                  AppStrings.of(context)(
                                    'Manzil ma’lumoti kiritilmagan',
                                  ),
                              style: const TextStyle(fontSize: 14, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (mosque.phone != null ||
                    mosque.website != null ||
                    mosque.openingHours != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SelectableText(
                      [
                        if (mosque.phone != null)
                          '${AppStrings.of(context)('phone')}: ${mosque.phone}',
                        if (mosque.website != null)
                          '${AppStrings.of(context)('website')}: ${mosque.website}',
                        if (mosque.openingHours != null)
                          '${AppStrings.of(context)('hours')}: ${mosque.openingHours}',
                      ].join('\n'),
                      style: const TextStyle(fontSize: 14, height: 1.6),
                    ),
                  ),
                const SizedBox(height: 16),
                AbsorbPointer(
                  absorbing: state.routeLoading,
                  child: RouteProfileSelector(
                    selected: state.profile,
                    onSelected: (profile) {
                      if (profile == state.profile) return;
                      context.read<MapBloc>().add(MapProfileChanged(profile));
                    },
                  ),
                ),
                const SizedBox(height: 18),
                AnimatedSize(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.route case final route?) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _Metric(
                                icon: Icons.straighten_rounded,
                                label: AppStrings.of(context)('Yo‘l masofasi'),
                                value: formatRouteDistance(route.distance),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _Metric(
                                icon: Icons.schedule_rounded,
                                label: AppStrings.of(context)('Taxminiy vaqt'),
                                value: formatRouteDuration(route.duration),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            AppStrings.of(context)(
                              'Vaqt yo‘l va harakat sharoitiga qarab o‘zgarishi mumkin.',
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                      if (state.routeErrorKey != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(
                            AppStrings.of(context)(state.routeErrorKey!),
                            style: const TextStyle(
                              color: AppColors.error,
                              height: 1.4,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: state.routeLoading
                      ? null
                      : state.route != null
                      ? () => Navigator.pop(context)
                      : () => context.read<MapBloc>().add(
                          MapRouteRequested(mosque, state.profile),
                        ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: state.routeLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.near_me_rounded, size: 20),
                  label: Text(
                    state.routeLoading
                        ? AppStrings.of(context)('Hisoblanmoqda…')
                        : state.route != null
                        ? AppStrings.of(context)('Xaritada ko‘rish')
                        : AppStrings.of(context)('Marshrut'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppStrings.of(context)('Boshlanish: joriy joylashuvingiz'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w700,
            letterSpacing: -.7,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}
