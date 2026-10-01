import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/services/location_service/auto_start_detector.dart';
import 'package:latlong2/latlong.dart' as latlng;

/// Auto start's motion trigger (E5.F1.S15): running starts it, walking
/// starts it only away from the start, a vehicle vetoes everything.
void main() {
  const int t0 = 1000000;
  int? check(MotionStartRule r, int secs, {bool arrived = true, double? m = 20}) =>
      r.check(nowMs: t0 + secs * 1000, arrived: arrived, metersFromStart: m);

  test('running for 20 s after arriving starts, backfilled 60 s', () {
    final r = MotionStartRule()..onActivity('running', 90, t0);
    expect(check(r, 19), isNull);
    expect(check(r, 20), t0 - 60000);
  });

  test('nothing before arriving at the start', () {
    final r = MotionStartRule()..onActivity('running', 90, t0);
    expect(check(r, 60, arrived: false), isNull);
  });

  test('walking near the start is milling, not setting off', () {
    final r = MotionStartRule()..onActivity('walking', 90, t0);
    expect(check(r, 120, m: 60), isNull);
    expect(check(r, 120, m: null), isNull);
  });

  test('walking more than 100 m from the start, for 20 s, starts', () {
    final r = MotionStartRule()..onActivity('walking', 60, t0);
    expect(check(r, 25, m: 120), t0 - 60000);
  });

  test('a vehicle vetoes, for two minutes', () {
    final r = MotionStartRule()
      ..onActivity('inVehicle', 90, t0)
      ..onActivity('running', 90, t0 + 1000);
    expect(r.vetoed(t0 + 60000), isTrue);
    expect(check(r, 60), isNull);
    expect(r.vetoed(t0 + 121000), isFalse);
    expect(check(r, 121), t0 + 1000 - 60000);
  });

  test('low confidence is ignored, not a reset', () {
    final r = MotionStartRule()
      ..onActivity('running', 90, t0)
      ..onActivity('still', 30, t0 + 5000);
    expect(check(r, 25), t0 - 60000);
  });

  test('stopping resets the clock', () {
    final r = MotionStartRule()
      ..onActivity('running', 90, t0)
      ..onActivity('still', 90, t0 + 10000)
      ..onActivity('running', 90, t0 + 15000);
    expect(check(r, 30), isNull);
    expect(check(r, 35), t0 + 15000 - 60000);
  });

  test('a blocked fix never counts towards the GPS departure', () {
    final d = AutoStartDetector(anchor: const latlng.LatLng(51.5, -0.1));
    AutoStartFix at(int s, double lat) =>
        AutoStartFix(lat: lat, lng: -0.1, acc: 5, alt: 0, tsMs: t0 + s * 1000);
    expect(d.add(at(0, 51.5)), isNull); // arrive
    // ~550 m north for two minutes, in a vehicle: no start.
    for (int s = 10; s <= 130; s += 10) {
      expect(d.add(at(s, 51.505), blocked: true), isNull);
    }
    // Out of the vehicle, still away: the 60 s clock starts afresh.
    expect(d.add(at(140, 51.505)), isNull);
    expect(d.add(at(200, 51.505)), isNotNull);
  });
}
