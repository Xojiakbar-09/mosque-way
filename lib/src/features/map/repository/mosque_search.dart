import 'mosque.dart';

class MosqueSearch {
  static List<Mosque> find(
    List<Mosque> mosques,
    String query, {
    int limit = 20,
  }) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty || limit <= 0) return const [];
    final words = normalizedQuery.split(' ');
    final matches = mosques
        .where(
          (mosque) => words.every(
            _normalize('${mosque.name} ${mosque.address ?? ''}').contains,
          ),
        )
        .toList();
    int rank(Mosque mosque) {
      final name = _normalize(mosque.name);
      return name == normalizedQuery
          ? 0
          : name.startsWith(normalizedQuery)
          ? 1
          : name.contains(normalizedQuery)
          ? 2
          : 3;
    }

    matches.sort((a, b) {
      final order = rank(a).compareTo(rank(b));
      return order != 0 ? order : a.name.compareTo(b.name);
    });
    return matches.take(limit).toList(growable: false);
  }

  // Match Uzbek apostrophe variants, punctuation and Cyrillic names.
  static String _normalize(String value) {
    const cyrillic = {
      'а': 'a',
      'б': 'b',
      'в': 'v',
      'г': 'g',
      'д': 'd',
      'е': 'e',
      'ё': 'yo',
      'ж': 'j',
      'з': 'z',
      'и': 'i',
      'й': 'y',
      'к': 'k',
      'л': 'l',
      'м': 'm',
      'н': 'n',
      'о': 'o',
      'п': 'p',
      'р': 'r',
      'с': 's',
      'т': 't',
      'у': 'u',
      'ф': 'f',
      'х': 'x',
      'ц': 'ts',
      'ч': 'ch',
      'ш': 'sh',
      'щ': 'sh',
      'ъ': '',
      'ы': 'i',
      'ь': '',
      'э': 'e',
      'ю': 'yu',
      'я': 'ya',
      'ў': 'o',
      'қ': 'q',
      'ғ': 'g',
      'ҳ': 'h',
    };
    final latin = value
        .toLowerCase()
        .split('')
        .map((c) => cyrillic[c] ?? c)
        .join();
    return latin
        .replaceAll(RegExp("['’‘ʻʼ`ʹ´ˈ]"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }
}
