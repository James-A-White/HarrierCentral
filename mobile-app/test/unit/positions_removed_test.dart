import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/data/models/user_positions/user_positions.dart';

/// GetPositions returns deletions on an incremental poll (2026-10-02,
/// PositionTombstones) so the map never needs a full re-download to learn a
/// point is gone. Older servers, and every full fetch, send no `removed`.
void main() {
  test('removed parses from an incremental reply', () {
    final p = UserPositionsPayload.fromJson(<String, dynamic>{
      'eventId': 'e1',
      'latestServerTimestampMs': '0000001759400000000',
      'users': <dynamic>[],
      'removed': <dynamic>[
        <String, dynamic>{'id': 'u1', 'timestampMs': 1759400000123, 'type': 'LST'},
        <String, dynamic>{'id': 'u2', 'timestampMs': 1759400000456},
      ],
    });
    expect(p.removed, hasLength(2));
    expect(p.removed.first.id, 'u1');
    expect(p.removed.first.timestampMs, 1759400000123);
    expect(p.removed.first.type, 'LST');
    expect(p.removed.last.type, isNull);
  });

  test('a reply without removed (full fetch, older server) is empty', () {
    final p = UserPositionsPayload.fromJson(<String, dynamic>{
      'eventId': 'e1',
      'users': <dynamic>[],
    });
    expect(p.removed, isEmpty);
  });
}
