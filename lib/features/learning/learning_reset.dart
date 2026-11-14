import 'package:drift/drift.dart';

import '../../core/database/database.dart';
import '../atlas/continent.dart';
import 'memory.dart';

/// Resets explicitly selected learning data. Call only after user confirmation.
class LearningReset {
  const LearningReset(this.db);
  final AppDatabase db;

  Future<void> all() => db.transaction(() async {
    await db.delete(db.activityDays).go();
    await db.delete(db.awardedMedals).go();
    await db.delete(db.memoryReviews).go();
    await db.delete(db.mapGuesses).go();
    await db.delete(db.attempts).go();
    await db.delete(db.sessions).go();
    await db.delete(db.memoryCards).go();
    await db.delete(db.memoryMeta).go();
  });

  Future<void> continent(
    Continent continent,
    Set<String> countryIds,
  ) => db.transaction(() async {
    await (db.delete(
      db.activityDays,
    )..where((d) => d.continent.equals(continent.name))).go();
    await (db.delete(
      db.awardedMedals,
    )..where((m) => m.continent.equals(continent.name))).go();
    await MemoryStore(db).importHistoryOnce();
    final sessions = await (db.select(
      db.sessions,
    )..where((s) => s.continent.equals(continent.name))).get();
    final sessionIds = sessions.map((s) => s.id).toList();
    final cards = await (db.select(
      db.memoryCards,
    )..where((c) => c.countryId.isIn(countryIds))).get();
    final cardIds = cards.map((c) => c.id).toList();
    await (db.delete(
          db.memoryReviews,
        )..where((r) => r.sessionId.isIn(sessionIds) | r.skillId.isIn(cardIds)))
        .go();
    await (db.delete(
      db.mapGuesses,
    )..where((g) => g.sessionId.isIn(sessionIds))).go();
    await (db.delete(
      db.attempts,
    )..where((a) => a.sessionId.isIn(sessionIds))).go();
    await (db.delete(db.sessions)..where((s) => s.id.isIn(sessionIds))).go();
    await (db.delete(db.memoryCards)..where((c) => c.id.isIn(cardIds))).go();
    // Other regions may retain historic attempts of shared countries.
    // They must not silently restore the reset memory on next startup.
    await db
        .into(db.memoryMeta)
        .insertOnConflictUpdate(
          MemoryMetaCompanion.insert(key: 'history-import-v1', value: 'done'),
        );
  });
}
