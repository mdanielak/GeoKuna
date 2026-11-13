import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/features/learning/memory.dart';

void main() {
  test('FSRS adapter records Again and Good with serializable state', () {
    final scheduler = MemoryScheduler();
    final now = DateTime.utc(2026, 11, 12, 12);
    final good = scheduler.review(
      skillId: 'capitals:POL:write',
      correct: true,
      now: now,
    );
    final again = scheduler.review(
      skillId: 'capitals:POL:write',
      correct: false,
      now: now,
    );
    expect(good.rating, 3);
    expect(again.rating, 1);
    expect(good.due.isUtc, isTrue);
    expect(good.due.isAfter(now), isTrue);
    expect(again.due.isAfter(now), isTrue);
    expect(jsonDecode(good.state), isNotNull);
    expect(jsonDecode(good.reviewLog), isNotNull);
    final next = scheduler.review(
      skillId: 'capitals:POL:write',
      previousState: good.state,
      correct: true,
      now: good.due,
    );
    expect(next.rating, 3);
    expect(next.due.isAfter(good.due), isTrue);
    expect(jsonDecode(next.state), isNotNull);
  });
}
