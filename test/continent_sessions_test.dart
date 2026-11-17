import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/continent.dart';
import 'package:geokuna/features/learning/session_repository.dart';

void main() {
  test('continent switches resume only their own map and history', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final europe = SessionRepository(db);
    final africa = SessionRepository(db, continent: Continent.africa);
    final eu = await europe.start(['POL']);
    await europe.guessMap(eu.row.id, 0, 'POL', {'POL'}, expectedGuessIndex: 0);
    final af = await africa.start(['EGY']);
    expect(af.row.id, isNot(eu.row.id));
    expect(af.row.continent, 'africa');
    expect((await africa.active())!.targetId, 'EGY');
    expect((await europe.active())!.row.id, eu.row.id);
    expect(await africa.history(), isEmpty);
    expect(await europe.history(), hasLength(1));
    await expectLater(africa.byId(eu.row.id), throwsStateError);
  });

  test('the first visit of an area ends with its first series', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final africa = SessionRepository(db, continent: Continent.africa);
    expect(await africa.firstVisit(), isTrue);
    await SessionRepository(db).start(['POL']);
    expect(await africa.firstVisit(), isTrue);
    await africa.start(['EGY']);
    expect(await africa.firstVisit(), isFalse);
  });
}
