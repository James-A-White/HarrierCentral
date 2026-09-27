import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/util/distance_format.dart';

/// Distance display rule (James, 2026-09-27): metres under 1 km, decimal km
/// above; yards under 1 mile, decimal miles above.
void main() {
  group('metric', () {
    String f(double m) => formatDistance(m, imperial: false);
    test('under 1 km: whole metres', () {
      expect(f(0), '0 m');
      expect(f(350.4), '350 m');
      expect(f(999.4), '999 m');
    });
    test('from 1 km: one decimal', () {
      expect(f(1000), '1.0 km');
      expect(f(2449), '2.4 km');
      expect(f(99940), '99.9 km');
    });
    test('from 100 km: whole, grouped', () {
      expect(f(99960), '100 km');
      expect(f(5369000), '5,369 km');
    });
  });

  group('imperial', () {
    String f(double m) => formatDistance(m, imperial: true);
    test('under 1 mile: whole yards', () {
      expect(f(402.336), '440 yd');
      expect(f(1609.0), '1,760 yd');
    });
    test('from 1 mile: one decimal', () {
      expect(f(1609.344), '1.0 mi');
      expect(f(2574.95), '1.6 mi');
    });
    test('from 100 mi: whole, grouped', () {
      expect(f(8640000), '5,369 mi');
    });
  });

  test('nonsense input reads as zero', () {
    expect(formatDistance(-5, imperial: false), '0 m');
    expect(formatDistance(double.nan, imperial: true), '0 yd');
  });
}
