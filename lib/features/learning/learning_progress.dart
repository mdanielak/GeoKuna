import '../atlas/catalog.dart';

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
  String get skillLabel => topic == 'flags'
      ? switch (difficulty) {
          'map' => 'Flaga · państwo na mapie',
          'mapEasy' => 'Flaga → mapa · łatwy',
          'mapVeryEasy' => 'Flaga → mapa · bardzo łatwy',
          'choice' => 'Flaga · wybór państwa A–D',
          'firstLetter' => 'Flaga · pierwsza litera',
          _ => 'Flaga · samodzielne pisanie',
        }
      : switch (difficulty) {
          'map' => 'Lokalizacja na mapie',
          'mapEasy' => 'Mapa · łatwy',
          'mapVeryEasy' => 'Mapa · bardzo łatwy',
          'choice' => 'Stolica · wybór A–D',
          'firstLetter' => 'Stolica · pierwsza litera',
          'write' => 'Stolica · samodzielne pisanie',
          _ => difficulty,
        };
}
