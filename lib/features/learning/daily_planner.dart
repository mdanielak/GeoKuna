import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../../core/database/database.dart';
import '../atlas/catalog.dart';
import '../atlas/continent.dart';
import '../settings/app_preferences.dart';
import 'achievements.dart';
import 'capitals.dart';
import 'flags.dart';
import 'learning_levels.dart';
import 'learning_types.dart';
import 'memory.dart';

/// Questions in one series; a series is shorter when nothing useful is left.
const seriesSize = 10;

/// Missed questions repeated later in one daily series.
const maxRetriesPerSeries = 3;

/// A repeat comes after this many other questions (3–5), never right away.
const retryGapMin = 3, retryGapMax = 5;

/// At most this many ladder steps per series, so it stays a review.
const maxScaffoldsPerSeries = 2;

/// A pair counts as confused after this many misses naming the same partner.
const confusionThreshold = 2;

/// At most this many contrast questions (ladder step 2) per series.
const maxContrastsPerSeries = 2;

/// New cards an extra round may introduce beyond the daily budget.
const extraNewPerRound = 3;

/// Daily new-card budget shared by all continents and levels.
const dailyNewBudget = 3;

enum DailyMode {
  /// Today's expedition: due reviews, then the new-card budget.
  regular,

  /// Another round the same day: due, a few new, then weakest known facts.
  extra,

  /// "Kuna checks what you know": unseen facts; hits do not use the budget.
  placement,
}

/// Chooses what Today asks: due FSRS cards, the new-card budget, extra and
/// placement rounds, and which hard skills get the easier ladder steps.
/// Reads the database (and adds cards a content update introduced); the
/// session itself is written by [SessionRepository.startDaily].
class DailyPlanner {
  DailyPlanner(
    this.db, {
    required this.continent,
    required this.level,
    required this.clock,
  });
  final AppDatabase db;
  final Continent continent;
  final LearningDifficulty level;
  final DateTime Function() clock;

