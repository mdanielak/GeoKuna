import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:geokuna/app/app.dart';
import 'package:geokuna/app/providers.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/catalog.dart';

void main() {
  testWidgets(
    'phone: resumes, selects small-country marker, saves and finishes lesson',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase(NativeDatabase.memory());
      await db
          .into(db.sessions)
          .insert(
            SessionsCompanion.insert(
              id: 'flow',
              countryIds: jsonEncode(['LIE', 'LUX']),
              createdAt: DateTime.now(),
            ),
          );
      final catalog = await tester.runAsync(Catalog.load);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            catalogProvider.overrideWith((ref) async => catalog!),
          ],
          child: const GeoKunaApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Trening mapy'), 180);
      await tester.tap(find.text('Trening mapy'));
      await tester.pumpAndSettle();
      expect(find.text('Gdzie leży Liechtenstein?'), findsOneWidget);
      expect(find.text('Potwierdź'), findsNothing);
      await selectMarker(tester, 'LIE');
      await tester.ensureVisible(find.text('Potwierdź'));
      await tester.tap(find.text('Potwierdź'));
      await tester.pumpAndSettle();
      expect(find.text('Dobrze! To Liechtenstein.'), findsOneWidget);
      expect(await db.select(db.attempts).get(), hasLength(1));
      await tester.ensureVisible(find.text('Następne pytanie'));
      await tester.tap(find.text('Następne pytanie'));
      await tester.pumpAndSettle();
      await selectMarker(tester, 'LUX');
      await tester.ensureVisible(find.text('Potwierdź'));
      await tester.tap(find.text('Potwierdź'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Zobacz wynik'));
      await tester.tap(find.text('Zobacz wynik'));
      await tester.pumpAndSettle();
      expect(find.text('Wyprawa ukończona!'), findsOneWidget);
      expect(find.text('2 z 2 poprawnych odpowiedzi.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await db.close();
    },
  );
}

Future<void> selectMarker(WidgetTester tester, String id) async {
  for (var i = 0; i < 4; i++) {
    final marker = find.byKey(ValueKey('country-marker-$id'));
    await tester.ensureVisible(marker);
    // Several markers can initially cover this location; the first tap zooms the cluster.
    await tester.tapAt(tester.getCenter(marker));
    await tester.pump(const Duration(milliseconds: 400));
    if (find.text('Potwierdź').evaluate().isNotEmpty) return;
  }
  fail('Small-country marker did not become selectable: $id');
}
