import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../../core/database/database.dart';
import 'learning_types.dart';

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
    ReviewOrigin? origin,
  }) {
    final card = previousState == null
        ? fsrs.Card(cardId: fsrsCardId(skillId), due: now.toUtc())
        : fsrs.Card.fromMap(jsonDecode(previousState) as Map<String, dynamic>);
    final time =
        card.lastReview != null && card.lastReview!.isAfter(now.toUtc())
        ? card.lastReview!
        : now.toUtc();
    // Unaided recall right at first sight (or a hit in the placement check)
    // means the fact is already known: skip the short learning steps.
    final difficulty = SkillDifficulty.fromDb(skillId.split(':').last);
    final knownAtFirstSight =
        previousState == null &&
        correct &&
        (difficulty.isRecall || origin == ReviewOrigin.placement);
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
    final practice =
        SkillDifficulty.fromDb(attempt.difficulty) == SkillDifficulty.choice &&
        !scheduleRecognition;
    final parsedOrigin = practice
        ? ReviewOrigin.recognition
        : ReviewOrigin.fromDb(origin);
    final applied =
        !practice &&
        !parsedOrigin.isPractice &&
        (fresh ||
            !attempt.correct ||
            parsedOrigin == ReviewOrigin.control ||
            parsedOrigin == ReviewOrigin.autoDemoted ||
            !card.due!.isAfter(attempt.answeredAt));
    ScheduledMemory? result;
    if (applied) {
      result = _scheduler.review(
        skillId: id,
        previousState: card.state,
        correct: attempt.correct,
        now: attempt.answeredAt,
        typo: attempt.typoAccepted,
        origin: parsedOrigin,
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
            origin: parsedOrigin.name,
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

/// Recovery state derived from applied graded reviews in chronological order.
class SkillRecoveryStats {
  const SkillRecoveryStats({
    required this.recovering,
    required this.missesSinceRecovery,
    required this.lastRecoveredAt,
  });

  /// Skills with a graded miss that are not yet recovered, mapped to the
  /// number of graded correct answers since that miss (0–2).
  final Map<String, int> recovering;

  /// Graded misses since a skill was last recovered ([recoveryTarget] correct
  /// in a row). Drives the ladder: a stubborn skill gets an easier step first.
  final Map<String, int> missesSinceRecovery;

  /// Timestamp of the review that completed the most recent recovery per skill.
  final Map<String, DateTime> lastRecoveredAt;
}

/// Computes recovery progress, ladder miss counts and latest recovery times
/// from [reviews] in a single pass.
SkillRecoveryStats analyzeRecovery(Iterable<MemoryReview> reviews) {
  final ordered = reviews.where((r) => r.applied).toList()
    ..sort((a, b) => a.reviewedAt.compareTo(b.reviewedAt));
  final misses = <String, int>{};
  final sinceMiss = <String, int>{};
  final lastRecoveredAt = <String, DateTime>{};
  for (final review in ordered) {
    final id = review.skillId;
    if (review.rating == 1) {
      misses[id] = (misses[id] ?? 0) + 1;
      sinceMiss[id] = 0;
    } else if (sinceMiss.containsKey(id)) {
      final hits = sinceMiss[id]! + 1;
      if (hits >= recoveryTarget) {
        misses.remove(id);
        sinceMiss.remove(id);
        final prev = lastRecoveredAt[id];
        if (prev == null || review.reviewedAt.isAfter(prev)) {
          lastRecoveredAt[id] = review.reviewedAt;
        }
      } else {
        sinceMiss[id] = hits;
      }
    }
  }
  return SkillRecoveryStats(
    recovering: sinceMiss,
    missesSinceRecovery: misses,
    lastRecoveredAt: lastRecoveredAt,
  );
}

/// Graded misses since a skill was last recovered ([recoveryTarget] correct
/// in a row).
Map<String, int> missesSinceRecovery(Iterable<MemoryReview> reviews) =>
    analyzeRecovery(reviews).missesSinceRecovery;

/// Skills with a graded miss that are not yet recovered, mapped to the number
/// of graded correct answers since that miss (0–2).
Map<String, int> recoveringSkills(Iterable<MemoryReview> reviews) =>
    analyzeRecovery(reviews).recovering;

const _formats = [
  'map',
  'choice',
  'firstLetter',
  'write',
  'mapEasy',
  'mapVeryEasy',
];

/// Stable numeric FSRS id of a skill `topic:areaId:difficulty`.
/// Three-letter country ids keep their original packing (saved cards keep
/// their history); longer ids (`PL-14`, `US-CA`) get their own range from
/// 10^13 (flags +5·10^12; up to 5 characters, 128^5·8 < 5·10^12), below 2^53 so the Web build counts them exactly.
int fsrsCardId(String id) {
  final parts = id.split(':');
  if (parts.length != 3 ||
      !['map', 'capitals', 'flags'].contains(parts[0]) ||
      !_formats.contains(parts[2])) {
    throw ArgumentError('Nieobsługiwana umiejętność: $id');
  }
  final area = parts[1].codeUnits.fold(0, (int n, c) => n * 128 + c);
  if (parts[1].length != 3) {
    if (parts[1].length > 5) throw ArgumentError('Za długi kod obszaru: $id');
    return 10000000000000 +
        (parts[0] == 'flags' ? 5000000000000 : 0) +
        area * 8 +
        _formats.indexOf(parts[2]);
  }
  if (parts[2] == 'mapEasy' || parts[2] == 'mapVeryEasy') {
    return 2000000000 +
        (parts[0] == 'flags' ? 1000000000 : 0) +
        area * 2 +
        (parts[2] == 'mapEasy' ? 0 : 1);
  }
  return (parts[0] == 'flags' ? 1000000000 : 0) +
      area * 4 +
      ['map', 'choice', 'firstLetter', 'write'].indexOf(parts[2]);
}
