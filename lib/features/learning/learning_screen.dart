import '../settings/app_preferences.dart';
import 'country_trivia.dart';
import 'memory.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/database/database.dart';
import '../atlas/catalog.dart';
import '../atlas/continent.dart';
import '../atlas/country_map.dart';
import 'capitals.dart';
import 'flags.dart';
import 'learning_levels.dart';
import 'answer_feedback.dart';
import 'mascot_feedback.dart';
import 'quiz_controller.dart';
import 'session_repository.dart';
import 'streaks.dart';
import 'token_icon.dart';

class LearningScreen extends ConsumerStatefulWidget {
  const LearningScreen({
    super.key,
    this.capitalDifficulty,
    this.flagDifficulty,
    this.daily = false,
    this.dailyMode = DailyMode.regular,
  });
  final FlagDifficulty? flagDifficulty;
  final CapitalDifficulty? capitalDifficulty;
  final bool daily;
  final DailyMode dailyMode;
  @override
  ConsumerState<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends ConsumerState<LearningScreen> {
  late Future<(Catalog, LearningSession?)> _initial;
  LearningSession? _session;
  bool _hasLoadedSession = false;
  String? _selected;
  bool _assisted = false;
  String _typed = '';

  /// Choice in the A–D practice after „Nie wiem, pomóż” (never saved).
  String? _practicePick;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _initial = _load();
  }

  QuizController get _quiz => ref.read(quizControllerProvider);

  Future<(Catalog, LearningSession?)> _load() async {
    final loaded = await _quiz.open(
      QuizKind(
        daily: widget.daily,
        dailyMode: widget.dailyMode,
        flags: widget.flagDifficulty,
        capitals: widget.capitalDifficulty,
        // The placement quiz is always easy: it checks what is already known.
        level: widget.dailyMode == DailyMode.placement
            ? LearningDifficulty.easy
            : null,
      ),
    );
    if (mounted) {
      setState(() {
        _session = loaded.$2;
        _hasLoadedSession = true;
      });
    }
    return loaded;
  }

  bool _canSubmit(LearningSession session) =>
      session.currentAttempt != null ||
      (session.isMapAt(session.index)
          ? false
          : session.difficultyNameAt(session.index) == 'choice'
          ? _selected != null
          : _typed.trim().isNotEmpty);

