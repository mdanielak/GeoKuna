import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/learning/auto_level.dart';
import 'package:geokuna/features/learning/session_repository.dart';
import 'package:geokuna/features/settings/progress_backup.dart';

void main() {
  test('backup round trip restores progress and auto levels; bad files change nothing', () async {
    final source = AppDatabase(NativeDatabase.memory());
    final target = AppDatabase(NativeDatabase.memory());
    addTearDown(source.close);
    addTearDown(target.close);
    final repo = SessionRepository(source);
    final session = await repo.start(['POL', 'DEU']);
    final target0 = session.targetId;
    await repo.guessMap(session.row.id, 0, target0, {
      'POL',
      'DEU',
    }, expectedGuessIndex: 0);
    await AutoLevelStore(source).recordAnswer(
      topic: 'map',
      countryId: 'POL',
      difficulty: 'map',
      correct: false,
      now: DateTime.utc(2026, 11, 26, 9),
    );
    final file = await ProgressBackup(source).export();

    final summary = await ProgressBackup(target).import(file);
    expect(summary.answers, 1);
    expect(await target.select(target.memoryReviews).get(), hasLength(1));
    expect(await target.select(target.autoLevels).get(), hasLength(1));
    expect(
      (await SessionRepository(target).history()).single.countryId,
      target0,
    );

    // Legacy v9 JSON without auto_levels still imports cleanly.
    final legacy = jsonDecode(file) as Map<String, dynamic>;
    legacy['schema'] = 9;
    (legacy['tables'] as Map<String, dynamic>).remove('auto_levels');
    await ProgressBackup(target).import(jsonEncode(legacy));
    expect(await target.select(target.autoLevels).get(), isEmpty);

    for (final bad in [
      'nie json',
      '{"format":"inna"}',
      file.replaceFirst('"schema":${source.schemaVersion}', '"schema":99'),
      file.replaceFirst('"attempts":[', '"attempts":[{"x":1},'),
    ]) {
      await expectLater(
        ProgressBackup(target).import(bad),
        throwsA(isA<BackupException>()),
      );
    }
    expect(await target.select(target.attempts).get(), hasLength(1));
  });
}
