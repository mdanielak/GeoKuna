import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart';
import 'achievements.dart';
import 'auto_level.dart';
import 'capitals.dart';
import 'flags.dart';
import 'memory.dart';
import 'learning_progress.dart';
import '../atlas/catalog.dart';
import '../atlas/continent.dart';
import '../settings/app_preferences.dart';
import 'learning_session.dart';
import 'learning_types.dart';
import 'daily_planner.dart';

export 'learning_session.dart'
    show LearningSession, MemoryOverview, QuestionInsight;

export 'daily_planner.dart'
    show
        DailyMode,
        seriesSize,
        maxRetriesPerSeries,
        retryGapMin,
        retryGapMax,
        confusionThreshold,
        maxContrastsPerSeries,
        extraNewPerRound,
        dailyNewBudget;

class SessionRepository {
  SessionRepository(
    this.db, {
    DateTime Function()? clock,
    this.continent = Continent.europe,
    this.level = LearningDifficulty.normal,
  }) : _clock = clock ?? DateTime.now;
  final Continent continent;
  final LearningDifficulty level;
  final DateTime Function() _clock;
  MemoryStore get _memory => MemoryStore(db);
  DailyPlanner get _planner =>
      DailyPlanner(db, continent: continent, level: level, clock: _clock);
  final AppDatabase db;

  Future<LearningSession> _load(Session row) async {
    final session = await _loadPlain(row);
    if (session.completed || session.currentAttempt == null) return session;
    return LearningSession(
      session.row,
      session.countryIds,
      session.attempts,
      mapGuesses: session.mapGuesses,
      assistedIndices: session.assistedIndices,
      insight: await _insight(session),
    );
  }

  Future<QuestionInsight?> _insight(LearningSession session) async {
    final index = session.index;
    final skill = session.skillIdAt(index);
    final reviews = await (db.select(
      db.memoryReviews,
    )..where((r) => r.skillId.equals(skill) & r.applied.equals(true))).get();
    final hadMiss = reviews.any((r) => r.rating == 1);
    final recovering = recoveringSkills(reviews)[skill];
    final recovery = !hadMiss || !session.isFirstTryCorrectAt(index)
        ? null
        : recovering ?? recoveryTarget;
    String? confused;
    final wrongNow = session.currentMapGuesses
        .where((g) => !g.correct)
        .map((g) => g.selectedCountryId)
        .toSet();
    if (wrongNow.isNotEmpty) {
      final earlier =
          await (db.select(db.mapGuesses)..where(
                (g) =>
                    g.sessionId.equals(session.row.id).not() &
                    g.correct.equals(false) &
                    g.selectedCountryId.isIn(wrongNow),
              ))
              .join([
                innerJoin(
                  db.attempts,
                  db.attempts.sessionId.equalsExp(db.mapGuesses.sessionId) &
                      db.attempts.questionIndex.equalsExp(
                        db.mapGuesses.questionIndex,
                      ) &
                      db.attempts.countryId.equals(session.targetId),
                ),
              ])
              .get();
      confused = earlier.firstOrNull
          ?.readTable(db.mapGuesses)
          .selectedCountryId;
    }
    String? confusedName;
    final attempt = session.currentAttempt!;
    if (session.isFlagAt(index) &&
        !session.isMapAt(index) &&
        !attempt.correct &&
        attempt.answer.isNotEmpty) {
      final wrongFlags =
          await (db.select(db.attempts)..where(
                (a) =>
                    a.sessionId.equals(session.row.id).not() &
                    a.countryId.equals(session.targetId) &
                    a.topic.equals(QuizTopic.flags.name) &
                    a.correct.equals(false),
              ))
              .get();
      final currentNorm = normalizeAnswer(attempt.answer);
      if (wrongFlags.any(
        (a) =>
            !SkillDifficulty.fromDb(a.difficulty).isMap &&
            normalizeAnswer(a.answer) == currentNorm,
      )) {
        confusedName = attempt.answer;
      }
    }
    String? autoNotice;
    if ((level.isAuto || session.isAutoAt(index)) &&
        _origin(session, index) != ReviewOrigin.contrast.name &&
        !(session.isMapAt(index) && session.assistedIndices.contains(index))) {
      final answerTime =
          (session.isMapAt(index) && session.currentMapGuesses.isNotEmpty
                  ? session.currentMapGuesses.first.guessedAt
                  : attempt.answeredAt)
              .toUtc();
      final itemId = autoItemId(
        session.topicAt(index),
        session.targetId,
        session.difficultyNameAt(index),
      );
      final autoRow = await AutoLevelStore(db).find(itemId);
      if (autoRow != null &&
          autoRow.updatedAt.toUtc().isAtSameMomentAs(answerTime)) {
        final rowLevel = AutoLevelStore.parseLevel(autoRow.level);
        if (autoRow.lastTransition == AutoLevelEvent.demoted.name) {
          autoNotice = 'Następnym razem łatwiej.';
        } else if (autoRow.lastTransition == AutoLevelEvent.promoted.name) {
          autoNotice = 'Wracasz do poziomu ${rowLevel.label}.';
        } else if (autoRow.hitStreak == 1 &&
            rowLevel != LearningDifficulty.normal) {
          final nextLevel = rowLevel == LearningDifficulty.veryEasy
              ? LearningDifficulty.easy
              : LearningDifficulty.normal;
          autoNotice =
              'Jeszcze 1 trafienie — wrócisz do poziomu ${nextLevel.label}.';
        }
      }
    }
    if (recovery == null &&
        confused == null &&
        confusedName == null &&
        autoNotice == null) {
      return null;
    }
    return QuestionInsight(
      recovery: recovery,
      confusedWithId: confused,
      confusedWithName: confusedName,
      autoNotice: autoNotice,
    );
  }

