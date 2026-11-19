import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maps/src/features/hadith/presentation/bloc/hadith_bloc.dart';
import 'package:maps/src/features/hadith/presentation/hadith_page.dart';
import 'package:maps/src/features/hadith/repository/hadith.dart';
import 'package:maps/src/features/hadith/repository/hadith_repository.dart';
import 'package:maps/src/features/hadith/repository/liked_hadith_repository.dart';
import 'package:maps/src/features/prayer/presentation/bloc/prayer_bloc.dart';
import 'package:maps/src/features/prayer/repository/prayer_location.dart';
import 'package:maps/src/features/prayer/repository/prayer_location_service.dart';
import 'package:maps/src/features/prayer/repository/prayer_repository.dart';
import 'package:maps/src/features/prayer/repository/prayer_schedule.dart';
import 'package:maps/src/features/qibla/presentation/bloc/qibla_bloc.dart';
import 'package:maps/src/features/qibla/repository/qibla_repository.dart';
import 'package:maps/src/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:maps/src/features/settings/repository/app_settings.dart';
import 'package:maps/src/features/settings/repository/settings_repository.dart';

Future<void> settleEvents() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Hadith sample() => Hadith.fromMap('one', {
  'title': 'Sarlavha',
  'category': 'Odob',
  'source': 'Manba',
  'textUz': 'Uzbek matni',
  'textRu': 'Русский текст',
  'textEn': 'English text',
  'order': '1',
});

