import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';

/// The Add Down Down form's two small rules, pure since 2026-09-23.
void main() {
  group('AddDownDownController.addName', () {
    test('adds a trimmed name once, case-insensitively', () {
      final names = <String>[];
      expect(AddDownDownController.addName(names, '  Bob '), isTrue);
      expect(AddDownDownController.addName(names, 'bob'), isFalse);
      expect(AddDownDownController.addName(names, ''), isFalse);
      expect(AddDownDownController.addName(names, '   '), isFalse);
      expect(names, ['Bob']);
    });
  });

  group('AddDownDownController.validationError', () {
    test('needs someone to charge', () {
      expect(
        AddDownDownController.validationError(
          selectedCount: 0,
          externalCount: 0,
          chargeText: 'x',
        ),
        isNotNull,
      );
    });
    test('a name not in the app is enough', () {
      expect(
        AddDownDownController.validationError(
          selectedCount: 0,
          externalCount: 1,
          chargeText: 'x',
        ),
        isNull,
      );
    });
    test('needs the charge text', () {
      expect(
        AddDownDownController.validationError(
          selectedCount: 1,
          externalCount: 0,
          chargeText: '  ',
        ),
        'Enter the charge',
      );
    });
  });

  test('UserQrCodeController.notYetOpenMessage picks the unit', () {
    expect(UserQrCodeController.notYetOpenMessage(48), endsWith('2 days'));
    expect(UserQrCodeController.notYetOpenMessage(5), endsWith('5 hours'));
    expect(UserQrCodeController.notYetOpenMessage(0.5), endsWith('30 minutes'));
    expect(
      UserQrCodeController.notYetOpenMessage(1 / 60),
      endsWith('1 minute'),
    );
  });
}
