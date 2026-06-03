import 'package:harrier_central/imports.dart';

// ---------------------------------------------------------------------------
// Incoming FCM song state — permanent singleton updated by NotificationService
// ---------------------------------------------------------------------------

class SongSessionNotifier extends GetxController {
  static SongSessionNotifier ensure() {
    if (Get.isRegistered<SongSessionNotifier>()) {
      return Get.find<SongSessionNotifier>();
    }
    return Get.put(SongSessionNotifier(), permanent: true);
  }

  final Rxn<String> pendingEventId = Rxn<String>();
  final Rxn<String> pendingSongId = Rxn<String>();
  final Rxn<String> pendingSongTitle = Rxn<String>();
  final Rxn<String> pendingSelectedByName = Rxn<String>();

  /// Set by FCM handler — real-time song update for open songbook / in-app toast.
  void onSongSelected({
    required String eventId,
    required String songId,
    required String songTitle,
    required String selectedByName,
  }) {
    navigateOnLoad = false;
    // Set all non-trigger fields first so they are already populated when the
    // ever() worker fires synchronously on pendingSongId assignment.
    pendingEventId.value = eventId;
    pendingSongTitle.value = songTitle;
    pendingSelectedByName.value = selectedByName;
    // Bounce through null before assigning: GetX only fires ever() on value
    // changes, so re-selecting the same song within a session (same UUID) would
    // otherwise be silently swallowed. null → songId always triggers the worker.
    // The ever() handler guards against null so the null assignment is harmless.
    pendingSongId.value = null;
    pendingSongId.value = songId; // triggers ever() last
  }

  /// Set at login when proximity check finds an active song. The boot service
  /// reads [navigateOnLoad] after routing to the main page and opens the songbook.
  void setPendingProximitySong({
    required String eventId,
    required String songId,
  }) {
    navigateOnLoad = true;
    pendingEventId.value = eventId;
    pendingSongId.value = songId;
    pendingSongTitle.value = '';
    pendingSelectedByName.value = '';
  }

  /// True when the boot service detected a proximity song and wants to navigate
  /// directly to the songbook on first frame of the main page.
  bool navigateOnLoad = false;

  void clearNavigateOnLoad() => navigateOnLoad = false;
}

// ---------------------------------------------------------------------------
// Result models
// ---------------------------------------------------------------------------

class CurrentSongResult {
  CurrentSongResult({
    required this.songId,
    required this.selectedByName,
    required this.songTitle,
  });

  final String songId;
  final String selectedByName;
  final String songTitle;
}

// ---------------------------------------------------------------------------
// HTTP service
// ---------------------------------------------------------------------------

class SongSessionService {
  /// Records a song selection for an event. Returns the song title on success
  /// (for the snackbar), or null on error.
  static Future<String?> selectSong({
    required String eventId,
    required String songId,
  }) async {
    if (Utilities.isNotConnected()) return null;

    final String userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final Map<String, String> body = <String, String>{
      'queryType': 'selectSong',
      'deviceId': deviceId,
      'eventId': eventId,
      'songId': songId,
    };

    final String responseBody = await ServiceCommon.sendHttpPost(() {
      body['accessToken'] = Utilities.generateToken(
        userId,
        'hcapp_selectSong',
        paramString: deviceSecret,
      );
      return jsonEncode(body);
    }, noRetries: true);

    if (responseBody.startsWith(ERROR_PREFIX)) return null;

    try {
      // rowset 0 = success envelope, rowset 1 = adHocData
      final List<dynamic> rowsets = jsonDecode(responseBody) as List<dynamic>;
      if (rowsets.length > 1 && (rowsets[1] as List).isNotEmpty) {
        final Map<String, dynamic> adHoc =
            (rowsets[1] as List)[0] as Map<String, dynamic>;
        return adHoc['songTitle'] as String? ?? '';
      }
    } catch (_) {}
    return '';
  }

  /// Returns the currently active song for an event (selected within the last
  /// 2 minutes) if the caller is RSVP'd, or null if none.
  static Future<CurrentSongResult?> getCurrentSong({
    required String eventId,
  }) async {
    if (Utilities.isNotConnected()) return null;

    final String userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final Map<String, String> body = <String, String>{
      'queryType': 'getCurrentSong',
      'deviceId': deviceId,
      'eventId': eventId,
    };

    final String responseBody = await ServiceCommon.sendHttpPost(() {
      body['accessToken'] = Utilities.generateToken(
        userId,
        'hcapp_getCurrentSong',
        paramString: deviceSecret,
      );
      return jsonEncode(body);
    });

    if (responseBody.startsWith(ERROR_PREFIX)) return null;

    try {
      final List<dynamic> rowsets = jsonDecode(responseBody) as List<dynamic>;
      if (rowsets.isEmpty || (rowsets[0] as List).isEmpty) return null;
      final Map<String, dynamic> row =
          (rowsets[0] as List)[0] as Map<String, dynamic>;
      final String? songId = row['songId'] as String?;
      if (songId == null || songId.isEmpty) return null;
      return CurrentSongResult(
        songId: songId,
        selectedByName: row['selectedByName'] as String? ?? 'Someone',
        songTitle: row['songName'] as String? ?? '',
      );
    } catch (_) {}
    return null;
  }
}
