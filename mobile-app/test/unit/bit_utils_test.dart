import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/util/bit_utils.dart';

void main() {
  group('parseBitField', () {
    test('true (JSON boolean) → true', () {
      expect(parseBitField(true), isTrue);
    });

    test('false (JSON boolean) → false', () {
      expect(parseBitField(false), isFalse);
    });

    test('1 (integer fallback) → true', () {
      expect(parseBitField(1), isTrue);
    });

    test('0 (integer fallback) → false', () {
      expect(parseBitField(0), isFalse);
    });

    test('null → false', () {
      expect(parseBitField(null), isFalse);
    });

    test('"true" string → false (not a truthy value)', () {
      expect(parseBitField('true'), isFalse);
    });

    test('2 → false (only 1 is the integer sentinel)', () {
      expect(parseBitField(2), isFalse);
    });
  });
}
