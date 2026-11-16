import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/atlas/continent.dart';
import 'package:geokuna/features/learning/capitals.dart';
import 'package:geokuna/features/learning/flags.dart';
import 'package:geokuna/features/learning/session_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('voivodeships and US states: map, capitals and symbols', () async {
    for (final (area, count, id, question, capital) in [
      (
        Continent.poland,
        16,
        'PL-14',
        'Gdzie leży województwo mazowieckie?',
        'Warszawa',
      ),
      (Continent.usa, 50, 'US-WA', 'Gdzie leży stan Waszyngton?', 'Olympia'),
    ]) {
      final catalog = await Catalog.load(continent: area);
      expect(catalog.countries, hasLength(count));
      expect(catalog.country(id).locationQuestion, question);
      final capitals = await CapitalCatalog.load(continent: area);
      final flags = await FlagCatalog.load(continent: area);
      expect(capitals.facts, hasLength(count));
      expect(flags.facts, hasLength(count));
      expect(capitals.facts.firstWhere((f) => f.countryId == id).name, capital);
      final db = AppDatabase(NativeDatabase.memory());
      try {
        final repo = SessionRepository(db, continent: area);
        expect(
          await repo.startDaily(catalog, capitals, flags: flags),
          isNotNull,
        );
        final progress = await repo.learningProgress(catalog, flags: flags);
        expect(progress, hasLength(count * 12));
      } finally {
        await db.close();
      }
    }
    // Split seats: both cities count, the note explains the split.
    final poland = await CapitalCatalog.load(continent: Continent.poland);
    final kp = poland.facts.firstWhere((f) => f.countryId == 'PL-04');
    expect(evaluateCapitalAnswer('Toruń', kp).correct, isTrue);
    expect(evaluateCapitalAnswer('Bydgoszcz', kp).correct, isTrue);
    expect(kp.note, contains('sejmik'));
    final lb = poland.facts.firstWhere((f) => f.countryId == 'PL-08');
    expect(evaluateCapitalAnswer('Zielona Góra', lb).correct, isTrue);
    expect(Continent.poland.symbolsLabel, 'Herby');
    expect(Continent.poland.symbolQuestion, 'Którego województwa to herb?');
    expect(Continent.usa.capitalPrompt, 'Stolica stanu?');
    expect(Continent.europe.symbolQuestion, 'Jakie to państwo?');
    final usa = await Catalog.load(continent: Continent.usa);
    expect(usa.insetFrames.map((f) => f.areaId), ['US-AK', 'US-HI']);
  });
}
