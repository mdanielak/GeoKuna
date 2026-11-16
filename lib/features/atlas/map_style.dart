import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:material_ui/material_ui.dart';

import '../settings/app_preferences.dart';
import 'catalog.dart';
import 'continent.dart';

/// Offline relief tiles (tools/data_pipeline/build_relief.py): one shared
/// set for unshifted maps, one for Oceania's 180°-shifted coordinates.
String reliefTileTemplate(Continent continent) =>
    'assets/maps/styles/relief/tiles/'
    '${continent == Continent.oceania ? 'oceania' : 'world'}_{z}_{x}_{y}.webp';

class MapPalette {
  const MapPalette(this.appearance);
  final MapAppearance appearance;

  Color get ocean => switch (appearance) {
    MapAppearance.atlas => const Color(0xFFBCE0F1),
    MapAppearance.paper => const Color(0xFFD9DCC4),
    // Matches the lightened Natural Earth water around the relief tiles.
    MapAppearance.relief => const Color(0xFF93C0DE),
  };

  /// Country borders: darker and thicker than before so neighbours read
  /// clearly at a glance, while staying calmer than answer colours.
  Color get boundary => switch (appearance) {
    MapAppearance.atlas => const Color(0xFF4F6470),
    MapAppearance.paper => const Color(0xFF6B5A3E),
    MapAppearance.relief => const Color(0xFF4F6352),
  };

  /// Strokes drawn under the land, outermost first; the fills cover their
  /// inner half, so only the sea side shows. Paper: engraved water lines
  /// along every coast; modern atlas: a soft shadow; relief: none.
  List<(double, Color)> get coastRings => switch (appearance) {
    // Each ink stroke is followed by a slightly narrower sea stroke, leaving
    // a thin engraved line 2, 4.5 and 7.5 px off the coast.
    MapAppearance.paper => const [
      (15, Color(0x596B5A3E)),
      (13.6, Color(0xFFD9DCC4)),
      (9, Color(0x736B5A3E)),
      (7.8, Color(0xFFD9DCC4)),
      (4, Color(0x8C6B5A3E)),
    ],
    MapAppearance.atlas => const [
      (9, Color(0x0F1F4E66)),
      (6, Color(0x141F4E66)),
      (3.5, Color(0x1F1F4E66)),
    ],
    MapAppearance.relief => const [],
  };

  /// Ink of the paper atlas frame, compass rose and vignette.
  Color get ink => const Color(0xFF5B4A31);
  Color get paperLight => const Color(0xFFF4ECD6);

  /// Land outside the quiz: neutral, so it reads as "not asked here".
  Color get contextLand => switch (appearance) {
    MapAppearance.atlas => const Color(0xFFE9E7E1),
    MapAppearance.paper => const Color(0xFFE4D8BC),
    MapAppearance.relief => const Color(0x40F2EFE6),
  };
  double get boundaryWidth => appearance == MapAppearance.relief ? 1.3 : 1.2;
  Color get markerFill => const Color(0xFFFAF7E9);

  // Answer states, the same in every style: they must beat any land fill.
  Color get correct => const Color(0xFF458461);
  Color get wrong => const Color(0xFFB85A48);
  Color get selected => const Color(0xFFD0A751);
  Color get markerBorder => const Color(0xFF365643);
  Color get wrongLabel => const Color(0xFF8C1D18);
  Color get labelShadow => const Color(0x55000000);

  /// Five fills per style; [countryColoring] gives neighbours different ones.
  List<Color> get fills => appearance == MapAppearance.paper
      ? const [
          Color(0xFFE9D7A6), // ochre
          Color(0xFFD3D5A2), // olive
          Color(0xFFE9C6A2), // light terracotta
          Color(0xFFDCCDB0), // stone
          Color(0xFFCAD5AE), // pale moss
        ]
      : const [
          Color(0xFFF6E3A6), // sun
          Color(0xFFC4E5A9), // leaf
          Color(0xFFF8CBA8), // apricot
          Color(0xFFDCCDF0), // lilac
          Color(0xFFAEE0CF), // aqua
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
            gradient: appearance == MapAppearance.paper
                ? RadialGradient(
                    radius: 1.1,
                    colors: [
                      Color.lerp(palette.ocean, palette.paperLight, .45)!,
                      palette.ocean,
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      palette.ocean,
                      Color.lerp(palette.ocean, Colors.white, .14)!,
                    ],
                  ),
          ),
          child: appearance == MapAppearance.paper
              ? CustomPaint(painter: _PaperGrain(palette.ink))
              : null,
        ),
      ),
    );
  }
}

