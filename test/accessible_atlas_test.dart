import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/app/app.dart';
import 'package:geokuna/app/providers.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/atlas/country_map.dart';
import 'package:geokuna/features/atlas/country_picker.dart';
import 'package:geokuna/features/home/atlas_screen.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('atlas wyszukuje bez polskich znaków, wybiera i czyści filtr', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final catalog = (await tester.runAsync(Catalog.load))!;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [catalogProvider.overrideWith((ref) async => catalog)],
        child: const MaterialApp(home: AtlasScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'wegry');
    await tester.pumpAndSettle();
    expect(find.text('Węgry'), findsOneWidget);
    await tester.tap(find.text('Węgry'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<CountryPicker>(find.byType(CountryPicker)).selectedId,
      'HUN',
    );
    final map = tester.widget<CountryMap>(find.byType(CountryMap));
    expect(map.selectedId, 'HUN');
    expect(map.focusId, 'HUN');
    await tester.enterText(find.byType(TextField), 'nieistniejace');
    await tester.pumpAndSettle();
    expect(
      find.text('Nie znaleziono państwa. Zmień wyszukiwaną nazwę.'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Wyczyść wyszukiwanie'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(
      find.text('Nie znaleziono państwa. Zmień wyszukiwaną nazwę.'),
      findsNothing,
    );
  });

  testWidgets('klawiatura przesuwa i przybliża mapę', (tester) async {
    final catalog = (await tester.runAsync(Catalog.load))!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CountryMap(catalog: catalog, onSelected: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    MapCamera camera() =>
        MapCamera.of(tester.element(find.byType(PolygonLayer<String>)));
    final initialCenter = camera().center;
    final initialZoom = camera().zoom;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(camera().center.longitude, greaterThan(initialCenter.longitude));
    await tester.sendKeyEvent(LogicalKeyboardKey.equal);
    await tester.pump();
    expect(camera().zoom, greaterThan(initialZoom));
    await tester.sendKeyEvent(LogicalKeyboardKey.minus);
    await tester.pump();
    expect(camera().zoom, closeTo(initialZoom, 0.001));
  });

  testWidgets('wybór z pomocą zapisuje kliknięcie jako próbę bez oceny FSRS', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final catalog = (await tester.runAsync(Catalog.load))!;
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await db.close();
    });
    await db
        .into(db.sessions)
        .insert(
          SessionsCompanion.insert(
            id: 'assisted-flow',
            countryIds: '["HUN"]',
            createdAt: DateTime.now(),
          ),
        );
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
    await tester.ensureVisible(find.text('Trening mapy'));
    await tester.tap(find.text('Trening mapy'));
    await tester.pumpAndSettle();
    final cardsBefore = await db.select(db.memoryCards).get();
    await tester.tap(find.text('Wybierz z listy (z pomocą)'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'wegry');
    await tester.pumpAndSettle();
    expect(await db.select(db.attempts).get(), isEmpty);
    await tester.tap(find.text('Węgry'));
    await tester.pumpAndSettle();
    expect(find.text('Potwierdź'), findsNothing);
    final attempts = await db.select(db.attempts).get();
    final reviews = await db.select(db.memoryReviews).get();
    expect(attempts, hasLength(1));
    expect(attempts.single.answer, 'HUN');
    expect(reviews, hasLength(1));
    expect(reviews.single.origin, 'assisted');
    expect(reviews.single.applied, isFalse);
    final cardsAfter = await db.select(db.memoryCards).get();
    final before = {for (final card in cardsBefore) card.id: card};
    for (final card in cardsAfter) {
      expect(card.state, before[card.id]?.state);
      expect(card.reviewCount, before[card.id]?.reviewCount ?? 0);
    }
  });
}
