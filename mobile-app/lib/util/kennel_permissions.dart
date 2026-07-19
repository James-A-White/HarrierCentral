import 'package:harrier_central/util/constants.dart';

/// App-side mirror of the server authorizer `HC6.CheckKennelPermission`.
///
/// Each feature carries the SAME (mmMask, flagMask) as the SP header table —
/// keep the two in sync, and keep both in sync with `docs/permissions_matrix.xlsx`.
/// See the `/hc-authorizations` skill.
///
/// `hareScoped` features are additionally granted to the designated hare of the
/// specific run (the SP checks HasherEventMap.IsHare for that event).
enum KennelFeature {
  viewPaymentReport(0x0004040E, authCanManageHashCash, false),
  takePayment(0x0004040E, authCanManageHashCash, true),
  bulkPayment(0x0004040E, authCanManageHashCash, false),
  manageReceipts(0x0004841E, authCanManageHashCash, true),
  createEditRuns(0x00080346, authCanManageRuns, true),
  printQrCodes(0x00080306, authCanManageRuns, true),
  manageAttendance(0x0008014E, authCanManageRuns, true),
  copyRsvps(0x00080146, authCanManageRuns, false),
  packTrackTrim(0x00000106, authCanManageRuns, false),
  awardList(0x0000001E, authCanManageAwards, false),
  manageDownDowns(0x0000001E, authCanManageAwards, false),
  manageMembers(0x00000046, authCanManageMembers, false),
  viewInviteCodes(0x00000046, authCanManageMembers, false),
  // super-admin only
  assignAppAccessFlags(0x00000000, 0, false),
  // GM|VGM + super-admin
  assignMismanagementRoles(0x00000006, 0, false),
  reviewPhotos(0x0000002E, authCanManagePhotos, false),
  editPhoto(0x0000002E, authCanManagePhotos, false),
  batchPhotos(0x0000102E, authCanManagePhotos, false),
  writeHashTrash(0x00121806, authCanManagePublicWebContent, false),
  viewHashTrashDrafts(0x00121806, authCanManagePublicWebContent, false),
  manageKennelSettings(0x00000006, authCanManageKennel, false),
  manageSongs(0x00000086, authCanManageSongs, false);

  const KennelFeature(this.mmMask, this.flagMask, this.hareScoped);

  /// MismanagementRoles bits whose holders get this feature by default.
  final int mmMask;

  /// The AppAccessFlags override bit for this feature (per-hasher grant).
  final int flagMask;

  /// True when a run's designated hare also gets this feature for that run.
  final bool hareScoped;
}

/// Mirrors `HC6.CheckKennelPermission`: allow when the caller is **SuperAdmin**,
/// OR holds a mismanagement **role** in the feature mask, OR holds the feature's
/// **flag**. `IsAdmin` (0x01) is deliberately NOT a bypass — it is an auto-derived
/// UI umbrella; folding it in would let one narrow grant unlock everything.
///
/// [isHareOfEvent] lets a run's hare access [KennelFeature.hareScoped] features
/// for that run.
bool canAccessFeature(
  KennelFeature feature, {
  required int appAccessFlags,
  required int mismanagementRoles,
  bool isHareOfEvent = false,
}) {
  if ((appAccessFlags & authIsSuperAdmin) != 0) return true;
  if ((mismanagementRoles & feature.mmMask) != 0) return true;
  if ((appAccessFlags & feature.flagMask) != 0) return true;
  if (feature.hareScoped && isHareOfEvent) return true;
  return false;
}
