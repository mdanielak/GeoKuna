import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/atlas/continent.dart';
import 'package:geokuna/features/learning/auto_level.dart';
import 'package:geokuna/features/learning/capitals.dart';
import 'package:geokuna/features/learning/flags.dart';
import 'package:geokuna/features/learning/learning_session.dart';
import 'package:geokuna/features/learning/widgets/text_quiz_view.dart';
import 'package:geokuna/features/settings/app_preferences.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('stepAutoLevel state machine', () {
    test('3 consecutive misses demote normal -> easy -> veryEasy and cap at veryEasy', () {
      var state = const AutoLevelState.initial();
      for (var i = 0; i < 2; i++) {
        final t = stepAutoLevel(state, correct: false);
        expect(t.event, isNull);
        expect(t.next.level, LearningDifficulty.normal);
        expect(t.next.missStreak, i + 1);
        expect(t.next.dueNow, isFalse);
        state = t.next;
      }

      final toEasy = stepAutoLevel(state, correct: false);
      expect(toEasy.event, AutoLevelEvent.demoted);
      expect(toEasy.next.level, LearningDifficulty.easy);
      expect(toEasy.next.missStreak, 0);
      expect(toEasy.next.hitStreak, 0);
      expect(toEasy.next.dueNow, isTrue);
      state = toEasy.next;

      for (var i = 0; i < 2; i++) {
        state = stepAutoLevel(state, correct: false).next;
        expect(state.level, LearningDifficulty.easy);
      }

      final toVeryEasy = stepAutoLevel(state, correct: false);
      expect(toVeryEasy.event, AutoLevelEvent.demoted);
      expect(toVeryEasy.next.level, LearningDifficulty.veryEasy);
      expect(toVeryEasy.next.dueNow, isTrue);

      var floored = toVeryEasy.next;
      for (var i = 0; i < 4; i++) {
        final stays = stepAutoLevel(floored, correct: false);
        expect(stays.event, isNull);
        expect(stays.next.level, LearningDifficulty.veryEasy);
        expect(stays.next.dueNow, isFalse);
        floored = stays.next;
      }
    });

    test(
      '2 consecutive hits climb veryEasy -> easy -> normal and cap at normal',
      () {
        var state = const AutoLevelState(
          level: LearningDifficulty.veryEasy,
          dueNow: true,
        );
        final hit1 = stepAutoLevel(state, correct: true);
        expect(hit1.event, isNull);
        expect(hit1.next.level, LearningDifficulty.veryEasy);
        expect(hit1.next.hitStreak, 1);
        expect(hit1.next.dueNow, isFalse);

        // A miss resets the hit streak before promotion completes.
        state = stepAutoLevel(hit1.next, correct: false).next;
        expect(state.hitStreak, 0);
        expect(state.missStreak, 1);

        state = stepAutoLevel(state, correct: true).next;
        final toEasy = stepAutoLevel(state, correct: true);
        expect(toEasy.event, AutoLevelEvent.promoted);
        expect(toEasy.next.level, LearningDifficulty.easy);
        expect(toEasy.next.hitStreak, 0);
        expect(toEasy.next.missStreak, 0);

        final easyHit1 = stepAutoLevel(toEasy.next, correct: true);
        expect(easyHit1.event, isNull);
        expect(easyHit1.next.hitStreak, 1);

        final toNormal = stepAutoLevel(easyHit1.next, correct: true);
        expect(toNormal.event, AutoLevelEvent.promoted);
        expect(toNormal.next.level, LearningDifficulty.normal);

        final capped = stepAutoLevel(
          stepAutoLevel(toNormal.next, correct: true).next,
          correct: true,
        );
        expect(capped.event, isNull);
        expect(capped.next.level, LearningDifficulty.normal);
      },
    );
  });

  group('Automatyczny UI badges & notices', () {
    late Catalog catalog;
    late CapitalCatalog capitals;
    late FlagCatalog flags;
    setUpAll(() async {
      catalog = await Catalog.load();
      capitals = await CapitalCatalog.load();
      flags = await FlagCatalog.load();
    });

    Widget wrapQuiz(LearningSession session, {Attempt? attempt}) =>
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TextQuizView(
                catalog: catalog,
                session: session,
                attempt: attempt,
                busy: false,
                questionLabel: 'Pytanie 1 z 2',
                trivia: null,
                onSubmit: ({
                  required selected,
                  required typed,
                  gaveUp = false,
                }) {},
              ),
            ),
          ),
        );

    testWidgets(
      'shows Łatwiej with country name on capitals, without spoiler on flags',
      (tester) async {
        final pol = catalog.country('POL');
        final capitalQuestion = capitals.questions(['POL'], Random(1)).single;
        final flagQuestion = flags.questions(['POL'], Random(1)).single;
        final now = DateTime.utc(2026, 11, 26, 10);
        final capitalSession = LearningSession(
          Session(
            id: 'auto-ui-cap',
            countryIds: '["POL"]',
            currentIndex: 0,
            createdAt: now,
            continent: Continent.europe.name,
            topic: 'daily',
            difficulty: 'mixed',
            questionData: jsonEncode([
              {
                ...capitalQuestion.toJson(),
                'topic': 'capitals',
                'difficulty': 'firstLetter',
                'skill_id': 'capitals:POL:firstLetter',
                'country_id': 'POL',
                'auto': true,
                'auto_easier': true,
              },
            ]),
            contentVersion: 'test',
          ),
          const ['POL'],
          const [],
        );
        await tester.pumpWidget(wrapQuiz(capitalSession));
        expect(find.text('Łatwiej: ${pol.name}'), findsOneWidget);

        final flagSession = LearningSession(
          Session(
            id: 'auto-ui-flag',
            countryIds: '["POL"]',
            currentIndex: 0,
            createdAt: now,
            continent: Continent.europe.name,
            topic: 'daily',
            difficulty: 'mixed',
            questionData: jsonEncode([
              {
                ...flagQuestion.toJson(),
                'topic': 'flags',
                'difficulty': 'firstLetter',
                'skill_id': 'flags:POL:firstLetter',
                'country_id': 'POL',
                'auto': true,
                'auto_easier': true,
              },
            ]),
            contentVersion: 'test',
          ),
          const ['POL'],
          const [],
        );
        await tester.pumpWidget(wrapQuiz(flagSession));
        expect(find.text('Łatwiej'), findsOneWidget);
        expect(find.textContaining('Łatwiej: ${pol.name}'), findsNothing);
      },
    );

    testWidgets('renders autoNotice in feedback even on a retry question', (
      tester,
    ) async {
      final capitalQuestion = capitals.questions(['POL'], Random(1)).single;
      final now = DateTime.utc(2026, 11, 26, 10);
      final attempt = Attempt(
        sessionId: 'auto-ui-retry',
        questionIndex: 0,
        countryId: 'POL',
        answer: 'Kraków',
        correct: false,
        typoAccepted: false,
        topic: 'capitals',
        difficulty: 'write',
        answeredAt: now,
      );
      final retrySession = LearningSession(
        Session(
          id: 'auto-ui-retry',
          countryIds: '["POL"]',
          currentIndex: 0,
          createdAt: now,
          continent: Continent.europe.name,
          topic: 'daily',
          difficulty: 'mixed',
          questionData: jsonEncode([
            {
              ...capitalQuestion.toJson(),
              'topic': 'capitals',
              'difficulty': 'write',
              'skill_id': 'capitals:POL:write',
              'country_id': 'POL',
              'auto': true,
              'retry': true,
            },
          ]),
          contentVersion: 'test',
        ),
        const ['POL'],
        [attempt],
        insight: const QuestionInsight(
          recovery: 1,
          autoNotice: 'Następnym razem łatwiej.',
        ),
      );
      await tester.pumpWidget(wrapQuiz(retrySession, attempt: attempt));
      expect(find.text('Następnym razem łatwiej.'), findsOneWidget);
      expect(find.textContaining('1 z 3'), findsNothing);
    });
  });
}
