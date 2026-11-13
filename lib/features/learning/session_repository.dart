import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart';
import 'capitals.dart';
import 'memory.dart';
import '../atlas/catalog.dart';

class LearningSession {
  const LearningSession(this.row, this.countryIds, this.attempts);
  final Session row;
  final List<String> countryIds;
  final List<Attempt> attempts;
  bool get completed => row.completedAt != null;
  int get index => row.currentIndex;
  bool get isDaily => row.topic == 'daily';
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

  int get correctCount => attempts.where((a) => a.correct).length;
}

class SessionRepository {
  SessionRepository(this.db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;
  final DateTime Function() _clock;
  MemoryStore get _memory => MemoryStore(db);
  final AppDatabase db;

  Future<LearningSession> _load(Session row) async => LearningSession(
    row,
    (jsonDecode(row.countryIds) as List).cast<String>(),
    await (db.select(
      db.attempts,
    )..where((a) => a.sessionId.equals(row.id))).get(),
  );

  Future<LearningSession?> active({
    String topic = 'map',
    String? difficulty,
  }) async {
    final rows =
        await (db.select(db.sessions)..where(
              (s) =>
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
    final rows = await (db.select(
      db.sessions,
    )..where((s) => s.completedAt.isNull() & s.topic.equals('capitals'))).get();
    return Future.wait(rows.map(_load));
  }

  Future<LearningSession> byId(String id) async => _load(
    await (db.select(db.sessions)..where((s) => s.id.equals(id))).getSingle(),
  );

  Future<LearningSession> start(List<String> ids, {Random? random}) =>
      db.transaction(() async {
        final existing = await active();
        if (existing != null) return existing;
        final shuffled = ids.toSet().toList()..shuffle(random);
        if (shuffled.isEmpty) throw StateError('Brak państw w katalogu');
        final id = const Uuid().v4();
        await db
            .into(db.sessions)
            .insert(
              SessionsCompanion.insert(
                id: id,
                countryIds: jsonEncode(shuffled.take(10).toList()),
                createdAt: _clock().toUtc(),
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
    final ids = catalog.facts.map((f) => f.countryId).toList()..shuffle(rng);
    final questions = catalog.questions(ids.take(10).toList(), rng);
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

  Future<LearningSession> answer(
    String id,
    int index,
    String selected,
    Set<String> allowed,
  ) => db.transaction(() async {
    final session = await byId(id);
    if (session.completed || session.index != index) {
      throw StateError('Nieaktualne pytanie');
    }
    if (session.currentAttempt != null) return session;
    if (session.isCapital) throw StateError('To nie jest pytanie mapowe');
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
            answeredAt: _clock().toUtc(),
          ),
        );
    final answered = await byId(id);
    await _memory.record(
      answered.currentAttempt!,
      origin: session.isDaily ? 'daily' : 'manual',
    );
    return answered;
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
          answered.currentAttempt!,
          origin: session.isDaily ? 'daily' : 'manual',
        );
        return answered;
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

  Future<MemoryOverview> memoryOverview(
    Catalog catalog,
    CapitalCatalog capitals,
  ) => db.transaction(() async {
    final plan = await _plan(catalog, capitals);
    return MemoryOverview(
      dueCount: plan.dueCount,
      newAvailable: plan.newAvailable,
      newRemainingToday: plan.newRemainingToday,
      reviewedToday: plan.reviewedToday,
      nextDue: plan.nextDue,
      plannedCount: plan.cards.length,
      plannedNewCount: plan.cards.where((c) => c.state == null).length,
      activeSession: await active(topic: 'daily'),
    );
  });

  Future<_MemoryPlan> _plan(Catalog catalog, CapitalCatalog capitals) async {
    await _memory.importHistoryOnce();
    for (final country in catalog.countries) {
      await _memory.ensureCard(country.id, 'map', 'map');
      if (capitals.facts.any((f) => f.countryId == country.id)) {
        for (final mode in CapitalDifficulty.values) {
          await _memory.ensureCard(country.id, 'capitals', mode.name);
        }
      }
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
    final budget = max(
      0,
      3 - reviews.where((r) => r.wasNew && r.origin == 'daily').length,
    );
    final known = catalog.countries.map((c) => c.id).toSet();
    final cards = (await db.select(db.memoryCards).get())
        .where((c) => known.contains(c.countryId))
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
            final date = a.due!.compareTo(b.due!);
            return date == 0 ? a.id.compareTo(b.id) : date;
          });
    final fresh = cards.where((c) => c.state == null).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    fresh.shuffle(Random(now.year * 10000 + now.month * 100 + now.day));
    final selected = <MemoryCard>[];
    final countries = <String>{};
    for (final card in due) {
      if (selected.length == 10) break;
      if (countries.add(card.countryId)) selected.add(card);
    }
    var added = 0;
    if (due.length < 10) {
      for (final card in fresh) {
        if (selected.length == 10 || added == budget) break;
        if (countries.add(card.countryId)) {
          selected.add(card);
          added++;
        }
      }
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
    return _MemoryPlan(
      selected,
      due.length,
      fresh.length,
      budget,
      reviews.where((r) => r.applied).length,
      future.firstOrNull,
    );
  }

  Future<LearningSession?> startDaily(
    Catalog catalog,
    CapitalCatalog capitals,
  ) => db.transaction(() async {
    final existing = await active(topic: 'daily');
    if (existing != null) return existing;
    final plan = await _plan(catalog, capitals);
    if (plan.cards.isEmpty) return null;
    final questions = plan.cards
        .map(
          (c) => <String, dynamic>{
            if (c.topic == 'capitals')
              ...capitals.questions([c.countryId], Random()).single.toJson(),
            'topic': c.topic,
            'difficulty': c.difficulty,
            'skill_id': c.id,
            'country_id': c.countryId,
          },
        )
        .toList();
    final id = const Uuid().v4();
    await db
        .into(db.sessions)
        .insert(
          SessionsCompanion.insert(
            id: id,
            countryIds: jsonEncode(plan.cards.map((c) => c.countryId).toList()),
            createdAt: _clock().toUtc(),
            topic: const Value('daily'),
            difficulty: const Value('mixed'),
            questionData: Value(jsonEncode(questions)),
            contentVersion: Value('memory-0.4.0|${capitals.version}'),
          ),
        );
    return byId(id);
  });

  Future<List<Attempt>> history() => (db.select(
    db.attempts,
  )..orderBy([(a) => OrderingTerm.desc(a.answeredAt)])).get();
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
  });
  final int dueCount,
      newAvailable,
      newRemainingToday,
      reviewedToday,
      plannedCount,
      plannedNewCount;
  final DateTime? nextDue;
  final LearningSession? activeSession;
}

class _MemoryPlan {
  const _MemoryPlan(
    this.cards,
    this.dueCount,
    this.newAvailable,
    this.newRemainingToday,
    this.reviewedToday,
    this.nextDue,
  );
  final List<MemoryCard> cards;
  final int dueCount, newAvailable, newRemainingToday, reviewedToday;
  final DateTime? nextDue;
}
