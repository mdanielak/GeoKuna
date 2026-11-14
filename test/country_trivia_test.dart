import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/features/learning/country_trivia.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'all supported countries have exactly three source-backed facts',
    () async {
      final catalog = await CountryTriviaCatalog.load();
      final ids = <String>{};
      for (final path in [
        'assets/content/countries.json',
        'assets/content/africa/countries.json',
        'assets/content/asia/countries.json',
      ]) {
        final data = jsonDecode(
          await rootBundle.loadString(path),
        ) as Map<String, dynamic>;
        for (final raw in data['countries'] as List<dynamic>) {
          ids.add((raw as Map<String, dynamic>)['id'] as String);
        }
      }
      expect(ids, hasLength(148));
      for (final id in ids) {
        final facts = catalog.factsFor(id);
        expect(facts, hasLength(3), reason: id);
        expect(facts.map((fact) => fact.id).toSet(), hasLength(3), reason: id);
        expect(
          facts.every((fact) => fact.sourceUrl.startsWith('https://')),
          isTrue,
          reason: id,
        );
      }
    },
  );

  test(
    'catalog loads three facts and selects consistently on resume',
    () async {
      final catalog = await CountryTriviaCatalog.load();
      final facts = catalog.factsFor('CZE');
      expect(facts, hasLength(3));
      expect(facts.map((fact) => fact.id).toSet(), hasLength(3));
      expect(
        facts.every((fact) => fact.sourceUrl.startsWith('https://')),
        isTrue,
      );
      final selected = catalog.pick('CZE', seed: 'session:question');
      expect(selected, isNotNull);
      expect(catalog.pick('CZE', seed: 'session:question')?.id, selected?.id);
      expect(catalog.pick('ZZZ', seed: 'session:question'), isNull);
      final ids = <String>{};
      for (var i = 0; i < 100; i++) {
        ids.add(catalog.pick('CZE', seed: 'session:$i')!.id);
      }
      expect(ids, facts.map((fact) => fact.id).toSet());
    },
  );
}
