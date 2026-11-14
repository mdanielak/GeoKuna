import '../../core/database/database.dart';
import '../atlas/continent.dart';

class StreakSummary {
  const StreakSummary({
    required this.current,
    required this.best,
    required this.practisedToday,
  });
  final int current, best;
  final bool practisedToday;
}

class StreakStore {
  const StreakStore(this.db);
  final AppDatabase db;

  Future<StreakSummary> overview(Continent continent, {DateTime? now}) async {
    final local = (now ?? DateTime.now()).toLocal();
    final today = DateTime.utc(local.year, local.month, local.day);
    final rows = await (db.select(
      db.activityDays,
    )..where((d) => d.continent.equals(continent.name))).get();
    final days =
        rows
            .map((r) => DateTime.parse('${r.localDate}T00:00:00Z'))
            .where((d) => !d.isAfter(today))
            .toSet()
            .toList()
          ..sort();
    final set = days.toSet();
    final practised = set.contains(today);
    var cursor = practised ? today : today.subtract(const Duration(days: 1));
    var current = 0;
    while (set.contains(cursor)) {
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var best = 0;
    var run = 0;
    DateTime? previous;
    for (final day in days) {
      run = previous != null && day.difference(previous).inDays == 1
          ? run + 1
          : 1;
      if (run > best) best = run;
      previous = day;
    }
    return StreakSummary(
      current: current,
      best: best,
      practisedToday: practised,
    );
  }
}

/// Polish day count: „1 dzień”, otherwise „N dni”.
String daysLabel(int days) => days == 1 ? '1 dzień' : '$days dni';
