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
    expect(out.any((LatLng p) => p.longitude > -0.1 + 0.0005), isTrue, reason: 'the kink survives');
  });

  test('a short trail is returned untouched', () {
    final List<LatLng> path = <LatLng>[const LatLng(1, 2), const LatLng(1.1, 2.1)];
    expect(identical(TrackIndex.simplify(path, 150), path), isTrue);
  });

  test('path storage round-trips at five decimals', () {
    final List<LatLng> path = <LatLng>[const LatLng(51.506321, -0.053049), const LatLng(51.50700, -0.05400)];
    final List<LatLng> back = TrackIndex.decodePath(TrackIndex.encodePath(path));
    expect(back.length, 2);
    expect(back[0].latitude, closeTo(51.50632, 1e-9));
    expect(back[0].longitude, closeTo(-0.05305, 1e-9));
    expect(TrackIndex.decodePath('not json'), isEmpty);
  });
}
