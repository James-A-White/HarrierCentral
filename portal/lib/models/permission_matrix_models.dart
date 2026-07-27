// Plain Dart models — no Freezed required.
// Rows returned by hcportal_getPermissionMatrix (Permissions V2 editor).

/// A gate-able function (a matrix column).
class PermissionFunction {
  const PermissionFunction({
    required this.id,
    required this.functionKey,
    required this.displayName,
    required this.featureArea,
    required this.hareScoped,
    required this.sortOrder,
  });

  factory PermissionFunction.fromJson(Map<String, dynamic> json) =>
      PermissionFunction(
        id: (json['id'] as num?)?.toInt() ?? 0,
        functionKey: (json['FunctionKey'] as String?) ?? '',
        displayName: (json['DisplayName'] as String?) ?? '',
        featureArea: (json['FeatureArea'] as String?) ?? '',
        hareScoped: json['HareScoped'] == true || json['HareScoped'] == 1,
        sortOrder: (json['SortOrder'] as num?)?.toInt() ?? 0,
      );

  final int id;
  final String functionKey;
  final String displayName;
  final String featureArea;
  final bool hareScoped;
  final int sortOrder;
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
  final String grantorType; // 'mmRole' | 'appFlag'

  /// Human grouping for the dropdown.
  String get typeLabel =>
      grantorType == 'appFlag' ? 'App-access flag' : 'Mismanagement role';

  final int sortOrder;
}

/// The full matrix payload: catalogs + the set of current global grants,
/// keyed as "grantorId:functionId".
class PermissionMatrixData {
  const PermissionMatrixData({
    required this.functions,
    required this.grantors,
    required this.grants,
  });

  final List<PermissionFunction> functions;
  final List<PermissionGrantor> grantors;
  final Set<String> grants;

  bool isGranted(int grantorId, int functionId) =>
      grants.contains('$grantorId:$functionId');
}
