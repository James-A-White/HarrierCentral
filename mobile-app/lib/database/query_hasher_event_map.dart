import 'package:harrier_central/imports.dart';

/// Local reads of the hasher's own attendance rows (common domain — the
/// complete cross-kennel history; never the kennel_/event_ tables).
class QueryHasherEventMap {
  /// The signed-in hasher's row on [eventId], or null when they have none.
  static Future<Map<String, dynamic>?> queryOwnRow(String eventId) async {
    final String userId = currentUserId;
    if (userId.isEmpty) return null;
    final h = tableModel.hasherEventMapTableHelper;
    final List<Map<String, dynamic>> rows = await database.rawQuery(
      '''
      SELECT * FROM ${EnumDataTables.hasherEventMap.commonTableName}
       WHERE ${h.colEventId} = ? AND ${h.colUserId} = ? AND ${h.colRemoved} = 0
       ORDER BY ${h.colAttendenceState} DESC
       LIMIT 1
      ''',
      <Object?>[normalizeUuid(eventId), userId],
    );
    return rows.isEmpty ? null : rows.first;
  }
}
