import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/app/app.dart';
import 'package:geokuna/app/providers.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/learning/capitals.dart';
import 'package:geokuna/features/learning/flags.dart';
import 'package:geokuna/features/learning/learning_levels.dart';
import 'package:geokuna/features/settings/app_preferences.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('Dziś: mały telefon i tekst 200% zachowują dostęp do CTA', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = (await tester.runAsync(
      () async => (
        await Catalog.load(),
        await CapitalCatalog.load(),
        await FlagCatalog.load(),
      ),
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
          flagsProvider.overrideWith((ref) async => data.$3),
        ],
        child: const GeoKunaApp(),
      ),
    );
    await tester.pumpAndSettle();
    // First visit: the main button is the easy placement quiz.
    expect(
      find.text('Europa · krótki quiz na start, poziom łatwy'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Wstępny quiz'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Wstępny quiz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wstępny quiz'));
    await tester.pumpAndSettle();
    expect(find.text('Pytanie 1 z 10'), findsOneWidget);
    final series = await db.select(db.sessions).getSingle();
    for (final q in jsonDecode(series.questionData) as List) {
      expect(
        levelForDifficulty((q as Map)['difficulty'] as String),
        LearningDifficulty.easy,
      );
    }
    expect(await db.select(db.attempts).get(), isEmpty);
    expect(await db.select(db.memoryReviews).get(), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'mieszana wyprawa zapisuje dopiero po zatwierdzeniu i wznawia feedback',
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
      final question = data.$2.questions(['POL'], Random(3)).single;
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await db.close();
      });
      await db
          .into(db.sessions)
          .insert(
            SessionsCompanion.insert(
              id: 'daily-flow',
              countryIds: '["POL","DEU"]',
              createdAt: DateTime.now(),
              topic: const Value('daily'),
              difficulty: const Value('mixed'),
              questionData: Value(
                jsonEncode([
                  {
                    ...question.toJson(),
                    'topic': 'capitals',
                    'difficulty': 'write',
                    'skill_id': 'capitals:POL:write',
                    'country_id': 'POL',
                  },
                  {
                    'topic': 'map',
                    'difficulty': 'map',
                    'skill_id': 'map:DEU:map',
                    'country_id': 'DEU',
                  },
                ]),
              ),
            ),
          );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            catalogProvider.overrideWith((ref) async => data.$1),
            capitalsProvider.overrideWith((ref) async => data.$2),
            flagsProvider.overrideWith((ref) async => data.$3),
          ],
          child: const GeoKunaApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wznów wyprawę'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Warszawa');
      await tester.pump();
      expect(await db.select(db.memoryReviews).get(), isEmpty);
      await tester.ensureVisible(find.text('Sprawdź odpowiedź'));
      await tester.tap(find.text('Sprawdź odpowiedź'));
      await tester.pumpAndSettle();
      expect(await db.select(db.memoryReviews).get(), hasLength(1));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wznów wyprawę'));
      await tester.pumpAndSettle();
      expect(find.text('Następne pytanie'), findsOneWidget);
      expect(await db.select(db.memoryReviews).get(), hasLength(1));
      await tester.ensureVisible(find.text('Następne pytanie'));
      await tester.tap(find.text('Następne pytanie'));
      await tester.pumpAndSettle();
      expect(find.text('Pytanie 2 z 2'), findsOneWidget);
      expect(find.text('Gdzie leżą Niemcy?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