  Future<DailyPlan> plan(
    Catalog catalog,
    CapitalCatalog capitals, {
    FlagCatalog? flags,
    DailyMode mode = DailyMode.regular,
  }) async {
    await MemoryStore(db).importHistoryOnce();
    final wanted = <MemoryCardsCompanion>[
      for (final country in catalog.countries) ...[
        for (final difficulty in mapDifficulties)
          MemoryCardsCompanion.insert(
            id: 'map:${country.id}:$difficulty',
            countryId: country.id,
            topic: 'map',
            difficulty: difficulty,
          ),
        if (capitals.facts.any((f) => f.countryId == country.id))
          for (final mode in CapitalDifficulty.values)
            MemoryCardsCompanion.insert(
              id: 'capitals:${country.id}:${mode.name}',
              countryId: country.id,
              topic: 'capitals',
              difficulty: mode.name,
            ),
      ],
      if (flags != null)
        for (final fact in flags.facts)
          for (final difficulty in [
            ...FlagDifficulty.values.map((m) => m.name),
            'mapEasy',
            'mapVeryEasy',
          ])
            MemoryCardsCompanion.insert(
              id: 'flags:${fact.countryId}:$difficulty',
              countryId: fact.countryId,
              topic: 'flags',
              difficulty: difficulty,
            ),
    ];
    // Cards exist after the first visit; insert only what a content update
    // added instead of rewriting hundreds of rows on every Today view.
    final existing =
        (await (db.selectOnly(db.memoryCards)..addColumns([db.memoryCards.id]))
                .map((r) => r.read(db.memoryCards.id)!)
                .get())
            .toSet();
    final missing = wanted
        .where((c) => !existing.contains(c.id.value))
        .toList();
    if (missing.isNotEmpty) {
      await db.batch(
        (batch) => batch.insertAll(
          db.memoryCards,
          missing,
          mode: InsertMode.insertOrIgnore,
        ),
      );
    }
    final now = clock();
    final start = DateTime(now.year, now.month, now.day).toUtc();
    final end = DateTime(now.year, now.month, now.day + 1).toUtc();
    final reviews =
        await (db.select(db.memoryReviews)..where(
              (r) =>
                  r.reviewedAt.isBiggerOrEqualValue(start) &
                  r.reviewedAt.isSmallerThanValue(end),
            ))
            .get();
    final allCards = await db.select(db.memoryCards).get();
    final freshIds = allCards
        .where((c) => c.state == null)
        .map((c) => c.id)
        .toSet();
    final elsewhere =
        await (db.select(db.sessions)..where(
              (s) =>
                  s.completedAt.isNull() &
                  s.topic.equals('daily') &
                  s.continent.equals(continent.name).not(),
            ))
            .get();
    final elsewhereIds = elsewhere.map((s) => s.id).toList();
    final answeredElsewhere =
        (await (db.select(
              db.memoryReviews,
            )..where((r) => r.sessionId.isIn(elsewhereIds))).get())
            .map((r) => '${r.sessionId}:${r.questionIndex}')
            .toSet();
    final reserved = <String>{};
    for (final session in elsewhere) {
      final questions = jsonDecode(session.questionData) as List;
      for (
        var index = session.currentIndex;
        index < questions.length;
        index++
      ) {
        if (answeredElsewhere.contains('${session.id}:$index')) continue;
        final skill = (questions[index] as Map<String, dynamic>)['skill_id'];
        if (skill is String && freshIds.contains(skill)) reserved.add(skill);
      }
    }
    // Facts already known in the knowledge check do not use the budget.
    final budget = max(
      0,
      dailyNewBudget -
          reviews
              .where(
                (r) =>
                    r.wasNew &&
                    (r.origin == 'daily' ||
                        (r.origin == 'placement' && r.rating == 1)),
              )
              .length -
          reserved.length,
    );
    final known = catalog.countries.map((c) => c.id).toSet();
    final appliedReviews =
        await (db.select(db.memoryReviews)..where(
              (r) =>
                  r.applied.equals(true) &
                  r.skillId.isIn(
                    allCards
                        .where((c) => known.contains(c.countryId))
                        .map((c) => c.id),
                  ),
            ))
            .get();
    final qualified = qualifiedSkillIds(appliedReviews);
    final recovering = recoveringSkills(appliedReviews);
    final misses = missesSinceRecovery(appliedReviews);
    final lastReviewed = <String, DateTime>{};
    for (final review in appliedReviews) {
      final last = lastReviewed[review.skillId];
      if (last == null || review.reviewedAt.isAfter(last)) {
        lastReviewed[review.skillId] = review.reviewedAt;
      }
    }
    final scheduler = MemoryScheduler();
    // Hard skills first, then the ones most likely to be forgotten.
    double priority(MemoryCard card) => recovering.containsKey(card.id)
        ? -1
        : scheduler.retrievability(card.state, now);
    bool coveredByStronger(MemoryCard card) {
      final category =
          card.topic == 'flags' && mapDifficulties.contains(card.difficulty)
          ? 'flagMap'
          : card.topic;
      return LearningDifficulty.values
          .where((candidate) => candidate.index > level.index)
          .any(
            (candidate) => qualified.contains(
              '${card.topic}:${card.countryId}:${difficultyForCategory(category, candidate)}',
            ),
          );
    }

    final cards = allCards
        .where(
          (c) =>
              known.contains(c.countryId) &&
              (c.topic != 'flags' || flags != null) &&
              levelForDifficulty(c.difficulty) == level,
        )
        .toList();
    final due =
        cards
            .where(
              (c) =>
                  c.state != null &&
                  c.due != null &&
                  !c.due!.isAfter(now.toUtc()),
            )
            .toList()
          ..sort((a, b) {
            final risk = priority(a).compareTo(priority(b));
            if (risk != 0) return risk;
            final date = a.due!.compareTo(b.due!);
            return date == 0 ? a.id.compareTo(b.id) : date;
          });
    final fresh =
        cards
            .where(
              (c) =>
                  c.state == null &&
                  !reserved.contains(c.id) &&
                  !coveredByStronger(c),
            )
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    fresh.shuffle(Random(now.year * 10000 + now.month * 100 + now.day));
    final selected = <MemoryCard>[];
    final origins = <String, String>{};
    final countries = <String>{};
    // One country per series, so questions never hint at each other.
    void take(Iterable<MemoryCard> pool, int limit, [String? origin]) {
      var added = 0;
      for (final card in pool) {
        if (selected.length == seriesSize || added >= limit) break;
        if (countries.add(card.countryId)) {
          selected.add(card);
          added++;
          if (origin != null) origins[card.id] = origin;
        }
      }
    }

    switch (mode) {
      case DailyMode.regular:
        // A large backlog still lets one new fact in, so learning never stalls.
        final backlog = due.length >= seriesSize;
        final newSlots = backlog ? (budget > 0 ? 1 : 0) : budget;
        take(due, seriesSize - (backlog ? newSlots : 0));
        take(fresh, newSlots);
      case DailyMode.extra:
        // Known facts are checked weakest first, at most once a day each.
        final control =
            cards
                .where(
                  (c) =>
                      c.state != null &&
                      c.due != null &&
                      c.due!.isAfter(now.toUtc()) &&
                      !recovering.containsKey(c.id) &&
                      (lastReviewed[c.id] == null ||
                          now.toUtc().difference(lastReviewed[c.id]!) >=
                              const Duration(hours: 20)),
                )
                .toList()
              ..sort((a, b) => priority(a).compareTo(priority(b)));
        take(due, seriesSize);
        take(fresh, extraNewPerRound);
        take(control, seriesSize, ReviewOrigin.control.name);
      case DailyMode.placement:
        take(fresh, seriesSize, ReviewOrigin.placement.name);
    }
    final future =
        cards
            .where(
              (c) =>
                  c.state != null &&
                  c.due != null &&
                  c.due!.isAfter(now.toUtc()),
            )
            .map((c) => c.due!)
            .toList()
          ..sort();
    // Stubborn due skills get an easier step first (see startDaily).
    final struggling = {
      for (final card in selected)
        if (card.state != null &&
            (misses[card.id] ?? 0) >= scaffoldAfterMisses &&
            scaffoldDifficulty(card.topic, card.difficulty) != null)
          card.id,
    };
    return DailyPlan(
      selected,
      origins,
      due.length,
      fresh.length,
      budget,
      reviews.where((r) => r.applied).length,
      future.firstOrNull,
      reserved.length,
      allCards
          .where(
            (c) =>
                known.contains(c.countryId) &&
                levelForDifficulty(c.difficulty) != level &&
                c.state != null &&
                c.due != null &&
                !c.due!.isAfter(now.toUtc()),
          )
          .length,
      cards.where((c) => c.state != null).length,
      struggling,
    );
  }

