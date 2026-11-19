import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_ce/hive.dart';

import 'core/consts/app_themes.dart';
import 'features/hadith/presentation/bloc/hadith_bloc.dart';
import 'features/hadith/presentation/liked_hadiths_page.dart';
import 'features/qibla/presentation/qibla_page.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/auth/presentation/email_auth_page.dart';
import 'features/main/presentation/main_screen.dart';
import 'features/main/presentation/bloc/navigation_bloc.dart';
import 'features/prayer/presentation/bloc/prayer_bloc.dart';
import 'features/prayer/repository/prayer_repository.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/settings/presentation/madhhab_page.dart';
import 'features/settings/repository/app_settings.dart';
import 'features/settings/repository/settings_repository.dart';

class MosqueApp extends StatelessWidget {
  const MosqueApp({
    super.key,
    required this.settingsRepository,
    required this.prayerBox,
  });
  final SettingsRepository settingsRepository;
  final Box<String> prayerBox;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => AuthBloc(AuthRepository()),
    child: _AuthSession(
      settingsRepository: settingsRepository,
      prayerBox: prayerBox,
    ),
  );
}

class _AuthSession extends StatelessWidget {
  const _AuthSession({
    required this.settingsRepository,
    required this.prayerBox,
  });
  final SettingsRepository settingsRepository;
  final Box<String> prayerBox;
  @override
  Widget build(BuildContext context) => BlocBuilder<AuthBloc, AuthState>(
    buildWhen: (previous, current) => previous.user?.uid != current.user?.uid,
    builder: (context, state) {
      final user = state.user;
      return BlocProvider(
        key: ValueKey(user?.uid ?? 'signed-out'),
        create: (_) =>
            SettingsBloc(settingsRepository, user?.uid ?? 'signed-out'),
        child: _AppView(user: user, prayerBox: prayerBox),
      );
    },
  );
}

class _AppView extends StatelessWidget {
  const _AppView({required this.user, required this.prayerBox});
  final User? user;
  final Box<String> prayerBox;
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsBloc>().state;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.light,
      darkTheme: AppThemes.dark,
      themeMode: settings.themeMode,
      locale: Locale(settings.language),
      supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: user == null
          ? const AuthGate()
          : _Session(user: user!, settings: settings, box: prayerBox),
      routes: {
        '/liked-hadiths': (context) => BlocProvider.value(
          value: ModalRoute.of(context)!.settings.arguments as HadithBloc,
          child: const LikedHadithsPage(),
        ),
        '/email-auth': (_) => const EmailAuthPage(),
        '/qibla': (_) => const QiblaPage(),
      },
    );
  }
}

class _Session extends StatelessWidget {
  const _Session({
    required this.user,
    required this.settings,
    required this.box,
  });
  final User user;
  final AppSettings settings;
  final Box<String> box;
  @override
  Widget build(BuildContext context) {
    if (settings.madhhab == null) return const MadhhabPage();
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => PrayerBloc(PrayerRepository(box))),
        BlocProvider(create: (_) => NavigationBloc()),
      ],
      child: MainScreen(user: user),
    );
  }
}
