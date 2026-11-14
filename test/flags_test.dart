import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/learning/flags.dart';
import 'package:geokuna/features/learning/memory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('47 sourced local flags, four unique names and one typo', () async {
    final catalog = await Catalog.load();
    final flags = await FlagCatalog.load();
    expect(flags.facts.length, catalog.countries.length);
    for (final fact in flags.facts) {
      expect(fact.countryName, catalog.country(fact.countryId).name);
      final data = await rootBundle.load(fact.assetPath);
      expect(data.lengthInBytes, greaterThan(50));
      expect(
        data.getUint8(0),
        137,
      ); // PNG signature, never emoji or a remote URL.
      final question = flags.questions([fact.countryId], Random(3)).single;
      expect(question.options.toSet(), hasLength(4));
      expect(
        question.options.where((o) => o == fact.countryName),
        hasLength(1),
      );
      expect(
        FlagQuestion.fromJson(question.toJson()).assetPath,
        fact.assetPath,
      );
    }
    final pol = flags.facts.firstWhere((f) => f.countryId == 'POL');
    expect(evaluateFlagAnswer('polsqa', pol).typoAccepted, isTrue);
    expect(evaluateFlagAnswer('Niemcy', pol).correct, isFalse);
  });
  test('flag scheduler IDs do not collide with capital skills', () {
    final scheduler = MemoryScheduler();
    final now = DateTime.utc(2026, 11, 13);
    final capital = scheduler.review(
      skillId: 'capitals:POL:write',
      correct: true,
      now: now,
    );
    final flag = scheduler.review(
      skillId: 'flags:POL:write',
      correct: true,
      now: now,
    );
    expect(
      jsonDecode(capital.state)['cardId'],
      isNot(jsonDecode(flag.state)['cardId']),
    );
  });
}
