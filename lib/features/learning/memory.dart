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

/// Longest gap between checks of a known skill; mastered facts still return.
const maxReviewIntervalDays = 60;

/// Formats where a first correct answer is unaided recall, not recognition.
const recallFormats = {'write', 'map'};

class MemoryScheduler {
  final _scheduler = fsrs.Scheduler(
    enableFuzzing: false,
    maximumInterval: maxReviewIntervalDays,
  );

  /// Predicted chance of recall now (0 for a card never reviewed).
  double retrievability(String? state, DateTime now) {
    if (state == null) return 0;
    final card = fsrs.Card.fromMap(jsonDecode(state) as Map<String, dynamic>);
    return _scheduler.getCardRetrievability(card, currentDateTime: now.toUtc());
  }

  ScheduledMemory review({
    required String skillId,
    String? previousState,
    required bool correct,
    required DateTime now,
    bool typo = false,
  }) {
    final card = previousState == null
        ? fsrs.Card(cardId: _cardId(skillId), due: now.toUtc())
        : fsrs.Card.fromMap(jsonDecode(previousState) as Map<String, dynamic>);
    final time =
        card.lastReview != null && card.lastReview!.isAfter(now.toUtc())
        ? card.lastReview!
        : now.toUtc();
    // Unaided recall right at first sight means the fact is already known:
    // skip the short learning steps instead of asking again in minutes.
    final knownAtFirstSight =
        previousState == null &&
        correct &&
        recallFormats.contains(skillId.split(':').last);
    // An accepted typo is correct but less certain: one grade lower.
    final rating = !correct
        ? fsrs.Rating.again
        : knownAtFirstSight
        ? (typo ? fsrs.Rating.good : fsrs.Rating.easy)
        : (typo ? fsrs.Rating.hard : fsrs.Rating.good);
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
        ![
          'map',
          'choice',
          'firstLetter',
          'write',
          'mapEasy',
          'mapVeryEasy',
        ].contains(parts[2])) {
      throw ArgumentError('Nieobsługiwana umiejętność: $id');
    }
    final country = parts[1].codeUnits.fold(0, (int n, c) => n * 128 + c);
    if (parts[2] == 'mapEasy' || parts[2] == 'mapVeryEasy') {
      return 2000000000 +
          (parts[0] == 'flags' ? 1000000000 : 0) +
          country * 2 +
          (parts[2] == 'mapEasy' ? 0 : 1);
    }
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
      await record(attempt, origin: 'manual', scheduleRecognition: false);
    }
    await db
        .into(db.memoryMeta)
        .insert(
          MemoryMetaCompanion.insert(key: 'history-import-v1', value: 'done'),
        );
  }

  Future<void> record(
    Attempt attempt, {
    required String origin,
    bool scheduleRecognition = true,
    DateTime? activityTime,
  }) async {
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
    // Old recognition history is retained, without manufacturing new reviews.
    final practice = attempt.difficulty == 'choice' && !scheduleRecognition;
    if (practice) origin = 'recognition';
    final applied =
        !practice &&
        origin != 'assisted' &&
        origin != 'retry' &&
        (fresh ||
            !attempt.correct ||
            origin == 'control' ||
            !card.due!.isAfter(attempt.answeredAt));
    ScheduledMemory? result;
    if (applied) {
      result = _scheduler.review(
        skillId: id,
        previousState: card.state,
        correct: attempt.correct,
        now: attempt.answeredAt,
        typo: attempt.typoAccepted,
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
            rating: practice ? 0 : result?.rating ?? (attempt.correct ? 3 : 1),
            reviewedAt: attempt.answeredAt,
            wasNew: fresh,
            applied: applied,
            origin: origin,
            reviewLog: Value(result?.reviewLog),
          ),
        );
    if (activityTime != null) {
      final session = await (db.select(
        db.sessions,
      )..where((s) => s.id.equals(attempt.sessionId))).getSingle();
      final local = activityTime.toLocal();
      final date =
          '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
      await db
          .into(db.activityDays)
          .insert(
            ActivityDaysCompanion.insert(
              continent: session.continent,
              localDate: date,
              recordedAt: activityTime.toUtc(),
              offsetMinutes: local.timeZoneOffset.inMinutes,
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }
}

/// Correct answers needed in a row after a miss before a skill stops being
/// treated as a problem.
const recoveryTarget = 3;

/// Skills with a graded miss that are not yet recovered, mapped to the number
/// of graded correct answers since that miss (0–2).
Map<String, int> recoveringSkills(Iterable<MemoryReview> reviews) {
  final ordered = reviews.where((r) => r.applied).toList()
    ..sort((a, b) => a.reviewedAt.compareTo(b.reviewedAt));
  final since = <String, int>{};
  for (final review in ordered) {
    if (review.rating == 1) {
      since[review.skillId] = 0;
    } else if (since.containsKey(review.skillId)) {
      since[review.skillId] = since[review.skillId]! + 1;
    }
  }
  return {
    for (final MapEntry(:key, :value) in since.entries)
      if (value < recoveryTarget) key: value,
  };
}
