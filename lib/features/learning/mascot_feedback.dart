import 'package:material_ui/material_ui.dart';

enum QuizMascotMood { neutral, happy, sad, thoughtful, encouraging, heart }

class QuizMascotFeedback {
  const QuizMascotFeedback({
    required this.mood,
    required this.message,
    required this.accessibilityLabel,
    required this.assetPath,
  });

  final QuizMascotMood mood;
  final String message;
  final String accessibilityLabel;
  final String assetPath;
}

/// Chooses supportive feedback from the exact ratio of scored first attempts.
QuizMascotFeedback quizMascotFeedback({
  required bool completedAllQuestions,
  required bool choiceOnly,
  required int scoredAttempts,
  required int correctCount,
  String seed = '',
}) {
  if (!completedAllQuestions) {
    return QuizMascotFeedback(
      mood: QuizMascotMood.neutral,
      message: _message(seed, const [
        'Każda wyprawa może poczekać. Kuna trzyma za Ciebie kciuki!',
        'Zrób spokojnie przerwę. Wrócimy do nauki, kiedy zechcesz.',
        'Odpocznij chwilę. Czeka nas jeszcze wiele ciekawych miejsc!',
      ]),
      accessibilityLabel: 'Kuna odpoczywa.',
      assetPath: 'assets/mascot/kuna-globe.png',
    );
  }

  if (choiceOnly ||
      scoredAttempts <= 0 ||
      correctCount < 0 ||
      correctCount > scoredAttempts) {
    return QuizMascotFeedback(
      mood: QuizMascotMood.happy,
      message: _message(seed, const [
        'Dzięki za wspólny trening! Fajnie poznawać świat razem.',
        'Dzięki za trening! Fajnie poznawać świat razem.',
        'Świetnie, że ćwiczysz! Wiedza rośnie z każdą wyprawą.',
      ]),
      accessibilityLabel: 'Kuna jest wesoła.',
      assetPath: 'assets/mascot/kuna-happy.png',
    );
  }

  if (correctCount * 100 <= scoredAttempts * 30) {
    return QuizMascotFeedback(
      mood: QuizMascotMood.sad,
      message: _message(seed, const [
        'Spokojnie, od tego są powtórki. Dasz radę!',
        'Pomyłki pokazują, co warto powtórzyć. Spróbujemy jeszcze raz!',
        'Każda wyprawa czegoś uczy. Następnym razem pójdzie łatwiej!',
      ]),
      accessibilityLabel: 'Kuna jest lekko zasmucona i wspiera w nauce.',
      assetPath: 'assets/mascot/kuna-sad.png',
    );
  }

  if (correctCount * 100 <= scoredAttempts * 45) {
    return QuizMascotFeedback(
      mood: QuizMascotMood.thoughtful,
      message: _message(seed, const [
        'Już wiemy, co warto jeszcze poćwiczyć. Ruszajmy dalej!',
        'Dobra wyprawa! Kilka powtórek i będzie coraz łatwiej.',
        'Masz już pierwsze odpowiedzi. Kuna pomoże utrwalić kolejne!',
      ]),
      accessibilityLabel: 'Kuna jest zamyślona i zachęca do dalszej nauki.',
      assetPath: 'assets/mascot/kuna-thoughtful.png',
    );
  }

  if (correctCount * 100 <= scoredAttempts * 60) {
    return QuizMascotFeedback(
      mood: QuizMascotMood.encouraging,
      message: _message(seed, const [
        'Coraz lepiej! Utrwalmy to, co już umiesz.',
        'Świetnie Ci idzie — jeszcze trochę i mapa nie będzie miała tajemnic!',
        'Brawo! Każda poprawna odpowiedź dodaje Ci geograficznej mocy!',
      ]),
      accessibilityLabel: 'Kuna zachęcająco mruga i dopinguje.',
      assetPath: 'assets/mascot/kuna-encouraging.png',
    );
  }

  if (correctCount < scoredAttempts) {
    return QuizMascotFeedback(
      mood: QuizMascotMood.happy,
      message: _message(seed, const [
        'Świetna wyprawa! Każda powtórka pomaga pamiętać.',
        'Brawo! Naprawdę dobrze znasz już ten kawałek świata!',
        'Ależ przygoda! Tak dobrze wskazujesz drogę na mapie!',
      ]),
      accessibilityLabel: 'Kuna jest wesoła i gratuluje.',
      assetPath: 'assets/mascot/kuna-happy-v2.png',
    );
  }

  return QuizMascotFeedback(
    mood: QuizMascotMood.heart,
    message: _message(seed, const [
      'Komplet odpowiedzi! Ogromne serduszko dla Ciebie!',
      'Sto procent! Kuna jest z Ciebie bardzo dumna!',
      'Wszystko poprawnie! Wysyłam Ci geograficzne serduszko!',
    ]),
    accessibilityLabel: 'Kuna daje serduszko i gratuluje kompletu.',
    assetPath: 'assets/mascot/kuna-heart.png',
  );
}

String _message(String seed, List<String> messages) {
  var hash = 0x811c9dc5;
  for (final unit in seed.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  return messages[hash % messages.length];
}

class QuizMascotFeedbackView extends StatelessWidget {
  const QuizMascotFeedbackView({required this.feedback, super.key});

  final QuizMascotFeedback feedback;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    label: '${feedback.accessibilityLabel} ${feedback.message}',
    child: ExcludeSemantics(
      child: Column(
        children: [
          SizedBox(
            height: 120,
            width: double.infinity,
            child: Image.asset(
              feedback.assetPath,
              fit: BoxFit.contain,
              cacheWidth: 384,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                'assets/mascot/kuna-globe.png',
                fit: BoxFit.contain,
                cacheWidth: 384,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            feedback.message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    ),
  );
}
