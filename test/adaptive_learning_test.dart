import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/learning/capitals.dart';
import 'package:geokuna/features/learning/flags.dart';
import 'package:geokuna/features/learning/memory.dart';
import 'package:geokuna/features/learning/session_repository.dart';

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
  }) {
    final i = s.index;
    final wrongCountry = catalog.countries
        .firstWhere((c) => c.id != s.targetId)
        .id;
    if (s.isMapAt(i)) {
      return repo.guessMap(
        s.row.id,
        i,
        correct ? s.targetId : wrongCountry,
        catalog.countries.map((c) => c.id).toSet(),
        expectedGuessIndex: 0,
      );
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
}
