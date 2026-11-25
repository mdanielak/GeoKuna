import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/database/database.dart';
import '../../atlas/catalog.dart';
import '../answer_feedback.dart';
import '../country_trivia.dart';
import '../learning_session.dart';
import 'map_quiz_view.dart';
import 'quiz_shared_widgets.dart';

class TextQuizView extends ConsumerStatefulWidget {
  const TextQuizView({
    super.key,
    required this.catalog,
    required this.session,
    required this.attempt,
    required this.busy,
    required this.questionLabel,
    required this.trivia,
    required this.onSubmit,
  });

  final Catalog catalog;
  final LearningSession session;
  final Attempt? attempt;
  final bool busy;
  final String questionLabel;
  final CountryTriviaFact? trivia;
  final void Function({
    required String? selected,
    required String typed,
    bool gaveUp,
  })
  onSubmit;

  @override
  ConsumerState<TextQuizView> createState() => _TextQuizViewState();
}

class _TextQuizViewState extends ConsumerState<TextQuizView> {
  final _controller = TextEditingController();
  String? _selected;

  /// Choice in the A–D practice after „Nie wiem, pomóż” (never saved).
  String? _practicePick;

  @override
  void didUpdateWidget(TextQuizView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.row.id != widget.session.row.id ||
        oldWidget.session.index != widget.session.index) {
      _controller.clear();
      _selected = null;
      _practicePick = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      widget.attempt != null ||
      (widget.session.difficultyNameAt(widget.session.index) == 'choice'
          ? _selected != null
          : _controller.text.trim().isNotEmpty);

  void _submit({bool gaveUp = false}) {
    if (widget.busy || (!gaveUp && !_canSubmit)) return;
    widget.onSubmit(
      selected: _selected,
      typed: gaveUp ? '' : _controller.text,
      gaveUp: gaveUp,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final attempt = widget.attempt;
    final flag = session.isFlagAt(session.index);
    final question = flag ? null : session.capitalQuestionAt(session.index);
    const defaultPrompt = 'Jaka jest stolica tego państwa?';
    final progress =
        (session.index + (attempt != null ? 1 : 0)) / session.countryIds.length;
    // After „Nie wiem, pomóż” notes and facts wait for the A–D choice:
    // they could give the answer away.
    final revealed =
        attempt != null && (!session.gaveUpCurrent || _practicePick != null);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.questionLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 20),
                    if (flag) ...[
                      Center(
                        child: FlagFrame(
                          assetPath: session
                              .flagQuestionAt(session.index)
                              .assetPath,
                          semanticLabel:
                              '${ref.watch(selectedContinentProvider).symbolLabel} do rozpoznania',
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        widget.catalog.continent.symbolQuestion,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ] else ...[
                      Text(
                        _capitalized(
                          widget.catalog.country(session.targetId).questionName,
                        ),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        question!.fact.prompt == defaultPrompt
                            ? widget.catalog.continent.capitalPrompt
                            : question.fact.prompt,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w400),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (attempt == null) _capitalInput(session),
                    if (attempt != null && session.gaveUpCurrent)
                      _gaveUpPractice(session)
                    else if (attempt != null)
                      AnswerFeedback(
                        correct: attempt.correct,
                        typoAccepted: attempt.typoAccepted,
                        answer: attempt.answer,
                        solution: flag
                            ? session.flagQuestionAt(session.index).countryName
                            : question!.fact.name,
                        note: flag ? '' : question!.fact.note,
                        subject: flag
                            ? widget.catalog.continent.areaSubject
                            : widget.catalog.continent.capitalSubject,
                      ),
                    if (revealed)
                      InsightNote(catalog: widget.catalog, session: session),
                    if (revealed && widget.trivia != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: TriviaCard(text: widget.trivia!.text),
                      ),
                  ],
                ),
              ),
            ),
            // Pinned above the soft keyboard and bottom inset so the main CTA
            // stays reachable one-handed at any scroll position.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, _, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton(
                      onPressed: widget.busy || !_canSubmit ? null : _submit,
                      child: Text(
                        widget.busy
                            ? 'Zapisuję…'
                            : attempt == null
                            ? 'Sprawdź odpowiedź'
                            : session.index == session.countryIds.length - 1
                            ? 'Zobacz wynik'
                            : 'Następne pytanie',
                      ),
                    ),
                    if (attempt == null &&
                        session.difficultyNameAt(session.index) !=
                            'choice') ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: GeoColors.of(context).wrong,
                          side: BorderSide(
                            color: GeoColors.of(context).wrong
                                .withValues(alpha: .45),
                            width: 1.5,
                          ),
                          minimumSize: const Size(48, 48),
                        ),
                        onPressed: widget.busy
                            ? null
                            : () => _submit(gaveUp: true),
                        child: const Text('Nie wiem, pomóż'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// After „Nie wiem, pomóż”: the same question as unscored A–D practice.
  Widget _gaveUpPractice(LearningSession session) {
    final flag = session.isFlagAt(session.index);
    final options = flag
        ? session.flagQuestionAt(session.index).options
        : session.capitalQuestionAt(session.index).options;
    final solution = flag
        ? session.flagQuestionAt(session.index).countryName
        : session.capitalQuestionAt(session.index).fact.name;
    final note = flag ? '' : session.capitalQuestionAt(session.index).fact.note;
    final subject = flag
        ? widget.catalog.continent.areaSubject
        : widget.catalog.continent.capitalSubject;
    final colors = GeoColors.of(context);
    final pick = _practicePick;
    final right = pick == solution;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Wybierz poprawną odpowiedź:'),
        const SizedBox(height: 12),
        ChoiceOptionList(
          options: options,
          selected: pick,
          enabled: pick == null,
          onChanged: (value) {
            if (pick == null) setState(() => _practicePick = value);
          },
        ),
        if (pick != null) ...[
          Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: right ? colors.correctContainer : colors.wrongContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    right ? Icons.check_circle_outline : Icons.cancel_outlined,
                    color: right
                        ? colors.onCorrectContainer
                        : colors.onWrongContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      right
                          ? 'Dobrze! $subject: $solution.'
                          : 'Poprawna odpowiedź: $solution.',
                      style: TextStyle(
                        color: right
                            ? colors.onCorrectContainer
                            : colors.onWrongContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
      ],
    );
  }

  Widget _capitalInput(LearningSession session) {
    final flag = session.isFlagAt(session.index);
    final options = flag
        ? session.flagQuestionAt(session.index).options
        : session.capitalQuestionAt(session.index).options;
    final firstLetter = flag
        ? session.flagQuestionAt(session.index).firstLetter
        : session.capitalQuestionAt(session.index).fact.firstLetter;
    final difficulty = session.difficultyNameAt(session.index);
    if (difficulty == 'choice') {
      return ChoiceOptionList(
        options: options,
        selected: _selected,
        enabled: !widget.busy,
        boldSelected: true,
        onChanged: (value) {
          if (!widget.busy) setState(() => _selected = value);
        },
      );
    }
    final hint = difficulty == 'firstLetter';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hint
              ? 'Pierwsza litera: $firstLetter. Dopisz pozostałe litery.'
              : flag
              ? 'Wpisz całą nazwę ${widget.catalog.continent.areaGenitive}.'
              : 'Wpisz całą nazwę ${widget.catalog.continent.capitalGenitive}.',
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: ValueKey('capital-input-${session.row.id}-${session.index}'),
          controller: _controller,
          enabled: !widget.busy,
          maxLength: 100,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: hint
              ? TextCapitalization.none
              : TextCapitalization.words,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            counterText: '',
            labelText: hint
                ? 'Pozostałe litery'
                : flag
                ? 'Nazwa ${widget.catalog.continent.areaGenitive}'
                : 'Nazwa ${widget.catalog.continent.capitalGenitive}',
            prefixIcon: hint
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      firstLetter,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                : null,
          ),
          onFieldSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 12),
        const Text(
          'Dopuszczamy jedną literówkę; polskie znaki nie są wymagane.',
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => showAnswerRulesDialog(context),
            child: const Text('Jak sprawdzamy odpowiedzi?'),
          ),
        ),
      ],
    );
  }
}

String _capitalized(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
