import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/app/providers.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/atlas/continent.dart';
import 'package:geokuna/features/learning/achievements.dart';
import 'package:geokuna/features/learning/learning_progress.dart';
import 'package:geokuna/features/learning/streaks.dart';
import 'package:geokuna/features/progress/learning_overview_screen.dart';
import 'package:geokuna/features/progress/progress_screen.dart';
import 'package:geokuna/features/settings/app_preferences.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('phone progress filters country and preserves separate skills', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final catalog = (await tester.runAsync(Catalog.load))!;
    LearningProgressEntry entry(
      String id,
      String mode,
      LearningProgressStatus status,
    ) => LearningProgressEntry(
      id: '$id:$mode',
      country: catalog.country(id),
      topic: mode == 'map' ? 'map' : 'capitals',
      difficulty: mode,
      status: status,
      reviewCount: status == LearningProgressStatus.insufficient ? 0 : 1,
      due: null,
      lastReview: null,
    );
    final entries = [
      entry('POL', 'map', LearningProgressStatus.review),
      entry('POL', 'write', LearningProgressStatus.insufficient),
      entry('DEU', 'firstLetter', LearningProgressStatus.practising),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learningProgressProvider.overrideWith((ref) async => entries),
        ],
        child: const MaterialApp(home: ProgressScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Do powtórki: 1'), findsOneWidget);
    expect(find.text('Ćwiczysz: 1'), findsOneWidget);
    expect(find.text('Za mało danych: 1'), findsOneWidget);
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'polska');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Lokalizacja na mapie'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Lokalizacja na mapie'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Stolica · samodzielne pisanie'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Stolica · samodzielne pisanie'), findsOneWidget);
    expect(find.text('Niemcy'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'learning overview medal detail count sums medal tiers out of 36',
    (tester) async {
      final achievements = [
        const CategoryAchievement(
          topic: 'map',
          level: LearningDifficulty.normal,
          earnedMedal: 3,
          earnedAt: null,
          qualifiedCount: 47,
          totalCount: 47,
          inheritedCount: 0,
        ),
        const CategoryAchievement(
          topic: 'capitals',
          level: LearningDifficulty.normal,
          earnedMedal: 2,
          earnedAt: null,
          qualifiedCount: 40,
          totalCount: 47,
          inheritedCount: 0,
        ),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            continentProgressProvider(Continent.europe)
                .overrideWith((ref) async => const []),
            continentAchievementsProvider(Continent.europe)
                .overrideWith((ref) async => achievements),
            continentStreakProvider(Continent.europe).overrideWith(
              (ref) async => const StreakSummary(
                current: 0,
                best: 0,
                practisedToday: false,
              ),
            ),
          ],
          child: const MaterialApp(
            home: LearningOverviewScreen(continent: Continent.europe),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('5 z 36 zdobytych · progi 50%, 80% i 100%'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ProgressScreen(continent) displays that continent without mutating selectedContinentProvider',
    (tester) async {
      final africa = (await tester.runAsync(
        () => Catalog.load(continent: Continent.africa),
      ))!;
      final entry = LearningProgressEntry(
        id: 'map:EGY:map',
        country: africa.country('EGY'),
        topic: 'map',
        difficulty: 'map',
        status: LearningProgressStatus.practising,
        reviewCount: 1,
        due: null,
        lastReview: null,
      );
      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            continentProgressProvider(Continent.africa)
                .overrideWith((ref) async => [entry]),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(
                home: ProgressScreen(continent: Continent.africa),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Postępy · Afryka'), findsOneWidget);
      expect(find.text('Egipt'), findsOneWidget);
      expect(container.read(selectedContinentProvider), Continent.europe);
    },
  );
}
