import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/atlas/continent.dart';
import 'package:geokuna/features/learning/capitals.dart';
import 'package:geokuna/features/learning/session_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CapitalCatalog capitals, africa, poland;
  setUpAll(() async {
    capitals = await CapitalCatalog.load();
    africa = await CapitalCatalog.load(continent: Continent.africa);
    poland = await CapitalCatalog.load(continent: Continent.poland);
  });

  test(
    'every European country has a verified capital and four unique choices',
    () async {
      final countries = await Catalog.load();
      expect(
        capitals.facts.map((f) => f.countryId).toSet(),
        countries.countries.map((c) => c.id).toSet(),
      );
      final questions = capitals.questions(
        capitals.facts.map((f) => f.countryId).toList(),
        Random(7),
      );
      for (final question in questions) {
        expect(question.options.toSet(), hasLength(4));
        expect(
          question.options.where(
            (o) => evaluateCapitalAnswer(o, question.fact).correct,
          ),
          [question.fact.name],
        );
      }
    },
  );

  test(
    'written answers: one typo, diacritics and endonyms; two errors fail',
    () {
      final warsaw = capitals.facts.firstWhere((f) => f.countryId == 'POL');
      for (final answer in ['Warszaqa', 'Warszwa', 'Warszzawa', 'Wasrzawa']) {
        final evaluation = evaluateCapitalAnswer(answer, warsaw);
        expect(evaluation.correct, isTrue, reason: answer);
        expect(evaluation.typoAccepted, isTrue, reason: answer);
      }
      for (final answer in [
        '',
        '   ',
        'Wrszqa',
        'Xarszaqa',
        'Warsz',
        'Kraków',
        'WarszawaaX',
      ]) {
        expect(
          evaluateCapitalAnswer(answer, warsaw).correct,
          isFalse,
          reason: answer,
        );
      }
      expect(
        evaluateCapitalAnswer('  wArSzAwA  ', warsaw).typoAccepted,
        isFalse,
      );
      final berlin = capitals.facts.firstWhere((f) => f.countryId == 'DEU');
      expect(evaluateCapitalAnswer('Berno', berlin).correct, isFalse);
      // Diacritics, decomposed accents and verified endonyms are not typos.
      for (final entry in {
        'LTU': '  WILNO ',
        'AUT': 'Wieden',
        'ISL': 'Reykjavi\u0301k',
        'UKR': 'Kyiv',
        'AND': 'Andorra la Vella',
        'CHE': 'Bern',
      }.entries) {
        final result = evaluateCapitalAnswer(
          entry.value,
          capitals.facts.firstWhere((f) => f.countryId == entry.key),
        );
        expect(result.correct, isTrue, reason: entry.value);
        expect(result.typoAccepted, isFalse, reason: entry.value);
      }
    },
  );

  test('each level resumes independently and keeps the same question/options snapshot', () async {
    final db = AppDatabase(NativeDatabase.memory());
    try {
      final repository = SessionRepository(db);
      final map = await repository.start(['POL', 'DEU', 'CZE']);
      final sessions = <LearningSession>[];
      for (final difficulty in CapitalDifficulty.values) {
        final session = await repository.startCapitals(
          capitals,
          difficulty,
          random: Random(1),
        );
        sessions.add(session);
        expect(session.countryIds.toSet(), hasLength(10));
        final resumed = await repository.startCapitals(
          capitals,
          difficulty,
          random: Random(2),
        );
        expect(resumed.row.id, session.row.id);
        expect(resumed.row.questionData, session.row.questionData);
        expect(resumed.difficulty, difficulty);
      }
      expect(sessions.map((s) => s.row.id).toSet(), hasLength(3));
      expect(await repository.activeCapitals(), hasLength(3));
      expect((await repository.active())!.row.id, map.row.id);
    } finally {
      await db.close();
    }
  });

  test(
    'text scoring and hint composition persist, choice mode stays strict',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        final repository = SessionRepository(db);
        for (final difficulty in CapitalDifficulty.values) {
          var session = await repository.startCapitals(
            capitals,
            difficulty,
            random: Random(4),
          );
          final fact = session.capitalQuestion.fact;
          if (difficulty == CapitalDifficulty.choice) {
            await expectLater(
              repository.answerCapital(session.row.id, 0, '${fact.name}X'),
              throwsArgumentError,
            );
            final wrong = session.capitalQuestion.options.firstWhere(
              (o) => o != fact.name,
            );
            session = await repository.answerCapital(session.row.id, 0, wrong);
            expect(session.currentAttempt!.correct, isFalse);
          } else {
            final input = difficulty == CapitalDifficulty.firstLetter
                ? fact.name.substring(1)
                : '${fact.name}X';
            session = await repository.answerCapital(session.row.id, 0, input);
            expect(session.currentAttempt!.correct, isTrue);
            expect(
              session.currentAttempt!.typoAccepted,
              difficulty == CapitalDifficulty.write,
            );
            expect(
              session.currentAttempt!.answer,
              difficulty == CapitalDifficulty.firstLetter
                  ? fact.name
                  : '${fact.name}X',
            );
            await repository.answerCapital(session.row.id, 0, 'wrong');
            expect(
              (await repository.byId(session.row.id)).attempts,
              hasLength(1),
            );
          }
        }
      } finally {
        await db.close();
      }
    },
  );

  test('English names count everywhere, also with one typo', () async {
    CapitalFact of(CapitalCatalog c, String id) =>
        c.facts.firstWhere((f) => f.countryId == id);
    final cyprus = of(capitals, 'CYP');
    for (final input in ['Nikozja', 'Nicosia', 'Nicosa', 'Makozia']) {
      expect(
        evaluateCapitalAnswer(input, cyprus).correct,
        input != 'Makozia',
        reason: input,
      );
    }
    expect(evaluateCapitalAnswer('Viena', of(capitals, 'AUT')).correct, isTrue);
    expect(evaluateCapitalAnswer('Cairo', of(africa, 'EGY')).correct, isTrue);
    expect(
      evaluateCapitalAnswer('Warsaw', of(poland, 'PL-14')).correct,
      isTrue,
    );
  });

  test('resolveFirstLetterAnswer tolerates re-typing the initial letter', () {
    final warsaw = capitals.facts.firstWhere((f) => f.countryId == 'POL');
    for (final (input, expectedCorrect, expectedTypo) in [
      ('arszawa', true, false),
      ('Warszawa', true, false),
      ('Warszaqa', true, true),
      ('arszaqa', true, true),
      ('Krakow', false, false),
    ]) {
      final (_, eval) = resolveFirstLetterAnswer(
        warsaw.firstLetter,
        input,
        (candidate) => evaluateCapitalAnswer(candidate, warsaw),
      );
      expect(eval.correct, expectedCorrect, reason: input);
      expect(eval.typoAccepted, expectedTypo, reason: input);
    }
  });
}
