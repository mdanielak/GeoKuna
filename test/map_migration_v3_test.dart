import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/learning/session_repository.dart';

void main() {
  test('v3 data and active feedback survive adding map guesses', () async {
    final directory = await Directory.systemTemp.createTemp('geokuna_v3_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/db.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    var repo = SessionRepository(db);
    final started = await repo.start(['POL', 'DEU']);
    await repo.answer(started.row.id, 0, started.targetId, {'POL', 'DEU'});
    final oldCards = await db.select(db.memoryCards).get();
    await db.close();
    final old = sqlite3.open(file.path);
    old.execute('DROP TABLE map_guesses');
    old.execute('PRAGMA user_version=3');
    old.close();
    db = AppDatabase(NativeDatabase(file));
    repo = SessionRepository(db);
    try {
      var resumed = (await repo.active())!;
      expect(resumed.row.id, started.row.id);
      expect(resumed.currentAttempt!.correct, isTrue);
      expect(
        (await db.select(db.memoryCards).get()).single.state,
        oldCards.single.state,
      );
      resumed = await repo.advance(resumed.row.id, 0);
      resumed = await repo.guessMap(resumed.row.id, 1, resumed.targetId, {
        'POL',
        'DEU',
      }, expectedGuessIndex: 0);
      expect(resumed.currentMapGuesses, hasLength(1));
      expect(resumed.currentAttempt!.correct, isTrue);
      expect(
        (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
          'user_version',
        ),
        4,
      );
    } finally {
      await db.close();
    }
  });
}
