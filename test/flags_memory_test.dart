import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/learning/capitals.dart';
import 'package:geokuna/features/learning/flags.dart';
import 'package:geokuna/features/learning/session_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'flag reviews join daily sessions with their snapshots and own skill',
    () async {
      final catalog = await Catalog.load();
      final capitals = await CapitalCatalog.load();
      final flags = await FlagCatalog.load();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      var now = DateTime.utc(2026, 11, 13, 12);
      final repo = SessionRepository(db, clock: () => now);
      final overview = await repo.memoryOverview(
        catalog,
        capitals,
        flags: flags,
      );
      expect(overview.newAvailable, 204);
      expect(overview.newRemainingToday, 3);
      final manual = await repo.startFlags(
        flags,
        FlagDifficulty.write,
        random: Random(3),
      );
      await repo.answerFlag(
        manual.row.id,
        0,
        manual.flagQuestionAt(0).countryName,
      );
      await repo.finish(manual.row.id);
      now = now.add(const Duration(days: 20)); // known at first sight: ~16 days
      final daily = (await repo.startDaily(catalog, capitals, flags: flags))!;
      expect(daily.isFlagAt(0), isTrue);
      expect(daily.flagDifficulty, FlagDifficulty.write);
      expect(daily.targetId, manual.targetId);
      expect(
        daily.flagQuestionAt(0).assetPath,
        manual.flagQuestionAt(0).assetPath,
      );
      expect(daily.countryIds.toSet().length, daily.countryIds.length);
      final progress = await repo.learningProgress(catalog, flags: flags);
      expect(progress, hasLength(612));
      final map = await repo.startFlags(
        flags,
        FlagDifficulty.map,
        random: Random(4),
      );
      await repo.guessMap(
        map.row.id,
        0,
        map.targetId,
        catalog.countries.map((c) => c.id).toSet(),
        expectedGuessIndex: 0,
      );
      final logs = await db.select(db.memoryReviews).get();
      expect(logs.any((l) => l.skillId == 'flags:${map.targetId}:map'), isTrue);
    },
  );
}
