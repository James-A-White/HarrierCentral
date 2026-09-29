import 'package:harrier_central/imports.dart';

/// Direct messages between hashers (E9.F1.S7 / S18 / S19, 2026-09-29).
///
/// The only door is "Message `<name>`" on another hasher's chat message. The
/// server decides what that tap does — open a thread, ask the other hasher,
/// or refuse — from THEIR preference and the friendship rows, and nothing
/// here second-guesses it. A thread is an HC.EventMessage stream keyed by
/// ThreadId, read and written through the room-shaped SPs, so the chat page
/// draws it exactly as it draws a room.

/// Who may message this hasher: two bits of HC.Hasher.Preferences.
///
/// The server's rule (HC6.DirectMessagePreference): bits 0x4000|0x8000,
/// `(Preferences >> 14) & 3` — 0 friends only (the default, every row is 0
/// today), 1 anyone, 2 nobody, and the unused 3 reads as nobody.
///
/// The value is WRITTEN only by hcapp_setDirectMessagePreference, which
/// read-modify-writes its own two bits server-side. On the phone it lives in
/// [IntPrefsEnum.hasherPreferences] — the bitfield every whole-Preferences
/// writer (Settings, the radius picker) starts from — so a successful set
/// must land its bits there too, or the next distance change would send the
/// old bits back and silently undo it (the 2026-09-27 bitfield rule).
class DirectMessagePreference {
  const DirectMessagePreference._();

  static const int friendsOnly = 0;
  static const int anyone = 1;
  static const int nobody = 2;

  static const int shift = 14;
  static const int mask = 0x3 << shift; // 0xC000

  /// The preference held in a Preferences bitfield. Matches the SQL function
  /// exactly, including the unused 3 reading as nobody.
  static int decode(int? preferences) {
    final int raw = ((preferences ?? 0) >> shift) & 0x3;
    if (raw == anyone) return anyone;
    if (raw == friendsOnly) return friendsOnly;
    return nobody;
  }

  /// [stored] with only the two DM bits replaced.
  static int withBits(int stored, int preference) =>
      (stored & ~mask) | ((preference & 0x3) << shift);

  static String label(int preference) => switch (preference) {
    anyone => 'Anyone',
    nobody => 'Nobody',
    _ => 'Friends only',
  };

  /// The phone's current value: the bitfield the login handed over and every
  /// app-side write has kept up to date since.
  static int current() =>
      decode(getIntPref(IntPrefsEnum.hasherPreferences) ?? 0);

  /// Store [preference] on the server, then mirror its bits locally. Returns
  /// the value the server now holds, or null when the call failed.
  static Future<int?> set(int preference) async {
    final _Creds? c = _Creds.current();
    if (c == null) return null;

    final String result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'setDirectMessagePreference',
        'deviceId': c.deviceId,
        'accessToken': Utilities.generateToken(
          c.userId,
          'hcapp_setDirectMessagePreference',
          paramString: c.deviceSecret,
        ),
        'preference': preference,
      }),
      errorCallback: (_) async => true,
    );
    if (result.startsWith(ERROR_PREFIX)) return null;

    final int? stored = parseSetReply(result);
    if (stored == null) return null;
    final int local = getIntPref(IntPrefsEnum.hasherPreferences) ?? 0;
    await setIntPref(IntPrefsEnum.hasherPreferences, withBits(local, stored));
    return stored;
  }

  /// Rowset 0 is the envelope; rowset 1 carries `{ Preference }`.
  static int? parseSetReply(String body) {
    try {
      final List<dynamic> outer = jsonDecode(body) as List<dynamic>;
      if (outer.isEmpty) return null;
      final Map<String, dynamic>? envelope = firstRow(
        outer[0] as List<dynamic>?,
      );
      final bool ok =
          envelope?['success'] == 1 || envelope?['success'] == true;
      if (!ok || outer.length < 2) return null;
      final Object? value = firstRow(outer[1] as List<dynamic>?)?['Preference'];
      return value is num ? decode(value.toInt() << shift) : null;
    } catch (e, s) {
      BootLogger.logError('[ERROR][DM]', 'preference reply unreadable: $e', s);
      return null;
    }
  }
}

