import 'package:flutter/material.dart';

Future<T?> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required T selected,
  required Map<T, String> options,
}) => showModalBottomSheet<T>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => DraggableScrollableSheet(
    initialChildSize: 0.55,
    minChildSize: 0.3,
    maxChildSize: 0.85,
    expand: false,
    builder: (context, controller) => ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        for (final entry in options.entries)
          ListTile(
            title: Text(entry.value),
            trailing: selected == entry.key
                ? Icon(
                    Icons.check_circle_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () => Navigator.pop(context, entry.key),
          ),
      ],
    ),
  ),
);
