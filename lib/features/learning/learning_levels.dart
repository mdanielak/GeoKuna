import '../settings/app_preferences.dart';
import 'learning_types.dart';

const mapDifficulties = ['mapVeryEasy', 'mapEasy', 'map'];

String mapDifficultyFor(LearningDifficulty level) =>
    AchievementCategory.map.difficultyFor(level).name;

LearningDifficulty levelForDifficulty(String difficulty) =>
    SkillDifficulty.fromDb(difficulty).level;

String difficultyForCategory(String topic, LearningDifficulty level) =>
    AchievementCategory.values.byName(topic).difficultyFor(level).name;