/// What hcapp_startDirectMessage (and respondDirectMessageRequest) said.
enum DmOutcome {
  /// The thread is ready: [DmStartResult.threadId] is set.
  open,

  /// The other hasher will be asked; nothing to open yet.
  requested,

  /// The other hasher accepts messages from nobody.
  refused,

  /// This hasher has blocked the other — unblock first.
  blocked,

  /// A request was declined (respond only).
  declined,

  /// A reply this build does not recognise. Treated as "nothing happened".
  unknown;

  static DmOutcome parse(Object? raw) {
    final String s = '${raw ?? ''}'.trim().toLowerCase();
    for (final DmOutcome o in DmOutcome.values) {
      if (o.name == s) return o;
    }
    return DmOutcome.unknown;
  }
}

/// Rowset 1 of a start / respond call: the outcome and who the other party is.
class DmStartResult {
  const DmStartResult({
    required this.outcome,
    required this.otherPublicHasherId,
    required this.otherDisplayName,
    this.threadId,
    this.otherPhoto,
  });

  final DmOutcome outcome;

  /// Set only when [outcome] is [DmOutcome.open].
  final HcId? threadId;
  final HcId otherPublicHasherId;
  final String otherDisplayName;
  final String? otherPhoto;

  factory DmStartResult.fromJson(Map<String, dynamic> json) => DmStartResult(
    outcome: DmOutcome.parse(json['Outcome']),
    threadId: HcId.tryParse(json['ThreadId']),
    otherPublicHasherId: HcId(json['OtherPublicHasherId'] as String?),
    otherDisplayName: _nameOr(json['OtherDisplayName']),
    otherPhoto: json['OtherPhoto'] as String?,
  );

  /// Rowset 0 is the envelope; rowset 1 the result. Null when the write did
  /// not happen or the reply is not one.
  static DmStartResult? parseReply(String body) {
    try {
      final List<dynamic> outer = jsonDecode(body) as List<dynamic>;
      if (outer.isEmpty) return null;
      final Map<String, dynamic>? envelope = firstRow(
        outer[0] as List<dynamic>?,
      );
      final bool ok =
          envelope?['success'] == 1 || envelope?['success'] == true;
      if (!ok || outer.length < 2) return null;
      final Map<String, dynamic>? row = firstRow(outer[1] as List<dynamic>?);
      return row == null ? null : DmStartResult.fromJson(row);
    } catch (e, s) {
      BootLogger.logError('[ERROR][DM]', 'start reply unreadable: $e', s);
      return null;
    }
  }
}

/// One hasher asking to message this one, as hcapp_getDirectMessageRequests
/// lists them (newest first).
class DirectMessageRequest {
  const DirectMessageRequest({
    required this.fromPublicHasherId,
    required this.displayName,
    this.photo,
    this.requestedAt,
  });

  /// The PUBLIC id — what a chat message carries as its authorId. SQL sends
  /// it UPPERCASE; [HcId] lowercases it.
  final HcId fromPublicHasherId;
  final String displayName;

  /// HC.Hasher.Photo: a URL, a `bundle://` avatar, or nothing — always drawn
  /// through avatarImageProvider (hc-avatars skill).
  final String? photo;
  final DateTime? requestedAt;

  factory DirectMessageRequest.fromJson(Map<String, dynamic> json) =>
      DirectMessageRequest(
        fromPublicHasherId: HcId(json['FromPublicHasherId'] as String?),
        displayName: _nameOr(json['DisplayName']),
        photo: json['Photo'] as String?,
        requestedAt: _dateOf(json['RequestedAt']),
      );

  static List<DirectMessageRequest> parseRows(dynamic rowset) {
    if (rowset is! List) return <DirectMessageRequest>[];
    return rowset
        .whereType<Map<String, dynamic>>()
        .map(DirectMessageRequest.fromJson)
        .where((DirectMessageRequest r) => r.fromPublicHasherId.isValid)
        .toList();
  }
}

