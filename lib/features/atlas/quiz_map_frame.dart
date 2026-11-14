import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

/// Camera framing for a location question, separate from answer evaluation.
class QuizMapFrame {
  const QuizMapFrame({required this.center, required this.zoom});

  final LatLng center;
  final double zoom;

  static QuizMapFrame forTarget({
    required LatLng continentCenter,
    required LatLng target,
    required double continentZoom,
    required Size viewport,
    required String supportLevel,
    required String seed,
  }) {
    final (zoomDelta, targetBias, jitterLimit) = switch (supportLevel) {
      // Zoom gain, pull toward the target, random offset (share of viewport).
      'veryEasy' => (0.9, 0.7, 0.08),
      'easy' => (0.5, 0.4, 0.06),
      _ => (0.0, 0.0, 0.0),
    };
    if (zoomDelta == 0 ||
        !viewport.width.isFinite ||
        !viewport.height.isFinite ||
        viewport.width <= 0 ||
        viewport.height <= 0) {
      return QuizMapFrame(center: continentCenter, zoom: continentZoom);
    }

    final nextZoom = continentZoom + zoomDelta;
    final worldSize = 256 * math.pow(2, nextZoom);
    final centerX = _projectX(continentCenter.longitude);
    final targetX = _projectX(target.longitude);
    var dx = targetX - centerX;
    if (dx > 0.5) dx -= 1;
    if (dx < -0.5) dx += 1;
    final dy = _projectY(target.latitude) - _projectY(continentCenter.latitude);
    final targetDx = dx * worldSize;
    final targetDy = dy * worldSize;

    final random = math.Random(_stableHash(seed));
    final jitterX =
        (random.nextDouble() * 2 - 1) * viewport.width * jitterLimit;
    final jitterY =
        (random.nextDouble() * 2 - 1) * viewport.height * jitterLimit;
    var cameraShiftX = targetDx * targetBias + jitterX;
    var cameraShiftY = targetDy * targetBias + jitterY;

    // Keep the country's label point well inside the visible camera window,
    // including the small zoom increase around microstates and the dateline.
    const edgePadding = 0.10;
    final maxTargetX = viewport.width * (0.5 - edgePadding);
    final maxTargetY = viewport.height * (0.5 - edgePadding);
    final remainingX = (targetDx - cameraShiftX).clamp(-maxTargetX, maxTargetX);
    final remainingY = (targetDy - cameraShiftY).clamp(-maxTargetY, maxTargetY);
    cameraShiftX = targetDx - remainingX;
    cameraShiftY = targetDy - remainingY;

    final shiftedX = _normalizeX(centerX + cameraShiftX / worldSize);
    final shiftedY = _normalizeY(
      _projectY(continentCenter.latitude) + cameraShiftY / worldSize,
    );
    return QuizMapFrame(
      center: LatLng(_unprojectY(shiftedY), shiftedX * 360 - 180),
      zoom: nextZoom,
    );
  }

  static int _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash = ((hash ^ codeUnit) * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  static double _projectX(double longitude) => (longitude + 180) / 360;

  static double _projectY(double latitude) {
    final clamped = latitude.clamp(-85.05112878, 85.05112878);
    final radians = clamped * math.pi / 180;
    return (1 - math.log(math.tan(radians) + 1 / math.cos(radians)) / math.pi) /
        2;
  }

  static double _unprojectY(double y) {
    final exponent = math.pi * (1 - 2 * y);
    final sinh = (math.exp(exponent) - math.exp(-exponent)) / 2;
    final radians = math.atan(sinh);
    return radians * 180 / math.pi;
  }

  static double _normalizeX(double x) => x - x.floorToDouble();

  static double _normalizeY(double y) => y.clamp(0, 1);
}
