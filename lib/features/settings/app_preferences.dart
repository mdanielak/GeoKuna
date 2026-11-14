import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/database/database.dart';
import '../atlas/continent.dart';

enum MapAppearance {
  atlas('Nowoczesny atlas'),
  paper('Papierowy atlas'),
  relief('Rzeźba terenu');

  const MapAppearance(this.label);
  final String label;
}

enum LearningDifficulty {
  veryEasy(
    'Bardzo łatwy',
    'Wybór A–D · osobne powtórki rozpoznawania',
    'choice',
  ),
  easy('Łatwy', 'Pierwsza litera i reszta do wpisania', 'firstLetter'),
  normal('Normalny', 'Wpisywanie całej odpowiedzi', 'write');

  const LearningDifficulty(this.label, this.description, this.mode);
  final String label;
  final String description;
  final String mode;
}

class AppPreferences {
  AppPreferences({
    this.appearance = MapAppearance.relief,
    Map<Continent, LearningDifficulty> difficulties = const {},
  }) : difficulties = Map.unmodifiable(difficulties);
  final MapAppearance appearance;
  final Map<Continent, LearningDifficulty> difficulties;
  LearningDifficulty difficultyFor(Continent continent) =>
      difficulties[continent] ?? LearningDifficulty.normal;
}

class AppPreferencesStore {
  const AppPreferencesStore(this.db);
  final AppDatabase db;

  Future<AppPreferences> load() async {
    final entries = {
      for (final e in await db.select(db.appPreferenceEntries).get())
        e.key: e.value,
    };
    return AppPreferences(
      appearance:
          MapAppearance.values
              .where((v) => v.name == entries['map_appearance'])
              .firstOrNull ??
          MapAppearance.relief,
      difficulties: {
        for (final continent in Continent.values)
          continent:
              LearningDifficulty.values
                  .where(
                    (v) => v.name == entries['difficulty_${continent.name}'],
                  )
                  .firstOrNull ??
              LearningDifficulty.normal,
      },
    );
  }

  Future<void> _write(String key, String value) => db
      .into(db.appPreferenceEntries)
      .insertOnConflictUpdate(
        AppPreferenceEntriesCompanion.insert(key: key, value: value),
      );
  Future<void> setAppearance(MapAppearance appearance) =>
      _write('map_appearance', appearance.name);
  Future<void> setDifficulty(
    Continent continent,
    LearningDifficulty difficulty,
  ) => _write('difficulty_${continent.name}', difficulty.name);
}

class AppPreferencesController extends AsyncNotifier<AppPreferences> {
  Future<void> _pending = Future.value();
  late AppPreferencesStore _store;

  @override
  Future<AppPreferences> build() {
    _store = AppPreferencesStore(ref.watch(databaseProvider));
    return _store.load();
  }

  Future<void> _save(Future<void> Function() action) {
    final result = _pending.then((_) async {
      await future;
      await action();
      final saved = await _store.load();
      if (ref.mounted) state = AsyncData(saved);
    });
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> setAppearance(MapAppearance appearance) =>
      _save(() => _store.setAppearance(appearance));
  Future<void> setDifficulty(
    Continent continent,
    LearningDifficulty difficulty,
  ) => _save(() => _store.setDifficulty(continent, difficulty));
}

final appPreferencesProvider =
    AsyncNotifierProvider<AppPreferencesController, AppPreferences>(
      AppPreferencesController.new,
    );