  /// Target country → the country most often given instead of it, once the
  /// same wrong answer happened [confusionThreshold] times since the last
  /// full recovery (3 consecutive graded hits). Map guesses and flag names
  /// are reliable; a typed capital does not name a country.
  Future<Map<String, String>> confusions(
    Catalog catalog,
    FlagCatalog? flags,
  ) async {
    final known = catalog.countries.map((c) => c.id).toSet();
    final appliedReviews =
        await (db.select(db.memoryReviews)
              ..where((r) => r.applied.equals(true))
              ..orderBy([(r) => OrderingTerm.asc(r.reviewedAt)]))
            .get();
    final lastRecoveredAt = <(String, String), DateTime>{};
    final hadMiss = <String, bool>{};
    final hitRun = <String, int>{};
    for (final review in appliedReviews) {
      final parts = review.skillId.split(':');
      if (parts.length != 3 || !known.contains(parts[1])) continue;
      if (review.rating == 1) {
        hadMiss[review.skillId] = true;
        hitRun[review.skillId] = 0;
      } else if (hadMiss[review.skillId] == true) {
        final nextRun = (hitRun[review.skillId] ?? 0) + 1;
        hitRun[review.skillId] = nextRun;
        if (nextRun >= recoveryTarget) {
          final key = (parts[0], parts[1]);
          final prev = lastRecoveredAt[key];
          if (prev == null || review.reviewedAt.isAfter(prev)) {
            lastRecoveredAt[key] = review.reviewedAt;
          }
          hadMiss[review.skillId] = false;
          hitRun[review.skillId] = 0;
        }
      }
    }
    final practiceKeys = {
      for (final r
          in await (db.select(db.memoryReviews)..where(
                (r) => r.origin.isIn([
                  ReviewOrigin.retry.name,
                  ReviewOrigin.scaffold.name,
                  ReviewOrigin.contrast.name,
                  ReviewOrigin.assisted.name,
                ]),
              ))
              .get())
        (r.sessionId, r.questionIndex),
    };
    final counts = <(String, String), int>{};
    void add(String target, String partner) {
      if (target == partner ||
          !known.contains(target) ||
          !known.contains(partner)) {
        return;
      }
      counts.update((target, partner), (n) => n + 1, ifAbsent: () => 1);
    }

    final guesses = await (db.select(db.mapGuesses).join([
      innerJoin(
        db.attempts,
        db.attempts.sessionId.equalsExp(db.mapGuesses.sessionId) &
            db.attempts.questionIndex.equalsExp(db.mapGuesses.questionIndex),
      ),
    ])..where(db.mapGuesses.correct.equals(false))).get();
    for (final row in guesses) {
      final attempt = row.readTable(db.attempts);
      final guess = row.readTable(db.mapGuesses);
      if (practiceKeys.contains((attempt.sessionId, attempt.questionIndex))) {
        continue;
      }
      final recovered = lastRecoveredAt[(attempt.topic, attempt.countryId)];
      if (recovered != null && !guess.guessedAt.isAfter(recovered)) continue;
      add(attempt.countryId, guess.selectedCountryId);
    }
    if (flags != null) {
      final byName = {
        for (final fact in flags.facts)
          for (final name in [fact.countryName, ...fact.aliases])
            normalizeAnswer(name): fact.countryId,
      };
      final wrong = await (db.select(
        db.attempts,
      )..where((a) => a.topic.equals('flags') & a.correct.equals(false))).get();
      for (final attempt in wrong) {
        if (SkillDifficulty.fromDb(attempt.difficulty).isMap ||
            attempt.answer.isEmpty) {
          continue;
        }
        if (practiceKeys.contains((attempt.sessionId, attempt.questionIndex))) {
          continue;
        }
        final recovered = lastRecoveredAt[('flags', attempt.countryId)];
        if (recovered != null && !attempt.answeredAt.isAfter(recovered)) {
          continue;
        }
        final partner = byName[normalizeAnswer(attempt.answer)];
        if (partner != null) add(attempt.countryId, partner);
      }
    }
    final best = <String, (String, int)>{};
    for (final MapEntry(key: (target, partner), :value) in counts.entries) {
      if (value >= confusionThreshold && value > (best[target]?.$2 ?? 0)) {
        best[target] = (partner, value);
      }
    }
    return {for (final e in best.entries) e.key: e.value.$1};
  }
}

