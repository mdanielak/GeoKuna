import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/learning/capitals.dart';
import 'package:geokuna/features/learning/flags.dart';
import 'package:geokuna/features/learning/session_repository.dart';
import 'package:geokuna/features/settings/app_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'a qualified normal skill does not introduce a redundant easier card',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      var now = DateTime(2026, 11, 14, 12);
      final normal = SessionRepository(db, clock: () => now);
      for (var day = 0; day < 2; day++) {
        final session = await normal.start(['POL']);
        await normal.guessMap(session.row.id, 0, 'POL', {
          'POL',
        }, expectedGuessIndex: 0);
        await normal.finish(session.row.id);
        now = now.add(const Duration(days: 20)); // past the first-sight gap
      }
      final full = await Catalog.load();
      final catalog = Catalog([
        full.country('POL'),
      ], full.shapes.where((s) => s.countryId == 'POL').toList());
      final easy = SessionRepository(
        db,
        clock: () => now,
        level: LearningDifficulty.veryEasy,
      );
      final overview = await easy.memoryOverview(
        catalog,
        await CapitalCatalog.load(),
      );
      expect(
        overview.newAvailable,
        1,
        reason: 'only capital recognition is new, map inherited',
      );
      final daily = (await easy.startDaily(
        catalog,
        await CapitalCatalog.load(),
      ))!;
      expect(daily.topicAt(0), 'capitals');
      expect(daily.difficultyNameAt(0), 'choice');
    },
  );
  test(
    'three map levels preserve normal key and have independent histories',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      for (final level in LearningDifficulty.values) {
        final repo = SessionRepository(db, level: level);
        final session = await repo.start(['POL']);
        final expected = ['mapVeryEasy', 'mapEasy', 'map'][level.index];
        expect(session.difficultyNameAt(0), expected);
        await repo.guessMap(session.row.id, 0, 'POL', {
          'POL',
        }, expectedGuessIndex: 0);
        await repo.finish(session.row.id);
      }
      final cards = await db.select(db.memoryCards).get();
      expect(cards.map((c) => c.id).toSet(), {
        'map:POL:mapVeryEasy',
        'map:POL:mapEasy',
        'map:POL:map',
      });
      expect(cards.every((c) => c.reviewCount == 1), isTrue);
    },
  );
  test(
    'daily recognition stays in its own level and shares global new limit',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SessionRepository(db, level: LearningDifficulty.veryEasy);
      final catalog = await Catalog.load();
      final capitals = await CapitalCatalog.load();
      final flags = await FlagCatalog.load();
      final daily = (await repo.startDaily(catalog, capitals, flags: flags))!;
      expect(daily.countryIds, hasLength(3));
      for (var index = 0; index < daily.countryIds.length; index++) {
        expect([
          'choice',
          'mapVeryEasy',
        ], contains(daily.difficultyNameAt(index)));
      }
      var current = daily;
      while (!current.completed) {
        if (current.isMapAt(current.index)) {
          current = await repo.guessMap(
            current.row.id,
            current.index,
            current.targetId,
            catalog.countries.map((c) => c.id).toSet(),
            expectedGuessIndex: 0,
          );
        } else if (current.isCapital) {
          current = await repo.answerCapital(
            current.row.id,
            current.index,
            current.capitalQuestion.fact.name,
          );
        } else {
          current = await repo.answerFlag(
            current.row.id,
            current.index,
            current.flagQuestionAt(current.index).countryName,
          );
        }
        current = await repo.advance(current.row.id, current.index);
      }
      final normal = SessionRepository(db);
      final overview = await normal.memoryOverview(
        catalog,
        capitals,
        flags: flags,
      );
      expect(overview.newRemainingToday, 0);
      expect(overview.plannedNewCount, 0);
    },
  );
}
