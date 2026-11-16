import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/atlas/continent.dart';
import 'package:geokuna/features/learning/achievements.dart';
import 'package:geokuna/features/learning/capitals.dart';
import 'package:geokuna/features/learning/flags.dart';
import 'package:geokuna/features/learning/session_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'voivodeships and US states: map-only catalogs and a daily round',
    () async {
      for (final (area, count, id, question) in [
        (Continent.poland, 16, 'PL-14', 'Gdzie leży województwo mazowieckie?'),
        (Continent.usa, 50, 'US-WA', 'Gdzie leży stan Waszyngton?'),
      ]) {
        expect(area.hasCapitalsAndFlags, isFalse);
        final catalog = await Catalog.load(continent: area);
        expect(catalog.countries, hasLength(count));
        expect(catalog.country(id).locationQuestion, question);
        final capitals = await CapitalCatalog.load(continent: area);
        expect(capitals.facts, isEmpty);
        expect((await FlagCatalog.load(continent: area)).facts, isEmpty);
        final db = AppDatabase(NativeDatabase.memory());
        try {
          final repo = SessionRepository(db, continent: area);
          final session = (await repo.startDaily(catalog, capitals))!;
          expect(session.isCapital, isFalse);
          final answered = await repo.guessMap(
            session.row.id,
            0,
            session.targetId,
            {session.targetId},
            expectedGuessIndex: 0,
          );
          expect(answered.currentAttempt!.correct, isTrue);
          final cards = await db.select(db.memoryCards).get();
          expect(
            cards.every((c) => c.countryId.startsWith(id.substring(0, 3))),
            isTrue,
          );
          expect(cards.where((c) => c.topic != 'map'), isEmpty);
          // Progress and medals count the map only (no capitals/flags yet).
          final progress = await repo.learningProgress(
            catalog,
            flags: await FlagCatalog.load(continent: area),
          );
          expect(progress, hasLength(count * 3));
          final medals = await AchievementStore(db).refresh(catalog);
          expect(medals.every((m) => m.topic == 'map'), isTrue);
        } finally {
          await db.close();
        }
      }
      final usa = await Catalog.load(continent: Continent.usa);
      expect(usa.insetFrames.map((f) => f.areaId), ['US-AK', 'US-HI']);
      expect(Continent.europe.hasCapitalsAndFlags, isTrue);
    },
  );
}
