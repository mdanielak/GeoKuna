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
      assetPath: 'assets/v2/kuna_neutral.webp',
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
      assetPath: 'assets/v2/kuna_happy.webp',
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
      assetPath: 'assets/v2/kuna_sad.webp',
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
      assetPath: 'assets/v2/kuna_thinking.webp',
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
      assetPath: 'assets/v2/kuna_wink.webp',
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
      accessibilityLabel: 'Kuna jest wesoła, zaciska pięść i gratuluje.',
      assetPath: 'assets/v2/kuna_determined.webp',
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
    assetPath: 'assets/v2/kuna_love.webp',
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scheme = Theme.of(context).colorScheme;
          final fill = scheme.surfaceContainerLowest;
          final edge = scheme.outlineVariant;
          final picture = SizedBox(
            width: 128,
            height: 140,
            child: Image.asset(
              feedback.assetPath,
              fit: BoxFit.contain,
              cacheWidth: 312,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                'assets/v2/kuna_neutral.webp',
                fit: BoxFit.contain,
                cacheWidth: 312,
              ),
            ),
          );
          // A real speech bubble: white, outlined, large friendly text.
          final bubble = Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: fill,
              border: Border.all(color: edge, width: 1.5),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              feedback.message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          );
          // Large text on a narrow screen: the bubble goes below the kuna,
          // so words never break mid-word beside her.
          if (constraints.maxWidth - 138 <
              MediaQuery.textScalerOf(context).scale(22) * 8) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(alignment: Alignment.centerLeft, child: picture),
                const SizedBox(height: 8),
                bubble,
              ],
            );
          }
          // The kuna speaks: her picture with a speech bubble beside it.
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              picture,
              Expanded(
                child: CustomPaint(
                  foregroundPainter: _BubbleTail(fill, edge),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: bubble,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

/// Small outlined triangle on the bubble's left edge, pointing at the kuna.
/// Painted over the bubble so it covers the bubble's border where they meet.
class _BubbleTail extends CustomPainter {
  const _BubbleTail(this.fill, this.edge);
  final Color fill, edge;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    final tip = Offset(0, mid);
    final top = Offset(12, mid - 9), bottom = Offset(12, mid + 9);
    canvas
      ..drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(top.dx + 1.5, top.dy)
          ..lineTo(bottom.dx + 1.5, bottom.dy)
          ..close(),
        Paint()..color = fill,
      )
      ..drawPath(
        Path()
          ..moveTo(top.dx, top.dy)
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(bottom.dx, bottom.dy),
        Paint()
          ..color = edge
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round,
      );
  }

  @override
  bool shouldRepaint(_BubbleTail oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.edge != edge;
}
