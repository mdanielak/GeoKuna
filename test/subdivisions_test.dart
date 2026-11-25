import 'package:drift/native.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/atlas/continent.dart';
import 'package:geokuna/features/atlas/country_map.dart';
import 'package:geokuna/features/learning/capitals.dart';
import 'package:geokuna/features/learning/flags.dart';
import 'package:geokuna/features/learning/memory.dart';
import 'package:geokuna/features/learning/session_repository.dart';
import 'package:geokuna/features/settings/app_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('voivodeships and US states: map, capitals and symbols', () async {
    for (final (area, count, id, question, capital) in [
      (
        Continent.poland,
        16,
        'PL-14',
        'Gdzie leży województwo mazowieckie?',
        'Warszawa',
      ),
      (Continent.usa, 50, 'US-WA', 'Gdzie leży stan Waszyngton?', 'Olympia'),
    ]) {
      final catalog = await Catalog.load(continent: area);
      expect(catalog.countries, hasLength(count));
      expect(catalog.country(id).locationQuestion, question);
      final capitals = await CapitalCatalog.load(continent: area);
      final flags = await FlagCatalog.load(continent: area);
      expect(capitals.facts, hasLength(count));
      expect(flags.facts, hasLength(count));
      expect(capitals.facts.firstWhere((f) => f.countryId == id).name, capital);
      final db = AppDatabase(NativeDatabase.memory());
      try {
        final repo = SessionRepository(db, continent: area);
        expect(
          await repo.startDaily(catalog, capitals, flags: flags),
          isNotNull,
        );
        final progress = await repo.learningProgress(catalog, flags: flags);
        expect(progress, hasLength(count * 12));
      } finally {
        await db.close();
      }
    }
    // Split seats: both cities count, the note explains the split.
    final poland = await CapitalCatalog.load(continent: Continent.poland);
    final kp = poland.facts.firstWhere((f) => f.countryId == 'PL-04');
    expect(evaluateCapitalAnswer('Toruń', kp).correct, isTrue);
    expect(evaluateCapitalAnswer('Bydgoszcz', kp).correct, isTrue);
    expect(kp.note, contains('sejmik'));
    final lb = poland.facts.firstWhere((f) => f.countryId == 'PL-08');
    expect(evaluateCapitalAnswer('Zielona Góra', lb).correct, isTrue);
    expect(Continent.poland.symbolsLabel, 'Herby');
    expect(Continent.poland.symbolQuestion, 'Którego województwa to herb?');
    expect(Continent.usa.capitalPrompt, 'Stolica stanu?');
    expect(Continent.europe.symbolQuestion, 'Jakie to państwo?');
    final usa = await Catalog.load(continent: Continent.usa);
    expect(usa.insetFrames.map((f) => f.areaId), ['US-AK', 'US-HI']);
    expect(Continent.poland.capitalGenitive, 'miasta wojewódzkiego');
    expect(Continent.usa.capitalGenitive, 'stolicy stanu');
    expect(Continent.europe.capitalGenitive, 'stolicy');
    expect(Continent.poland.hardAreaLabel, 'Trudne województwo');
    expect(Continent.usa.hardAreaMasteredLabel, 'Trudny stan opanowany');
    expect(Continent.usa.smallAreaMarkerLabel, 'Mały stan — znacznik');
  });

  test(
    'analyzeRecovery tracks misses, recovery count and latest timestamp',
    () {
      MemoryReview rev(int day, int rating, {bool applied = true}) =>
          MemoryReview(
            sessionId: 's$day',
            questionIndex: 0,
            skillId: 'map:POL:map',
            rating: rating,
            reviewedAt: DateTime.utc(2026, 11, day),
            wasNew: false,
            applied: applied,
            origin: 'daily',
          );
      final inProgress = analyzeRecovery([
        rev(1, 1),
        rev(2, 3),
        rev(3, 3, applied: false),
        rev(4, 3),
      ]);
      expect(inProgress.recovering['map:POL:map'], 2);
      expect(inProgress.missesSinceRecovery['map:POL:map'], 1);
      expect(inProgress.lastRecoveredAt, isEmpty);

      final recovered = analyzeRecovery([
        rev(1, 1),
        rev(2, 3),
        rev(3, 3),
        rev(4, 3),
        rev(5, 3),
      ]);
      expect(recovered.recovering, isEmpty);
      expect(recovered.missesSinceRecovery, isEmpty);
      expect(
        recovered.lastRecoveredAt['map:POL:map'],
        DateTime.utc(2026, 11, 4),
      );
    },
  );

  testWidgets(
    'USA map hides inset state names in quiz mode and taps Hawaii inset',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final usa = (await tester.runAsync(
        () => Catalog.load(continent: Continent.usa),
      ))!;
      String? picked;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 500,
              child: CountryMap(
                catalog: usa,
                quizMode: true,
                appearance: MapAppearance.atlas,
                onSelected: (id) => picked = id,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Alaska'), findsNothing);
      expect(find.textContaining('Hawaje'), findsNothing);
      expect(find.text('inna skala'), findsWidgets);

      // Tap inside the Hawaii inset box (even on water between islands).
      final hawaiiFrame = usa.insetFrames.firstWhere(
        (f) => f.areaId == 'US-HI',
      );
      final mapFinder = find.byType(FlutterMap);
      final mapWidget = tester.widget<FlutterMap>(mapFinder);
      final camera = mapWidget.mapController!.camera;
      final mapTopLeft = tester.getTopLeft(mapFinder);
      final waterPoint = LatLng(
        (hawaiiFrame.bounds.north + hawaiiFrame.bounds.south) / 2,
        hawaiiFrame.bounds.west + 0.3,
      );
      final localOffset = camera.latLngToScreenOffset(waterPoint);
      await tester.tapAt(mapTopLeft + localOffset);
      await tester.pumpAndSettle();
      expect(picked, 'US-HI');

      // Atlas mode shows full inset captions cleanly.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 500,
              child: CountryMap(
                catalog: usa,
                quizMode: false,
                appearance: MapAppearance.atlas,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Alaska — inna skala'), findsOneWidget);
      expect(find.text('Hawaje — inna skala'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
