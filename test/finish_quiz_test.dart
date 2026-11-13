import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:geokuna/app/providers.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/learning/capitals.dart';
import 'package:geokuna/features/learning/learning_screen.dart';

void main() {
  testWidgets(
    'cancel keeps the question; finish leaves unconfirmed input ungraded',
    (tester) async {
      final (catalog, capitals) = (await tester.runAsync(
        () async => (await Catalog.load(), await CapitalCatalog.load()),
      ))!;
      final questions = capitals.questions(['POL', 'DEU'], Random(3));
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await db.close();
      });
      await db
          .into(db.sessions)
          .insert(
            SessionsCompanion.insert(
              id: 'finish-test',
              countryIds: '["POL","DEU"]',
              createdAt: DateTime.now(),
              topic: const Value('capitals'),
              difficulty: const Value('write'),
              contentVersion: Value(capitals.version),
              questionData: Value(
                jsonEncode(questions.map((q) => q.toJson()).toList()),
              ),
            ),
          );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            catalogProvider.overrideWith((ref) async => catalog),
            capitalsProvider.overrideWith((ref) async => capitals),
          ],
          child: const MaterialApp(
            home: LearningScreen(capitalDifficulty: CapitalDifficulty.write),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Warszawa');
      await tester.tap(find.byTooltip('Zakończ quiz'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wróć do quizu'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsOneWidget);
      expect((await db.select(db.attempts).get()), isEmpty);
      await tester.tap(find.byTooltip('Zakończ quiz'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zakończ quiz').last);
      await tester.pumpAndSettle();
      expect(find.text('Nie zatwierdzono żadnej odpowiedzi.'), findsOneWidget);
      expect(await db.select(db.attempts).get(), isEmpty);
      expect(await db.select(db.memoryReviews).get(), isEmpty);
      expect(
        (await db.select(db.sessions).get()).single.completedAt,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
