import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hcportal/imports.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _deviceId() => box.get(HIVE_DEVICE_ID) as String;
String _deviceSecret() => (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';

String _token(String procName) =>
    Utilities.generateToken(_deviceId(), procName, paramString: _deviceSecret());

// ---------------------------------------------------------------------------
// Pending newsflashes (user-facing)
// ---------------------------------------------------------------------------

/// Returns newsflashes that are due for the current user.
/// Returns an empty list on any error.
Future<List<NewsflashModel>> queryPendingNewsflashes() async {
  final body = <String, String?>{
    'queryType': 'getPendingNewsflashes',
    'deviceId': _deviceId(),
    'accessToken': _token('hcportal_getPendingNewsflashes'),
  };

  final jsonResult = await ServiceCommon.sendHttpPostToHC6Api(body);
  debugPrint(jsonResult.startsWith(ERROR_PREFIX)
      ? 'SP [getPendingNewsflashes] — FAILED'
      : 'SP [getPendingNewsflashes] — success');

  if (jsonResult.startsWith(ERROR_PREFIX) || jsonResult.length <= 10) {
    return [];
  }

  try {
    final rows =
        (json.decode(jsonResult) as List<dynamic>)[0] as List<dynamic>;
    return rows
        .map((r) => NewsflashModel.fromJson(r as Map<String, dynamic>))
        .toList();
  } on Exception catch (e) {
    if (kDebugMode) debugPrint('queryPendingNewsflashes parse error: $e');
    return [];
  }
}

// ---------------------------------------------------------------------------
// Respond to newsflash (user-facing)
// ---------------------------------------------------------------------------

/// Records a user response. [isDismissed] = true → "I've read it";
/// [isDismissed] = false → "Read Later" (snooze until tomorrow).
/// Returns true on success.
Future<bool> respondToNewsflash(
  String newsflashId, {
  required bool isDismissed,
}) async {
  final body = <String, String?>{
    'queryType': 'respondToNewsflash',
    'deviceId': _deviceId(),
    'accessToken': _token('hcportal_respondToNewsflash'),
    'newsflashId': newsflashId,
    'isDismissed': isDismissed ? '1' : '0',
  };

  final jsonResult = await ServiceCommon.sendHttpPostToHC6Api(body);
  debugPrint(jsonResult.startsWith(ERROR_PREFIX)
      ? 'SP [respondToNewsflash] — FAILED'
      : 'SP [respondToNewsflash] — success');

  if (jsonResult.startsWith(ERROR_PREFIX) || jsonResult.length <= 10) {
    return false;
  }

  try {
    final row = ((json.decode(jsonResult) as List<dynamic>)[0]
        as List<dynamic>)[0] as Map<String, dynamic>;
    return (row['Success'] as int?) == 1;
  } on Exception catch (e) {
    if (kDebugMode) debugPrint('respondToNewsflash parse error: $e');
    return false;
  }
}

// ---------------------------------------------------------------------------
// Admin: get newsflash list
// ---------------------------------------------------------------------------

/// Returns all newsflashes (including soft-deleted) for the admin screen.
Future<List<NewsflashAdminModel>> queryNewsflashList() async {
  final body = <String, String?>{
    'queryType': 'getNewsflashList',
    'deviceId': _deviceId(),
    'accessToken': _token('hcportal_getNewsflashList'),
  };

  final jsonResult = await ServiceCommon.sendHttpPostToHC6Api(body);
  debugPrint(jsonResult.startsWith(ERROR_PREFIX)
      ? 'SP [getNewsflashList] — FAILED'
      : 'SP [getNewsflashList] — success');

  if (jsonResult.startsWith(ERROR_PREFIX) || jsonResult.length <= 10) {
    return [];
  }

  try {
    final rows =
        (json.decode(jsonResult) as List<dynamic>)[0] as List<dynamic>;
    return rows
        .map((r) => NewsflashAdminModel.fromJson(r as Map<String, dynamic>))
        .toList();
  } on Exception catch (e) {
    if (kDebugMode) debugPrint('queryNewsflashList parse error: $e');
    return [];
  }
}

// ---------------------------------------------------------------------------
// Admin: add or edit newsflash
// ---------------------------------------------------------------------------

/// Creates or updates a newsflash. Pass [newsflashId] = null to add new.
/// Returns true on success.
Future<bool> addEditNewsflash({
  String? newsflashId,
  required String title,
  required String bodyText,
  String? imageUrl,
  required DateTime startDate,
  DateTime? endDate,
  String? kennelId,
}) async {
  final body = <String, String?>{
    'queryType': 'addEditNewsflash',
    'deviceId': _deviceId(),
    'accessToken': _token('hcportal_addEditNewsflash'),
    if (newsflashId != null) 'newsflashId': newsflashId,
    'title': title,
    'bodyText': bodyText,
    if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
    'startDate': startDate.toIso8601String().substring(0, 10),
    if (endDate != null)
      'endDate': endDate.toIso8601String().substring(0, 10),
    if (kennelId != null) 'kennelId': kennelId,
  };

  final jsonResult = await ServiceCommon.sendHttpPostToHC6Api(body);
  debugPrint(jsonResult.startsWith(ERROR_PREFIX)
      ? 'SP [addEditNewsflash] — FAILED'
      : 'SP [addEditNewsflash] — success');

  if (jsonResult.startsWith(ERROR_PREFIX) || jsonResult.length <= 10) {
    return false;
  }

  try {
    final row = ((json.decode(jsonResult) as List<dynamic>)[0]
        as List<dynamic>)[0] as Map<String, dynamic>;
    return (row['Success'] as int?) == 1;
  } on Exception catch (e) {
    if (kDebugMode) debugPrint('addEditNewsflash parse error: $e');
    return false;
  }
}

// ---------------------------------------------------------------------------
// Admin: delete newsflash
// ---------------------------------------------------------------------------

/// Soft-deletes a newsflash. Returns true on success.
Future<bool> deleteNewsflash(String newsflashId) async {
  final body = <String, String?>{
    'queryType': 'deleteNewsflash',
    'deviceId': _deviceId(),
    'accessToken': _token('hcportal_deleteNewsflash'),
    'newsflashId': newsflashId,
  };

  final jsonResult = await ServiceCommon.sendHttpPostToHC6Api(body);
  debugPrint(jsonResult.startsWith(ERROR_PREFIX)
      ? 'SP [deleteNewsflash] — FAILED'
      : 'SP [deleteNewsflash] — success');

  if (jsonResult.startsWith(ERROR_PREFIX) || jsonResult.length <= 10) {
    return false;
  }

  try {
    final row = ((json.decode(jsonResult) as List<dynamic>)[0]
        as List<dynamic>)[0] as Map<String, dynamic>;
    return (row['Success'] as int?) == 1;
  } on Exception catch (e) {
    if (kDebugMode) debugPrint('deleteNewsflash parse error: $e');
    return false;
  }
}

// ---------------------------------------------------------------------------
// Admin: get readers for a newsflash
// ---------------------------------------------------------------------------

/// Returns all users who have interacted with a newsflash.
Future<List<NewsflashReaderModel>> queryNewsflashReaders(
    String newsflashId) async {
  final body = <String, String?>{
    'queryType': 'getNewsflashReaders',
    'deviceId': _deviceId(),
    'accessToken': _token('hcportal_getNewsflashReaders'),
    'newsflashId': newsflashId,
  };

  final jsonResult = await ServiceCommon.sendHttpPostToHC6Api(body);
  debugPrint(jsonResult.startsWith(ERROR_PREFIX)
      ? 'SP [getNewsflashReaders] — FAILED'
      : 'SP [getNewsflashReaders] — success');

  if (jsonResult.startsWith(ERROR_PREFIX) || jsonResult.length <= 10) {
    return [];
  }

  try {
    final rows =
        (json.decode(jsonResult) as List<dynamic>)[0] as List<dynamic>;
    return rows
        .map((r) => NewsflashReaderModel.fromJson(r as Map<String, dynamic>))
        .toList();
  } on Exception catch (e) {
    if (kDebugMode) debugPrint('queryNewsflashReaders parse error: $e');
    return [];
  }
}