  Future<LearningSession> _loadPlain(Session row) async => LearningSession(
    row,
    (jsonDecode(row.countryIds) as List).cast<String>(),
    await (db.select(
      db.attempts,
    )..where((a) => a.sessionId.equals(row.id))).get(),
    assistedIndices:
        (await (db.select(db.memoryReviews)..where(
                  (r) =>
                      r.sessionId.equals(row.id) & r.origin.equals('assisted'),
                ))
                .get())
            .map((r) => r.questionIndex)
            .toSet(),
    mapGuesses:
        await (db.select(db.mapGuesses)
              ..where((g) => g.sessionId.equals(row.id))
              ..orderBy([
                (g) => OrderingTerm.asc(g.questionIndex),
                (g) => OrderingTerm.asc(g.guessIndex),
              ]))
            .get(),
  );

  Future<LearningSession?> active({
    String topic = 'map',
    String? difficulty,
  }) async {
    final rows =
        await (db.select(db.sessions)..where(
              (s) =>
                  s.continent.equals(continent.name) &
                  s.completedAt.isNull() &
                  s.topic.equals(topic) &
                  (difficulty == null
                      ? const Constant(true)
                      : s.difficulty.equals(difficulty)),
            ))
            .get();
    return rows.isEmpty ? null : _load(rows.first);
  }

  Future<List<LearningSession>> _activeByTopic(String topic) async {
    final rows =
        await (db.select(db.sessions)..where(
              (s) =>
                  s.continent.equals(continent.name) &
                  s.completedAt.isNull() &
                  s.topic.equals(topic),
            ))
            .get();
    return Future.wait(rows.map(_load));
  }

  Future<List<LearningSession>> activeCapitals() => _activeByTopic('capitals');

  Future<LearningSession> byId(String id) async {
    final row = await (db.select(
      db.sessions,
    )..where((s) => s.id.equals(id))).getSingle();
    if (row.continent != continent.name) {
      throw StateError('Sesja innego kontynentu');
    }
    return _load(row);
  }

