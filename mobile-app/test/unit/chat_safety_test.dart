// Block a hasher / report a message (E9.F1.S16 / S17): the parts that read
// a server reply, which are pure and would otherwise only be exercised on a
// phone against production.
import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';

void main() {
  const String upper = 'F66CEFDF-23E0-43B6-88E9-90D4B9DA8487';
  const String lower = 'f66cefdf-23e0-43b6-88e9-90d4b9da8487';

  group('BlockedHasher.fromJson', () {
    test('lowercases the public id SQL sends in UPPERCASE', () {
      final BlockedHasher h = BlockedHasher.fromJson(<String, dynamic>{
        'PublicHasherId': upper,
        'DisplayName': 'Sir Spanks',
        'Photo': 'bundle://avatar-7',
        'BlockedAt': '2026-09-29T10:15:00+00:00',
      });
      expect(h.publicHasherId, lower);
      expect(h.publicHasherId.isValid, isTrue);
      expect(h.displayName, 'Sir Spanks');
      expect(h.photo, 'bundle://avatar-7');
      expect(h.blockedAt, DateTime.utc(2026, 9, 29, 10, 15));
    });

    test('survives a missing name, photo and date', () {
      final BlockedHasher h = BlockedHasher.fromJson(<String, dynamic>{
        'PublicHasherId': lower,
      });
      expect(h.displayName, 'A hasher');
      expect(h.photo, isNull);
      expect(h.blockedAt, isNull);
    });

    test('accepts a date as epoch milliseconds too', () {
      final BlockedHasher h = BlockedHasher.fromJson(<String, dynamic>{
        'PublicHasherId': lower,
        'BlockedAt': DateTime.utc(2026, 9, 29).millisecondsSinceEpoch,
      });
      expect(h.blockedAt, DateTime.utc(2026, 9, 29));
    });
  });

  group('HasherBlockService.parseBlockedReply', () {
    test('rowset 0 is the envelope; the list is rowset 1', () {
      final List<BlockedHasher>? list = HasherBlockService.parseBlockedReply(
        jsonEncode(<dynamic>[
          <dynamic>[
            <String, dynamic>{'success': 1, 'errorMessage': null},
          ],
          <dynamic>[
            <String, dynamic>{'PublicHasherId': upper, 'DisplayName': 'A'},
            <String, dynamic>{'PublicHasherId': lower, 'DisplayName': 'B'},
          ],
        ]),
      );
      expect(list, isNotNull);
      expect(list!.map((BlockedHasher h) => h.displayName), <String>['A', 'B']);
      expect(list.every((BlockedHasher h) => h.publicHasherId == lower), isTrue);
    });

    test('a success with no list rowset is an empty list, not a failure', () {
      expect(
        HasherBlockService.parseBlockedReply(
          jsonEncode(<dynamic>[
            <dynamic>[
              <String, dynamic>{'success': 1},
            ],
          ]),
        ),
        isEmpty,
      );
    });

    test('an envelope that says the write did not happen is null', () {
      expect(
        HasherBlockService.parseBlockedReply(
          jsonEncode(<dynamic>[
            <dynamic>[
              <String, dynamic>{'success': 0, 'errorCode': 1985, 'errorType': 2},
            ],
          ]),
        ),
        isNull,
      );
    });

    test('an empty envelope (dropped socket) is null, not a RangeError', () {
      expect(HasherBlockService.parseBlockedReply('[[]]'), isNull);
      expect(HasherBlockService.parseBlockedReply('[]'), isNull);
      expect(HasherBlockService.parseBlockedReply('not json'), isNull);
    });

    test('rows without a usable id are dropped', () {
      final List<BlockedHasher> rows = HasherBlockService.parseBlockedRows(
        <dynamic>[
          <String, dynamic>{'PublicHasherId': lower, 'DisplayName': 'kept'},
          <String, dynamic>{'PublicHasherId': null, 'DisplayName': 'dropped'},
          <String, dynamic>{
            'PublicHasherId': '00000000-0000-0000-0000-000000000000',
            'DisplayName': 'dropped too',
          },
          'not a row',
        ],
      );
      expect(rows.map((BlockedHasher h) => h.displayName), <String>['kept']);
    });
  });

  test('the report reason cap matches the SP (1,000 characters)', () {
    expect(kChatReportReasonMaxLength, 1000);
  });
}
