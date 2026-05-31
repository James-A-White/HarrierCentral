import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/util/uuid_utils.dart';

const _upper = '550E8400-E29B-41D4-A716-446655440000';
const _lower = '550e8400-e29b-41d4-a716-446655440000';
const _empty = '00000000-0000-0000-0000-000000000000';

void main() {
  group('normalizeUuid', () {
    test('lowercases uppercase UUID', () {
      expect(normalizeUuid(_upper), _lower);
    });

    test('returns empty string for null', () {
      expect(normalizeUuid(null), '');
    });

    test('returns empty string for empty input', () {
      expect(normalizeUuid(''), '');
    });

    test('passes through already-lowercase UUID unchanged', () {
      expect(normalizeUuid(_lower), _lower);
    });
  });

  group('String.asUuid extension', () {
    test('lowercases uppercase UUID', () {
      expect(_upper.asUuid, _lower);
    });
  });

  group('String.equalsUuid extension', () {
    test('uppercase and lowercase compare equal', () {
      expect(_upper.equalsUuid(_lower), isTrue);
    });

    test('different UUIDs compare unequal', () {
      expect(_lower.equalsUuid(_empty), isFalse);
    });
  });

  group('isValidUuid', () {
    test('returns false for null', () {
      expect(isValidUuid(null), isFalse);
    });

    test('returns false for empty string', () {
      expect(isValidUuid(''), isFalse);
    });

    test('returns false for GUID_EMPTY', () {
      expect(isValidUuid(_empty), isFalse);
    });

    test('returns false for uppercase GUID_EMPTY', () {
      expect(isValidUuid(_empty.toUpperCase()), isFalse);
    });

    test('returns true for valid UUID', () {
      expect(isValidUuid(_lower), isTrue);
    });

    test('returns true for valid uppercase UUID', () {
      expect(isValidUuid(_upper), isTrue);
    });
  });
}
