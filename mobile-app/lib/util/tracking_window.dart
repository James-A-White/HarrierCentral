import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

/// When run tracking may be started, in one place.
///
/// The two entry points used to disagree wildly. The live-run page opened
/// tracking 5 minutes before the start; the "Track my run" button on the Run
/// Details map tab opened it **fifteen hours** before. On 2026-09-01 a runner
/// began a track 40 minutes before an event started and appeared on the map
/// for a run that had not begun — the map-tab button had been live since
/// 03:00 that morning.
///
/// Keep both entry points on these helpers so the rule cannot drift again.

/// How long before a run's start tracking becomes available.
const Duration kTrackingOpensBefore = Duration(minutes: 5);

/// How long after the start the map-tab button stops being offered.
///
/// Only the map tab enforces a close. The live-run page deliberately does not:
/// a runner who stopped tracking mid-run must still be able to resume and
/// continue their existing track afterwards.
const Duration kTrackingClosesAfter = Duration(hours: 6);

/// True once tracking may be started for an event starting at [eventStartGmt].
bool trackingHasOpened(DateTime eventStartGmt, {DateTime? asOf}) =>
    (asOf ?? DateTime.now()).toUtc().isAfter(
      eventStartGmt.toUtc().subtract(kTrackingOpensBefore),
    );

/// True once the map tab should stop offering to start tracking.
bool trackingHasClosed(DateTime eventStartGmt, {DateTime? asOf}) =>
    (asOf ?? DateTime.now()).toUtc().isAfter(
      eventStartGmt.toUtc().add(kTrackingClosesAfter),
    );

/// Local-time label for when tracking opens, e.g. `6:55 PM`.
String trackingOpensAtLabel(DateTime eventStartGmt) => DateFormat('h:mm a')
    .format(eventStartGmt.toLocal().subtract(kTrackingOpensBefore));
