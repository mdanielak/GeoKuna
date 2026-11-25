import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../atlas/catalog.dart';
import '../atlas/continent.dart';
import '../settings/app_preferences.dart';
import 'capitals.dart';
import 'country_trivia.dart';
import 'flags.dart';
import 'quiz_controller.dart';
import 'session_repository.dart';
import 'widgets/map_quiz_view.dart';
import 'widgets/quiz_summary_view.dart';
import 'widgets/text_quiz_view.dart';

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

  Future<void> _guessSelected(
    Catalog catalog,
    LearningSession session,
    String id,
  ) async {
    if (_busy || session.currentAttempt != null) return;
    setState(() => _busy = true);
    try {
      final updated = await _quiz.guess(catalog, session, id);
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
      });
    } catch (e, st) {
      debugPrint('LearningScreen guess error: $e\n$st');
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
    required String? selected,
    required String typed,
    bool gaveUp = false,
  }) async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final updated = await _quiz.submit(
        catalog,
        session,
        selected: selected,
        typed: typed,
        gaveUp: gaveUp,
      );
      if (mounted) {
        setState(() {
          _session = updated;
          _selected = null;
        });
      }
    } catch (e, st) {
      debugPrint('LearningScreen submit error: $e\n$st');
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
      });
    } catch (e, st) {
      debugPrint('LearningScreen finish error: $e\n$st');
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
            if (session.completed) {
              return QuizSummaryView(
                catalog: catalog,
                session: session,
                daily: widget.daily,
              );
            }
            final attempt = session.currentAttempt;
            final quizSeed = '${session.row.id}:${session.index}';
            final trivia = _trivia(catalog, session, quizSeed);
            final questionLabel = _questionLabel(session);
            if (session.isMapAt(session.index)) {
              final selected =
                  attempt?.answer ??
                  _selected ??
                  (session.currentMapGuesses.isEmpty
                      ? null
                      : session.currentMapGuesses.last.selectedCountryId);
              return MapQuizView(
                catalog: catalog,
                session: session,
                selected: selected,
                attempt: attempt,
                busy: _busy,
                questionLabel: questionLabel,
                trivia: trivia,
                onSelected: (id) => _guessSelected(catalog, session, id),
                onNext: () =>
                    _submit(catalog, session, selected: null, typed: ''),
              );
            }
            return TextQuizView(
              catalog: catalog,
              session: session,
              attempt: attempt,
              busy: _busy,
              questionLabel: questionLabel,
              trivia: trivia,
              onSubmit: ({required selected, required typed, gaveUp = false}) =>
                  _submit(
                    catalog,
                    session,
                    selected: selected,
                    typed: typed,
                    gaveUp: gaveUp,
                  ),
            );
          },
        ),
      ),
    );
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
