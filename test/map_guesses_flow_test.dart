import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:geokuna/app/app.dart';
import 'package:geokuna/app/providers.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/atlas/country_map.dart';
import 'package:geokuna/features/learning/country_trivia.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('map hides solution until third wrong direct tap', (
    tester,
  ) async {
    final catalog = (await tester.runAsync(Catalog.load))!;
    final trivia = (await tester.runAsync(CountryTriviaCatalog.load))!;
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await db.close();
    });
    await db
        .into(db.sessions)
        .insert(
          SessionsCompanion.insert(
            id: 'retries-ui',
            countryIds: '["POL"]',
            createdAt: DateTime.now(),
          ),
        );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          catalogProvider.overrideWith((ref) async => catalog),
          countryTriviaProvider.overrideWith((ref) async => trivia),
        ],
        child: const GeoKunaApp(),
      ),
    );
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(NavigationBar))).go('/learn');
    await tester.pumpAndSettle();
    expect(find.text('Potwierdź'), findsNothing);
    for (var i = 0; i < 3; i++) {
      tester
          .widget<CountryMap>(find.byType(CountryMap))
          .onSelected(['DEU', 'CZE', 'ITA'][i]);
      await tester.pumpAndSettle();
      final map = tester.widget<CountryMap>(find.byType(CountryMap));
      expect(map.correctId, i == 2 ? 'POL' : isNull);
      if (i < 2) {
        expect(find.textContaining('Pozostało prób: ${2 - i}'), findsOneWidget);
        expect(await db.select(db.attempts).get(), isEmpty);
      }
    }
    expect(find.textContaining('Poprawna odpowiedź: Polska'), findsOneWidget);
    // A fact also follows a miss, on its own bulb card.
    expect(find.text('Ciekawostka'), findsOneWidget);
    expect(find.byIcon(Icons.lightbulb), findsOneWidget);
    expect((await db.select(db.memoryReviews).get()).single.rating, 1);
  });
}
