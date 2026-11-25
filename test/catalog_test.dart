import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:drift/native.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/learning/session_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'expanding the catalog preserves an active session and saved answers',
    () async {
      final catalog = await Catalog.load();
      final db = AppDatabase(NativeDatabase.memory());
      try {
        final repository = SessionRepository(db);
        final previous = await repository.start(['POL', 'DEU', 'CZE']);
        await repository.guessMap(previous.row.id, 0, previous.targetId, {
          'POL',
          'DEU',
          'CZE',
        }, expectedGuessIndex: 0);
        final resumed = await repository.start(
          catalog.countries.map((c) => c.id).toList(),
        );
        expect(resumed.row.id, previous.row.id);
        expect(resumed.countryIds, previous.countryIds);
        expect(resumed.currentAttempt!.correct, isTrue);
        expect(await repository.history(), hasLength(1));
      } finally {
        await db.close();
      }
    },
  );
  test(
    'bundled map covers every country and includes small-country markers',
    () async {
      final catalog = await Catalog.load();
      expect(catalog.countries, hasLength(47));
      expect(
        catalog.shapes.map((s) => s.countryId).toSet(),
        catalog.countries.map((c) => c.id).toSet(),
      );
      expect(catalog.country('LIE').small, isTrue);
      expect(catalog.country('LUX').small, isTrue);
      expect(catalog.country('POL').name, 'Polska');
      expect(catalog.countries.where((c) => c.small), hasLength(7));
      expect(catalog.country('VAT').small, isTrue);
      expect(catalog.country('KOS').name, 'Kosowo');
      // Kazakhstan and the South Caucasus are Asia-only; here they are context.
      for (final id in ['KAZ', 'GEO', 'ARM', 'AZE']) {
        expect(catalog.countries.any((c) => c.id == id), isFalse, reason: id);
      }
      expect(catalog.context, isNotEmpty);
      for (final id in ['DEU', 'CZE', 'HUN', 'ITA']) {
        expect(
          catalog.country(id).locationQuestion,
          'Gdzie leżą ${catalog.country(id).name}?',
        );
      }
      for (final country in catalog.countries.where((c) => !c.plural)) {
        expect(country.locationQuestion, 'Gdzie leży ${country.name}?');
      }

      for (final shape in catalog.shapes) {
        for (final ring in shape.rings) {
          expect(ring.length, greaterThanOrEqualTo(4));
          expect(ring.first, ring.last);
        }
      }
    },
  );

  test('CatalogMeta loads countries and version without GeoJSON', () async {
    CatalogMeta.clearCache();
    final full = await Catalog.load();
    final meta = await CatalogMeta.load();
    expect(meta.version, full.version);
    expect(meta.continent, full.continent);
    expect(
      meta.countries.map((c) => (c.id, c.name, c.small, c.plural)).toList(),
      full.countries.map((c) => (c.id, c.name, c.small, c.plural)).toList(),
    );
  });
}
