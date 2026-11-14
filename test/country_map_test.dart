import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:latlong2/latlong.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/atlas/country_map.dart';
import 'package:geokuna/features/settings/app_preferences.dart';

void main() {
  testWidgets(
    'quiz uses almost the full continent, independent of question key',
    (tester) async {
      final catalog = (await tester.runAsync(Catalog.load))!;
      Future<MapCamera> cameraFor(String key, {bool quiz = false}) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 390,
                height: 450,
                child: CountryMap(
                  key: ValueKey(key),
                  catalog: catalog,
                  onSelected: (_) {},
                  quizMode: quiz,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return MapCamera.of(tester.element(find.byType(PolygonLayer<String>)));
      }

      final atlas = await cameraFor('atlas');
      final kosovo = await cameraFor('question-KOS', quiz: true);
      final iceland = await cameraFor('question-ISL', quiz: true);
      expect(kosovo.center, iceland.center);
      expect(kosovo.zoom, closeTo(iceland.zoom, .0001));
      expect(kosovo.zoom - atlas.zoom, inInclusiveRange(0, .12));
      for (final country in catalog.countries) {
        expect(
          kosovo.visibleBounds.contains(country.center),
          isTrue,
          reason: country.name,
        );
      }
      await tester.tap(find.byTooltip('Pokaż cały obszar'));
      await tester.pumpAndSettle();
      final reset = MapCamera.of(
        tester.element(find.byType(PolygonLayer<String>)),
      );
      expect(reset.zoom, closeTo(atlas.zoom, .001));
      expect(reset.center, atlas.center);
    },
  );

  testWidgets(
    'overlapping small states zoom before selection; Vatican remains reachable',
    (tester) async {
      final catalog = (await tester.runAsync(Catalog.load))!;
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 450,
              child: CountryMap(
                catalog: catalog,
                onSelected: (id) => selected = id,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final layer = find.byType(PolygonLayer<String>);
      final initialZoom = MapCamera.of(tester.element(layer)).zoom;
      final marker = find.byKey(const ValueKey('country-marker-VAT'));
      await tester.tapAt(tester.getCenter(marker));
      await tester.pump(const Duration(milliseconds: 400));
      expect(selected, isNull);
      expect(
        MapCamera.of(tester.element(layer)).zoom,
        greaterThan(initialZoom),
      );
      for (var i = 0; i < 4 && selected == null; i++) {
        await tester.tapAt(tester.getCenter(marker));
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(selected, 'VAT');
    },
  );

  testWidgets('atlas focus centers the selected country', (tester) async {
    final catalog = (await tester.runAsync(Catalog.load))!;
    Widget map(String? focus) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 390,
          height: 450,
          child: CountryMap(
            catalog: catalog,
            onSelected: (_) {},
            focusId: focus,
          ),
        ),
      ),
    );
    await tester.pumpWidget(map(null));
    await tester.pumpAndSettle();
    await tester.pumpWidget(map('ISL'));
    await tester.pumpAndSettle();
    final camera = MapCamera.of(
      tester.element(find.byType(PolygonLayer<String>)),
    );
    expect(camera.center, catalog.country('ISL').center);
    expect(camera.zoom, 6);
  });

  testWidgets('wrong country label shows its name without intercepting taps', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final catalog = (await tester.runAsync(Catalog.load))!;
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 450,
            child: CountryMap(
              catalog: catalog,
              onSelected: (id) => selected = id,
              wrongCountryIds: const {'DEU'},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Niemcy'), findsOneWidget);
    expect(find.bySemanticsLabel('Błędna odpowiedź: Niemcy'), findsOneWidget);
    final mapFinder = find.byType(FlutterMap);
    final camera = MapCamera.of(
      tester.element(find.byType(PolygonLayer<String>)),
    );
    await tester.tapAt(
      tester.getTopLeft(mapFinder) +
          camera.latLngToScreenOffset(const LatLng(52, 19)),
    );
    expect(selected, 'POL');
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('easy map support applies one stable small camera hint', (
    tester,
  ) async {
    final catalog = (await tester.runAsync(Catalog.load))!;
    Widget map(MapAppearance appearance, String level) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 390,
          height: 450,
          child: CountryMap(
            key: ValueKey(level),
            catalog: catalog,
            onSelected: (_) {},
            quizMode: true,
            appearance: appearance,
            supportLevel: level,
            targetId: 'ISL',
            questionSeed: 'daily-question-0',
          ),
        ),
      ),
    );
    final layer = find.byType(PolygonLayer<String>);
    await tester.pumpWidget(map(MapAppearance.atlas, 'normal'));
    await tester.pumpAndSettle();
    final normal = MapCamera.of(tester.element(layer));
    await tester.pumpWidget(map(MapAppearance.atlas, 'veryEasy'));
    await tester.pumpAndSettle();
    final hinted = MapCamera.of(tester.element(layer));
    expect(hinted.zoom - normal.zoom, closeTo(.9, .02));
    expect(hinted.center, isNot(normal.center));

    await tester.pumpWidget(map(MapAppearance.paper, 'veryEasy'));
    await tester.pumpAndSettle();
    final afterStyleChange = MapCamera.of(tester.element(layer));
    expect(afterStyleChange.center, hinted.center);
    expect(afterStyleChange.zoom, closeTo(hinted.zoom, .001));
  });

  testWidgets('exhausting guesses refits map to the revealed country once', (
    tester,
  ) async {
    final catalog = (await tester.runAsync(Catalog.load))!;
    Widget map(String? reveal) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 390,
          height: 450,
          child: CountryMap(
            catalog: catalog,
            onSelected: (_) {},
            quizMode: true,
            revealId: reveal,
          ),
        ),
      ),
    );
    await tester.pumpWidget(map(null));
    await tester.pumpAndSettle();
    final layer = find.byType(PolygonLayer<String>);
    final overview = MapCamera.of(tester.element(layer));
    await tester.pumpWidget(map('ISL'));
    await tester.pumpAndSettle();
    final revealed = MapCamera.of(tester.element(layer));
    expect(revealed.zoom, greaterThan(overview.zoom));
    expect(revealed.zoom, lessThanOrEqualTo(overview.zoom + 1.5 + .01));
    expect(revealed.center.latitude, closeTo(65, 8));
    expect(revealed.center.longitude, closeTo(-18, 8));

    await tester.tap(find.byTooltip('Oddal mapę'));
    await tester.pumpAndSettle();
    final manuallyMoved = MapCamera.of(tester.element(layer));
    await tester.pumpWidget(map('ISL'));
    await tester.pumpAndSettle();
    expect(MapCamera.of(tester.element(layer)).zoom, manuallyMoved.zoom);
  });

  testWidgets('polygon selection remains accurate after zoom and reset', (
    tester,
  ) async {
    final catalog = (await tester.runAsync(Catalog.load))!;
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 450,
            child: CountryMap(
              catalog: catalog,
              onSelected: (id) => selected = id,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> selectPoland() async {
      final layer = find.byType(PolygonLayer<String>);
      final camera = MapCamera.of(tester.element(layer));
      final offset = camera.latLngToScreenOffset(const LatLng(52, 19));
      await tester.tapAt(tester.getTopLeft(find.byType(FlutterMap)) + offset);
      await tester.pump();
      expect(selected, 'POL');
      selected = null;
    }

    await selectPoland();
    await tester.tap(find.byTooltip('Przybliż mapę'));
    await tester.pumpAndSettle();
    // Reset also verifies that controls do not get interpreted as a country tap.
    expect(selected, isNull);
    await tester.tap(find.byTooltip('Pokaż cały obszar'));
    await tester.pumpAndSettle();
    await selectPoland();
    expect(tester.takeException(), isNull);
  });
}
