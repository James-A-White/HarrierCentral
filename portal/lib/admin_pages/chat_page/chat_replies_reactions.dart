// Chat replies and emoji reactions (E9.F1.S21 / S22, 2026-09-30).
//
// The server holds a reply as HC.EventMessage.ReplyToMessageId and hands the
// reader a quote of the original (author, text, kind, whether it is gone),
// so a client never needs the original in memory to draw the strip.
// Reactions live in ReactionsJson, `{"beer":["<PUBLICHASHERID>", …]}`, keyed
// by a CODE and never by the emoji itself: in the database's collation a
// surrogate pair compares equal to '' (2026-09-19), so an emoji is not a safe
// key. The palette is fixed — six codes — and each client draws the glyph.
import 'dart:convert';

import 'package:hcportal/util/uuid_utils.dart';

/// Metadata keys a message carries its reply quote and reactions under.
const String chatMetaReplyTo = 'hcReplyTo';
const String chatMetaReplyText = 'hcReplyText';
const String chatMetaReplyKind = 'hcReplyKind';
const String chatMetaReplyAuthor = 'hcReplyAuthor';
const String chatMetaReplyRemoved = 'hcReplyRemoved';
const String chatMetaReactions = 'hcReactions';

/// One reaction the palette offers: its server code and the glyph drawn.
class ChatReaction {
  const ChatReaction(this.code, this.emoji);
  final String code;
  final String emoji;
}

/// The fixed six, in display order. Codes are what the SP accepts.
const List<ChatReaction> chatReactionPalette = <ChatReaction>[
  ChatReaction('thumbs', '👍'),
  ChatReaction('heart', '❤️'),
  ChatReaction('laugh', '😂'),
  ChatReaction('beer', '🍺'),
  ChatReaction('run', '🏃'),
  ChatReaction('fire', '🔥'),
];

String chatReactionEmoji(String code) => chatReactionPalette
    .firstWhere((r) => r.code == code, orElse: () => ChatReaction(code, code))
    .emoji;

/// `{"beer":["ID", …]}` → `{beer: [id, …]}` with lowercased ids. An unreadable
/// or empty value is an empty map, never a throw: a reaction must not be able
/// to break a chat that was fine before it.
Map<String, List<String>> parseChatReactions(Object? raw) {
  final out = <String, List<String>>{};
  if (raw == null) return out;
  Object? decoded = raw;
  if (raw is String) {
    if (raw.trim().isEmpty) return out;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return out;
    }
  }
  if (decoded is! Map) return out;
  for (final entry in decoded.entries) {
    final v = entry.value;
    if (v is! List) continue;
    final ids = v.whereType<String>().map((s) => s.asUuid).toList();
    if (ids.isNotEmpty) out[entry.key.toString()] = ids;
  }
  return out;
}

/// The reactions a message carries, from its metadata.
Map<String, List<String>> chatReactionsOf(Map<String, dynamic>? meta) {
  final raw = meta?[chatMetaReactions];
  if (raw is Map<String, List<String>>) return raw;
  if (raw is Map) {
    return <String, List<String>>{
      for (final e in raw.entries)
        if (e.value is List)
          e.key.toString(): (e.value as List).whereType<String>().toList(),
    };
  }
  return parseChatReactions(raw);
}

/// Which line the quote strip shows for the original (text, "📷 Photo",
/// "📍 Location") — null when the original has been deleted.
String? chatReplySnippet(Map<String, dynamic>? meta) {
  if (meta == null || meta[chatMetaReplyTo] == null) return null;
  if (meta[chatMetaReplyRemoved] == true) return null;
  final kind = (meta[chatMetaReplyKind] as num?)?.toInt() ?? 0;
  if (kind == 1) return '📷 Photo';
  if (kind == 2) return '📍 Location';
  final text = (meta[chatMetaReplyText] as String?) ?? '';
  return text;
}
