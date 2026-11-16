import '../atlas/catalog.dart';
import '../atlas/continent.dart';

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
  });
  final String id;
  final Country country;
  final String topic;
  final String difficulty;
  final LearningProgressStatus status;
  final int reviewCount;
  final DateTime? due;
  final DateTime? lastReview;

  String get skillKey => '$topic:$difficulty';
  Continent get _area => Continent.ofArea(country.id);
  String get skillLabel => topic == 'flags'
      ? switch (difficulty) {
          'map' => '${_area.symbolLabel} · ${_area.areaAccusative} na mapie',
          'mapEasy' => '${_area.symbolLabel} → mapa · łatwy',
          'mapVeryEasy' => '${_area.symbolLabel} → mapa · bardzo łatwy',
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
