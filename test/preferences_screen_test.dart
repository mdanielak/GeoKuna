import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:geokuna/app/providers.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/continent.dart';
import 'package:geokuna/features/settings/app_preferences.dart';
import 'package:geokuna/features/settings/settings_screen.dart';

void main() {
  testWidgets('map style and per-continent difficulty are saved', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final db = AppDatabase(NativeDatabase.memory());
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await db.close();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ustawienia'), findsOneWidget);
    expect(find.text('Rzeźba terenu'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Nowoczesny atlas'));
    await tester.tap(find.text('Nowoczesny atlas'));
    await tester.pumpAndSettle();
    expect(
      (await db.select(db.appPreferenceEntries).get())
          .singleWhere((entry) => entry.key == 'map_appearance')
          .value,
      MapAppearance.atlas.name,
    );

    await tester.scrollUntilVisible(
      find.text('Poziom nauki'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Poziom nauki'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Poziom nauki'));
    await tester.pumpAndSettle();
    expect(
      find.byType(DropdownButtonFormField<LearningDifficulty>),
      findsNWidgets(Continent.values.length),
    );

    final firstDropdown = find
        .byType(DropdownButtonFormField<LearningDifficulty>)
        .first;
    await tester.scrollUntilVisible(
      firstDropdown,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(firstDropdown);
    await tester.pumpAndSettle();
    await tester.tap(firstDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Łatwy').last);
    await tester.pumpAndSettle();
    final preferences = await AppPreferencesStore(db).load();
    expect(
      preferences.difficultyFor(Continent.europe),
      LearningDifficulty.easy,
    );
    expect(
      preferences.difficultyFor(Continent.africa),
      LearningDifficulty.auto,
    );
    expect(tester.takeException(), isNull);
  });
}