/// A DM thread's live state, shared between the page that draws the chat
/// and the scaffold that draws its app bar. Each DM page creates one and
/// hands it to both, so the app-bar menu (Mute, End conversation) and the
/// composer (hidden once sending is refused) agree without either looking
/// the other up in the GetX registry — ChatPageController is owned by its
/// page and is not in it.
class DmThreadState {
  DmThreadState({
    required this.threadId,
    required HcId otherPublicHasherId,
    required String otherDisplayName,
    String? otherPhoto,
  }) : otherPublicHasherId = otherPublicHasherId.obs,
       otherDisplayName = otherDisplayName.obs,
       otherPhoto = (otherPhoto ?? '').obs;

  final HcId threadId;
  final Rx<HcId> otherPublicHasherId;
  final RxString otherDisplayName;
  final RxString otherPhoto;

  /// 1 when both friendship rows are live and nobody blocks. Assumed true
  /// until the first read says otherwise, so the composer does not flicker.
  final RxBool canSend = true.obs;
  final RxBool muted = false.obs;

  /// Set once hcapp_getDirectMessages has answered, so the menu can show a
  /// Mute state it actually knows rather than a guess.
  final RxBool known = false.obs;

  /// Apply rowset 1 of hcapp_getDirectMessages.
  void applyThreadRow(Map<String, dynamic> row) {
    canSend.value = row['canSend'] == 1 || row['canSend'] == true;
    muted.value = row['muted'] == 1 || row['muted'] == true;
    final HcId? other = HcId.tryParse(row['otherPublicHasherId']);
    if (other != null) otherPublicHasherId.value = other;
    final Object? name = row['otherDisplayName'];
    if (name is String && name.trim().isNotEmpty) {
      otherDisplayName.value = name.trim();
    }
    final Object? photo = row['otherPhoto'];
    if (photo is String) otherPhoto.value = photo;
    known.value = true;
  }
}

class DirectMessageService {
  const DirectMessageService();

