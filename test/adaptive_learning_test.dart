import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/learning/capitals.dart';
import 'package:geokuna/features/learning/daily_planner.dart';
import 'package:geokuna/features/learning/flags.dart';
import 'package:geokuna/features/learning/memory.dart';
import 'package:geokuna/features/learning/session_repository.dart';
import 'package:geokuna/features/settings/app_preferences.dart';

/// Simulated learners checking the core rule: do not ask about what the user
/// already knows, focus on mistakes, and still re-check known facts.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Catalog catalog;
  late CapitalCatalog capitals;
  late FlagCatalog flags;
  setUpAll(() async {
    catalog = await Catalog.load();
    capitals = await CapitalCatalog.load();
    flags = await FlagCatalog.load();
  });

  Future<LearningSession> answer(
    SessionRepository repo,
    LearningSession s, {
    required bool correct,
  }) async {
    final i = s.index;
    final all = catalog.countries.map((c) => c.id).toSet();
    if (s.isMapAt(i)) {
      if (correct) {
        return repo.guessMap(
          s.row.id,
          i,
          s.targetId,
          all,
          expectedGuessIndex: 0,
        );
      }
      final wrongPicks = catalog.countries
          .where((c) => c.id != s.targetId)
          .take(3)
          .map((c) => c.id)
          .toList();
      var current = s;
      for (var g = 0; g < 3; g++) {
        current = await repo.guessMap(
          current.row.id,
          i,
          wrongPicks[g],
          all,
          expectedGuessIndex: g,
        );
      }
      return current;
    }
    if (s.isCapital) {
      return repo.answerCapital(
        s.row.id,
        i,
        correct ? s.capitalQuestion.fact.name : 'Xyzzyx',
      );
    }
    return repo.answerFlag(
      s.row.id,
      i,
      correct ? s.flagQuestionAt(i).countryName : 'Xyzzyx',
    );
  }

  Future<void> finishSeries(
    SessionRepository repo,
    LearningSession s, {
    bool Function(LearningSession)? correct,
  }) async {
    while (!s.completed) {
      s = await answer(repo, s, correct: correct?.call(s) ?? true);
      s = await repo.advance(s.row.id, s.index);
    }
  }

  test('expert: known skills return only after the capped gap', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    var now = DateTime(2026, 11, 1, 9);
    final repo = SessionRepository(db, clock: () => now);
    final asked = <String, List<int>>{};
    for (var day = 0; day < 30; day++) {
      now = DateTime(2026, 11, 1 + day, 9);
      final s = await repo.startDaily(catalog, capitals, flags: flags);
      if (s == null) continue;
      for (var i = 0; i < s.countryIds.length; i++) {
        final skill =
            '${s.topicAt(i)}:${s.countryIds[i]}:${s.difficultyNameAt(i)}';
        (asked[skill] ??= []).add(day);
      }
      await finishSeries(repo, s);
    }
    expect(asked, isNotEmpty);
    for (final MapEntry(key: skill, value: days) in asked.entries) {
      for (var k = 1; k < days.length; k++) {
        // Known at first sight: no re-ask minutes or days later.
        expect(days[k] - days[k - 1], greaterThanOrEqualTo(7), reason: skill);
        expect(days[k] - days[k - 1], lessThanOrEqualTo(maxReviewIntervalDays));
      }
    }
  });

  test('struggler: a miss repeats after 3–5 questions, ungraded, and leads '
      'the next round the same day', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    var now = DateTime(2026, 11, 1, 9);
    final repo = SessionRepository(db, clock: () => now);
    var s = (await repo.startDaily(
      catalog,
      capitals,
      flags: flags,
      mode: DailyMode.placement,
    ))!;
    final planned = s.countryIds.length;
    expect(planned, seriesSize);
    final missed = s.skillIdAt(0);
    s = await answer(repo, s, correct: false);
    expect(s.countryIds, hasLength(planned + 1));
    final position = List.generate(
      s.countryIds.length,
      (i) => i,
    ).singleWhere(s.isRetryAt);
    expect(position - 1, inInclusiveRange(retryGapMin, retryGapMax));
    expect(s.skillIdAt(position), missed);
    await finishSeries(repo, await repo.advance(s.row.id, 0));
    s = await repo.byId(s.row.id);
    expect(s.scoredAttempts, hasLength(planned));
    expect(s.correctCount, planned - 1);
    final reviews = await db.select(db.memoryReviews).get();
    expect(reviews.singleWhere((r) => r.origin == 'retry').applied, isFalse);
    // Hits in the knowledge check are free; only the miss uses the budget.
    expect(
      (await repo.memoryOverview(
        catalog,
        capitals,
        flags: flags,
      )).newRemainingToday,
      dailyNewBudget - 1,
    );

    now = now.add(const Duration(minutes: 30));
    var next = (await repo.startDaily(
      catalog,
      capitals,
      flags: flags,
      mode: DailyMode.extra,
    ))!;
    expect(next.skillIdAt(0), missed, reason: 'the hard country leads');
    next = await answer(repo, next, correct: true);
    expect(next.insight?.recovery, 1);
  });

  test(
    'ladder: a skill missed twice is first asked in an easier format',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      var now = DateTime(2026, 11, 1, 9);
      final repo = SessionRepository(db, clock: () => now);
      String? stubborn;
      for (var day = 0; day < 14; day++) {
        now = DateTime(2026, 11, 1 + day, 9);
        var s = await repo.startDaily(catalog, capitals, flags: flags);
        if (s == null) continue;
        stubborn ??= s.skillIdAt(0);
        final scaffold = List.generate(
          s.countryIds.length,
          (i) => i,
        ).where((i) => s.isScaffoldAt(i)).firstOrNull;
        if (scaffold != null) {
          final real = List.generate(
            s.countryIds.length,
            (i) => i,
          ).firstWhere((i) => s.skillIdAt(i) == stubborn && !s.isScaffoldAt(i));
          expect(s.countryIds[scaffold], s.countryIds[real]);
          expect(s.skillIdAt(scaffold), isNot(stubborn));
          expect(
            real - scaffold,
            greaterThan(2),
            reason: 'recall follows later',
          );
          await finishSeries(repo, s);
          final step = await (db.select(
            db.memoryReviews,
          )..where((r) => r.questionIndex.equals(scaffold))).get();
          expect(
            step.where((r) => r.sessionId == s.row.id).single.applied,
            isFalse,
            reason: 'the easier step is practice, not a grade',
          );
          return;
        }
        await finishSeries(
          repo,
          s,
          correct: (s) =>
              s.skillIdAt(s.index) != stubborn || s.isRetryAt(s.index),
        );
      }
      fail('no ladder step within two weeks');
    },
  );

  test('ladder step 2: a confused pair is asked side by side', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    var now = DateTime(2026, 11, 1, 9);
    final repo = SessionRepository(db, clock: () => now);
    final all = catalog.countries.map((c) => c.id).toSet();
    // Twice Slovakia was marked where Slovenia was asked.
    for (var day = 0; day < 2; day++) {
      now = DateTime(2026, 11, 1 + day, 9);
      var s = await repo.start(['SVN']);
      for (final (g, pick) in [(0, 'SVK'), (1, 'HRV'), (2, 'AUT')].indexed) {
        s = await repo.guessMap(
          s.row.id,
          0,
          pick.$2,
          all,
          expectedGuessIndex: g,
        );
      }
      await repo.finish(s.row.id);
    }
    now = DateTime(2026, 11, 4, 9);
    final daily = (await repo.startDaily(catalog, capitals, flags: flags))!;
    final at = List.generate(daily.countryIds.length, (i) => i).firstWhere(
      (i) => daily.skillIdAt(i) == 'map:SVN:map' && !daily.isPracticeAt(i),
    );
    expect(daily.countryIds[at + 1], 'SVK');
    expect(daily.isContrastAt(at + 1), isTrue);
    expect(daily.skillIdAt(at + 1), 'map:SVK:map');
  });

  test('extra round checks known facts once the daily plan is done', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    var now = DateTime(2026, 11, 1, 9);
    final repo = SessionRepository(db, clock: () => now);
    await finishSeries(
      repo,
      (await repo.startDaily(catalog, capitals, flags: flags))!,
    );
    now = DateTime(2026, 11, 2, 9);
    final overview = await repo.memoryOverview(catalog, capitals, flags: flags);
    expect(overview.canStartExtra, isTrue);
    final extra = (await repo.startDaily(
      catalog,
      capitals,
      flags: flags,
      mode: DailyMode.extra,
    ))!;
    expect(extra.countryIds, isNotEmpty);
    expect(
      List.generate(extra.countryIds.length, extra.originAt),
      contains('control'),
    );
  });

  test('manual training puts a missed country first', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    var now = DateTime(2026, 11, 1, 9);
    final repo = SessionRepository(db, clock: () => now);
    final ids = catalog.countries.map((c) => c.id).toList();
    var s = await repo.start(ids);
    final hard = s.targetId;
    await answer(repo, s, correct: false);
    await repo.finish(s.row.id);
    now = DateTime(2026, 11, 2, 9);
    s = await repo.start(ids);
    expect(s.targetId, hard);
  });

  test('placement on easy grants Rating.easy and schedules >= 7 days while misses consume budget', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime(2026, 11, 1, 9);
    final repo = SessionRepository(
      db,
      level: LearningDifficulty.easy,
      clock: () => now,
    );
    var s = (await repo.startDaily(
      catalog,
      capitals,
      flags: flags,
      mode: DailyMode.placement,
    ))!;
    // First question is correct, second is missed, rest correct.
    while (!s.completed) {
      s = await answer(repo, s, correct: s.index != 1);
      s = await repo.advance(s.row.id, s.index);
    }
    final reviews = await db.select(db.memoryReviews).get();
    final graded = reviews.where((r) => r.applied).toList();
    expect(graded.where((r) => r.rating == 4), hasLength(seriesSize - 1));
    expect(graded.where((r) => r.rating == 1), hasLength(1));
    final cards = {
      for (final c in await db.select(db.memoryCards).get()) c.id: c,
    };
    for (final r in graded.where((r) => r.rating == 4)) {
      expect(
        cards[r.skillId]!.due!.difference(now).inDays,
        greaterThanOrEqualTo(7),
      );
    }
    final after = await repo.memoryOverview(catalog, capitals, flags: flags);
    expect(after.newRemainingToday, dailyNewBudget - 1);
  });

  test(
    'normal daily introduces both write and map skills without starving map',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      var now = DateTime(2026, 11, 1, 9);
      final repo = SessionRepository(db, clock: () => now);
      final seenTopics = <String>{};
      for (var day = 0; day < 7; day++) {
        now = DateTime(2026, 11, 1 + day, 9);
        final s = (await repo.startDaily(catalog, capitals, flags: flags))!;
        for (var i = 0; i < s.countryIds.length; i++) {
          seenTopics.add(s.topicAt(i));
        }
        await finishSeries(repo, s);
      }
      expect(seenTopics, contains('map'));
      expect(seenTopics, contains('capitals'));
      expect(seenTopics, contains('flags'));
    },
  );

  test('confusion decays after 3 consecutive graded hits and flag A–D contrast keeps target option', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    var now = DateTime(2026, 11, 1, 9);
    final repo = SessionRepository(db, clock: () => now);
    final all = catalog.countries.map((c) => c.id).toSet();
    for (var day = 0; day < 2; day++) {
      now = DateTime(2026, 11, 1 + day, 9);
      var s = await repo.start(['SVN']);
      for (final (g, pick) in [(0, 'SVK'), (1, 'HRV'), (2, 'AUT')].indexed) {
        s = await repo.guessMap(
          s.row.id,
          0,
          pick.$2,
          all,
          expectedGuessIndex: g,
        );
      }
      await repo.finish(s.row.id);
    }
    final planner = DailyPlanner(
      db,
      continent: catalog.continent,
      level: LearningDifficulty.normal,
      clock: () => now,
    );
    expect(
      await planner.confusions(catalog, flags),
      containsPair('SVN', 'SVK'),
    );
    for (var k = 0; k < 3; k++) {
      now = now.add(const Duration(days: 30));
      var s = await repo.start(['SVN']);
      await repo.guessMap(s.row.id, 0, 'SVN', all, expectedGuessIndex: 0);
      await repo.finish(s.row.id);
    }
    expect(await planner.confusions(catalog, flags), isNot(contains('SVN')));

    // Check symmetric options on flag A–D contrast.
    final polQuestion = flags.questions(['POL'], Random(1)).single;
    final mcoQuestions = <Map<String, dynamic>>[
      {
        ...polQuestion.toJson(),
        'topic': 'flags',
        'difficulty': 'choice',
        'skill_id': 'flags:POL:choice',
        'country_id': 'POL',
      },
    ];
    addContrasts(mcoQuestions, {'POL': 'MCO'}, flags);
    expect(mcoQuestions, hasLength(2));
    expect(mcoQuestions[0]['options'], contains('Monako'));
    expect(mcoQuestions[1]['options'], contains('Polska'));
  });
}
