import '../settings/app_preferences.dart';

/// Quiz topic stored in `sessions.topic`, `attempts.topic` and skill IDs.
enum QuizTopic {
  map,
  capitals,
  flags,
  daily;

  static QuizTopic fromDb(String value) => values.byName(value);
}

/// Achievement / medal category; `flagMap` maps to `flags` in storage.
enum AchievementCategory {
  map,
  capitals,
  flags,
  flagMap;

  static const all = values;

  QuizTopic get storageTopic => switch (this) {
    AchievementCategory.map => QuizTopic.map,
    AchievementCategory.capitals => QuizTopic.capitals,
    AchievementCategory.flags || AchievementCategory.flagMap => QuizTopic.flags,
  };

  SkillDifficulty difficultyFor(LearningDifficulty level) => switch (this) {
    AchievementCategory.map || AchievementCategory.flagMap => switch (level) {
      LearningDifficulty.veryEasy => SkillDifficulty.mapVeryEasy,
      LearningDifficulty.easy => SkillDifficulty.mapEasy,
      LearningDifficulty.normal => SkillDifficulty.map,
    },
    AchievementCategory.capitals ||
    AchievementCategory.flags => switch (level) {
      LearningDifficulty.veryEasy => SkillDifficulty.choice,
      LearningDifficulty.easy => SkillDifficulty.firstLetter,
      LearningDifficulty.normal => SkillDifficulty.write,
    },
  };
}

/// Difficulty / format stored in `memory_cards.difficulty` and skill IDs.
enum SkillDifficulty {
  map,
  mapEasy,
  mapVeryEasy,
  choice,
  firstLetter,
  write;

  static SkillDifficulty fromDb(String value) => values.byName(value);

  bool get isMap => this == map || this == mapEasy || this == mapVeryEasy;

  /// Formats where a first correct answer is unaided recall, not recognition.
  bool get isRecall => this == write || this == map;

  LearningDifficulty get level => switch (this) {
    choice || mapVeryEasy => LearningDifficulty.veryEasy,
    firstLetter || mapEasy => LearningDifficulty.easy,
    write || map => LearningDifficulty.normal,
  };

  /// Easier format used as the ladder step, or null when none is easier.
  SkillDifficulty? scaffoldFor(QuizTopic topic) => switch ((topic, this)) {
    (QuizTopic.capitals || QuizTopic.flags, write || firstLetter) => choice,
    (QuizTopic.map || QuizTopic.flags, map || mapEasy) => mapVeryEasy,
    _ => null,
  };
}

/// Origin of a review stored in `memory_reviews.origin`.
enum ReviewOrigin {
  daily,
  manual,
  retry,
  scaffold,
  contrast,
  control,
  placement,
  assisted,
  recognition;

  static ReviewOrigin fromDb(String value) => values.byName(value);

  bool get isPractice =>
      this == retry ||
      this == scaffold ||
      this == contrast ||
      this == assisted ||
      this == recognition;
}
