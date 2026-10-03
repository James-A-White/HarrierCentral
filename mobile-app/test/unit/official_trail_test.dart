// The official trail's lane maths (E5.F6.S6): parsing the server's JSON,
// replay auto-align (position at elapsed ms), the scout/promote point
// builder, and On-Inn cutting for a promoted PackTrack.
import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/data/models/user_positions/user_positions.dart';
import 'package:harrier_central/services/official_trails/official_trail_overlay.dart';
import 'package:harrier_central/services/official_trails/official_trail_service.dart';
import 'package:harrier_central/util/hc_id.dart';
import 'package:latlong2/latlong.dart' as latlng;

void main() {
  group('parseLanes', () {
    test('timed and untimed lanes, with info', () {
      final lanes = OfficialTrailLane.parseLanes(
        '{"lanes":[{"type":3,"points":[[50.0,-0.1,0],[50.001,-0.1,60000]]},'
            '{"type":1,"points":[[50.0,-0.1],[50.002,-0.1]]}]}',
        '{"lanes":[{"type":3,"distanceM":111,"source":"scout"}]}',
      );
      expect(lanes, hasLength(2));
      expect(lanes[0].timed, isTrue);
      expect(lanes[0].distanceM, 111);
      expect(lanes[0].source, 'scout');
      expect(lanes[1].timed, isFalse);
      expect(lanes[1].distanceM, isNull);
    });

    test('a partly timed lane is untimed; junk is skipped', () {
      final lanes = OfficialTrailLane.parseLanes(
        '{"lanes":[{"type":3,"points":[[50,-0.1,0],[50.1,-0.1]]},'
            '{"type":2,"points":[[50,-0.1]]},"x"]}',
        'not json',
      );
      expect(lanes, hasLength(1));
      expect(lanes.single.timed, isFalse);
    });

    test('bad JSON gives no lanes', () {
      expect(OfficialTrailLane.parseLanes('{', null), isEmpty);
      expect(OfficialTrailLane.parseLanes(null, null), isEmpty);
    });
  });

  group('replay alignment', () {
    final lane = OfficialTrailLane.parseLanes(
      '{"lanes":[{"type":3,"points":[[50.0,0.0,0],[50.0,1.0,1000],[50.0,2.0,3000]]}]}',
      null,
    ).single;

    test('interpolates between points', () {
      expect(lane.positionAt(500)!.longitude, closeTo(0.5, 1e-9));
      expect(lane.positionAt(2000)!.longitude, closeTo(1.5, 1e-9));
    });

    test('before the start: nowhere; after the end: the last point', () {
      expect(lane.positionAt(-1), isNull);
      expect(lane.positionAt(99999)!.longitude, 2.0);
    });

    test('pointsUpTo ends at the current position', () {
      final pts = lane.pointsUpTo(2000);
      expect(pts, hasLength(3));
      expect(pts.last.longitude, closeTo(1.5, 1e-9));
    });

    test('an untimed lane is always whole', () {
      final untimed = OfficialTrailLane.parseLanes(
        '{"lanes":[{"type":3,"points":[[50,0],[50,1]]}]}',
        null,
      ).single;
      expect(untimed.positionAt(10), isNull);
      expect(untimed.pointsUpTo(10), hasLength(2));
    });
  });

  group('lanePointsFrom', () {
    TrackPoint p(double lng, int ts, {String? type}) =>
        TrackPoint(lat: 50, lng: lng, acc: 5, timestampMs: ts, type: type);

    test('times are relative, marks dropped, close points thinned', () {
      final out = OfficialTrailService.lanePointsFrom(<TrackPoint>[
        p(0.0, 1000000),
        p(0.00001, 1001000), // ~0.7 m: thinned
        p(0.001, 1002000, type: 'CHK'),
        p(0.001, 1005000),
        p(0.002, 1009000),
      ]);
      expect(out.points.map((List<num> x) => x[2]).toList(), <num>[0, 5000, 9000]);
      expect(out.distanceM, inInclusiveRange(140, 145)); // 0.002° lng at 50°N
    });

    test('too few points gives nothing', () {
      expect(OfficialTrailService.lanePointsFrom(<TrackPoint>[p(0, 1)]).points, isEmpty);
    });
  });

  test('a promoted track stops at On Inn and drops marks', () {
    final out = OfficialTrailOverlay.trackForPromotion(<TrackPoint>[
      TrackPoint(lat: 50, lng: 0.003, acc: 5, timestampMs: 4),
      TrackPoint(lat: 50, lng: 0.000, acc: 5, timestampMs: 1),
      TrackPoint(lat: 50, lng: 0.001, acc: 5, timestampMs: 2, type: 'TRL::3'),
      TrackPoint(lat: 50, lng: 0.002, acc: 5, timestampMs: 3, type: 'OIN'),
    ]);
    expect(out.map((TrackPoint t) => t.timestampMs), <int>[1]);
  });

  group('kennel start points', () {
    test('rows parse; a row with no position is skipped', () {
      final ok = KennelRunStart.fromRow(<String, dynamic>{
        'EventId': 'ABC', 'EventNumber': 1094, 'EventName': 'Hermitage',
        'EventStartLocal': '2025-09-14T11:00:00+00:00', 'Lat': 50.84618, 'Lon': '-0.92908',
      });
      expect(ok!.eventId, 'abc');
      expect(ok.point.longitude, closeTo(-0.92908, 1e-9));
      expect(ok.startLocal, DateTime(2025, 9, 14, 11));
      expect(KennelRunStart.fromRow(<String, dynamic>{'EventId': 'x', 'Lat': null, 'Lon': 1}), isNull);
    });

    test('runs at the same place share one pin, newest first', () {
      KennelRunStart s(int n, double lat, String day) => KennelRunStart(
        eventId: HcId('e$n'), eventNumber: n, eventName: '',
        startLocal: DateTime.parse(day), point: latlng.LatLng(lat, -0.9),
      );
      final places = KennelRunStart.group(<KennelRunStart>[
        s(1, 50.80001, '2020-01-05'),
        s(2, 50.80003, '2024-06-01'), // same place to ~10 m
        s(3, 50.90000, '2023-01-01'),
      ]);
      expect(places, hasLength(2));
      final busy = places.firstWhere((p) => p.runs.length == 2);
      expect(busy.runs.map((r) => r.eventNumber), <int>[2, 1]);
    });
  });
}
