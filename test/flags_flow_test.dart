import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/app/providers.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/learning/flags.dart';
import 'package:geokuna/features/learning/learning_screen.dart';
import 'package:geokuna/features/learning/capitals.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  for (final mode in FlagDifficulty.values) {
    testWidgets('flag ${mode.name}: offline question and independent memory', (
      tester,
    ) async {
      tester.view.physicalSize = mode == FlagDifficulty.write
          ? const Size(320, 640)
          : const Size(390, 844);
      if (mode == FlagDifficulty.write) {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      }
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = (await tester.runAsync(
        () async => (
          await Catalog.load(),
          await FlagCatalog.load(),
          await CapitalCatalog.load(),
        ),
      ))!;
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await db.close();
      });
      final question = data.$2.questions(['POL'], Random(2)).single;
      await db
          .into(db.sessions)
          .insert(
            SessionsCompanion.insert(
              id: 'flags-flow',
              countryIds: '["POL"]',
              createdAt: DateTime.now(),
              topic: const Value('flags'),
              difficulty: Value(mode.name),
              contentVersion: Value(data.$2.version),
              questionData: Value(jsonEncode([question.toJson()])),
            ),
          );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            catalogProvider.overrideWith((ref) async => data.$1),
            flagsProvider.overrideWith((ref) async => data.$2),
            capitalsProvider.overrideWith((ref) async => data.$3),
          ],
          child: MaterialApp(home: LearningScreen(flagDifficulty: mode)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Flaga do rozpoznania'), findsOneWidget);
      if (mode == FlagDifficulty.map) {
        expect(find.text('Polska'), findsNothing);
        final layer = find.byType(PolygonLayer<String>);
        final camera = MapCamera.of(tester.element(layer));
        await tester.tapAt(
          tester.getTopLeft(find.byType(FlutterMap)) +
              camera.latLngToScreenOffset(data.$1.country('POL').center),
        );
      } else if (mode == FlagDifficulty.choice) {
        final index = question.options.indexOf('Polska');
        await tester.tap(
          find.text('${String.fromCharCode(65 + index)}. Polska'),
        );
        await tester.pump();
        await tester.ensureVisible(find.text('Sprawdź odpowiedź'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sprawdź odpowiedź'));
      } else {
        await tester.ensureVisible(find.byType(TextFormField));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField),
          mode == FlagDifficulty.firstLetter ? 'olska' : 'Polsqa',
        );
        await tester.pump();
        await tester.ensureVisible(find.text('Sprawdź odpowiedź'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sprawdź odpowiedź'));
      }
      await tester.pumpAndSettle();
      final attempt = (await db.select(db.attempts).get()).single;
      expect(attempt.topic, 'flags');
      expect(attempt.correct, isTrue);
      expect(
        (await db.select(db.memoryReviews).get()).single.skillId,
        'flags:POL:${mode.name}',
      );
      final other = await (db.select(
        db.memoryCards,
      )..where((c) => c.id.equals('map:POL:map'))).getSingleOrNull();
      expect(other?.state, isNull);
      if (mode == FlagDifficulty.write) {
        expect(
          find.byKey(const ValueKey('answer-feedback-typo')),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
}
