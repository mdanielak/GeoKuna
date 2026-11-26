import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/database/database.dart';
import '../../atlas/catalog.dart';
import '../../atlas/continent.dart';
import '../learning_session.dart';
import '../learning_types.dart';
import '../mascot_feedback.dart';
import '../streaks.dart';
import '../token_icon.dart';

class QuizSummaryView extends ConsumerWidget {
  const QuizSummaryView({
    super.key,
    required this.catalog,
    required this.session,
    required this.daily,
  });

  final Catalog catalog;
  final LearningSession session;
  final bool daily;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confirmedCount = session.attempts.length;
    final isPartial = confirmedCount < session.countryIds.length;
    final scoredAttempts = session.scoredAttempts;
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
                  : daily
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
                'Ćwiczenia w serii (powtórki i pary): $retryCount — nie liczą się do wyniku.',
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
            if (daily && confirmedCount > 0) ...[
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
            if (!daily) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  if (session.isFlagAt(0)) {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                      context.push('/flags');
                    }
                  } else {
                    context.go('/atlas');
                  }
                },
                child: Text(
                  session.isFlagAt(0)
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
}

enum _ResultStatus { correct, foundLater, wrong }

/// One summary line; [given] is what the learner typed, chose or pointed
/// at, shown after a tap on a wrong (or typo) answer.
typedef _Result = ({
  _ResultStatus status,
  String title,
  String detail,
  String? given,
  String? practiceTag,
});

_Result _resultRow(Catalog catalog, LearningSession session, Attempt attempt) {
  final i = attempt.questionIndex;
  final typo = attempt.typoAccepted ? ', literówka' : '';
  final practiceTag = session.isRetryAt(i)
      ? 'powtórka'
      : session.isScaffoldAt(i)
      ? 'podpowiedź'
      : session.isContrastAt(i)
      ? 'para'
      : null;
  String nameOf(String id) =>
      catalog.countries.any((c) => c.id == id) ? catalog.country(id).name : id;
  final verb = attempt.difficulty == 'choice' ? 'Wybrano' : 'Wpisano';
  final String detail;
  String? given;
  final symbolLower = catalog.continent.symbolLabel.toLowerCase();
  if (session.assistedIndices.contains(i)) {
    detail = 'z pomocą';
  } else if (attempt.answer.isEmpty && attempt.topic != 'map') {
    // „Nie wiem, pomóż” stores no typed answer.
    detail = attempt.topic == 'capitals'
        ? session.capitalQuestionAt(i).fact.name
        : symbolLower;
    given = 'Nie wiem — pomoc A–D';
  } else if (attempt.topic == 'capitals') {
    detail = '${session.capitalQuestionAt(i).fact.name}$typo';
    given = '$verb: ${attempt.answer}';
  } else if (attempt.topic == 'flags' &&
      !mapDifficulties.contains(attempt.difficulty)) {
    detail = '$symbolLower$typo';
    given = '$verb: ${nameOf(attempt.answer)}';
  } else {
    final guesses = session.mapGuesses
        .where((g) => g.questionIndex == i)
        .toList();
    final mapPrefix = !session.isDaily
        ? ''
        : attempt.topic == 'flags'
        ? '$symbolLower na mapie · '
        : 'mapa · ';
    detail = !attempt.correct
        ? '${mapPrefix}nie odnaleziono'
        : guesses.length > 1
        ? '${mapPrefix}za ${guesses.length}. razem'
        : '${mapPrefix}od razu';
    final wrong = [
      for (final g in guesses)
        if (g.selectedCountryId != attempt.countryId)
          nameOf(g.selectedCountryId),
    ];
    if (wrong.isNotEmpty) given = 'Wskazano: ${wrong.join(', ')}';
  }
  final status = !attempt.correct
      ? _ResultStatus.wrong
      : session.isFirstTryCorrectAt(i)
      ? _ResultStatus.correct
      : _ResultStatus.foundLater;
  return (
    status: status,
    title: catalog.country(attempt.countryId).name,
    detail: detail,
    // Only mistakes and typos open; a clean answer has nothing to add.
    given:
        !attempt.correct ||
            attempt.typoAccepted ||
            given?.startsWith('Wskazano') == true
        ? given
        : null,
    practiceTag: practiceTag,
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
            Material(
              color: row.practiceTag != null
                  ? GeoTheme.creamCard.withValues(alpha: .45)
                  : Colors.transparent,
              child: InkWell(
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
                          if (row.practiceTag != null &&
                              row.status == _ResultStatus.wrong)
                            const Icon(
                              Icons.replay_circle_filled,
                              size: 20,
                              color: Color(0xFFD08A00),
                              semanticLabel: 'Ćwiczenie — błąd',
                            )
                          else
                            switch (row.status) {
                              _ResultStatus.correct => Icon(
                                Icons.check_circle,
                                size: 20,
                                color: colors.correct,
                                semanticLabel: 'Dobrze',
                              ),
                              _ResultStatus.foundLater => Icon(
                                Icons.info_outline,
                                size: 20,
                                color: colors.onTypoContainer,
                                semanticLabel: 'Odnaleziono w kolejnej próbie — błąd w pierwszej',
                              ),
                              _ResultStatus.wrong => Icon(
                                Icons.cancel,
                                size: 20,
                                color: colors.wrong,
                                semanticLabel: 'Błąd',
                              ),
                            },
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  row.title,
                                  style: theme.textTheme.bodyLarge,
                                ),
                                if (row.practiceTag case final tag?)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.typoContainer,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        tag,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: colors.onTypoContainer,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 165),
                            child: Text(
                              row.detail,
                              textAlign: TextAlign.end,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 20,
                            child: row.given != null
                                ? Icon(
                                    _open.contains(index)
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    size: 20,
                                    semanticLabel: _open.contains(index)
                                        ? 'Zwiń'
                                        : 'Pokaż odpowiedź',
                                  )
                                : null,
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
                                padding: const EdgeInsets.only(
                                  left: 30,
                                  top: 4,
                                ),
                                child: Text(
                                  row.given!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: row.status == _ResultStatus.correct
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
