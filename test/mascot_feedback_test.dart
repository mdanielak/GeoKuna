import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/features/learning/mascot_feedback.dart';

void main() {
  QuizMascotFeedback scored(int correct, int total, {String seed = ''}) =>
      quizMascotFeedback(
        completedAllQuestions: true,
        choiceOnly: false,
        scoredAttempts: total,
        correctCount: correct,
        seed: seed,
      );

  test('approved bands for 10 and 5 questions, heart only at 100%', () {
    const sad = 'assets/mascot/kuna-sad.png';
    const thoughtful = 'assets/mascot/kuna-thoughtful.png';
    const encouraging = 'assets/mascot/kuna-encouraging.png';
    const happy = 'assets/mascot/kuna-happy-v2.png';
    const heart = 'assets/mascot/kuna-heart.png';
    const expected = <int, List<String>>{
      10: [
        sad,
        sad,
        sad,
        sad,
        thoughtful,
        encouraging,
        encouraging,
        happy,
        happy,
        happy,
        heart,
      ],
      5: [sad, sad, thoughtful, encouraging, happy, heart],
    };
    for (final entry in expected.entries) {
      for (var correct = 0; correct < entry.value.length; correct++) {
        expect(
          scored(correct, entry.key).assetPath,
          entry.value[correct],
          reason: '$correct / ${entry.key}',
        );
      }
    }
    expect(scored(249, 250).assetPath, happy, reason: 'no rounding up');
    for (final (total, correct) in [(0, 0), (1, 2), (-1, -1)]) {
      expect(scored(correct, total).assetPath, isNot(heart));
    }
  });

  test('each mood has three stable supportive messages', () {
    for (final correct in [1, 4, 6, 9, 10]) {
      final messages = {
        for (var i = 0; i < 20; i++) scored(correct, 10, seed: 's$i').message,
      };
      expect(messages, hasLength(3), reason: '$correct / 10');
      expect(
        scored(correct, 10, seed: 's7').message,
        scored(correct, 10, seed: 's7').message,
      );
    }
    final low = scored(1, 10);
    expect(low.message, isNot(contains('poraż')));
    expect(low.message, isNot(contains('musisz')));
  });

  test('interrupted and A–D-only sessions get no score-based mood', () {
    final partial = quizMascotFeedback(
      completedAllQuestions: false,
      choiceOnly: false,
      scoredAttempts: 1,
      correctCount: 0,
    );
    expect(partial.mood, QuizMascotMood.neutral);
    expect(partial.assetPath, 'assets/mascot/kuna-globe.png');
    final choice = quizMascotFeedback(
      completedAllQuestions: true,
      choiceOnly: true,
      scoredAttempts: 1,
      correctCount: 1,
    );
    expect(choice.assetPath, isNot('assets/mascot/kuna-heart.png'));
    expect(choice.message, contains('trening'));
  });
}