class FakeHadithRepository implements HadithRepository {
  final controller = StreamController<HadithFeed>.broadcast();
  int listens = 0;
  @override
  Stream<HadithFeed> watch({bool nextPage = false}) {
    listens++;
    return controller.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class InMemoryFavorites implements LikedHadithRepository {
  List<Hadith> _items = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  List<Hadith> read() => List.of(_items);

  @override
  Future<void> save(List<Hadith> items) async {
    _items = List.of(items);
  }
}

class FakeSettingsRepository implements SettingsRepository {
  AppSettings saved = const AppSettings();
  bool fail = false;
  final writes = <AppSettings>[];
  @override
  AppSettings read(String uid) => saved;
  @override
  Future<void> save(String uid, AppSettings settings) async {
    await Future<void>.delayed(Duration.zero);
    if (fail) throw StateError('disk full');
    writes.add(settings);
    saved = settings;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePrayerRepository implements PrayerRepository {
  int clears = 0;
  bool disposed = false;
  @override
  PrayerSchedule? cached(
    Madhhab madhhab,
    int? method, {
    PrayerLocation? location,
  }) => null;
  @override
  Future<void> clear() async {
    clears++;
  }

  @override
  void dispose() {
    disposed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FailingLocation extends PrayerLocationService {
  @override
  Future<PrayerLocation> current() async => throw const LocationUnavailable();
}

class FakeQiblaRepository extends QiblaRepository {
  final readings = StreamController<QiblaReading>.broadcast();
  final fallback = StreamController<QiblaReading>.broadcast();
  Completer<Position>? pendingLocation;
  bool compass = true;
  int starts = 0;
  @override
  Future<Position> currentPosition() =>
      pendingLocation?.future ??
      Future.value(
        Position(
          latitude: 41.3,
          longitude: 69.2,
          timestamp: DateTime(2026),
          accuracy: 1,
          altitude: 0,
          altitudeAccuracy: 1,
          heading: 0,
          headingAccuracy: 1,
          speed: 0,
          speedAccuracy: 1,
        ),
      );
  @override
  Future<bool> hasCompassSensor() async => compass;
  @override
  Stream<QiblaReading> headings(Position position) {
    starts++;
    return readings.stream;
  }

  @override
  Stream<QiblaReading> gpsHeadings() => fallback.stream;
  @override
  Future<void> dispose() async {
    await readings.close();
    await fallback.close();
  }
}

void main() {
  test(
    'Hadith parser handles string order, bad fields and language fallback',
    () {
      expect(sample().order, 1);
      expect(sample().textFor('ru'), 'Русский текст');
      final item = Hadith.fromMap('two', {
        'textUz': ' Fallback ',
        'order': 'NaN',
        'title': 3,
      });
      expect(item.order.isFinite, isTrue);
      expect(item.title, '');
      expect(item.textFor('en'), 'Fallback');
      expect(Hadith.fromMap('empty', {}).hasText, isFalse);
    },
  );

  test(
    'Hadith BLoC receives live updates and retries after denied access',
    () async {
      final repo = FakeHadithRepository();
      final bloc = HadithBloc(repo, InMemoryFavorites())..add(const HadithLoadRequested());
      await settleEvents();
      repo.controller.add(HadithFeed([sample()], fromCache: true));
      await settleEvents();
      expect(bloc.state.items.single.id, 'one');
      expect(bloc.state.fromCache, isTrue);
      repo.controller.addError(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      await settleEvents();
      expect(bloc.state.errorKey, 'hadithAccessError');
      expect(bloc.state.items, isNotEmpty);
      bloc.add(const HadithLoadRequested());
      await settleEvents();
      repo.controller.add(const HadithFeed([], fromCache: false));
      await settleEvents();
      expect(repo.listens, 2);
      expect(bloc.state.items, isEmpty);
      expect(bloc.state.errorKey, isNull);
      await bloc.close();
      expect(repo.controller.hasListener, isFalse);
      await repo.controller.close();
    },
  );

  test(
    'Settings events save sequentially and expose save failure to caller',
    () async {
      final repo = FakeSettingsRepository();
      final bloc = SettingsBloc(repo, 'user');
      final first = SettingsUpdateRequested(
        bloc.state.copyWith(language: 'ru'),
      );
      final second = SettingsUpdateRequested(
        bloc.state.copyWith(language: 'en'),
      );
      bloc.add(first);
      bloc.add(second);
      await Future.wait([first.done, second.done]);
      expect(repo.writes.map((s) => s.language), ['ru', 'en']);
      expect(bloc.state.language, 'en');
      repo.fail = true;
      final failed = SettingsUpdateRequested(
        bloc.state.copyWith(language: 'uz'),
      );
      final check = expectLater(failed.done, throwsStateError);
      bloc.add(failed);
      await check;
      expect(bloc.state.language, 'en');
      await bloc.close();
    },
  );

  test('Prayer BLoC handles location failure and cache clear events', () async {
    final repo = FakePrayerRepository();
    final bloc = PrayerBloc(repo, locationService: FailingLocation());
    final load = PrayerLoadRequested(
      const AppSettings(madhhab: Madhhab.hanafi),
    );
    bloc.add(load);
    await load.done;
    expect(bloc.state.message, 'permissionError');
    expect(bloc.state.loading, isFalse);
    final clear = PrayerCacheClearRequested();
    bloc.add(clear);
    await clear.done;
    expect(repo.clears, 1);
    expect(bloc.state.message, isNull);
    await bloc.close();
    expect(repo.disposed, isTrue);
  });

  test(
    'Qibla BLoC starts sensor, follows north crossing, pauses and resumes',
    () async {
      final repo = FakeQiblaRepository();
      final bloc = QiblaBloc(repository: repo)..add(const QiblaStarted());
      await settleEvents();
      repo.readings.add(const QiblaReading(heading: 359));
      await settleEvents();
      final dial = bloc.state.dialDegrees;
      repo.readings.add(const QiblaReading(heading: 1));
      await settleEvents();
      expect((bloc.state.dialDegrees - dial).abs(), lessThan(5));
      bloc.add(const QiblaPaused());
      await settleEvents();
      expect(repo.readings.hasListener, isFalse);
      expect(bloc.state.heading, isNull);
      bloc.add(const QiblaStarted());
      await settleEvents();
      expect(repo.starts, 2);
      await bloc.close();
    },
  );

  test('Qibla pause discards a pending location result', () async {
    final repo = FakeQiblaRepository()..pendingLocation = Completer<Position>();
    final bloc = QiblaBloc(repository: repo)..add(const QiblaStarted());
    await settleEvents();
    bloc.add(const QiblaPaused());
    await settleEvents();
    repo.pendingLocation!.complete(
      Position(
        latitude: 41,
        longitude: 69,
        timestamp: DateTime(2026),
        accuracy: 1,
        altitude: 0,
        altitudeAccuracy: 1,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      ),
    );
    await settleEvents();
    expect(repo.starts, 0);
    expect(bloc.state.heading, isNull);
    await bloc.close();
  });

  test('Qibla unsupported sensor uses GPS as an approximate heading', () async {
    final repo = FakeQiblaRepository()..compass = false;
    final bloc = QiblaBloc(repository: repo)..add(const QiblaStarted());
    await settleEvents();
    repo.fallback.add(const QiblaReading(heading: 180, approximate: true));
    await settleEvents();
    expect(bloc.state.approximate, isTrue);
    expect(bloc.state.message, 'compassUnsupported');
    expect(bloc.state.aligned, isFalse);
    await bloc.close();
  });

  test('Qibla stream error removes the stale heading', () async {
    final repo = FakeQiblaRepository();
    final bloc = QiblaBloc(repository: repo)..add(const QiblaStarted());
    await settleEvents();
    repo.readings.add(const QiblaReading(heading: 90));
    await settleEvents();
    expect(bloc.state.heading, 90);
    repo.readings.addError(const QiblaSensorException());
    await settleEvents();
    expect(bloc.state.heading, isNull);
    expect(bloc.state.message, 'compassUnavailable');
    expect(repo.readings.hasListener, isFalse);
    await bloc.close();
  });

  testWidgets('Hadith empty cache offers retry without endless loading', (
    tester,
  ) async {
    final repo = FakeHadithRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: HadithPage(repository: repo, favorites: InMemoryFavorites()),
      ),
    );
    await tester.pump();
    repo.controller.add(const HadithFeed([], fromCache: true));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('No saved hadiths'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await repo.controller.close();
  });

  for (final language in ['uz', 'ru', 'en']) {
    testWidgets('Hadith page displays $language text and live empty state', (
      tester,
    ) async {
      final repo = FakeHadithRepository();
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(language),
          supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: HadithPage(repository: repo, favorites: InMemoryFavorites()),
        ),
      );
      await tester.pump();
      repo.controller.add(HadithFeed([sample()], fromCache: false));
      await tester.pumpAndSettle();
      expect(find.text(sample().textFor(language)), findsOneWidget);
      expect(find.text('Manba'), findsOneWidget);
      repo.controller.add(const HadithFeed([], fromCache: false));
      await tester.pumpAndSettle();
      expect(find.text(sample().textFor(language)), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await repo.controller.close();
    });
  }
}