  Future<LearningSession> start(List<String> ids, {Random? random}) =>
      db.transaction(() async {
        final existing = await active(difficulty: mapDifficultyFor(level));
        if (existing != null) return existing;
        final shuffled = await _adaptivePick(
          ids.toSet().toList(),
          'map',
          mapDifficultyFor(level),
          random ?? Random(),
        );
        if (shuffled.isEmpty) throw StateError('Brak państw w katalogu');
        final id = const Uuid().v4();
        await db
            .into(db.sessions)
            .insert(
              SessionsCompanion.insert(
                id: id,
                countryIds: jsonEncode(shuffled.take(seriesSize).toList()),
                difficulty: Value(mapDifficultyFor(level)),
                createdAt: _clock().toUtc(),
                continent: Value(continent.name),
              ),
            );
        return byId(id);
      });

  Future<LearningSession> startCapitals(
    CapitalCatalog catalog,
    CapitalDifficulty difficulty, {
    Random? random,
  }) => db.transaction(() async {
    final existing = await active(
      topic: 'capitals',
      difficulty: difficulty.name,
    );
    if (existing != null) return existing;
    final rng = random ?? Random();
    final ids = await _adaptivePick(
      catalog.facts.map((f) => f.countryId).toList(),
      'capitals',
      difficulty.name,
      rng,
    );
    final questions = catalog.questions(ids, rng);
    final id = const Uuid().v4();
    await db
        .into(db.sessions)
        .insert(
          SessionsCompanion.insert(
            id: id,
            countryIds: jsonEncode(
              questions.map((q) => q.fact.countryId).toList(),
            ),
            createdAt: _clock().toUtc(),
            continent: Value(continent.name),
            topic: const Value('capitals'),
            difficulty: Value(difficulty.name),
            contentVersion: Value(catalog.version),
            questionData: Value(
              jsonEncode(questions.map((q) => q.toJson()).toList()),
            ),
          ),
        );
    return byId(id);
  });

  Future<List<LearningSession>> activeFlags() => _activeByTopic('flags');

  Future<LearningSession> startFlags(
    FlagCatalog catalog,
    FlagDifficulty difficulty, {
    Random? random,
  }) => db.transaction(() async {
    final storedDifficulty = difficulty == FlagDifficulty.map
        ? mapDifficultyFor(level)
        : difficulty.name;
    final existing = await active(topic: 'flags', difficulty: storedDifficulty);
    if (existing != null) return existing;
    final rng = random ?? Random();
    final ids = await _adaptivePick(
      catalog.facts.map((f) => f.countryId).toList(),
      'flags',
      storedDifficulty,
      rng,
    );
    final questions = catalog.questions(ids, rng);
    final id = const Uuid().v4();
    await db
        .into(db.sessions)
        .insert(
          SessionsCompanion.insert(
            id: id,
            countryIds: jsonEncode(questions.map((q) => q.countryId).toList()),
            createdAt: _clock().toUtc(),
            continent: Value(continent.name),
            topic: const Value('flags'),
            difficulty: Value(storedDifficulty),
            contentVersion: Value(catalog.version),
            questionData: Value(
              jsonEncode(questions.map((q) => q.toJson()).toList()),
            ),
          ),
        );
    return byId(id);
  });

  /// Manual training order: due hard skills, other due, then unseen;
  /// well-known countries only fill remaining places, weakest first.
  Future<List<String>> _adaptivePick(
    List<String> ids,
    String topic,
    String difficulty,
    Random random, {
    int count = seriesSize,
  }) async {
    final skillIds = [for (final id in ids) '$topic:$id:$difficulty'];
    final cards = {
      for (final card in await (db.select(
        db.memoryCards,
      )..where((c) => c.id.isIn(skillIds))).get())
        card.countryId: card,
    };
    final recovering = recoveringSkills(
      await (db.select(
        db.memoryReviews,
      )..where((r) => r.applied.equals(true) & r.skillId.isIn(skillIds))).get(),
    );
    final now = _clock().toUtc();
    final scheduler = MemoryScheduler();
    final order = [...ids]..shuffle(random);
    final tieBreak = {for (var i = 0; i < order.length; i++) order[i]: i};
    (int, double) rank(String id) {
      final card = cards[id];
      if (card?.state == null) return (2, 0);
      final due = card!.due != null && !card.due!.isAfter(now);
      final r = scheduler.retrievability(card.state, now);
      if (due && recovering.containsKey(card.id)) return (0, r);
      return (due ? 1 : 3, r);
    }

    order.sort((a, b) {
      final (ta, ra) = rank(a);
      final (tb, rb) = rank(b);
      if (ta != tb) return ta.compareTo(tb);
      if (ra != rb) return ra.compareTo(rb);
      return tieBreak[a]!.compareTo(tieBreak[b]!);
    });
    return order.take(count).toList();
  }

