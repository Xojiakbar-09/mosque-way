import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../repository/hadith.dart';

class HadithCard extends StatelessWidget {
  const HadithCard({
    super.key,
    required this.hadith,
    required this.language,
    required this.liked,
    required this.onLike,
  });
  final Hadith hadith;
  final String language;
  final bool liked;
  final VoidCallback? onLike;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: AppStrings.of(context)(
                  liked ? 'hadithUnlike' : 'hadithLike',
                ),
                onPressed: onLike,
                icon: Icon(
                  liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                ),
                color: liked ? theme.colorScheme.primary : null,
              ),
            ),
            if (hadith.categoryFor(language).isNotEmpty) ...[
              Text(
                hadith.categoryFor(language),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (hadith.titleFor(language).isNotEmpty) ...[
              Text(
                hadith.titleFor(language),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
            ],
            SelectableText(
              hadith.textFor(language),
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.65),
            ),
            if (hadith.sourceFor(language).isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                hadith.sourceFor(language),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
