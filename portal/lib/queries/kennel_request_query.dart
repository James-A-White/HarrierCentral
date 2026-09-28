import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hcportal/imports.dart';

// ---------------------------------------------------------------------------
// Kennel requests (E12.F1.S5–S6) — the review queue for kennels asking to
// join, from hashruns.org/add-kennel and the old forms before it. Every SP
// requires HC.PlatformAdmin.CanEditKennel. A refused call shows the SP's
// message in the standard alert (ServiceCommon), so these return a plain
// success flag.
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
    debugPrint('SP [$queryType] — ${result is ApiSuccess ? 'success' : 'FAILED'}');
  }
  if (result is! ApiSuccess) return null;
  try {
    return json.decode(result.body) as List<dynamic>;
  } on Exception catch (e) {
    if (kDebugMode) debugPrint('$queryType parse error: $e');
    return null;
  }
}

bool _succeeded(List<dynamic>? rowsets) {
  if (rowsets == null || rowsets.isEmpty) return false;
  final rows = rowsets[0] as List<dynamic>;
  if (rows.isEmpty) return false;
  return ((rows[0] as Map<String, dynamic>)['Success'] as num?)?.toInt() == 1;
}

/// The requests with one status, plus the count for every status.
class KennelRequestPage {
  const KennelRequestPage(this.requests, this.counts);
  final List<KennelRequestModel> requests;
  final Map<int, int> counts;
}

Future<KennelRequestPage?> queryKennelRequests(int status) async {
  final rowsets = _rowsets(
    await ServiceCommon.sendHttpPostToHC6Api(<String, String?>{
      'queryType': 'getKennelRequests',
      'deviceId': _deviceId(),
      'accessToken': _token('hcportal_getKennelRequests'),
      'status': '$status',
    }),
    'getKennelRequests',
  );
  if (rowsets == null || rowsets.length < 2) return null;
  try {
    final requests = (rowsets[0] as List<dynamic>)
        .map((r) => KennelRequestModel.fromJson(r as Map<String, dynamic>))
        .toList();
    final counts = <int, int>{
      for (final r in rowsets[1] as List<dynamic>)
        ((r as Map<String, dynamic>)['RequestStatus'] as num).toInt():
            (r['RequestCount'] as num).toInt(),
    };
    return KennelRequestPage(requests, counts);
  } on Exception catch (e) {
    if (kDebugMode) debugPrint('queryKennelRequests parse error: $e');
    return null;
  }
}

/// Saves the reviewer's edits. Only the fields given are changed; pass an
/// empty string to clear an optional one.
Future<bool> updateKennelRequest(
  String kennelImportId,
  Map<String, String?> fields,
) async {
  final rowsets = _rowsets(
    await ServiceCommon.sendHttpPostToHC6Api(<String, String?>{
      'queryType': 'updateKennelRequest',
      'deviceId': _deviceId(),
      'accessToken': _token('hcportal_updateKennelRequest'),
      'kennelImportId': kennelImportId,
      ...fields,
    }),
    'updateKennelRequest',
  );
  return _succeeded(rowsets);
}

/// What approval made — for the confirmation message.
class ApprovedKennel {
  const ApprovedKennel({
    required this.kennelName,
    required this.slug,
    required this.adminEmail,
    required this.adminIsNew,
    required this.welcomeEmailSent,
  });
  final String kennelName;
  final String slug;
  final String adminEmail;
  final bool adminIsNew;
  final bool welcomeEmailSent;
}

Future<ApprovedKennel?> approveKennelRequest(String kennelImportId) async {
  final rowsets = _rowsets(
    await ServiceCommon.sendHttpPostToHC6Api(<String, String?>{
      'queryType': 'approveKennelRequest',
      'deviceId': _deviceId(),
      'accessToken': _token('hcportal_approveKennelRequest'),
      'kennelImportId': kennelImportId,
    }),
    'approveKennelRequest',
  );
  if (!_succeeded(rowsets) || rowsets!.length < 2) return null;
  final rows = rowsets[1] as List<dynamic>;
  if (rows.isEmpty) return null;
  final r = rows[0] as Map<String, dynamic>;
  return ApprovedKennel(
    kennelName: (r['KennelName'] as String?) ?? '',
    slug: ((r['KennelUniqueShortName'] as String?) ?? '').toLowerCase(),
    adminEmail: (r['AdminEmail'] as String?) ?? '',
    adminIsNew: (r['AdminIsNew'] as num?)?.toInt() == 1,
    welcomeEmailSent: (r['WelcomeEmailSent'] as num?)?.toInt() == 1,
  );
}

/// Rejects (3), marks as spam (4) or duplicate (5), or reopens (1) one or
/// more requests. Returns how many changed, or null on failure.
Future<int?> setKennelRequestStatus(
  List<String> kennelImportIds,
  int newStatus, {
  String? reviewNote,
}) async {
  final rowsets = _rowsets(
    await ServiceCommon.sendHttpPostToHC6Api(<String, String?>{
      'queryType': 'rejectKennelRequest',
      'deviceId': _deviceId(),
      'accessToken': _token('hcportal_rejectKennelRequest'),
      'kennelImportIds': kennelImportIds.join('|'),
      'newStatus': '$newStatus',
      'reviewNote': reviewNote,
    }),
    'rejectKennelRequest',
  );
  if (!_succeeded(rowsets)) return null;
  final row = (rowsets![0] as List<dynamic>)[0] as Map<String, dynamic>;
  return (row['UpdatedCount'] as num?)?.toInt() ?? 0;
}
