import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:latlong2/latlong.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/atlas/country_map.dart';

void main() {
  testWidgets(
    'Kosovo question starts slightly closer to the Balkans and can reset to Europe',
    (tester) async {
      final catalog = (await tester.runAsync(Catalog.load))!;
      Widget map(String? region) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 450,
            child: CountryMap(
              key: ValueKey(region),
              catalog: catalog,
              onSelected: (_) {},
              questionRegionId: region,
            ),
          ),
        ),
      );
      await tester.pumpWidget(map(null));
      await tester.pumpAndSettle();
      final fullZoom = MapCamera.of(
        tester.element(find.byType(PolygonLayer<String>)),
      ).zoom;
      await tester.pumpWidget(map('KOS'));
      await tester.pumpAndSettle();
      final camera = MapCamera.of(
        tester.element(find.byType(PolygonLayer<String>)),
      );
      expect(camera.zoom, greaterThan(fullZoom));
      expect(camera.zoom - fullZoom, lessThan(1.8));
      expect(
        camera.visibleBounds.contains(catalog.country('KOS').center),
        isTrue,
      );
      expect(camera.center, isNot(catalog.country('KOS').center));
      await tester.tap(find.byTooltip('Pokaż cały obszar'));
      await tester.pumpAndSettle();
      expect(
        MapCamera.of(tester.element(find.byType(PolygonLayer<String>))).zoom,
        closeTo(fullZoom, .001),
      );
    },
  );

  testWidgets('question seeds give stable regional framing', (tester) async {
    final catalog = (await tester.runAsync(Catalog.load))!;
    Future<MapCamera> cameraFor(String seed) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 450,
              child: CountryMap(
                key: ValueKey(seed),
                catalog: catalog,
                onSelected: (_) {},
                questionRegionId: 'POL',
                questionSeed: seed,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return MapCamera.of(tester.element(find.byType(PolygonLayer<String>)));
    }

    final first = await cameraFor('question-1');
    final same = await cameraFor('question-1');
    final other = await cameraFor('question-2');
    final target = catalog.country('POL').center;
    expect(first.center, same.center);
    expect(first.center, isNot(other.center));
    for (final camera in [first, other]) {
      expect((camera.center.latitude - target.latitude).abs(), lessThan(5));
      expect((camera.center.longitude - target.longitude).abs(), lessThan(7));
      expect(camera.center, isNot(target));
      expect(camera.visibleBounds.contains(target), isTrue);
    }
  });

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
