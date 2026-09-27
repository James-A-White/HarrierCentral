import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/data/models/user_positions/user_positions.dart';
import 'package:harrier_central/services/location_service/run_summary.dart';

/// End-of-run summary (James, 2026-09-27): checks gone through, drink stops,
/// time at them.
void main() {
  const double lat0 = 51.5000;
  const double lng0 = -0.1000;
  // ~1 m of latitude.
  double north(double m) => lat0 + m / 111195;

  TrackPoint gps(double metresNorth, int seconds) => TrackPoint(
    lat: north(metresNorth),
    lng: lng0,
    acc: 5,
    timestampMs: seconds * 1000,
  );
  TrackPoint mark(double metresNorth, String type, {int seconds = 0}) =>
      TrackPoint(
        lat: north(metresNorth),
        lng: lng0,
        acc: 5,
        timestampMs: seconds * 1000,
        type: type,
      );

  test('classifies every mark scheme', () {
    expect(classifyMark('GLY::check'), SummaryMarkKind.check);
    expect(classifyMark('GLY::check::L=left'), SummaryMarkKind.check);
    expect(classifyMark('GLY::drinkstop'), SummaryMarkKind.drinkStop);
    expect(classifyMark('TXT::DS'), SummaryMarkKind.drinkStop);
    expect(classifyMark('I-002.png'), SummaryMarkKind.check);
    expect(classifyMark('I-450.png::the Swan'), SummaryMarkKind.drinkStop);
    expect(classifyMark('CHK'), SummaryMarkKind.check);
    expect(classifyMark('DRK'), SummaryMarkKind.drinkStop);
    expect(classifyMark(null), isNull);
    expect(classifyMark('GLY::label::L=bog'), isNull);
    expect(classifyMark('TXT::FT'), isNull);
    expect(classifyMark('OIN'), isNull);
    expect(classifyMark('PHO::abc'), isNull);
    expect(classifyMark('TRL::3'), isNull);
  });

  test('counts the checks the track went through, merging duplicates', () {
    // A straight run north from 0 to 1000 m, a fix every 10 m / 5 s.
    final List<TrackPoint> own = [
      for (int i = 0; i <= 100; i++) gps(i * 10.0, i * 5),
    ];
    final List<TrackPoint> others = [
      mark(300, 'GLY::check'),
      mark(310, 'GLY::check'), // same check, marked twice
      mark(700, 'I-001.png'),
      mark(500, 'GLY::check').copyWith(lng: lng0 + 0.01), // ~700 m east: missed
    ];
    final s = RunSummary.compute(ownTrack: own, allPoints: [...own, ...others]);
    expect(s.checksOnTrail, 3);
    expect(s.checksReached, 2);
    expect(s.drinkStopsReached, 0);
    expect(s.drinkStopTime, Duration.zero);
  });

  test('time at a drink stop is the time spent near it', () {
    final List<TrackPoint> own = [
      gps(0, 0),
      gps(200, 60),
      gps(500, 120), // arrive
      gps(505, 400), // standing about: few fixes
      gps(495, 900),
      gps(520, 1200), // leave (still inside 40 m)
      gps(700, 1260),
    ];
    final s = RunSummary.compute(
      ownTrack: own,
      allPoints: [...own, mark(500, 'GLY::drinkstop')],
    );
    expect(s.drinkStopsReached, 1);
    expect(s.drinkStopTime, const Duration(seconds: 1080));
  });

  test("a mark the runner placed counts even when their GPS missed it", () {
    final List<TrackPoint> own = [
      gps(0, 0),
      gps(100, 60),
      mark(160, 'GLY::check', seconds: 70), // their own mark, 60 m off-track
      gps(200, 120),
    ];
    final s = RunSummary.compute(ownTrack: own, allPoints: own);
    expect(s.checksOnTrail, 1);
    expect(s.checksReached, 1);
  });
}
