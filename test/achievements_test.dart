import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/learning/achievements.dart';
import 'package:geokuna/features/settings/app_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('qualification requires delayed applied successes without intervening error', () {
    final start = DateTime.utc(2026, 11, 14, 12);
    MemoryReview review(int hours, int rating, {bool applied = true}) =>
        MemoryReview(
          sessionId: '$hours-$rating',
          questionIndex: 0,
          skillId: 'capitals:POL:choice',
          rating: rating,
          reviewedAt: start.add(Duration(hours: hours)),
          wasNew: hours == 0,
          applied: applied,
          origin: 'manual',
          reviewLog: null,
        );
    expect(qualifiedSkillIds([review(0, 3), review(23, 3)]), isEmpty);
    expect(
      qualifiedSkillIds([review(0, 3), review(24, 3, applied: false)]),
      isEmpty,
    );
    expect(
      qualifiedSkillIds([review(0, 3), review(12, 1), review(24, 3)]),
      isEmpty,
    );
    expect(qualifiedSkillIds([review(0, 3), review(24, 3)]), {
      'capitals:POL:choice',
    });
  });
  test('historical medals survive a later mistake and only inherit within their category', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final full = await Catalog.load();
    final countries = full.countries.take(2).toList();
    final ids = countries.map((c) => c.id).toSet();
    final catalog = Catalog(
      countries,
      full.shapes.where((s) => ids.contains(s.countryId)).toList(),
      version: 'test-v1',
    );
    final start = DateTime.utc(2026, 11, 14, 12);
    var sequence = 0;
    Future<void> review(String country, int day, int rating) async {
      final id = 'review-${sequence++}';
      await db
          .into(db.sessions)
          .insert(
            SessionsCompanion.insert(
              id: id,
              countryIds: '["$country"]',
              createdAt: start,
            ),
          );
      await db
          .into(db.memoryCards)
          .insert(
            MemoryCardsCompanion.insert(
              id: 'map:$country:map',
              countryId: country,
              topic: 'map',
              difficulty: 'map',
            ),
            mode: InsertMode.insertOrIgnore,
          );
      await db
          .into(db.memoryReviews)
          .insert(
            MemoryReviewsCompanion.insert(
              sessionId: id,
              questionIndex: 0,
              skillId: 'map:$country:map',
              rating: rating,
              reviewedAt: start.add(Duration(days: day)),
              wasNew: day == 0,
              applied: true,
              origin: 'manual',
            ),
          );
    }

    for (final c in countries) {
      await review(c.id, 0, 3);
      await review(c.id, 1, 3);
    }
    // No overview was opened before the later error.
    await review(countries.first.id, 2, 1);
    final achievements = await AchievementStore(db).refresh(catalog);
    for (final level in LearningDifficulty.values) {
      final map = achievements.singleWhere(
        (a) => a.topic == 'map' && a.level == level,
      );
      expect(map.earnedMedal, 3);
      expect(map.earnedAt!.toUtc(), start.add(const Duration(days: 1)));
      expect(map.qualifiedCount, 1);
      expect(map.inheritedCount, level == LearningDifficulty.normal ? 0 : 1);
    }
    expect(
      achievements
          .where((a) => a.topic != 'map')
          .every((a) => a.earnedMedal == 0),
      isTrue,
    );
    final count = (await db.select(db.memoryReviews).get()).length;
    await AchievementStore(db).refresh(catalog);
    expect((await db.select(db.memoryReviews).get()).length, count);
    expect(await db.select(db.awardedMedals).get(), hasLength(9));
  });
}