  Future<void> _guessSelected(
    Catalog catalog,
    LearningSession session,
    String id,
  ) async {
    if (_busy || session.currentAttempt != null) return;
    setState(() => _busy = true);
    try {
      final updated = await _quiz.guess(
        catalog,
        session,
        id,
        assisted: _assisted,
      );
      if (!mounted) return;
      if (updated.currentMapGuesses.length ==
          session.currentMapGuesses.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'To ${ref.read(selectedContinentProvider).areaAccusative} już wskazywano. Wybierz inne.',
            ),
          ),
        );
      }
      setState(() {
        _session = updated;
        _selected = id;
        _assisted = updated.assistedIndices.contains(updated.index);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się zapisać próby. Spróbuj ponownie.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit(
    Catalog catalog,
    LearningSession session, {
    bool gaveUp = false,
  }) async {
    if (_busy || (!gaveUp && !_canSubmit(session))) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final updated = await _quiz.submit(
        catalog,
        session,
        selected: _selected,
        typed: gaveUp ? '' : _typed,
        assisted: _assisted,
        gaveUp: gaveUp,
      );
      if (mounted) {
        setState(() {
          _session = updated;
          _selected = null;
          _assisted = false;
          _typed = '';
          _practicePick = null;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się zapisać postępu. Spróbuj ponownie.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finishQuiz() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final session = _session ?? (await _initial).$2;
      if (!mounted || session == null || session.completed) return;
      final shouldFinish = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Zakończyć quiz?'),
          content: const Text(
            'Zachowamy zatwierdzone odpowiedzi. Pozostałe pytania nie będą ocenione. Tej serii nie wznowisz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Wróć do quizu'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Zakończ quiz'),
            ),
          ],
        ),
      );
      if (shouldFinish != true || !mounted) return;

      final finished = await _quiz.finish(session);
      if (!mounted) return;
      setState(() {
        _session = finished;
        _selected = null;
        _assisted = false;
        _typed = '';
        _practicePick = null;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się zakończyć quizu. Spróbuj ponownie.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final continent = ref.watch(selectedContinentProvider);
    return Scaffold(
      appBar: regionAppBar(
        context,
        continent: continent,
        title: widget.daily
            ? 'Dzisiejsza wyprawa po ${continent.journey}'
            : widget.flagDifficulty != null
            ? '${continent.symbolsLabel} ${continent.genitive}'
            : widget.capitalDifficulty == null
            ? 'Wyprawa po ${continent.journey}'
            : continent == Continent.usa
            ? 'Stolice stanów USA'
            : '${continent.capitalsLabel} ${continent.genitive}',
        actions: _hasLoadedSession && _session != null && !_session!.completed
            ? [
                IconButton(
                  tooltip: 'Zakończ quiz',
                  onPressed: _busy ? null : _finishQuiz,
                  style: IconButton.styleFrom(
                    backgroundColor: GeoTheme.paper.withValues(alpha: .9),
                  ),
                  icon: const Icon(Icons.close),
                ),
              ]
            : const [],
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<(Catalog, LearningSession?)>(
          future: _initial,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return LoadError(
                onRetry: () => setState(() => _initial = _load()),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final (catalog, initialSession) = snapshot.requireData;
            final session = _session ?? initialSession;
            if (session == null) return _emptyDaily();
            if (session.completed) return _summary(catalog, session);
            final attempt = session.currentAttempt;
            final selected =
                attempt?.answer ??
                _selected ??
                (session.currentMapGuesses.isEmpty
                    ? null
                    : session.currentMapGuesses.last.selectedCountryId);
            if (session.isMapAt(session.index)) {
              return _mapQuestion(catalog, session, selected, attempt);
            }
            return _capitalQuestion(catalog, session, attempt);
          },
        ),
      ),
    );
  }

  Widget _mapQuestion(
    Catalog catalog,
    LearningSession session,
    String? selected,
    Attempt? attempt,
  ) {
    final difficulty = session.difficultyNameAt(session.index);
    final supportLevel = switch (difficulty) {
      'mapVeryEasy' => 'veryEasy',
      'mapEasy' => 'easy',
      _ => 'normal',
    };
    final quizSeed = '${session.row.id}:${session.index}';
    final trivia = _trivia(catalog, session, quizSeed);
    final textTheme = Theme.of(context).textTheme;
    final colors = GeoColors.of(context);
    final progress =
        (session.index + (attempt != null ? 1 : 0)) / session.countryIds.length;
    // The question sits above the map so it never covers countries or labels.
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _questionLabel(session),
            style: textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 8),
          if (session.isFlagAt(session.index))
            Row(
              children: [
                _flagImage(session.flagQuestionAt(session.index), height: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Wskaż to ${ref.watch(selectedContinentProvider).areaAccusative}',
                    style: textTheme.titleLarge,
                  ),
                ),
              ],
            )
          else
            Text(
              catalog.country(session.targetId).locationQuestion,
              style: textTheme.headlineSmall,
            ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: CountryMap(
                  key: ValueKey('${session.row.id}:${session.index}'),
                  catalog: catalog,
                  appearance:
                      ref
                          .watch(appPreferencesProvider)
                          .asData
                          ?.value
                          .appearance ??
                      MapAppearance.relief,
                  quizMode: true,
                  selectedId: selected,
                  correctId: attempt == null ? null : session.targetId,
                  wrongCountryIds: session.currentMapGuesses
                      .where((guess) => !guess.correct)
                      .map((guess) => guess.selectedCountryId)
                      .toSet(),
                  targetId: session.targetId,
                  supportLevel: supportLevel,
                  questionSeed: quizSeed,
                  revealId: attempt != null && !attempt.correct
                      ? session.targetId
                      : null,
                  locked: attempt != null || _busy,
                  onSelected: (id) => _guessSelected(catalog, session, id),
                ),
              ),
              if (attempt != null ||
                  session.currentMapGuesses.isNotEmpty ||
                  session.assistedIndices.contains(session.index))
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: SafeArea(
                    top: false,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 680,
                          maxHeight: MediaQuery.sizeOf(context).height * .44,
                        ),
                        child: Card.filled(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (attempt != null) ...[
                                  Semantics(
                                    liveRegion: true,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: attempt.correct
                                              ? colors.correctContainer
                                              : colors.wrongContainer,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              attempt.correct
                                                  ? Icons.check_circle_outline
                                                  : Icons.cancel_outlined,
                                              color: attempt.correct
                                                  ? colors.onCorrectContainer
                                                  : colors.onWrongContainer,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                _feedback(catalog, session),
                                                style: TextStyle(
                                                  color: attempt.correct
                                                      ? colors
                                                            .onCorrectContainer
                                                      : colors.onWrongContainer,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  _InsightNote(
                                    catalog: catalog,
                                    session: session,
                                  ),
                                  // After a hit or the third miss: one local fact.
                                  if (trivia != null) ...[
                                    _TriviaCard(text: trivia.text),
                                    const SizedBox(height: 12),
                                  ],
                                  FilledButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _submit(catalog, session),
                                    child: Text(
                                      session.index ==
                                              session.countryIds.length - 1
                                          ? 'Zobacz wynik'
                                          : 'Następne pytanie',
                                    ),
                                  ),
                                ] else ...[
                                  if (session.currentMapGuesses.isNotEmpty)
                                    Semantics(
                                      liveRegion: true,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.wrongContainer,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.touch_app_outlined,
                                              size: 20,
                                              color: colors.onWrongContainer,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'Wskazano: ${catalog.country(session.currentMapGuesses.last.selectedCountryId).name}. '
                                                'Pozostało prób: ${3 - session.currentMapGuesses.length}.',
                                                style: TextStyle(
                                                  color:
                                                      colors.onWrongContainer,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (session.assistedIndices.contains(
                                    session.index,
                                  ))
                                    const Padding(
                                      padding: EdgeInsets.only(top: 6),
                                      child: Text(
                                        'Z pomocą — bez oceny pamięci mapy.',
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _capitalQuestion(
    Catalog catalog,
    LearningSession session,
    Attempt? attempt,
  ) {
    final flag = session.isFlagAt(session.index);
    final question = flag ? null : session.capitalQuestionAt(session.index);
    final defaultPrompt = 'Jaka jest stolica tego państwa?';
    final progress =
        (session.index + (attempt != null ? 1 : 0)) / session.countryIds.length;
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
                      _questionLabel(session),
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
                        child: _flagImage(
                          session.flagQuestionAt(session.index),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        catalog.continent.symbolQuestion,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ] else ...[
                      Text(
                        _capitalized(
                          catalog.country(session.targetId).questionName,
                        ),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        question!.fact.prompt == defaultPrompt
                            ? catalog.continent.capitalPrompt
                            : question.fact.prompt,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w400),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (attempt == null) _capitalInput(catalog, session),
                    if (attempt != null && session.gaveUpCurrent)
                      _gaveUpPractice(catalog, session)
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
                            ? catalog.continent.areaSubject
                            : catalog.continent.capitalSubject,
                      ),
                    if (attempt != null)
                      _InsightNote(catalog: catalog, session: session),
                    // Flag questions show a flag fact, capital questions a capital fact.
                    if (attempt != null)
                      if (_trivia(
                            catalog,
                            session,
                            '${session.row.id}:${session.index}',
                          )
                          case final fact?)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _TriviaCard(text: fact.text),
                        ),
                  ],
                ),
              ),
            ),
            // Pinned above the soft keyboard and bottom inset so the main CTA
            // stays reachable one-handed at any scroll position.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton(
                    onPressed: _busy || !_canSubmit(session)
                        ? null
                        : () => _submit(catalog, session),
                    child: Text(
                      _busy
                          ? 'Zapisuję…'
                          : attempt == null
                          ? 'Sprawdź odpowiedź'
                          : session.index == session.countryIds.length - 1
                          ? 'Zobacz wynik'
                          : 'Następne pytanie',
                    ),
                  ),
                  if (attempt == null &&
                      session.difficultyNameAt(session.index) != 'choice') ...[
                    const SizedBox(height: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: GeoColors.of(context).wrong,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _busy
                          ? null
                          : () => _submit(catalog, session, gaveUp: true),
                      child: const Text('Nie wiem, pomóż'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// After „Nie wiem, pomóż”: the same question as unscored A–D practice.
  Widget _gaveUpPractice(Catalog catalog, LearningSession session) {
    final flag = session.isFlagAt(session.index);
    final options = flag
        ? session.flagQuestionAt(session.index).options
        : session.capitalQuestionAt(session.index).options;
    final solution = flag
        ? session.flagQuestionAt(session.index).countryName
        : session.capitalQuestionAt(session.index).fact.name;
    final subject = flag
        ? catalog.continent.areaSubject
        : catalog.continent.capitalSubject;
    final scheme = Theme.of(context).colorScheme;
    final colors = GeoColors.of(context);
    final pick = _practicePick;
    final right = pick == solution;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Wybierz poprawną odpowiedź:'),
        const SizedBox(height: 12),
        RadioGroup<String>(
          groupValue: pick,
          onChanged: (value) {
            if (pick == null) setState(() => _practicePick = value);
          },
          child: Column(
            children: [
              for (var i = 0; i < options.length; i++)
                Card.filled(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: pick == options[i]
                      ? scheme.primaryContainer.withValues(alpha: .45)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: pick == options[i]
                          ? scheme.primary
                          : GeoTheme.border,
                      width: pick == options[i] ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: RadioListTile<String>(
                    value: options[i],
                    enabled: pick == null,
                    title: Text(
                      '${String.fromCharCode(65 + i)}. ${options[i]}',
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (pick != null)
          Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: right ? colors.correctContainer : colors.wrongContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                right ? 'Dobrze! $subject: $solution.' : 'To była $solution.',
                style: TextStyle(
                  color: right
                      ? colors.onCorrectContainer
                      : colors.onWrongContainer,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _capitalInput(Catalog catalog, LearningSession session) {
    final flag = session.isFlagAt(session.index);
    final options = flag
        ? session.flagQuestionAt(session.index).options
        : session.capitalQuestionAt(session.index).options;
    final firstLetter = flag
        ? session.flagQuestionAt(session.index).firstLetter
        : session.capitalQuestionAt(session.index).fact.firstLetter;
    final difficulty = session.difficultyNameAt(session.index);
    if (difficulty == 'choice') {
      final scheme = Theme.of(context).colorScheme;
      return RadioGroup<String>(
        groupValue: _selected,
        onChanged: (value) {
          if (!_busy) setState(() => _selected = value);
        },
        child: Column(
          children: [
            for (var i = 0; i < options.length; i++)
              Card.filled(
                margin: const EdgeInsets.only(bottom: 10),
                color: _selected == options[i]
                    ? scheme.primaryContainer.withValues(alpha: .45)
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: _selected == options[i]
                        ? scheme.primary
                        : GeoTheme.border,
                    width: _selected == options[i] ? 2 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: RadioListTile<String>(
                  value: options[i],
                  enabled: !_busy,
                  title: Text(
                    '${String.fromCharCode(65 + i)}. ${options[i]}',
                    style: TextStyle(
                      fontWeight: _selected == options[i]
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
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
              ? 'Wpisz całą nazwę ${ref.watch(selectedContinentProvider).areaGenitive}.'
              : 'Wpisz całą nazwę stolicy.',
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: ValueKey('capital-input-${session.row.id}-${session.index}'),
          initialValue: _typed,
          enabled: !_busy,
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
                ? 'Nazwa ${ref.watch(selectedContinentProvider).areaGenitive}'
                : 'Nazwa stolicy',
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
          onChanged: (value) => setState(() => _typed = value),
          onFieldSubmitted: (_) => _submit(catalog, session),
        ),
        const SizedBox(height: 12),
        const Text(
          'Dopuszczamy jedną literówkę; polskie znaki nie są wymagane.',
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _showCapitalAnswerHelp,
            child: const Text('Jak sprawdzamy odpowiedzi?'),
          ),
        ),
      ],
    );
  }

  Future<void> _showCapitalAnswerHelp() => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Jak sprawdzamy odpowiedzi?'),
      content: const Text(
        'Przy wpisywaniu akceptujemy jedną literówkę: zamianę, pominięcie, dodanie litery lub przestawienie dwóch sąsiednich liter. Wielkość liter i znaki diakrytyczne nie wpływają na wynik.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Rozumiem'),
        ),
      ],
    ),
  );

  Widget _flagImage(FlagQuestion question, {double height = 156}) => Container(
    height: height,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      // Barely grey so white flag fields (e.g. the Netherlands) stay visible.
      color: GeoColors.of(context).flagFrame,
      border: Border.all(color: GeoColors.of(context).flagFrameBorder),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Image.asset(
      question.assetPath,
      fit: BoxFit.contain,
      semanticLabel:
          '${ref.read(selectedContinentProvider).symbolLabel} do rozpoznania',
    ),
  );

  String _feedback(Catalog catalog, LearningSession session) {
    final attempt = session.currentAttempt!;
    final guesses = session.currentMapGuesses;
    final result = attempt.correct
        ? guesses.length > 1
              ? 'Odnaleziono za ${guesses.length}. próbą. To ${catalog.country(session.targetId).name}.\nPóźniejsze próby są ćwiczeniem.'
              : 'Dobrze! To ${catalog.country(session.targetId).name}.'
        : 'Wskazane ${catalog.continent.areaAccusative}: ${catalog.country(attempt.answer).name}. Poprawna odpowiedź: ${catalog.country(session.targetId).name} — zaznaczona na zielono.';
    return session.assistedIndices.contains(session.index)
        ? 'Z pomocą — bez oceny pamięci mapy.\n$result'
        : result;
  }

  /// One local fact for the current question: about the flag in flag
  /// questions, the capital in capital questions, otherwise the country.
  /// Skips facts naming countries asked later in this series.
  CountryTriviaFact? _trivia(
    Catalog catalog,
    LearningSession session,
    String seed,
  ) {
    final provider = session.isFlagAt(session.index)
        ? flagTriviaProvider
        : session.isCapitalAt(session.index)
        ? capitalTriviaProvider
        : countryTriviaProvider;
    final upcoming = [
      for (final id in session.countryIds.skip(session.index + 1))
        if (catalog.countries.any((c) => c.id == id)) catalog.country(id).name,
    ];
    return ref
        .watch(provider)
        .asData
        ?.value
        .pick(session.targetId, seed: seed, avoid: upcoming);
  }

  String _questionLabel(LearningSession session) {
    final label = 'Pytanie ${session.index + 1} z ${session.countryIds.length}';
    if (session.isRetryAt(session.index)) return '$label, powtórka błędu';
    if (session.isScaffoldAt(session.index)) return '$label, z podpowiedzią';
    if (session.isContrastAt(session.index)) {
      return '$label, para do porównania';
    }
    return session.originAt(session.index) == 'control'
        ? '$label, kontrola'
        : label;
  }

  Widget _summary(Catalog catalog, LearningSession session) {
    final confirmedCount = session.attempts.length;
    final isPartial = confirmedCount < session.countryIds.length;
    final scoredAttempts = session.scoredAttempts;
    final unscoredCount = session.attempts
        .where((a) => session.assistedIndices.contains(a.questionIndex))
        .length;
    final retryCount = session.attempts
        .where((a) => session.isPracticeAt(a.questionIndex))
        .length;
    final isChoiceOnly = List.generate(
      session.countryIds.length,
      (index) =>
          session.difficultyNameAt(index) == 'choice' &&
          (session.topicAt(index) == 'capitals' ||
              session.topicAt(index) == 'flags'),
    ).every((isChoice) => isChoice);
    final scoreCount = scoredAttempts.length;
    final correctScoredCount = session.correctCount;
    final mascotFeedback = quizMascotFeedback(
      completedAllQuestions: !isPartial,
      choiceOnly: isChoiceOnly && scoreCount == 0,
      scoredAttempts: scoreCount,
      correctCount: correctScoredCount,
      seed: session.row.id,
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 8),
            Text(
              isPartial
                  ? 'Quiz zakończony'
                  : widget.daily
                  ? 'Dzisiejsza wyprawa ukończona!'
                  : 'Wyprawa ukończona!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              textAlign: TextAlign.center,
              isChoiceOnly
                  ? 'Trening rozpoznawania A–D: $correctScoredCount z $scoreCount odpowiedzi poprawnych. Każdy poziom ma osobne powtórki.'
                  : isPartial
                  ? confirmedCount == 0
                        ? 'Nie zatwierdzono żadnej odpowiedzi.'
                        : 'Zatwierdzono $confirmedCount z ${session.countryIds.length} pytań.\n'
                              '$correctScoredCount z $scoreCount ocenianych odpowiedzi poprawnych.'
                  : '$correctScoredCount z $scoreCount ocenianych odpowiedzi poprawnych.',
            ),
            const SizedBox(height: 16),
            // One centred column: title, result, then the kuna's reaction.
            QuizMascotFeedbackView(feedback: mascotFeedback),
            if (ref.watch(streakProvider).asData?.value.rewardToday
                case final days?) ...[
              const SizedBox(height: 16),
              _StreakReward(days: days),
            ] else if (ref.watch(streakProvider).asData?.value.current
                case final days? when days > 0) ...[
              const SizedBox(height: 16),
              _StreakDays(
                days: days,
                continent: ref.watch(selectedContinentProvider),
              ),
            ],
            if (ref.watch(streakProvider).asData?.value case final streak?
                when streak.tokenEarnedToday) ...[
              const SizedBox(height: 12),
              _TokenEarned(tokens: streak.tokens),
            ],
            if (retryCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Ćwiczenia w serii (powtórki, podpowiedzi, pary): $retryCount — nie liczą się do wyniku.',
              ),
            ],
            if (unscoredCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Bez oceny tej umiejętności: $unscoredCount odpowiedzi z pomocą.',
              ),
            ],
            if (session.assistedIndices.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Odpowiedzi z pomocą: ${session.assistedIndices.length} — bez oceny pamięci mapy.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 24),
            if (session.attempts.isNotEmpty)
              _ResultList(
                rows: [
                  for (final attempt in session.attempts)
                    _resultRow(catalog, session, attempt),
                ],
              ),
            const SizedBox(height: 24),
            // One primary action: another round after real answers,
            // otherwise going back.
            if (widget.daily && confirmedCount > 0) ...[
              FilledButton.icon(
                onPressed: () => context.pushReplacement('/daily?mode=extra'),
                icon: const Icon(Icons.replay),
                label: const Text('Kolejna runda'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/'),
                child: const Text('Wróć na start'),
              ),
            ] else
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Wróć na start'),
              ),
            if (!widget.daily) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  if (session.isCapitalAt(0) || session.isFlagAt(0)) {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      final setup = session.isFlagAt(0)
                          ? '/flags'
                          : '/capitals';
                      context.go('/');
                      context.push(setup);
                    }
                  } else {
                    context.go('/atlas');
                  }
                },
                child: Text(
                  (session.isCapitalAt(0) || session.isFlagAt(0))
                      ? 'Wybierz inny poziom'
                      : 'Obejrzyj atlas',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyDaily() {
    final nextDue = ref.watch(dailyOverviewProvider).asData?.value.nextDue;
    final nextDueMessage = nextDue == null
        ? 'Nowe pytania pojawią się w kolejnych dniach.'
        : 'Następna powtórka: ${MaterialLocalizations.of(context).formatMediumDate(nextDue.toLocal())} o ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(nextDue.toLocal()), alwaysUse24HourFormat: true)}.';
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            ExcludeSemantics(
              child: Image.asset(
                'assets/v2/kuna_happy.webp',
                height: 120,
                cacheWidth: 312,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Na dziś wszystko.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(nextDueMessage, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Wróć na start'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Short learning hints after an answer: recovery of a hard country and a
/// pair that keeps being confused. Shown below the feedback, never blocking.
class _InsightNote extends StatelessWidget {
  const _InsightNote({required this.catalog, required this.session});
  final Catalog catalog;
  final LearningSession session;

  @override
  Widget build(BuildContext context) {
    final insight = session.insight;
    if (insight == null || session.isPracticeAt(session.index)) {
      return const SizedBox.shrink();
    }
    final lines = [
      if (insight.recovery case final done?)
        done >= recoveryTarget
            ? 'Trudny kraj opanowany: $done z $recoveryTarget trafień z rzędu.'
            : 'Trudny kraj: $done z $recoveryTarget trafień z rzędu.',
      if (insight.confusedWithId case final other?)
        'Ta para już się myliła: ${catalog.country(session.targetId).name} '
            'i ${catalog.country(other).name}. Porównaj ich położenie.',
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.insights_outlined, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(lines.join('\n'))),
        ],
      ),
    );
  }
}

/// Country fact card: warm cream background, bulb icon and a text label,
/// so colour is never the only signal (yellow alone means an accepted typo).
class _TriviaCard extends StatelessWidget {
  const _TriviaCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = GeoColors.of(context);
    return Semantics(
      container: true,
      label: 'Ciekawostka: $text',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.triviaContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.triviaBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The kuna with a magnifying glass (v2.5) marks the fact.
              Image.asset(
                'assets/v2/kuna_lupa.webp',
                width: 52,
                height: 52,
                cacheWidth: 156,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ciekawostka',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.triviaTitle,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: TextStyle(color: colors.onTriviaContainer),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One summary line; [given] is what the learner typed, chose or pointed
/// at, shown after a tap on a wrong (or typo) answer.
typedef _Result = ({bool correct, String title, String detail, String? given});

_Result _resultRow(Catalog catalog, LearningSession session, Attempt attempt) {
  final i = attempt.questionIndex;
  final typo = attempt.typoAccepted ? ', literówka' : '';
  final retry = session.isRetryAt(i)
      ? 'powtórka, '
      : session.isScaffoldAt(i)
      ? 'podpowiedź, '
      : session.isContrastAt(i)
      ? 'para, '
      : '';
  String nameOf(String id) =>
      catalog.countries.any((c) => c.id == id) ? catalog.country(id).name : id;
  final verb = attempt.difficulty == 'choice' ? 'Wybrano' : 'Wpisano';
  final String detail;
  String? given;
  if (session.assistedIndices.contains(i)) {
    detail = 'z pomocą';
  } else if (attempt.answer.isEmpty && attempt.topic != 'map') {
    // „Nie wiem, pomóż” stores no typed answer.
    detail = attempt.topic == 'capitals'
        ? session.capitalQuestionAt(i).fact.name
        : 'flaga';
    given = 'Nie wiem — pomoc A–D';
  } else if (attempt.topic == 'capitals') {
    detail = '${session.capitalQuestionAt(i).fact.name}$typo';
    given = '$verb: ${attempt.answer}';
  } else if (attempt.topic == 'flags' &&
      !mapDifficulties.contains(attempt.difficulty)) {
    detail = 'flaga$typo';
    given = '$verb: ${nameOf(attempt.answer)}';
  } else {
    final guesses = session.mapGuesses
        .where((g) => g.questionIndex == i)
        .toList();
    detail = !attempt.correct
        ? 'nie odnaleziono'
        : guesses.length > 1
        ? 'za ${guesses.length}. razem'
        : 'od razu';
    final wrong = [
      for (final g in guesses)
        if (g.selectedCountryId != attempt.countryId)
          nameOf(g.selectedCountryId),
    ];
    if (wrong.isNotEmpty) given = 'Wskazano: ${wrong.join(', ')}';
  }
  return (
    correct: attempt.correct,
    title: catalog.country(attempt.countryId).name,
    detail: '$retry$detail',
    // Only mistakes and typos open; a clean answer has nothing to add.
    given:
        !attempt.correct ||
            attempt.typoAccepted ||
            given?.startsWith('Wskazano') == true
        ? given
        : null,
  );
}

/// Compact result table: one short line per question. A mistake opens on
/// tap and shows what was typed, chosen or pointed at.
class _ResultList extends StatefulWidget {
  const _ResultList({required this.rows});
  final List<_Result> rows;

  @override
  State<_ResultList> createState() => _ResultListState();
}

class _ResultListState extends State<_ResultList> {
  final _open = <int>{};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = GeoColors.of(context);
    return Card.outlined(
      margin: const EdgeInsets.only(top: 20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (index, row) in widget.rows.indexed) ...[
            if (index > 0) const Divider(height: 1),
            InkWell(
              onTap: row.given == null
                  ? null
                  : () => setState(
                      () => _open.contains(index)
                          ? _open.remove(index)
                          : _open.add(index),
                    ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          row.correct ? Icons.check_circle : Icons.cancel,
                          size: 20,
                          color: row.correct ? colors.correct : colors.wrong,
                          semanticLabel: row.correct ? 'Dobrze' : 'Błąd',
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            row.title,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            row.detail,
                            textAlign: TextAlign.end,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (row.given != null)
                          Icon(
                            _open.contains(index)
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 20,
                            semanticLabel: _open.contains(index)
                                ? 'Zwiń'
                                : 'Pokaż odpowiedź',
                          ),
                      ],
                    ),
                    AnimatedSize(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      alignment: Alignment.topCenter,
                      child: _open.contains(index)
                          ? Padding(
                              padding: const EdgeInsets.only(left: 30, top: 4),
                              child: Text(
                                row.given!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: row.correct
                                      ? theme.colorScheme.onSurfaceVariant
                                      : colors.onWrongContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The current streak, on every summary without a reward that day.
class _StreakDays extends StatelessWidget {
  const _StreakDays({required this.days, required this.continent});
  final int days;
  final Continent continent;

  @override
  Widget build(BuildContext context) {
    final colors = GeoColors.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      child: Card.filled(
        color: colors.triviaContainer,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Icon(
            Icons.local_fire_department,
            color: colors.streak,
            size: 36,
          ),
          title: Text('Passa: ${daysLabel(days)} z rzędu · ${continent.label}'),
        ),
      ),
    );
  }
}

/// Shown on the summary the day a streak reward is reached.
class _StreakReward extends StatelessWidget {
  const _StreakReward({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    final colors = GeoColors.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      child: Card.filled(
        color: colors.triviaContainer,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Icon(
            Icons.local_fire_department,
            color: colors.streak,
            size: 36,
          ),
          title: Text('Nagroda: $days dni z rzędu!'),
          subtitle: Text(
            days == streakRewards.last
                ? 'To najwyższa nagroda za passę. Kuna jest pod wrażeniem!'
                : 'Następna czeka za '
                      '${streakRewards.firstWhere((d) => d > days)} dni.',
          ),
        ),
      ),
    );
  }
}

/// A new „Nieprzykunowanie” token, earned with every 7 streak days.
class _TokenEarned extends StatelessWidget {
  const _TokenEarned({required this.tokens});
  final int tokens;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    child: Card.filled(
      color: GeoColors.of(context).triviaContainer,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const TokenIcon(size: 36),
        title: const Text('Nowy żeton: Nieprzykunowanie!'),
        subtitle: Text(
          'Uratuje passę, gdy opuścisz dzień. '
          'Masz ${tokensLabel(tokens)} (najwyżej $maxTokens).',
        ),
      ),
    ),
  );
}

String _capitalized(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
