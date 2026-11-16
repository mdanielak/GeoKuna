import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/features/learning/memory.dart';

void main() {
  test(
    'FSRS card ids: old ids unchanged, region codes unique and web-safe',
    () {
      // Values of the 3-letter scheme are fixed: changing them would detach
      // every saved card from its FSRS history.
      expect(fsrsCardId('map:POL:map'), 5283632);
      expect(fsrsCardId('flags:POL:mapEasy'), 3002641816);
      final ids = <int>{};
      for (final code in [
        'PL-02',
        'PL-14',
        'PL-32',
        'US-AL',
        'US-CA',
        'US-WY',
      ]) {
        for (final skill in [
          'map:$code:map',
          'map:$code:mapEasy',
          'map:$code:mapVeryEasy',
          'capitals:$code:choice',
          'capitals:$code:firstLetter',
          'capitals:$code:write',
          'flags:$code:choice',
          'flags:$code:mapVeryEasy',
        ]) {
          final id = fsrsCardId(skill);
          expect(id, lessThan(1 << 53), reason: skill);
          expect(id, greaterThanOrEqualTo(10000000000000), reason: skill);
          expect(ids.add(id), isTrue, reason: skill);
        }
      }
    },
  );
}
