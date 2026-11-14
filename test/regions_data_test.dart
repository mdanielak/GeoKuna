import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/atlas/continent.dart';
import 'package:geokuna/features/learning/capitals.dart';
import 'package:geokuna/features/learning/flags.dart';
import 'package:geokuna/features/learning/session_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'regional packages have full map/capital/flag coverage and valid options',
    () async {
      for (final (continent, count) in [
        (Continent.africa, 54),
        (Continent.asia, 50),
      ]) {
        final catalog = await Catalog.load(continent: continent);
        final capitals = await CapitalCatalog.load(continent: continent);
        final flags = await FlagCatalog.load(continent: continent);
        expect(catalog.continent, continent);
        expect(catalog.countries, hasLength(count));
        final ids = catalog.countries.map((c) => c.id).toSet();
        expect(capitals.facts.map((f) => f.countryId).toSet(), ids);
        expect(flags.facts.map((f) => f.countryId).toSet(), ids);
        for (final question in capitals.questions(ids.toList(), Random(2))) {
          expect(question.options.toSet(), hasLength(4));
          expect(question.options, contains(question.fact.name));
          for (final alias in question.fact.aliases) {
            expect(evaluateCapitalAnswer(alias, question.fact).correct, isTrue);
          }
        }
        final db = AppDatabase(NativeDatabase.memory());
        try {
          final repo = SessionRepository(db, continent: continent);
          final session = await repo.startCapitals(
            capitals,
            CapitalDifficulty.write,
          );
          final answered = await repo.answerCapital(
            session.row.id,
            0,
            session.capitalQuestion.fact.name,
          );
          expect(answered.currentAttempt!.correct, isTrue);
          expect(
            (await db.select(db.memoryReviews).get()).single.applied,
            isTrue,
          );
        } finally {
          await db.close();
        }
      }
    },
  );
  test(
    'daily budget is shared across continents while suggestions are regional',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final eu = SessionRepository(db);
      final catalog = await Catalog.load();
      final capitals = await CapitalCatalog.load();
      var session = (await eu.startDaily(catalog, capitals))!;
      final africaWhileEuropeIsOpen = SessionRepository(
        db,
        continent: Continent.africa,
      );
      expect(
        (await africaWhileEuropeIsOpen.memoryOverview(
          await Catalog.load(continent: Continent.africa),
          await CapitalCatalog.load(continent: Continent.africa),
        )).newRemainingToday,
        0,
      );
      while (!session.completed) {
        expect(session.difficulty.name, 'write');
        await eu.answerCapital(
          session.row.id,
          session.index,
          session.capitalQuestion.fact.name,
        );
        session = await eu.advance(session.row.id, session.index);
      }
      final af = SessionRepository(db, continent: Continent.africa);
      final afCatalog = await Catalog.load(continent: Continent.africa);
      final afCapitals = await CapitalCatalog.load(continent: Continent.africa);
      final overview = await af.memoryOverview(afCatalog, afCapitals);
      expect(overview.newRemainingToday, 0);
      expect(overview.dueCount, 0);
      expect(await af.startDaily(afCatalog, afCapitals), isNull);
    },
  );
}
