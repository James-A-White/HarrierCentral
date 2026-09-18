/// Reading a stored procedure's reply without assuming it arrived.
///
/// Every write SP hands the app a list of "adHoc" rows alongside the sync
/// data — the new id, the server's message, the reconciled state. The list is
/// almost always exactly one row, so the obvious way to read it is
/// `adHocData[0]['serverMessage']`.
///
/// That is wrong often enough to matter. The list is EMPTY whenever the call
/// did not really happen: a dropped socket, a 30-second local timeout, an
/// error envelope instead of data, a sync-only reply. Indexing it then throws
/// `RangeError (length): Invalid value: Valid value range is empty: 0`, and
/// because these reads sit after an `await` inside a callback, the throw takes
/// the rest of the callback with it — the refresh never runs, the spinner is
/// never cleared, and the hasher sees a tap that did nothing rather than an
/// error they could act on.
///
/// That exact fault was found and fixed three separate times in three separate
/// files (run tabs 2026-09-05, run list, check-in 2026-09-17) before anyone
/// looked for the fourth. [firstRow] exists so there is one safe way to do it
/// rather than four hand-written guards and a fifth site that forgot.
///
/// Use it instead of `[0]`:
/// ```dart
/// final row = firstRow(adHocData);
/// if (row == null) {
///   showHcSnackbar("Couldn't save — please try again.", isError: true);
///   return;
/// }
/// final int rsvp = row['rsvpState'];
/// ```
/// or, where an absent row simply means "nothing to say":
/// ```dart
/// final String serverMessage = firstRow(adHocData)?['serverMessage'] ?? '';
/// ```
///
/// There should be NO `adHocData[` left in the app. If a grep finds one, it is
/// a new unguarded read, not a survivor.
library;

/// The first row of an SP reply, or null when there is not one.
///
/// Null covers both an empty list and a reply whose first element is not a row
/// at all, because a malformed reply should degrade the same way a missing one
/// does rather than throw a cast error.
Map<String, dynamic>? firstRow(List<dynamic>? rows) {
  if (rows == null || rows.isEmpty) return null;
  final Object? first = rows.first;
  return first is Map<String, dynamic> ? first : null;
}
