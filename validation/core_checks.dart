import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:maps/src/core/cache/cache_policy.dart';
import 'package:maps/src/core/localization/app_translations.dart';
import 'package:maps/src/features/hadith/repository/hadith.dart';
import 'package:maps/src/features/hadith/repository/hadith_shuffle.dart';
import 'package:maps/src/features/map/repository/mosque.dart';
import 'package:maps/src/features/map/repository/mosque_search.dart';
import 'package:maps/src/features/qibla/repository/qibla_math.dart';
import 'package:maps/src/features/auth/presentation/bloc/auth_form_bloc.dart';
import 'package:maps/src/features/main/presentation/bloc/navigation_bloc.dart';
import 'package:maps/src/features/home/presentation/bloc/clock_bloc.dart';

int checks = 0;
void check(bool condition, String description) {
  if (!condition) throw StateError(description);
  checks++;
}

Future<void> main() async {
  final now = DateTime.utc(2026, 11, 17);
  check(
    CachePolicy.isFresh(now.subtract(const Duration(days: 6)), now: now),
    '6-day cache remains usable',
  );
  check(
    !CachePolicy.isFresh(now.subtract(const Duration(days: 7)), now: now),
    '7-day cache expires',
  );
  check(
    !CachePolicy.isFresh(now.add(const Duration(seconds: 1)), now: now),
    'Future timestamps do not extend cache lifetime',
  );

  final hadith = Hadith.fromMap('one', {
    'order': '2',
    'title': 'Niyat',
    'titleRu': 'Намерение',
    'titleEn': 'Intention',
    'category': 'Odob',
    'source': 'Source',
    'textUz': 'Matn',
    'textEn': 'Text',
  });
  check(hadith.order == 2, 'Legacy string order is readable');
  check(hadith.titleFor('ru') == 'Намерение', 'Localized metadata');
  check(
    hadith.textFor('ru') == 'Matn',
    'Missing translation falls back to Uzbek',
  );
  final restored = Hadith.fromMap(
    hadith.id,
    jsonDecode(jsonEncode(hadith.toMap())) as Map<String, dynamic>,
  );
  check(
    restored.titleFor('en') == 'Intention' && restored.textUz == 'Matn',
    'Favorite snapshot survives JSON round trip',
  );

  final items = [
    for (var i = 0; i < 5; i++)
      Hadith.fromMap('$i', {'textUz': 'Hadis $i', 'order': i}),
  ];
  final shuffle = HadithShuffle(random: Random(42));
  String? previous;
  for (var cycle = 0; cycle < 100; cycle++) {
    final ids = <String>{};
    for (var i = 0; i < 5; i++) {
      final next = shuffle.next(items, previousId: previous);
      check(
        next.id != previous,
        'No adjacent repeat, including cycle boundaries',
      );
      ids.add(next.id);
      previous = next.id;
    }
    check(ids.length == 5, 'All five hadiths appear in each cycle');
  }
  final single = HadithShuffle();
  check(
    single.next([hadith]).id == hadith.id &&
        single.next([hadith], previousId: hadith.id).id == hadith.id,
    'Single-hadith collection is safe',
  );
  final changing = HadithShuffle(random: Random(4));
  changing.next(items);
  check(
    changing.next([hadith]).id == hadith.id,
    'Removed IDs are pruned from shuffled bag',
  );

  final mosque = Mosque.fromOsm({
    'type': 'node',
    'id': 7,
    'lat': 41.3,
    'lon': 69.2,
    'tags': {
      'amenity': 'place_of_worship',
      'religion': 'muslim',
      'name': 'Ko‘kcha masjidi',
    },
  })!;
  check(
    MosqueSearch.find([mosque], "ko'kcha").length == 1,
    'Uzbek apostrophe normalization',
  );
  check(MosqueSearch.find([mosque], 'Кўкча').length == 1, 'Cyrillic search');
  check(
    MosqueSearch.find([mosque], 'unknown').isEmpty,
    'Unmatched search is empty',
  );
  check(
    Mosque.fromOsm({
          'lat': 41.3,
          'lon': 69.2,
          'tags': {'amenity': 'place_of_worship', 'religion': 'muslim'},
        }) ==
        null,
    'Unnamed mosque is filtered',
  );
  check(
    Mosque.fromOsm({
          'lat': 100,
          'lon': 69.2,
          'tags': {
            'amenity': 'place_of_worship',
            'religion': 'muslim',
            'name': 'Invalid',
          },
        }) ==
        null,
    'Invalid coordinates are filtered',
  );

  check(
    QiblaMath.delta(359, 1) == 2 && QiblaMath.delta(1, 359) == -2,
    'Compass crosses north by shortest arc',
  );
  final bearing = QiblaMath.bearing(41.2995, 69.2401);
  check(bearing > 230 && bearing < 250, 'Tashkent qibla bearing is southwest');
  for (final language in ['uz', 'ru', 'en']) {
    for (final key in [
      'authInvalidCredentials',
      'authResetSent',
      'mosqueLoadError',
      'regionRestored',
      'cacheClearBoth',
      'hadithFavorites',
    ]) {
      check(
        AppTranslations.text(key, language) != key,
        'New user-facing messages are localized: $key/$language',
      );
    }
  }

  final navigation = NavigationBloc();
  navigation.add(const NavigationTabSelected(2));
  await Future<void>.delayed(Duration.zero);
  check(
    navigation.state.index == 2 &&
        navigation.state.hadithOpened &&
        !navigation.state.mapOpened,
    'Hadith tab opens lazily',
  );
  navigation.add(const NavigationTabSelected(1));
  await Future<void>.delayed(Duration.zero);
  navigation.add(const NavigationTabSelected(0));
  await Future<void>.delayed(Duration.zero);
  check(
    navigation.state.index == 0 &&
        navigation.state.mapOpened &&
        navigation.state.hadithOpened,
    'Visited tabs stay initialized',
  );
  navigation.add(const NavigationTabSelected(8));
  await Future<void>.delayed(Duration.zero);
  check(navigation.state.index == 0, 'Invalid tab cannot corrupt navigation');
  await navigation.close();

  final form = AuthFormBloc();
  form.add(const AuthPasswordVisibilityToggled());
  form.add(const AuthFormModeToggled());
  await Future<void>.delayed(Duration.zero);
  check(
    form.state.register && !form.state.hidePassword,
    'Form mode and visibility are independent BLoC state',
  );
  await form.close();

  final clock = ClockBloc();
  clock.add(ClockTicked(now));
  await Future<void>.delayed(Duration.zero);
  check(clock.state == now, 'Clock tick updates state');
  await clock.close();
  check(clock.isClosed, 'Clock cleanup cancels its timer');
  stdout.writeln('PASS: $checks checks');
}
