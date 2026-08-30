import 'dart:convert';

import 'package:harrier_central/util/constants.dart';

/// App-side mirror of the server authorizer `HC6.CheckKennelPermission`.
///
/// The gate is data-driven (Permissions V2): the effective `(mmMask, flagMask,
/// hareScoped)` for each feature comes from the server-compiled matrix
/// ([PermissionMatrix]) — the global matrix delivered at login, overlaid with a
/// per-kennel override. The literals on each enum entry below are the built-in
/// **fallback floor**: they equal today's masks and are used whenever the server
/// matrix has not loaded (first launch / offline) or lacks a key, so gating is
/// always safe. Keep them in sync with `docs/permissions_matrix.xlsx`.
/// See the `/hc-authorizations` and permissions-v2 notes.
///
/// `hareScoped` features are additionally granted to the designated hare of the
/// specific run (the SP checks HasherEventMap.IsHare for that event).
/// Stable area slugs (HC.PermissionFunction.AreaKey). A UI "doorway" for an area
/// is DERIVED — shown iff the user holds >=1 capability in it (see [canEnterArea]).
class PermissionArea {
  static const String runAdmin = 'runAdmin';
  static const String kennelTools = 'kennelTools';
  static const String photos = 'photos';
  static const String web = 'web';
  static const String songs = 'songs';
}

enum KennelFeature {
  viewPaymentReport(0x0004040E, authCanManageHashCash, false, PermissionArea.runAdmin),
  takePayment(0x0004040E, authCanManageHashCash, true, PermissionArea.runAdmin),
  bulkPayment(0x0004040E, authCanManageHashCash, false, PermissionArea.runAdmin),
  manageReceipts(0x0004841E, authCanManageHashCash, true, PermissionArea.runAdmin),
  // Adding/editing runs is a KENNEL-admin function (managing the kennel's
  // calendar), not per-run admin. Lives in the kennelTools area.
  createEditRuns(0x00080346, authCanManageRuns, true, PermissionArea.kennelTools),
  printQrCodes(0x00080306, authCanManageRuns, true, PermissionArea.runAdmin),
  manageAttendance(0x0008014E, authCanManageRuns, true, PermissionArea.runAdmin),
  copyRsvps(0x00080146, authCanManageRuns, false, PermissionArea.runAdmin),
  packTrackTrim(0x00000106, authCanManageRuns, false, PermissionArea.runAdmin),
  awardList(0x0000001E, authCanManageAwards, false, PermissionArea.runAdmin),
  manageDownDowns(0x0000001E, authCanManageAwards, false, PermissionArea.runAdmin),
  manageMembers(0x00000046, authCanManageMembers, false, PermissionArea.kennelTools),
  viewInviteCodes(0x00000046, authCanManageMembers, false, PermissionArea.kennelTools),
  // super-admin only
  assignAppAccessFlags(0x00000000, 0, false, PermissionArea.kennelTools),
  // GM|VGM + super-admin
  assignMismanagementRoles(0x00000006, 0, false, PermissionArea.kennelTools),
  // GM | VGM | HashFlash | WebMeister — RA removed 2026-08-30 (James), and the
  // grant flag is now the dedicated Photo Approver rather than Manage Photos.
  // Mirrors the HC.RolePermission rows for 'reviewPhotos'; the old 0x2E here
  // had also drifted from the DB, which already granted WebMeister.
  reviewPhotos(0x00001026, authCanApprovePhotos, false, PermissionArea.photos),
  editPhoto(0x0000002E, authCanManagePhotos, false, PermissionArea.photos),
  batchPhotos(0x0000102E, authCanManagePhotos, false, PermissionArea.photos),
  writeHashTrash(0x00121806, authCanManagePublicWebContent, false, PermissionArea.web),
  viewHashTrashDrafts(0x00121806, authCanManagePublicWebContent, false, PermissionArea.web),
  manageKennelSettings(0x00000006, authCanManageKennel, false, PermissionArea.kennelTools),
  manageSongs(0x00000086, authCanManageSongs, false, PermissionArea.songs);

  const KennelFeature(this.mmMask, this.flagMask, this.hareScoped, this.areaKey);

  /// Fallback MismanagementRoles bits whose holders get this feature by default.
  final int mmMask;

  /// Fallback AppAccessFlags override bit for this feature (per-hasher grant).
  final int flagMask;

  /// True when a run's designated hare also gets this feature for that run.
  final bool hareScoped;

  /// Which derived-entry area this capability belongs to ([PermissionArea]).
  final String areaKey;
}

/// Resolved permission for one feature: which role/flag bits grant it, and
/// whether a run's hare qualifies.
class FeaturePerm {
  const FeaturePerm(this.mmMask, this.flagMask, this.hareScoped);
  final int mmMask;
  final int flagMask;
  final bool hareScoped;
}

