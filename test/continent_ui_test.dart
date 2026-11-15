import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/app/app.dart';
import 'package:geokuna/app/providers.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/learning/session_repository.dart';
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
    expect(find.text('Wyprawa po Europie'), findsOneWidget);
    expect(find.text('Zacznij dziś passę'), findsOneWidget);
    expect(
      find.textContaining('Nowe pytania czekają już w rozpoczętej wyprawie'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Europa'))
          .selected,
      isTrue,
    );

    await tester.tap(find.text('Afryka'));
    await tester.pumpAndSettle();

    expect(find.text('Afryka'), findsOneWidget);
    expect(find.text('Wyprawa po Afryce'), findsOneWidget);
    expect(find.text('Zacznij dziś passę'), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Afryka'))
          .selected,
      isTrue,
    );

    await tester.tap(find.text('Azja'));
    await tester.pumpAndSettle();
    expect(find.text('Wyprawa po Azji'), findsOneWidget);
    expect(find.text('Zacznij dziś passę'), findsOneWidget);
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
}