  /// After a first-attempt miss in a daily series, ask the same question
  /// again after 3–5 other questions. The repeat is practice, never graded.
  /// Without room for the gap, the next round or day takes it via FSRS.
  Future<void> _queueRetry(LearningSession session, int index) async {
    // A missed ladder step needs no retry: the real question follows.
    if (!session.isDaily || session.isPracticeAt(index)) {
      return;
    }
    final questions = jsonDecode(session.row.questionData) as List;
    final question = Map<String, dynamic>.of(
      questions[index] as Map<String, dynamic>,
    )..remove('origin');
    final retries = questions.where((q) => (q as Map)['retry'] == true);
    final others = questions.length - index - 1;
    if (others < retryGapMin ||
        retries.length >= maxRetriesPerSeries ||
        retries.any((q) => (q as Map)['skill_id'] == question['skill_id'])) {
      return;
    }
    final at = index + 1 + (others < retryGapMax ? others : retryGapMax);
    final ids = [...session.countryIds]..insert(at, session.targetId);
    await (db.update(
      db.sessions,
    )..where((s) => s.id.equals(session.row.id))).write(
      SessionsCompanion(
        countryIds: Value(jsonEncode(ids)),
        questionData: Value(
          jsonEncode([...questions]..insert(at, question..['retry'] = true)),
        ),
      ),
    );
  }

  String _origin(LearningSession session, int index, {bool assisted = false}) =>
      assisted
      ? ReviewOrigin.assisted.name
      : session.isRetryAt(index)
      ? ReviewOrigin.retry.name
      : session.originAt(index) ??
            (session.isDaily
                ? ReviewOrigin.daily.name
                : ReviewOrigin.manual.name);

  /// [gaveUp]: „Nie wiem, pomóż” — a graded error with an empty answer.
  Future<LearningSession> answerFlag(
    String id,
    int index,
    String input, {
    bool gaveUp = false,
  }) => _answerTextQuestion(
    id,
    index,
    input,
    topic: QuizTopic.flags,
    gaveUp: gaveUp,
  );

