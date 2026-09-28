import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/services/location_service/auto_start_detector.dart';
import 'package:latlong2/latlong.dart' as latlng;

/// PackTrack auto-start (James, 2026-09-27): arrive at the start, then be
/// more than 150 m from it for 60 s; the track backfills 60 s before the
/// runner first crossed out.
void main() {
  const latlng.LatLng start = latlng.LatLng(51.5000, -0.1000);
  // ~1 m of latitude = 1/111_195 degrees.
  double north(double metres) => start.latitude + metres / 111195;

  AutoStartFix at(double metresNorth, int seconds, {double acc = 8}) =>
      AutoStartFix(
        lat: north(metresNorth),
        lng: start.longitude,
        acc: acc,
        alt: 0,
        tsMs: seconds * 1000,
      );

  test('milling about the start never triggers', () {
    final d = AutoStartDetector(anchor: start);
    for (int s = 0; s < 1200; s += 15) {
      expect(d.add(at((s ~/ 15).isEven ? 20 : 120, s)), isNull);
    }
    expect(d.hasArrived, isTrue);
    expect(d.hasStarted, isFalse);
  });

  test('not arrived: far away and moving does not trigger', () {
    final d = AutoStartDetector(anchor: start);
    for (int s = 0; s < 600; s += 15) {
      expect(d.add(at(5000.0 + s, s)), isNull);
    }
    expect(d.hasArrived, isFalse);
  });

  test('arrive, then leave for 60 s: start = first crossing minus 60 s', () {
    final d = AutoStartDetector(anchor: start);
    d.add(at(10, 0));
    d.add(at(30, 30));
    expect(d.add(at(160, 100)), isNull); // first fix beyond 150 m
    expect(d.add(at(220, 130)), isNull);
    expect(d.add(at(300, 160)), 40000); // 100 s - 60 s backfill
    expect(d.hasStarted, isTrue);
    expect(d.add(at(400, 190)), isNull, reason: 'fires once');
  });

  test('stepping back inside resets the 60 s', () {
    final d = AutoStartDetector(anchor: start);
    d.add(at(0, 0));
    d.add(at(200, 10));
    d.add(at(200, 50));
    d.add(at(100, 60)); // back inside 150 m
    expect(d.add(at(200, 80)), isNull);
    expect(d.add(at(200, 120)), isNull); // 40 s outside
    expect(d.add(at(200, 140)), 20000); // 60 s after re-crossing at 80 s
  });

  test('poor fixes never decide', () {
    final d = AutoStartDetector(anchor: start);
    d.add(at(0, 0));
    for (int s = 10; s <= 200; s += 10) {
      expect(d.add(at(400, s, acc: 120)), isNull);
    }
    expect(d.hasStarted, isFalse);
  });

  test('no start point: the first good fix is the anchor (hare arming there)',
      () {
    final d = AutoStartDetector();
    d.add(at(1000, 0));
    expect(d.hasArrived, isTrue);
    d.add(at(1100, 30)); // 100 m from the anchor
    d.add(at(1200, 60));
    expect(d.add(at(1300, 120)), 0); // crossed at 60 s → start 0 s
  });

  test('ring keeps 15 minutes; pointsFrom gives the backfill', () {
    final d = AutoStartDetector(anchor: start);
    for (int s = 0; s <= 1800; s += 60) {
      d.add(at(10, s));
    }
    expect(d.ring.first.tsMs, 900000);
    expect(d.pointsFrom(1740000).length, 2);
  });

  test('indoors: a poor fix at the start still counts as arriving', () {
    // Black Death #200: the pack waited in a pub, fixes around 120 m.
    final d = AutoStartDetector(anchor: start);
    expect(d.add(at(90, 0, acc: 120)), isNull);
    expect(d.hasArrived, isTrue);
  });

  test('a kilometre-wide fix never counts as arriving', () {
    final d = AutoStartDetector(anchor: start);
    d.add(at(1500, 0, acc: 1000));
    expect(d.hasArrived, isFalse);
  });

  test('arriving on a poor fix, setting off still needs good fixes', () {
    final d = AutoStartDetector(anchor: start);
    d.add(at(20, 0, acc: 150)); // arrived, indoors
    for (int s = 10; s <= 200; s += 10) {
      expect(d.add(at(400, s, acc: 120)), isNull, reason: 'poor fixes');
    }
    expect(d.add(at(200, 210)), isNull);
    expect(d.add(at(260, 270)), 150000); // crossed at 210 s, minus 60 s
  });
}