/// Holds the server-compiled permission matrix (Permissions V2) and resolves the
/// effective permission for a feature: per-kennel override → global → enum floor.
///
/// The global matrix is set from `HC.ServerStatus.PermissionMatrixJson` (delivered
/// via `hcapp_approveLogin`, persisted locally). A per-kennel override is the
/// synced `HC.Kennel.PermissionOverrideJson`. Both share the compiled shape:
/// `{ "functions": [ { "key", "mmMask", "flagMask", "hareScoped" }, ... ] }`.
class PermissionMatrix {
  PermissionMatrix._();

  static Map<String, FeaturePerm> _global = <String, FeaturePerm>{};
  // Parsed per-kennel overrides, cached by their raw JSON string (few, stable).
  static final Map<String, Map<String, FeaturePerm>> _overrideCache =
      <String, Map<String, FeaturePerm>>{};

  /// Load/replace the global matrix from the server JSON. Null/blank/invalid
  /// clears it, so [effective] falls back to the enum floor.
  static void setGlobalJson(String? json) {
    _global = _parse(json) ?? <String, FeaturePerm>{};
  }

  static bool get hasGlobal => _global.isNotEmpty;

  static Map<String, FeaturePerm>? _parse(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final obj = jsonDecode(json) as Map<String, dynamic>;
      final list = (obj['functions'] as List<dynamic>?) ?? const <dynamic>[];
      final map = <String, FeaturePerm>{};
      for (final dynamic e in list) {
        final m = e as Map<String, dynamic>;
        final key = m['key'] as String?;
        if (key == null) continue;
        map[key] = FeaturePerm(
          (m['mmMask'] as num?)?.toInt() ?? 0,
          (m['flagMask'] as num?)?.toInt() ?? 0,
          ((m['hareScoped'] as num?)?.toInt() ?? 0) != 0,
        );
      }
      return map;
    } catch (_) {
      return null;
    }
  }

  static Map<String, FeaturePerm> _overrideFor(String? overrideJson) {
    if (overrideJson == null || overrideJson.isEmpty) {
      return const <String, FeaturePerm>{};
    }
    return _overrideCache.putIfAbsent(
      overrideJson,
      () => _parse(overrideJson) ?? <String, FeaturePerm>{},
    );
  }

  /// Effective permission for [feature]: per-kennel override, else global, else
  /// the enum floor (so gating is always defined even with no server matrix).
  static FeaturePerm effective(
    KennelFeature feature, {
    String? kennelOverrideJson,
  }) {
    final key = feature.name;
    final override = _overrideFor(kennelOverrideJson);
    final o = override[key];
    if (o != null) return o;
    final g = _global[key];
    if (g != null) return g;
    return FeaturePerm(feature.mmMask, feature.flagMask, feature.hareScoped);
  }
}

/// Mirrors `HC6.CheckKennelPermission`: allow when the caller is **SuperAdmin**,
/// OR holds a mismanagement **role** that grants the feature, OR holds the
/// feature's granting **flag**. `IsAdmin` (0x01) is deliberately NOT a bypass.
///
/// The granting masks come from [PermissionMatrix] (server-driven, with the enum
/// floor). [kennelOverrideJson] is the resolved kennel's
/// `HC.Kennel.PermissionOverrideJson` when a per-kennel override applies.
/// [isHareOfEvent] lets a run's hare access [KennelFeature.hareScoped] features.
bool canAccessFeature(
  KennelFeature feature, {
  required int appAccessFlags,
  required int mismanagementRoles,
  bool isHareOfEvent = false,
  String? kennelOverrideJson,
}) {
  if ((appAccessFlags & authIsSuperAdmin) != 0) return true;
  final perm = PermissionMatrix.effective(
    feature,
    kennelOverrideJson: kennelOverrideJson,
  );
  if ((mismanagementRoles & perm.mmMask) != 0) return true;
  if ((appAccessFlags & perm.flagMask) != 0) return true;
  if (perm.hareScoped && isHareOfEvent) return true;
  return false;
}

/// DERIVED entry — mirrors `HC6.CheckAreaEntry`. A UI doorway for [areaKey]
/// (the Run Admin gear, the Kennel Tools entry, the Photos entry) is shown iff
/// the user can do at least one thing in that area. Never gate a doorway on a
/// standalone "enter…" permission — compute it from the capabilities.
bool canEnterArea(
  String areaKey, {
  required int appAccessFlags,
  required int mismanagementRoles,
  bool isHareOfEvent = false,
  String? kennelOverrideJson,
}) {
  if ((appAccessFlags & authIsSuperAdmin) != 0) return true;
  for (final feature in KennelFeature.values) {
    if (feature.areaKey != areaKey) continue;
    if (canAccessFeature(
      feature,
      appAccessFlags: appAccessFlags,
      mismanagementRoles: mismanagementRoles,
      isHareOfEvent: isHareOfEvent,
      kennelOverrideJson: kennelOverrideJson,
    )) {
      return true;
    }
  }
  return false;
}
