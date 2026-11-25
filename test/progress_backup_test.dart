import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/learning/session_repository.dart';
import 'package:geokuna/features/settings/progress_backup.dart';

void main() {
  test(
    'backup round trip restores progress; bad files change nothing',
    () async {
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
      final file = await ProgressBackup(source).export();

      final summary = await ProgressBackup(target).import(file);
      expect(summary.answers, 1);
      expect(await target.select(target.memoryReviews).get(), hasLength(1));
      expect(
        (await SessionRepository(target).history()).single.countryId,
        target0,
      );

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
    },
  );
}
