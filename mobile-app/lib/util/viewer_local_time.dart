import 'package:intl/intl.dart';

/// Companion label for a run start time when the viewer's clock differs from
/// the kennel's — e.g. a Tokyo run shown as "7:00 PM" gets "12:00 PM your
/// time" underneath for a viewer in London.
///
/// [kennelWall] is the kennel wall-clock start (`EventStartDatetime` — its
/// printed components ARE the kennel time, whatever zone flag the parse left
/// on it). [gmt] is the true instant (`EventStartDatetimeGmt`), converted to
/// the device zone for the comparison.
///
/// Returns null when the two wall-clocks agree to the minute — the normal
/// case of a viewer standing in the kennel's timezone — so callers can use
/// a collection-if and render nothing extra.
String? viewerLocalStartLabel(DateTime kennelWall, DateTime gmt) {
  final DateTime viewer = gmt.toLocal();
  final bool sameMinute =
      viewer.year == kennelWall.year &&
      viewer.month == kennelWall.month &&
      viewer.day == kennelWall.day &&
      viewer.hour == kennelWall.hour &&
      viewer.minute == kennelWall.minute;
  if (sameMinute) return null;
  final bool sameDate =
      viewer.year == kennelWall.year &&
      viewer.month == kennelWall.month &&
      viewer.day == kennelWall.day;
  // Include the weekday when the conversion crosses a date line so
  // "Sat 4:45 AM your time" can't be misread as the same day.
  final DateFormat fmt =
      sameDate ? DateFormat('h:mm a') : DateFormat('EEE h:mm a');
  return '${fmt.format(viewer)} your time';
}

/// Suffix for the kennel-local time itself (" BST", " JST", " UTC+5:30") —
/// empty when the viewer is on kennel time, so the normal case stays clean.
/// Pairs with [viewerLocalStartLabel]: primary line "7:00 PM JST", secondary
/// "12:00 PM your time".
///
/// The abbreviation comes from a curated IANA table, validated against the
/// run's ACTUAL offset (kennel wall-clock minus GMT instant) — if the map
/// entry doesn't contain that offset (wrong/defaulted [iana], rare zone, DST
/// edge), it falls back to the always-true "UTC±X" form rather than risk
/// labelling a Tokyo run "BST".
String kennelTzSuffix(DateTime kennelWall, DateTime gmt, String? iana) {
  if (viewerLocalStartLabel(kennelWall, gmt) == null) return '';
  final DateTime wallUtc = DateTime.utc(
    kennelWall.year,
    kennelWall.month,
    kennelWall.day,
    kennelWall.hour,
    kennelWall.minute,
  );
  final DateTime instant = gmt.isUtc
      ? gmt
      : DateTime.utc(gmt.year, gmt.month, gmt.day, gmt.hour, gmt.minute);
  final int offsetMin = wallUtc.difference(instant).inMinutes;

  final String? abbr = _ianaAbbrs[iana]?[offsetMin];
  if (abbr != null) return ' $abbr';

  final String sign = offsetMin < 0 ? '-' : '+';
  final int absMin = offsetMin.abs();
  final int h = absMin ~/ 60, m = absMin % 60;
  return m == 0 ? ' UTC$sign$h' : ' UTC$sign$h:${m.toString().padLeft(2, '0')}';
}

// Shared zone families (offset-minutes → abbreviation, std + DST variants).
const Map<int, String> _gmtBst = {0: 'GMT', 60: 'BST'};
const Map<int, String> _cet = {60: 'CET', 120: 'CEST'};
const Map<int, String> _eet = {120: 'EET', 180: 'EEST'};
const Map<int, String> _usEastern = {-300: 'EST', -240: 'EDT'};
const Map<int, String> _usCentral = {-360: 'CST', -300: 'CDT'};
const Map<int, String> _usMountain = {-420: 'MST', -360: 'MDT'};
const Map<int, String> _usPacific = {-480: 'PST', -420: 'PDT'};
const Map<int, String> _ausEast = {600: 'AEST', 660: 'AEDT'};
const Map<int, String> _ict = {420: 'ICT'};

