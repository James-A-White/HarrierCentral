import 'package:harrier_central/imports.dart';

/// How a hasher takes part in a room. Mirrors the values stored in
/// HC.EventMessageBadgeCounts.ParticipationState — keep the two in step.
const int kRoomParticipatePush = 0;
const int kRoomParticipateBadgesOnly = 1;
const int kRoomOptOut = 2;

/// One platform-wide chat room, exactly as the SERVER describes it.
///
/// Deliberately NOT an enum and not a hard-coded list. The rooms live in
/// HC6.ChatRoomCatalog() and arrive over the wire, so adding a room is a
/// stored-procedure deploy — no app build, no store review, and every phone
/// already installed picks it up on its next look (James, 2026-09-14: "make
/// it easy to extend to other rooms as well"). A hasher made an RA today sees
/// the RA room today.
class ChatRoom {
  const ChatRoom({
    required this.roomType,
    required this.roomName,
    required this.unreadCount,
    required this.participationState,
  });

  /// Matches HC.EventMessage.MessageType, so it is permanent once a room has
  /// traffic. The app never interprets it — it only hands it back.
  final int roomType;
  final String roomName;
  final int unreadCount;

  /// 0 participate with push · 1 participate, badges only · 2 opted out.
  /// Held as the server's number rather than an app-side enum for the same
  /// reason as [roomType]: the app does not need to interpret it to show it,
  /// and a fourth state would not need a build.
  final int participationState;

  bool get wantsPush => participationState == kRoomParticipatePush;
  bool get isOptedOut => participationState == kRoomOptOut;

  factory ChatRoom.fromJson(Map<String, dynamic> json) => ChatRoom(
    roomType: (json['roomType'] as num?)?.toInt() ?? 0,
    roomName: (json['roomName'] as String?) ?? '',
    unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    participationState:
        (json['participationState'] as num?)?.toInt() ?? kRoomParticipatePush,
  );
}

class ChatRoomService {
  const ChatRoomService();

  /// The rooms this hasher may enter, newest unread counts included.
  ///
  /// Returns null when the call FAILED, and an empty list when the hasher is
  /// simply in no rooms. The caller must tell those apart: most hashers hold
  /// no role at all, so empty is the ordinary answer and must not be dressed
  /// up as an error — while a failure must not be drawn as "you have no
  /// rooms", which is the same trap as flashing "No runs" during a load.
  /// [includeOptedOut] must be true for the settings console and false for
  /// the chat list. Opting out hides a room from the list, so without this
  /// the settings screen could not show it back — a one-way door.
  static Future<List<ChatRoom>?> fetchRooms({bool includeOptedOut = false}) async {
    final String userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';
    if (userId.isEmpty || deviceId.isEmpty) return null;

    final result = await ServiceCommon.sendHttpPost(() {
      // Minted inside the closure so a retry gets a fresh token.
      return jsonEncode(<String, dynamic>{
        'queryType': 'getChatRooms',
        'deviceId': deviceId,
        'includeOptedOut': includeOptedOut ? 1 : 0,
        'accessToken': Utilities.generateToken(
          userId,
          'hcapp_getChatRooms',
          paramString: deviceSecret,
        ),
      });
    });

    if (result.startsWith(ERROR_PREFIX)) return null;

    try {
      final outer = jsonDecode(result) as List<dynamic>;
      if (outer.isEmpty) return <ChatRoom>[];
      final rows = outer[0] as List<dynamic>;
      return rows
          .map((dynamic r) => ChatRoom.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Records how this hasher takes part in one room. Returns true on success.
  ///
  /// The server is the only store for this — there is no local mirror,
  /// because the setting has to reach the push sender, which is server-side.
  static Future<bool> setParticipation({
    required int roomType,
    required int participationState,
  }) async {
    final String userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';
    if (userId.isEmpty || deviceId.isEmpty) return false;

    final result = await ServiceCommon.sendHttpPost(() {
      return jsonEncode(<String, dynamic>{
        'queryType': 'setChatRoomParticipation',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          userId,
          'hcapp_setChatRoomParticipation',
          paramString: deviceSecret,
        ),
        'roomType': roomType,
        'participationState': participationState,
      });
    });

    if (result.startsWith(ERROR_PREFIX)) return false;
    try {
      final outer = jsonDecode(result) as List<dynamic>;
      if (outer.isEmpty) return false;
      final rows = outer[0] as List<dynamic>;
      if (rows.isEmpty) return false;
      final row = rows[0] as Map<String, dynamic>;
      return row['Success'] == 1 || row['Success'] == true;
    } catch (_) {
      return false;
    }
  }
}
