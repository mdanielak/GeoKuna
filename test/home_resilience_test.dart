import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/app/app.dart';
import 'package:geokuna/app/providers.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/atlas/country_map.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('atlas działa mimo błędu bazy', (tester) async {
    final catalog = (await tester.runAsync(Catalog.load))!;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogProvider.overrideWith((ref) async => catalog),
          databaseProvider.overrideWith((ref) => throw StateError('baza')),
        ],
        child: const GeoKunaApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Nie udało się wczytać dzisiejszej wyprawy.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.textContaining('Odkrywaj atlas'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Odkrywaj atlas'));
    await tester.pumpAndSettle();
    expect(find.text('Atlas Europy'), findsOneWidget);
    expect(find.byType(CountryMap), findsOneWidget);
  });

  testWidgets('trening mapy działa mimo błędu stolic', (tester) async {
    final catalog = (await tester.runAsync(Catalog.load))!;
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await db.close();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogProvider.overrideWith((ref) async => catalog),
          capitalsProvider.overrideWith(
            (ref) async => throw StateError('stolice'),
          ),
          databaseProvider.overrideWithValue(db),
        ],
        child: const GeoKunaApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Nie udało się wczytać dzisiejszej wyprawy.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Trening mapy'));
    await tester.tap(find.text('Trening mapy'));
    await tester.pumpAndSettle();
    expect(find.byType(CountryMap), findsOneWidget);
  });

  testWidgets('ładowanie i błąd katalogu nie ukrywają nawigacji', (
    tester,
  ) async {
    final pending = Completer<Catalog>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [catalogProvider.overrideWith((ref) => pending.future)],
        child: const GeoKunaApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Trening mapy'), findsOneWidget);
    expect(find.text('Odkrywaj atlas'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Postępy'), 160);
    expect(find.text('Postępy'), findsOneWidget);
    pending.completeError(StateError('katalog'));
    await tester.pumpAndSettle();
    expect(
      find.text('Nie udało się wczytać dzisiejszej wyprawy.'),
      findsOneWidget,
    );
    expect(find.text('Odkrywaj atlas'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Ponów odczyt'), -160);
    expect(find.text('Ponów odczyt'), findsOneWidget);
  });
}
