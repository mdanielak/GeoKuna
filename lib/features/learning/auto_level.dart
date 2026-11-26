import 'package:drift/drift.dart';

import '../../core/database/database.dart';
import '../settings/app_preferences.dart';
import 'learning_types.dart';

const autoDemoteAfterMisses = 3;
const autoPromoteAfterHits = 2;

/// Canonical item key `category:countryId` for per-item automatic difficulty.
String autoItemId(String topic, String countryId, String difficulty) {
  final category = topic == 'flags' && SkillDifficulty.fromDb(difficulty).isMap
      ? 'flagMap'
      : topic;
  return '$category:$countryId';
}

enum AutoLevelEvent { demoted, promoted }

class AutoLevelState {
  const AutoLevelState({
    required this.level,
    this.missStreak = 0,
    this.hitStreak = 0,
    this.dueNow = false,
  });

  const AutoLevelState.initial()
    : level = LearningDifficulty.normal,
      missStreak = 0,
      hitStreak = 0,
      dueNow = false;

  final LearningDifficulty level;
  final int missStreak;
  final int hitStreak;
  final bool dueNow;
}

class AutoLevelTransition {
  const AutoLevelTransition({required this.next, this.event});
  final AutoLevelState next;
  final AutoLevelEvent? event;
}

/// Pure state transition for one item under „Automatyczny” mode:
/// - 3 consecutive misses drop one tier (`normal -> easy -> veryEasy`) and
///   mark the easier card due right away;
/// - 2 consecutive hits climb one tier (`veryEasy -> easy -> normal`).
AutoLevelTransition stepAutoLevel(
  AutoLevelState current, {
  required bool correct,
}) {
  final level = current.level.effectiveFixed;
  if (!correct) {
    final misses = current.missStreak + 1;
    if (misses >= autoDemoteAfterMisses &&
        level != LearningDifficulty.veryEasy) {
      final lower = level == LearningDifficulty.normal
          ? LearningDifficulty.easy
          : LearningDifficulty.veryEasy;
      return AutoLevelTransition(
        next: AutoLevelState(
          level: lower,
          missStreak: 0,
          hitStreak: 0,
          dueNow: true,
        ),
        event: AutoLevelEvent.demoted,
      );
    }
    return AutoLevelTransition(
      next: AutoLevelState(
        level: level,
        missStreak: misses,
        hitStreak: 0,
        dueNow: false,
      ),
    );
  }

  final hits = current.hitStreak + 1;
  if (hits >= autoPromoteAfterHits && level != LearningDifficulty.normal) {
    final higher = level == LearningDifficulty.veryEasy
        ? LearningDifficulty.easy
        : LearningDifficulty.normal;
    return AutoLevelTransition(
      next: AutoLevelState(
        level: higher,
        missStreak: 0,
        hitStreak: 0,
        dueNow: false,
      ),
      event: AutoLevelEvent.promoted,
    );
  }
  return AutoLevelTransition(
    next: AutoLevelState(
      level: level,
      missStreak: 0,
      hitStreak: hits,
      dueNow: false,
    ),
  );
}

class AutoLevelStore {
  const AutoLevelStore(this.db);
  final AppDatabase db;

  Future<Map<String, AutoLevel>> loadForCountries(
    Iterable<String> countryIds,
  ) async {
    final ids = countryIds.toList();
    if (ids.isEmpty) return const {};
    final rows = await (db.select(
      db.autoLevels,
    )..where((a) => a.countryId.isIn(ids))).get();
    return {for (final row in rows) row.itemId: row};
  }

  Future<AutoLevel?> find(String itemId) => (db.select(
    db.autoLevels,
  )..where((a) => a.itemId.equals(itemId))).getSingleOrNull();

  static LearningDifficulty parseLevel(String raw) =>
      LearningDifficulty.fixed.where((l) => l.name == raw).firstOrNull ??
      LearningDifficulty.normal;

  Future<AutoLevelTransition?> recordAnswer({
    required String topic,
    required String countryId,
    required String difficulty,
    required bool correct,
    required DateTime now,
  }) async {
    final id = autoItemId(topic, countryId, difficulty);
    final existing = await find(id);
    if (existing == null && correct) return null;
    final current = existing == null
        ? const AutoLevelState.initial()
        : AutoLevelState(
            level: parseLevel(existing.level),
            missStreak: existing.missStreak,
            hitStreak: existing.hitStreak,
            dueNow: existing.dueNow,
          );
    final transition = stepAutoLevel(current, correct: correct);
    await db
        .into(db.autoLevels)
        .insertOnConflictUpdate(
          AutoLevelsCompanion.insert(
            itemId: id,
            countryId: countryId,
            level: transition.next.level.name,
            missStreak: Value(transition.next.missStreak),
            hitStreak: Value(transition.next.hitStreak),
            dueNow: Value(transition.next.dueNow),
            lastTransition: Value(transition.event?.name),
            updatedAt: now.toUtc(),
          ),
        );
    return transition;
  }
}
