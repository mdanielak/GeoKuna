import 'package:drift/native.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/app/app.dart';
import 'package:geokuna/app/providers.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/atlas/country_map.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('mapa zajmuje ekran, a klaster nie potwierdza odpowiedzi', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await db.close();
    });
    await db
        .into(db.sessions)
        .insert(
          SessionsCompanion.insert(
            id: 'map-layout',
            countryIds: '["VAT"]',
            createdAt: DateTime.now(),
          ),
        );
    final catalog = (await tester.runAsync(Catalog.load))!;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          catalogProvider.overrideWith((ref) async => catalog),
        ],
        child: const GeoKunaApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Trening mapy'), 180);
    await tester.tap(find.text('Trening mapy'));
    await tester.pumpAndSettle();

    final availableHeight = 844 - tester.getBottomLeft(find.byType(AppBar)).dy;
    expect(
      tester.getSize(find.byType(CountryMap)).height,
      greaterThan(availableHeight * .9),
    );
    expect(find.text('Potwierdź'), findsNothing);
    expect(await db.select(db.attempts).get(), isEmpty);

    await tester.tap(find.byTooltip('Pokaż cały obszar'));
    await tester.pumpAndSettle();
    final layer = find.byType(PolygonLayer<String>);
    final initialZoom = MapCamera.of(tester.element(layer)).zoom;
    final marker = find.byKey(const ValueKey('country-marker-VAT'));
    await tester.tapAt(tester.getCenter(marker));
    await tester.pump(const Duration(milliseconds: 400));
    expect(MapCamera.of(tester.element(layer)).zoom, greaterThan(initialZoom));
    expect(find.text('Potwierdź'), findsNothing);
    expect(await db.select(db.attempts).get(), isEmpty);
    for (var i = 0; i < 4 && find.text('Potwierdź').evaluate().isEmpty; i++) {
      await tester.tapAt(tester.getCenter(marker));
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(find.text('Potwierdź'), findsOneWidget);
    expect(await db.select(db.attempts).get(), isEmpty);
    await tester.tap(find.text('Potwierdź'));
    await tester.pumpAndSettle();
    expect(await db.select(db.attempts).get(), hasLength(1));
    expect(tester.takeException(), isNull);
  });
}
