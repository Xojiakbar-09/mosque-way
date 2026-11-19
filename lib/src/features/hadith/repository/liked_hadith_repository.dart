import 'dart:convert';
import 'package:hive_ce/hive.dart';
import 'hadith.dart';

/// Durable, account-scoped local favorites, separate from expiring caches.
class LikedHadithRepository {
  LikedHadithRepository(this.box, this.uid);
  final Box<String> box;
  final String uid;
  String get _key => 'liked_hadiths:$uid';

  List<Hadith> read() {
    final raw = box.get(_key);
    if (raw == null) return [];
    final entries = jsonDecode(raw) as List<dynamic>;
    final items = <Hadith>[];
    final ids = <String>{};
    for (final entry in entries) {
      try {
        final map = Map<String, dynamic>.from(entry as Map);
        final item = Hadith.fromMap(map.remove('id') as String, map);
        if (item.hasText && ids.add(item.id)) items.add(item);
      } catch (_) {
        /* Retain the remaining valid favorites. */
      }
    }
    return items;
  }

  Future<void> save(List<Hadith> items) => box.put(
    _key,
    jsonEncode([
      for (final item in items) {'id': item.id, ...item.toMap()},
    ]),
  );
}
