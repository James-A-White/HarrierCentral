import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/util/trail_gap.dart';
import 'package:latlong2/latlong.dart';

// Tracks are drawn in metres east (x) / north (y) of a fixed spot, one point
// every 10 m, as a phone's 5 m filter would roughly give.
const double _lat0 = 51.5, _lng0 = -0.1;
const double _mPerDeg = 6371008.8 * math.pi / 180;

LatLng _at(double x, double y) => LatLng(
  _lat0 + y / _mPerDeg,
  _lng0 + x / (_mPerDeg * math.cos(_lat0 * math.pi / 180)),
);

/// A track through [corners] (metres), a point every 10 m.
List<LatLng> _track(List<List<double>> corners) {
  final List<LatLng> out = <LatLng>[_at(corners.first[0], corners.first[1])];
  for (int i = 1; i < corners.length; i++) {
    final double x0 = corners[i - 1][0], y0 = corners[i - 1][1];
    final double x1 = corners[i][0], y1 = corners[i][1];
    final double len = math.sqrt(math.pow(x1 - x0, 2) + math.pow(y1 - y0, 2));
    final int steps = math.max(1, (len / 10).round());
    for (int k = 1; k <= steps; k++) {
      out.add(_at(x0 + (x1 - x0) * k / steps, y0 + (y1 - y0) * k / steps));
    }
  }
  return out;
}

