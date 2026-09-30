import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/data/models/user_positions/user_positions.dart';
import 'package:harrier_central/services/location_service/gps_health.dart';

/// PackTrack GPS health (E5.F1.S13): the signal light's colour from the age
/// and accuracy of the last fix, and the track-health line on the run
/// summary.
void main() {
  group('classifySignal', () {
    test('a recent, tight fix is green', () {
      expect(
        classifySignal(age: const Duration(seconds: 8), accuracyM: 6),
        SignalLight.green,
      );
      expect(
        classifySignal(age: const Duration(seconds: 29), accuracyM: 25),
        SignalLight.green,
      );
    });

    test('a recent but loose fix is amber', () {
      expect(
        classifySignal(age: const Duration(seconds: 5), accuracyM: 26),
        SignalLight.amber,
      );
      expect(
        classifySignal(age: const Duration(seconds: 5), accuracyM: 80),
        SignalLight.amber,
      );
    });

    test('a tight fix going stale is amber, then red at two minutes', () {
      expect(
        classifySignal(age: const Duration(seconds: 30), accuracyM: 5),
        SignalLight.amber,
      );
      expect(
        classifySignal(age: const Duration(seconds: 119), accuracyM: 5),
        SignalLight.amber,
      );
      expect(
        classifySignal(age: const Duration(seconds: 120), accuracyM: 5),
        SignalLight.red,
      );
    });

    test('no fix yet is amber until two minutes, then red', () {
      expect(
        classifySignal(age: const Duration(seconds: 10), accuracyM: null),
        SignalLight.amber,
      );
      expect(
        classifySignal(age: const Duration(minutes: 3), accuracyM: null),
        SignalLight.red,
      );
    });
  });

  group('signalText', () {
    test('says the age and accuracy', () {
      expect(
        signalText(age: const Duration(seconds: 8), accuracyM: 6.4),
        'GPS 8 s ago · 6 m',
      );
      expect(
        signalText(age: const Duration(seconds: 75), accuracyM: 12),
        'GPS 1 min ago · 12 m',
      );
    });

    test('waiting, silent and standing still', () {
      expect(
        signalText(age: const Duration(seconds: 3), accuracyM: null),
        'Waiting for GPS…',
      );
      expect(
        signalText(age: const Duration(minutes: 2), accuracyM: null),
        'No GPS fix for 2 min',
      );
      expect(
        signalText(age: const Duration(minutes: 4), accuracyM: 5),
        'No GPS fix for 4 min',
      );
      expect(
        signalText(
          age: const Duration(seconds: 20),
          accuracyM: 5,
          stationary: true,
        ),
        'GPS fine · standing still',
      );
    });
  });

  group('TrackHealth', () {
    TrackPoint fix(int seconds, {String? type}) => TrackPoint(
      lat: 51.5,
      lng: -0.1,
      acc: 5,
      timestampMs: seconds * 1000,
      type: type,
    );

    test('counts fixes, finds the longest gap, names the tier', () {
      final TrackHealth h = TrackHealth.compute(
        points: [fix(0), fix(10), fix(70), fix(75), fix(80)],
        tier: 2,
      );
      expect(h.fixCount, 5);
      expect(h.longestGap, const Duration(seconds: 60));
      expect(h.line, '5 fixes · longest gap 1 min · Best');
    });

    test('marks are not fixes and order does not matter', () {
      final TrackHealth h = TrackHealth.compute(
        points: [fix(40), fix(0, type: 'GLY::check'), fix(20), fix(0)],
        tier: 1,
      );
      expect(h.fixCount, 3);
      expect(h.longestGap, const Duration(seconds: 20));
      expect(h.line, '3 fixes · longest gap 20 s · Balanced');
    });

    test('a long hole is the story, and the pre-flight names the cause', () {
      final List<TrackPoint> points = <TrackPoint>[
        for (int i = 0; i < 92; i++)
          fix(i < 46 ? i * 10 : 460 + 27 * 60 + (i - 46) * 10),
      ];
      final TrackHealth h = TrackHealth.compute(
        points: points,
        tier: 2,
        problem: 'Location was While Using',
      );
      expect(h.fixCount, 92);
      expect(h.longestGap, const Duration(minutes: 27, seconds: 10));
      expect(h.line, '92 fixes · a 27-minute gap · Location was While Using');
    });

    test('Power Saver reads as the tier when nothing else was wrong', () {
      final TrackHealth h = TrackHealth.compute(
        points: [for (int i = 0; i < 15; i++) fix(i * 240)],
        tier: 0,
      );
      expect(h.line, '15 fixes · longest gap 4 min · Power Saver');
    });

    test('no tier known (a past run from the server) ends at the gap', () {
      expect(
        TrackHealth.compute(points: [fix(0), fix(5)], tier: null).line,
        '2 fixes · longest gap 5 s',
      );
    });

    test('nothing recorded, and a single fix', () {
      expect(
        TrackHealth.compute(points: const [], tier: 2).line,
        'No GPS fixes were recorded · Best',
      );
      expect(
        TrackHealth.compute(
          points: const [],
          tier: 2,
          problem: 'Precise Location was off',
        ).line,
        'No GPS fixes were recorded · Precise Location was off',
      );
      expect(
        TrackHealth.compute(points: [fix(0)], tier: 2).line,
        '1 fix · Best',
      );
    });

    test('tier names', () {
      expect(trackingTierName(0), 'Power Saver');
      expect(trackingTierName(1), 'Balanced');
      expect(trackingTierName(2), 'Best');
      expect(trackingTierName(null), 'Best');
    });
  });
}
