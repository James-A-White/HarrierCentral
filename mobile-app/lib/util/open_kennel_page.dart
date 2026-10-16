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
  final KennelListAggregate? kennelAggregate = await kennelAggregateFor(kennelId);
  if (kennelAggregate == null) return false;
  if (navigatorKey.currentContext == null) return false;
  await Navigator.of(navigatorKey.currentContext!).push<dynamic>(
    MaterialPageRoute<dynamic>(
      builder: (BuildContext context) =>
          KennelAdminMainPage(kennelAggregateItem: kennelAggregate),
    ),
  );
  return true;
}

/// The kennel, its row for this hasher and its list extras, as the kennel
/// page takes them — or null when the kennel is not on this phone.
Future<KennelListAggregate?> kennelAggregateFor(HcId kennelId) async {
  final bool isHomeKennel =
      normalizeUuid(kennelId) ==
      normalizeUuid(getStringPref(StringPrefsEnum.homeKennelId));

  final List<Map<String, dynamic>> results = await QueryKennels.queryKennels(
    EnumKennelQueryType.singleKennel,
    EnumKennelQueryContext.user,
    hasherId: HcId(currentUserId),
    kennelId: kennelId,
  );
  if (results.isEmpty) return null;

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

  return KennelListAggregate(
    kennel: kennelItem,
    extensions: extensionsItem,
    hkm: hkmItem,
    isHomeKennel: isHomeKennel,
  );
}

/// `hashruns.org/<slug>/review-photos` — the link in the weekly Mismanagement
/// reminder (E9.F1.S33, James 2026-10-16): the kennel's whole pending-photo
/// queue, the screen the kennel page's Review photos button opens. Only for
/// someone who may review that kennel's photos (the same canAccessFeature
/// rule as the button, and the server's own gate behind it); anyone else —
/// a forwarded link — lands on the kennel page. Returns false when the kennel
/// is not on this phone or there is no navigator.
Future<bool> openKennelPhotoReview(HcId kennelId) async {
  final KennelListAggregate? agg = await kennelAggregateFor(kennelId);
  if (agg == null || navigatorKey.currentContext == null) return false;
  final bool mayReview = canAccessFeature(
    KennelFeature.reviewPhotos,
    appAccessFlags: agg.hkm?.appAccessFlags ?? 0,
    mismanagementRoles: agg.hkm?.mismanagementRoles ?? 0,
    kennelOverrideJson: agg.kennel.permissionOverrideJson,
  );
  if (!mayReview) return openKennelPage(kennelId);
  await Navigator.of(navigatorKey.currentContext!).push<dynamic>(
    MaterialPageRoute<dynamic>(
      builder: (BuildContext context) => PhotoReviewPage(
        kennelId: agg.kennel.kennelId,
        eventId: '',
        eventName: agg.kennel.kennelShortName,
        eventNumber: null,
        kennelSlug: agg.kennel.kennelUniqueShortName,
        kennelLogoUrl: agg.kennel.kennelLogo,
        kennelShortName: agg.kennel.kennelShortName,
      ),
    ),
  );
  return true;
}
