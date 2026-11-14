import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/atlas/country_map.dart';
import 'package:geokuna/features/atlas/map_style.dart';
import 'package:geokuna/features/settings/app_preferences.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'all styles preserve camera and correct-answer color and use local relief',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final catalog = (await tester.runAsync(Catalog.load))!;
      MapCamera? first;
      for (final style in MapAppearance.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CountryMap(
                catalog: catalog,
                appearance: style,
                correctId: 'POL',
                onSelected: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final layer = find.byType(PolygonLayer<String>);
        final camera = MapCamera.of(tester.element(layer));
        first ??= camera;
        expect(camera.center, first.center);
        expect(camera.zoom, first.zoom);
        final polygons = tester.widget<PolygonLayer<String>>(layer).polygons;
        expect(
          polygons
              .where((p) => p.hitValue == 'POL')
              .every((p) => p.color == const Color(0xFF458461)),
          isTrue,
        );
        if (style == MapAppearance.relief) {
          final overlay = tester.widget<OverlayImageLayer>(
            find.byType(OverlayImageLayer),
          );
          expect(
            (overlay.overlayImages.single.imageProvider as AssetImage)
                .assetName,
            'assets/maps/styles/relief/europe.webp',
          );
          expect(
            polygons
                .where((p) => p.hitValue != 'POL')
                .every((p) => p.color == Colors.transparent),
            isTrue,
          );
        } else {
          expect(find.byType(OverlayImageLayer), findsNothing);
        }
        expect(
          find.byType(MapGraticule),
          style == MapAppearance.paper ? findsOneWidget : findsNothing,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
}
