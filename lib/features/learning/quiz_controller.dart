import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../atlas/catalog.dart';
import '../settings/app_preferences.dart';
import 'capitals.dart';
import 'flags.dart';
import 'session_repository.dart';

/// Which series a quiz screen runs.
class QuizKind {
  const QuizKind({
    this.daily = false,
    this.dailyMode = DailyMode.regular,
    this.flags,
    this.capitals,
    this.level,
  });
  final bool daily;

  /// Level of a daily series that ignores the area's setting (placement).
  final LearningDifficulty? level;
  final DailyMode dailyMode;
  final FlagDifficulty? flags;
  final CapitalDifficulty? capitals;
}

/// Quiz logic behind [LearningScreen]: opening a series, saving answers and
/// finishing. The screen keeps only input state (selection, typed text).
/// Every saved answer refreshes the views that show progress.
class QuizController {
  QuizController(this.ref);
  final Ref ref;

  SessionRepository get _repository => ref.read(repositoryProvider);

  /// The open series of [kind], or a new one; null when Today has nothing.
  Future<(Catalog, LearningSession?)> open(QuizKind kind) async {
    await ref.read(appPreferencesProvider.future);
    final repository = _repository;
    final catalog = await ref.read(catalogProvider.future);
    Future<LearningSession?> start() async {
      if (kind.daily) {
        final daily = kind.level == null
            ? repository
            : SessionRepository(
                repository.db,
                continent: repository.continent,
                level: kind.level!,
              );
        return daily.startDaily(
          catalog,
          await ref.read(capitalsProvider.future),
          flags: await ref.read(flagsProvider.future),
          mode: kind.dailyMode,
        );
      } else if (kind.flags != null) {
        return repository.startFlags(
          await ref.read(flagsProvider.future),
          kind.flags!,
        );
      } else if (kind.capitals != null) {
        return repository.startCapitals(
          await ref.read(capitalsProvider.future),
          kind.capitals!,
        );
      }
      return repository.start(catalog.countries.map((c) => c.id).toList());
    }

    var session = await start();
    // A series started before a catalog change (e.g. countries moved to
    // another continent) is closed with its answers kept, then replaced.
    final known = catalog.countries.map((c) => c.id).toSet();
    if (session != null && !session.countryIds.every(known.contains)) {
      await repository.finish(session.row.id);
      session = await start();
    }
    ref
      ..invalidate(dashboardProvider)
      ..invalidate(dailyOverviewProvider);
    return (catalog, session);
  }

  /// One map guess; the session is unchanged when [id] was already guessed.
  Future<LearningSession> guess(
    Catalog catalog,
    LearningSession session,
    String id,
  ) async {
    final updated = await _repository.guessMap(
      session.row.id,
      session.index,
      id,
      catalog.countries.map((c) => c.id).toSet(),
      expectedGuessIndex: session.currentMapGuesses.length,
    );
    _answered(updated);
    return updated;
  }

  /// Saves the answer to the current question, or moves on once answered.
  Future<LearningSession> submit(
    Catalog catalog,
    LearningSession session, {
    required String? selected,
    required String typed,
    bool gaveUp = false,
  }) async {
    final repository = _repository;
    final id = session.row.id, index = session.index;
    final LearningSession updated;
    if (session.currentAttempt != null) {
      updated = await repository.advance(id, index);
    } else if (session.isFlagAt(index)) {
      updated = await repository.answerFlag(
        id,
        index,
        session.flagDifficulty == FlagDifficulty.choice ? selected! : typed,
        gaveUp: gaveUp,
      );
    } else if (session.isCapitalAt(index)) {
      updated = await repository.answerCapital(
        id,
        index,
        session.difficultyAt(index) == CapitalDifficulty.choice
            ? selected!
            : typed,
        gaveUp: gaveUp,
      );
    } else {
      throw StateError('Pytania mapowe zapisujemy przez guess().');
    }
    _answered(updated);
    return updated;
  }

  /// Ends the series early; graded answers stay.
  Future<LearningSession> finish(LearningSession session) async {
    final finished = await _repository.finish(session.row.id);
    ref.invalidate(dashboardProvider);
    _seriesEnded();
    return finished;
  }

  /// Cheap views refresh after every answer. Today's plan, medals and full
  /// progress are costly (they read history) and stay mounted under the quiz,
  /// so they refresh once: when the series ends, or when Today regains focus
  /// after the quiz is left early.
  void _answered(LearningSession updated) {
    ref
      ..invalidate(dashboardProvider)
      ..invalidate(streakProvider);
    if (updated.completed) _seriesEnded();
  }

  void _seriesEnded() => ref
    ..invalidate(dailyOverviewProvider)
    ..invalidate(learningProgressProvider)
    ..invalidate(continentProgressProvider)
    ..invalidate(achievementsProvider)
    ..invalidate(continentAchievementsProvider)
    ..invalidate(continentStreakProvider);
}

final quizControllerProvider = Provider<QuizController>(QuizController.new);
