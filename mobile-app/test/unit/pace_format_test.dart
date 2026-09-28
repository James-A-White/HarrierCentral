import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/util/distance_format.dart';

void main() {
  // Opee at Black Death 200 (2026-09-27): 1:49:58 less 49 min of drink stops
  // is 1:00:58 of running over 8.5 km.
  const Duration running = Duration(hours: 1, seconds: 58);

  test('pace per km', () {
    expect(formatPace(running, 8500, imperial: false), '7:10 /km');
  });

  test('pace per mile', () {
    expect(formatPace(running, 8500, imperial: true), '11:33 /mi');
  });

  test('rounding carries into the minute, never ":60"', () {
    expect(formatPace(const Duration(milliseconds: 359600), 1000, imperial: false), '6:00 /km');
  });

  test('too little to go on gives no pace', () {
    expect(formatPace(running, 99, imperial: false), isNull);
    expect(formatPace(Duration.zero, 8500, imperial: false), isNull);
  });
}
