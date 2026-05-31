import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hcportal/imports.dart';

/// Fetches all songs with kennel membership flags for the given kennel.
///
/// Calls the [hcportal_getSongs] stored procedure which returns all non-removed
/// songs along with an `isInKennel` flag indicating whether each song is
/// associated with the specified kennel.
Future<List<SongModel>> queryKennelSongs(String publicKennelId) async {
  publicKennelId = normalizeUuid(publicKennelId);
  if (publicKennelId.length != 36) return <SongModel>[];

  final deviceId = box.get(HIVE_DEVICE_ID) as String;
  final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
  final accessToken = Utilities.generateToken(
    deviceId,
    'hcportal_getSongs',
    paramString: '$deviceSecret:$publicKennelId',
  );

  final body = <String, String>{
    'queryType': 'getSongs',
    'deviceId': deviceId,
    'accessToken': accessToken,
    'publicKennelId': publicKennelId,
  };

  final result = await ServiceCommon.sendHttpPostToHC6Api(body);
  if (kDebugMode) debugPrint(result is ApiError
      ? 'SP 15 [getSongs] called — FAILED'
      : 'SP 15 [getSongs] called — success');

  if (result case ApiSuccess(:final body)) {
    final jsonItems = json.decode(body) as List<dynamic>;
    final songRecords = jsonItems[0] as List<dynamic>;
    return songRecords
        .map((record) => SongModel.fromJson(record as Map<String, dynamic>))
        .toList();
  }

  return <SongModel>[];
}

/// Updates an existing song's editable fields.
///
/// Calls [hcportal_editSong]. The server enforces that the caller holds
/// authIsSuperAdmin or authCanManageSongs on the kennel that originally
/// added the song. Returns true on success, false on auth/validation failure.
Future<bool> editSong({
  required String publicKennelId,
  required String songId,
  required String songName,
  required String tuneOf,
  required String lyrics,
  required String notes,
  required String actions,
  required String variants,
  required String tags,
  required int bawdyRating,
}) async {
  publicKennelId = normalizeUuid(publicKennelId);
  songId = normalizeUuid(songId);
  if (publicKennelId.length != 36 || songId.length != 36) return false;

  final deviceId = box.get(HIVE_DEVICE_ID) as String;
  final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
  final accessToken = Utilities.generateToken(
    deviceId,
    'hcportal_editSong',
    paramString: '$deviceSecret:$publicKennelId',
  );

  final body = <String, dynamic>{
    'queryType': 'editSong',
    'deviceId': deviceId,
    'accessToken': accessToken,
    'publicKennelId': publicKennelId,
    'songId': songId,
    'songName': songName,
    'tuneOf': tuneOf,
    'lyrics': lyrics,
    'notes': notes,
    'actions': actions,
    'variants': variants,
    'tags': tags,
    'bawdyRating': bawdyRating,
  };

  final apiResult = await ServiceCommon.sendHttpPostToHC6Api(body);
  if (kDebugMode) debugPrint(apiResult is ApiError
      ? 'SP [editSong] called — FAILED'
      : 'SP [editSong] called — success');

  if (apiResult case ApiSuccess(:final body)) {
    final jsonItems = json.decode(body) as List<dynamic>;
    final row = (jsonItems[0] as List<dynamic>)[0] as Map<String, dynamic>;
    if ((row['resultCode'] as int?) == 1) return true;
    final errorMsg = row['ErrorMessage'] as String? ?? 'Edit failed';
    await CoreUtilities.showAlert('Edit Song', errorMsg, 'OK');
  }

  return false;
}

/// Toggles a song's membership in a kennel (add or remove).
///
/// Calls the [hcportal_toggleKennelSong] stored procedure which either
/// inserts/un-removes a KennelSongMap row (isInKennel=true) or soft-deletes
/// it (isInKennel=false).
///
/// Returns `true` if the server confirmed success.
Future<bool> toggleKennelSong({
  required String publicKennelId,
  required String songId,
  required bool isInKennel,
}) async {
  publicKennelId = normalizeUuid(publicKennelId);
  songId = normalizeUuid(songId);
  if (publicKennelId.length != 36 || songId.length != 36) return false;

  final deviceId = box.get(HIVE_DEVICE_ID) as String;
  final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
  final accessToken = Utilities.generateToken(
    deviceId,
    'hcportal_toggleKennelSong',
    paramString: '$deviceSecret:$songId',
  );

  final body = <String, String>{
    'queryType': 'toggleKennelSong',
    'deviceId': deviceId,
    'accessToken': accessToken,
    'publicKennelId': publicKennelId,
    'songId': songId,
    'isInKennel': isInKennel ? '1' : '0',
  };

  final apiResult = await ServiceCommon.sendHttpPostToHC6Api(body);
  if (kDebugMode) debugPrint(apiResult is ApiError
      ? 'SP 18 [toggleKennelSong] called — FAILED'
      : 'SP 18 [toggleKennelSong] called — success');

  if (apiResult case ApiSuccess(:final body)) {
    final jsonItems = json.decode(body) as List<dynamic>;
    final row = (jsonItems[0] as List<dynamic>)[0] as Map<String, dynamic>;
    return (row['resultCode'] as int) == 1;
  }

  return false;
}
