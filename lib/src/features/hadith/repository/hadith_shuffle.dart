import 'dart:math';
import 'hadith.dart';

/// Visits every item once per shuffled cycle, avoiding an adjacent repeat.
class HadithShuffle {
  HadithShuffle({Random? random}) : _random = random ?? Random();
  final Random _random;
  final List<String> _bag = [];
  bool get hasRemaining => _bag.isNotEmpty;
  void clear() => _bag.clear();

  Hadith next(List<Hadith> items, {String? previousId}) {
    if (items.isEmpty) throw StateError('No hadiths available');
    final ids = items.map((item) => item.id).toSet();
    _bag.removeWhere((id) => !ids.contains(id));
    if (_bag.isEmpty) _bag.addAll(ids.toList()..shuffle(_random));
    if (_bag.length > 1 && _bag.last == previousId) {
      final last = _bag.last;
      _bag[_bag.length - 1] = _bag.first;
      _bag[0] = last;
    }
    final id = _bag.removeLast();
    return items.firstWhere((item) => item.id == id);
  }
}
