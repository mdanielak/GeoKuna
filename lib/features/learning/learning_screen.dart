import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../app/providers.dart';
import '../../core/database/database.dart';
import '../atlas/catalog.dart';
import '../atlas/country_map.dart';
import 'capitals.dart';
import 'session_repository.dart';

class LearningScreen extends ConsumerStatefulWidget {
  const LearningScreen({super.key, this.capitalDifficulty, this.daily = false});
  final CapitalDifficulty? capitalDifficulty;
  final bool daily;
  @override
  ConsumerState<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends ConsumerState<LearningScreen> {
  late Future<(Catalog, LearningSession?)> _initial;
  LearningSession? _session;
  String? _selected;
  String _typed = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _initial = _load();
  }

  Future<(Catalog, LearningSession?)> _load() async {
    final repository = ref.read(repositoryProvider);
    final catalogFuture = ref.read(catalogProvider.future);
    final capitalsFuture = widget.capitalDifficulty == null && !widget.daily
        ? null
        : ref.read(capitalsProvider.future);
    final catalog = await catalogFuture;
    final session = widget.daily
        ? await repository.startDaily(catalog, await capitalsFuture!)
        : capitalsFuture == null
        ? await repository.start(catalog.countries.map((c) => c.id).toList())
        : await repository.startCapitals(
            await capitalsFuture,
            widget.capitalDifficulty!,
          );
    if (mounted) ref.invalidate(dashboardProvider);
    if (mounted) ref.invalidate(dailyOverviewProvider);
    return (catalog, session);
  }

  bool _canSubmit(LearningSession session) =>
      session.currentAttempt != null ||
      (session.isCapitalAt(session.index) &&
              session.difficultyAt(session.index) != CapitalDifficulty.choice
          ? _typed.trim().isNotEmpty
          : _selected != null);

