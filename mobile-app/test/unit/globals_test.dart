import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/util/get_storage.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/globals.dart';
import '../golden/test_helpers.dart';

void main() {
  setUp(() async {
    await setupTestEnvironment();
  });

  tearDown(() async {
    await tearDownTestEnvironment();
  });

  group('currentUserId', () {
    test('returns empty string when no userId pref is set', () {
      expect(currentUserId, equals(''));
    });

    test('returns the stored value when userId pref is set', () async {
      await setStringPref(StringPrefsEnum.userId, 'abc-def-123');
      expect(currentUserId, equals('abc-def-123'));
    });

    test('returns empty string after userId pref is cleared', () async {
      await setStringPref(StringPrefsEnum.userId, 'abc-def-123');
      await setStringPref(StringPrefsEnum.userId, null);
      expect(currentUserId, equals(''));
    });
  });

  group('getUserId', () {
    test('returns null when no userId pref is set', () {
      expect(getUserId(), isNull);
    });

    test('returns the stored value when userId pref is set', () async {
      await setStringPref(StringPrefsEnum.userId, 'abc-def-123');
      expect(getUserId(), equals('abc-def-123'));
    });
  });
}
