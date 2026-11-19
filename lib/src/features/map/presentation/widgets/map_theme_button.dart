import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../map_light_preset.dart';
import 'map_button.dart';

class MapThemeButton extends StatelessWidget {
  const MapThemeButton({
    super.key,
    required this.preset,
    required this.onSelected,
  });
  final MapLightPreset preset;
  final ValueChanged<MapLightPreset> onSelected;
  Future<void> _openMenu(BuildContext context) async {
    final t = AppStrings.of(context);
    final selected = await showModalBottomSheet<MapLightPreset>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              t('mapLight'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final option in MapLightPreset.values)
            ListTile(
              leading: Icon(option.icon),
              title: Text(t(option.name)),
              trailing: option == preset
                  ? const Icon(Icons.check_circle_rounded)
                  : null,
              onTap: () => Navigator.pop(context, option),
            ),
        ],
      ),
    );
    if (selected != null) onSelected(selected);
  }

  @override
  Widget build(BuildContext context) => MapButton(
    icon: preset.icon,
    tooltip:
        '${AppStrings.of(context)('mapLight')}: ${AppStrings.of(context)(preset.name)}',
    onPressed: () => _openMenu(context),
  );
}
