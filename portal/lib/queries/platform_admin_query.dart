import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hcportal/imports.dart';

// ---------------------------------------------------------------------------
// Minting and de-minting platform admins (E12.F7.S1). Both SPs require
// HC.PlatformAdmin.CanManagePermissions; a refusal shows the SP's message in
// the standard alert (ServiceCommon), so these return null / false on failure.
// ---------------------------------------------------------------------------

String _deviceId() => box.get(HIVE_DEVICE_ID) as String;
String _deviceSecret() => (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';

String _token(String procName) => Utilities.generateToken(
  _deviceId(),
  procName,
  paramString: _deviceSecret(),
);

List<dynamic>? _rowsets(ApiResult result, String queryType) {
  if (kDebugMode) {
    debugPrint(
      'SP [$queryType] — ${result is ApiSuccess ? 'success' : 'FAILED'}',
    );
  }
  if (result is! ApiSuccess) return null;
  try {
    return json.decode(result.body) as List<dynamic>;
  } on Exception catch (e) {
    if (kDebugMode) debugPrint('$queryType parse error: $e');
    return null;
  }
}

/// The four things an HC.PlatformAdmin row can grant, in the table's order.
enum PlatformCapability {
  viewMonitor('canViewMonitor', 'CanViewMonitor', 'Monitor'),
  manageNewsflash('canManageNewsflash', 'CanManageNewsflash', 'Newsflash'),
  editKennel('canEditKennel', 'CanEditKennel', 'Kennels & merges'),
  managePermissions(
    'canManagePermissions',
    'CanManagePermissions',
    'Permissions & admins',
  );

  const PlatformCapability(this.param, this.column, this.label);
  final String param;
  final String column;
  final String label;
}

/// One platform admin, as hcportal_getPlatformAdmins lists them.
class PlatformAdmin {
  const PlatformAdmin(this.row);
  final Map<String, dynamic> row;

  String get id => ((row['HasherId'] as String?) ?? '').toLowerCase();
  String get hashName => ((row['HashName'] as String?) ?? '').trim();
  String get name =>
      '${row['FirstName'] ?? ''} ${row['LastName'] ?? ''}'.trim();
  String get email => (row['Email'] as String?) ?? '';
  String get homeKennel => (row['HomeKennel'] as String?) ?? '';
  String get display =>
      hashName.isNotEmpty ? hashName : (name.isNotEmpty ? name : email);
  bool get isSelf => (row['IsSelf'] as num?)?.toInt() == 1;
  bool has(PlatformCapability c) => (row[c.column] as num?)?.toInt() == 1;
  DateTime? get since => DateTime.tryParse(row['CreatedAt']?.toString() ?? '');
}

/// Every live platform admin. Null on failure (the alert shows why).
Future<List<PlatformAdmin>?> getPlatformAdmins() async {
  final rowsets = _rowsets(
    await ServiceCommon.sendHttpPostToHC6Api(<String, String?>{
      'queryType': 'getPlatformAdmins',
      'deviceId': _deviceId(),
      'accessToken': _token('hcportal_getPlatformAdmins'),
    }),
    'getPlatformAdmins',
  );
  if (rowsets == null || rowsets.isEmpty) return null;
  final rows = (rowsets[0] as List<dynamic>).cast<Map<String, dynamic>>();
  if (rows.length == 1 && rows[0].containsKey('Success')) return null;
  return rows.map(PlatformAdmin.new).toList();
}

/// Mints, changes or de-mints [hasherId]. [capabilities] names the flags to
/// write (absent = keep; a NEW admin's absent flags are 0); [removed] = true
/// de-mints. True on success.
Future<bool> setPlatformAdmin(
  String hasherId, {
  Map<PlatformCapability, bool> capabilities = const {},
  bool removed = false,
}) async {
  final rowsets = _rowsets(
    await ServiceCommon.sendHttpPostToHC6Api(<String, String?>{
      'queryType': 'setPlatformAdmin',
      'deviceId': _deviceId(),
      'accessToken': _token('hcportal_setPlatformAdmin'),
      'targetHasherId': hasherId,
      'removed': removed ? '1' : '0',
      for (final e in capabilities.entries) e.key.param: e.value ? '1' : '0',
    }),
    'setPlatformAdmin',
  );
  if (rowsets == null || rowsets.isEmpty) return false;
  final envelope = (rowsets[0] as List<dynamic>).cast<Map<String, dynamic>>();
  return envelope.isNotEmpty && (envelope[0]['Success'] as num?)?.toInt() == 1;
}
