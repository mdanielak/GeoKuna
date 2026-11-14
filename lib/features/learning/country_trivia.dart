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

  static const countryAsset = 'assets/content/country_trivia.json';
  static const flagAsset = 'assets/content/flag_trivia.json';

  static Future<CountryTriviaCatalog> load({
    String asset = countryAsset,
  }) async {
    final decoded =
        jsonDecode(await rootBundle.loadString(asset)) as Map<String, dynamic>;
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
  ///
  /// Facts naming any of [avoid] (countries asked later in the same series)
  /// are skipped, so a fact never gives away a future answer.
  CountryTriviaFact? pick(
    String countryId, {
    required String seed,
    Iterable<String> avoid = const [],
  }) {
    final patterns = [for (final name in avoid) _stem(name)].nonNulls.toList();
    final facts = factsFor(countryId)
        .where((f) => !patterns.any((p) => p.hasMatch(f.text)))
        .toList();
    if (facts.isEmpty) return null;
    var hash = 0;
    for (final byte in utf8.encode('$countryId\u0000$seed')) {
      hash = (hash * 31 + byte) & 0x3fffffff;
    }
    return facts[hash % facts.length];
  }

  /// Word-start match on the first four letters of the longest word of a
  /// country name, which also catches Polish inflected forms.
  static RegExp? _stem(String name) {
    final words = name.split(RegExp(r'[\s-]+'))
      ..sort((a, b) => b.length - a.length);
    if (words.isEmpty || words.first.length < 4) return null;
    final stem = RegExp.escape(words.first.substring(0, 4));
    return RegExp('(^|[^\\p{L}])$stem', caseSensitive: false, unicode: true);
  }
}