  Future<LearningSession> _answerTextQuestion(
    String id,
    int index,
    String input, {
    required QuizTopic topic,
    required bool gaveUp,
  }) => db.transaction(() async {
    final session = await byId(id);
    final isFlag = topic == QuizTopic.flags;
    if (session.completed ||
        session.index != index ||
        (isFlag
            ? (!session.isFlagAt(index) || session.isMapAt(index))
            : !session.isCapital)) {
      throw StateError(
        isFlag
            ? 'Nieaktualne pytanie o flagę'
            : 'Nieaktualne pytanie o stolicę',
      );
    }
    if (session.currentAttempt != null) return session;
    final String difficultyName;
    final bool isChoice;
    final bool isFirstLetter;
    final List<String> options;
    final String firstLetter;
    final String canonicalAnswer;
    final AnswerEvaluation Function(String candidate) evaluate;
    if (isFlag) {
      final q = session.flagQuestionAt(index);
      final d = session.flagDifficulty;
      difficultyName = d.name;
      isChoice = d == FlagDifficulty.choice;
      isFirstLetter = d == FlagDifficulty.firstLetter;
      options = q.options;
      firstLetter = q.firstLetter;
      canonicalAnswer = q.countryName;
      evaluate = (c) => evaluateFlagAnswer(c, q);
    } else {
      final q = session.capitalQuestion;
      final d = session.difficulty;
      difficultyName = d.name;
      isChoice = d == CapitalDifficulty.choice;
      isFirstLetter = d == CapitalDifficulty.firstLetter;
      options = q.options;
      firstLetter = q.fact.firstLetter;
      canonicalAnswer = q.fact.name;
      evaluate = (c) => evaluateCapitalAnswer(c, q.fact);
    }
    if (gaveUp && isChoice) throw ArgumentError('A–D nie ma podpowiedzi');
    if (!gaveUp && (input.trim().isEmpty || input.length > 100)) {
      throw ArgumentError('Pusta lub zbyt długa odpowiedź');
    }
    if (isChoice && !options.contains(input)) {
      throw ArgumentError('Odpowiedź spoza listy');
    }
    final (String answer, AnswerEvaluation evaluation) = gaveUp
        ? ('', const AnswerEvaluation(false))
        : isFirstLetter
        ? resolveFirstLetterAnswer(firstLetter, input, evaluate)
        : isChoice
        ? (input.trim(), AnswerEvaluation(input.trim() == canonicalAnswer))
        : (input.trim(), evaluate(input.trim()));
    await _memory.importHistoryOnce();
    final activityTime = _clock();
    final answeredAt = activityTime.toUtc();
    await db
        .into(db.attempts)
        .insert(
          AttemptsCompanion.insert(
            sessionId: id,
            questionIndex: index,
            countryId: session.targetId,
            answer: answer,
            correct: evaluation.correct,
            typoAccepted: Value(evaluation.typoAccepted),
            answeredAt: answeredAt,
            topic: Value(topic.name),
            difficulty: Value(difficultyName),
          ),
        );
    final answered = await byId(id);
    await _memory.record(
      activityTime: activityTime,
      answered.currentAttempt!,
      origin: _origin(session, index),
    );
    if ((level.isAuto || session.isAutoAt(index)) &&
        _origin(session, index) != ReviewOrigin.contrast.name) {
      await AutoLevelStore(db).recordAnswer(
        topic: topic.name,
        countryId: session.targetId,
        difficulty: difficultyName,
        correct: evaluation.correct,
        now: answeredAt,
      );
    }
    if (!evaluation.correct) await _queueRetry(session, index);
    return byId(id);
  });

  Future<LearningSession> guessMap(
    String id,
    int index,
    String selected,
    Set<String> allowed, {
    required int expectedGuessIndex,
    bool assisted = false,
  }) => db.transaction(() async {
    final session = await byId(id);
    if (session.completed ||
        session.index != index ||
        !session.isMapAt(index)) {
      throw StateError('Nieaktualne pytanie mapowe');
    }
    if (session.currentAttempt != null) return session;
    final guesses = session.currentMapGuesses;
    if (expectedGuessIndex < guesses.length) return session;
    if (expectedGuessIndex != guesses.length || guesses.length >= 3) {
      throw StateError('Nieaktualna próba');
    }
    if (!allowed.contains(selected)) throw ArgumentError('Nieznane państwo');
    if (guesses.any((g) => g.selectedCountryId == selected)) return session;
    await _memory.importHistoryOnce();
    final activityTime = _clock();
    final now = activityTime.toUtc();
    final withHelp = assisted || guesses.any((g) => g.assisted);
    final correct = selected == session.targetId;
    await db
        .into(db.mapGuesses)
        .insert(
          MapGuessesCompanion.insert(
            sessionId: id,
            questionIndex: index,
            guessIndex: guesses.length,
            selectedCountryId: selected,
            correct: correct,
            assisted: Value(withHelp),
            guessedAt: now,
          ),
        );
    if (guesses.isEmpty) {
      await _memory.record(
        activityTime: activityTime,
        Attempt(
          sessionId: id,
          questionIndex: index,
          countryId: session.targetId,
          answer: selected,
          correct: correct,
          answeredAt: now,
          typoAccepted: false,
          topic: session.topicAt(index),
          difficulty: session.difficultyNameAt(index),
        ),
        origin: _origin(session, index, assisted: withHelp),
      );
      if (!withHelp &&
          (level.isAuto || session.isAutoAt(index)) &&
          _origin(session, index) != ReviewOrigin.contrast.name) {
        await AutoLevelStore(db).recordAnswer(
          topic: session.topicAt(index),
          countryId: session.targetId,
          difficulty: session.difficultyNameAt(index),
          correct: correct,
          now: now,
        );
      }
      if (!correct && !withHelp) await _queueRetry(session, index);
    }
    if (correct || guesses.length == 2) {
      await _completeMapQuestion(session, selected, correct, now);
    }
    return byId(id);
  });

