import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/app_strings.dart';
import '../../hadith/presentation/hadith_page.dart';
import '../../home/presentation/home_page.dart';
import '../../map/presentation/map_page.dart';
import '../../prayer/presentation/bloc/prayer_bloc.dart';
import '../../settings/presentation/bloc/settings_bloc.dart';
import '../../settings/presentation/settings_page.dart';
import 'bloc/navigation_bloc.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.user});
  final User user;
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int get _index => context.read<NavigationBloc>().state.index;
  bool get _mapOpened => context.read<NavigationBloc>().state.mapOpened;
  bool get _hadithOpened => context.read<NavigationBloc>().state.hadithOpened;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<PrayerBloc>().add(
      PrayerLoadRequested(context.read<SettingsBloc>().state),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<PrayerBloc>().add(
        PrayerLoadRequested(context.read<SettingsBloc>().state),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<NavigationBloc>();
    final t = AppStrings.of(context);
    final settings = context.watch<SettingsBloc>().state;
    final prayer = context.watch<PrayerBloc>().state;
    final location = prayer.locationConfirmed
        ? prayer.schedule?.location
        : null;
    return MultiBlocListener(
      listeners: [
        BlocListener<SettingsBloc, SettingsState>(
          listenWhen: (a, b) =>
              a.madhhab != b.madhhab ||
              a.calculationMethod != b.calculationMethod,
          listener: (context, s) =>
              context.read<PrayerBloc>().add(PrayerLoadRequested(s)),
        ),
      ],
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            HomePage(user: widget.user),
            _mapOpened
                ? MapPage(
                    defaults: settings,
                    active: _index == 1,
                    locationKey: location == null
                        ? null
                        : '${location.latitude}:${location.longitude}',
                  )
                : const SizedBox.shrink(),
            _hadithOpened ? const HadithPage() : const SizedBox.shrink(),
            SettingsPage(user: widget.user),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) =>
              context.read<NavigationBloc>().add(NavigationTabSelected(value)),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: t('home'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.map_outlined),
              selectedIcon: const Icon(Icons.map_rounded),
              label: t('map'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              selectedIcon: const Icon(Icons.menu_book_rounded),
              label: t('hadith'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings_rounded),
              label: t('settings'),
            ),
          ],
        ),
      ),
    );
  }
}
