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
    await tester.scrollUntilVisible(find.text('Trening mapy'), 160);
    await tester.scrollUntilVisible(find.text('Odkrywaj atlas'), 160);
    await tester.scrollUntilVisible(find.text('Moja nauka'), 160);
    expect(find.text('Moja nauka'), findsOneWidget);
    pending.completeError(StateError('katalog'));
    await tester.pumpAndSettle();
    expect(
      find.text('Nie udało się wczytać dzisiejszej wyprawy.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('Odkrywaj atlas'), 160);
    expect(find.text('Odkrywaj atlas'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Ponów odczyt'), -160);
    expect(find.text('Ponów odczyt'), findsOneWidget);
  });
}
