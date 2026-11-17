import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/app/providers.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/atlas/continent.dart';
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
    final poland = (await tester.runAsync(
      () => Catalog.load(continent: Continent.poland),
    ))!;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogProvider.overrideWith(
            (ref) async =>
                ref.watch(selectedContinentProvider) == Continent.poland
                ? poland
                : catalog,
          ),
        ],
        child: const MaterialApp(home: AtlasScreen()),
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
    // The selection belongs to its continent: switching to the voivodeships
    // must not look up 'HUN' there.
    ProviderScope.containerOf(tester.element(find.byType(AtlasScreen)))
        .read(selectedContinentProvider.notifier)
        .select(Continent.poland);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Dokąd dziś wyruszymy?'), findsOneWidget);
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
}
