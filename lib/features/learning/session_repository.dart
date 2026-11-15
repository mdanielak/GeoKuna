import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart';
import 'capitals.dart';
import 'flags.dart';
import 'memory.dart';
import 'achievements.dart';
import 'learning_progress.dart';
import '../atlas/catalog.dart';
import '../atlas/continent.dart';
import '../settings/app_preferences.dart';
import 'learning_levels.dart';

class LearningSession {
  const LearningSession(
    this.row,
    this.countryIds,
    this.attempts, {
    Set<int> assistedIndices = const {},
    this.mapGuesses = const [],
    this.insight,
    // Preserve the public argument while exposing combined assistance evidence.
    // ignore: prefer_initializing_formals
  }) : _assistedIndices = assistedIndices;
  final Set<int> _assistedIndices;
  final List<MapGuess> mapGuesses;
  final QuestionInsight? insight;
  Set<int> get assistedIndices => {
    ..._assistedIndices,
    ...mapGuesses.where((g) => g.assisted).map((g) => g.questionIndex),
  };
  List<MapGuess> get currentMapGuesses =>
      mapGuesses.where((g) => g.questionIndex == index).toList();
  final Session row;
  final List<String> countryIds;
  final List<Attempt> attempts;
  bool get completed => row.completedAt != null;
  int get index => row.currentIndex;
  bool get isDaily => row.topic == 'daily';
  String topicAt(int i) =>
      isDaily ? _questions[i]['topic'] as String : row.topic;
  String difficultyNameAt(int i) =>
      isDaily ? _questions[i]['difficulty'] as String : row.difficulty;
  bool isFlagAt(int i) => topicAt(i) == 'flags';
  bool isMapAt(int i) =>
      topicAt(i) == 'map' ||
      (isFlagAt(i) && mapDifficulties.contains(difficultyNameAt(i)));
  FlagDifficulty get flagDifficulty => isMapAt(index)
      ? FlagDifficulty.map
      : FlagDifficulty.values.byName(difficultyNameAt(index));
  FlagQuestion flagQuestionAt(int i) =>
      FlagQuestion.fromJson(_questions[i] as Map<String, dynamic>);
  List<dynamic> get _questions => jsonDecode(row.questionData) as List;
  bool isCapitalAt(int i) =>
      isDaily ? _questions[i]['topic'] == 'capitals' : row.topic == 'capitals';
  bool get isCapital => isCapitalAt(index);
  CapitalDifficulty difficultyAt(int i) => CapitalDifficulty.values.byName(
    isDaily ? _questions[i]['difficulty'] as String : row.difficulty,
  );
  CapitalQuestion capitalQuestionAt(int i) =>
      CapitalQuestion.fromJson(_questions[i] as Map<String, dynamic>);
  CapitalDifficulty get difficulty => difficultyAt(index);
  List<CapitalQuestion> get capitalQuestions =>
      (jsonDecode(row.questionData) as List)
          .map((q) => CapitalQuestion.fromJson(q as Map<String, dynamic>))
          .toList();
  CapitalQuestion get capitalQuestion => capitalQuestionAt(index);
  String get targetId => countryIds[index];
  Attempt? get currentAttempt {
    for (final attempt in attempts) {
      if (attempt.questionIndex == index) return attempt;
    }
    return null;
  }

  /// A repeat of a missed question later in the same daily series.
  bool isRetryAt(int i) =>
      isDaily && i < _questions.length && _questions[i]['retry'] == true;

  /// An easier, unscored ladder step before a stubborn skill's real question.
  bool isScaffoldAt(int i) => originAt(i) == 'scaffold';

  /// The country a stubborn skill keeps being confused with, asked right
  /// after it as unscored practice (ladder step 2).
  bool isContrastAt(int i) => originAt(i) == 'contrast';

  /// Practice inside a daily series: never scored and never an FSRS grade.
  bool isPracticeAt(int i) =>
      isRetryAt(i) || isScaffoldAt(i) || isContrastAt(i);

