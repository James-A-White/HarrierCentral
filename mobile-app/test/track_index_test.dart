import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/util/track_index.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('simplify keeps the ends, drops collinear points, respects the cap', () {
    // A 1,000-point trail: a straight line with a kink in the middle.
    final List<LatLng> path = List<LatLng>.generate(
      1000,
      (int i) => LatLng(51.5 + i * 0.00001, i == 500 ? -0.1 + 0.001 : -0.1),
    );
    final List<LatLng> out = TrackIndex.simplify(path, 150);
    expect(out.length, lessThanOrEqualTo(150));
    expect(out.first, path.first);
    expect(out.last, path.last);
    expect(
      out.any((LatLng p) => p.longitude > -0.1 + 0.0005),
      isTrue,
      reason: 'the kink survives',
    );
  });

  test('a short trail is returned untouched', () {
    final List<LatLng> path = <LatLng>[
      const LatLng(1, 2),
      const LatLng(1.1, 2.1),
    ];
    expect(identical(TrackIndex.simplify(path, 150), path), isTrue);
  });

  test(
    'detail tolerance follows the zoom: none below the threshold, finer as it grows',
    () {
      expect(
        TrackIndex.toleranceDegForZoom(TrackIndex.detailFromZoom - 0.01, 51.5),
        isNull,
      );
      final double? z12 = TrackIndex.toleranceDegForZoom(12, 51.5);
      final double? z16 = TrackIndex.toleranceDegForZoom(16, 51.5);
      expect(z12, isNotNull);
      expect(z16, isNotNull);
      // Four zoom levels = 16x more pixels per metre = 16x finer tolerance.
      expect(z12! / z16!, closeTo(16, 1e-6));
      // At zoom 16 near London a pixel is about 1.5 m: sub-pixel tolerance stays
      // under 2 m of latitude.
      expect(z16 * 111320, lessThan(2));
      // Nearer the pole a pixel covers less ground, so the tolerance is finer.
      expect(
        TrackIndex.toleranceDegForZoom(14, 60)!,
        lessThan(TrackIndex.toleranceDegForZoom(14, 0)!),
      );
    },
  );

  test('a finer tolerance keeps more of the trail than the overview cap', () {
    // A wiggly 2,000-point trail: a sine wave a few metres wide.
    final List<LatLng> path = List<LatLng>.generate(
      2000,
      (int i) => LatLng(51.5 + i * 0.00002, -0.1 + 0.00004 * (i % 7 - 3)),
    );
    final List<LatLng> overview = TrackIndex.simplify(
      path,
      TrackIndex.maxSimplifiedPoints,
    );
    final List<LatLng> detail = TrackIndex.simplifyTo(
      path,
      TrackIndex.toleranceDegForZoom(17, 51.5)!,
    );
    expect(overview.length, lessThanOrEqualTo(TrackIndex.maxSimplifiedPoints));
    expect(detail.length, greaterThan(overview.length));
    expect(detail.first, path.first);
    expect(detail.last, path.last);
  });

  test('a trail is measured from its full path, not the drawn simplification',
      () {
    // One degree of latitude is about 111.2 km; a tenth of a degree due north
    // is a known length to check the haversine against.
    final List<LatLng> north = <LatLng>[
      const LatLng(51.5, -0.1),
      const LatLng(51.6, -0.1),
    ];
    expect(TrackIndex.pathLengthMeters(north), closeTo(11119, 40));

    expect(TrackIndex.pathLengthMeters(const <LatLng>[]), 0);
    expect(TrackIndex.pathLengthMeters(<LatLng>[const LatLng(1, 2)]), 0);

    // A wiggly trail: simplifying for the screen loses real distance, which
    // is exactly why the figure is measured once on the full path.
    final List<LatLng> wiggly = List<LatLng>.generate(
      2000,
      (int i) => LatLng(51.5 + i * 0.00002, -0.1 + 0.00004 * (i % 7 - 3)),
    );
    final double full = TrackIndex.pathLengthMeters(wiggly);
    final double drawn = TrackIndex.pathLengthMeters(
      TrackIndex.simplify(wiggly, TrackIndex.maxSimplifiedPoints),
    );
    expect(full, greaterThan(drawn));
  });

  test('path storage round-trips at five decimals', () {
    final List<LatLng> path = <LatLng>[
      const LatLng(51.506321, -0.053049),
      const LatLng(51.50700, -0.05400),
    ];
    final List<LatLng> back = TrackIndex.decodePath(
      TrackIndex.encodePath(path),
    );
    expect(back.length, 2);
    expect(back[0].latitude, closeTo(51.50632, 1e-9));
    expect(back[0].longitude, closeTo(-0.05305, 1e-9));
    expect(TrackIndex.decodePath('not json'), isEmpty);
  });
}
