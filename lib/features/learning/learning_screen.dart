import '../settings/app_preferences.dart';
import 'memory.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../app/providers.dart';
import '../../core/database/database.dart';
import '../atlas/catalog.dart';
import '../atlas/country_map.dart';
import 'capitals.dart';
import 'flags.dart';
import 'learning_levels.dart';
import 'answer_feedback.dart';
import 'mascot_feedback.dart';
import 'session_repository.dart';

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
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _initial = _load();
  }

  Future<(Catalog, LearningSession?)> _load() async {
    await ref.read(appPreferencesProvider.future);
    final repository = ref.read(repositoryProvider);
    final catalogFuture = ref.read(catalogProvider.future);
    final catalog = await catalogFuture;
    final LearningSession? session;
    if (widget.daily) {
      session = await repository.startDaily(
        catalog,
        await ref.read(capitalsProvider.future),
        flags: await ref.read(flagsProvider.future),
        mode: widget.dailyMode,
      );
    } else if (widget.flagDifficulty != null) {
      session = await repository.startFlags(
        await ref.read(flagsProvider.future),
        widget.flagDifficulty!,
      );
    } else if (widget.capitalDifficulty != null) {
      session = await repository.startCapitals(
        await ref.read(capitalsProvider.future),
        widget.capitalDifficulty!,
      );
    } else {
      session = await repository.start(
        catalog.countries.map((c) => c.id).toList(),
      );
    }
    if (mounted) {
      ref.invalidate(dashboardProvider);
      ref.invalidate(dailyOverviewProvider);
      setState(() {
        _session = session;
        _hasLoadedSession = true;
      });
    }
    return (catalog, session);
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
      final updated = await ref
          .read(repositoryProvider)
          .guessMap(
            session.row.id,
            session.index,
            id,
            catalog.countries.map((c) => c.id).toSet(),
            expectedGuessIndex: session.currentMapGuesses.length,
            assisted:
                _assisted || session.assistedIndices.contains(session.index),
          );
      if (!mounted) return;
      if (updated.currentMapGuesses.length ==
          session.currentMapGuesses.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('To państwo już wskazywano. Wybierz inne.'),
          ),
        );
      }
      ref.invalidate(dashboardProvider);
      ref.invalidate(dailyOverviewProvider);
      ref.invalidate(learningProgressProvider);
      ref.invalidate(streakProvider);
      ref.invalidate(
        continentAchievementsProvider(ref.read(selectedContinentProvider)),
      );
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

  Future<void> _submit(Catalog catalog, LearningSession session) async {
    if (_busy || !_canSubmit(session)) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final repository = ref.read(repositoryProvider);
      final LearningSession updated;
      if (session.currentAttempt != null) {
        updated = await repository.advance(session.row.id, session.index);
      } else if (session.isFlagAt(session.index)) {
        updated = await repository.answerFlag(
          session.row.id,
          session.index,
          session.flagDifficulty == FlagDifficulty.choice ? _selected! : _typed,
        );
      } else if (session.isCapitalAt(session.index)) {
        updated = await repository.answerCapital(
          session.row.id,
          session.index,
          session.difficultyAt(session.index) == CapitalDifficulty.choice
              ? _selected!
              : _typed,
        );
      } else {
        updated = await repository.answer(
          session.row.id,
          session.index,
          _selected!,
          catalog.countries.map((c) => c.id).toSet(),
          assisted: _assisted,
        );
      }
      if (mounted) {
        ref.invalidate(dashboardProvider);
        ref.invalidate(dailyOverviewProvider);
        ref.invalidate(learningProgressProvider);
        ref.invalidate(streakProvider);
        ref.invalidate(
          continentAchievementsProvider(ref.read(selectedContinentProvider)),
        );
        setState(() {
          _session = updated;
          _selected = null;
          _assisted = false;
          _typed = '';
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

      final finished = await ref
          .read(repositoryProvider)
          .finish(session.row.id);
      if (!mounted) return;
      ref.invalidate(dashboardProvider);
      ref.invalidate(dailyOverviewProvider);
      ref.invalidate(learningProgressProvider);
      setState(() {
        _session = finished;
        _selected = null;
        _assisted = false;
        _typed = '';
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.daily
            ? 'Dzisiejsza wyprawa po ${ref.watch(selectedContinentProvider).journey}'
            : widget.flagDifficulty != null
            ? 'Flagi ${ref.watch(selectedContinentProvider).genitive}'
            : widget.capitalDifficulty == null
            ? 'Wyprawa po ${ref.watch(selectedContinentProvider).journey}'
            : 'Stolice ${ref.watch(selectedContinentProvider).genitive}',
      ),
      actions: _hasLoadedSession && _session != null && !_session!.completed
          ? [
              IconButton(
                tooltip: 'Zakończ quiz',
                onPressed: _busy ? null : _finishQuiz,
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
            return LoadError(onRetry: () => setState(() => _initial = _load()));
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
    final trivia = ref
        .watch(countryTriviaProvider)
        .asData
        ?.value
        .pick(session.targetId, seed: quizSeed);
    final textTheme = Theme.of(context).textTheme;
    // The question sits above the map so it never covers countries or labels.
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _questionLabel(session),
            style: textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          if (session.isFlagAt(session.index))
            Row(
              children: [
                _flagImage(session.flagQuestionAt(session.index), height: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Wskaż to państwo',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              catalog.country(session.targetId).locationQuestion,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
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
                                      child: Text(_feedback(catalog, session)),
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
                                      child: Text(
                                        'Jeszcze nie. Pozostało prób: ${3 - session.currentMapGuesses.length}.',
                                        style: const TextStyle(
                                          color: Color(0xFF8C1D18),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  if (session.assistedIndices.contains(
                                    session.index,
                                  ))
                                    const Text(
                                      'Z pomocą — bez oceny pamięci mapy.',
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Text(
              _questionLabel(session),
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: session.index / session.countryIds.length,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 20),
            if (flag) ...[
              _flagImage(session.flagQuestionAt(session.index)),
              const SizedBox(height: 12),
              Text(
                'Jakie to państwo?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ] else ...[
              Text(
                catalog.country(session.targetId).name,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                question!.fact.prompt == defaultPrompt
                    ? 'Stolica?'
                    : question.fact.prompt,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
            const SizedBox(height: 20),
            if (attempt == null) _capitalInput(catalog, session),
            if (attempt != null)
              AnswerFeedback(
                correct: attempt.correct,
                typoAccepted: attempt.typoAccepted,
                answer: attempt.answer,
                solution: flag
                    ? session.flagQuestionAt(session.index).countryName
                    : question!.fact.name,
                note: flag ? '' : question!.fact.note,
                subject: flag ? 'Państwo' : 'Stolica',
              ),
            if (attempt != null)
              _InsightNote(catalog: catalog, session: session),
            const SizedBox(height: 12),
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
          ],
        ),
      ),
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
      return RadioGroup<String>(
        groupValue: _selected,
        onChanged: (value) {
          if (!_busy) setState(() => _selected = value);
        },
        child: Column(
          children: [
            for (var i = 0; i < options.length; i++)
              Card.filled(
                child: RadioListTile<String>(
                  value: options[i],
                  enabled: !_busy,
                  title: Text('${String.fromCharCode(65 + i)}. ${options[i]}'),
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
              ? 'Wpisz całą nazwę państwa.'
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
                ? 'Nazwa państwa'
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
      color: Colors.white,
      border: Border.all(color: const Color(0xFF7C887E)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Image.asset(
      question.assetPath,
      fit: BoxFit.contain,
      semanticLabel: 'Flaga do rozpoznania',
    ),
  );

  String _feedback(Catalog catalog, LearningSession session) {
    final attempt = session.currentAttempt!;
    final guesses = session.currentMapGuesses;
    final result = attempt.correct
        ? guesses.length > 1
              ? 'Odnaleziono za ${guesses.length}. próbą. To ${catalog.country(session.targetId).name}.\nPóźniejsze próby są ćwiczeniem.'
              : 'Dobrze! To ${catalog.country(session.targetId).name}.'
        : 'Wskazane państwo: ${catalog.country(attempt.answer).name}. Poprawna odpowiedź: ${catalog.country(session.targetId).name} — zaznaczona na zielono.';
    return session.assistedIndices.contains(session.index)
        ? 'Z pomocą — bez oceny pamięci mapy.\n$result'
        : result;
  }

  String _questionLabel(LearningSession session) {
    final label = 'Pytanie ${session.index + 1} z ${session.countryIds.length}';
    if (session.isRetryAt(session.index)) return '$label, powtórka błędu';
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
        .where((a) => session.isRetryAt(a.questionIndex))
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
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
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
            if (retryCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Powtórzone w serii: $retryCount — to ćwiczenie, wynik liczy pierwszą odpowiedź.',
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
                onPressed: () => context.go(
                  session.isFlagAt(session.index)
                      ? '/flags'
                      : session.isCapitalAt(session.index)
                      ? '/capitals'
                      : '/atlas',
                ),
                child: Text(
                  (session.isCapitalAt(session.index) ||
                          session.isFlagAt(session.index))
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
            const Icon(Icons.check_circle_outline, size: 56),
            const SizedBox(height: 20),
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
    if (insight == null || session.isRetryAt(session.index)) {
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
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Ciekawostka: $text',
    excludeSemantics: true,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFCF0CF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5C46B)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb, color: Color(0xFFB07800), size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ciekawostka',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF5C3F00),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(text, style: const TextStyle(color: Color(0xFF3B2F12))),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

typedef _Result = ({bool correct, String title, String detail});

_Result _resultRow(Catalog catalog, LearningSession session, Attempt attempt) {
  final i = attempt.questionIndex;
  final typo = attempt.typoAccepted ? ', literówka' : '';
  final retry = session.isRetryAt(i) ? 'powtórka, ' : '';
  final String detail;
  if (session.assistedIndices.contains(i)) {
    detail = 'z pomocą';
  } else if (attempt.topic == 'capitals') {
    detail = '${session.capitalQuestionAt(i).fact.name}$typo';
  } else if (attempt.topic == 'flags' &&
      !mapDifficulties.contains(attempt.difficulty)) {
    detail = 'flaga$typo';
  } else {
    final tries = session.mapGuesses.where((g) => g.questionIndex == i).length;
    detail = !attempt.correct
        ? 'nie odnaleziono'
        : tries > 1
        ? 'za $tries. razem'
        : 'od razu';
  }
  return (
    correct: attempt.correct,
    title: catalog.country(attempt.countryId).name,
    detail: '$retry$detail',
  );
}

/// Compact result table: one short line per question.
class _ResultList extends StatelessWidget {
  const _ResultList({required this.rows});
  final List<_Result> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.outlined(
      margin: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          children: [
            for (final (index, row) in rows.indexed) ...[
              if (index > 0) const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      row.correct ? Icons.check_circle : Icons.cancel,
                      size: 20,
                      color: row.correct
                          ? const Color(0xFF2E7D57)
                          : const Color(0xFFA63A2B),
                      semanticLabel: row.correct ? 'Dobrze' : 'Błąd',
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(row.title, style: theme.textTheme.bodyLarge),
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
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
