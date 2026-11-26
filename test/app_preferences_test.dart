import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/continent.dart';
import 'package:geokuna/features/learning/learning_reset.dart';
import 'package:geokuna/features/settings/app_preferences.dart';

void main() {
  test('preferences default to relief and auto, persist independently and survive learning reset', () async {
    final dir = await Directory.systemTemp.createTemp('geokuna_preferences_');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    var store = AppPreferencesStore(db);
    final defaults = await store.load();
    expect(defaults.appearance, MapAppearance.relief);
    for (final continent in Continent.values) {
      expect(defaults.difficultyFor(continent), LearningDifficulty.auto);
    }
    await store.setAppearance(MapAppearance.paper);
    await store.setDifficulty(Continent.europe, LearningDifficulty.veryEasy);
    await store.setDifficulty(Continent.africa, LearningDifficulty.easy);
    await db.close();
    db = AppDatabase(NativeDatabase(file));
    store = AppPreferencesStore(db);
    try {
      var restored = await store.load();
      expect(restored.appearance, MapAppearance.paper);
      expect(
        restored.difficultyFor(Continent.europe),
        LearningDifficulty.veryEasy,
      );
      expect(restored.difficultyFor(Continent.africa), LearningDifficulty.easy);
      expect(restored.difficultyFor(Continent.asia), LearningDifficulty.auto);
      await LearningReset(db).all();
      await db
          .into(db.appPreferenceEntries)
          .insertOnConflictUpdate(
            AppPreferenceEntriesCompanion.insert(
              key: 'map_appearance',
              value: 'unknown-future-style',
            ),
          );
      expect((await store.load()).appearance, MapAppearance.relief);
      await store.setAppearance(MapAppearance.paper);
      restored = await store.load();
      expect(restored.appearance, MapAppearance.paper);
      expect(
        restored.difficultyFor(Continent.europe),
        LearningDifficulty.veryEasy,
      );
    } finally {
      await db.close();
    }
  });
}