  /// Special origin stored in the daily snapshot (`control`, `placement`,
  /// `scaffold`).
  String? originAt(int i) => isDaily && i < _questions.length
      ? _questions[i]['origin'] as String?
      : null;
  String skillIdAt(int i) =>
      '${topicAt(i)}:${countryIds[i]}:${difficultyNameAt(i)}';
  List<Attempt> get scoredAttempts => attempts
      .where(
        (a) =>
            !assistedIndices.contains(a.questionIndex) &&
            !isPracticeAt(a.questionIndex),
      )
      .toList();
  int get correctCount => scoredAttempts.where((attempt) {
    final first = mapGuesses
        .where(
          (g) => g.questionIndex == attempt.questionIndex && g.guessIndex == 0,
        )
        .firstOrNull;
    return first?.correct ?? attempt.correct;
  }).length;
}

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

/// Learning hints for the current, already answered question.
class QuestionInsight {
  const QuestionInsight({this.recovery, this.confusedWithId});

  /// Correct answers in a row since the last miss of a hard skill (1–3).
  final int? recovery;

  /// A country chosen by mistake for this target before and again now.
  final String? confusedWithId;
}

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
  final AppDatabase db;

  Future<LearningSession> _load(Session row) async {
    final session = await _loadPlain(row);
    if (session.completed || session.currentAttempt == null) return session;
    return LearningSession(
      session.row,
      session.countryIds,
      session.attempts,
      mapGuesses: session.mapGuesses,
      assistedIndices: session._assistedIndices,
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
    final recovery = !hadMiss || !session.currentAttempt!.correct
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
    if (recovery == null && confused == null) return null;
    return QuestionInsight(recovery: recovery, confusedWithId: confused);
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

  Future<List<LearningSession>> activeCapitals() async {
    final rows =
        await (db.select(db.sessions)..where(
              (s) =>
                  s.continent.equals(continent.name) &
                  s.completedAt.isNull() &
                  s.topic.equals('capitals'),
            ))
            .get();
    return Future.wait(rows.map(_load));
  }

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
                countryIds: jsonEncode(shuffled.take(10).toList()),
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

  Future<List<LearningSession>> activeFlags() async {
    final rows =
        await (db.select(db.sessions)..where(
              (s) =>
                  s.continent.equals(continent.name) &
                  s.completedAt.isNull() &
                  s.topic.equals('flags'),
            ))
            .get();
    return Future.wait(rows.map(_load));
  }

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
    int count = 10,
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
      ? 'assisted'
      : session.isRetryAt(index)
      ? 'retry'
      : session.originAt(index) ?? (session.isDaily ? 'daily' : 'manual');

  Future<LearningSession> answerFlag(String id, int index, String input) =>
      db.transaction(() async {
        final session = await byId(id);
        if (session.completed ||
            session.index != index ||
            !session.isFlagAt(index) ||
            session.isMapAt(index)) {
          throw StateError('Nieaktualne pytanie o flagę');
        }
        if (session.currentAttempt != null) return session;
        if (input.trim().isEmpty || input.length > 100) {
          throw ArgumentError('Pusta lub zbyt długa odpowiedź');
        }
        final question = session.flagQuestionAt(index);
        final difficulty = session.flagDifficulty;
        if (difficulty == FlagDifficulty.choice &&
            !question.options.contains(input)) {
          throw ArgumentError('Odpowiedź spoza listy');
        }
        final answer = difficulty == FlagDifficulty.firstLetter
            ? question.firstLetter + input.trim()
            : input.trim();
        final evaluation = difficulty == FlagDifficulty.choice
            ? AnswerEvaluation(answer == question.countryName)
            : evaluateFlagAnswer(answer, question);
        await _memory.importHistoryOnce();
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
                answeredAt: _clock().toUtc(),
                topic: const Value('flags'),
                difficulty: Value(difficulty.name),
              ),
            );
        final answered = await byId(id);
        await _memory.record(
          activityTime: _clock(),
          answered.currentAttempt!,
          origin: _origin(session, index),
        );
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
    final now = _clock().toUtc();
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
        activityTime: _clock(),
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

  Future<LearningSession> answer(
    String id,
    int index,
    String selected,
    Set<String> allowed, {
    bool assisted = false,
  }) => db.transaction(() async {
    final session = await byId(id);
    if (session.completed || session.index != index) {
      throw StateError('Nieaktualne pytanie');
    }
    if (session.currentAttempt != null) return session;
    if (!session.isMapAt(index)) throw StateError('To nie jest pytanie mapowe');
    if (!allowed.contains(selected)) throw ArgumentError('Nieznane państwo');
    await _memory.importHistoryOnce();
    await db
        .into(db.attempts)
        .insert(
          AttemptsCompanion.insert(
            sessionId: id,
            questionIndex: index,
            countryId: session.targetId,
            answer: selected,
            correct: selected == session.targetId,
            topic: Value(session.topicAt(index)),
            difficulty: Value(session.difficultyNameAt(index)),
            answeredAt: _clock().toUtc(),
          ),
        );
    final answered = await byId(id);
    await _memory.record(
      activityTime: _clock(),
      answered.currentAttempt!,
      origin: assisted
          ? 'assisted'
          : session.isDaily
          ? 'daily'
          : 'manual',
    );
    return byId(id);
  });

  Future<LearningSession> answerCapital(String id, int index, String input) =>
      db.transaction(() async {
        final session = await byId(id);
        if (!session.isCapital || session.completed || session.index != index) {
          throw StateError('Nieaktualne pytanie o stolicę');
        }
        if (session.currentAttempt != null) return session;
        if (input.trim().isEmpty || input.length > 100) {
          throw ArgumentError('Pusta lub zbyt długa odpowiedź');
        }
        final question = session.capitalQuestion;
        final choice = session.difficulty == CapitalDifficulty.choice;
        if (choice && !question.options.contains(input)) {
          throw ArgumentError('Odpowiedź spoza listy');
        }
        final answer = session.difficulty == CapitalDifficulty.firstLetter
            ? question.fact.firstLetter + input.trim()
            : input.trim();
        final evaluation = choice
            ? AnswerEvaluation(answer == question.fact.name)
            : evaluateCapitalAnswer(answer, question.fact);
        await _memory.importHistoryOnce();
        await db
            .into(db.attempts)
            .insert(
              AttemptsCompanion.insert(
                sessionId: id,
                questionIndex: index,
                countryId: session.targetId,
                answer: answer,
                correct: evaluation.correct,
                answeredAt: _clock().toUtc(),
                typoAccepted: Value(evaluation.typoAccepted),
                topic: const Value('capitals'),
                difficulty: Value(session.difficulty.name),
              ),
            );
        final answered = await byId(id);
        await _memory.record(
          activityTime: _clock(),
          answered.currentAttempt!,
          origin: _origin(session, index),
        );
        if (!evaluation.correct) await _queueRetry(session, index);
        return byId(id);
      });

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
    Catalog catalog, {
    FlagCatalog? flags,
  }) => db.transaction(() async {
    await _memory.importHistoryOnce();
    final cards = {
      for (final card in await db.select(db.memoryCards).get()) card.id: card,
    };
    final logs =
        await (db.select(db.memoryReviews)
              ..where((r) => r.applied.equals(true))
              ..orderBy([(r) => OrderingTerm.asc(r.reviewedAt)]))
            .get();
    final latest = <String, MemoryReview>{};
    for (final log in logs) {
      latest[log.skillId] = log;
    }
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
            );
          })(),
    ];
  });

  Future<MemoryOverview> memoryOverview(
    Catalog catalog,
    CapitalCatalog capitals, {
    FlagCatalog? flags,
  }) => db.transaction(() async {
    final plan = await _plan(catalog, capitals, flags: flags);
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
    );
  });

  Future<_MemoryPlan> _plan(
    Catalog catalog,
    CapitalCatalog capitals, {
    FlagCatalog? flags,
    DailyMode mode = DailyMode.regular,
  }) async {
    await _memory.importHistoryOnce();
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
    final now = _clock();
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
    final preferredFresh = [
      ...fresh.where((c) => c.difficulty == 'write'),
      ...fresh.where((c) => c.difficulty != 'write'),
    ];
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
        take(preferredFresh, newSlots);
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
        take(preferredFresh, extraNewPerRound);
        take(control, seriesSize, 'control');
      case DailyMode.placement:
        take(preferredFresh, seriesSize, 'placement');
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
    return _MemoryPlan(
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

  Future<LearningSession?> startDaily(
    Catalog catalog,
    CapitalCatalog capitals, {
    FlagCatalog? flags,
    DailyMode mode = DailyMode.regular,
  }) => db.transaction(() async {
    final existing = await active(topic: 'daily');
    if (existing != null) return existing;
    final plan = await _plan(catalog, capitals, flags: flags, mode: mode);
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
            if (plan.origins[c.id] != null) 'origin': plan.origins[c.id],
          },
        )
        .toList();
    _addScaffolds(questions, plan.struggling);
    _addContrasts(questions, await _confusions(catalog, flags), flags);
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

  /// Ladder: a stubborn skill is first asked in an easier format (A–D or a
  /// zoomed map) as unscored practice; its real question moves a few places
  /// later, so recall follows the reminder without being a copy of it.
  void _addScaffolds(
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
      final easier = scaffoldDifficulty(
        topic,
        original['difficulty'] as String,
      )!;
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

  /// Target country → the country most often given instead of it, once the
  /// same wrong answer happened [confusionThreshold] times. Map guesses and
  /// flag names are reliable; a typed capital does not name a country.
  Future<Map<String, String>> _confusions(
    Catalog catalog,
    FlagCatalog? flags,
  ) async {
    final known = catalog.countries.map((c) => c.id).toSet();
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
      add(
        row.readTable(db.attempts).countryId,
        row.readTable(db.mapGuesses).selectedCountryId,
      );
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

  /// Ladder step 2: right after a graded question about a confused country,
  /// its usual partner follows in the same format as practice, so the two
  /// are compared side by side. In A–D the partner is always an option.
  void _addContrasts(
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
      if (question['origin'] == 'scaffold') continue;
      final difficulty = question['difficulty'] as String;
      questions.insert(i + 1, {
        if (topic == 'flags')
          ...flags!.questions([partner], Random()).single.toJson(),
        'topic': topic,
        'difficulty': difficulty,
        'skill_id': '$topic:$partner:$difficulty',
        'country_id': partner,
        'origin': 'contrast',
      });
      added++;
      i++;
    }
  }

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

class MemoryOverview {
  const MemoryOverview({
    required this.dueCount,
    required this.newAvailable,
    required this.newRemainingToday,
    required this.reviewedToday,
    required this.nextDue,
    required this.plannedCount,
    required this.plannedNewCount,
    required this.activeSession,
    this.reservedNewElsewhere = 0,
    this.otherDueCount = 0,
    this.learnedCount = 0,
  });

  /// Cards of this level with at least one graded answer.
  final int learnedCount;

  /// Another round today has something worth asking.
  bool get canStartExtra => newAvailable > 0 || learnedCount > 0;
  final int dueCount,
      newAvailable,
      newRemainingToday,
      reviewedToday,
      plannedCount,
      plannedNewCount;
  final int reservedNewElsewhere;
  final int otherDueCount;
  final DateTime? nextDue;
  final LearningSession? activeSession;
}

class _MemoryPlan {
  const _MemoryPlan(
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
