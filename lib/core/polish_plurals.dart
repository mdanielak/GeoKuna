/// Polish pluralization helper for counts.
String pluralPl(int n, String one, String few, String many) {
  if (n == 1) return one;
  final tens = n % 100;
  if (n % 10 >= 2 && n % 10 <= 4 && (tens < 12 || tens > 14)) return few;
  return many;
}
