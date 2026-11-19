import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/localization/app_strings.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../../core/widgets/user_identity.dart';
import '../../map/presentation/map_light_preset.dart';
import '../../map/repository/directions_profile.dart';
import '../../prayer/repository/calculation_methods.dart';
import '../repository/app_settings.dart';
import 'bloc/settings_bloc.dart';
import 'widgets/setting_section.dart';
import 'widgets/choice_sheet.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.user});
  final User user;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool get _busy =>
      context.read<SettingsBloc>().state.saving ||
      context.read<AuthBloc>().state.busy;

  Future<void> _choose<T>(
    String title,
    T selected,
    Map<T, String> options,
    AppSettings Function(AppSettings, T) update,
  ) async {
    if (_busy) return;
    final result = await showChoiceSheet<T>(
      context,
      title: title,
      selected: selected,
      options: options,
    );
    if (!mounted || result == null) return;
    final bloc = context.read<SettingsBloc>();
    final event = SettingsUpdateRequested(update(bloc.state, result));
    // State reports errors; consume the legacy completion future as well.
    unawaited(event.done.catchError((Object _) {}));
    bloc.add(event);
  }

  Future<void> _clearCache() async {
    final t = AppStrings.of(context);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('clearCache')),
        content: Text(t('cacheClearBoth')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('clearCache')),
          ),
        ],
      ),
    );
    if (!mounted || accepted != true) return;
    context.read<SettingsBloc>().add(const SettingsCachesClearRequested());
  }

  void _sources() {
    final t = AppStrings.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('source')),
        content: SingleChildScrollView(
          child: SelectableText(
            'AlAdhan / Islamic Network\n'
            'https://aladhan.com/prayer-times-api\n\n${t('sourceNote')}\n\n'
            '© OpenStreetMap contributors · ODbL\nhttps://www.openstreetmap.org/copyright\nOverpass API',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final s = context.watch<SettingsBloc>().state;
    Widget tile(
      String title,
      String value,
      IconData icon,
      VoidCallback action,
    ) => ListTile(
      enabled: !_busy,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: action,
    );
    context.watch<AuthBloc>();
    return BlocListener<SettingsBloc, SettingsState>(
      listenWhen: (a, b) =>
          a.cacheRevision != b.cacheRevision ||
          (a.errorKey != b.errorKey && b.errorKey != null),
      listener: (context, state) {
        if (state.errorKey != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(t(state.errorKey!))));
        }
        if (state.errorKey == null && state.cacheRevision > 0) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(t('cacheCleared'))));
        }
      },
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (a, b) => a.errorKey != b.errorKey && b.errorKey != null,
        listener: (context, state) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t(state.errorKey!)))),
        child: Scaffold(
          appBar: AppBar(title: Text(t('settings'))),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              UserIdentity(user: widget.user, subtitle: widget.user.email),
              const SizedBox(height: 12),
              Text(
                widget.user.providerData.map((p) => p.providerId).join(' · '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 28),
              SettingSection(
                title: t('prayerTimes'),
                children: [
                  tile(
                    t('madhhab'),
                    t(s.madhhab!.name),
                    Icons.nights_stay_outlined,
                    () => _choose(t('madhhab'), s.madhhab!, {
                      for (final m in Madhhab.values) m: t(m.name),
                    }, (s, Madhhab v) => s.copyWith(madhhab: v)),
                  ),
                  tile(
                    t('method'),
                    s.calculationMethod == null
                        ? t('auto')
                        : t(CalculationMethods.names[s.calculationMethod]!),
                    Icons.calculate_outlined,
                    () => _choose(
                      t('method'),
                      s.calculationMethod ?? -1,
                      {
                        -1: t('auto'),
                        for (final entry in CalculationMethods.names.entries)
                          entry.key: t(entry.value),
                      },
                      (s, int v) => s.copyWith(
                        calculationMethod: v == -1 ? null : v,
                        automaticMethod: v == -1,
                      ),
                    ),
                  ),
                ],
              ),
              SettingSection(
                title: t('appearance'),
                children: [
                  tile(
                    t('language'),
                    {
                      'uz': 'O‘zbekcha',
                      'ru': 'Русский',
                      'en': 'English',
                    }[s.language]!,
                    Icons.translate_rounded,
                    () => _choose(
                      t('language'),
                      s.language,
                      {'uz': 'O‘zbekcha', 'ru': 'Русский', 'en': 'English'},
                      (s, String v) => s.copyWith(language: v),
                    ),
                  ),
                  tile(
                    t('theme'),
                    t(s.themeMode.name),
                    Icons.contrast_rounded,
                    () => _choose(
                      t('theme'),
                      s.themeMode,
                      {for (final mode in ThemeMode.values) mode: t(mode.name)},
                      (s, ThemeMode v) => s.copyWith(themeMode: v),
                    ),
                  ),
                ],
              ),
              SettingSection(
                title: t('mapDefaults'),
                children: [
                  tile(
                    t('mapLight'),
                    t(s.mapPreset.name),
                    Icons.wb_sunny_outlined,
                    () => _choose(
                      t('mapLight'),
                      s.mapPreset,
                      {for (final p in MapLightPreset.values) p: t(p.name)},
                      (s, MapLightPreset v) => s.copyWith(mapPreset: v),
                    ),
                  ),
                  SwitchListTile(
                    title: Text(t('map3D')),
                    secondary: const Icon(Icons.view_in_ar_rounded),
                    value: s.map3D,
                    onChanged: _busy
                        ? null
                        : (v) {
                            final c = context.read<SettingsBloc>();
                            final event = SettingsUpdateRequested(
                              c.state.copyWith(map3D: v),
                            );
                            unawaited(event.done.catchError((Object _) {}));
                            c.add(event);
                          },
                  ),
                  tile(
                    t('transport'),
                    t(s.routeProfile.name),
                    Icons.route_outlined,
                    () => _choose(
                      t('transport'),
                      s.routeProfile,
                      {for (final p in DirectionsProfile.values) p: t(p.name)},
                      (s, DirectionsProfile v) => s.copyWith(routeProfile: v),
                    ),
                  ),
                ],
              ),
              SettingSection(
                title: t('cacheAll'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(t('cacheSevenDays')),
                  ),
                  ListTile(
                    enabled: !_busy,
                    leading: const Icon(Icons.delete_outline_rounded),
                    title: Text(t('clearCache')),
                    subtitle: Text(t('cacheClearBoth')),
                    onTap: _clearCache,
                  ),
                ],
              ),
              SettingSection(
                title: t('settings'),
                children: [
                  ListTile(
                    leading: const Icon(Icons.my_location_rounded),
                    title: Text(t('location')),
                    onTap: () => Geolocator.openAppSettings(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: Text(t('source')),
                    onTap: _sources,
                  ),
                  ListTile(
                    enabled: !_busy && !context.watch<AuthBloc>().state.busy,
                    leading: const Icon(Icons.logout_rounded),
                    title: Text(t('signOut')),
                    onTap: () => context.read<AuthBloc>().add(
                      const AuthSignOutRequested(),
                    ),
                  ),
                ],
              ),
              if (_busy) const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}
