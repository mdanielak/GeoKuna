import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../settings/app_preferences.dart';
import 'catalog.dart';

class MapPalette {
  const MapPalette(this.appearance);
  final MapAppearance appearance;

  Color get ocean => switch (appearance) {
    MapAppearance.atlas => const Color(0xFFCFE5EF),
    MapAppearance.paper => const Color(0xFFD3E1D6),
    MapAppearance.relief => const Color(0xFFDAEEF4),
  };

  /// Country borders: darker and thicker than before so neighbours read
  /// clearly at a glance, while staying calmer than answer colours.
  Color get boundary => switch (appearance) {
    MapAppearance.atlas => const Color(0xFF5B6E60),
    MapAppearance.paper => const Color(0xFF6F6650),
    MapAppearance.relief => const Color(0xFF4F6352),
  };
  double get boundaryWidth => appearance == MapAppearance.relief ? 1.3 : 1.2;
  Color get markerFill => const Color(0xFFFAF7E9);

  /// Five fills per style; [countryColoring] gives neighbours different ones.
  List<Color> get fills => appearance == MapAppearance.paper
      ? const [
          Color(0xFFEADFB6), // ochre
          Color(0xFFD5DCAC), // olive
          Color(0xFFEBCFAF), // light terracotta
          Color(0xFFDDD3BE), // stone
          Color(0xFFCFDCC0), // pale moss
        ]
      : const [
          Color(0xFFEEE3C1), // sand
          Color(0xFFD2E4BF), // sage
          Color(0xFFF1D4BC), // peach
          Color(0xFFE2D7E9), // lavender
          Color(0xFFCDE5D8), // mint
        ];
}

final _colorings = Expando<Map<String, int>>();

/// Greedy colouring of the land-border graph (countries sharing border
/// vertices), so adjacent countries never share a fill. Cached per catalog.
Map<String, int> countryColoring(Catalog catalog, int colors) =>
    _colorings[catalog] ??= () {
      final owners = <int, Set<String>>{};
      for (final shape in catalog.shapes) {
        for (final ring in shape.rings) {
          for (final point in ring) {
            final key =
                (point.latitude * 1e4).round() * 4000000 +
                (point.longitude * 1e4).round();
            (owners[key] ??= {}).add(shape.countryId);
          }
        }
      }
      final shared = <String, Map<String, int>>{};
      for (final ids in owners.values.where((ids) => ids.length > 1)) {
        for (final a in ids) {
          for (final b in ids.where((b) => b != a)) {
            final counts = shared[a] ??= {};
            counts[b] = (counts[b] ?? 0) + 1;
          }
        }
      }
      final neighbours = {
        for (final c in catalog.countries)
          c.id: {
            for (final MapEntry(:key, :value) in (shared[c.id] ?? {}).entries)
              if (value >= 2) key,
          },
      };
      final order = [...catalog.countries.map((c) => c.id)]
        ..sort((a, b) {
          final degree = neighbours[b]!.length.compareTo(neighbours[a]!.length);
          return degree != 0 ? degree : a.compareTo(b);
        });
      final result = <String, int>{};
      for (final id in order) {
        final used = {for (final n in neighbours[id]!) result[n]};
        var color = 0;
        while (used.contains(color) && color < colors - 1) {
          color++;
        }
        result[id] = color;
      }
      return result;
    }();

/// Purely decorative surface; it cannot receive a map gesture or an answer.
class MapSurface extends StatelessWidget {
  const MapSurface({super.key, required this.appearance});
  final MapAppearance appearance;
  @override
  Widget build(BuildContext context) {
    final palette = MapPalette(appearance);
    return IgnorePointer(
      child: RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                palette.ocean,
                Color.lerp(palette.ocean, Colors.white, .14)!,
              ],
            ),
          ),
          child: appearance == MapAppearance.paper
              ? const CustomPaint(painter: _PaperGrain())
              : null,
        ),
      ),
    );
  }
}

class _PaperGrain extends CustomPainter {
  const _PaperGrain();
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(41);
    final ink = Paint()..color = const Color(0x12877E59);
    for (var i = 0; i < 2200; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        .35,
        ink,
      );
    }
  }

  @override
  bool shouldRepaint(_PaperGrain oldDelegate) => false;
}

/// A real Web Mercator graticule, projected by the same camera as the countries.
class MapGraticule extends StatelessWidget {
  const MapGraticule({super.key});
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      size: Size.infinite,
      painter: _GraticulePainter(MapCamera.of(context)),
    ),
  );
}

class _GraticulePainter extends CustomPainter {
  const _GraticulePainter(this.camera);
  final MapCamera camera;
  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = const Color(0x20827C62)
      ..strokeWidth = .7;
    for (var lon = -180; lon <= 180; lon += 15) {
      final x = camera.latLngToScreenOffset(LatLng(0, lon.toDouble())).dx;
      if (x >= 0 && x <= size.width) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), pen);
      }
    }
    for (var lat = -80; lat <= 80; lat += 10) {
      final y = camera.latLngToScreenOffset(LatLng(lat.toDouble(), 0)).dy;
      if (y >= 0 && y <= size.height) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), pen);
      }
    }
  }

  @override
  bool shouldRepaint(_GraticulePainter oldDelegate) =>
      oldDelegate.camera != camera;
}
