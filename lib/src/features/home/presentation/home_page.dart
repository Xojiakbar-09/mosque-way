import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/widgets/user_identity.dart';
import '../../prayer/presentation/bloc/prayer_bloc.dart';
import '../../prayer/repository/calculation_methods.dart';
import '../../settings/presentation/bloc/settings_bloc.dart';
import 'widgets/next_prayer_card.dart';
import 'widgets/prayer_times_card.dart';
import 'widgets/qibla_card.dart';
import 'bloc/clock_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.user});
  final User user;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ClockBloc(),
    child: _HomeView(user: user),
  );
}

class _HomeView extends StatefulWidget {
  const _HomeView({required this.user});
  final User user;
  @override
  State<_HomeView> createState() => _HomePageState();
}

class _HomePageState extends State<_HomeView> {
  DateTime get _now => context.read<ClockBloc>().state;
  void _onTick(BuildContext context, DateTime now) =>
      context.read<PrayerBloc>().add(PrayerClockTicked(now));

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    context.watch<ClockBloc>();
    return BlocListener<ClockBloc, DateTime>(
      listener: _onTick,
      child: BlocBuilder<PrayerBloc, PrayerState>(
        builder: (context, state) {
          final schedule = state.schedule;
          final day = schedule?.dayAt(_now);
          final next = schedule?.next(_now);
          final settings = context.watch<SettingsBloc>().state;
          Future<void> refresh() {
            final event = PrayerLoadRequested(settings, force: true);
            context.read<PrayerBloc>().add(event);
            return event.done;
          }

          return Scaffold(
            appBar: AppBar(
              toolbarHeight: 90,
              title: UserIdentity(user: widget.user, subtitle: t('greeting')),
              actions: [
                IconButton(
                  tooltip: t('refresh'),
                  onPressed: state.loading ? null : refresh,
                  icon: const Icon(Icons.refresh_rounded),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  const QiblaCard(),
                  const SizedBox(height: 20),
                  if (state.loading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  if (schedule != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            schedule.location.label.isEmpty
                                ? schedule.timezone
                                : schedule.location.label,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (day != null)
                      Text(
                        '${day.date} · ${day.hijriFor(Localizations.localeOf(context).languageCode)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 20),
                  ],
                  if (!state.locationConfirmed && schedule != null)
                    _Notice(text: t('unconfirmed')),
                  if (state.message != null) _Notice(text: t(state.message!)),
                  if (state.fromCache && day != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '${t('saved')} · ${schedule!.savedAt.toLocal().toString().substring(0, 16)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  if (day != null && schedule != null) ...[
                    NextPrayerCard(schedule: schedule, now: _now),
                    const SizedBox(height: 26),
                    Text(
                      t('prayerTimes'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    PrayerTimesCard(
                      day: day,
                      nextKey: next?.tomorrow == false ? next?.key : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${t(settings.madhhab!.name)} · ${t(CalculationMethods.names[schedule.method] ?? schedule.methodName)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'AlAdhan · ${t('sourceNote')}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ] else if (!state.loading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_off_outlined,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(t('noSchedule'), textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: refresh,
                            child: Text(t('retry')),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(
        context,
      ).colorScheme.secondaryContainer.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(text, style: Theme.of(context).textTheme.bodySmall),
  );
}
