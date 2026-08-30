import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/data/models/user_positions/user_positions.dart';
import 'package:harrier_central/util/track_point_filter.dart';

/// Pins the contract this filter shares with public-web `lib/packtrack.ts`.
/// If you change one, change the other and update these expectations.
TrackPoint p(int sec, double lat, double lng, double acc, {String? type}) =>
    TrackPoint(
      lat: lat,
      lng: lng,
      acc: acc,
      timestampMs: 1700000000000 + sec * 15000,
      type: type,
    );

void main() {
  final TrackPointFilter filter = TrackPointFilter();

  /// A straight, slow, accurate walk north — the "good GPS" baseline.
  List<TrackPoint> cleanWalk({int n = 12, double acc = 6}) => List.generate(
        n,
        (int i) => p(i, 51.0 + i * 0.0004, 4.0, acc),
      );

  group('accurate tracks are left alone', () {
    test('every point survives unmoved', () {
      final List<TrackPoint> input = cleanWalk();
      final List<TrackPoint> out = filter.filterAndInterpolate(input);
      expect(out.length, input.length);
      for (int i = 0; i < input.length; i++) {
        expect(out[i].lat, input[i].lat);
        expect(out[i].lng, input[i].lng);
      }
    });

    test('a fix at the trust threshold is still untouched', () {
      final List<TrackPoint> input = cleanWalk(acc: 20);
      final List<TrackPoint> out = filter.filterAndInterpolate(input);
      expect(out[5].lat, input[5].lat);
    });
  });

  group('uncertain fixes are pulled back toward their neighbours', () {
    test('a wildly inaccurate fix is corrected, not dropped', () {
      final List<TrackPoint> input = cleanWalk();
      // Same moment, but flung 500m east with a hopeless accuracy radius.
      input[6] = p(6, 51.0024, 4.0072, 300);
      final List<TrackPoint> out = filter.filterAndInterpolate(input);

      // It survives — the old accuracy gate deleted points like this and
      // interpolated over the hole, which on a long run erased whole minutes.
      expect(out.length, input.length);
      // ...and it has been pulled back to within a few metres of the line.
      expect((out[6].lng - 4.0).abs(), lessThan(0.0005));
    });

    test('a stray fix ends up near the trail at any uncertainty', () {
      // Smoothing and the velocity pass complement each other, and which one
      // does the work is NOT monotonic in accuracy: a lightly smoothed fix can
      // still be far enough out to fail the velocity check, and interpolation
      // then puts it exactly on the line; a heavily smoothed one is pulled in
      // far enough to survive, with a small residual. What is guaranteed either
      // way is that it no longer sticks out into the map.
      for (final double acc in <double>[30, 60, 90, 200, 600]) {
        final List<TrackPoint> input = cleanWalk();
        input[6] = p(6, 51.0024, 4.0072, acc);
        final List<TrackPoint> out = filter.filterAndInterpolate(input);
        expect(out.length, input.length, reason: 'acc=$acc dropped a point');
        expect(
          (out[6].lng - 4.0).abs(),
          lessThan(0.0005), // ~35m
          reason: 'acc=$acc left the fix sticking out',
        );
      }
    });
  });

  group('marks', () {
    test('a photo mark never moves and never anchors the track', () {
      final List<TrackPoint> input = cleanWalk();
      // An imported photo, dropped where the PHOTOGRAPHER stood, far off-trail.
      input.insert(6, p(6, 51.02, 4.03, 5, type: 'PHO::abc'));
      final List<TrackPoint> out = filter.filterAndInterpolate(input);

      final TrackPoint photo =
          out.firstWhere((TrackPoint q) => q.type == 'PHO::abc');
      expect(photo.lat, 51.02);
      expect(photo.lng, 4.03);
      // The GPS fixes around it are untouched — the photo must not make them
      // look like impossible sprints (BMPH3 #2060 added 1.09km that way).
      final List<TrackPoint> gps =
          out.where((TrackPoint q) => q.type == null).toList();
      expect(gps.length, 12);
      for (final TrackPoint q in gps) {
        expect(q.lng, 4.0);
      }
    });

    test('a trail mark stays exactly where it was dropped', () {
      final List<TrackPoint> input = cleanWalk();
      input.insert(6, p(6, 51.0024, 4.0, 90, type: 'CHK'));
      final List<TrackPoint> out = filter.filterAndInterpolate(input);
      final TrackPoint chk =
          out.firstWhere((TrackPoint q) => q.type == 'CHK');
      expect(chk.lat, 51.0024);
    });
  });

  test('too little data to judge is returned unchanged', () {
    final List<TrackPoint> input = <TrackPoint>[p(0, 51.0, 4.0, 400)];
    expect(filter.filterAndInterpolate(input), input);
  });
}
