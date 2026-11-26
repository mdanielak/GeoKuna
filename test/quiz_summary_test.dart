import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/app/providers.dart';
import 'package:geokuna/app/theme.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/atlas/continent.dart';
import 'package:geokuna/features/learning/capitals.dart';
import 'package:geokuna/features/learning/learning_session.dart';
import 'package:geokuna/features/learning/streaks.dart';
import 'package:geokuna/features/learning/widgets/quiz_summary_view.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'QuizSummaryView shows yellow icon for practice errors, map category labels, and fits 320x640 at 2x scale',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final (catalog, capitals) = (await tester.runAsync(
        () async => (await Catalog.load(), await CapitalCatalog.load()),
      ))!;
      final fraQuestion = capitals.questions(['FRA'], Random(1)).single;
      final now = DateTime.utc(2026, 11, 26, 10);

      final session = LearningSession(
        Session(
          id: 'summary-test',
          countryIds: '["POL","DEU","FRA"]',
          currentIndex: 2,
          createdAt: now,
          completedAt: now,
          continent: Continent.europe.name,
          topic: 'daily',
          difficulty: 'mixed',
          questionData: jsonEncode([
            {
              'topic': 'map',
              'difficulty': 'map',
              'skill_id': 'map:POL:map',
              'country_id': 'POL',
            },
            {
              'topic': 'map',
              'difficulty': 'map',
              'skill_id': 'map:DEU:map',
              'country_id': 'DEU',
            },
            {
              ...fraQuestion.toJson(),
              'topic': 'capitals',
              'difficulty': 'write',
              'skill_id': 'capitals:FRA:write',
              'country_id': 'FRA',
              'retry': true,
            },
          ]),
          contentVersion: 'test',
        ),
        const ['POL', 'DEU', 'FRA'],
        [
          Attempt(
            sessionId: 'summary-test',
            questionIndex: 0,
            countryId: 'POL',
            answer: 'POL',
            correct: true,
            typoAccepted: false,
            topic: 'map',
            difficulty: 'map',
            answeredAt: now,
          ),
          Attempt(
            sessionId: 'summary-test',
            questionIndex: 1,
            countryId: 'DEU',
            answer: 'AUT',
            correct: false,
            typoAccepted: false,
            topic: 'map',
            difficulty: 'map',
            answeredAt: now,
          ),
          Attempt(
            sessionId: 'summary-test',
            questionIndex: 2,
            countryId: 'FRA',
            answer: 'Lyon',
            correct: false,
            typoAccepted: false,
            topic: 'capitals',
            difficulty: 'write',
            answeredAt: now,
          ),
        ],
        mapGuesses: [
          MapGuess(
            sessionId: 'summary-test',
            questionIndex: 0,
            guessIndex: 0,
            selectedCountryId: 'POL',
            correct: true,
            assisted: false,
            guessedAt: now,
          ),
          MapGuess(
            sessionId: 'summary-test',
            questionIndex: 1,
            guessIndex: 0,
            selectedCountryId: 'AUT',
            correct: false,
            assisted: false,
            guessedAt: now,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            streakProvider.overrideWith(
              (ref) async => const StreakSummary(
                current: 0,
                best: 0,
                practisedToday: false,
                tokens: 0,
              ),
            ),
          ],
          child: MaterialApp(
            theme: GeoTheme.light(),
            home: Scaffold(
              body: QuizSummaryView(
                catalog: catalog,
                session: session,
                daily: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text(
          'Ćwiczenia w serii (powtórki i pary): 1 — nie liczą się do wyniku.',
        ),
        200,
      );
      expect(
        find.text(
          'Ćwiczenia w serii (powtórki i pary): 1 — nie liczą się do wyniku.',
        ),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(find.text('mapa · od razu'), 200);
      expect(find.text('mapa · od razu'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('mapa · nie odnaleziono'), 200);
      expect(find.text('mapa · nie odnaleziono'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('powtórka'), 200);
      expect(find.text('powtórka'), findsOneWidget);
      expect(find.text(fraQuestion.fact.name), findsOneWidget);
      // 1 scored wrong (DEU -> cancel), 1 practice wrong (FRA -> replay_circle_filled).
      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.byIcon(Icons.replay_circle_filled), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
