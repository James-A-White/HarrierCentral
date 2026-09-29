import 'package:harrier_central/imports.dart';

/// Blocking a hasher and reporting a message (E9.F1.S16 / S17, 2026-09-29).
///
/// A block is the hasher's OWN tool and lives entirely on the server: every
/// chat reader leaves out a blocked hasher's messages, no push from them
/// reaches this hasher's devices, and the unread counts skip them. The
/// blocked hasher is told nothing. Nothing is mirrored locally — the app
/// asks the server for the list and repaints from what it hands back.
///
/// A report is a letterbox: the message goes to Harrier Central's reviewers
/// by email, and nothing is hidden or removed by it. Block is the tool for
/// that.

/// One hasher this hasher has blocked, as hcapp_getBlockedHashers lists them.
class BlockedHasher {
  const BlockedHasher({
    required this.publicHasherId,
    required this.displayName,
    this.photo,
    this.blockedAt,
  });

  /// The PUBLIC id — what a chat message carries as its authorId — never the
  /// internal HC.Hasher.id. SQL sends it UPPERCASE; [HcId] lowercases it so
  /// it compares with the ids on a chat screen.
  final HcId publicHasherId;
  final String displayName;

  /// HC.Hasher.Photo: a URL, a `bundle://` avatar, or nothing. Always drawn
  /// through avatarImageProvider (hc-avatars skill).
  final String? photo;
  final DateTime? blockedAt;

  factory BlockedHasher.fromJson(Map<String, dynamic> json) => BlockedHasher(
    publicHasherId: HcId(json['PublicHasherId'] as String?),
    displayName: (json['DisplayName'] as String?) ?? 'A hasher',
    photo: json['Photo'] as String?,
    blockedAt: _dateOf(json['BlockedAt']),
  );

  /// A DATETIMEOFFSET arrives as an ISO string through the shim; a number
  /// would be epoch milliseconds, the way chat timestamps travel.
  static DateTime? _dateOf(Object? raw) {
    if (raw == null) return null;
    if (raw is num) {
      return DateTime.fromMillisecondsSinceEpoch(raw.toInt(), isUtc: true);
    }
    return DateTime.tryParse(raw.toString());
  }
}

/// What setHasherBlock came back with: the caller's blocked list on
/// success, or the server's own reason when it refused.
class BlockOutcome {
  const BlockOutcome.ok(List<BlockedHasher> this.blocked) : refusal = null;
  const BlockOutcome.failed([this.refusal]) : blocked = null;

  final List<BlockedHasher>? blocked;

  /// The server's errorUserMessage ("You cannot block yourself."), or null
  /// when the call never got an answer.
  final String? refusal;

  bool get ok => blocked != null;
}

class ReportOutcome {
  const ReportOutcome.ok() : ok = true, refusal = null;
  const ReportOutcome.failed([this.refusal]) : ok = false;

  final bool ok;
  final String? refusal;
}

class HasherBlockService {
  const HasherBlockService();

  /// Everyone this hasher has blocked, newest first. Null when the call
  /// FAILED; an empty list is the ordinary answer and is not an error.
  static Future<List<BlockedHasher>?> fetchBlocked() async {
    final _Creds? c = _Creds.current();
    if (c == null) return null;

    final String result = await ServiceCommon.sendHttpPost(() {
      return jsonEncode(<String, dynamic>{
        'queryType': 'getBlockedHashers',
        'deviceId': c.deviceId,
        'accessToken': Utilities.generateToken(
          c.userId,
          'hcapp_getBlockedHashers',
          paramString: c.deviceSecret,
        ),
      });
    });
    if (result.startsWith(ERROR_PREFIX)) return null;

    try {
      final List<dynamic> outer = jsonDecode(result) as List<dynamic>;
      if (outer.isEmpty) return <BlockedHasher>[];
      return parseBlockedRows(outer[0]);
    } catch (e, s) {
      BootLogger.logError('[ERROR][CHAT]', 'blocked list failed: $e', s);
      return null;
    }
  }

