import '../atlas/catalog.dart';
import '../atlas/continent.dart';
import '../settings/app_preferences.dart';
import 'learning_types.dart';

// These describe observed practice, never a percentage of mastered geography.
enum LearningProgressStatus {
  review('Do powtórki'),
  practising('Ćwiczysz'),
  insufficient('Za mało danych');

  const LearningProgressStatus(this.label);
  final String label;
}

class LearningProgressEntry {
  const LearningProgressEntry({
    required this.id,
    required this.country,
    required this.topic,
    required this.difficulty,
    required this.status,
    required this.reviewCount,
    required this.due,
    required this.lastReview,
    this.qualified = false,
    this.recoveryProgress,
  });
  final String id;
  final Country country;
  final String topic;
  final String difficulty;
  final LearningProgressStatus status;
  final int reviewCount;
  final DateTime? due;
  final DateTime? lastReview;

  /// True once qualified for medals (2+ delayed applied hits without miss).
  final bool qualified;

  /// Consecutive graded hits since the latest miss (0–2) while recovering.
  final int? recoveryProgress;

  bool get isHard => recoveryProgress != null;

  String get skillKey => '$topic:$difficulty';
  Continent get _area => Continent.ofArea(country.id);
  String get skillLabel => topic == 'flags'
      ? switch (difficulty) {
          'map' => '${_area.symbolLabel} · ${_area.areaAccusative} na mapie',
          'mapEasy' => '${_area.symbolLabel} · mapa (łatwy)',
          'mapVeryEasy' => '${_area.symbolLabel} · mapa (bardzo łatwy)',
          'choice' => '${_area.symbolLabel} · wybór ${_area.areaGenitive} A–D',
          'firstLetter' => '${_area.symbolLabel} · pierwsza litera',
          _ => '${_area.symbolLabel} · samodzielne pisanie',
        }
      : switch (difficulty) {
          'map' => 'Lokalizacja na mapie',
          'mapEasy' => 'Mapa · łatwy',
          'mapVeryEasy' => 'Mapa · bardzo łatwy',
          'choice' => '${_area.capitalSubject} · wybór A–D',
          'firstLetter' => '${_area.capitalSubject} · pierwsza litera',
          'write' => '${_area.capitalSubject} · samodzielne pisanie',
          _ => difficulty,
        };
}

/// Collapses the 12 per-country FSRS skills down to the categories for
/// [level], inheriting stronger levels downward (Normal -> Easy -> VeryEasy)
/// just like medals do.
List<LearningProgressEntry> effectiveEntriesForLevel(
  Iterable<LearningProgressEntry> entries,
  LearningDifficulty level,
) {
  final grouped = <(String, String), List<LearningProgressEntry>>{};
  for (final entry in entries) {
    final diff = SkillDifficulty.fromDb(entry.difficulty);
    if (diff.level.index < level.index) continue;
    final category = entry.topic == 'flags' && diff.isMap
        ? 'flagMap'
        : entry.topic;
    grouped.putIfAbsent((entry.country.id, category), () => []).add(entry);
  }
  int rank(LearningProgressStatus s) => switch (s) {
    LearningProgressStatus.practising => 2,
    LearningProgressStatus.review => 1,
    LearningProgressStatus.insufficient => 0,
  };
  return [
    for (final group in grouped.values)
      (() {
        final base = group.firstWhere(
          (e) => SkillDifficulty.fromDb(e.difficulty).level == level,
          orElse: () => group.first,
        );
        final best = group.reduce(
          (a, b) => rank(b.status) > rank(a.status) ? b : a,
        );
        return LearningProgressEntry(
          id: base.id,
          country: base.country,
          topic: base.topic,
          difficulty: base.difficulty,
          status: best.status,
          reviewCount: best.reviewCount,
          due: best.due,
          lastReview: best.lastReview,
          qualified: group.any((e) => e.qualified),
          recoveryProgress: base.recoveryProgress,
        );
      })(),
  ];
}
