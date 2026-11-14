import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:math' as math;

import 'package:geokuna/features/atlas/quiz_map_frame.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('QuizMapFrame', () {
    const viewport = Size(390, 700);
    const center = LatLng(50, 10);
    const target = LatLng(48, 16);

    test('normal mode preserves the broad continent framing', () {
      final frame = QuizMapFrame.forTarget(
        continentCenter: center,
        target: target,
        continentZoom: 3,
        viewport: viewport,
        supportLevel: 'normal',
        seed: 'session-1:0',
      );

      expect(frame.center, center);
      expect(frame.zoom, 3);
    });

    test('very easy and easy add a small deterministic framing hint', () {
      final veryEasy = QuizMapFrame.forTarget(
        continentCenter: center,
        target: target,
        continentZoom: 3,
        viewport: viewport,
        supportLevel: 'veryEasy',
        seed: 'session-1:0',
      );
      final repeated = QuizMapFrame.forTarget(
        continentCenter: center,
        target: target,
        continentZoom: 3,
        viewport: viewport,
        supportLevel: 'veryEasy',
        seed: 'session-1:0',
      );
      final easy = QuizMapFrame.forTarget(
        continentCenter: center,
        target: target,
        continentZoom: 3,
        viewport: viewport,
        supportLevel: 'easy',
        seed: 'session-1:0',
      );

      expect(veryEasy.center, repeated.center);
      expect(veryEasy.zoom, 3.9);
      expect(easy.zoom, 3.5);
      expect(
        const Distance().as(LengthUnit.Meter, center, veryEasy.center),
        greaterThan(0),
      );
      expect(
        const Distance().as(LengthUnit.Meter, center, easy.center),
        lessThan(
          const Distance().as(LengthUnit.Meter, center, veryEasy.center),
        ),
      );
    });

    test(
      'unknown levels and non-finite viewports preserve current framing',
      () {
        final frame = QuizMapFrame.forTarget(
          continentCenter: center,
          target: target,
          continentZoom: 2.5,
          viewport: Size.zero,
          supportLevel: 'legacy',
          seed: 'session-1:0',
        );

        expect(frame.center, center);
        expect(frame.zoom, 2.5);
      },
    );

    test('target crossing the antimeridian uses the nearby world copy', () {
      final frame = QuizMapFrame.forTarget(
        continentCenter: const LatLng(20, 179),
        target: const LatLng(21, -179),
        continentZoom: 2,
        viewport: viewport,
        supportLevel: 'easy',
        seed: 'asia:turkey',
      );

      expect(frame.center.longitude.abs(), lessThanOrEqualTo(180));
      expect(
        math.min(
          (frame.center.longitude - 180).abs(),
          (frame.center.longitude + 180).abs(),
        ),
        lessThan(8), // random offset only; never the far side of the world
      );
      expect(frame.zoom, 2.5);
    });
  });
}
