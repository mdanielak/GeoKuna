import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

@TableIndex(name: 'sessions_open', columns: {#topic, #completedAt})
class Sessions extends Table {
  TextColumn get id => text()();
  TextColumn get countryIds => text()();
  TextColumn get continent => text().withDefault(const Constant('europe'))();
  IntColumn get currentIndex => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get topic => text().withDefault(const Constant('map'))();
  TextColumn get difficulty => text().withDefault(const Constant('map'))();
  TextColumn get questionData => text().withDefault(const Constant('[]'))();
  TextColumn get contentVersion =>
      text().withDefault(const Constant('europe-location-0.2.0'))();
  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'attempts_country', columns: {#countryId})
class Attempts extends Table {
  TextColumn get sessionId => text().references(Sessions, #id)();
  IntColumn get questionIndex => integer()();
  TextColumn get countryId => text()();
  TextColumn get answer => text()();
  BoolColumn get correct => boolean()();
  BoolColumn get typoAccepted => boolean().withDefault(const Constant(false))();
  TextColumn get topic => text().withDefault(const Constant('map'))();
  TextColumn get difficulty => text().withDefault(const Constant('map'))();
  DateTimeColumn get answeredAt => dateTime()();
  @override
  Set<Column> get primaryKey => {sessionId, questionIndex};
}

@DataClassName('MapGuess')
@TableIndex(name: 'map_guesses_selected', columns: {#selectedCountryId})
class MapGuesses extends Table {
  TextColumn get sessionId => text().references(Sessions, #id)();
  IntColumn get questionIndex => integer()();
  IntColumn get guessIndex => integer()();
  TextColumn get selectedCountryId => text()();
  BoolColumn get correct => boolean()();
  BoolColumn get assisted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get guessedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {sessionId, questionIndex, guessIndex};
}

@TableIndex(name: 'memory_cards_country', columns: {#countryId})
class MemoryCards extends Table {
  TextColumn get id => text()();
  TextColumn get countryId => text()();
  TextColumn get topic => text()();
  TextColumn get difficulty => text()();
  TextColumn get state => text().nullable()();
  DateTimeColumn get due => dateTime().nullable()();
  DateTimeColumn get introducedAt => dateTime().nullable()();
  IntColumn get reviewCount => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'memory_reviews_skill', columns: {#skillId, #reviewedAt})
@TableIndex(name: 'memory_reviews_time', columns: {#reviewedAt})
class MemoryReviews extends Table {
  TextColumn get sessionId => text().references(Sessions, #id)();
  IntColumn get questionIndex => integer()();
  TextColumn get skillId => text().references(MemoryCards, #id)();
  IntColumn get rating => integer()();
  DateTimeColumn get reviewedAt => dateTime()();
  BoolColumn get wasNew => boolean()();
  BoolColumn get applied => boolean()();
  TextColumn get origin => text()();
  TextColumn get reviewLog => text().nullable()();
  @override
  Set<Column> get primaryKey => {sessionId, questionIndex};
}

class MemoryMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('PreferenceEntry')
class AppPreferenceEntries extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

class ActivityDays extends Table {
  TextColumn get continent => text()();
  TextColumn get localDate => text()();
  DateTimeColumn get recordedAt => dateTime()();
  IntColumn get offsetMinutes => integer()();
  @override
  Set<Column> get primaryKey => {continent, localDate};
}

class AwardedMedals extends Table {
  TextColumn get continent => text()();
  TextColumn get topic => text()();
  TextColumn get level => text()();
  IntColumn get medal => integer()();
  DateTimeColumn get earnedAt => dateTime()();
  TextColumn get catalogVersion => text()();
  @override
  Set<Column> get primaryKey => {continent, topic, level, medal};
}

/// A missed streak day: covered by a „Nieprzykunowanie” token ([kept]) or
/// declined, so Today does not ask again. Token balance is derived from
/// activity days and these rows (see streaks.dart).
class StreakSaves extends Table {
  TextColumn get continent => text()();
  TextColumn get localDate => text()();
  BoolColumn get kept => boolean()();
  DateTimeColumn get decidedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {continent, localDate};
}

/// Per-item difficulty state when an area uses the „Automatyczny” level:
/// items start at normal, drop one step after 3 consecutive misses and climb
/// back after 2 consecutive hits.
class AutoLevels extends Table {
  TextColumn get itemId => text()();
  TextColumn get countryId => text()();
  TextColumn get level => text()();
  IntColumn get missStreak => integer().withDefault(const Constant(0))();
  IntColumn get hitStreak => integer().withDefault(const Constant(0))();
  BoolColumn get dueNow => boolean().withDefault(const Constant(false))();
  TextColumn get lastTransition => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {itemId};
}

@DriftDatabase(
  tables: [
    Sessions,
    Attempts,
    MemoryCards,
    MemoryReviews,
    MemoryMeta,
    MapGuesses,
    AppPreferenceEntries,
    ActivityDays,
    AwardedMedals,
    StreakSaves,
    AutoLevels,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);
  AppDatabase.local()
    : super(
        driftDatabase(
          name: 'geokuna',
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.dart.js'),
          ),
        ),
      );
  @override
  int get schemaVersion => 10;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(sessions, sessions.topic);
        await m.addColumn(sessions, sessions.difficulty);
        await m.addColumn(sessions, sessions.questionData);
        await m.addColumn(sessions, sessions.contentVersion);
        await m.renameColumn(attempts, 'selected_country_id', attempts.answer);
        await m.addColumn(attempts, attempts.typoAccepted);
        await m.addColumn(attempts, attempts.topic);
        await m.addColumn(attempts, attempts.difficulty);
      }
      if (from < 3) {
        await m.createTable(memoryCards);
        await m.createTable(memoryReviews);
        await m.createTable(memoryMeta);
      }
      if (from < 4) {
        await m.createTable(mapGuesses);
      }
      if (from < 5) {
        await m.addColumn(sessions, sessions.continent);
      }
      if (from < 6) {
        await m.createTable(appPreferenceEntries);
      }
      if (from < 7) {
        await m.createTable(activityDays);
        await m.createTable(awardedMedals);
      }
      if (from < 8) {
        // Lookups by skill, country and day; history grows every answer.
        for (final index in [
          sessionsOpen,
          attemptsCountry,
          mapGuessesSelected,
          memoryCardsCountry,
          memoryReviewsSkill,
          memoryReviewsTime,
        ]) {
          await m.createIndex(index);
        }
      }
      if (from < 9) {
        await m.createTable(streakSaves);
      }
      if (from < 10) {
        await m.createTable(autoLevels);
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
