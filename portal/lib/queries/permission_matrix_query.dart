import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hcportal/imports.dart';

// ---------------------------------------------------------------------------
// Helpers (mirror newsflash_query.dart)
// ---------------------------------------------------------------------------

String _deviceId() => box.get(HIVE_DEVICE_ID) as String;
String _deviceSecret() => (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';

String _token(String procName) =>
    Utilities.generateToken(_deviceId(), procName, paramString: _deviceSecret());

// ---------------------------------------------------------------------------
// Load the permission matrix (super-admin editor)
// ---------------------------------------------------------------------------

/// Loads the function catalog, grantor catalog and current global grants.
/// When [publicKennelId] is supplied, also loads that kennel's overrides.
/// Returns null on any error / not authorised.
Future<PermissionMatrixData?> queryPermissionMatrix({
  String? publicKennelId,
}) async {
  final body = <String, String?>{
    'queryType': 'getPermissionMatrix',
    'deviceId': _deviceId(),
    'accessToken': _token('hcportal_getPermissionMatrix'),
    if (publicKennelId != null) 'publicKennelId': publicKennelId,
  };

  final result = await ServiceCommon.sendHttpPostToHC6Api(body);
  if (kDebugMode) {
    debugPrint(result is ApiError
        ? 'SP [getPermissionMatrix] — FAILED'
        : 'SP [getPermissionMatrix] — success');
  }
  if (result is! ApiSuccess) return null;

  try {
    final decoded = json.decode(result.body) as List<dynamic>;
    final envelope = (decoded[0] as List<dynamic>)[0] as Map<String, dynamic>;
    if ((envelope['Success'] as int?) != 1) return null;

    final functions = (decoded[1] as List<dynamic>)
        .map((r) => PermissionFunction.fromJson(r as Map<String, dynamic>))
        .toList();
    final grantors = (decoded[2] as List<dynamic>)
        .map((r) => PermissionGrantor.fromJson(r as Map<String, dynamic>))
        .toList();
    final grants = <String>{
      for (final dynamic g in decoded[3] as List<dynamic>)
        '${((g as Map<String, dynamic>)['GrantorId'] as num).toInt()}:'
            '${(g['FunctionId'] as num).toInt()}',
    };
    final kennelOverrides = <String, int>{
      if (decoded.length > 4)
        for (final dynamic o in decoded[4] as List<dynamic>)
          '${((o as Map<String, dynamic>)['GrantorId'] as num).toInt()}:'
                  '${(o['FunctionId'] as num).toInt()}':
              (o['Allowed'] as num).toInt(),
    };

    return PermissionMatrixData(
      functions: functions,
      grantors: grantors,
      grants: grants,
      kennelOverrides: kennelOverrides,
    );
  } on Exception catch (e) {
    if (kDebugMode) debugPrint('queryPermissionMatrix parse error: $e');
    return null;
  }
}

// ---------------------------------------------------------------------------
// Save the global grants for one grantor
// ---------------------------------------------------------------------------

/// Saves a grantor's grants. Global scope: pass [functionKeys] (granted set).
/// Kennel scope: pass [publicKennelId] + [grantedKeys] (+1) and [revokedKeys] (-1);
/// functions in neither list inherit the global default.
/// Returns true on success.
Future<bool> savePermissionMatrix({
  required String grantorKey,
  List<String> functionKeys = const [],
  String? publicKennelId,
  List<String> grantedKeys = const [],
  List<String> revokedKeys = const [],
}) async {
  final body = <String, String?>{
    'queryType': 'savePermissionMatrix',
    'deviceId': _deviceId(),
    'accessToken': _token('hcportal_savePermissionMatrix'),
    'grantorKey': grantorKey,
    if (publicKennelId == null) 'functionKeys': functionKeys.join('|'),
    if (publicKennelId != null) ...<String, String?>{
      'publicKennelId': publicKennelId,
      'grantedKeys': grantedKeys.join('|'),
      'revokedKeys': revokedKeys.join('|'),
    },
  };

  final result = await ServiceCommon.sendHttpPostToHC6Api(body);
  if (kDebugMode) {
    debugPrint(result is ApiError
        ? 'SP [savePermissionMatrix] — FAILED'
        : 'SP [savePermissionMatrix] — success');
  }
  if (result is! ApiSuccess) return false;

  try {
    final row = ((json.decode(result.body) as List<dynamic>)[0]
        as List<dynamic>)[0] as Map<String, dynamic>;
    return (row['Success'] as int?) == 1;
  } on Exception catch (e) {
    if (kDebugMode) debugPrint('savePermissionMatrix parse error: $e');
    return false;
  }
}
