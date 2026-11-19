import 'package:flutter/material.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../prayer/repository/prayer_schedule.dart';

class NextPrayerCard extends StatelessWidget {
  const NextPrayerCard({super.key, required this.schedule, required this.now});
  final PrayerSchedule schedule;
  final DateTime now;
  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final next = schedule.next(now);
    final remaining = next?.instant.difference(now);
    String two(int n) => n.toString().padLeft(2, '0');
    final countdown = remaining == null
        ? ''
        : '${two(remaining.inHours)}:${two(remaining.inMinutes % 60)}:${two(remaining.inSeconds % 60)}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF218A66), Color(0xFF0B503C)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.nights_stay_outlined, color: Colors.white70),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t('next'),
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              if (next?.tomorrow == true)
                Text(
                  t('tomorrow'),
                  style: const TextStyle(color: Colors.white70),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            next == null ? t('finished') : t(next.key),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 28,
            ),
          ),
          if (next != null) ...[
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                countdown,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 46,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w300,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${next.clock} · ${schedule.timezone}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}
