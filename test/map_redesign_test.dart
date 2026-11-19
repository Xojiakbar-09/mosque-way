import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maps/src/core/utils/service/location_service.dart';
import 'package:maps/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:maps/src/features/auth/presentation/google_sign_in_page.dart';
import 'package:maps/src/features/auth/repository/auth_repository.dart';
import 'package:maps/src/features/map/presentation/bloc/map_bloc.dart';
import 'package:maps/src/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:maps/src/features/settings/repository/app_settings.dart';
import 'package:maps/src/features/settings/repository/settings_repository.dart';
import 'package:maps/src/features/map/repository/directions_profile.dart';
import 'package:maps/src/features/map/repository/directions_repository.dart';
import 'package:maps/src/features/map/repository/directions_route.dart';
import 'package:maps/src/features/map/repository/map_repository.dart';
import 'package:maps/src/features/map/repository/mosque.dart';
import 'package:maps/src/features/map/presentation/widgets/mosque_info_sheet.dart';
import 'package:maps/src/features/map/presentation/widgets/mosque_search_bar.dart';

const mosque = Mosque(
  name: 'Sinov masjidi',
  latitude: 41.3,
  longitude: 69.2,
  address: 'Toshkent, Sinov ko‘chasi, 12',
);
const route = DirectionsRoute(
  points: [
    RoutePoint(latitude: 41.3, longitude: 69.2),
    RoutePoint(latitude: 41.31, longitude: 69.21),
  ],
  distance: 2700,
  duration: 420,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Directions decodes API distance, duration and coordinate order',
    () async {
      final repository = DirectionsRepositoryImpl(
        accessToken: 'test',
        client: MockClient((request) async {
          expect(request.url.path, contains('/driving/69.2,41.3;69.21,41.31'));
          return http.Response(
            jsonEncode({
              'routes': [
                {
                  'distance': 2700,
                  'duration': 420,
                  'geometry': {
                    'coordinates': [
                      [69.2, 41.3],
                      [69.21, 41.31],
                    ],
                  },
                },
              ],
            }),
            200,
          );
        }),
      );
      final result = await repository.getRoute(
        profile: DirectionsProfile.driving,
        fromLatitude: 41.3,
        fromLongitude: 69.2,
        toLatitude: 41.31,
        toLongitude: 69.21,
      );
      expect(result?.distance, 2700);
      expect(result?.duration, 420);
      expect(result?.points.first.latitude, 41.3);
    },
  );

  testWidgets(
    'Sheet waits for button, shows failure and retries with real route metrics',
    (tester) async {
      var calls = 0;
      final directions = _Directions((profile) {
        expect(profile, DirectionsProfile.driving);
        return ++calls == 1 ? null : route;
      });
      final bloc = _mapBloc(directions);
      addTearDown(bloc.close);
      await tester.pumpWidget(
        _uzApp(
          BlocProvider.value(
            value: bloc,
            child: const Scaffold(body: MosqueInfoSheet(mosque: mosque)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.text(mosque.address!), findsOneWidget);
      await tester.ensureVisible(find.text('Marshrut'));
      await tester.tap(find.text('Marshrut'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Marshrutni hisoblab bo‘lmadi'), findsOneWidget);
      await tester.ensureVisible(find.text('Marshrut'));
      await tester.tap(find.text('Marshrut'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('2.7 km'), findsOneWidget);
      expect(find.text('7 daq'), findsOneWidget);
      expect(find.text('Xaritada ko‘rish'), findsOneWidget);
    },
  );

  testWidgets(
    'Transport change clears previous estimate without requesting a route',
    (tester) async {
      var calls = 0;
      final bloc = _mapBloc(_Directions((_) {
        calls++;
        return route;
      }));
      addTearDown(bloc.close);
      await tester.pumpWidget(
        _uzApp(
          BlocProvider.value(
            value: bloc,
            child: const Scaffold(body: MosqueInfoSheet(mosque: mosque)),
          ),
        ),
      );
      final request = MapRouteRequested(mosque, DirectionsProfile.driving);
      bloc.add(request);
      await tester.pumpAndSettle();
      expect(await request.done, same(route));
      expect(find.text('2.7 km'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Piyoda'));
      await tester.tap(find.byTooltip('Piyoda'));
      await tester.pumpAndSettle();
      expect(bloc.state.profile, DirectionsProfile.walking);
      expect(calls, 1);
      expect(find.text('2.7 km'), findsNothing);
      expect(find.text('Marshrut'), findsOneWidget);
    },
  );

  testWidgets('Sign-in fits a small screen and enlarged text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = AuthBloc(_AuthRepository());
    final settings = SettingsBloc(_SettingsRepository(), 'test');
    addTearDown(auth.close);
    addTearDown(settings.close);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('uz'),
        supportedLocales: const [Locale('uz')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: auth),
            BlocProvider.value(value: settings),
          ],
          child: const GoogleSignInPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Google orqali davom etish'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Search results scroll inside compact bounded map overlay', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Sinov');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 320,
              height: 240,
              child: MosqueSearchBar(
                controller: controller,
                query: 'Sinov',
                results: List.filled(8, mosque),
                showResults: true,
                isLoading: false,
                onChanged: (_) {},
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Widget _uzApp(Widget home) => MaterialApp(
  locale: const Locale('uz'),
  supportedLocales: const [Locale('uz')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: home,
);

MapBloc _mapBloc(DirectionsRepository directions) => MapBloc(
  defaults: const AppSettings(routeProfile: DirectionsProfile.driving),
  directions: directions,
  repository: _MapRepository(),
  locationService: _GrantedLocation(),
);

class _GrantedLocation extends LocationService {
  @override
  Future<LocationPermissionStatus> checkPermission() async =>
      LocationPermissionStatus.granted;
}

class _MapRepository extends MapRepositoryImpl {
  @override
  Future<Position> getCurrentPosition() async => Position(
    latitude: 41.31,
    longitude: 69.21,
    timestamp: DateTime.utc(2026),
    accuracy: 3,
    altitude: 0,
    altitudeAccuracy: 1,
    heading: 0,
    headingAccuracy: 1,
    speed: 0,
    speedAccuracy: 1,
  );
}

class _Directions implements DirectionsRepository {
  _Directions(this.result);
  final DirectionsRoute? Function(DirectionsProfile) result;

  @override
  Future<DirectionsRoute?> getRoute({
    required DirectionsProfile profile,
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) async => result(profile);

  @override
  void dispose() {}
}

class _AuthRepository extends AuthRepository {
  @override
  User? get currentUser => null;

  @override
  Stream<User?> watch() => const Stream<User?>.empty();
}

class _SettingsRepository implements SettingsRepository {
  @override
  AppSettings read(String uid) => const AppSettings();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
