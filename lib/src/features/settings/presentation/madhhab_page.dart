import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/widgets/glass_panel.dart';
import '../repository/app_settings.dart';
import 'bloc/settings_bloc.dart';

class MadhhabPage extends StatefulWidget {
  const MadhhabPage({super.key});
  @override
  State<MadhhabPage> createState() => _MadhhabPageState();
}

class _MadhhabPageState extends State<MadhhabPage> {
  Madhhab? get _selected => context.read<SettingsBloc>().state.selectedMadhhab;
  bool get _saving => context.read<SettingsBloc>().state.saving;
  void _save() {
    final selected = _selected;
    if (selected == null || _saving) return;
    final bloc = context.read<SettingsBloc>();
    final event = SettingsUpdateRequested(
      bloc.state.copyWith(madhhab: selected),
    );
    unawaited(event.done.catchError((Object _) {}));
    bloc.add(event);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsBloc>();
    final t = AppStrings.of(context);
    return BlocListener<SettingsBloc, SettingsState>(
      listenWhen: (a, b) => a.errorKey != b.errorKey && b.errorKey != null,
      listener: (context, state) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t(state.errorKey!)))),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.nights_stay_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      t('chooseMadhhab'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Text(t('madhhabHint'), textAlign: TextAlign.center),
                    const SizedBox(height: 28),
                    GlassPanel(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          for (final madhhab in Madhhab.values)
                            ListTile(
                              title: Text(t(madhhab.name)),
                              trailing: Icon(
                                _selected == madhhab
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onTap: _saving
                                  ? null
                                  : () => context.read<SettingsBloc>().add(
                                      SettingsMadhhabSelected(madhhab),
                                    ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t('asrHint'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _selected == null || _saving ? null : _save,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(t('continue')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
