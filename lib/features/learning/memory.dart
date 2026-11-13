import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../../core/database/database.dart';

class ScheduledMemory {
  const ScheduledMemory(this.state, this.due, this.rating, this.reviewLog);
  final String state;
  final DateTime due;
  final int rating;
  final String reviewLog;
}

class MemoryScheduler {
  final _scheduler = fsrs.Scheduler(enableFuzzing: false);

  ScheduledMemory review({
    required String skillId,
    String? previousState,
    required bool correct,
    required DateTime now,
  }) {
    final card = previousState == null
        ? fsrs.Card(cardId: _cardId(skillId), due: now.toUtc())
        : fsrs.Card.fromMap(jsonDecode(previousState) as Map<String, dynamic>);
    final time =
        card.lastReview != null && card.lastReview!.isAfter(now.toUtc())
        ? card.lastReview!
        : now.toUtc();
    final rating = correct ? fsrs.Rating.good : fsrs.Rating.again;
    final result = _scheduler.reviewCard(card, rating, reviewDateTime: time);
    return ScheduledMemory(
      jsonEncode(result.card.toMap()),
      result.card.due,
      rating.value,
      jsonEncode(result.reviewLog.toMap()),
    );
  }

  int _cardId(String id) {
    final parts = id.split(':');
    if (parts.length != 3 ||
        !['map', 'capitals', 'flags'].contains(parts[0]) ||
        !['map', 'choice', 'firstLetter', 'write'].contains(parts[2])) {
      throw ArgumentError('Nieobsługiwana umiejętność: $id');
    }
    final country = parts[1].codeUnits.fold(0, (int n, c) => n * 128 + c);
    return (parts[0] == 'flags' ? 1000000000 : 0) +
        country * 4 +
        ['map', 'choice', 'firstLetter', 'write'].indexOf(parts[2]);
  }
}

class MemoryStore {
  MemoryStore(this.db);
  final AppDatabase db;
  final _scheduler = MemoryScheduler();

  Future<void> ensureCard(
    String country,
    String topic,
    String difficulty,
  ) async {
    await db
        .into(db.memoryCards)
        .insert(
          MemoryCardsCompanion.insert(
            id: '$topic:$country:$difficulty',
            countryId: country,
            topic: topic,
            difficulty: difficulty,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> importHistoryOnce() async {
    final marker = await (db.select(
      db.memoryMeta,
    )..where((m) => m.key.equals('history-import-v1'))).getSingleOrNull();
    if (marker != null) return;
    final attempts =
        await (db.select(db.attempts)..orderBy([
              (a) => OrderingTerm.asc(a.answeredAt),
              (a) => OrderingTerm.asc(a.sessionId),
              (a) => OrderingTerm.asc(a.questionIndex),
            ]))
            .get();
    for (final attempt in attempts) {
      await record(attempt, origin: 'manual');
    }
    await db
        .into(db.memoryMeta)
        .insert(
          MemoryMetaCompanion.insert(key: 'history-import-v1', value: 'done'),
        );
  }

  Future<void> record(Attempt attempt, {required String origin}) async {
    final existing =
        await (db.select(db.memoryReviews)..where(
              (r) =>
                  r.sessionId.equals(attempt.sessionId) &
                  r.questionIndex.equals(attempt.questionIndex),
            ))
            .getSingleOrNull();
    if (existing != null) return;
    await ensureCard(attempt.countryId, attempt.topic, attempt.difficulty);
    final id = '${attempt.topic}:${attempt.countryId}:${attempt.difficulty}';
    final card = await (db.select(
      db.memoryCards,
    )..where((c) => c.id.equals(id))).getSingle();
    final fresh = card.state == null;
    final applied =
        origin != 'assisted' &&
        (fresh || !attempt.correct || !card.due!.isAfter(attempt.answeredAt));
    ScheduledMemory? result;
    if (applied) {
      result = _scheduler.review(
        skillId: id,
        previousState: card.state,
        correct: attempt.correct,
        now: attempt.answeredAt,
      );
      await (db.update(db.memoryCards)..where((c) => c.id.equals(id))).write(
        MemoryCardsCompanion(
          state: Value(result.state),
          due: Value(result.due),
          introducedAt: Value(card.introducedAt ?? attempt.answeredAt),
          reviewCount: Value(card.reviewCount + 1),
        ),
      );
    }
    await db
        .into(db.memoryReviews)
        .insert(
          MemoryReviewsCompanion.insert(
            sessionId: attempt.sessionId,
            questionIndex: attempt.questionIndex,
            skillId: id,
            rating: attempt.correct ? 3 : 1,
            reviewedAt: attempt.answeredAt,
            wasNew: fresh,
            applied: applied,
            origin: origin,
            reviewLog: Value(result?.reviewLog),
          ),
        );
  }
}
