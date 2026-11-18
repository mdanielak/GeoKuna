import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';

class AnswerFeedback extends StatelessWidget {
  const AnswerFeedback({
    super.key,
    required this.correct,
    required this.typoAccepted,
    required this.answer,
    required this.solution,
    this.note = '',
    this.subject = 'Stolica',
  });
  final bool correct, typoAccepted;
  final String answer, solution, note, subject;
  Widget _block(
    String key,
    Color background,
    Color foreground,
    IconData icon,
    String text,
  ) => Container(
    key: ValueKey(key),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: foreground),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: TextStyle(color: foreground)),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final colors = GeoColors.of(context);
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (typoAccepted) ...[
            _block(
              'answer-feedback-typo',
              colors.typoContainer,
              colors.onTypoContainer,
              Icons.spellcheck,
              'Dobrze — literówka zaakceptowana.\nTwoja odpowiedź: $answer',
            ),
            const SizedBox(height: 8),
          ] else if (!correct) ...[
            _block(
              'answer-feedback-wrong',
              colors.wrongContainer,
              colors.onWrongContainer,
              Icons.cancel_outlined,
              'Błędna odpowiedź.\nTwoja odpowiedź: $answer',
            ),
            const SizedBox(height: 8),
          ],
          _block(
            'answer-feedback-correct',
            colors.correctContainer,
            colors.onCorrectContainer,
            Icons.check_circle_outline,
            typoAccepted
                ? 'Poprawna pisownia: $solution.'
                : correct
                ? 'Dobrze! $subject: $solution.'
                : 'Poprawna odpowiedź: $solution.',
          ),
          if (correct && !typoAccepted)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Twoja odpowiedź: $answer'),
            ),
          if (note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Card.filled(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(note)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