  Future<void> _submit(Catalog catalog, LearningSession session) async {
    if (_busy || !_canSubmit(session)) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final repository = ref.read(repositoryProvider);
      final LearningSession updated;
      if (session.currentAttempt != null) {
        updated = await repository.advance(session.row.id, session.index);
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
        );
      }
      if (mounted) {
        ref.invalidate(dashboardProvider);
        ref.invalidate(dailyOverviewProvider);
        setState(() {
          _session = updated;
          _selected = null;
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.daily
            ? 'Dzisiejsza wyprawa'
            : widget.capitalDifficulty == null
            ? 'Wyprawa po Europie'
            : 'Stolice Europy',
      ),
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
          final selected = attempt?.answer ?? _selected;
          if (!session.isCapitalAt(session.index)) {
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
  ) => Stack(
    children: [
      Positioned.fill(
        child: CountryMap(
          key: ValueKey(session.index),
          catalog: catalog,
          questionRegionId: session.targetId,
          selectedId: selected,
          correctId: attempt == null ? null : session.targetId,
          locked: attempt != null || _busy,
          onSelected: (id) => setState(() => _selected = id),
        ),
      ),
      Positioned(
        top: 12,
        left: 12,
        right: 76,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Card.filled(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PYTANIE ${session.index + 1} Z ${session.countryIds.length}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      catalog.country(session.targetId).locationQuestion,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      if (selected != null || attempt != null)
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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (attempt != null)
                          Semantics(
                            liveRegion: true,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(_feedback(catalog, session)),
                            ),
                          ),
                        FilledButton(
                          onPressed: _busy
                              ? null
                              : () => _submit(catalog, session),
                          child: Text(
                            _busy
                                ? 'Zapisuję…'
                                : attempt == null
                                ? 'Potwierdź'
                                : session.index == session.countryIds.length - 1
                                ? 'Zobacz wynik'
                                : 'Następne pytanie',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );

  Widget _capitalQuestion(
    Catalog catalog,
    LearningSession session,
    Attempt? attempt,
  ) {
    final question = session.capitalQuestionAt(session.index);
    final defaultPrompt = 'Jaka jest stolica tego państwa?';
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Text(
              'PYTANIE ${session.index + 1} Z ${session.countryIds.length}',
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: session.index / session.countryIds.length,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 20),
            Text(
              catalog.country(session.targetId).name,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              question.fact.prompt == defaultPrompt
                  ? 'Stolica?'
                  : question.fact.prompt,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            if (attempt == null) _capitalInput(catalog, session),
            if (attempt != null)
              Semantics(
                liveRegion: true,
                child: Card.filled(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_feedback(catalog, session)),
                  ),
                ),
              ),
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
    final question = session.capitalQuestionAt(session.index);
    final difficulty = session.difficultyAt(session.index);
    if (difficulty == CapitalDifficulty.choice) {
      return RadioGroup<String>(
        groupValue: _selected,
        onChanged: (value) {
          if (!_busy) setState(() => _selected = value);
        },
        child: Column(
          children: [
            for (var i = 0; i < question.options.length; i++)
              Card.filled(
                child: RadioListTile<String>(
                  value: question.options[i],
                  enabled: !_busy,
                  title: Text(
                    '${String.fromCharCode(65 + i)}. ${question.options[i]}',
                  ),
                ),
              ),
          ],
        ),
      );
    }
    final hint = difficulty == CapitalDifficulty.firstLetter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hint
              ? 'Pierwsza litera: ${question.fact.firstLetter}. Dopisz pozostałe litery.'
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
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            counterText: '',
            labelText: hint ? 'Pozostałe litery' : 'Nazwa stolicy',
            prefixIcon: hint
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      question.fact.firstLetter,
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
          'Jedna literówka jest dozwolona. Nie musisz wpisywać znaków diakrytycznych.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  String _feedback(Catalog catalog, LearningSession session) {
    final attempt = session.currentAttempt!;
    if (attempt.topic != 'capitals') {
      return attempt.correct
          ? 'Dobrze! To ${catalog.country(session.targetId).name}.'
          : 'Wskazane państwo: ${catalog.country(attempt.answer).name}. '
                'Poprawna odpowiedź: ${catalog.country(session.targetId).name} — zaznaczona na zielono.';
    }
    final fact = session.capitalQuestionAt(attempt.questionIndex).fact;
    final result = attempt.correct
        ? (attempt.typoAccepted
              ? 'Dobrze — literówka zaakceptowana.\nPoprawna pisownia: ${fact.name}.'
              : 'Dobrze! Stolica: ${fact.name}.')
        : 'Poprawna odpowiedź: ${fact.name}.';
    return '$result\nTwoja odpowiedź: ${attempt.answer}${fact.note.isEmpty ? '' : '\n\n${fact.note}'}';
  }

  Widget _summary(Catalog catalog, LearningSession session) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.explore, size: 64),
          const SizedBox(height: 24),
          Text(
            widget.daily
                ? 'Dzisiejsza wyprawa ukończona!'
                : 'Wyprawa ukończona!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            '${session.correctCount} z ${session.countryIds.length} poprawnych odpowiedzi.',
          ),
          const SizedBox(height: 24),
          for (final attempt in session.attempts)
            ListTile(
              leading: Icon(
                attempt.correct ? Icons.check_circle_outline : Icons.replay,
              ),
              title: Text(catalog.country(attempt.countryId).name),
              subtitle: Text(
                attempt.topic == 'capitals'
                    ? '${session.capitalQuestionAt(attempt.questionIndex).fact.name} · ${CapitalDifficulty.values.byName(attempt.difficulty).label}${attempt.typoAccepted ? ' · literówka zaakceptowana' : ''}'
                    : attempt.correct
                    ? 'Odnalezione!'
                    : 'Wróć do tego państwa w atlasie.',
              ),
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Wróć na start'),
          ),
          if (!widget.daily) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go(
                session.isCapitalAt(session.index) ? '/capitals' : '/atlas',
              ),
              child: Text(
                session.isCapitalAt(session.index)
                    ? 'Wybierz inny poziom'
                    : 'Obejrzyj atlas',
              ),
            ),
          ],
        ],
      ),
    ),
  );

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
