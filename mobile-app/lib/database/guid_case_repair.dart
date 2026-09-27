import 'package:harrier_central/imports.dart';

/// One-time repair (James, 2026-09-27): lowercase every GUID the phone's
/// database holds in another case.
///
/// Rows from the API are already lowercase (its JSON writer, and since 1416
/// [lowerGuidsInPlace] at the sync door). What this catches is anything the
/// app wrote itself from an id that came in uppercase — a push payload, an SP
/// column CAST to text — before [HcId] existed. SQLite's `=` is
/// case-sensitive, so such a row is invisible to every lookup.
///
/// Every table, every column whose name ends in "id", only values that are
/// 36 characters and contain an uppercase hex digit: a no-op on a clean
/// database beyond one scan per column. Each UPDATE stands alone so one
/// failure (a UNIQUE clash between two cases of the same id) cannot stop the
/// rest; the pass is marked done either way and never runs again.
Future<void> lowercaseStoredGuidsOnce(Database db) async {
  if (getBoolPref(BoolPrefsEnum.storedGuidsLowercased) == true) return;
  int changed = 0;
  int failed = 0;
  try {
    final List<Map<String, Object?>> tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'",
    );
    for (final Map<String, Object?> t in tables) {
      final String table = t['name']! as String;
      final List<Map<String, Object?>> cols = await db.rawQuery(
        'SELECT name FROM pragma_table_info(?)',
        <Object>[table],
      );
      for (final Map<String, Object?> c in cols) {
        final String col = c['name']! as String;
        if (!col.toLowerCase().endsWith('id')) continue;
        try {
          changed += await db.rawUpdate(
            'UPDATE "$table" SET "$col" = lower("$col") '
            'WHERE length("$col") = 36 AND "$col" GLOB \'*[A-F]*\'',
          );
        } catch (e) {
          failed++;
          BootLogger.logBreadcrumb('[IDS] could not lowercase $table.$col: $e');
        }
      }
    }
  } catch (e, s) {
    BootLogger.logError('[ERROR][IDS]', 'guid case repair failed: $e', s);
  }
  BootLogger.logBreadcrumb(
    '[IDS] stored GUIDs lowercased: $changed row(s) changed, $failed column(s) failed',
  );
  await setBoolPref(BoolPrefsEnum.storedGuidsLowercased, true);
}
