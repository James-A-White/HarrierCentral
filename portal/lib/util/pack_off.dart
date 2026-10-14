// Pack-off time (E3.F1.S6).
//
// Many kennels gather at one time and set off at another ("gather 12:00, pack
// off 12:30"). The server stores pack-off as MINUTES AFTER THE GATHER, on the
// kennel (default) and on the run (override); null = at the gather. Storing
// minutes rather than a clock time means moving a run's start time moves its
// pack-off with it.

import 'package:intl/intl.dart';

/// Largest pack-off the stored procedures accept, in minutes (10 hours).
const int kMaxPackOffMinutes = 600;

/// The pack-off clock time for a run starting at [start], or null when the
/// pack sets off at the gather ([minutes] null or 0).
DateTime? packOffTime(DateTime start, int? minutes) {
  if (minutes == null || minutes <= 0) return null;
  return start.add(Duration(minutes: minutes));
}

/// " · Pack off 12:30 PM" to follow a run's start time, or '' when the pack
/// sets off at the gather. Same clock format as the portal's run times.
String packOffSuffix(DateTime start, int? minutes) {
  final t = packOffTime(start, minutes);
  return t == null ? '' : ' · Pack off ${DateFormat('h:mm a').format(t)}';
}

/// "at the gather" / "30 min after the gather".
String packOffMinutesLabel(int? minutes) {
  if (minutes == null || minutes <= 0) return 'at the gather';
  return '$minutes min after the gather';
}
