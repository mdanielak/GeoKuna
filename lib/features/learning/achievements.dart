import 'package:drift/drift.dart';

import '../../core/database/database.dart';
import '../atlas/catalog.dart';
import '../atlas/continent.dart';
import '../settings/app_preferences.dart';
import 'learning_levels.dart';

class CategoryAchievement {
  const CategoryAchievement({
    required this.topic,
    required this.level,
    required this.earnedMedal,
    required this.earnedAt,
    required this.qualifiedCount,
    required this.totalCount,
    required this.inheritedCount,
    this.learningCount = 0,
  });

  /// Countries answered at this level but not yet qualified ("w nauce").
  final int learningCount;
  final String topic;
  final LearningDifficulty level;
  final int earnedMedal, qualifiedCount, totalCount, inheritedCount;
  final DateTime? earnedAt;
  int get percent => totalCount == 0 ? 0 : qualifiedCount * 100 ~/ totalCount;
}

class AchievementStore {
  const AchievementStore(this.db);
  final AppDatabase db;

  /// Computes medals; with [persist] newly reached ones are stored. Today
  /// reads without writing (no lock on every visit); Moja nauka persists.
  Future<List<CategoryAchievement>> refresh(
    Catalog catalog, {
    DateTime? now,
    bool persist = true,
  }) => persist
      ? db.transaction(() => _compute(catalog, true))
      : _compute(catalog, false);

  Future<List<CategoryAchievement>> _compute(
    Catalog catalog,
    bool persist,
  ) async {
    final countryIds = catalog.countries.map((c) => c.id).toSet();
    final cards = await (db.select(
      db.memoryCards,
    )..where((c) => c.countryId.isIn(countryIds))).get();
    final reviews =
        await (db.select(db.memoryReviews)
              ..where(
                (r) =>
                    r.applied.equals(true) &
                    r.skillId.isIn(cards.map((c) => c.id)),
              )
              ..orderBy([(r) => OrderingTerm.asc(r.reviewedAt)]))
            .get();
    final milestones = <String, DateTime>{};
    final qualified = qualifiedSkillIds(
      reviews,
      onQualified: (skills, at) {
        for (final topic in _topics(catalog.continent)) {
          for (final level in LearningDifficulty.values) {
            final count = _effectiveCountries(
              skills,
              countryIds,
              topic,
              level,
            ).length;
            for (final (medal, threshold) in [(1, 50), (2, 80), (3, 100)]) {
              if (countryIds.isNotEmpty &&
                  count * 100 >= countryIds.length * threshold) {
                milestones.putIfAbsent('$topic:${level.name}:$medal', () => at);
              }
            }
          }
        }
      },
    );
    final earned = await (db.select(
      db.awardedMedals,
    )..where((m) => m.continent.equals(catalog.continent.name))).get();
    final answered = reviews.map((r) => r.skillId).toSet();
    final result = <CategoryAchievement>[];
    for (final topic in _topics(catalog.continent)) {
      for (final level in LearningDifficulty.values) {
        final direct = _effectiveCountries(
          qualified,
          countryIds,
          topic,
          level,
          directOnly: true,
        );
        final effective = _effectiveCountries(
          qualified,
          countryIds,
          topic,
          level,
        );
        for (final medal in [1, 2, 3]) {
          final earnedAt = milestones['$topic:${level.name}:$medal'];
          if (earnedAt != null &&
              !earned.any(
                (m) =>
                    m.topic == topic &&
                    m.level == level.name &&
                    m.medal == medal,
              )) {
            final row = !persist
                ? AwardedMedal(
                    continent: catalog.continent.name,
                    topic: topic,
                    level: level.name,
                    medal: medal,
                    earnedAt: earnedAt.toUtc(),
                    catalogVersion: catalog.version,
                  )
                : await db
                      .into(db.awardedMedals)
                      .insertReturning(
                        AwardedMedalsCompanion.insert(
                          continent: catalog.continent.name,
                          topic: topic,
                          level: level.name,
                          medal: medal,
                          earnedAt: earnedAt.toUtc(),
                          catalogVersion: catalog.version,
                        ),
                        mode: InsertMode.insertOrIgnore,
                      );
            earned.add(row);
          }
        }
        final awards =
            earned
                .where((m) => m.topic == topic && m.level == level.name)
                .toList()
              ..sort((a, b) => b.medal.compareTo(a.medal));
        result.add(
          CategoryAchievement(
            topic: topic,
            level: level,
            earnedMedal: awards.firstOrNull?.medal ?? 0,
            earnedAt: awards.firstOrNull?.earnedAt,
            qualifiedCount: effective.length,
            totalCount: countryIds.length,
            inheritedCount: effective.difference(direct).length,
            learningCount: _effectiveCountries(
              answered,
              countryIds,
              topic,
              level,
              directOnly: true,
            ).difference(effective).length,
          ),
        );
      }
    }
    return result;
  }
}

/// Uses only real, applied first-answer reviews. An early successful practice
/// has applied=false, so cannot qualify a fact or manufacture an achievement.
Set<String> qualifiedSkillIds(
  Iterable<MemoryReview> input, {
  void Function(Set<String> skills, DateTime at)? onQualified,
}) {
  final reviews = input.where((r) => r.applied).toList()
    ..sort((a, b) {
      final time = a.reviewedAt.compareTo(b.reviewedAt);
      return time != 0 ? time : a.sessionId.compareTo(b.sessionId);
    });
  final first = <String, DateTime>{};
  final qualified = <String>{};
  for (final review in reviews) {
    if (review.rating == 1) {
      first.remove(review.skillId);
      qualified.remove(review.skillId);
    } else if (review.rating >= 2) {
      final previous = first[review.skillId];
      if (previous != null &&
          review.reviewedAt.difference(previous) >= const Duration(hours: 24)) {
        final a = previous.toLocal();
        final b = review.reviewedAt.toLocal();
        if ((a.year != b.year || a.month != b.month || a.day != b.day) &&
            qualified.add(review.skillId)) {
          onQualified?.call(qualified, review.reviewedAt);
        }
      }
      first.putIfAbsent(review.skillId, () => review.reviewedAt);
    }
  }
  return qualified;
}

Set<String> _effectiveCountries(
  Set<String> qualified,
  Set<String> countryIds,
  String topic,
  LearningDifficulty level, {
  bool directOnly = false,
}) {
  final storageTopic = topic == 'flagMap' ? 'flags' : topic;
  return {
    for (final country in countryIds)
      if (LearningDifficulty.values
          .where(
            (candidate) => directOnly
                ? candidate == level
                : candidate.index >= level.index,
          )
          .any(
            (candidate) => qualified.contains(
              '$storageTopic:$country:${difficultyForCategory(topic, candidate)}',
            ),
          ))
        country,
  };
}

/// Medal categories; map-only areas (voivodeships, US states) have just one.
List<String> _topics(Continent area) => area.hasCapitalsAndFlags
    ? const ['map', 'capitals', 'flags', 'flagMap']
    : const ['map'];
