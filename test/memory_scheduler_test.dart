import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/features/learning/memory.dart';

void main() {
  test('known at first sight skips learning steps; gaps never exceed cap', () {
    final scheduler = MemoryScheduler();
    final now = DateTime.utc(2026, 11, 12, 12);
    const cap = Duration(days: maxReviewIntervalDays);

    // Unaided recall right away: Easy, straight to a long review gap.
    final known = scheduler.review(
      skillId: 'capitals:POL:write',
      correct: true,
      now: now,
    );
    expect(known.rating, 4);
    final gap = known.due.difference(now);
    expect(gap, greaterThanOrEqualTo(const Duration(days: 7)));
    expect(gap, lessThanOrEqualTo(cap));
    expect(jsonDecode(known.reviewLog), isNotNull);

    // Recognition (A–D) is weaker evidence: normal learning steps.
    final recognised = scheduler.review(
      skillId: 'capitals:POL:choice',
      correct: true,
      now: now,
    );
    expect(recognised.rating, 3);
    expect(recognised.due.difference(now), lessThan(const Duration(hours: 1)));

    final missed = scheduler.review(
      skillId: 'map:POL:map',
      correct: false,
      now: now,
    );
    expect(missed.rating, 1);
    expect(missed.due.difference(now), lessThan(const Duration(hours: 1)));

    var state = known.state;
    var due = known.due;
    for (var i = 0; i < 5; i++) {
      final next = scheduler.review(
        skillId: 'capitals:POL:write',
        previousState: state,
        correct: true,
        now: due,
      );
      expect(next.rating, 3);
      expect(next.due.difference(due), lessThanOrEqualTo(cap));
      state = next.state;
      due = next.due;
    }
    expect(scheduler.retrievability(state, due), greaterThan(.5));
    expect(scheduler.retrievability(null, due), 0);
  });
}
