import 'package:harrier_central/imports.dart';

/// How long after its start a run stops being "upcoming".
///
/// This is the same six hours the run list uses to decide whether a run belongs
/// in the future section or the past section — see the
/// `julianday(EventStartDatetimeGmt) < julianday('now','-6 hours')` split in
/// `query_runs.dart`. Keep the two in step: a run that has dropped into the
/// past list must look past everywhere else too.
const Duration kRunBecomesPastAfter = Duration(hours: 6);

/// Whether [run] has moved into the past.
///
/// Prefers `showAsPastEvent`, which is that exact rule evaluated in SQL when
/// the list was built, so the app and the database can never disagree about
/// which side of the line a run sits on. Falls back to computing it here when
/// the flag is absent — and also re-checks locally, because the flag is a
/// snapshot from query time and an app left open across the boundary would
/// otherwise keep showing a finished run as upcoming.
///
/// The local comparison uses `eventStartDatetime` (wall clock) against
/// `DateTime.now()` (wall clock), matching how the rest of the widget layer
/// treats this field. Do not mix it with the GMT column: see the event
/// date/time reference — `EventStartDatetime` carries a spurious `+00:00` on
/// most rows, so only compare like with like.
bool isRunPast(RunDetailsAggregate run) {
  if (run.extensions.showAsPastEvent != 0) return true;

  return DateTime.now().isAfter(
    run.event.eventStartDatetime.add(kRunBecomesPastAfter),
  );
}

/// The directions button under the run map (James, 2026-09-26).
enum RunDirections {
  /// The day of the run: the hasher is on their way.
  getMeThere('Get me there'),

  /// Any day before it: they are planning.
  getDirections('Get Directions');

  const RunDirections(this.label);
  final String label;
}

/// Which directions button the run map shows, or null for none.
///
/// - PackTrack data on the run → none: the map is a trail now, not a
///   destination, and the playback panel owns the bottom of it.
/// - The run's day → [RunDirections.getMeThere].
/// - Before it → [RunDirections.getDirections].
/// - The day after or later → none.
///
/// Days are compared on the wall clock: [runStart] is `eventStartDatetime`,
/// synced as `CONVERT(DATETIME2, EventStartDatetime)` — the run's local time
/// with no offset — and [now] is the phone's local time. Like with like, as
/// in [isRunPast].
RunDirections? runDirectionsFor({
  required DateTime runStart,
  required DateTime now,
  required bool hasPackTrack,
}) {
  if (hasPackTrack) return null;
  final DateTime runDay = DateTime(runStart.year, runStart.month, runStart.day);
  final DateTime today = DateTime(now.year, now.month, now.day);
  if (today.isBefore(runDay)) return RunDirections.getDirections;
  if (today == runDay) return RunDirections.getMeThere;
  return null;
}

/// The image a run's card shows (James, 2026-09-26: option B).
///
/// Once the run has STARTED, a cover photo — a photo chosen from the run's
/// own pictures — replaces the run image: the run image advertised the run,
/// the cover shows what happened. Before the start, the run image. A run with
/// neither has no card image. Until 2026-09-26 the cover only stood in for a
/// MISSING run image on a past run, so LH3 #2852 kept its sheep after a cover
/// was chosen.
///
/// Wall clock against wall clock, as [isRunPast]: [runStart] is
/// `eventStartDatetime`, synced without an offset.
String? runCardImage({
  required String? eventImage,
  required String? coverPhotoUrl,
  required DateTime runStart,
  required DateTime now,
}) {
  final bool hasCover = (coverPhotoUrl ?? '').isNotEmpty;
  if (hasCover && !now.isBefore(runStart)) return coverPhotoUrl;
  if ((eventImage ?? '').isNotEmpty) return eventImage;
  return null;
}
