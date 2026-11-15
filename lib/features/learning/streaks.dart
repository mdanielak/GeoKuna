import 'package:drift/drift.dart';

import '../../core/database/database.dart';
import '../atlas/continent.dart';

/// Streak rewards in days. Earned once the best streak on a continent
/// reaches them; derived from activity days, so nothing extra is stored.
const streakRewards = [3, 7, 10, 14, 20, 30, 40, 50, 60, 90];

/// „Nieprzykunowanie” tokens: one per [tokenEveryDays] streak days, at most
/// [maxTokens] per continent. One token covers one missed day.
const tokenEveryDays = 7, maxTokens = 3;

/// Missed days that a token can still save, offered on Today.
class StreakRescue {
  const StreakRescue({required this.missedDays, required this.streak});

  /// Local dates (yyyy-mm-dd) without an answer, oldest first.
  final List<String> missedDays;

  /// The streak that ends unless the days are saved.
  final int streak;
}

class StreakSummary {
  const StreakSummary({
    required this.current,
    required this.best,
    required this.practisedToday,
    this.bestBefore = 0,
    this.tokens = 0,
    this.tokenProgress = 0,
    this.tokenEarnedToday = false,
    this.rescue,
  });

  /// Best streak not counting the current one.
  final int bestBefore;
  final int current, best;
  final bool practisedToday;

  /// Tokens held now (0–[maxTokens]).
  final int tokens;

  /// Streak days collected towards the next token.
  final int tokenProgress;
  final bool tokenEarnedToday;
  final StreakRescue? rescue;

  /// Streak days still needed for the next token; null with a full set.
  int? get daysToNextToken =>
      tokens >= maxTokens ? null : tokenEveryDays - tokenProgress;

  /// Rewards earned so far (best streak, so a broken streak keeps them).
  List<int> get earnedRewards => [
    for (final days in streakRewards)
      if (best >= days) days,
  ];

  /// The next reward not earned yet; null after the last one.
  int? get nextReward => streakRewards.where((d) => d > best).firstOrNull;

  /// Days still needed for [nextReward] from the current streak.
  int? get daysToNextReward =>
      nextReward == null ? null : nextReward! - current;

  /// A reward reached today for the first time.
  int? get rewardToday =>
      practisedToday && current > bestBefore && streakRewards.contains(current)
      ? current
      : null;
}

class StreakStore {
  const StreakStore(this.db);
  final AppDatabase db;

  /// Replays the continent's calendar day by day: practice extends the
  /// streak and fills the token counter, a saved day only bridges the gap,
  /// a missed day ends the streak. Missed days right before today are not
  /// final yet: they become a [StreakRescue] while enough tokens are held.
  Future<StreakSummary> overview(Continent continent, {DateTime? now}) async {
    final local = (now ?? DateTime.now()).toLocal();
    final today = DateTime.utc(local.year, local.month, local.day);
    final practised = {
      for (final row in await (db.select(
        db.activityDays,
      )..where((d) => d.continent.equals(continent.name))).get())
        row.localDate,
    };
    final saves = {
      for (final row in await (db.select(
        db.streakSaves,
      )..where((s) => s.continent.equals(continent.name))).get())
        row.localDate: row.kept,
    };
    final todayKey = dateKey(today);
    if (practised.isEmpty) {
      return const StreakSummary(current: 0, best: 0, practisedToday: false);
    }
    var day = DateTime.parse('${(practised.toList()..sort()).first}T00:00:00Z');
    var streak = 0, best = 0, bestBefore = 0;
    var tokens = 0, progress = 0;
    var earnedToday = false;
    // Missed days not yet final (only the trailing ones stay pending).
    final pending = <String>[];
    var streakBeforeGap = 0;
    StreakRescue? rescue;
    void breakStreak() {
      if (streak > bestBefore) bestBefore = streak;
      streak = 0;
      progress = 0;
    }

    while (!day.isAfter(today)) {
      final key = dateKey(day);
      if (practised.contains(key)) {
        if (pending.isNotEmpty) {
          // Answering today first keeps the offer open until the day ends.
          if (key == todayKey && pending.length <= tokens) {
            rescue = StreakRescue(
              missedDays: [...pending],
              streak: streakBeforeGap,
            );
          }
          pending.clear();
          breakStreak();
        }
        streak++;
        if (streak > best) best = streak;
        if (tokens < maxTokens && ++progress == tokenEveryDays) {
          tokens++;
          progress = 0;
          if (key == todayKey) earnedToday = true;
        }
      } else if (saves[key] == true && tokens > 0 && pending.isEmpty) {
        // A spent token is replaced after a full 7 more streak days.
        tokens--;
        progress = 0;
      } else if (key != todayKey) {
        // Today without an answer yet is not a missed day.
        if (pending.isEmpty) streakBeforeGap = streak;
        if (saves[key] == false || streak == 0) {
          pending.clear();
          breakStreak();
        } else {
          pending.add(key);
        }
      }
      day = DateTime.utc(day.year, day.month, day.day + 1);
    }
    if (pending.isNotEmpty) {
      if (pending.length <= tokens) {
        rescue = StreakRescue(missedDays: pending, streak: streakBeforeGap);
      }
      breakStreak();
    }
    return StreakSummary(
      current: streak,
      best: best,
      practisedToday: practised.contains(todayKey),
      bestBefore: bestBefore,
      tokens: tokens,
      tokenProgress: progress,
      tokenEarnedToday: earnedToday,
      rescue: rescue,
    );
  }

  /// Spends one token per missed day ([keep]) or gives the streak up.
  Future<void> decide(
    Continent continent,
    StreakRescue rescue, {
    required bool keep,
    DateTime? now,
  }) => db.batch(
    (batch) => batch.insertAll(db.streakSaves, [
      for (final date in rescue.missedDays)
        StreakSavesCompanion.insert(
          continent: continent.name,
          localDate: date,
          kept: keep,
          decidedAt: (now ?? DateTime.now()).toUtc(),
        ),
    ], mode: InsertMode.insertOrReplace),
  );
}

String dateKey(DateTime day) =>
    '${day.year}-${day.month.toString().padLeft(2, '0')}'
    '-${day.day.toString().padLeft(2, '0')}';

/// Polish day count: „1 dzień”, otherwise „N dni”.
String daysLabel(int days) => days == 1 ? '1 dzień' : '$days dni';

/// Polish token count: „1 żeton”, „2 żetony”, „5 żetonów”.
String tokensLabel(int n) => n == 1
    ? '1 żeton'
    : (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20))
    ? '$n żetony'
    : '$n żetonów';
