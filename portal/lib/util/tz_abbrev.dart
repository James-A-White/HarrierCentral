import 'package:timezone/timezone.dart' as tz;

/// Standard + daylight abbreviations for an IANA zone, e.g. ('EST','EDT') for
/// `America/New_York`, ('GMT','BST') for `Europe/London`. For a zone without
/// DST, [std] and [dst] are equal. Returns null if the zone is empty/unknown.
///
/// Requires `initializeTimeZones()` to have run (done once in main()).
/// Standard = the abbreviation during the smaller-offset (non-DST) period, so
/// the std/dst pairing is correct in both hemispheres.
({String std, String dst})? zoneAbbreviations(String iana) {
  if (iana.trim().isEmpty) return null;
  try {
    final loc = tz.getLocation(iana);
    final year = DateTime.now().year;
    final jan = tz.TZDateTime(loc, year, 1, 1);
    final jul = tz.TZDateTime(loc, year, 7, 1);
    final janOff = jan.timeZoneOffset.inMinutes;
    final julOff = jul.timeZoneOffset.inMinutes;
    return (
      std: janOff <= julOff ? jan.timeZoneName : jul.timeZoneName,
      dst: janOff >= julOff ? jan.timeZoneName : jul.timeZoneName,
    );
  } catch (_) {
    return null;
  }
}
