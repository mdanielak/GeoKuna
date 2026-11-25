import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'continent.dart';

/// Full regional map bounds (also matches relief tile coverage).
LatLngBounds regionBoundsFor(Continent continent) => switch (continent) {
  Continent.europe => LatLngBounds(const LatLng(34, -32), const LatLng(72, 65)),
  Continent.africa => LatLngBounds(
    const LatLng(-36, -26),
    const LatLng(38, 65),
  ),
  Continent.asia => LatLngBounds(const LatLng(-12, 20), const LatLng(82, 180)),
  Continent.northAmerica => LatLngBounds(
    const LatLng(5, -170),
    const LatLng(84, -50),
  ),
  Continent.southAmerica => LatLngBounds(
    const LatLng(-57, -95),
    const LatLng(15, -30),
  ),
  // Shifted longitudes: 110°E → -70, 150°W → 30.
  Continent.oceania => LatLngBounds(
    const LatLng(-50, -70),
    const LatLng(22, 30),
  ),
  // Must match tools/data_pipeline/build_subdivisions.py windows.
  Continent.poland => LatLngBounds(
    const LatLng(48.6, 13.5),
    const LatLng(55.3, 24.5),
  ),
  Continent.usa => LatLngBounds(const LatLng(16, -128), const LatLng(51, -64)),
};

/// On a portrait phone the whole continent leaves most of the screen as sea:
/// frame its core instead; outlying areas stay reachable by panning.
LatLngBounds portraitBoundsFor(Continent continent) => switch (continent) {
  Continent.europe => LatLngBounds(const LatLng(35, -11), const LatLng(71, 50)),
  Continent.africa => LatLngBounds(
    const LatLng(-35, -18),
    const LatLng(37.5, 52),
  ),
  Continent.asia => LatLngBounds(const LatLng(-11, 26), const LatLng(56, 146)),
  // Without Alaska and the far north, which a portrait phone cannot fit.
  Continent.northAmerica => LatLngBounds(
    const LatLng(7, -128),
    const LatLng(60, -58),
  ),
  Continent.southAmerica => LatLngBounds(
    const LatLng(-56, -82),
    const LatLng(13, -34),
  ),
  // Australia, New Guinea, New Zealand and Fiji; far atolls by panning.
  Continent.oceania => LatLngBounds(const LatLng(-47, -68), const LatLng(3, 5)),
  Continent.poland => LatLngBounds(
    const LatLng(49, 14.1),
    const LatLng(54.9, 24.2),
  ),
  // Contiguous states plus the Alaska and Hawaii insets below them.
  Continent.usa => LatLngBounds(
    const LatLng(16.2, -128.6),
    const LatLng(49.5, -66),
  ),
};
