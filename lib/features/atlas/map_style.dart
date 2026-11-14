import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../settings/app_preferences.dart';

class MapPalette {
  const MapPalette(this.appearance);
  final MapAppearance appearance;

  Color get ocean => switch (appearance) {
    MapAppearance.atlas => const Color(0xFFDDEEF4),
    MapAppearance.paper => const Color(0xFFDDE9E3),
    MapAppearance.relief => const Color(0xFFDAEEF4),
  };
  Color get boundary => appearance == MapAppearance.paper
      ? const Color(0xFF817E65)
      : const Color(0xFF637866);
  Color get markerFill => const Color(0xFFFAF7E9);

  Color country(String id) {
    final seed = id.codeUnits.fold(0, (sum, unit) => sum * 31 + unit);
    final colors = appearance == MapAppearance.paper
        ? const [
            Color(0xFFE8E2C5),
            Color(0xFFD9DEBE),
            Color(0xFFECE7D2),
            Color(0xFFDDE3CA),
          ]
        : const [
            Color(0xFFE8E7D3),
            Color(0xFFD9E4D1),
            Color(0xFFEAE1CC),
            Color(0xFFDEE4E2),
          ];
    return colors[seed % colors.length];
  }
}

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
