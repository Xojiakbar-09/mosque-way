import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/consts/app_colors.dart';
import '../../core/widgets/entrance_transition.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/location_halo.dart';
import '../map/presentation/map_page.dart';
import 'presentation/bloc/promision_bloc.dart';
import 'presentation/bloc/promision_event.dart';
import 'presentation/bloc/promision_state.dart';

/// Ilovaning boshlanish ekrani: joylashuvga ruxsat so'raydi,
/// lokatsiyani aniqlaydi va xaritaga o'tish imkonini beradi.
class PromisionPage extends StatelessWidget {
  const PromisionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PromisionBloc()..add(const PromisionCheckRequested()),
      child: const _PromisionView(),
    );
  }
}

class _PromisionView extends StatelessWidget {
  const _PromisionView();

  void _openMap(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MapPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE9F3EB), Color(0xFFFAFCF8), Color(0xFFEDF3EE)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: EntranceTransition(
                  child: GlassPanel(
                    padding: const EdgeInsets.all(28),
                    radius: 36,
                    child: BlocBuilder<PromisionBloc, PromisionState>(
                      builder: (context, state) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const LocationHalo(child: _LocationBadge()),
                          const SizedBox(height: 16),
                          const Text(
                            'JOYLASHUV',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Yo‘l shu yerdan\nboshlanadi.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              letterSpacing: -1,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Yaqin masjidlarni ko‘rish uchun joylashuvingizga ruxsat bering.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const _PermissionBenefit(
                            icon: Icons.explore_outlined,
                            title: 'Atrofingizdagi masjidlar',
                            subtitle: 'Joriy joylashuvingiz yaqinidan izlash',
                          ),
                          const SizedBox(height: 12),
                          const _PermissionBenefit(
                            icon: Icons.route_outlined,
                            title: 'Aniqroq yo‘l',
                            subtitle:
                                'Sizdan masjidgacha masofa va taxminiy vaqt',
                          ),
                          const SizedBox(height: 26),
                          AnimatedSize(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            child: _StatusContent(
                              state: state,
                              onOpenMap: () => _openMap(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Yuqoridagi dumaloq lokatsiya belgisi.
class _LocationBadge extends StatelessWidget {
  const _LocationBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF55A981), AppColors.primary],
        ),
        borderRadius: BorderRadius.all(Radius.circular(30)),
      ),
      child: const Icon(Icons.near_me_rounded, color: Colors.white, size: 48),
    );
  }
}

/// Holatga qarab: spinner, davlat/shahar yoki xato xabari.
class _StatusContent extends StatelessWidget {
  const _StatusContent({required this.state, required this.onOpenMap});

  final PromisionState state;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case PromisionStatus.checking:
        return const Column(
          children: [
            Text(
              'Joylashuvga ruxsat so\'ralmoqda...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: AppColors.primary),
          ],
        );
      case PromisionStatus.granted:
        return Column(
          children: [
            Text(
              [state.city, state.country]
                  .whereType<String>()
                  .where((part) => part.trim().isNotEmpty)
                  .join(', '),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: onOpenMap,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Xaritani ochish',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      case PromisionStatus.error:
        return Column(
          children: [
            Text(
              state.message ?? 'Joylashuvga ruxsat berilmadi.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.error),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: () => context.read<PromisionBloc>().add(
                  const PromisionCheckRequested(),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Qayta urinish',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: onOpenMap,
              child: const Text('Xaritani ochish'),
            ),
          ],
        );
    }
  }
}

class _PermissionBenefit extends StatelessWidget {
  const _PermissionBenefit({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFE5F1E9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 22, color: AppColors.primary),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
