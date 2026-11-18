import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/app/providers.dart';
import 'package:geokuna/app/theme.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/atlas/continent.dart';
import 'package:geokuna/features/atlas/country_map.dart';
import 'package:geokuna/features/atlas/country_picker.dart';
import 'package:geokuna/features/home/atlas_screen.dart';
import 'package:geokuna/features/learning/capitals.dart';
import 'package:geokuna/features/learning/country_trivia.dart';
import 'package:geokuna/features/learning/flags.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'atlas wyszukuje bez polskich znaków, pokazuje wizytówkę i zmienia obszar',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final loaded = (await tester.runAsync(
        () async => (
          await Catalog.load(),
          await CapitalCatalog.load(),
          await FlagCatalog.load(),
          await CountryTriviaCatalog.load(),
          await Catalog.load(continent: Continent.poland),
          await CapitalCatalog.load(continent: Continent.poland),
          await FlagCatalog.load(continent: Continent.poland),
        ),
      ))!;
      final (
        catalog,
        capitals,
        flags,
        trivia,
        poland,
        polandCapitals,
        polandFlags,
      ) = loaded;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogProvider.overrideWith(
              (ref) async =>
                  ref.watch(selectedContinentProvider) == Continent.poland
                  ? poland
                  : catalog,
            ),
            capitalsProvider.overrideWith(
              (ref) async =>
                  ref.watch(selectedContinentProvider) == Continent.poland
                  ? polandCapitals
                  : capitals,
            ),
            flagsProvider.overrideWith(
              (ref) async =>
                  ref.watch(selectedContinentProvider) == Continent.poland
                  ? polandFlags
                  : flags,
            ),
            countryTriviaProvider.overrideWith((ref) async => trivia),
          ],
          child: MaterialApp(
            theme: GeoTheme.light(),
            home: const AtlasScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      MapCamera camera() =>
          MapCamera.of(tester.element(find.byType(PolygonLayer<String>)));
      final overviewZoom = camera().zoom;
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
      expect(find.text('Stolica: Budapeszt'), findsOneWidget);
      final map = tester.widget<CountryMap>(find.byType(CountryMap));
      expect(map.selectedId, 'HUN');
      expect(map.focusId, 'HUN');
      // Choosing a country centres it with only a slight (~3%) zoom.
      expect(camera().zoom - overviewZoom, inInclusiveRange(0.01, 0.1));
      await tester.enterText(find.byType(TextField), 'nieistniejace');
      await tester.pumpAndSettle();
      expect(
        find.text('Nic nie znaleziono. Zmień wyszukiwaną nazwę.'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Wyczyść wyszukiwanie'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(
        find.text('Nic nie znaleziono. Zmień wyszukiwaną nazwę.'),
        findsNothing,
      );
      // Switching continent directly via the Atlas chip clears the old selection.
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Polska'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Polska'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Atlas Polski'), findsOneWidget);
      expect(find.text('Dokąd dziś wyruszymy?'), findsOneWidget);
    },
  );

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
}
