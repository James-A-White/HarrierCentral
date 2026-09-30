import 'package:harrier_central/imports.dart';

/// Emoji reactions on chat messages (E9.F1.S22, James 2026-09-30) and the
/// quoted-reply fields that ride on the same message rows (E9.F1.S21).
///
/// A reaction is STORED by its code and DRAWN here: in the database's
/// collation an emoji compares equal to '' (memory sql-collation-emoji-
/// blank), so the server keys `HC.EventMessage.ReactionsJson` on ASCII words
/// from `HC6.ChatReactionCatalog()` — `{"beer":["<PublicHasherId>",…]}` —
/// and this list is the same six in the same order. A code this build does
/// not know draws nothing rather than a hole. "The fixed six for now, we
/// might add more later" — a seventh is a row on the server AND a line here.
class ChatReaction {
  const ChatReaction(this.code, this.emoji, this.label);
  final String code;
  final String emoji;
  final String label;

  static const List<ChatReaction> all = <ChatReaction>[
    ChatReaction('thumbs', '👍', 'Thumbs up'),
    ChatReaction('heart', '❤️', 'Love'),
    ChatReaction('laugh', '😂', 'Laugh'),
    ChatReaction('beer', '🍺', 'Beer'),
    ChatReaction('run', '🏃', 'Run'),
    ChatReaction('fire', '🔥', 'Fire'),
  ];

  static ChatReaction? byCode(String code) =>
      all.where((ChatReaction r) => r.code == code).firstOrNull;

  static bool isKnown(String code) => byCode(code) != null;
}

/// The message-metadata keys the chat page carries these on. Public because
/// the bubble decorations read them; written only by the chat controller.
const String kChatReplyToKey = 'hcReplyTo';
const String kChatReplyTextKey = 'hcReplyText';
const String kChatReplyKindKey = 'hcReplyKind';
const String kChatReplyAuthorKey = 'hcReplyAuthor';
const String kChatReplyRemovedKey = 'hcReplyRemoved';
const String kChatReactionsKey = 'hcReactions';

/// `{"beer":["ID",…]}` → `{beer: [id, …]}` with every id lowercased so a
/// plain `==` against the chat's authorIds is right (CLAUDE.md: ids are
/// lowercase everywhere). Tolerant: null, '', or junk → empty; unknown
/// codes are kept (a newer server may know more than this build).
Map<String, List<String>> parseChatReactions(Object? raw) {
  if (raw == null) return <String, List<String>>{};
  Object? decoded = raw;
  if (raw is String) {
    if (raw.trim().isEmpty) return <String, List<String>>{};
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return <String, List<String>>{};
    }
  }
  if (decoded is! Map) return <String, List<String>>{};
  final Map<String, List<String>> out = <String, List<String>>{};
  decoded.forEach((Object? k, Object? v) {
    if (k is! String || v is! List) return;
    final List<String> ids = v
        .whereType<String>()
        .map((String s) => s.toLowerCase())
        .toList(growable: false);
    if (ids.isNotEmpty) out[k] = ids;
  });
  return out;
}

/// The one-line quote of a message: its text, or what a photo or location
/// is. Null for a deleted original — the strip says "Message deleted".
String chatQuoteSnippet(int kind, String? text) {
  if (kind == ChatMessageKind.photo) return '📷 Photo';
  if (kind == ChatMessageKind.location) return '📍 Location';
  return (text ?? '').trim();
}

/// What a reaction call came back with: the message's reactions after the
/// change on success, or the server's own reason when it refused.
class ReactionOutcome {
  const ReactionOutcome.ok(Map<String, List<String>> this.reactions)
    : refusal = null;
  const ReactionOutcome.failed([this.refusal]) : reactions = null;
  final Map<String, List<String>>? reactions;
  final String? refusal;
  bool get ok => reactions != null;
}

class ChatReactionService {
  const ChatReactionService();

  /// Add ([on] true) or remove the signed-in hasher's [code] reaction on
  /// [messageId], through hcapp_reactToChatMessage. A refusal ("You can't
  /// react in that chat") comes back as [ReactionOutcome.refusal] rather
  /// than the generic error dialog, so the chat can toast it and put the
  /// chip back.
  static Future<ReactionOutcome> react(
    HcId messageId,
    String code, {
    required bool on,
  }) async {
    final String userId = getStringPref(StringPrefsEnum.userId) ?? '';
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';
    if (userId.isEmpty || deviceId.isEmpty) {
      return const ReactionOutcome.failed();
    }

    String? refusal;
    final String result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'reactToChatMessage',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          userId,
          'hcapp_reactToChatMessage',
          paramString: deviceSecret,
        ),
        'messageId': messageId,
        'reaction': code,
        'on': on ? 1 : 0,
      }),
      errorCallback: (DbErrorModel e) async {
        refusal = e.errorUserMessage;
        return true;
      },
    );
    if (result.startsWith(ERROR_PREFIX)) return ReactionOutcome.failed(refusal);

    try {
      final List<dynamic> outer = jsonDecode(result) as List<dynamic>;
      final Map<String, dynamic>? row = outer.isEmpty
          ? null
          : firstRow(outer[0] as List<dynamic>?);
      if (row == null || row['success'] != 1) {
        return ReactionOutcome.failed(refusal);
      }
      return ReactionOutcome.ok(parseChatReactions(row['reactions']));
    } catch (e, s) {
      BootLogger.logError('[ERROR][CHAT]', 'reaction reply failed: $e', s);
      return ReactionOutcome.failed(refusal);
    }
  }
}
