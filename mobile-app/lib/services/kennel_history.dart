import 'package:harrier_central/imports.dart';

/// Getting a kennel's full run history onto the phone. The user sync carries
/// only ten days of the runs of kennels a hasher does not follow, so opening
/// an older run of such a kennel — from a shared link or the kennel trail
/// map — first offers to follow it, then loads its whole history through the
/// same force-replicate path the kennel admin screen uses. One copy, shared
/// by the deep link service and the kennel trail map (2026-10-04).
class KennelHistory {
  const KennelHistory._();

  /// True when this hasher follows [kennelId] (or is a member, which the
  /// user sync treats the same way for run history).
  static Future<bool> isFollowing(String kennelId) async {
    final hkm = tableModel.hasherKennelMapTableHelper;
    final rows = await database.rawQuery(
      'SELECT 1 FROM ${EnumDataTables.hasherKennelMap.commonTableName} '
      'WHERE lower(${hkm.colKennelId}) = ? AND ${hkm.colFollowing} = ? LIMIT 1',
      <Object?>[normalizeUuid(kennelId), followTypeFollow.value],
    );
    return rows.isNotEmpty;
  }

  static Future<bool> offerToFollow(String kennelName) async {
    final BuildContext? ctx = navigatorKey.currentContext;
    if (ctx == null) return false;
    final bool? yes = await showDialog<bool>(
      context: ctx,
      builder: (BuildContext c) => AlertDialog(
        title: Text('Follow $kennelName?'),
        content: Text(
          "This run belongs to $kennelName, which you don't follow yet. "
          'Follow them to open it — their runs will then show in your list.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Not now', textAlign: TextAlign.center),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Follow', textAlign: TextAlign.center),
          ),
        ],
      ),
    );
    return yes == true;
  }

  /// Verbatim the kennel-admin auto-follow: mark followed, clear the stale
  /// ten-day slice of this kennel's events, then force-replicate its full
  /// history so the run is actually there.
  static Future<void> followAndLoad(String kennelId) async {
    await HasherKennelMapService().updateHasherKennelStatus(
      kennelId,
      AppDomainType.user,
      followingState: followTypeFollow.value,
    );
    await database.rawDelete(
      'DELETE FROM ${EnumDataTables.events.commonTableName} '
      'WHERE lower(${tableModel.eventsTableHelper.colKennelId}) = "${normalizeUuid(kennelId)}"',
    );
    await tableModel.syncUserDataService.updateFromBackend(
      EnumDataTables.events.flag,
      true,
      forceReplicateAllRunsForKennel: kennelId,
      debugText:
          'deep_link_service: follow + force-replicate to open a linked run',
    );
  }
}