  /// Block ([blocked] true) or unblock one hasher by their PUBLIC id.
  ///
  /// The SP's refusal — not found, yourself — comes back as the outcome's
  /// [BlockOutcome.refusal] rather than the generic error dialog, so the
  /// chat can show it in a toast under the message that was long-pressed.
  static Future<BlockOutcome> setBlock(
    HcId targetPublicHasherId, {
    required bool blocked,
  }) async {
    final _Creds? c = _Creds.current();
    if (c == null) return const BlockOutcome.failed();

    String? refusal;
    final String result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'setHasherBlock',
        'deviceId': c.deviceId,
        'accessToken': Utilities.generateToken(
          c.userId,
          'hcapp_setHasherBlock',
          paramString: c.deviceSecret,
        ),
        'targetPublicHasherId': targetPublicHasherId,
        'blocked': blocked ? 1 : 0,
      }),
      errorCallback: (DbErrorModel e) async {
        refusal = e.errorUserMessage;
        return true;
      },
    );
    if (result.startsWith(ERROR_PREFIX)) return BlockOutcome.failed(refusal);

    final List<BlockedHasher>? list = parseBlockedReply(result);
    return list == null ? BlockOutcome.failed(refusal) : BlockOutcome.ok(list);
  }

  /// The blocked list from a setHasherBlock reply: rowset 0 is the success
  /// envelope and never business data; the list is rowset 1. Null when the
  /// envelope says the write did not happen, or the reply is not one.
  static List<BlockedHasher>? parseBlockedReply(String body) {
    try {
      final List<dynamic> outer = jsonDecode(body) as List<dynamic>;
      if (outer.isEmpty) return null;
      final Map<String, dynamic>? envelope = firstRow(
        outer[0] as List<dynamic>?,
      );
      final bool ok =
          envelope?['success'] == 1 || envelope?['success'] == true;
      if (!ok) return null;
      if (outer.length < 2) return <BlockedHasher>[];
      return parseBlockedRows(outer[1]);
    } catch (e, s) {
      BootLogger.logError('[ERROR][CHAT]', 'block reply unreadable: $e', s);
      return null;
    }
  }

  static List<BlockedHasher> parseBlockedRows(dynamic rowset) {
    if (rowset is! List) return <BlockedHasher>[];
    return rowset
        .whereType<Map<String, dynamic>>()
        .map(BlockedHasher.fromJson)
        .where((BlockedHasher h) => h.publicHasherId.isValid)
        .toList();
  }
}

/// hcapp_reportChatMessage's reason is optional and capped at 1,000
/// characters; the composer stops at the same number so the server's
/// refusal is a backstop, never something a hasher meets.
const int kChatReportReasonMaxLength = 1000;

class ChatReportService {
  const ChatReportService();

  /// Send one message to the reviewers. Reporting the same message twice is
  /// a success on the server (it sends nothing new), so the caller can say
  /// "thank you" either way.
  static Future<ReportOutcome> report(HcId messageId, {String? reason}) async {
    final _Creds? c = _Creds.current();
    if (c == null) return const ReportOutcome.failed();

    final String trimmed = (reason ?? '').trim();
    String? refusal;
    final String result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'reportChatMessage',
        'deviceId': c.deviceId,
        'accessToken': Utilities.generateToken(
          c.userId,
          'hcapp_reportChatMessage',
          paramString: c.deviceSecret,
        ),
        'messageId': messageId,
        // The SP's parameter is NVARCHAR(MAX) with a LEN() check, so an
        // over-long reason is refused rather than cut; the sheet already
        // stops at the cap.
        if (trimmed.isNotEmpty) 'reason': trimmed,
      }),
      errorCallback: (DbErrorModel e) async {
        refusal = e.errorUserMessage;
        return true;
      },
    );
    if (result.startsWith(ERROR_PREFIX)) return ReportOutcome.failed(refusal);

    try {
      final List<dynamic> outer = jsonDecode(result) as List<dynamic>;
      final Map<String, dynamic>? envelope = outer.isEmpty
          ? null
          : firstRow(outer[0] as List<dynamic>?);
      final bool ok =
          envelope?['success'] == 1 || envelope?['success'] == true;
      return ok ? const ReportOutcome.ok() : ReportOutcome.failed(refusal);
    } catch (e, s) {
      BootLogger.logError('[ERROR][CHAT]', 'report reply unreadable: $e', s);
      return ReportOutcome.failed(refusal);
    }
  }
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
