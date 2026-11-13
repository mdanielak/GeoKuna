import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:geokuna/app/app.dart';
import 'package:geokuna/app/providers.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/atlas/country_map.dart';
import 'package:geokuna/features/learning/capitals.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('zmiana parametrów quizu nie zachowuje starego pytania', (
    tester,
  ) async {
    final data = (await tester.runAsync(
      () async => (await Catalog.load(), await CapitalCatalog.load()),
    ))!;
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await db.close();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          catalogProvider.overrideWith((ref) async => data.$1),
          capitalsProvider.overrideWith((ref) async => data.$2),
        ],
        child: const GeoKunaApp(),
      ),
    );
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.text('Dziś')));
    router.go('/learn?topic=capitals&level=write');
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsOneWidget);
    router.go('/learn');
    await tester.pumpAndSettle();
    expect(find.byType(CountryMap), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    router.go('/learn?topic=capitals&level=choice');
    await tester.pumpAndSettle();
    expect(find.byType(CountryMap), findsNothing);
    expect(find.byType(RadioListTile<String>), findsNWidgets(4));
    expect(await db.select(db.attempts).get(), isEmpty);
  });
}
