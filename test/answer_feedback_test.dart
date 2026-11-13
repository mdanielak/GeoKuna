import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/features/learning/answer_feedback.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'wrong, correct and typo retain text and distinct accessible colors',
    (tester) async {
      Future<void> show(bool correct, bool typo) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnswerFeedback(
                correct: correct,
                typoAccepted: typo,
                answer: 'Warszaqa',
                solution: 'Warszawa',
              ),
            ),
          ),
        );
      }

      Color color(String key) =>
          (tester.widget<Container>(find.byKey(ValueKey(key))).decoration
                  as BoxDecoration)
              .color!;
      await show(false, false);
      final red = color('answer-feedback-wrong');
      final green = color('answer-feedback-correct');
      expect(red.r, greaterThan(red.g));
      expect(green.g, greaterThan(green.r));
      expect(find.textContaining('Błędna odpowiedź'), findsOneWidget);
      expect(find.text('Poprawna odpowiedź: Warszawa.'), findsOneWidget);
      await show(true, true);
      final yellow = color('answer-feedback-typo');
      expect(yellow.r, greaterThan(yellow.b));
      expect(yellow.g, greaterThan(yellow.b));
      expect(find.textContaining('literówka zaakceptowana'), findsOneWidget);
      expect(find.byKey(const ValueKey('answer-feedback-wrong')), findsNothing);
      await show(true, false);
      expect(
        find.byKey(const ValueKey('answer-feedback-correct')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('answer-feedback-typo')), findsNothing);
    },
  );
}
