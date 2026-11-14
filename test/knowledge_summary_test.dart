import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/learning/learning_progress.dart';
import 'package:geokuna/features/progress/learning_overview_screen.dart';
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
}
