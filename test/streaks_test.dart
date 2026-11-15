import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/continent.dart';
import 'package:geokuna/features/learning/learning_reset.dart';
import 'package:geokuna/features/learning/streaks.dart';

void main() {
  test(
    'streak uses stored local dates, yesterday grace, gaps and regional reset',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final store = StreakStore(db);
      Future<void> day(String date, String continent) async {
        await db
            .into(db.activityDays)
            .insert(
              ActivityDaysCompanion.insert(
                continent: continent,
                localDate: date,
                recordedAt: DateTime.parse('${date}T12:00:00Z'),
                offsetMinutes: 60,
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }

      await day('2026-10-24', 'europe');
      await day('2026-10-25', 'europe');
      await day('2026-10-26', 'europe');
      await day('2026-10-26', 'europe');
      await day('2026-10-26', 'asia');
      final beforeToday = await store.overview(
        Continent.europe,
        now: DateTime(2026, 10, 27, 12),
      );
      expect(beforeToday.current, 3);
      expect(beforeToday.best, 3);
      expect(beforeToday.practisedToday, isFalse);
      final rewardDay = await store.overview(
        Continent.europe,
        now: DateTime(2026, 10, 26, 18),
      );
      expect(rewardDay.rewardToday, 3);
      expect(beforeToday.rewardToday, null);
      expect(beforeToday.earnedRewards, [3]);
      final gap = await store.overview(
        Continent.europe,
        now: DateTime(2026, 10, 28, 12),
      );
      expect(gap.current, 0);
      expect(gap.best, 3);
      await day('2026-10-28', 'europe');
      final resumed = await store.overview(
        Continent.europe,
        now: DateTime(2026, 10, 28, 12),
      );
      expect(resumed.current, 1);
      expect(resumed.practisedToday, isTrue);
      // A broken streak keeps the reward; the next one counts from today.
      expect(resumed.earnedRewards, [3]);
      expect((resumed.nextReward, resumed.daysToNextReward), (7, 6));
      await LearningReset(db).continent(Continent.europe, {'TUR'});
      expect((await db.select(db.activityDays).get()).single.continent, 'asia');
      await LearningReset(db).all();
      expect(await db.select(db.activityDays).get(), isEmpty);
    },
  );

  test('tokens: one per 7 days up to 3; one saves one missed day', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final store = StreakStore(db);
    Future<void> practise(Continent continent, int from, int to) async {
      for (var d = from; d <= to; d++) {
        final date = dateKey(DateTime.utc(2026, 1, d));
        await db
            .into(db.activityDays)
            .insert(
              ActivityDaysCompanion.insert(
                continent: continent.name,
                localDate: date,
                recordedAt: DateTime.utc(2026, 1, d, 12),
                offsetMinutes: 60,
              ),
            );
      }
    }

    Future<StreakSummary> on(Continent continent, int day) =>
        store.overview(continent, now: DateTime(2026, 1, day, 12));

    await practise(Continent.europe, 1, 8);
    final day8 = await on(Continent.europe, 8);
    expect((day8.tokens, day8.daysToNextToken), (1, 6));
    expect((await on(Continent.europe, 7)).tokenEarnedToday, isTrue);
    // Day 9 missed: on day 10 the streak waits for a decision.
    final day10 = await on(Continent.europe, 10);
    expect(day10.current, 0);
    expect(day10.rescue!.missedDays, ['2026-01-09']);
    expect(day10.rescue!.streak, 8);
    await store.decide(Continent.europe, day10.rescue!, keep: true);
    await practise(Continent.europe, 10, 10);
    final saved = await on(Continent.europe, 10);
    expect((saved.current, saved.tokens, saved.rescue), (9, 0, null));
    expect(saved.daysToNextToken, 6); // 7 after the spent token, day 10 counts

    // Declining ends the streak; a full set of tokens stops at 3.
    await practise(Continent.asia, 1, 30);
    expect((await on(Continent.asia, 30)).tokens, 3);
    final gap = await on(Continent.asia, 32);
    await store.decide(Continent.asia, gap.rescue!, keep: false);
    final declined = await on(Continent.asia, 32);
    expect((declined.current, declined.rescue, declined.tokens), (0, null, 3));
  });
}
