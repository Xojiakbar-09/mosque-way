import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/glass_panel.dart';

class QiblaCard extends StatelessWidget {
  const QiblaCard({super.key});
  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return GlassPanel(
      radius: 24,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          Icons.explore_rounded,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          t('qibla'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(t('qiblaHint')),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.pushNamed(context, '/qibla'),
      ),
    );
  }
}
