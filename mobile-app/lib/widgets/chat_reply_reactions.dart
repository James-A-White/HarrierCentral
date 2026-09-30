import 'package:flutter_chat_core/flutter_chat_core.dart' as core;
import 'package:harrier_central/imports.dart';

/// The three pieces of chrome replies and reactions add to a chat page
/// (E9.F1.S21 / S22, 2026-09-30):
///
///  * [ChatReplyBar] — above the composer while a reply is being written:
///    "Replying to `<name>`", the quoted line, and an × that drops it without
///    losing what was typed.
///  * [ChatMessageDecor] — wraps a bubble: the quoted strip above it when the
///    message is a reply, the reaction chips under it when it has any.
///  * [ChatReactionPicker] — the six emoji in a row at the top of the
///    long-press sheet; the ones already mine are ringed.
///
/// Everything here reads the message's metadata (keys in
/// chat_reaction_service.dart); nothing calls the server — the chat
/// controller does, and repaints the message.

class ChatReplyBar extends StatelessWidget {
  const ChatReplyBar({
    required this.replyingTo,
    required this.authorName,
    required this.onCancel,
    super.key,
  });

  final Rxn<core.Message> replyingTo;
  final String Function(core.Message) authorName;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // The Rx read comes first, before any early return (obx_scan).
      final core.Message? m = replyingTo.value;
      if (m == null) return const SizedBox.shrink();
      final String snippet = chatMessageSnippet(m);
      return Container(
        margin: const EdgeInsets.fromLTRB(8, 6, 8, 0),
        padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF3F8),
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: hc_blue, width: 3)),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.reply, size: 18, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Replying to ${authorName(m)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    snippet,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              key: const Key('chat-reply-cancel'),
              icon: const Icon(Icons.close, size: 20, color: Colors.black54),
              onPressed: onCancel,
              tooltip: 'Cancel reply',
            ),
          ],
        ),
      );
    });
  }
}

/// The message's own one-line quote, from what the controller stored.
String chatMessageSnippet(core.Message m) {
  final Object? kind = m.metadata?['hcKind'];
  final Object? content = m.metadata?['hcContent'];
  final String text = content is String && content.isNotEmpty
      ? content
      : (m is core.TextMessage ? m.text : '');
  return chatQuoteSnippet(kind is int ? kind : ChatMessageKind.text, text);
}

class ChatMessageDecor extends StatelessWidget {
  const ChatMessageDecor({
    required this.message,
    required this.isSentByMe,
    required this.myId,
    required this.onToggleReaction,
    required this.child,
    super.key,
  });

  final core.Message message;
  final bool isSentByMe;

  /// The signed-in hasher's public id, lowercased — what the reaction
  /// lists hold.
  final String myId;
  final void Function(core.Message message, String code) onToggleReaction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? meta = message.metadata;
    final Object? replyTo = meta?[kChatReplyToKey];
    final Map<String, List<String>> reactions = _reactionsOf(meta);
    if ((replyTo == null || '$replyTo'.isEmpty) && reactions.isEmpty) {
      return child;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isSentByMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: <Widget>[
        if (replyTo != null && '$replyTo'.isNotEmpty)
          _QuoteStrip(meta: meta!, isSentByMe: isSentByMe),
        child,
        if (reactions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              alignment: isSentByMe ? WrapAlignment.end : WrapAlignment.start,
              children: <Widget>[
                for (final ChatReaction r in ChatReaction.all)
                  if ((reactions[r.code] ?? const <String>[]).isNotEmpty)
                    _ReactionChip(
                      reaction: r,
                      count: reactions[r.code]!.length,
                      mine: reactions[r.code]!.contains(myId),
                      onTap: () => onToggleReaction(message, r.code),
                    ),
              ],
            ),
          ),
      ],
    );
  }

  static Map<String, List<String>> _reactionsOf(Map<String, dynamic>? meta) {
    final Object? raw = meta?[kChatReactionsKey];
    if (raw is Map<String, List<String>>) return raw;
    if (raw is Map) {
      return <String, List<String>>{
        for (final MapEntry<dynamic, dynamic> e in raw.entries)
          if (e.key is String && e.value is List)
            e.key as String: (e.value as List).whereType<String>().toList(),
      };
    }
    return const <String, List<String>>{};
  }
}

class _QuoteStrip extends StatelessWidget {
  const _QuoteStrip({required this.meta, required this.isSentByMe});
  final Map<String, dynamic> meta;
  final bool isSentByMe;

  @override
  Widget build(BuildContext context) {
    final bool removed =
        meta[kChatReplyRemovedKey] == 1 || meta[kChatReplyRemovedKey] == true;
    final String author = (meta[kChatReplyAuthorKey] as String?)?.trim() ?? '';
    final Object? kindRaw = meta[kChatReplyKindKey];
    final int kind = kindRaw is int
        ? kindRaw
        : (kindRaw is num ? kindRaw.toInt() : ChatMessageKind.text);
    final String? text = meta[kChatReplyTextKey] as String?;
    final String snippet = removed || text == null
        ? 'Message deleted'
        : chatQuoteSnippet(kind, text);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Container(
        key: const Key('chat-quote-strip'),
        margin: EdgeInsets.only(
          bottom: 2,
          left: isSentByMe ? 0 : 2,
          right: isSentByMe ? 2 : 0,
        ),
        padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF3F8),
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: hc_blue, width: 3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (author.isNotEmpty)
              Text(
                author,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              snippet,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.black54,
                fontStyle: removed || text == null
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.reaction,
    required this.count,
    required this.mine,
    required this.onTap,
  });
  final ChatReaction reaction;
  final int count;
  final bool mine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('chat-reaction-chip-${reaction.code}'),
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFFDCEBFF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: mine ? hc_blue : Colors.black26,
            width: mine ? 1.5 : 1,
          ),
        ),
        child: Text(
          '${reaction.emoji} $count',
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
      ),
    );
  }
}

/// The six emoji across the top of the long-press sheet. Tapping one closes
/// the sheet with `react:<code>`, which the controller turns into a toggle.
class ChatReactionPicker extends StatelessWidget {
  const ChatReactionPicker({
    required this.mine,
    required this.onPick,
    super.key,
  });
  final Set<String> mine;
  final void Function(String code) onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          for (final ChatReaction r in ChatReaction.all)
            Semantics(
              button: true,
              label: r.label,
              child: InkWell(
                key: Key('chat-react-${r.code}'),
                borderRadius: BorderRadius.circular(24),
                onTap: () => onPick(r.code),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: mine.contains(r.code)
                        ? const Color(0xFFDCEBFF)
                        : Colors.transparent,
                    border: mine.contains(r.code)
                        ? Border.all(color: hc_blue, width: 1.5)
                        : null,
                  ),
                  child: Text(r.emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
