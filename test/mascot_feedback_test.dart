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
    const sad = 'assets/v2/kuna_sad.webp';
    const thoughtful = 'assets/v2/kuna_thinking.webp';
    const encouraging = 'assets/v2/kuna_wink.webp';
    const happy = 'assets/v2/kuna_determined.webp';
    const heart = 'assets/v2/kuna_love.webp';
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
    expect(partial.assetPath, 'assets/v2/kuna_neutral.webp');
    final choice = quizMascotFeedback(
      completedAllQuestions: true,
      choiceOnly: true,
      scoredAttempts: 1,
      correctCount: 1,
    );
    expect(choice.assetPath, isNot('assets/v2/kuna_love.webp'));
    expect(choice.message, contains('trening'));
  });
}
