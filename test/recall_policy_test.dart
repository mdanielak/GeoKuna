import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/learning/capitals.dart';
import 'package:geokuna/features/learning/flags.dart';
import 'package:geokuna/features/learning/memory.dart';
import 'package:geokuna/features/learning/session_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'A–D has separate recognition FSRS without updating full recall',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SessionRepository(
        db,
        clock: () => DateTime(2026, 11, 14, 12),
      );
      final capitals = await CapitalCatalog.load();
      final session = await repo.startCapitals(
        capitals,
        CapitalDifficulty.choice,
      );
      final result = await repo.answerCapital(
        session.row.id,
        0,
        session.capitalQuestion.fact.name,
      );
      // A repeated write is idempotent and records the learning day once.
      await repo.answerCapital(
        session.row.id,
        0,
        session.capitalQuestion.fact.name,
      );
      expect(await db.select(db.activityDays).get(), hasLength(1));
      expect(result.currentAttempt!.correct, isTrue);
      expect(result.correctCount, 1);
      expect(
        (await db.select(db.memoryCards).get()).where((c) => c.state != null),
        hasLength(1),
      );
      final reviews = await db.select(db.memoryReviews).get();
      expect(reviews.single.applied, isTrue);
      expect(reviews.single.skillId, endsWith(':choice'));
      expect(reviews.single.rating, 3);
      final flags = await FlagCatalog.load();
      final flag = await repo.startFlags(flags, FlagDifficulty.choice);
      await repo.answerFlag(flag.row.id, 0, flag.flagQuestionAt(0).countryName);
      expect(
        (await db.select(db.memoryReviews).get()).every((r) => r.applied),
        isTrue,
      );
    },
  );
  test(
    'new daily questions prefer full recall and never suggest A–D',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SessionRepository(db);
      final catalog = await Catalog.load();
      final capitals = await CapitalCatalog.load();
      final flags = await FlagCatalog.load();
      final session = (await repo.startDaily(catalog, capitals, flags: flags))!;
      for (var i = 0; i < session.countryIds.length; i++) {
        expect(recallFormats, contains(session.difficultyNameAt(i)));
      }
      final entries = await repo.learningProgress(catalog, flags: flags);
      expect(entries.any((e) => e.difficulty == 'choice'), isTrue);
      expect(entries.length, 47 * 12);
    },
  );
}