/// Ladder: a stubborn skill is first asked in an easier format (A–D or a
/// zoomed map) as unscored practice; its real question moves a few places
/// later, so recall follows the reminder without being a copy of it.
void addScaffolds(
  List<Map<String, dynamic>> questions,
  Set<String> struggling,
) {
  var added = 0;
  for (final skill in struggling) {
    if (added == maxScaffoldsPerSeries) break;
    final at = questions.indexWhere((q) => q['skill_id'] == skill);
    final others = questions.length - at - 1;
    if (at < 0 || others < 2) continue;
    final original = questions.removeAt(at);
    final topic = original['topic'] as String;
    final easier = scaffoldDifficulty(topic, original['difficulty'] as String)!;
    questions.insert(at, {
      ...original,
      'difficulty': easier,
      'skill_id': '$topic:${original['country_id']}:$easier',
      'origin': 'scaffold',
    });
    final gap = others < retryGapMin ? others : retryGapMin;
    questions.insert(at + 1 + gap, original);
    added++;
  }
}

/// Ladder step 2: right after a graded question about a confused country,
/// its usual partner follows in the same format as practice, so the two
/// are compared side by side. In A–D the partner is always an option.
void addContrasts(
  List<Map<String, dynamic>> questions,
  Map<String, String> confusions,
  FlagCatalog? flags,
) {
  var added = 0;
  for (var i = 0; i < questions.length; i++) {
    if (added == maxContrastsPerSeries) break;
    final question = questions[i];
    final topic = question['topic'] as String;
    final partner = confusions[question['country_id']];
    if (partner == null ||
        topic == 'capitals' ||
        (topic == 'flags' && flags == null) ||
        question['retry'] == true ||
        questions.any((q) => q['country_id'] == partner)) {
      continue;
    }
    final partnerName = flags?.facts
        .where((f) => f.countryId == partner)
        .firstOrNull
        ?.countryName;
    final options = question['options'];
    if (topic == 'flags' &&
        options is List &&
        partnerName != null &&
        !options.contains(partnerName)) {
      // Keep the answer, swap one distractor for the confused partner.
      final answer = question['country_name'];
      final slot = options.indexWhere((o) => o != answer);
      if (slot >= 0) options[slot] = partnerName;
    }
    if (question['origin'] == ReviewOrigin.scaffold.name) continue;
    final difficulty = question['difficulty'] as String;
    final Map<String, dynamic> contrastData;
    if (topic == 'flags') {
      final partnerQuestion = flags!.questions([partner], Random()).single;
      final partnerOptions = [...partnerQuestion.options];
      final targetName = question['country_name'] as String?;
      if (difficulty == SkillDifficulty.choice.name &&
          targetName != null &&
          !partnerOptions.contains(targetName)) {
        final slot = partnerOptions.indexWhere(
          (o) => o != partnerQuestion.countryName,
        );
        if (slot >= 0) partnerOptions[slot] = targetName;
      }
      contrastData = {...partnerQuestion.toJson(), 'options': partnerOptions};
    } else {
      contrastData = const {};
    }
    questions.insert(i + 1, {
      ...contrastData,
      'topic': topic,
      'difficulty': difficulty,
      'skill_id': '$topic:$partner:$difficulty',
      'country_id': partner,
      'origin': ReviewOrigin.contrast.name,
    });
    added++;
    i++;
  }
}

/// Today's series before it becomes a session, plus the counts Today shows.
class DailyPlan {
  const DailyPlan(
    this.cards,
    this.origins,
    this.dueCount,
    this.newAvailable,
    this.newRemainingToday,
    this.reviewedToday,
    this.nextDue,
    this.reservedNewElsewhere,
    this.otherDueCount,
    this.learnedCount,
    this.struggling,
  );
  final List<MemoryCard> cards;

  /// Selected skills missed [scaffoldAfterMisses]+ times since recovery.
  final Set<String> struggling;
  final Map<String, String> origins;
  final int dueCount,
      newAvailable,
      newRemainingToday,
      reviewedToday,
      reservedNewElsewhere,
      otherDueCount,
      learnedCount;
  final DateTime? nextDue;
}
