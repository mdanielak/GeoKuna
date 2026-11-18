import 'dart:convert';

import '../atlas/continent.dart';

import 'dart:math';

import 'package:flutter/services.dart';

import 'capitals.dart';

enum FlagDifficulty {
  choice(
    'Bardzo łatwy',
    'Wybierz państwo spośród A–D. Osobne powtórki rozpoznawania.',
  ),
  firstLetter('Łatwy', 'Pierwsza litera i reszta do wpisania.'),
  write('Normalny', 'Wpisz całą nazwę bez podpowiedzi.'),
  map('Flaga na mapie', 'Wskaż państwo na mapie.');

  const FlagDifficulty(this.label, this.description);
  final String label;
  final String description;
}

class FlagQuestion {
  const FlagQuestion({
    required this.countryId,
    required this.countryName,
    required this.aliases,
    required this.assetPath,
    required this.options,
    required this.sha256,
  });
  factory FlagQuestion.fromJson(Map<String, dynamic> json) => FlagQuestion(
    countryId: json['country_id'] as String,
    countryName: json['country_name'] as String,
    aliases: (json['aliases'] as List).cast<String>(),
    assetPath: json['asset_path'] as String,
    sha256: json['sha256'] as String,
    options: (json['options'] as List? ?? const []).cast<String>(),
  );
  final String countryId, countryName, assetPath, sha256;
  final List<String> aliases, options;
  String get firstLetter => countryName.substring(0, 1);
  Map<String, dynamic> toJson() => {
    'country_id': countryId,
    'country_name': countryName,
    'aliases': aliases,
    'asset_path': assetPath,
    'sha256': sha256,
    'options': options,
  };
}

class FlagCatalog {
  FlagCatalog(this.version, this.facts) {
    if (facts.length < 4 ||
        facts.map((f) => f.countryId).toSet().length != facts.length ||
        facts.map((f) => normalizeAnswer(f.countryName)).toSet().length !=
            facts.length ||
        facts.any(
          (f) =>
              !f.assetPath.startsWith('assets/flags/') ||
              f.assetPath.contains('..') ||
              !f.assetPath.endsWith('.png') ||
              f.sha256.length != 64,
        )) {
      throw const FormatException('Niespójna paczka flag');
    }
  }
  final String version;
  final List<FlagQuestion> facts;
  List<FlagQuestion> questions(List<String> ids, Random random) => ids.map((
    id,
  ) {
    final fact = facts.firstWhere((f) => f.countryId == id);
    final accepted = [
      fact.countryName,
      ...fact.aliases,
    ].map(normalizeAnswer).toSet();
    final others =
        facts
            .where((f) => !accepted.contains(normalizeAnswer(f.countryName)))
            .map((f) => f.countryName)
            .toList()
          ..shuffle(random);
    final options = [fact.countryName, ...others.take(3)]..shuffle(random);
    return FlagQuestion(
      countryId: id,
      countryName: fact.countryName,
      aliases: fact.aliases,
      assetPath: fact.assetPath,
      sha256: fact.sha256,
      options: options,
    );
  }).toList();
  static Future<FlagCatalog> load({
    Continent continent = Continent.europe,
  }) async {
    final json = jsonDecode(
      await rootBundle.loadString(continent.contentPath('flags.json')),
    ) as Map<String, dynamic>;
    final facts = (json['flags'] as List).cast<Map<String, dynamic>>();
    if (facts.any((f) => f['status'] != 'verified')) {
      throw const FormatException('Niezweryfikowana flaga');
    }
    return FlagCatalog(
      json['version'] as String,
      facts.map(FlagQuestion.fromJson).toList(),
    );
  }
}

AnswerEvaluation evaluateFlagAnswer(String input, FlagQuestion question) =>
    evaluateTextAnswer(input, [question.countryName, ...question.aliases]);
