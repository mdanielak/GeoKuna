import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/app/app.dart';
import 'package:geokuna/app/providers.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/learning/achievements.dart';
import 'package:geokuna/features/learning/session_repository.dart';
import 'package:geokuna/features/settings/app_preferences.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('Dziś przełącza cały ekran i katalog między kontynentami', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogProvider.overrideWith((ref) async {
            final continent = ref.watch(selectedContinentProvider);
            return Catalog([], [], continent: continent);
          }),
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
              reservedNewElsewhere: 2,
            ),
          ),
        ],
        child: const GeoKunaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Europa'), findsOneWidget);
    expect(find.textContaining('Europa · '), findsOneWidget);
    expect(find.text('0 dni'), findsOneWidget);
    // Reserved questions elsewhere are not announced on Today.
    expect(find.textContaining('rozpoczętej wyprawie'), findsNothing);
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Europa'))
          .selected,
      isTrue,
    );

    await tester.tap(find.text('Afryka'));
    await tester.pumpAndSettle();

    expect(find.text('Afryka'), findsOneWidget);
    expect(find.textContaining('Afryka · '), findsOneWidget);
    expect(find.text('0 dni'), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Afryka'))
          .selected,
      isTrue,
    );

    await tester.tap(find.text('Azja'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Azja · '), findsOneWidget);
    expect(find.text('0 dni'), findsOneWidget);
    // Swiping the banner: left goes to the next area, right comes back.
    await tester.fling(
      find.textContaining('Azja · '),
      const Offset(-250, 0),
      800,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Ameryka Północna · '), findsOneWidget);
    await tester.fling(
      find.textContaining('Ameryka Północna · '),
      const Offset(250, 0),
      800,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Azja · '), findsOneWidget);
    // A slow swipe that pauses before lifting the finger (velocity 0) counts too.
    Future<void> slowSwipe(String from, double dx) async {
      final swipe = await tester.startGesture(
        tester.getCenter(find.textContaining(from)),
      );
      for (var i = 0; i < 6; i++) {
        await swipe.moveBy(Offset(dx / 6, 0));
        await tester.pump(const Duration(milliseconds: 30));
      }
      await tester.pump(const Duration(milliseconds: 300));
      await swipe.up();
      await tester.pumpAndSettle();
    }

    await slowSwipe('Azja · ', -120);
    expect(find.textContaining('Ameryka Północna · '), findsOneWidget);
    await slowSwipe('Ameryka Północna · ', 120);
    expect(find.textContaining('Azja · '), findsOneWidget);
    tester.view.physicalSize = const Size(320, 640);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Azja'))
          .selected,
      isTrue,
    );
    // The level row sits below training; its sheet lists all levels.
    await tester.scrollUntilVisible(
      find.text('Poziom dla Azji: Normalny'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Poziom dla Azji: Normalny'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Poziom dla Azji: Normalny'));
    await tester.pumpAndSettle();
    for (final level in ['Bardzo łatwy', 'Łatwy', 'Normalny']) {
      expect(find.text(level), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dziś shows "W nauce" on the map badge from day 1', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogProvider.overrideWith(
            (ref) async => Catalog(
              [],
              [],
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
          achievementsProvider.overrideWith(
            (ref) async => const [
              CategoryAchievement(
                topic: 'map',
                level: LearningDifficulty.normal,
                earnedMedal: 0,
                earnedAt: null,
                qualifiedCount: 0,
                totalCount: 47,
                inheritedCount: 0,
                learningCount: 3,
              ),
            ],
          ),
        ],
        child: const GeoKunaApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Europa: 0/47 państw zaliczonych'), findsOneWidget);
    expect(find.text('W nauce: 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
