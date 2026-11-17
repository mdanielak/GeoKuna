import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:latlong2/latlong.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/atlas/country_map.dart';
import 'package:geokuna/features/settings/app_preferences.dart';

void main() {
  testWidgets(
    'quiz frame ignores the question; landscape shows the whole continent, '
    'portrait its core',
    (tester) async {
      final catalog = (await tester.runAsync(Catalog.load))!;
      Future<MapCamera> cameraFor(
        String key,
        Size size, {
        bool quiz = true,
      }) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox.fromSize(
                  size: size,
                  child: CountryMap(
                    key: ValueKey('$key$size'),
                    catalog: catalog,
                    onSelected: (_) {},
                    quizMode: quiz,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return MapCamera.of(tester.element(find.byType(PolygonLayer<String>)));
      }

      const landscape = Size(700, 450), portrait = Size(390, 560);
      final atlas = await cameraFor('atlas', landscape, quiz: false);
      final wide = await cameraFor('question-KOS', landscape);
      expect((await cameraFor('question-ISL', landscape)).center, wide.center);
      expect(wide.zoom - atlas.zoom, inInclusiveRange(0, .12));
      for (final country in catalog.countries) {
        expect(
          wide.visibleBounds.contains(country.center),
          isTrue,
          reason: country.name,
        );
      }

      final tall = await cameraFor('question-KOS', portrait);
      final tallOther = await cameraFor('question-ISL', portrait);
      expect(tallOther.center, tall.center);
      expect(tallOther.zoom, closeTo(tall.zoom, .0001));
      for (final id in ['PRT', 'NOR', 'GRC', 'TUR', 'GBR', 'POL']) {
        expect(
          tall.visibleBounds.contains(catalog.country(id).center),
          isTrue,
          reason: id,
        );
      }
      // Reset returns to the starting frame of the quiz.
      await tester.tap(find.byTooltip('Pokaż cały obszar'));
      await tester.pumpAndSettle();
      final reset = MapCamera.of(
        tester.element(find.byType(PolygonLayer<String>)),
      );
      expect(reset.zoom, closeTo(tallOther.zoom, .001));
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
    final overview = MapCamera.of(
      tester.element(find.byType(PolygonLayer<String>)),
    ).zoom;
    await tester.pumpWidget(map('ISL'));
    await tester.pumpAndSettle();
    final camera = MapCamera.of(
      tester.element(find.byType(PolygonLayer<String>)),
    );
    expect(camera.center, catalog.country('ISL').center);
    // Only ~3% closer: the neighbours stay in view.
    expect(camera.zoom - overview, closeTo(0.0426, 0.001));
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
    // The label fades after ~2 s so it does not hide the map; the country
    // itself stays red.
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Niemcy'), findsNothing);
    expect(
      tester
          .widget<PolygonLayer<String>>(find.byType(PolygonLayer<String>))
          .polygons
          .where((p) => p.hitValue == 'DEU')
          .every((p) => p.color == const Color(0xFFB85A48)),
      isTrue,
    );
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
