import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../localization/app_strings.dart';

class UserIdentity extends StatelessWidget {
  const UserIdentity({super.key, required this.user, this.subtitle});
  final User user;
  final String? subtitle;
  @override
  Widget build(BuildContext context) {
    final text = AppStrings.of(context);
    final name = user.displayName?.trim();
    final label = name != null && name.isNotEmpty
        ? name
        : user.email?.split('@').first ?? text('user');
    final photo = user.photoURL;
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: photo == null
              ? Text(label.characters.first.toUpperCase())
              : ClipOval(
                  child: Image.network(
                    photo,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stack) =>
                        const Icon(Icons.person_outline_rounded),
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
