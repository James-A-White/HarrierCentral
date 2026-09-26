import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';

/// The Add Down Down form's two small rules, pure since 2026-09-23.
void main() {
  group('DownDownFormController.addName', () {
    test('adds a trimmed name once, case-insensitively', () {
      final names = <String>[];
      expect(DownDownFormController.addName(names, '  Bob '), isTrue);
      expect(DownDownFormController.addName(names, 'bob'), isFalse);
      expect(DownDownFormController.addName(names, ''), isFalse);
      expect(DownDownFormController.addName(names, '   '), isFalse);
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

  // Editing who is charged (2026-09-26): the edit page opens with the
  // charge's hashers ticked, and a charged hasher who is not on the attendee
  // list is added rather than silently dropped on save.
  group('DownDownFormController.applyChargedSelection', () {
    List<AttendeeItem> list() => [
      AttendeeItem(hasherId: 'AAAAAAAA-0000-0000-0000-000000000001', displayName: 'Alice'),
      AttendeeItem(hasherId: 'aaaaaaaa-0000-0000-0000-000000000002', displayName: 'Bob'),
    ];
    DownDownHasherModel h(String id, String name) =>
        DownDownHasherModel(downDownId: 'dd', hasherId: id, displayName: name);

    test('ticks charged attendees, case-insensitively', () {
      final out = DownDownFormController.applyChargedSelection(
        list(),
        [h('aaaaaaaa-0000-0000-0000-000000000001', 'Alice')],
      );
      expect(out.map((a) => a.selected).toList(), [true, false]);
    });

    test('adds a charged hasher missing from the attendees, ticked, first', () {
      final out = DownDownFormController.applyChargedSelection(
        list(),
        [h('bbbbbbbb-0000-0000-0000-000000000009', 'Doorstop')],
      );
      expect(out.length, 3);
      expect(out.first.displayName, 'Doorstop');
      expect(out.first.selected, isTrue);
      expect(out.skip(1).every((a) => !a.selected), isTrue);
    });

    test('nobody charged: list unchanged, nothing ticked', () {
      final out = DownDownFormController.applyChargedSelection(list(), const []);
      expect(out.length, 2);
      expect(out.every((a) => !a.selected), isTrue);
    });
  });
}
