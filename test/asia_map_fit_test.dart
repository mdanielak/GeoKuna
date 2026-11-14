import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/atlas/continent.dart';
import 'package:geokuna/features/atlas/country_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('Asia overview fits its complete rendering window on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final catalog = (await tester.runAsync(
      () => Catalog.load(continent: Continent.asia),
    ))!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 440,
            child: CountryMap(catalog: catalog, onSelected: (_) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final map = find.byType(FlutterMap);
    final camera = MapCamera.of(
      tester.element(find.byType(PolygonLayer<String>)),
    );
    final size = tester.getSize(map);
    for (final corner in [const LatLng(-12, 20), const LatLng(82, 180)]) {
      final point = camera.latLngToScreenOffset(corner);
      expect(point.dx, inInclusiveRange(0, size.width));
      expect(point.dy, inInclusiveRange(0, size.height));
    }
    expect(tester.takeException(), isNull);
  });
}