void main() {
  group('TrailGapCalculator — on the leader\'s track', () {
    test('them behind me on my track: I am ahead by the gap', () {
      final TrailGap g = TrailGapCalculator.compute(
        me: _track(<List<double>>[
          <double>[0, 0],
          <double>[1000, 0],
        ]),
        them: _track(<List<double>>[
          <double>[0, 0],
          <double>[931, 0],
        ]),
      );
      expect(g.basis, TrailGapBasis.myTrack);
      expect(g.meAhead, isTrue);
      expect(g.trailMeters, closeTo(69, 2));
      expect(g.crowMeters, closeTo(69, 2));
      expect(g.segment, isNotEmpty);
    });

    test('me behind them on their track: they are ahead', () {
      final TrailGap g = TrailGapCalculator.compute(
        me: _track(<List<double>>[
          <double>[0, 0],
          <double>[931, 0],
        ]),
        them: _track(<List<double>>[
          <double>[0, 0],
          <double>[1000, 0],
        ]),
      );
      expect(g.basis, TrailGapBasis.theirTrack);
      expect(g.meAhead, isFalse);
      expect(g.trailMeters, closeTo(69, 2));
      // Follower → leader: starts at me, ends at them.
      expect(
        const Distance().as(LengthUnit.Meter, g.segment.first, _at(931, 0)),
        lessThan(2),
      );
      expect(
        const Distance().as(LengthUnit.Meter, g.segment.last, _at(1000, 0)),
        lessThan(2),
      );
    });

    test('a false trail I ran out and back is not counted', () {
      // East 300 m, 200 m up a false trail and back, then on east to 1000.
      final TrailGap g = TrailGapCalculator.compute(
        me: _track(<List<double>>[
          <double>[0, 0],
          <double>[300, 0],
          <double>[300, 200],
          <double>[300, 0],
          <double>[1000, 0],
        ]),
        them: _track(<List<double>>[
          <double>[0, 0],
          <double>[100, 0],
        ]),
      );
      expect(g.basis, TrailGapBasis.myTrack);
      // 1300 m of my track, 900 m of trail.
      expect(g.trailMeters, closeTo(900, 3));
      expect(g.crowMeters, closeTo(900, 3));
    });

    test('the loop of a lollipop trail is counted, not cut out', () {
      // Out 1500 m, round a 2 km loop, back to the 1000 m mark; they are at
      // the 1000 m mark on the way out — beside me, 3 km behind.
      final TrailGap g = TrailGapCalculator.compute(
        me: _track(<List<double>>[
          <double>[0, 0],
          <double>[1500, 0],
          <double>[1500, 500],
          <double>[2000, 500],
          <double>[2000, 0],
          <double>[1500, 0],
          <double>[1000, 0],
        ]),
        them: _track(<List<double>>[
          <double>[0, 0],
          <double>[1000, 0],
        ]),
      );
      expect(g.basis, TrailGapBasis.myTrack);
      expect(g.meAhead, isTrue);
      expect(g.trailMeters, closeTo(3000, 5));
      expect(g.crowMeters, lessThan(2));
    });

    test('side by side is a gap of about nothing', () {
      final TrailGap g = TrailGapCalculator.compute(
        me: _track(<List<double>>[
          <double>[0, 0],
          <double>[1000, 0],
        ]),
        them: _track(<List<double>>[
          <double>[0, 0],
          <double>[995, 0],
        ]),
      );
      expect(g.trailMeters, lessThan(10));
    });
  });

  group('TrailGapCalculator — no shared trail', () {
    test('a parallel path 100 m away is not my trail', () {
      final TrailGap g = TrailGapCalculator.compute(
        me: _track(<List<double>>[
          <double>[0, 0],
          <double>[1000, 0],
        ]),
        them: _track(<List<double>>[
          <double>[0, 100],
          <double>[900, 100],
        ]),
      );
      expect(g.basis, TrailGapBasis.none);
      expect(g.onSameTrail, isFalse);
      expect(g.trailMeters, isNull);
      expect(g.meAhead, isNull);
      expect(g.segment, isEmpty);
      expect(g.crowMeters, closeTo(141, 2));
    });

    test('an empty track gives nothing at all', () {
      final TrailGap g = TrailGapCalculator.compute(
        me: const <LatLng>[],
        them: _track(<List<double>>[
          <double>[0, 0],
          <double>[10, 0],
        ]),
      );
      expect(g.basis, TrailGapBasis.none);
    });
  });

  group('TrailGapCalculator — official trail', () {
    test('is preferred, and my check excursion costs nothing on it', () {
      final List<LatLng> lane = _track(<List<double>>[
        <double>[0, 0],
        <double>[2000, 0],
      ]);
      final TrailGap g = TrailGapCalculator.compute(
        me: _track(<List<double>>[
          <double>[0, 0],
          <double>[400, 0],
          <double>[400, 250],
          <double>[400, 0],
          <double>[800, 0],
        ]),
        them: _track(<List<double>>[
          <double>[0, 0],
          <double>[300, 0],
        ]),
        officialLanes: <List<LatLng>>[lane],
      );
      expect(g.basis, TrailGapBasis.officialTrail);
      expect(g.meAhead, isTrue);
      expect(g.trailMeters, closeTo(500, 2));
    });

    test('an out-and-back trail puts each runner on the right pass', () {
      // The trail goes 3 km east and returns along the same road. I am on
      // the way home at the 2.5 km mark; they are on the way out at 2.5 km.
      final List<LatLng> lane = _track(<List<double>>[
        <double>[0, 0],
        <double>[3000, 0],
        <double>[0, 0],
      ]);
      final TrailGap g = TrailGapCalculator.compute(
        me: _track(<List<double>>[
          <double>[0, 0],
          <double>[3000, 0],
          <double>[2500, 0],
        ]),
        them: _track(<List<double>>[
          <double>[0, 0],
          <double>[2500, 0],
        ]),
        officialLanes: <List<LatLng>>[lane],
      );
      expect(g.basis, TrailGapBasis.officialTrail);
      expect(g.meAhead, isTrue);
      expect(g.trailMeters, closeTo(1000, 3));
      expect(g.crowMeters, lessThan(2));
    });

    test('a runner off the official trail falls back to the tracks', () {
      final List<LatLng> lane = _track(<List<double>>[
        <double>[0, 500],
        <double>[2000, 500],
      ]);
      final TrailGap g = TrailGapCalculator.compute(
        me: _track(<List<double>>[
          <double>[0, 0],
          <double>[1000, 0],
        ]),
        them: _track(<List<double>>[
          <double>[0, 0],
          <double>[931, 0],
        ]),
        officialLanes: <List<LatLng>>[lane],
      );
      expect(g.basis, TrailGapBasis.myTrack);
      expect(g.trailMeters, closeTo(69, 2));
    });
  });
}
