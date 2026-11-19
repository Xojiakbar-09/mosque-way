import 'package:flutter/material.dart';
import '../../../../core/consts/app_colors.dart';
import '../../repository/mosque_catalog.dart';

class RegionStatusHeader extends StatelessWidget {
  const RegionStatusHeader({
    super.key,
    required this.catalog,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onInfo,
  });
  final MosqueCatalog? catalog;
  final bool loading;
  final String? error;
  final VoidCallback onRefresh;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final data = catalog;
    final date = data?.savedAt.toLocal();
    final updated = date == null
        ? ''
        : '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    final notice = error ?? (loading ? 'Hudud tekshirilmoqda…' : data?.notice);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(
              Icons.location_city_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data?.region.name ?? 'Hududingizdagi masjidlar',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    data == null
                        ? 'Joylashuv bo‘yicha aniqlanadi'
                        : '${data.region.label} · ${data.mosques.length} masjid · ${data.fromCache ? 'Saqlangan' : 'Yangilangan'} $updated',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Ma’lumot manbasi',
              onPressed: onInfo,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.info_outline_rounded, size: 19),
            ),
            IconButton(
              tooltip: 'Masjidlarni yangilash',
              onPressed: loading ? null : onRefresh,
              visualDensity: VisualDensity.compact,
              icon: loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, color: AppColors.primary),
            ),
          ],
        ),
        if (notice != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                notice,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  color: error != null || data?.notice != null
                      ? AppColors.error
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        if (!loading && data != null && !data.locationConfirmed)
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Joriy hudud tasdiqlanmagan — oxirgi kesh ko‘rsatilmoqda.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
        if (!loading && data != null && data.mosques.isEmpty)
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Bu hudud uchun nomi kiritilgan masjid topilmadi.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}
