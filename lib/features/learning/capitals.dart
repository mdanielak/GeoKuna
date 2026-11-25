import 'dart:convert';

import '../atlas/continent.dart';

import 'dart:math';

import 'package:diacritic/diacritic.dart';
import 'package:flutter/services.dart';

enum CapitalDifficulty {
  choice(
    'Bardzo łatwy',
    'Wybierz jedną z odpowiedzi A–D. Osobne powtórki rozpoznawania.',
  ),
  firstLetter('Łatwy', 'Pierwszą literę dostajesz. Dopisz resztę nazwy.'),
  write('Normalny', 'Wpisz całą nazwę bez podpowiedzi.');

  const CapitalDifficulty(this.label, this.description);
  final String label;
  final String description;
}

class CapitalFact {
  CapitalFact.fromJson(Map<String, dynamic> json)
    : countryId = json['country_id'] as String,
      name = json['name'] as String,
      aliases = (json['aliases'] as List).cast<String>(),
      prompt = json['prompt'] as String? ?? 'Jaka jest stolica tego państwa?',
      note = json['note'] as String? ?? '',
      sourcePage = json['source_page'] as int;

  final String countryId;
  final String name;
  final List<String> aliases;
  final String prompt;
  final String note;
  final int sourcePage;
  String get firstLetter => name.substring(0, 1);

  Map<String, dynamic> toJson() => {
    'country_id': countryId,
    'name': name,
    'aliases': aliases,
    'prompt': prompt,
    'note': note,
    'source_page': sourcePage,
  };
}

class CapitalQuestion {
  CapitalQuestion(this.fact, this.options);
  CapitalQuestion.fromJson(Map<String, dynamic> json)
    : fact = CapitalFact.fromJson(json),
      options = (json['options'] as List).cast<String>();
  final CapitalFact fact;
  final List<String> options;
  Map<String, dynamic> toJson() => {...fact.toJson(), 'options': options};
}

class CapitalCatalog {
  CapitalCatalog(this.version, this.facts) {
    if (facts.length < 4 ||
        facts.map((f) => f.countryId).toSet().length != facts.length ||
        facts.map((f) => normalizeAnswer(f.name)).toSet().length !=
            facts.length) {
      throw const FormatException('Niespójny katalog stolic');
    }
  }
  final String version;
  final List<CapitalFact> facts;

  List<CapitalQuestion> questions(List<String> ids, Random random) => ids.map((
    id,
  ) {
    final fact = facts.firstWhere((f) => f.countryId == id);
    final accepted = [fact.name, ...fact.aliases].map(normalizeAnswer).toSet();
    final distractors =
        facts
            .where((f) => !accepted.contains(normalizeAnswer(f.name)))
            .map((f) => f.name)
            .toList()
          ..shuffle(random);
    final options = [fact.name, ...distractors.take(3)]..shuffle(random);
    if (options.toSet().length != 4) {
      throw StateError('Niejednoznaczne odpowiedzi');
    }
    return CapitalQuestion(fact, options);
  }).toList();

  static Future<CapitalCatalog> load({
    Continent continent = Continent.europe,
  }) async {
    final json = jsonDecode(
      await rootBundle.loadString(continent.contentPath('capitals.json')),
    ) as Map<String, dynamic>;
    final records = (json['capitals'] as List).cast<Map<String, dynamic>>();
    if (records.any((r) => r['status'] != 'verified')) {
      throw const FormatException('Niezweryfikowany fakt');
    }
    // English names (Natural Earth, see build_capitals_en.py) are accepted
    // answers too; the bundled facts keep their verified Polish names.
    final english =
        ((jsonDecode(
                  await rootBundle.loadString(
                    'assets/content/capitals_en.json',
                  ),
                ) as Map<String, dynamic>)['names']
                as Map<String, dynamic>)[continent.name]
            as Map<String, dynamic>? ??
        const {};
    return CapitalCatalog(json['version'] as String, [
      for (final record in records)
        CapitalFact.fromJson({
          ...record,
          'aliases': [
            ...(record['aliases'] as List),
            ...(english[record['country_id']] as List? ?? const []),
          ],
        }),
    ]);
  }
}

String normalizeAnswer(String input) =>
    removeDiacritics(input)
        .toLowerCase()
        .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');

class AnswerEvaluation {
  const AnswerEvaluation(this.correct, {this.typoAccepted = false});
  final bool correct;
  final bool typoAccepted;
}

AnswerEvaluation evaluateCapitalAnswer(String input, CapitalFact fact) {
  return evaluateTextAnswer(input, [fact.name, ...fact.aliases]);
}

AnswerEvaluation evaluateTextAnswer(
  String input,
  List<String> acceptedAnswers,
) {
  final answer = normalizeAnswer(input);
  if (answer.isEmpty || answer.length > 100) {
    return const AnswerEvaluation(false);
  }
  final accepted = acceptedAnswers.map(normalizeAnswer).toList();
  if (accepted.contains(answer)) return const AnswerEvaluation(true);
  final typo = accepted.any((expected) => _editDistance(answer, expected) == 1);
  return AnswerEvaluation(typo, typoAccepted: typo);
}

/// Evaluates `firstLetter` mode, tolerating when the learner re-types the
/// pre-filled initial letter (e.g. typing "Warszawa" instead of "arszawa").
(String answer, AnswerEvaluation evaluation) resolveFirstLetterAnswer(
  String firstLetter,
  String input,
  AnswerEvaluation Function(String candidate) evaluate,
) {
  final trimmed = input.trim();
  final prefixed = '$firstLetter$trimmed';
  final prefixedEval = evaluate(prefixed);
  if (prefixedEval.correct && !prefixedEval.typoAccepted) {
    return (prefixed, prefixedEval);
  }
  if (normalizeAnswer(trimmed).startsWith(normalizeAnswer(firstLetter))) {
    final directEval = evaluate(trimmed);
    if ((directEval.correct && !prefixedEval.correct) ||
        (directEval.correct &&
            !directEval.typoAccepted &&
            prefixedEval.typoAccepted)) {
      return (trimmed, directEval);
    }
  }
  return (prefixed, prefixedEval);
}

// Optimal string alignment: insertion, deletion, substitution or ONE adjacent swap.
int _editDistance(String a, String b) {
  if ((a.length - b.length).abs() > 1) return 2;
  final matrix = List.generate(
    a.length + 1,
    (_) => List.filled(b.length + 1, 0),
  );
  for (var i = 0; i <= a.length; i++) {
    matrix[i][0] = i;
  }
  for (var j = 0; j <= b.length; j++) {
    matrix[0][j] = j;
  }
  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      matrix[i][j] = min(
        matrix[i - 1][j] + 1,
        min(
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1),
        ),
      );
      if (i > 1 && j > 1 && a[i - 1] == b[j - 2] && a[i - 2] == b[j - 1]) {
        matrix[i][j] = min(matrix[i][j], matrix[i - 2][j - 2] + 1);
      }
    }
  }
  return matrix[a.length][b.length];
}
