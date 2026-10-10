import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';

/// Opens a kennel's page — logo, description, map, upcoming runs, and the
/// admin functions for those who hold them — from nothing but its id. The
/// map's kennel pin and a `hashruns.org/<slug>` link both land here, so the
/// two cannot drift (2026-10-10: the "Open in the Harrier Central app" banner
/// on a kennel page did nothing, because only run links reached the app).
///
/// Anyone may open the page: the admin section and its data sync are gated
/// inside (KennelAdminController._syncAndLoad on isAdmin). Returns false when
/// the kennel is not on this phone (not synced yet) or there is no navigator.
Future<bool> openKennelPage(HcId kennelId) async {
  final bool isHomeKennel =
      normalizeUuid(kennelId) ==
      normalizeUuid(getStringPref(StringPrefsEnum.homeKennelId));

  final List<Map<String, dynamic>> results = await QueryKennels.queryKennels(
    EnumKennelQueryType.singleKennel,
    EnumKennelQueryContext.user,
    hasherId: HcId(currentUserId),
    kennelId: kennelId,
  );
  if (results.isEmpty) return false;

  double? dist;
  if (deviceInfo.deviceLat != null &&
      deviceInfo.deviceLon != null &&
      results[0]['cityLat'] != null &&
      results[0]['cityLon'] != null) {
    dist = Geolocator.distanceBetween(
      deviceInfo.deviceLat!,
      deviceInfo.deviceLon!,
      results[0]['cityLat'],
      results[0]['cityLon'],
    );
  }

  final KennelsModel kennelItem = tableModel.kennelsTableHelper.fromMap(
    results[0],
  );
  HasherKennelMapModel? hkmItem;
  if (results[0]['hkmId'] != null) {
    hkmItem = tableModel.hasherKennelMapTableHelper.fromMap(results[0]);
  }
  final KennelListQueryExtenstions extensionsItem =
      KennelListQueryExtenstions.fromMap(results[0]);
  extensionsItem.distToKennel = dist;
  extensionsItem.followingRequested = -1;
  extensionsItem.notificationsRequested = -1;
  extensionsItem.emailAlertRequested = -1;

  final KennelListAggregate kennelAggregate = KennelListAggregate(
    kennel: kennelItem,
    extensions: extensionsItem,
    hkm: hkmItem,
    isHomeKennel: isHomeKennel,
  );

  if (navigatorKey.currentContext == null) return false;
  await Navigator.of(navigatorKey.currentContext!).push<dynamic>(
    MaterialPageRoute<dynamic>(
      builder: (BuildContext context) =>
          KennelAdminMainPage(kennelAggregateItem: kennelAggregate),
    ),
  );
  return true;
}
