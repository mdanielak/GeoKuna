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
import 'package:geokuna/features/learning/country_trivia.dart';
import 'package:geokuna/features/learning/flags.dart';
import 'package:geokuna/features/atlas/continent.dart';
import 'package:geokuna/features/settings/app_preferences.dart';

void main() {
  // firstLetter scoring is covered by capitals_test; the UI flow checks A–D and full typing.
  for (final difficulty in [
    CapitalDifficulty.choice,
    CapitalDifficulty.write,
  ]) {
    testWidgets(
      'capitals ${difficulty.name}: use saved level, answer, save and finish',
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
            await CountryTriviaCatalog.load(
              asset: CountryTriviaCatalog.capitalAsset,
            ),
          ),
        ))!;
        final (catalog, capitals, flags, capitalTrivia) = data;
        final question = capitals.questions(['POL'], Random(3)).single;
        final db = AppDatabase(NativeDatabase.memory());
        final preference = LearningDifficulty.values.firstWhere(
          (value) => value.mode == difficulty.name,
        );
        await AppPreferencesStore(db)
            .setDifficulty(Continent.europe, preference);
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
              capitalTriviaProvider.overrideWith((ref) async => capitalTrivia),
            ],
            child: const GeoKunaApp(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Kuna z globusem'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Stolice'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        // Clear the bottom navigation bar, which would take the tap.
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Stolice'));
        await tester.pumpAndSettle();
        expect(find.text('Poziom: ${preference.label}'), findsOneWidget);
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
          if (difficulty == CapitalDifficulty.firstLetter) {
            expect(
              tester
                  .widget<TextField>(
                    find.descendant(
                      of: input,
                      matching: find.byType(TextField),
                    ),
                  )
                  .textCapitalization,
              TextCapitalization.none,
            );
          }
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
        // After a capital question the fact is about the capital (Warsaw).
        expect(find.text('Ciekawostka'), findsOneWidget);
        expect(
          capitalTrivia
              .factsFor('POL')
              .where((f) => find.text(f.text).evaluate().isNotEmpty),
          hasLength(1),
        );
        final attempt = (await db.select(db.attempts).get()).single;
        expect(attempt.correct, isTrue);
        expect(attempt.topic, 'capitals');
        expect(attempt.difficulty, difficulty.name);
        expect(attempt.typoAccepted, difficulty == CapitalDifficulty.write);
        await tester.ensureVisible(find.text('Zobacz wynik'));
        await tester.tap(find.text('Zobacz wynik'));
        await tester.pumpAndSettle();
        if (difficulty == CapitalDifficulty.choice) {
          // A–D has its own recognition FSRS, reported separately.
          expect(
            find.textContaining('Trening rozpoznawania A–D: 1 z 1'),
            findsOneWidget,
          );
        } else {
          expect(
            find.text('1 z 1 ocenianych odpowiedzi poprawnych.'),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