/// Curated IANA → per-offset abbreviations for zones where hash kennels
/// actually live. Anything absent (or offset-mismatched) renders as UTC±X —
/// correct, just less pretty. Extend freely; never guess an entry.
const Map<String, Map<int, String>> _ianaAbbrs = {
  'Europe/London': _gmtBst,
  'Europe/Dublin': {0: 'GMT', 60: 'IST'},
  'Europe/Lisbon': {0: 'WET', 60: 'WEST'},
  'Europe/Paris': _cet,
  'Europe/Berlin': _cet,
  'Europe/Madrid': _cet,
  'Europe/Rome': _cet,
  'Europe/Amsterdam': _cet,
  'Europe/Brussels': _cet,
  'Europe/Vienna': _cet,
  'Europe/Zurich': _cet,
  'Europe/Prague': _cet,
  'Europe/Warsaw': _cet,
  'Europe/Budapest': _cet,
  'Europe/Stockholm': _cet,
  'Europe/Oslo': _cet,
  'Europe/Copenhagen': _cet,
  'Europe/Athens': _eet,
  'Europe/Helsinki': _eet,
  'Europe/Bucharest': _eet,
  'Europe/Kyiv': _eet,
  'Europe/Istanbul': {180: 'TRT'},
  'Europe/Moscow': {180: 'MSK'},
  'Africa/Cairo': _eet,
  'Africa/Johannesburg': {120: 'SAST'},
  'Africa/Nairobi': {180: 'EAT'},
  'Africa/Lagos': {60: 'WAT'},
  'Asia/Dubai': {240: 'GST'},
  'Asia/Riyadh': {180: 'AST'},
  'Asia/Kolkata': {330: 'IST'},
  'Asia/Kathmandu': {345: 'NPT'},
  'Asia/Dhaka': {360: 'BST'},
  'Asia/Bangkok': _ict,
  'Asia/Ho_Chi_Minh': _ict,
  'Asia/Phnom_Penh': _ict,
  'Asia/Vientiane': _ict,
  'Asia/Jakarta': {420: 'WIB'},
  'Asia/Singapore': {480: 'SGT'},
  'Asia/Kuala_Lumpur': {480: 'MYT'},
  'Asia/Manila': {480: 'PHT'},
  'Asia/Hong_Kong': {480: 'HKT'},
  'Asia/Shanghai': {480: 'CST'},
  'Asia/Taipei': {480: 'CST'},
  'Asia/Tokyo': {540: 'JST'},
  'Asia/Seoul': {540: 'KST'},
  'Australia/Perth': {480: 'AWST'},
  'Australia/Darwin': {570: 'ACST'},
  'Australia/Adelaide': {570: 'ACST', 630: 'ACDT'},
  'Australia/Brisbane': {600: 'AEST'},
  'Australia/Sydney': _ausEast,
  'Australia/Melbourne': _ausEast,
  'Australia/Hobart': _ausEast,
  'Pacific/Auckland': {720: 'NZST', 780: 'NZDT'},
  'America/St_Johns': {-210: 'NST', -150: 'NDT'},
  'America/Halifax': {-240: 'AST', -180: 'ADT'},
  'America/New_York': _usEastern,
  'America/Toronto': _usEastern,
  'America/Chicago': _usCentral,
  'America/Mexico_City': {-360: 'CST'},
  'America/Denver': _usMountain,
  'America/Phoenix': {-420: 'MST'},
  'America/Los_Angeles': _usPacific,
  'America/Vancouver': _usPacific,
  'America/Anchorage': {-540: 'AKST', -480: 'AKDT'},
  'Pacific/Honolulu': {-600: 'HST'},
  'America/Sao_Paulo': {-180: 'BRT'},
  'America/Argentina/Buenos_Aires': {-180: 'ART'},
  'America/Santiago': {-240: 'CLT', -180: 'CLST'},
  'America/Bogota': {-300: 'COT'},
  'America/Lima': {-300: 'PET'},
};
