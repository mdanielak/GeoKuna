import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:geokuna/app/providers.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/learning/session_repository.dart';
import 'package:geokuna/features/settings/settings_screen.dart';

void main() {
  testWidgets(
    'reset needs confirmation, cancellation preserves data and full reset clears it',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final db = AppDatabase(NativeDatabase.memory());
      final repo = SessionRepository(db);
      final session = await tester.runAsync(() => repo.start(['POL']));
      await tester.runAsync(
        () => repo.guessMap(session!.row.id, 0, 'POL', {
          'POL',
        }, expectedGuessIndex: 0),
      );
      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Start')),
          ),
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
      await tester.scrollUntilVisible(
        find.text('Zresetuj naukę'),
        160,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 200,
      );
      await tester.ensureVisible(find.text('Zresetuj naukę'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zresetuj naukę'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zachowaj naukę'));
      await tester.pumpAndSettle();
      expect(await db.select(db.sessions).get(), hasLength(1));
      await tester.scrollUntilVisible(
        find.text('Cała nauka'),
        -160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Cała nauka'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cała nauka'));
      await tester.scrollUntilVisible(
        find.text('Zresetuj naukę'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Zresetuj naukę'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zresetuj naukę'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Usuń postęp'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usuń postęp'));
      await tester.pumpAndSettle();
      expect(await db.select(db.sessions).get(), isEmpty);
      expect(await db.select(db.memoryCards).get(), isEmpty);
      expect(find.text('Start'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
