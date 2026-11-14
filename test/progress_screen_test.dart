import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/app/providers.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/learning/learning_progress.dart';
import 'package:geokuna/features/progress/progress_screen.dart';
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
}
