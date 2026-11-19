import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/src/features/map/presentation/map_page.dart';

void main() {
  // MapWidget Mapbox platformasi MapboxMapsFlutterPlatform.setInstance() ni
  // talab qiladi. Platform mock qo'shilgach bu test yoqiladi.
  testWidgets('MapPage renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MapPage()));
    expect(find.byType(MapPage), findsOneWidget);
  }, skip: true);
}
