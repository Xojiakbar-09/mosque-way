import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_strings.dart';
import '../bloc/qibla_bloc.dart';

/// Error message with a retry button that restarts the bloc.
class QiblaErrorSection extends StatelessWidget {
  const QiblaErrorSection({super.key, required this.messageKey});

  /// `AppStrings` key for the error message.
  final String messageKey;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(t(messageKey), textAlign: TextAlign.center),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () => context.read<QiblaBloc>().add(const QiblaStarted()),
          icon: const Icon(Icons.refresh_rounded),
          label: Text(t('retry')),
        ),
      ],
    );
  }
}
