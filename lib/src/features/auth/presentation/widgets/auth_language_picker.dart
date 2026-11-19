import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/consts/app_colors.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';

class AuthLanguagePicker extends StatelessWidget {
  const AuthLanguagePicker({super.key});
  @override
  Widget build(BuildContext context) {
    final language = context.watch<SettingsBloc>().state.language;
    return PopupMenuButton<String>(
      tooltip: AppStrings.of(context)('language'),
      initialValue: language,
      onSelected: (value) async {
        final bloc = context.read<SettingsBloc>();
        try {
          final event = SettingsUpdateRequested(
            bloc.state.copyWith(language: value),
          );
          bloc.add(event);
          await event.done;
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppStrings.of(context)('saveError'))),
            );
          }
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'uz', child: Text('O‘zbekcha')),
        PopupMenuItem(value: 'ru', child: Text('Русский')),
        PopupMenuItem(value: 'en', child: Text('English')),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.language_rounded,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              language.toUpperCase(),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
