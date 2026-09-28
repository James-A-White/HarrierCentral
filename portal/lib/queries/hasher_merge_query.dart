import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hcportal/imports.dart';

// ---------------------------------------------------------------------------
// Merging two accounts that belong to one person (E12.F6). Both SPs require
// HC.PlatformAdmin.CanEditKennel; a refusal shows the SP's message in the
// standard alert (ServiceCommon), so these return null on failure.
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

/// One side of the merge, as hcportal_previewHasherMerge describes it.
class MergeAccount {
  const MergeAccount(this.row);
  final Map<String, dynamic> row;

  String get id => ((row['HasherId'] as String?) ?? '').toLowerCase();
  String get hashName => (row['HashName'] as String?) ?? '';
  String get name => '${row['FirstName'] ?? ''} ${row['LastName'] ?? ''}'.trim();
  String get email => (row['Email'] as String?) ?? '';
  String get display => hashName.isNotEmpty ? hashName : (name.isNotEmpty ? name : email);
  int n(String key) => (row[key] as num?)?.toInt() ?? 0;
  double d(String key) => (row[key] as num?)?.toDouble() ?? 0;
  String? s(String key) => row[key]?.toString();
}

class MergePreview {
  const MergePreview(this.keep, this.merge, this.overlap);
  final MergeAccount keep;
  final MergeAccount merge;
  final Map<String, dynamic> overlap;
  int n(String key) => (overlap[key] as num?)?.toInt() ?? 0;
}

Future<MergePreview?> previewHasherMerge(String keepEmail, String mergeEmail) async {
  final rowsets = _rowsets(
    await ServiceCommon.sendHttpPostToHC6Api(<String, String?>{
      'queryType': 'previewHasherMerge',
      'deviceId': _deviceId(),
      'accessToken': _token('hcportal_previewHasherMerge'),
      'keepEmail': keepEmail,
      'mergeEmail': mergeEmail,
    }),
    'previewHasherMerge',
  );
  if (rowsets == null || rowsets.length < 2) return null;
  final accounts = (rowsets[0] as List<dynamic>).cast<Map<String, dynamic>>();
  final overlap = (rowsets[1] as List<dynamic>).cast<Map<String, dynamic>>();
  if (accounts.length != 2 || overlap.isEmpty) return null;
  return MergePreview(MergeAccount(accounts[0]), MergeAccount(accounts[1]), overlap[0]);
}

/// Merges [mergeHasherId] into [keepHasherId]. Returns the counts of what
/// moved, or null on failure.
Future<Map<String, int>?> mergeHashers(String keepHasherId, String mergeHasherId) async {
  final rowsets = _rowsets(
    await ServiceCommon.sendHttpPostToHC6Api(<String, String?>{
      'queryType': 'mergeHashers',
      'deviceId': _deviceId(),
      'accessToken': _token('hcportal_mergeHashers'),
      'keepHasherId': keepHasherId,
      'mergeHasherId': mergeHasherId,
    }),
    'mergeHashers',
  );
  if (rowsets == null || rowsets.length < 2) return null;
  final envelope = (rowsets[0] as List<dynamic>).cast<Map<String, dynamic>>();
  if (envelope.isEmpty || (envelope[0]['Success'] as num?)?.toInt() != 1) return null;
  final rows = (rowsets[1] as List<dynamic>).cast<Map<String, dynamic>>();
  if (rows.isEmpty) return <String, int>{};
  return {for (final e in rows[0].entries) e.key: (e.value as num?)?.toInt() ?? 0};
}

/// One account in the merge search table (hcportal_searchHashersForMerge).
class MergeCandidate {
  const MergeCandidate(this.row);
  final Map<String, dynamic> row;

  String get id => ((row['HasherId'] as String?) ?? '').toLowerCase();
  String get hashName => ((row['HashName'] as String?) ?? '').trim();
  String get name => '${row['FirstName'] ?? ''} ${row['LastName'] ?? ''}'.trim();
  String get email => (row['Email'] as String?) ?? '';
  String get display => hashName.isNotEmpty ? hashName : (name.isNotEmpty ? name : email);
  int n(String key) => (row[key] as num?)?.toInt() ?? 0;
  String? s(String key) {
    final String? v = row[key]?.toString().trim();
    return (v == null || v.isEmpty) ? null : v;
  }
}

/// Every live account matching [terms] — hash names, or an email / hasher id
/// for an account whose name is blank. Null on failure (the alert shows why).
Future<List<MergeCandidate>?> searchHashersForMerge(List<String> terms) async {
  final rowsets = _rowsets(
    await ServiceCommon.sendHttpPostToHC6Api(<String, String?>{
      'queryType': 'searchHashersForMerge',
      'deviceId': _deviceId(),
      'accessToken': _token('hcportal_searchHashersForMerge'),
      // The admin types commas; the SP splits on '|', the project's list
      // delimiter, which never appears in a hash name (CLAUDE.md).
      'searchTerms': terms.join('|'),
    }),
    'searchHashersForMerge',
  );
  if (rowsets == null || rowsets.isEmpty) return null;
  final rows = (rowsets[0] as List<dynamic>).cast<Map<String, dynamic>>();
  if (rows.length == 1 && rows[0].containsKey('Success')) return null;
  return rows.map(MergeCandidate.new).toList();
}
