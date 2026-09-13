import 'package:harrier_central/imports.dart';

/// The platform-wide Harrier Central admin channel.
///
/// Audience is SuperAdmin on ANY kennel — 290 people, the narrowest of the
/// three audiences considered. The wider groups (345 who can manage a kennel,
/// 414 holding admin somewhere) make a room too big to be a support channel,
/// and widening later is a one-line change here whereas narrowing it after 400
/// people have been talking is not (James, 2026-09-13).
class AdminChannelService {
  const AdminChannelService();

  /// Whether this hasher may see the channel at all.
  ///
  /// Read from the LOCAL HasherKennelMap, so the support page can decide
  /// without a round trip and still shows correctly offline. The server checks
  /// the same bit independently in hcapp_sendAdminMessage and
  /// hcapp_getAdminMessages — this is the UX gate, never the real one.
  static Future<bool> currentUserMayUse() async {
    final h = tableModel.hasherKennelMapTableHelper;
    final String table = EnumDataTables.hasherKennelMap.commonTableName;
    final String me = normalizeUuid(currentUserId);
    if (me.isEmpty) return false;

    final List<Map<String, dynamic>> rows = await database.rawQuery(
      '''
      SELECT 1 FROM $table
       WHERE ${h.colUserId} = ?
         AND ${h.colRemoved} = 0
         AND (${h.colAppAccessFlags} & ?) <> 0
       LIMIT 1
      ''',
      <Object?>[me, authIsSuperAdmin],
    );
    return rows.isNotEmpty;
  }
}
