import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/learning/capitals.dart';
import 'package:geokuna/features/learning/session_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'schema 1 upgrades without losing old answers, feedback or active sessions',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'geokuna_migration_',
      );
      final file = File('${directory.path}/progress.sqlite');
      final old = sqlite3.open(file.path);
      old.execute(
        'CREATE TABLE sessions (id TEXT NOT NULL PRIMARY KEY, country_ids TEXT NOT NULL, current_index INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL, completed_at INTEGER)',
      );
      old.execute(
        'CREATE TABLE attempts (session_id TEXT NOT NULL REFERENCES sessions(id), question_index INTEGER NOT NULL, country_id TEXT NOT NULL, selected_country_id TEXT NOT NULL, correct INTEGER NOT NULL, answered_at INTEGER NOT NULL, PRIMARY KEY (session_id, question_index))',
      );
      old.execute('INSERT INTO sessions VALUES (?, ?, 0, 1794510000, NULL)', [
        'legacy',
        '["POL","DEU"]',
      ]);
      old.execute('INSERT INTO attempts VALUES (?, 0, ?, ?, 1, 1794510001)', [
        'legacy',
        'POL',
        'POL',
      ]);
      old.execute('PRAGMA user_version = 1');
      old.close();
      final db = AppDatabase(NativeDatabase(file));
      try {
        final repository = SessionRepository(db);
        final restored = (await repository.active())!;
        expect(restored.row.id, 'legacy');
        expect(restored.countryIds, ['POL', 'DEU']);
        expect(restored.currentAttempt!.answer, 'POL');
        expect(restored.currentAttempt!.correct, isTrue);
        expect(restored.currentAttempt!.topic, 'map');
        expect(restored.currentAttempt!.typoAccepted, isFalse);
        await repository.advance('legacy', 0);
        await repository.guessMap('legacy', 1, 'DEU', {
          'POL',
          'DEU',
        }, expectedGuessIndex: 0);
        expect(await repository.history(), hasLength(2));
        final session = await repository.startCapitals(
          await CapitalCatalog.load(),
          CapitalDifficulty.write,
        );
        await repository.answerCapital(
          session.row.id,
          0,
          session.capitalQuestion.fact.name,
        );
        expect(await repository.history(), hasLength(3));
        expect(
          (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
            'user_version',
          ),
          10,
        );
        expect(await db.select(db.autoLevels).get(), isEmpty);
        expect(
          await db
              .customSelect(
                "SELECT name FROM sqlite_master WHERE type = 'index' "
                "AND name = 'memory_reviews_skill'",
              )
              .get(),
          hasLength(1),
        );
        expect(await db.select(db.streakSaves).get(), isEmpty);
      } finally {
        await db.close();
        await directory.delete(recursive: true);
      }
    },
  );
  test(
    'schema 2 upgrades preserving capital attempts and permits new sessions',
    () async {
      final directory = await Directory.systemTemp.createTemp('geokuna_v2_');
      final file = File('${directory.path}/progress.sqlite');
      final old = sqlite3.open(file.path);
      old.execute(
        "CREATE TABLE sessions (id TEXT NOT NULL PRIMARY KEY, country_ids TEXT NOT NULL, current_index INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL, completed_at INTEGER, topic TEXT NOT NULL DEFAULT 'map', difficulty TEXT NOT NULL DEFAULT 'map', question_data TEXT NOT NULL DEFAULT '[]', content_version TEXT NOT NULL DEFAULT 'europe-location-0.2.0')",
      );
      old.execute(
        "CREATE TABLE attempts (session_id TEXT NOT NULL REFERENCES sessions(id), question_index INTEGER NOT NULL, country_id TEXT NOT NULL, answer TEXT NOT NULL, correct INTEGER NOT NULL, typo_accepted INTEGER NOT NULL DEFAULT 0, topic TEXT NOT NULL DEFAULT 'map', difficulty TEXT NOT NULL DEFAULT 'map', answered_at INTEGER NOT NULL, PRIMARY KEY (session_id, question_index))",
      );
      old.execute(
        "INSERT INTO sessions VALUES ('old', '[\"POL\"]', 0, 1794510000, 1794510100, 'capitals', 'write', '[]', 'legacy')",
      );
      old.execute(
        "INSERT INTO attempts VALUES ('old', 0, 'POL', 'Warszaqa', 1, 1, 'capitals', 'write', 1794510001)",
      );
      old.execute('PRAGMA user_version = 2');
      old.close();
      final db = AppDatabase(NativeDatabase(file));
      try {
        final repository = SessionRepository(db);
        final history = await repository.history();
        expect(history, hasLength(1));
        expect(history.single.answer, 'Warszaqa');
        expect(history.single.typoAccepted, isTrue);
        expect(history.single.difficulty, 'write');
        final session = await repository.start(['POL']);
        await repository.guessMap(session.row.id, 0, 'POL', {
          'POL',
        }, expectedGuessIndex: 0);
        expect(await repository.history(), hasLength(2));
        expect(
          (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
            'user_version',
          ),
          10,
        );
        expect(await db.select(db.autoLevels).get(), isEmpty);
        expect(
          await db
              .customSelect(
                "SELECT name FROM sqlite_master WHERE type = 'index' "
                "AND name = 'memory_reviews_skill'",
              )
              .get(),
          hasLength(1),
        );
      } finally {
        await db.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
