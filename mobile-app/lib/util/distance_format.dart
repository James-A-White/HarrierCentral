import 'package:intl/intl.dart';

/// The one way the app writes a distance (James, 2026-09-27).
///
/// Metric: under 1 km whole metres ("350 m"); from 1 km one decimal
/// ("2.4 km"); from 100 km whole, grouped ("5,369 km").
/// Imperial: under 1 mile whole yards ("440 yd"); from 1 mile one decimal
/// ("1.6 mi"); from 100 mi whole, grouped ("5,369 mi").
///
/// Which one a viewer gets is [Utilities.prefersImperial]'s decision — the
/// hasher's own choice, else the kennel's, else the phone's locale. Every
/// screen that shows a distance calls this; a local `toStringAsFixed` next to
/// a hard-coded "km" is how the app ended up with metres, "0.25 miles",
/// "(in km)" and "3.19 mi / 5.13 km" on different screens. Pure; tested.
String formatDistance(double meters, {required bool imperial}) {
  final double m = meters.isFinite && meters > 0 ? meters : 0;
  if (imperial) {
    if (m < _metersPerMile) return '${_whole.format(m * _yardsPerMeter)} yd';
    return _large(m / _metersPerMile, 'mi');
  }
  if (m < 1000) return '${_whole.format(m)} m';
  return _large(m / 1000, 'km');
}

String _large(double value, String unit) {
  // Round first, so 99.96 reads "100 km", not "100.0 km".
  final double rounded = double.parse(value.toStringAsFixed(1));
  return rounded >= 100
      ? '${_whole.format(rounded)} $unit'
      : '${rounded.toStringAsFixed(1)} $unit';
}

const double _metersPerMile = 1609.344;
const double _yardsPerMeter = 1.0936133;
final NumberFormat _whole = NumberFormat('#,##0');
