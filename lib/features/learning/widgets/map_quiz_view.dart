import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/database/database.dart';
import '../../atlas/catalog.dart';
import '../../atlas/country_map.dart';
import '../../settings/app_preferences.dart';
import '../country_trivia.dart';
import '../learning_session.dart';
import '../memory.dart';
import 'quiz_shared_widgets.dart';

class MapQuizView extends ConsumerWidget {
  const MapQuizView({
    super.key,
    required this.catalog,
    required this.session,
    required this.selected,
    required this.attempt,
    required this.busy,
    required this.questionLabel,
    required this.trivia,
    required this.onSelected,
    required this.onNext,
  });

  final Catalog catalog;
  final LearningSession session;
  final String? selected;
  final Attempt? attempt;
  final bool busy;
  final String questionLabel;
  final CountryTriviaFact? trivia;
  final ValueChanged<String> onSelected;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final difficulty = session.difficultyNameAt(session.index);
    final supportLevel = switch (difficulty) {
      'mapVeryEasy' => 'veryEasy',
      'mapEasy' => 'easy',
      _ => 'normal',
    };
    final quizSeed = '${session.row.id}:${session.index}';
    final textTheme = Theme.of(context).textTheme;
    final colors = GeoColors.of(context);
    final progress =
        (session.index + (attempt != null ? 1 : 0)) / session.countryIds.length;
    final foundLater =
        attempt != null &&
        attempt!.correct &&
        !session.isFirstTryCorrectAt(session.index);
    final feedbackBg = foundLater
        ? colors.typoContainer
        : (attempt?.correct ?? false)
        ? colors.correctContainer
        : colors.wrongContainer;
    final feedbackFg = foundLater
        ? colors.onTypoContainer
        : (attempt?.correct ?? false)
        ? colors.onCorrectContainer
        : colors.onWrongContainer;
    final feedbackIcon = foundLater
        ? Icons.info_outline
        : (attempt?.correct ?? false)
        ? Icons.check_circle_outline
        : Icons.cancel_outlined;

    // The question sits above the map so it never covers countries or labels.
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                questionLabel,
                style: textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (session.isAutoEasierAt(session.index))
                AutoEasierChip(
                  countryName: session.isFlagAt(session.index)
                      ? null
                      : catalog.country(session.targetId).name,
                ),
            ],
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
                FlagFrame(
                  assetPath: session.flagQuestionAt(session.index).assetPath,
                  semanticLabel:
                      '${ref.watch(selectedContinentProvider).symbolLabel} do rozpoznania',
                  height: 56,
                ),
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
                  revealId: attempt != null && !attempt!.correct
                      ? session.targetId
                      : null,
                  locked: attempt != null || busy,
                  revealBottomInset: MediaQuery.sizeOf(context).height * .32,
                  onSelected: onSelected,
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
                                          color: feedbackBg,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              feedbackIcon,
                                              color: feedbackFg,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                _feedback(catalog, session),
                                                style: TextStyle(
                                                  color: feedbackFg,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  InsightNote(
                                    catalog: catalog,
                                    session: session,
                                  ),
                                  if (trivia != null) ...[
                                    TriviaCard(text: trivia!.text),
                                    const SizedBox(height: 12),
                                  ],
                                  FilledButton(
                                    onPressed: busy ? null : onNext,
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
}

/// Short learning hints after an answer: recovery of a hard country and a
/// pair that keeps being confused. Shown below the feedback, never blocking.
class InsightNote extends StatelessWidget {
  const InsightNote({super.key, required this.catalog, required this.session});
  final Catalog catalog;
  final LearningSession session;

  @override
  Widget build(BuildContext context) {
    final insight = session.insight;
    if (insight == null) return const SizedBox.shrink();
    final practice = session.isPracticeAt(session.index);
    final lines = [
      ?insight.autoNotice,
      if (!practice) ...[
        if (insight.recovery case final done?)
          done >= recoveryTarget
              ? '${catalog.continent.hardAreaMasteredLabel}: $done z $recoveryTarget trafień z rzędu.'
              : '${catalog.continent.hardAreaLabel}: $done z $recoveryTarget trafień z rzędu.',
        if (insight.confusedWithId case final other?)
          'Ta para już się myliła: ${catalog.country(session.targetId).name} '
              'i ${catalog.country(other).name}. Porównaj ich położenie.',
        if (insight.confusedWithName case final otherName?)
          'Ta para już się myliła: ${catalog.country(session.targetId).name} '
              'i $otherName.',
      ],
    ];
    if (lines.isEmpty) return const SizedBox.shrink();
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
