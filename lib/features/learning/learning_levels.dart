import '../settings/app_preferences.dart';

const mapDifficulties = ['mapVeryEasy', 'mapEasy', 'map'];

String mapDifficultyFor(LearningDifficulty level) => switch (level) {
  LearningDifficulty.veryEasy => 'mapVeryEasy',
  LearningDifficulty.easy => 'mapEasy',
  LearningDifficulty.normal => 'map',
};

LearningDifficulty levelForDifficulty(String difficulty) =>
    switch (difficulty) {
      'choice' || 'mapVeryEasy' => LearningDifficulty.veryEasy,
      'firstLetter' || 'mapEasy' => LearningDifficulty.easy,
      _ => LearningDifficulty.normal,
    };

String difficultyForCategory(String topic, LearningDifficulty level) =>
    topic == 'map' || topic == 'flagMap' ? mapDifficultyFor(level) : level.mode;
