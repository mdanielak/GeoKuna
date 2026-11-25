import 'dart:convert';

import '../../core/database/database.dart';
import 'capitals.dart';
import 'flags.dart';
import 'learning_levels.dart';
import 'learning_types.dart';

class LearningSession {
  LearningSession(
    this.row,
    this.countryIds,
    this.attempts, {
    Set<int> assistedIndices = const {},
    this.mapGuesses = const [],
    this.insight,
    // Preserve the public argument while exposing combined assistance evidence.
    // ignore: prefer_initializing_formals
  }) : _assistedIndices = assistedIndices,
       _questions = jsonDecode(row.questionData) as List<dynamic>;

  final Set<int> _assistedIndices;
  final List<MapGuess> mapGuesses;
  final QuestionInsight? insight;
  final List<dynamic> _questions;

  Set<int> get assistedIndices => {
    ..._assistedIndices,
    ...mapGuesses.where((g) => g.assisted).map((g) => g.questionIndex),
  };

  /// The current question was answered with „Nie wiem, pomóż” (only that
  /// path stores an empty answer).
  bool get gaveUpCurrent => currentAttempt?.answer.isEmpty ?? false;

  List<MapGuess> get currentMapGuesses =>
      mapGuesses.where((g) => g.questionIndex == index).toList();

  final Session row;
  final List<String> countryIds;
  final List<Attempt> attempts;
  bool get completed => row.completedAt != null;
  int get index => row.currentIndex;
  bool get isDaily => row.topic == QuizTopic.daily.name;

  String topicAt(int i) =>
      isDaily ? _questions[i]['topic'] as String : row.topic;

  String difficultyNameAt(int i) =>
      isDaily ? _questions[i]['difficulty'] as String : row.difficulty;

  bool isFlagAt(int i) => topicAt(i) == QuizTopic.flags.name;

  bool isMapAt(int i) =>
      topicAt(i) == QuizTopic.map.name ||
      (isFlagAt(i) && mapDifficulties.contains(difficultyNameAt(i)));

  FlagDifficulty get flagDifficulty => isMapAt(index)
      ? FlagDifficulty.map
      : FlagDifficulty.values.byName(difficultyNameAt(index));

  FlagQuestion flagQuestionAt(int i) =>
      FlagQuestion.fromJson(_questions[i] as Map<String, dynamic>);

  bool isCapitalAt(int i) => topicAt(i) == QuizTopic.capitals.name;
  bool get isCapital => isCapitalAt(index);

  CapitalDifficulty difficultyAt(int i) =>
      CapitalDifficulty.values.byName(difficultyNameAt(i));

  CapitalQuestion capitalQuestionAt(int i) =>
      CapitalQuestion.fromJson(_questions[i] as Map<String, dynamic>);

  CapitalDifficulty get difficulty => difficultyAt(index);

  List<CapitalQuestion> get capitalQuestions => _questions
      .map((q) => CapitalQuestion.fromJson(q as Map<String, dynamic>))
      .toList();

  CapitalQuestion get capitalQuestion => capitalQuestionAt(index);
  String get targetId => countryIds[index];

  Attempt? get currentAttempt {
    for (final attempt in attempts) {
      if (attempt.questionIndex == index) return attempt;
    }
    return null;
  }

  /// A repeat of a missed question later in the same daily series.
  bool isRetryAt(int i) =>
      isDaily && i < _questions.length && _questions[i]['retry'] == true;

  /// An easier, unscored ladder step before a stubborn skill's real question.
  bool isScaffoldAt(int i) => originAt(i) == ReviewOrigin.scaffold.name;

  /// The country a stubborn skill keeps being confused with, asked right
  /// after it as unscored practice (ladder step 2).
  bool isContrastAt(int i) => originAt(i) == ReviewOrigin.contrast.name;

  /// Practice inside a daily series: never scored and never an FSRS grade.
  bool isPracticeAt(int i) =>
      isRetryAt(i) || isScaffoldAt(i) || isContrastAt(i);

  /// Special origin stored in the daily snapshot (`control`, `placement`,
  /// `scaffold`, `contrast`).
  String? originAt(int i) => isDaily && i < _questions.length
      ? _questions[i]['origin'] as String?
      : null;

  String skillIdAt(int i) =>
      '${topicAt(i)}:${countryIds[i]}:${difficultyNameAt(i)}';

  List<Attempt> get scoredAttempts => attempts
      .where(
        (a) =>
            !assistedIndices.contains(a.questionIndex) &&
            !isPracticeAt(a.questionIndex),
      )
      .toList();

  /// Whether the first graded try on question [questionIndex] was correct.
  /// For map questions, guessing on the 2nd or 3rd try counts as a miss.
  bool isFirstTryCorrectAt(int questionIndex) {
    final first = mapGuesses
        .where((g) => g.questionIndex == questionIndex && g.guessIndex == 0)
        .firstOrNull;
    if (first != null) return first.correct;
    for (final attempt in attempts) {
      if (attempt.questionIndex == questionIndex) return attempt.correct;
    }
    return false;
  }

  int get correctCount =>
      scoredAttempts.where((a) => isFirstTryCorrectAt(a.questionIndex)).length;
}

/// Learning hints for the current, already answered question.
class QuestionInsight {
  const QuestionInsight({
    this.recovery,
    this.confusedWithId,
    this.confusedWithName,
  });

  /// Correct answers in a row since the last miss of a hard skill (1–3).
  final int? recovery;

  /// A country chosen by mistake on the map for this target before and again now.
  final String? confusedWithId;

  /// A country name given by mistake for this target's flag before and again now.
  final String? confusedWithName;
}

class MemoryOverview {
  const MemoryOverview({
    required this.dueCount,
    required this.newAvailable,
    required this.newRemainingToday,
    required this.reviewedToday,
    required this.nextDue,
    required this.plannedCount,
    required this.plannedNewCount,
    required this.activeSession,
    this.reservedNewElsewhere = 0,
    this.otherDueCount = 0,
    this.learnedCount = 0,
    this.firstVisit = false,
  });

  /// Nothing was ever started in this area (see [SessionRepository.firstVisit]).
  final bool firstVisit;

  /// Cards of this level with at least one graded answer.
  final int learnedCount;

  /// Another round today has something worth asking.
  bool get canStartExtra => newAvailable > 0 || learnedCount > 0;
  final int dueCount,
      newAvailable,
      newRemainingToday,
      reviewedToday,
      plannedCount,
      plannedNewCount;
  final int reservedNewElsewhere;
  final int otherDueCount;
  final DateTime? nextDue;
  final LearningSession? activeSession;
}
