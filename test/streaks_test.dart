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
      await LearningReset(db).continent(Continent.europe, {'TUR'});
      expect((await db.select(db.activityDays).get()).single.continent, 'asia');
      await LearningReset(db).all();
      expect(await db.select(db.activityDays).get(), isEmpty);
    },
  );
}
