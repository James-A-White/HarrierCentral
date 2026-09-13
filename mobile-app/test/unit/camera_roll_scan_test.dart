import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/services/photos/camera_roll_scan_service.dart';
import 'package:latlong2/latlong.dart';

/// The two rules that decide whether a photo belongs to a run (E6.F2.S5).
/// Pure functions on purpose: the library and the platform stay out of it.
void main() {
  final DateTime start = DateTime.utc(2026, 9, 3, 15, 0);

  ScannableRun run({
    double? lat,
    double? lng,
    List<LatLng> trail = const <LatLng>[],
  }) => ScannableRun(
    eventId: 'e',
    eventName: 'Run',
    eventNumber: 1,
    kennelId: 'k',
    kennelSlug: 's',
    startUtc: start,
    startLat: lat,
    startLng: lng,
    trail: trail,
  );

  group('the time window', () {
    test('opens 30 minutes before the run and closes 6 hours after', () {
      expect(
        CameraRollScanService.withinWindow(
          start.subtract(const Duration(minutes: 29)),
          start,
        ),
        isTrue,
      );
      expect(
        CameraRollScanService.withinWindow(
          start.add(const Duration(hours: 5, minutes: 59)),
          start,
        ),
        isTrue,
      );
      expect(CameraRollScanService.withinWindow(start, start), isTrue);
    });

    test('rejects the morning before and the next day', () {
      expect(
        CameraRollScanService.withinWindow(
          start.subtract(const Duration(minutes: 31)),
          start,
        ),
        isFalse,
      );
      expect(
        CameraRollScanService.withinWindow(
          start.add(const Duration(hours: 6, minutes: 1)),
          start,
        ),
        isFalse,
      );
    });
  });

  group('the geofence', () {
    // A trail heading north from the circle for roughly a kilometre.
    final List<LatLng> trail = <LatLng>[
      const LatLng(51.5000, -0.1000),
      const LatLng(51.5050, -0.1000),
      const LatLng(51.5090, -0.1000),
    ];

    test('accepts a photo beside the far end of the trail, not just the start',
        () {
      // ~1 km from the start, but a few metres off the trail's last point.
      expect(
        CameraRollScanService.withinGeofence(51.5090, -0.1002, run(trail: trail)),
        isTrue,
      );
    });

    test('rejects a photo well away from every point of the trail', () {
      // ~2 km east of the whole trail.
      expect(
        CameraRollScanService.withinGeofence(51.5050, -0.0700, run(trail: trail)),
        isFalse,
      );
    });

    test('falls back to a radius around the start when there is no trail', () {
      final ScannableRun r = run(lat: 51.5, lng: -0.1);
      expect(CameraRollScanService.withinGeofence(51.5010, -0.1010, r), isTrue);

      // 10 km from 2026-09-13, widened from 2 km: a point-to-point or a coach
      // out of town leaves the old radius behind entirely. ~5 km used to be
      // rejected and is now accepted.
      expect(
        CameraRollScanService.withinGeofence(51.5450, -0.1000, r),
        isTrue,
        reason: '~5 km from the start is inside the 10 km fallback',
      );

      // The boundary still exists, which is the point of keeping this test.
      // ~22 km north is the rest of the county, not the trail.
      expect(
        CameraRollScanService.withinGeofence(51.7000, -0.1000, r),
        isFalse,
        reason: 'the fallback is wider, not absent',
      );
    });

    test('a run with neither a trail nor a location judges nothing', () {
      final ScannableRun blind = run();
      expect(blind.hasGeofence, isFalse);
      expect(
        CameraRollScanService.withinGeofence(51.5, -0.1, blind),
        isFalse,
        reason: 'a run we cannot place must not claim a photo',
      );
    });

    test('the trail is preferred over the start when both are known', () {
      // A point the START rule would REJECT and the TRAIL rule accepts, which
      // is what proves which rule ran. The start fallback is now 10 km, so this
      // has to reach beyond that: ~22 km north, with the trail running all the
      // way there. Before the widening ~4.4 km was enough.
      final List<LatLng> longTrail = <LatLng>[
        const LatLng(51.5000, -0.1000),
        const LatLng(51.7000, -0.1000), // ~22 km north, outside startRadius
      ];
      final ScannableRun r = ScannableRun(
        eventId: 'e',
        eventName: 'Run',
        eventNumber: 1,
        kennelId: 'k',
        kennelSlug: 's',
        startUtc: start,
        startLat: 51.5,
        startLng: -0.1,
        trail: longTrail,
      );
      // Beside the trail's FAR point — the geofence measures to trail points,
      // not along the line between them — and ~22 km from the start, so only
      // the trail rule can be accepting it.
      expect(
        CameraRollScanService.withinGeofence(51.7000, -0.1001, r),
        isTrue,
        reason: 'near the trail but far outside the 10 km start fallback',
      );
    });
  });
}
