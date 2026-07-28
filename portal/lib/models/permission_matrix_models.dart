// Plain Dart models — no Freezed required.
// Rows returned by hcportal_getPermissionMatrix (Permissions V2 editor).

/// Surface bitmask values (HC.PermissionFunction.Surfaces).
const int kSurfaceApp = 1;
const int kSurfacePortal = 2;

/// The legacy explicit entry-gate functions. Entry is now DERIVED (a doorway shows
/// iff the grantor holds >=1 capability in the area), so these are filtered out of
/// the editor. They are removed from the DB in the final cutover; until then the SP
/// still returns them and we drop them here.
const Set<String> kEntryGateKeys = {'enterRunAdmin', 'enterKennelAdmin'};

/// A gate-able function (a matrix column).
class PermissionFunction {
  const PermissionFunction({
    required this.id,
    required this.functionKey,
    required this.displayName,
    required this.featureArea,
    required this.areaKey,
    required this.surfaces,
    required this.hareScoped,
    required this.sortOrder,
  });

  factory PermissionFunction.fromJson(Map<String, dynamic> json) =>
      PermissionFunction(
        id: (json['id'] as num?)?.toInt() ?? 0,
        functionKey: (json['FunctionKey'] as String?) ?? '',
        displayName: (json['DisplayName'] as String?) ?? '',
        featureArea: (json['FeatureArea'] as String?) ?? '',
        areaKey: (json['AreaKey'] as String?) ?? '',
        surfaces: (json['Surfaces'] as num?)?.toInt() ?? (kSurfaceApp | kSurfacePortal),
        hareScoped: json['HareScoped'] == true || json['HareScoped'] == 1,
        sortOrder: (json['SortOrder'] as num?)?.toInt() ?? 0,
      );

  final int id;
  final String functionKey;
  final String displayName;
  final String featureArea;
  final String areaKey;
  final int surfaces;
  final bool hareScoped;
  final int sortOrder;

  bool get isEntryGate => kEntryGateKeys.contains(functionKey);
  bool onSurface(int surface) => (surfaces & surface) != 0;
}

/// A grantor (a matrix row): a mismanagement role or an app-access flag.
class PermissionGrantor {
  const PermissionGrantor({
    required this.id,
    required this.grantorKey,
    required this.displayName,
    required this.grantorType,
    required this.sortOrder,
  });

  factory PermissionGrantor.fromJson(Map<String, dynamic> json) =>
      PermissionGrantor(
        id: (json['id'] as num?)?.toInt() ?? 0,
        grantorKey: (json['GrantorKey'] as String?) ?? '',
        displayName: (json['DisplayName'] as String?) ?? '',
        grantorType: (json['GrantorType'] as String?) ?? '',
        sortOrder: (json['SortOrder'] as num?)?.toInt() ?? 0,
      );

  final int id;
  final String grantorKey;
  final String displayName;
  final String grantorType; // 'mmRole' | 'appFlag' | 'hare'

  /// Human grouping for the dropdown.
  String get typeLabel => switch (grantorType) {
        'appFlag' => 'App-access flag',
        'hare' => 'Run hare',
        _ => 'Mismanagement role',
      };

  final int sortOrder;
}

/// The full matrix payload: catalogs, the set of current global grants (keyed as
/// "grantorId:functionId"), and — when a kennel scope was requested — that
/// kennel's override rows (same key → Allowed: 1 grant / -1 revoke).
class PermissionMatrixData {
  const PermissionMatrixData({
    required this.functions,
    required this.grantors,
    required this.grants,
    this.kennelOverrides = const <String, int>{},
  });

  final List<PermissionFunction> functions;
  final List<PermissionGrantor> grantors;
  final Set<String> grants;
  final Map<String, int> kennelOverrides;

  bool isGranted(int grantorId, int functionId) =>
      grants.contains('$grantorId:$functionId');

  /// Kennel override for a cell: 1 (grant), -1 (revoke), or null (inherit global).
  int? overrideFor(int grantorId, int functionId) =>
      kennelOverrides['$grantorId:$functionId'];

  /// Real capabilities only — the legacy entry-gate rows are dropped (entry is derived).
  List<PermissionFunction> get capabilities =>
      functions.where((f) => !f.isEntryGate).toList();

  /// Distinct area keys in display order, with their display label (from FeatureArea).
  List<({String key, String label})> get areas {
    final seen = <String>{};
    final out = <({String key, String label})>[];
    for (final f in capabilities) {
      if (f.areaKey.isEmpty || !seen.add(f.areaKey)) continue;
      out.add((key: f.areaKey, label: f.featureArea));
    }
    return out;
  }

  /// Effective grant of a cell for a kennel scope: override wins (1 grant / -1
  /// revoke), else the global default. In the GLOBAL editor pass an empty override
  /// map so this is just the global grant.
  bool effectiveGrant(int grantorId, int functionId) {
    final ov = overrideFor(grantorId, functionId);
    if (ov == 1) return true;
    if (ov == -1) return false;
    return isGranted(grantorId, functionId);
  }

  /// DERIVED entry: does this grantor hold >=1 capability in [areaKey] on [surface]?
  /// Uses effective grants, so it reflects per-kennel overrides in the kennel editor.
  bool entersArea(int grantorId, String areaKey, int surface) => capabilities.any(
      (f) =>
          f.areaKey == areaKey &&
          f.onSurface(surface) &&
          effectiveGrant(grantorId, f.id));
}
