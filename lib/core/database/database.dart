import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

class Sessions extends Table {
  TextColumn get id => text()();
  TextColumn get countryIds => text()();
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

@DriftDatabase(
  tables: [
    Sessions,
    Attempts,
    MemoryCards,
    MemoryReviews,
    MemoryMeta,
    MapGuesses,
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
  int get schemaVersion => 4;
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
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
