import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/learning/learning_progress.dart';
import 'package:geokuna/features/progress/learning_overview_screen.dart';
import 'package:geokuna/features/settings/app_preferences.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('knowledge indicator tracks recognition separately and never rounds up to mastery', () {
    LearningProgressEntry entry(
      LearningProgressStatus status, {
      String difficulty = 'write',
    }) => LearningProgressEntry(
      id: 'example',
      country: const Country(
        'POL',
        'Polska',
        LatLng(52, 19),
        false,
        plural: false,
      ),
      topic: 'capitals',
      difficulty: difficulty,
      status: status,
      reviewCount: 1,
      due: null,
      lastReview: null,
    );
    final summary = KnowledgeSummary([
      entry(LearningProgressStatus.practising),
      entry(LearningProgressStatus.review),
      entry(LearningProgressStatus.insufficient),
      entry(LearningProgressStatus.practising, difficulty: 'choice'),
    ]);
    expect(summary.percent, 50);
    expect(summary.ready, 2);
    expect(summary.review, 1);
    expect(summary.unknown, 1);
    expect(KnowledgeSummary([]).percent, 0);
    expect(
      KnowledgeSummary([
        for (var i = 0; i < 305; i++) entry(LearningProgressStatus.practising),
        entry(LearningProgressStatus.insufficient),
      ]).percent,
      99,
    );
  });

  test(
    'effectiveEntriesForLevel collapses to active level and inherits downward',
    () {
      const pol = Country(
        'POL',
        'Polska',
        LatLng(52, 19),
        false,
        plural: false,
      );
      LearningProgressEntry skill(
        String topic,
        String difficulty,
        LearningProgressStatus status,
      ) => LearningProgressEntry(
        id: '$topic:POL:$difficulty',
        country: pol,
        topic: topic,
        difficulty: difficulty,
        status: status,
        reviewCount: status == LearningProgressStatus.insufficient ? 0 : 1,
        due: null,
        lastReview: null,
      );

      final all = [
        skill('map', 'mapVeryEasy', LearningProgressStatus.insufficient),
        skill('map', 'mapEasy', LearningProgressStatus.insufficient),
        skill('map', 'map', LearningProgressStatus.practising),
        skill('capitals', 'choice', LearningProgressStatus.insufficient),
        skill('capitals', 'firstLetter', LearningProgressStatus.review),
        skill('capitals', 'write', LearningProgressStatus.insufficient),
      ];

      final normal = KnowledgeSummary(
        effectiveEntriesForLevel(all, LearningDifficulty.normal),
      );
      expect(normal.entries, hasLength(2));
      expect(normal.ready, 1);
      expect(normal.unknown, 1);
      expect(normal.percent, 50);

      // Easy inherits practising from Normal on map, and keeps its own review on capitals.
      final easy = KnowledgeSummary(
        effectiveEntriesForLevel(all, LearningDifficulty.easy),
      );
      expect(easy.entries, hasLength(2));
      expect(easy.ready, 1);
      expect(easy.review, 1);
      expect(easy.unknown, 0);
    },
  );
}
