import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/database/database.dart';

/// What an import restored, for the confirmation message.
class BackupSummary {
  const BackupSummary({required this.answers, required this.days});
  final int answers, days;
}

/// Rejected file: [message] is shown to the user as is.
class BackupException implements Exception {
  const BackupException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Whole-device progress as one JSON file: sessions, answers, FSRS cards and
/// reviews, streak days, medals and preferences. Import replaces everything
/// in one transaction, so a bad file never leaves half a state behind.
class ProgressBackup {
  const ProgressBackup(this.db);
  final AppDatabase db;

  static const format = 'geokuna-progress';
  static const version = 1;

  String fileName(DateTime now) =>
      'geokuna-postep-${now.year}-${_two(now.month)}-${_two(now.day)}.json';

  Future<String> export({DateTime? now}) async {
    List<Map<String, dynamic>> rows(List<DataClass> list) => [
      for (final row in list) row.toJson(),
    ];
    return jsonEncode({
      'format': format,
      'version': version,
      'schema': db.schemaVersion,
      'exported_at': (now ?? DateTime.now()).toUtc().toIso8601String(),
      'tables': {
        'sessions': rows(await db.select(db.sessions).get()),
        'attempts': rows(await db.select(db.attempts).get()),
        'map_guesses': rows(await db.select(db.mapGuesses).get()),
        'memory_cards': rows(await db.select(db.memoryCards).get()),
        'memory_reviews': rows(await db.select(db.memoryReviews).get()),
        'memory_meta': rows(await db.select(db.memoryMeta).get()),
        'preferences': rows(await db.select(db.appPreferenceEntries).get()),
        'activity_days': rows(await db.select(db.activityDays).get()),
        'awarded_medals': rows(await db.select(db.awardedMedals).get()),
      },
    });
  }

  /// Checks the whole file before touching the database.
  Future<BackupSummary> import(String text) async {
    final Object? data;
    try {
      data = jsonDecode(text);
    } on FormatException {
      throw const BackupException('To nie jest plik kopii GeoKuny.');
    }
    if (data case {
      'format': format,
      'version': final int fileVersion,
      'schema': final int schema,
      'tables': final Map<String, dynamic> tables,
    }) {
      if (fileVersion > version || schema > db.schemaVersion) {
        throw const BackupException(
          'Kopia pochodzi z nowszej wersji aplikacji. Zaktualizuj GeoKunę.',
        );
      }
      List<T> parse<T>(String key, T Function(Map<String, dynamic>) from) {
        final list = tables[key];
        if (list is! List) {
          throw const BackupException('Kopia jest niepełna.');
        }
        return [for (final row in list) from(row as Map<String, dynamic>)];
      }

      try {
        final sessions = parse('sessions', Session.fromJson);
        final attempts = parse('attempts', Attempt.fromJson);
        final guesses = parse('map_guesses', MapGuess.fromJson);
        final cards = parse('memory_cards', MemoryCard.fromJson);
        final reviews = parse('memory_reviews', MemoryReview.fromJson);
        final meta = parse('memory_meta', MemoryMetaData.fromJson);
        final preferences = parse('preferences', PreferenceEntry.fromJson);
        final days = parse('activity_days', ActivityDay.fromJson);
        final medals = parse('awarded_medals', AwardedMedal.fromJson);
        await db.transaction(() async {
          // Children first: foreign keys point at sessions and cards.
          for (final table in <TableInfo<Table, Object?>>[
            db.memoryReviews,
            db.mapGuesses,
            db.attempts,
            db.sessions,
            db.memoryCards,
            db.memoryMeta,
            db.appPreferenceEntries,
            db.activityDays,
            db.awardedMedals,
          ]) {
            await db.delete(table).go();
          }
          await db.batch((batch) {
            batch
              ..insertAll(db.sessions, sessions)
              ..insertAll(db.memoryCards, cards)
              ..insertAll(db.attempts, attempts)
              ..insertAll(db.mapGuesses, guesses)
              ..insertAll(db.memoryReviews, reviews)
              ..insertAll(db.memoryMeta, meta)
              ..insertAll(db.appPreferenceEntries, preferences)
              ..insertAll(db.activityDays, days)
              ..insertAll(db.awardedMedals, medals);
          });
        });
        return BackupSummary(answers: attempts.length, days: days.length);
      } on BackupException {
        rethrow;
      } catch (_) {
        throw const BackupException(
          'Kopia jest uszkodzona. Obecny postęp został bez zmian.',
        );
      }
    }
    throw const BackupException('To nie jest plik kopii GeoKuny.');
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
