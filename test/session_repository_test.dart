import 'dart:io';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/learning/session_repository.dart';

void main() {
  const ids = [
    'POL',
    'DEU',
    'CZE',
    'SVK',
    'AUT',
    'HUN',
    'SVN',
    'HRV',
    'ITA',
    'CHE',
    'FRA',
    'BEL',
    'NLD',
    'LUX',
    'LIE',
  ];
  late AppDatabase db;
  var defaultDbClosed = false;
  late SessionRepository repository;
  setUp(() {
    defaultDbClosed = false;
    db = AppDatabase(NativeDatabase.memory());
    repository = SessionRepository(db);
  });
  tearDown(() async {
    if (!defaultDbClosed) await db.close();
  });

  test('ten distinct questions resume, finish and keep history', () async {
    var session = await repository.start(ids, random: Random(7));
    expect(session.countryIds.toSet(), hasLength(10));
    final resumed = await repository.start(ids);
    expect(resumed.row.id, session.row.id);
    expect(resumed.countryIds, session.countryIds);
    expect(await repository.history(), isEmpty);
    session = await repository.start(ids);
    for (var i = 0; i < 10; i++) {
      session = await repository.guessMap(
        session.row.id,
        i,
        session.targetId,
        ids.toSet(),
        expectedGuessIndex: 0,
      );
      session = await repository.advance(session.row.id, i);
    }
    expect(session.completed, isTrue);
    expect(session.correctCount, 10);
    expect(await repository.active(), isNull);
    expect(await repository.history(), hasLength(10));
    expect((await repository.start(ids)).row.id, isNot(session.row.id));
  });

  test(
    'scores correct and incorrect answers, duplicate writes do not overwrite',
    () async {
      final session = await repository.start(ids);
      final first = await repository.guessMap(
        session.row.id,
        0,
        session.targetId,
        ids.toSet(),
        expectedGuessIndex: 0,
      );
      expect(first.currentAttempt!.correct, isTrue);
      final wrong = ids.firstWhere((id) => id != session.targetId);
      await repository.guessMap(
        session.row.id,
        0,
        wrong,
        ids.toSet(),
        expectedGuessIndex: 0,
      );
      expect(await repository.history(), hasLength(1));
      var missed = await repository.advance(session.row.id, 0);
      final wrongPicks = ids
          .where((id) => id != missed.targetId)
          .take(3)
          .toList();
      for (var g = 0; g < 3; g++) {
        missed = await repository.guessMap(
          missed.row.id,
          1,
          wrongPicks[g],
          ids.toSet(),
          expectedGuessIndex: g,
        );
      }
      expect(missed.currentAttempt!.correct, isFalse);
      expect(missed.correctCount, 1);
    },
  );

  test(
    'cannot advance unanswered questions or write unknown/stale selections',
    () async {
      final session = await repository.start(ids);
      await expectLater(
        repository.advance(session.row.id, 0),
        throwsStateError,
      );
      await expectLater(
        repository.guessMap(
          session.row.id,
          0,
          'UNKNOWN',
          ids.toSet(),
          expectedGuessIndex: 0,
        ),
        throwsArgumentError,
      );
      await repository.guessMap(
        session.row.id,
        0,
        session.targetId,
        ids.toSet(),
        expectedGuessIndex: 0,
      );
      await repository.advance(session.row.id, 0);
      await expectLater(
        repository.guessMap(
          session.row.id,
          0,
          'POL',
          ids.toSet(),
          expectedGuessIndex: 0,
        ),
        throwsStateError,
      );
      final duplicateAdvance = await repository.advance(session.row.id, 0);
      expect(duplicateAdvance.index, 1);
    },
  );

  test('early finish preserves answers and memory and is idempotent', () async {
    var now = DateTime.utc(2026, 1, 1);
    repository = SessionRepository(db, clock: () => now);
    var session = await repository.start(ids, random: Random(7));
    session = await repository.guessMap(
      session.row.id,
      0,
      session.targetId,
      ids.toSet(),
      expectedGuessIndex: 0,
    );
    session = await repository.advance(session.row.id, 0);
    final attempts = await repository.history();
    final cards = await db.select(db.memoryCards).get();
    final reviews = await db.select(db.memoryReviews).get();
    final finished = await repository.finish(session.row.id);
    expect(finished.completed, isTrue);
    expect(finished.attempts, attempts);
    expect(finished.attempts, hasLength(1));
    expect(await db.select(db.memoryCards).get(), cards);
    expect(await db.select(db.memoryReviews).get(), reviews);
    expect(await repository.active(), isNull);
    await expectLater(
      repository.guessMap(
        session.row.id,
        1,
        session.targetId,
        ids.toSet(),
        expectedGuessIndex: 0,
      ),
      throwsStateError,
    );
    now = now.add(const Duration(days: 1));
    expect(
      (await repository.finish(session.row.id)).row.completedAt,
      finished.row.completedAt,
    );
    expect((await repository.start(ids)).row.id, isNot(session.row.id));
  });

  test(
    'reopens file database with feedback, order and history intact',
    () async {
      await db.close();
      defaultDbClosed = true;
      final directory = await Directory.systemTemp.createTemp('geokuna_test_');
      final path = File('${directory.path}/progress.sqlite');
      final firstDb = AppDatabase(NativeDatabase(path));
      final firstRepository = SessionRepository(firstDb);
      try {
        final first = await firstRepository.start(ids, random: Random(1));
        await firstRepository.guessMap(
          first.row.id,
          0,
          first.targetId,
          ids.toSet(),
          expectedGuessIndex: 0,
        );
        await firstDb.close();
        final reopened = AppDatabase(NativeDatabase(path));
        try {
          final restored = (await SessionRepository(reopened).active())!;
          expect(restored.row.id, first.row.id);
          expect(restored.countryIds, first.countryIds);
          expect(restored.index, 0);
          expect(restored.currentAttempt!.correct, isTrue);
        } finally {
          await reopened.close();
        }
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
}