  Future<void> _completeMapQuestion(
    LearningSession session,
    String answer,
    bool correct,
    DateTime time,
  ) => db
      .into(db.attempts)
      .insert(
        AttemptsCompanion.insert(
          sessionId: session.row.id,
          questionIndex: session.index,
          countryId: session.targetId,
          answer: answer,
          correct: correct,
          answeredAt: time,
          topic: Value(session.topicAt(session.index)),
          difficulty: Value(session.difficultyNameAt(session.index)),
        ),
      );

  /// [gaveUp]: „Nie wiem, pomóż” — a graded error with an empty answer.
  Future<LearningSession> answerCapital(
    String id,
    int index,
    String input, {
    bool gaveUp = false,
  }) => _answerTextQuestion(
    id,
    index,
    input,
    topic: QuizTopic.capitals,
    gaveUp: gaveUp,
  );

  Future<LearningSession> finish(String id) => db.transaction(() async {
    final session = await byId(id);
    if (session.completed) return session;
    if (session.currentAttempt == null &&
        session.currentMapGuesses.isNotEmpty) {
      final last = session.currentMapGuesses.last;
      await _completeMapQuestion(
        session,
        last.selectedCountryId,
        last.correct,
        last.guessedAt,
      );
    }
    await (db.update(db.sessions)..where((s) => s.id.equals(id))).write(
      SessionsCompanion(completedAt: Value(_clock().toUtc())),
    );
    return byId(id);
  });

  Future<LearningSession> advance(String id, int expectedIndex) =>
      db.transaction(() async {
        final session = await byId(id);
        if (session.completed || session.index != expectedIndex) return session;
        if (session.currentAttempt == null) {
          throw StateError('Najpierw odpowiedz');
        }
        final last = session.index == session.countryIds.length - 1;
        await (db.update(db.sessions)..where((s) => s.id.equals(id))).write(
          SessionsCompanion(
            currentIndex: Value(last ? session.index : session.index + 1),
            completedAt: Value(last ? _clock().toUtc() : null),
          ),
        );
        return byId(id);
      });

  Future<List<LearningProgressEntry>> learningProgress(
    AreaCatalog catalog, {
    FlagCatalog? flags,
  }) async {
    await _memory.importHistoryOnce();
    final countryIds = catalog.countries.map((c) => c.id).toList();
    final cards = countryIds.isEmpty
        ? const <String, MemoryCard>{}
        : {
            for (final card in await (db.select(
              db.memoryCards,
            )..where((c) => c.countryId.isIn(countryIds))).get())
              card.id: card,
          };
    final logs = cards.isEmpty
        ? const <MemoryReview>[]
        : await (db.select(db.memoryReviews)
                ..where(
                  (r) => r.applied.equals(true) & r.skillId.isIn(cards.keys),
                )
                ..orderBy([(r) => OrderingTerm.asc(r.reviewedAt)]))
              .get();
    final latest = <String, MemoryReview>{};
    for (final log in logs) {
      latest[log.skillId] = log;
    }
    final recovering = analyzeRecovery(logs).recovering;
    final qualified = qualifiedSkillIds(logs);
    final now = _clock().toUtc();
    return [
      for (final country in catalog.countries)
        for (final spec in [
          for (final difficulty in mapDifficulties) ('map', difficulty),
          ('capitals', 'choice'),
          ('capitals', 'firstLetter'),
          ('capitals', 'write'),
          if (flags != null) ...[
            ('flags', 'choice'),
            ('flags', 'firstLetter'),
            ('flags', 'write'),
            for (final difficulty in mapDifficulties) ('flags', difficulty),
          ],
        ])
          (() {
            final (topic, difficulty) = spec;
            final id = '$topic:${country.id}:$difficulty';
            final card = cards[id];
            final log = latest[id];
            final status = card?.state == null || log == null
                ? LearningProgressStatus.insufficient
                : log.rating == 1 ||
                      (card!.due != null && !card.due!.isAfter(now))
                ? LearningProgressStatus.review
                : LearningProgressStatus.practising;
            return LearningProgressEntry(
              id: id,
              country: country,
              topic: topic,
              difficulty: difficulty,
              status: status,
              reviewCount: card?.reviewCount ?? 0,
              due: card?.due,
              lastReview: log?.reviewedAt,
              qualified: qualified.contains(id),
              recoveryProgress: recovering[id],
            );
          })(),
    ];
  }

