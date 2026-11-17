import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/app/app.dart';
import 'package:geokuna/app/providers.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('ładowanie i błąd katalogu nie ukrywają nawigacji', (
    tester,
  ) async {
    final pending = Completer<Catalog>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [catalogProvider.overrideWith((ref) => pending.future)],
        child: const GeoKunaApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.scrollUntilVisible(
      find.bySemanticsLabel('Trening: Mapa'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    // Atlas and "Moja nauka" stay in the bottom bar whatever the data state.
    expect(find.widgetWithText(NavigationBar, 'Atlas'), findsOneWidget);
    expect(find.widgetWithText(NavigationBar, 'Moja nauka'), findsOneWidget);
    pending.completeError(StateError('katalog'));
    await tester.pumpAndSettle();
    expect(
      find.text('Nie udało się wczytać dzisiejszej wyprawy.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(NavigationBar, 'Atlas'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Ponów odczyt'),
      -160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Ponów odczyt'), findsOneWidget);
  });
}
