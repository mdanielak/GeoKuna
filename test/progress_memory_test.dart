import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/learning/session_repository.dart';
import 'package:geokuna/features/learning/learning_progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'assisted selection survives resume without changing map memory',
    () async {
      final catalog = await Catalog.load();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = SessionRepository(db);
      final session = await repo.start(['POL']);
      final answered = await repo.answer(session.row.id, 0, 'POL', {
        'POL',
      }, assisted: true);
      expect(answered.assistedIndices, {0});
      expect((await repo.byId(session.row.id)).assistedIndices, {0});
      expect((await db.select(db.memoryCards).get()).single.state, isNull);
      final log = (await db.select(db.memoryReviews).get()).single;
      expect(log.origin, 'assisted');
      expect(log.applied, isFalse);
      final progress = await repo.learningProgress(catalog);
      expect(
        progress.firstWhere((p) => p.id == 'map:POL:map').status,
        LearningProgressStatus.insufficient,
      );
      await repo.answer(session.row.id, 0, 'POL', {'POL'});
      expect(await db.select(db.memoryReviews).get(), hasLength(1));
    },
  );

  test('progress separates formats, errors, and due dates', () async {
    final catalog = await Catalog.load();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    var now = DateTime.utc(2026, 11, 13, 12);
    final repo = SessionRepository(db, clock: () => now);
    var progress = await repo.learningProgress(catalog);
    expect(progress, hasLength(204));
    expect(
      progress.every((p) => p.status == LearningProgressStatus.insufficient),
      isTrue,
    );
    final session = await repo.start(['POL']);
    await repo.answer(session.row.id, 0, 'POL', {'POL'});
    progress = await repo.learningProgress(catalog);
    expect(
      progress.firstWhere((p) => p.id == 'map:POL:map').status,
      LearningProgressStatus.practising,
    );
    expect(
      progress
          .where((p) => p.country.id == 'POL' && p.topic == 'capitals')
          .every((p) => p.status == LearningProgressStatus.insufficient),
      isTrue,
    );
    now = now.add(const Duration(days: 1));
    expect(
      (await repo.learningProgress(catalog))
          .firstWhere((p) => p.id == 'map:POL:map')
          .status,
      LearningProgressStatus.review,
    );
    await repo.finish(session.row.id);
    final next = await repo.start(['DEU']);
    await repo.answer(next.row.id, 0, 'POL', {'POL', 'DEU'});
    expect(
      (await repo.learningProgress(catalog))
          .firstWhere((p) => p.id == 'map:DEU:map')
          .status,
      LearningProgressStatus.review,
    );
  });
}
