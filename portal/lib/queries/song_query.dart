import 'package:hcportal/imports.dart';

/// Fetches all songs with kennel membership flags for the given kennel.
///
/// Calls the [hcportal_getSongs] stored procedure which returns all non-removed
/// songs along with an `isInKennel` flag indicating whether each song is
/// associated with the specified kennel.
Future<List<SongModel>> queryKennelSongs(String publicKennelId) async {
  if (publicKennelId.length != 36) {
    return <SongModel>[];
  }

  final deviceId = box.get(HIVE_DEVICE_ID) as String;
  final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
  final accessToken = Utilities.generateToken(
    deviceId,
    'hcportal_getSongs',
    paramString: deviceSecret,
  );

  final body = <String, String>{
    'queryType': 'getSongs',
    'deviceId': deviceId,
    'accessToken': accessToken,
    'publicKennelId': publicKennelId,
  };

  final jsonResult = await ServiceCommon.sendHttpPostToHC6Api(body);

  if (!jsonResult.startsWith(ERROR_PREFIX)) {
    final jsonItems = json.decode(jsonResult) as List<dynamic>;

    // The SP returns a single result set of songs
    final songRecords = jsonItems[0] as List<dynamic>;
    return songRecords
        .map((record) => SongModel.fromJson(record as Map<String, dynamic>))
        .toList();
  }

  return <SongModel>[];
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
  if (publicKennelId.length != 36 || songId.length != 36) return false;

  final deviceId = box.get(HIVE_DEVICE_ID) as String;
  final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
  final accessToken = Utilities.generateToken(
    deviceId,
    'hcportal_toggleKennelSong',
    paramString: deviceSecret,
  );

  final body = <String, String>{
    'queryType': 'toggleKennelSong',
    'deviceId': deviceId,
    'accessToken': accessToken,
    'publicKennelId': publicKennelId,
    'songId': songId,
    'isInKennel': isInKennel ? '1' : '0',
  };

  final jsonResult = await ServiceCommon.sendHttpPostToHC6Api(body);

  if (!jsonResult.startsWith(ERROR_PREFIX)) {
    final jsonItems = json.decode(jsonResult) as List<dynamic>;
    final result = (jsonItems[0] as List<dynamic>)[0] as Map<String, dynamic>;
    return (result['resultCode'] as int) == 1;
  }

  return false;
}
