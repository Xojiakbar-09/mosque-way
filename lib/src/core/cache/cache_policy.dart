/// Both data caches expire seven days after saving, not after the last read.
class CachePolicy {
  static const lifetime = Duration(days: 7);
  static bool isFresh(DateTime savedAt, {DateTime? now}) {
    final age = (now ?? DateTime.now()).toUtc().difference(savedAt.toUtc());
    return !age.isNegative && age < lifetime;
  }
}
