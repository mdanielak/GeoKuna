import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:geokuna/app/app.dart';
import 'package:geokuna/app/providers.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/learning/capitals.dart';
import 'package:geokuna/features/learning/flags.dart';

void main() {
  for (final difficulty in CapitalDifficulty.values) {
    testWidgets(
      'capitals ${difficulty.name}: select level, answer, save and finish',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final data = (await tester.runAsync(
          () async => (
            await Catalog.load(),
            await CapitalCatalog.load(),
            await FlagCatalog.load(),
          ),
        ))!;
        final (catalog, capitals, flags) = data;
        final question = capitals.questions(['POL'], Random(3)).single;
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox());
          await db.close();
        });
        await db
            .into(db.sessions)
            .insert(
              SessionsCompanion.insert(
                id: 'capital-flow',
                countryIds: '["POL"]',
                createdAt: DateTime.now(),
                topic: const Value('capitals'),
                difficulty: Value(difficulty.name),
                contentVersion: Value(capitals.version),
                questionData: Value(jsonEncode([question.toJson()])),
              ),
            );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              catalogProvider.overrideWith((ref) async => catalog),
              capitalsProvider.overrideWith((ref) async => capitals),
              flagsProvider.overrideWith((ref) async => flags),
            ],
            child: const GeoKunaApp(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Kuna z globusem'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Trening stolic · wybierz poziom'),
          200,
        );
        await tester.tap(find.text('Trening stolic · wybierz poziom'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(difficulty.label));
        await tester.tap(find.text(difficulty.label));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Wznów trening stolic'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Wznów trening stolic'));
        await tester.pumpAndSettle();
        expect(find.text('Polska'), findsOneWidget);
        expect(find.text('Stolica?'), findsOneWidget);
        expect(find.text('Polska · ${difficulty.label}'), findsNothing);
        if (difficulty == CapitalDifficulty.choice) {
          final index = question.options.indexOf('Warszawa');
          expect(find.byType(RadioListTile<String>), findsNWidgets(4));
          await tester.tap(
            find.text('${String.fromCharCode(65 + index)}. Warszawa'),
          );
        } else {
          expect(find.text('Warszawa'), findsNothing);
          if (difficulty == CapitalDifficulty.firstLetter) {
            expect(
              find.text('Pierwsza litera: W. Dopisz pozostałe litery.'),
              findsOneWidget,
            );
          }
          final input = find.byType(TextFormField);
          expect(tester.widget<TextFormField>(input).initialValue, '');
          await tester.enterText(
            input,
            difficulty == CapitalDifficulty.firstLetter
                ? 'arszawa'
                : 'Warszaqa',
          );
        }
        await tester.pump();
        await tester.ensureVisible(find.text('Sprawdź odpowiedź'));
        await tester.tap(find.text('Sprawdź odpowiedź'));
        await tester.pumpAndSettle();
        if (difficulty == CapitalDifficulty.write) {
          expect(
            find.textContaining('literówka zaakceptowana'),
            findsOneWidget,
          );
          expect(
            find.textContaining('Poprawna pisownia: Warszawa.'),
            findsOneWidget,
          );
        }
        final attempt = (await db.select(db.attempts).get()).single;
        expect(attempt.correct, isTrue);
        expect(attempt.topic, 'capitals');
        expect(attempt.difficulty, difficulty.name);
        expect(attempt.typoAccepted, difficulty == CapitalDifficulty.write);
        await tester.ensureVisible(find.text('Zobacz wynik'));
        await tester.tap(find.text('Zobacz wynik'));
        await tester.pumpAndSettle();
        expect(find.text('1 z 1 poprawnych odpowiedzi.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
