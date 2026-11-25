import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/app/app.dart';
import 'package:geokuna/app/providers.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/home/how_it_works_screen.dart';
import 'package:geokuna/features/learning/session_repository.dart';
import 'package:geokuna/features/settings/settings_screen.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'HowItWorksScreen is reachable from Dziś, Ustawienia and Moja nauka and fits small text-scaled screens',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await db.close();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            catalogProvider.overrideWith(
              (ref) async => Catalog(
                const [],
                const [],
                continent: ref.watch(selectedContinentProvider),
              ),
            ),
            dailyOverviewProvider.overrideWith(
              (ref) async => const MemoryOverview(
                dueCount: 0,
                newAvailable: 0,
                newRemainingToday: 3,
                reviewedToday: 0,
                nextDue: null,
                plannedCount: 0,
                plannedNewCount: 0,
                activeSession: null,
              ),
            ),
            continentProgressProvider.overrideWith((ref, _) async => const []),
            continentAchievementsProvider.overrideWith(
              (ref, _) async => const [],
            ),
          ],
          child: const GeoKunaApp(),
        ),
      );
      await tester.pumpAndSettle();

      // From Dziś (?)
      await tester.tap(find.byTooltip('Jak to działa?'));
      await tester.pumpAndSettle();
      expect(find.byType(HowItWorksScreen), findsOneWidget);
      expect(find.text('Krótki przewodnik po nauce'), findsOneWidget);

      final guideScrollable = find.descendant(
        of: find.byType(HowItWorksScreen),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text('Dzisiejsza wyprawa i powtórki'),
        400,
        maxScrolls: 120,
        scrollable: guideScrollable,
      );
      expect(find.text('Dzisiejsza wyprawa i powtórki'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Kiedy kraj jest zaliczony?'),
        400,
        maxScrolls: 120,
        scrollable: guideScrollable,
      );
      expect(find.text('Kiedy kraj jest zaliczony?'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Offline i kopia zapasowa'),
        400,
        maxScrolls: 120,
        scrollable: guideScrollable,
      );
      expect(find.text('Offline i kopia zapasowa'), findsOneWidget);

      // Back to Dziś, then open Ustawienia -> Jak działa nauka?
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ustawienia'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Jak działa nauka?'),
        400,
        maxScrolls: 120,
        scrollable: find.descendant(
          of: find.byType(SettingsScreen),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.ensureVisible(find.text('Jak działa nauka?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jak działa nauka?'));
      await tester.pumpAndSettle();
      expect(find.byType(HowItWorksScreen), findsOneWidget);

      // Back to Ustawienia -> back to Dziś -> Moja nauka (?)
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Moja nauka'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Jak to działa?'));
      await tester.pumpAndSettle();
      expect(find.byType(HowItWorksScreen), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );
}
