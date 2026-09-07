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