  /// "Message `<name>`": open, ask, or be refused. The server's own refusal
  /// (yourself, not found) comes back as [refusal] on a null result.
  static Future<DmStartResult?> start(
    HcId targetPublicHasherId, {
    void Function(String? refusal)? onRefused,
  }) async {
    final _Creds? c = _Creds.current();
    if (c == null) return null;

    final String result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'startDirectMessage',
        'deviceId': c.deviceId,
        'accessToken': Utilities.generateToken(
          c.userId,
          'hcapp_startDirectMessage',
          paramString: c.deviceSecret,
        ),
        'targetPublicHasherId': targetPublicHasherId,
      }),
      errorCallback: (DbErrorModel e) async {
        onRefused?.call(e.errorUserMessage);
        return true;
      },
    );
    if (result.startsWith(ERROR_PREFIX)) return null;
    return DmStartResult.parseReply(result);
  }

  /// Requests waiting for this hasher's answer. Null when the call FAILED;
  /// an empty list is the ordinary answer and is not an error.
  static Future<List<DirectMessageRequest>?> fetchRequests() async {
    final _Creds? c = _Creds.current();
    if (c == null) return null;

    final String result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'getDirectMessageRequests',
        'deviceId': c.deviceId,
        'accessToken': Utilities.generateToken(
          c.userId,
          'hcapp_getDirectMessageRequests',
          paramString: c.deviceSecret,
        ),
      }),
      // A background refresh — never an alert.
      errorCallback: (_) async => true,
    );
    if (result.startsWith(ERROR_PREFIX)) return null;

    try {
      final List<dynamic> outer = jsonDecode(result) as List<dynamic>;
      if (outer.isEmpty) return <DirectMessageRequest>[];
      return DirectMessageRequest.parseRows(outer[0]);
    } catch (e, s) {
      BootLogger.logError('[ERROR][DM]', 'requests unreadable: $e', s);
      return null;
    }
  }

  /// Accept (the thread opens and the requester is told) or decline (the
  /// requester is told nothing).
  static Future<DmStartResult?> respond(
    HcId fromPublicHasherId, {
    required bool accept,
    void Function(String? refusal)? onRefused,
  }) async {
    final _Creds? c = _Creds.current();
    if (c == null) return null;

    final String result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'respondDirectMessageRequest',
        'deviceId': c.deviceId,
        'accessToken': Utilities.generateToken(
          c.userId,
          'hcapp_respondDirectMessageRequest',
          paramString: c.deviceSecret,
        ),
        'fromPublicHasherId': fromPublicHasherId,
        'accept': accept ? 1 : 0,
      }),
      errorCallback: (DbErrorModel e) async {
        onRefused?.call(e.errorUserMessage);
        return true;
      },
    );
    if (result.startsWith(ERROR_PREFIX)) return null;
    return DmStartResult.parseReply(result);
  }

  /// End the conversation: this side's row is removed, the thread stays
  /// readable, and neither side can send. The other party is not told.
  static Future<bool> end(HcId threadId) async {
    final _Creds? c = _Creds.current();
    if (c == null) return false;

    final String result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'endDirectMessage',
        'deviceId': c.deviceId,
        'accessToken': Utilities.generateToken(
          c.userId,
          'hcapp_endDirectMessage',
          paramString: c.deviceSecret,
        ),
        'threadId': threadId,
      }),
      errorCallback: (_) async => true,
    );
    if (result.startsWith(ERROR_PREFIX)) return false;
    return _envelopeOk(result);
  }

  /// Mute (silent pushes) or unmute one thread. Returns the state the server
  /// now holds, or null when the call failed.
  static Future<bool?> setMute(HcId threadId, {required bool mute}) async {
    final _Creds? c = _Creds.current();
    if (c == null) return null;

    final String result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'setDirectMessageMute',
        'deviceId': c.deviceId,
        'accessToken': Utilities.generateToken(
          c.userId,
          'hcapp_setDirectMessageMute',
          paramString: c.deviceSecret,
        ),
        'threadId': threadId,
        'mute': mute ? 1 : 0,
      }),
      errorCallback: (_) async => true,
    );
    if (result.startsWith(ERROR_PREFIX)) return null;

    try {
      final List<dynamic> outer = jsonDecode(result) as List<dynamic>;
      if (!_envelopeOk(result) || outer.length < 2) return null;
      final Object? muted = firstRow(outer[1] as List<dynamic>?)?['Muted'];
      return muted == 1 || muted == true;
    } catch (e, s) {
      BootLogger.logError('[ERROR][DM]', 'mute reply unreadable: $e', s);
      return null;
    }
  }

  static bool _envelopeOk(String body) {
    try {
      final List<dynamic> outer = jsonDecode(body) as List<dynamic>;
      if (outer.isEmpty) return false;
      final Map<String, dynamic>? envelope = firstRow(
        outer[0] as List<dynamic>?,
      );
      return envelope?['success'] == 1 || envelope?['success'] == true;
    } catch (_) {
      return false;
    }
  }
}

String _nameOr(Object? raw) {
  final String s = '${raw ?? ''}'.trim();
  return s.isEmpty ? 'A hasher' : s;
}

/// A DATETIMEOFFSET arrives as an ISO string through the shim; a number
/// would be epoch milliseconds, the way chat timestamps travel.
DateTime? _dateOf(Object? raw) {
  if (raw == null) return null;
  if (raw is num) {
    return DateTime.fromMillisecondsSinceEpoch(raw.toInt(), isUtc: true);
  }
  return DateTime.tryParse(raw.toString());
}

/// The three things every app SP call needs, or null when this install is
/// not signed in — in which case there is nothing to ask the server.
class _Creds {
  const _Creds(this.userId, this.deviceId, this.deviceSecret);
  final String userId;
  final String deviceId;
  final String deviceSecret;

  static _Creds? current() {
    final String userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';
    if (userId.isEmpty || deviceId.isEmpty || deviceSecret.isEmpty) {
      return null;
    }
    return _Creds(userId, deviceId, deviceSecret);
  }
}
