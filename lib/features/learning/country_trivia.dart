import 'dart:convert';

import 'package:flutter/services.dart';

/// A source-backed fact from the locally bundled country trivia catalogue.
class CountryTriviaFact {
  const CountryTriviaFact({
    required this.id,
    required this.text,
    required this.sourceUrl,
  });

  final String id;
  final String text;
  final String sourceUrl;
}

/// Read-only country facts. No network is required when answering questions.
class CountryTriviaCatalog {
  CountryTriviaCatalog._(this._facts);

  final Map<String, List<CountryTriviaFact>> _facts;

  static Future<CountryTriviaCatalog> load() async {
    final decoded = jsonDecode(
      await rootBundle.loadString('assets/content/country_trivia.json'),
    ) as Map<String, dynamic>;
    final countries = decoded['countries'] as Map<String, dynamic>;
    return CountryTriviaCatalog._(
      Map.unmodifiable({
        for (final entry in countries.entries)
          entry.key: List<CountryTriviaFact>.unmodifiable(
            (entry.value as List<dynamic>).map((raw) {
              final fact = raw as Map<String, dynamic>;
              return CountryTriviaFact(
                id: fact['id'] as String,
                text: fact['text'] as String,
                sourceUrl: fact['source_url'] as String,
              );
            }),
          ),
      }),
    );
  }

  List<CountryTriviaFact> factsFor(String countryId) =>
      _facts[countryId] ?? const [];

  /// A bounded hash is stable across app restarts, Dart VM and web runtimes.
  CountryTriviaFact? pick(String countryId, {required String seed}) {
    final facts = factsFor(countryId);
    if (facts.isEmpty) return null;
    var hash = 0;
    for (final byte in utf8.encode('$countryId\u0000$seed')) {
      hash = (hash * 31 + byte) & 0x3fffffff;
    }
    return facts[hash % facts.length];
  }
}
