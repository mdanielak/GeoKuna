import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/database.dart';
import '../features/atlas/catalog.dart';
import '../features/atlas/continent.dart';
import '../features/learning/session_repository.dart';
import '../features/learning/capitals.dart';
import '../features/learning/flags.dart';
import '../features/learning/learning_progress.dart';
import '../features/learning/achievements.dart';
import '../features/learning/streaks.dart';
import '../features/learning/country_trivia.dart';
import '../features/learning/learning_reset.dart';
import '../features/settings/app_preferences.dart';
import '../features/settings/progress_backup.dart';

class SelectedContinent extends Notifier<Continent> {
  @override
  Continent build() => Continent.europe;
  void select(Continent continent) => state = continent;
}

final selectedContinentProvider =
    NotifierProvider<SelectedContinent, Continent>(SelectedContinent.new);
final catalogProvider = FutureProvider<Catalog>(
  (ref) => Catalog.load(continent: ref.watch(selectedContinentProvider)),
);
final capitalsProvider = FutureProvider<CapitalCatalog>((ref) async {
  final continent = ref.watch(selectedContinentProvider);
  final catalog = await ref.watch(catalogProvider.future);
  final capitals = await CapitalCatalog.load(continent: continent);
  if (capitals.facts
          .map((f) => f.countryId)
          .toSet()
          .difference(catalog.countries.map((c) => c.id).toSet())
          .isNotEmpty ||
      capitals.facts.length != catalog.countries.length) {
    throw const FormatException('Brak stolic w katalogu');
  }
  return capitals;
});
final flagsProvider = FutureProvider<FlagCatalog>((ref) async {
  final continent = ref.watch(selectedContinentProvider);
  final catalog = await ref.watch(catalogProvider.future);
  final flags = await FlagCatalog.load(continent: continent);
  final expected = {for (final c in catalog.countries) c.id: c.name};
  if (flags.facts.length != expected.length ||
      flags.facts.any((f) => expected[f.countryId] != f.countryName)) {
    throw const FormatException('Niezgodna paczka flag');
  }
  return flags;
});
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.local();
  ref.onDispose(db.close);
  return db;
});
final backupProvider = Provider<ProgressBackup>(
  (ref) => ProgressBackup(ref.watch(databaseProvider)),
);
final resetProvider = Provider<LearningReset>(
  (ref) => LearningReset(ref.watch(databaseProvider)),
);
final repositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepository(
    ref.watch(databaseProvider),
    continent: ref.watch(selectedContinentProvider),
    level:
        ref
            .watch(appPreferencesProvider)
            .asData
            ?.value
            .difficultyFor(ref.watch(selectedContinentProvider)) ??
        LearningDifficulty.normal,
  ),
);
final dashboardProvider = FutureProvider((ref) async {
  final repository = ref.watch(repositoryProvider);
  return (
    active: await repository.active(),
    capitalSessions: await repository.activeCapitals(),
    flagsSessions: await repository.activeFlags(),
  );
});

final streakProvider = FutureProvider.autoDispose<StreakSummary>((ref) async {
  final timer = Timer(const Duration(minutes: 1), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return StreakStore(ref.watch(databaseProvider))
      .overview(ref.watch(selectedContinentProvider));
});

/// Streak of any continent, for the progress overview.
final continentStreakProvider = FutureProvider.autoDispose
    .family<StreakSummary, Continent>(
      (ref, continent) =>
          StreakStore(ref.watch(databaseProvider)).overview(continent),
    );

final countryTriviaProvider = FutureProvider(
  (ref) => CountryTriviaCatalog.load(),
);

final flagTriviaProvider = FutureProvider(
  (ref) => CountryTriviaCatalog.load(asset: CountryTriviaCatalog.flagAsset),
);

final capitalTriviaProvider = FutureProvider(
  (ref) => CountryTriviaCatalog.load(asset: CountryTriviaCatalog.capitalAsset),
);

final continentAchievementsProvider = FutureProvider.autoDispose
    .family<List<CategoryAchievement>, Continent>((ref, continent) async {
      final db = ref.watch(databaseProvider);
      final catalog = await Catalog.load(continent: continent);
      return AchievementStore(db).refresh(catalog);
    });

/// Medals of the selected continent. Reuses the loaded catalog instead of
/// reading the map asset again (Today shows it on every visit).
final achievementsProvider =
    FutureProvider.autoDispose<List<CategoryAchievement>>((ref) async {
      final db = ref.watch(databaseProvider);
      final catalog = await ref.watch(catalogProvider.future);
      return AchievementStore(db).refresh(catalog, persist: false);
    });

final dailyOverviewProvider = FutureProvider.autoDispose<MemoryOverview>((
  ref,
) async {
  final timer = Timer(const Duration(minutes: 1), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  final repository = ref.watch(repositoryProvider);
  final catalogFuture = ref.watch(catalogProvider.future);
  final capitalsFuture = ref.watch(capitalsProvider.future);
  final flagsFuture = ref.watch(flagsProvider.future);
  final catalog = await catalogFuture;
  final capitals = await capitalsFuture;
  final flags = await flagsFuture;
  return repository.memoryOverview(catalog, capitals, flags: flags);
});

final learningProgressProvider =
    FutureProvider.autoDispose<List<LearningProgressEntry>>((ref) async {
      final timer = Timer(const Duration(minutes: 1), ref.invalidateSelf);
      ref.onDispose(timer.cancel);
      final repository = ref.watch(repositoryProvider);
      final catalogFuture = ref.watch(catalogProvider.future);
      final flagsFuture = ref.watch(flagsProvider.future);
      final catalog = await catalogFuture;
      final flags = await flagsFuture;
      return repository.learningProgress(catalog, flags: flags);
    });

final continentProgressProvider = FutureProvider.autoDispose
    .family<List<LearningProgressEntry>, Continent>((ref, continent) async {
      final timer = Timer(const Duration(minutes: 1), ref.invalidateSelf);
      ref.onDispose(timer.cancel);
      final db = ref.watch(databaseProvider);
      final catalog = await Catalog.load(continent: continent);
      final flags = await FlagCatalog.load(continent: continent);
      return SessionRepository(
        db,
        continent: continent,
      ).learningProgress(catalog, flags: flags);
    });