  /// No series (any topic or level) was ever started in this area: Today
  /// then offers the placement quiz as its main action.
  Future<bool> firstVisit() async =>
      await (db.select(db.sessions)
            ..where((s) => s.continent.equals(continent.name))
            ..limit(1))
          .getSingleOrNull() ==
      null;

  Future<MemoryOverview> memoryOverview(
    Catalog catalog,
    CapitalCatalog capitals, {
    FlagCatalog? flags,
  }) => db.transaction(() async {
    final plan = await _planner.plan(catalog, capitals, flags: flags);
    return MemoryOverview(
      dueCount: plan.dueCount,
      newAvailable: plan.newAvailable,
      newRemainingToday: plan.newRemainingToday,
      reviewedToday: plan.reviewedToday,
      nextDue: plan.nextDue,
      plannedCount: plan.cards.length,
      plannedNewCount: plan.cards.where((c) => c.state == null).length,
      activeSession: await active(topic: 'daily'),
      reservedNewElsewhere: plan.reservedNewElsewhere,
      otherDueCount: plan.otherDueCount,
      learnedCount: plan.learnedCount,
      firstVisit: await firstVisit(),
    );
  });

  Future<LearningSession?> startDaily(
    Catalog catalog,
    CapitalCatalog capitals, {
    FlagCatalog? flags,
    DailyMode mode = DailyMode.regular,
  }) => db.transaction(() async {
    final existing = await active(topic: 'daily');
    if (existing != null) return existing;
    final plan = await _planner.plan(
      catalog,
      capitals,
      flags: flags,
      mode: mode,
    );
    if (plan.cards.isEmpty) return null;
    final questions = plan.cards
        .map(
          (c) => <String, dynamic>{
            if (c.topic == 'capitals')
              ...capitals.questions([c.countryId], Random()).single.toJson(),
            if (c.topic == 'flags')
              ...flags!.questions([c.countryId], Random()).single.toJson(),
            'topic': c.topic,
            'difficulty': c.difficulty,
            'skill_id': c.id,
            'country_id': c.countryId,
            if (level.isAuto) 'auto': true,
            if (plan.easierCardIds.contains(c.id)) 'auto_easier': true,
            if (plan.origins[c.id] != null) 'origin': plan.origins[c.id],
          },
        )
        .toList();
    addContrasts(questions, await _planner.confusions(catalog, flags), flags);
    final id = const Uuid().v4();
    await db
        .into(db.sessions)
        .insert(
          SessionsCompanion.insert(
            id: id,
            countryIds: jsonEncode(
              questions.map((q) => q['country_id'] as String).toList(),
            ),
            createdAt: _clock().toUtc(),
            continent: Value(continent.name),
            topic: const Value('daily'),
            difficulty: const Value('mixed'),
            questionData: Value(jsonEncode(questions)),
            contentVersion: Value(
              'memory-0.5.0|${continent.name}|${capitals.version}|${flags?.version ?? ''}',
            ),
          ),
        );
    return byId(id);
  });

  Future<List<Attempt>> history() async {
    final sessions = await (db.select(
      db.sessions,
    )..where((s) => s.continent.equals(continent.name))).get();
    final ids = sessions.map((s) => s.id).toList();
    return (db.select(db.attempts)
          ..where((a) => a.sessionId.isIn(ids))
          ..orderBy([(a) => OrderingTerm.desc(a.answeredAt)]))
        .get();
  }
}
