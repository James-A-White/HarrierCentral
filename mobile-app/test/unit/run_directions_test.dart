import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';

/// The run map's directions button (James, 2026-09-26): "Get me there" on the
/// day, "Get Directions" before it, nothing after it, and nothing at all once
/// the run has PackTrack data.
void main() {
  final DateTime run = DateTime(2026, 9, 27, 11, 0);

  RunDirections? at(DateTime now, {bool track = false}) =>
      runDirectionsFor(runStart: run, now: now, hasPackTrack: track);

  test('before the day: Get Directions', () {
    expect(at(DateTime(2026, 9, 20, 9)), RunDirections.getDirections);
    expect(at(DateTime(2026, 9, 26, 23, 59)), RunDirections.getDirections);
  });

  test('the whole day of the run: Get me there', () {
    expect(at(DateTime(2026, 9, 27, 0, 0)), RunDirections.getMeThere);
    expect(at(DateTime(2026, 9, 27, 18, 0)), RunDirections.getMeThere);
    expect(at(DateTime(2026, 9, 27, 23, 59)), RunDirections.getMeThere);
  });

  test('the day after or later: nothing', () {
    expect(at(DateTime(2026, 9, 28, 0, 0)), isNull);
    expect(at(DateTime(2026, 10, 5)), isNull);
  });

  test('PackTrack data hides it on every day', () {
    expect(at(DateTime(2026, 9, 20), track: true), isNull);
    expect(at(DateTime(2026, 9, 27, 12), track: true), isNull);
  });

  test('labels', () {
    expect(RunDirections.getMeThere.label, 'Get me there');
    expect(RunDirections.getDirections.label, 'Get Directions');
  });
}
