import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/continent.dart';
import 'package:geokuna/features/learning/learning_reset.dart';
import 'package:geokuna/features/learning/memory.dart';
import 'package:geokuna/features/learning/session_repository.dart';

void main() {
  test('reset of a shared country clears its memory without resurrecting historical attempts', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final asia = SessionRepository(db, continent: Continent.asia);
    final session = await asia.start(['TUR']);
    await asia.guessMap(session.row.id, 0, 'TUR', {
      'TUR',
    }, expectedGuessIndex: 0);
    await LearningReset(db).continent(Continent.europe, {'TUR'});
    expect((await asia.active())!.row.id, session.row.id);
    expect(await db.select(db.memoryCards).get(), isEmpty);
    expect(await db.select(db.memoryReviews).get(), isEmpty);
    await MemoryStore(db).importHistoryOnce();
    expect(await db.select(db.memoryCards).get(), isEmpty);
    expect(await asia.history(), hasLength(1));
  });

  test(
    'regional reset preserves unrelated learning; full reset clears all',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final europe = SessionRepository(db);
      final africa = SessionRepository(db, continent: Continent.africa);
      final eu = await europe.start(['POL']);
      await europe.guessMap(eu.row.id, 0, 'POL', {
        'POL',
      }, expectedGuessIndex: 0);
      final af = await africa.start(['EGY']);
      await africa.guessMap(af.row.id, 0, 'EGY', {
        'EGY',
      }, expectedGuessIndex: 0);
      final reset = LearningReset(db);
      await reset.continent(Continent.europe, {'POL'});
      expect(await europe.active(), isNull);
      expect((await africa.active())!.row.id, af.row.id);
      expect((await db.select(db.memoryCards).get()).single.countryId, 'EGY');
      expect(await europe.history(), isEmpty);
      expect(await africa.history(), hasLength(1));
      await reset.all();
      expect(await db.select(db.sessions).get(), isEmpty);
      expect(await db.select(db.attempts).get(), isEmpty);
      expect(await db.select(db.mapGuesses).get(), isEmpty);
      expect(await db.select(db.memoryReviews).get(), isEmpty);
      expect(await db.select(db.memoryCards).get(), isEmpty);
      expect(await db.select(db.memoryMeta).get(), isEmpty);
      await reset.all();
    },
  );
}
