import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/services/official_trails/official_trail_service.dart';

/// The kennel trail map's rows (hcapp_getKennelOfficialTrails, E5.F6.S6).
void main() {
  test('a row with a Normal and a Walkers lane', () {
    final KennelRunTrail? t = KennelRunTrail.fromRow(<String, dynamic>{
      'EventId': 'EE8FA2A4-0566-41E0-BFDA-63AF74377C19',
      'EventNumber': 1094,
      'EventName': 'Run 1094 - Westbourne',
      'EventStartLocal': '2026-09-20T11:00:00',
      'OfficialTrail':
          '{"lanes":[{"type":3,"points":[[50.86,-0.93],[50.87,-0.94]]},{"type":1,"points":[[50.86,-0.93],[50.861,-0.931]]}]}',
      'OfficialTrailInfo': '{"lanes":[{"type":3,"distanceM":6880},{"type":1,"distanceM":4100}]}',
    });
    expect(t, isNotNull);
    expect(t!.eventId, 'ee8fa2a4-0566-41e0-bfda-63af74377c19');
    expect(t.lanes.length, 2);
    expect(t.distanceM, 6880); // the Normal lane is the main one
    expect(t.startLocal, DateTime(2026, 9, 20, 11));
  });

  test('a row whose trail will not parse is left out, not fatal', () {
    expect(KennelRunTrail.fromRow(<String, dynamic>{'EventId': 'x', 'OfficialTrail': 'not json'}), isNull);
    expect(KennelRunTrail.fromRow(<String, dynamic>{'EventId': 'x', 'OfficialTrail': '{"lanes":[{"type":3,"points":[[1,2]]}]}'}), isNull);
  });
}
