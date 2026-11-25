import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/learning/session_repository.dart';

void main() {
  late AppDatabase db;
  late SessionRepository repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = SessionRepository(db);
  });
  tearDown(() => db.close());
  test(
    'three guesses persist; first error grades once even if later correct',
    () async {
      var session = await repo.start(['POL']);
      session = await repo.guessMap(session.row.id, 0, 'DEU', {
        'POL',
        'DEU',
        'CZE',
      }, expectedGuessIndex: 0);
      expect(session.currentAttempt, isNull);
      expect(session.currentMapGuesses, hasLength(1));
      final log = (await db.select(db.memoryReviews).get()).single;
      expect(log.rating, 1);
      session = await repo.guessMap(session.row.id, 0, 'DEU', {
        'POL',
        'DEU',
        'CZE',
      }, expectedGuessIndex: 0);
      expect(session.currentMapGuesses, hasLength(1));
      session = await repo.byId(session.row.id);
      session = await repo.guessMap(session.row.id, 0, 'CZE', {
        'POL',
        'DEU',
        'CZE',
      }, expectedGuessIndex: 1);
      expect(session.currentAttempt, isNull);
      session = await repo.guessMap(session.row.id, 0, 'POL', {
        'POL',
        'DEU',
        'CZE',
      }, expectedGuessIndex: 2);
      expect(session.currentAttempt!.correct, isTrue);
      expect(session.correctCount, 0);
      expect(session.currentMapGuesses, hasLength(3));
      expect(await db.select(db.memoryReviews).get(), hasLength(1));
      expect((await db.select(db.memoryCards).get()).single.reviewCount, 1);
    },
  );
  test(
    'third wrong closes; finish after one wrong preserves that answer',
    () async {
      var session = await repo.start(['POL']);
      const ids = {'POL', 'DEU', 'CZE', 'ITA'};
      for (var i = 0; i < 3; i++) {
        session = await repo.guessMap(
          session.row.id,
          0,
          ['DEU', 'CZE', 'ITA'][i],
          ids,
          expectedGuessIndex: i,
        );
      }
      expect(session.currentAttempt!.correct, isFalse);
      await repo.finish(session.row.id);
      session = await repo.start(['POL']);
      session = await repo.guessMap(
        session.row.id,
        0,
        'DEU',
        ids,
        expectedGuessIndex: 0,
      );
      session = await repo.finish(session.row.id);
      expect(session.completed, isTrue);
      expect(session.currentAttempt!.correct, isFalse);
      expect(session.attempts, hasLength(1));
    },
  );

  test('2nd-try map hit after earlier miss sets isFirstTryCorrectAt=false and no 0-of-3 recovery insight', () async {
    const ids = {'POL', 'DEU', 'CZE'};
    var first = await repo.start(['POL']);
    first = await repo.guessMap(
      first.row.id,
      0,
      'DEU',
      ids,
      expectedGuessIndex: 0,
    );
    await repo.finish(first.row.id);

    var second = await repo.start(['POL']);
    second = await repo.guessMap(
      second.row.id,
      0,
      'DEU',
      ids,
      expectedGuessIndex: 0,
    );
    second = await repo.guessMap(
      second.row.id,
      0,
      'POL',
      ids,
      expectedGuessIndex: 1,
    );
    expect(second.currentAttempt!.correct, isTrue);
    expect(second.isFirstTryCorrectAt(0), isFalse);
    expect(second.insight?.recovery, isNull);
  });
}
