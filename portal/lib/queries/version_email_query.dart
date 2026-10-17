import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hcportal/imports.dart';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// HC Admin Tools › Version email (E19.F3.S3, James 2026-10-17): email everyone
// still on a given app build. Reads go through the HC6 shim; test, send and
// the AI feature list go through the API's VersionEmail route, which sends
// the mail. Every call needs HC.PlatformAdmin with CanManageNewsflash.
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

int _int(dynamic v) => (v as num?)?.toInt() ?? 0;

/// One app build people are on now, as hcportal_getAppVersionUsage lists it.
class AppVersionUsage {
  const AppVersionUsage(this.row);
  final Map<String, dynamic> row;

  String get version => (row['Version'] as String?) ?? '';
  String get build => (row['BuildNumber'] as String?) ?? '';
  int get users => _int(row['Users']);
  int get ios => _int(row['IosUsers']);
  int get android => _int(row['AndroidUsers']);
  String get major => version.split('.').first;
}

/// One person the email would reach (or would not, and why).
class VersionEmailRecipient {
  const VersionEmailRecipient(this.row);
  final Map<String, dynamic> row;

  String get name => (row['Name'] as String?) ?? '';
  String get email => (row['Email'] as String?) ?? '';
  String get version => '${row['Version'] ?? ''} (${row['BuildNumber'] ?? ''})';
  bool get ios => _int(row['IsIos']) == 1;
  bool get android => _int(row['IsAndroid']) == 1;
  bool get eligible => _int(row['Eligible']) == 1;
  String get reason => (row['Reason'] as String?) ?? '';
  DateTime? get lastLogin => DateTime.tryParse(row['LastLogin']?.toString() ?? '')?.toLocal();
}

/// How a send is going.
class VersionEmailProgress {
  const VersionEmailProgress({this.queued = 0, this.sending = 0, this.sent = 0, this.failed = 0});
  final int queued;
  final int sending;
  final int sent;
  final int failed;
  int get total => queued + sending + sent + failed;
  bool get done => total > 0 && queued == 0 && sending == 0;
}

/// Every build with active users in the last [days]. Null on failure.
Future<List<AppVersionUsage>?> getAppVersionUsage(int days) async {
  final rowsets = _rowsets(
    await ServiceCommon.sendHttpPostToHC6Api(<String, String?>{
      'queryType': 'getAppVersionUsage',
      'deviceId': _deviceId(),
      'accessToken': _token('hcportal_getAppVersionUsage'),
      'days': '$days',
    }),
    'getAppVersionUsage',
  );
  if (rowsets == null || rowsets.isEmpty) return null;
  final rows = (rowsets[0] as List<dynamic>).cast<Map<String, dynamic>>();
  if (rows.length == 1 && rows[0].containsKey('Success')) return null;
  return rows.map(AppVersionUsage.new).toList();
}

/// The people for [builds] (and, with [sendId], that send's progress).
Future<({List<VersionEmailRecipient> people, VersionEmailProgress progress})?>
getVersionEmailRecipients(List<String> builds, int days, {String? sendId}) async {
  final rowsets = _rowsets(
    await ServiceCommon.sendHttpPostToHC6Api(<String, String?>{
      'queryType': 'getVersionEmailRecipients',
      'deviceId': _deviceId(),
      'accessToken': _token('hcportal_getVersionEmailRecipients'),
      'builds': builds.join('|'),
      'days': '$days',
      'sendId': sendId,
    }),
    'getVersionEmailRecipients',
  );
  if (rowsets == null || rowsets.isEmpty) return null;
  final rows = (rowsets[0] as List<dynamic>).cast<Map<String, dynamic>>();
  if (rows.length == 1 && rows[0].containsKey('Success')) return null;
  VersionEmailProgress progress = const VersionEmailProgress();
  if (rowsets.length > 1 && (rowsets[1] as List<dynamic>).isNotEmpty) {
    final p = (rowsets[1] as List<dynamic>)[0] as Map<String, dynamic>;
    progress = VersionEmailProgress(
      queued: _int(p['Queued']),
      sending: _int(p['Sending']),
      sent: _int(p['Sent']),
      failed: _int(p['Failed']),
    );
  }
  return (people: rows.map(VersionEmailRecipient.new).toList(), progress: progress);
}

/// Thrown with a message to show.
class VersionEmailException implements Exception {
  const VersionEmailException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// One call to the API's VersionEmail route. The token is the portal's own,
/// signed for hcportal_queueVersionEmail (the SP that checks the caller).
Future<Map<String, dynamic>> _post(String action, Map<String, dynamic> extra, {Duration timeout = const Duration(seconds: 60)}) async {
  http.Response response;
  try {
    response = await http
        .post(
          Uri.parse(BASE_VERSION_EMAIL_URL),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'deviceId': _deviceId(),
            'accessToken': _token('hcportal_queueVersionEmail'),
            'action': action,
            ...extra,
          }),
        )
        .timeout(timeout);
  } catch (_) {
    throw const VersionEmailException('No connection to Harrier Central. Check your connection and try again.');
  }
  Map<String, dynamic> j;
  try {
    j = jsonDecode(response.body) as Map<String, dynamic>;
  } catch (_) {
    j = {};
  }
  if (response.statusCode != 200) {
    throw VersionEmailException(
      (j['errorUserMessage'] as String?) ?? 'Harrier Central could not do that just now (${response.statusCode}).',
    );
  }
  return j;
}

/// The five most important features since the oldest of [builds], as lines.
Future<List<String>> suggestVersionFeatures(List<String> builds) async {
  final j = await _post('features', {'builds': builds.join('|')}, timeout: const Duration(seconds: 90));
  return ((j['features'] as List<dynamic>?) ?? const []).map((e) => e.toString()).toList();
}

/// Sends the email to the caller only (both store buttons). Returns the address.
Future<String> sendVersionEmailTest(String subject, String body) async {
  final j = await _post('test', {'subject': subject, 'body': body});
  return (j['to'] as String?) ?? '';
}

/// Queues the send under [sendId] and starts it. Returns how many are queued.
Future<int> sendVersionEmail(String sendId, List<String> builds, int days, String subject, String body) async {
  final j = await _post('send', {
    'sendId': sendId,
    'builds': builds.join('|'),
    'days': days,
    'subject': subject,
    'body': body,
  });
  return _int(j['queued']);
}
