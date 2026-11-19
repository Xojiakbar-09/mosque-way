import 'package:flutter/material.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/mosque_icon.dart';
import '../../repository/mosque.dart';

/// Masjid qidiruvi: koordinatalar foydalanuvchiga ko'rsatilmaydi.
class MosqueSearchBar extends StatelessWidget {
  const MosqueSearchBar({
    super.key,
    required this.controller,
    required this.query,
    required this.results,
    required this.showResults,
    required this.isLoading,
    required this.onChanged,
    required this.onSelected,
    this.onTap,
    this.error,
  });

  final VoidCallback? onTap;
  final String? error;
  final TextEditingController controller;
  final String query;
  final List<Mosque> results;
  final bool showResults;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final ValueChanged<Mosque> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;
    final showResultList = showResults && query.trim().isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) => GlassPanel(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              onChanged: onChanged,
              onTap: onTap,
              onSubmitted: (_) {
                if (!isLoading && error == null && results.length == 1) {
                  onSelected(results.single);
                } else {
                  FocusScope.of(context).unfocus();
                }
              },
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: t('search'),
                hintStyle: TextStyle(
                  color: secondary,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(Icons.search_rounded, color: secondary),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: t('clear'),
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                filled: true,
                fillColor: const Color(0x126C7B8B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            if (showResultList) ...[
              const SizedBox(height: 8),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      TextButton(
                        onPressed: () => onChanged(controller.text),
                        child: Text(t('retry')),
                      ),
                    ],
                  ),
                )
              else if (results.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      t('mosqueEmpty'),
                      style: TextStyle(color: secondary),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.separated(
                      shrinkWrap: true,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      itemCount: results.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, indent: 55),
                      itemBuilder: (context, index) {
                        final mosque = results[index];
                        return ListTile(
                          leading: const MosqueIcon(size: 34),
                          title: Text(
                            mosque.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: mosque.address == null
                              ? null
                              : Text(
                                  mosque.address!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: secondary,
                          ),
                          onTap: () => onSelected(mosque),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
