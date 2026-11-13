import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/database.dart';
import '../features/atlas/catalog.dart';
import '../features/learning/session_repository.dart';
import '../features/learning/capitals.dart';

final catalogProvider = FutureProvider<Catalog>((ref) => Catalog.load());
final capitalsProvider = FutureProvider<CapitalCatalog>((ref) async {
  final catalog = await ref.watch(catalogProvider.future);
  final capitals = await CapitalCatalog.load();
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
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.local();
  ref.onDispose(db.close);
  return db;
});
final repositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepository(ref.watch(databaseProvider)),
);
final dashboardProvider = FutureProvider((ref) async {
  final repository = ref.watch(repositoryProvider);
  return (
    active: await repository.active(),
    capitalSessions: await repository.activeCapitals(),
    history: await repository.history(),
  );
});

final dailyOverviewProvider = FutureProvider.autoDispose<MemoryOverview>((
  ref,
) async {
  final timer = Timer(const Duration(minutes: 1), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  final catalog = await ref.watch(catalogProvider.future);
  final capitals = await ref.watch(capitalsProvider.future);
  return ref.watch(repositoryProvider).memoryOverview(catalog, capitals);
});
