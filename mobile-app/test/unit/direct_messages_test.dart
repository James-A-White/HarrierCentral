// Direct messages (E9.F1.S7 / S18 / S19): the parts that decode a bitfield
// or read a server reply, which are pure and would otherwise only be
// exercised on a phone against production.
import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';

void main() {
  const String upperThread = '2F2C5D1E-8B0A-4C3B-9E7D-1A2B3C4D5E6F';
  const String lowerThread = '2f2c5d1e-8b0a-4c3b-9e7d-1a2b3c4d5e6f';
  const String upperHasher = 'F66CEFDF-23E0-43B6-88E9-90D4B9DA8487';
  const String lowerHasher = 'f66cefdf-23e0-43b6-88e9-90d4b9da8487';

  group('DirectMessagePreference — the two Preferences bits', () {
    test('every row is 0 today, and 0 is friends only', () {
      expect(DirectMessagePreference.decode(0), DirectMessagePreference.friendsOnly);
      expect(DirectMessagePreference.decode(null), DirectMessagePreference.friendsOnly);
    });

    test('decodes (Preferences >> 14) & 3 exactly as HC6.DirectMessagePreference', () {
      expect(DirectMessagePreference.decode(0x4000), DirectMessagePreference.anyone);
      expect(DirectMessagePreference.decode(0x8000), DirectMessagePreference.nobody);
      // The unused 3 reads as nobody, like the SQL function.
      expect(DirectMessagePreference.decode(0xC000), DirectMessagePreference.nobody);
    });

    test('ignores every other bit in the field', () {
      // Units, radius, camera roll, debug harvest — all set, DM bits clear.
      const int others = 0x3 | 0x3C | 0x80 | 0x100 | 0x2000;
      expect(DirectMessagePreference.decode(others), DirectMessagePreference.friendsOnly);
      expect(
        DirectMessagePreference.decode(others | 0x4000),
        DirectMessagePreference.anyone,
      );
    });

    test('withBits replaces only its own two bits', () {
      const int others = 0x3 | 0x3C | 0x80 | 0x100 | 0x2000;
      final int stored = DirectMessagePreference.withBits(
        others | 0x8000,
        DirectMessagePreference.anyone,
      );
      expect(stored & ~DirectMessagePreference.mask, others);
      expect(DirectMessagePreference.decode(stored), DirectMessagePreference.anyone);
      expect(
        DirectMessagePreference.withBits(stored, DirectMessagePreference.friendsOnly),
        others,
      );
    });

    test('mask is 0x4000|0x8000', () {
      expect(DirectMessagePreference.mask, 0xC000);
      expect(DirectMessagePreference.shift, 14);
    });

    test('parseSetReply reads rowset 1 after a success envelope', () {
      final String body = jsonEncode(<dynamic>[
        <dynamic>[
          <String, dynamic>{'success': 1, 'errorMessage': null},
        ],
        <dynamic>[
          <String, dynamic>{'Preference': 2},
        ],
      ]);
      expect(DirectMessagePreference.parseSetReply(body), DirectMessagePreference.nobody);
    });

    test('parseSetReply is null when the envelope says no', () {
      final String body = jsonEncode(<dynamic>[
        <dynamic>[
          <String, dynamic>{'success': 0, 'errorCode': 2000, 'errorType': 2},
        ],
      ]);
      expect(DirectMessagePreference.parseSetReply(body), isNull);
      expect(DirectMessagePreference.parseSetReply('[]'), isNull);
      expect(DirectMessagePreference.parseSetReply('not json'), isNull);
    });
  });

  group('DmStartResult.parseReply — what "Message <name>" came back with', () {
    String reply(Map<String, dynamic> row) => jsonEncode(<dynamic>[
      <dynamic>[
        <String, dynamic>{'success': 1, 'errorMessage': null},
      ],
      <dynamic>[row],
    ]);

    test('open carries the ThreadId, lowercased', () {
      final DmStartResult? r = DmStartResult.parseReply(
        reply(<String, dynamic>{
          'Outcome': 'open',
          'ThreadId': upperThread,
          'OtherPublicHasherId': upperHasher,
          'OtherDisplayName': 'Sir Spanks',
          'OtherPhoto': 'bundle://avatar-7',
        }),
      );
      expect(r, isNotNull);
      expect(r!.outcome, DmOutcome.open);
      expect(r.threadId, lowerThread);
      expect(r.otherPublicHasherId, lowerHasher);
      expect(r.otherDisplayName, 'Sir Spanks');
      expect(r.otherPhoto, 'bundle://avatar-7');
    });

    test('requested has no ThreadId', () {
      final DmStartResult? r = DmStartResult.parseReply(
        reply(<String, dynamic>{
          'Outcome': 'requested',
          'ThreadId': null,
          'OtherPublicHasherId': upperHasher,
          'OtherDisplayName': 'Sir Spanks',
        }),
      );
      expect(r!.outcome, DmOutcome.requested);
      expect(r.threadId, isNull);
    });

    test('refused, blocked and declined parse; case does not matter', () {
      for (final MapEntry<String, DmOutcome> e in <String, DmOutcome>{
        'refused': DmOutcome.refused,
        'BLOCKED': DmOutcome.blocked,
        ' declined ': DmOutcome.declined,
      }.entries) {
        final DmStartResult? r = DmStartResult.parseReply(
          reply(<String, dynamic>{
            'Outcome': e.key,
            'OtherPublicHasherId': lowerHasher,
            'OtherDisplayName': 'X',
          }),
        );
        expect(r!.outcome, e.value, reason: e.key);
      }
    });

    test('an outcome this build does not know is unknown, not a throw', () {
      final DmStartResult? r = DmStartResult.parseReply(
        reply(<String, dynamic>{
          'Outcome': 'teleported',
          'OtherPublicHasherId': lowerHasher,
          'OtherDisplayName': '',
        }),
      );
      expect(r!.outcome, DmOutcome.unknown);
      expect(r.otherDisplayName, 'A hasher');
    });

    test('null when the envelope refused, or the reply is not one', () {
      expect(
        DmStartResult.parseReply(
          jsonEncode(<dynamic>[
            <dynamic>[
              <String, dynamic>{'success': 0, 'errorCode': 2002, 'errorType': 2},
            ],
          ]),
        ),
        isNull,
      );
      expect(DmStartResult.parseReply('[]'), isNull);
      expect(DmStartResult.parseReply('[[]]'), isNull);
      expect(DmStartResult.parseReply('{'), isNull);
    });
  });

  group('DirectMessageRequest.fromJson', () {
    test('lowercases the public id and reads the date', () {
      final DirectMessageRequest r = DirectMessageRequest.fromJson(<String, dynamic>{
        'FromPublicHasherId': upperHasher,
        'DisplayName': 'Just Chris',
        'Photo': null,
        'RequestedAt': '2026-09-29T10:15:00+00:00',
      });
      expect(r.fromPublicHasherId, lowerHasher);
      expect(r.displayName, 'Just Chris');
      expect(r.photo, isNull);
      expect(r.requestedAt, DateTime.utc(2026, 9, 29, 10, 15));
    });

    test('parseRows drops a row with no usable id', () {
      final List<DirectMessageRequest> rows = DirectMessageRequest.parseRows(<dynamic>[
        <String, dynamic>{'FromPublicHasherId': lowerHasher, 'DisplayName': 'A'},
        <String, dynamic>{'FromPublicHasherId': '', 'DisplayName': 'B'},
        'not a row',
      ]);
      expect(rows.map((DirectMessageRequest r) => r.displayName), <String>['A']);
    });
  });

  group('EventChatSummary — a DM row from hcapp_getEventBadgeCount', () {
    Map<String, dynamic> dmRow() => <String, dynamic>{
      'BadgeCount': 2,
      'PublicEventId': null,
      'EventId': null,
      'EventName': 'Sir Spanks',
      'EventNumber': null,
      'EventStartDatetimeGmt': null,
      'EventImage': null,
      'KennelId': null,
      'PublicKennelId': null,
      'KennelShortName': null,
      'KennelLogo': 'bundle://avatar-7',
      'MessageCount': 5,
      'LastMessageAt': '2026-09-29T10:15:00+00:00',
      'Pinned': 0,
      'RoomType': null,
      'RoomIcon': null,
      'ThreadId': upperThread,
      'OtherPublicHasherId': upperHasher,
      'OtherDisplayName': 'Sir Spanks',
      'OtherPhoto': 'bundle://avatar-7',
    };

    test('is a DM and nothing else', () {
      final EventChatSummary s = EventChatSummary.fromJson(dmRow());
      expect(s.isDmThread, isTrue);
      expect(s.isKennelThread, isFalse);
      expect(s.isRoomThread, isFalse);
      expect(s.eventId, isNull);
      expect(s.publicEventId, '');
      expect(s.threadId, lowerThread);
      expect(s.otherPublicHasherId, lowerHasher);
      expect(s.otherDisplayName, 'Sir Spanks');
      expect(s.otherPhoto, 'bundle://avatar-7');
      expect(s.badgeCount, 2);
      expect(s.messageCount, 5);
      expect(s.pinned, isFalse);
    });

    test('withBadgeCount keeps the DM identity', () {
      final EventChatSummary s = EventChatSummary.fromJson(dmRow()).withBadgeCount(0);
      expect(s.badgeCount, 0);
      expect(s.isDmThread, isTrue);
      expect(s.threadId, lowerThread);
      expect(s.otherDisplayName, 'Sir Spanks');
    });

    test('a row without the four DM columns is not a DM (older SP)', () {
      final Map<String, dynamic> row = dmRow()
        ..remove('ThreadId')
        ..remove('OtherPublicHasherId')
        ..remove('OtherDisplayName')
        ..remove('OtherPhoto');
      final EventChatSummary s = EventChatSummary.fromJson(row);
      expect(s.isDmThread, isFalse);
      expect(s.threadId, isNull);
    });

    test('a room row and a kennel row are still what they were', () {
      final EventChatSummary room = EventChatSummary.fromJson(<String, dynamic>{
        'BadgeCount': 0,
        'RoomType': 3,
        'ThreadId': null,
      });
      expect(room.isRoomThread, isTrue);
      expect(room.isDmThread, isFalse);
      final EventChatSummary kennel = EventChatSummary.fromJson(<String, dynamic>{
        'BadgeCount': 1,
        'KennelId': upperHasher,
        'PublicKennelId': upperHasher,
      });
      expect(kennel.isKennelThread, isTrue);
      expect(kennel.isDmThread, isFalse);
    });

    test('the badge key for a DM cannot collide with a run or kennel key', () {
      final EventChatSummary s = EventChatSummary.fromJson(dmRow());
      expect(NotificationService.dmBadgeKey(s.threadId!), 'dm:$lowerThread');
    });
  });
}