/// Speckles and short fibres of old paper, fixed by a seed.
class _PaperGrain extends CustomPainter {
  const _PaperGrain(this.ink);
  final Color ink;
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(41);
    final dot = Paint()..color = ink.withValues(alpha: .09);
    final fibre = Paint()
      ..color = ink.withValues(alpha: .07)
      ..strokeWidth = .6;
    final area = size.width * size.height;
    for (var i = 0; i < area / 90; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        .3 + random.nextDouble() * .4,
        dot,
      );
    }
    for (var i = 0; i < area / 2600; i++) {
      final start = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final angle = random.nextDouble() * math.pi;
      final length = 3 + random.nextDouble() * 7;
      canvas.drawLine(
        start,
        start + Offset(math.cos(angle), math.sin(angle)) * length,
        fibre,
      );
    }
  }

  @override
  bool shouldRepaint(_PaperGrain oldDelegate) => oldDelegate.ink != ink;
}

/// Paper atlas over the map: darker edges and a double neatline whose band
/// alternates ink and paper every 5° of the real graticule.
class PaperAtlasFrame extends StatelessWidget {
  const PaperAtlasFrame({super.key});
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: CustomPaint(
        size: Size.infinite,
        painter: _FramePainter(MapCamera.of(context)),
      ),
    ),
  );
}

class _FramePainter extends CustomPainter {
  const _FramePainter(this.camera);
  final MapCamera camera;
  static const _outer = 4.0, _band = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    const palette = MapPalette(MapAppearance.paper);
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: .95,
          colors: [
            palette.ink.withValues(alpha: 0),
            palette.ink.withValues(alpha: .16),
          ],
          stops: const [.62, 1],
        ).createShader(rect),
    );
    final band = rect.deflate(_outer);
    final inner = band.deflate(_band);
    final light = Paint()..color = palette.paperLight;
    final dark = Paint()..color = palette.ink.withValues(alpha: .85);
    // The band: paper first, then ink cells between alternate 5° lines.
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(band)
        ..addRect(inner),
      light,
    );
    double x(double lon) => camera.latLngToScreenOffset(LatLng(0, lon)).dx;
    double y(double lat) => camera.latLngToScreenOffset(LatLng(lat, 0)).dy;
    for (var lon = -180; lon < 180; lon += 10) {
      final a = x(lon.toDouble()).clamp(band.left, band.right);
      final b = x(lon + 5.0).clamp(band.left, band.right);
      if (b - a < .5) continue;
      canvas
        ..drawRect(Rect.fromLTRB(a, band.top, b, inner.top), dark)
        ..drawRect(Rect.fromLTRB(a, inner.bottom, b, band.bottom), dark);
    }
    for (var lat = -85; lat < 85; lat += 10) {
      final a = y(lat + 5.0).clamp(band.top, band.bottom);
      final b = y(lat.toDouble()).clamp(band.top, band.bottom);
      if (b - a < .5) continue;
      canvas
        ..drawRect(Rect.fromLTRB(band.left, a, inner.left, b), dark)
        ..drawRect(Rect.fromLTRB(inner.right, a, band.right, b), dark);
    }
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..color = palette.ink
      ..strokeWidth = 1;
    canvas
      ..drawRect(band, line..strokeWidth = 1.4)
      ..drawRect(inner, line..strokeWidth = .8);
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) => oldDelegate.camera != camera;
}

/// Eight-point compass rose of the paper atlas; north is always up.
class CompassRose extends StatelessWidget {
  const CompassRose({super.key, this.size = 58});
  final double size;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: CustomPaint(size: Size.square(size), painter: const _Rose()),
    ),
  );
}

class _Rose extends CustomPainter {
  const _Rose();
  @override
  void paint(Canvas canvas, Size size) {
    const palette = MapPalette(MapAppearance.paper);
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 7;
    final ink = Paint()..color = palette.ink;
    final paper = Paint()..color = palette.paperLight;
    canvas.drawCircle(
      c,
      r + 5,
      Paint()..color = palette.paperLight.withValues(alpha: .75),
    );
    canvas.drawCircle(
      c,
      r * .62,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = palette.ink.withValues(alpha: .6)
        ..strokeWidth = .8,
    );
    void point(double angle, double length, double width) {
      Offset at(double a, double d) =>
          c + Offset(math.sin(a), -math.cos(a)) * d;
      final tip = at(angle, length);
      final left = at(angle - math.pi / 2, width);
      final right = at(angle + math.pi / 2, width);
      canvas
        ..drawPath(Path()..addPolygon([c, left, tip], true), paper)
        ..drawPath(Path()..addPolygon([c, tip, right], true), ink)
        ..drawPath(
          Path()..addPolygon([left, tip, right, c], true),
          Paint()
            ..style = PaintingStyle.stroke
            ..color = palette.ink
            ..strokeWidth = .6,
        );
    }

    for (var i = 0; i < 4; i++) {
      point(math.pi / 4 + i * math.pi / 2, r * .55, r * .12);
    }
    for (var i = 0; i < 4; i++) {
      point(i * math.pi / 2, r, r * .2);
    }
    final label = TextPainter(
      text: TextSpan(
        text: 'N',
        style: TextStyle(
          color: palette.ink,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(c.dx - label.width / 2, 0));
  }

  @override
  bool shouldRepaint(_Rose oldDelegate) => false;
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
