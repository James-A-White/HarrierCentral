import 'package:flutter_chat_core/flutter_chat_core.dart' as core;
import 'package:intl/intl.dart';
import 'package:hcportal/admin_pages/chat_page/chat_message_kinds.dart';
import 'package:hcportal/admin_pages/chat_page/chat_replies_reactions.dart';
import 'package:hcportal/imports.dart';

class ChatSheetPage extends StatelessWidget {
  ChatSheetPage({
    required this.publicEventId,
    required this.messageTitle,
    required this.eventName,
    this.runLat,
    this.runLng,
    super.key,
  });

  final String publicEventId;
  final String messageTitle;
  final String eventName;

  /// The run's location — where "Drop a pin" opens. Optional.
  final double? runLat;
  final double? runLng;

  late final ChatSheetController chatSheetController = Get.put(
    ChatSheetController(
      publicEventId: publicEventId,
      messageTitle: messageTitle,
      runLat: runLat,
      runLng: runLng,
    ),
  );

  static final _chatTheme = () {
    final base = core.ChatTheme.light();
    return base.copyWith(
      colors: base.colors.copyWith(
        primary: const Color(0xFF1D4ED8), // sent bubble — portal blue-700
        onPrimary: Colors.white,
        surfaceContainer: const Color(
          0xFFE2E8F0,
        ), // received bubble — slate-200
        surfaceContainerHigh: const Color(0xFFCBD5E1),
        onSurface: const Color(0xFF1E293B), // text — slate-800
      ),
      shape: const BorderRadius.all(Radius.circular(18)),
    );
  }();

  static final _timeFormat = DateFormat('HH:mm');

  // Avatar diameter + right margin = total leading slot width.
  static const double _avatarSize = 34;
  static const double _avatarMargin = 6;
  static const double _leadingSlot = _avatarSize + _avatarMargin;
  // ChatMessage.horizontalPadding (8) + leading slot — aligns name with bubble.
  static const double _nameLeftPad = 8 + _leadingSlot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$eventName Trail Chat'),
        leading: GestureDetector(
          onTap: Get.back<void>,
          child: const Icon(
            MaterialCommunityIcons.arrow_left,
            color: Colors.black,
          ),
        ),
        actions: const [],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Obx(
            () => chatSheetController.isUploading.value
                ? const LinearProgressIndicator(minHeight: 3)
                : const SizedBox(height: 3),
          ),
        ),
      ),
      body: Chat(
        currentUserId: chatSheetController.currentUser.id,
        resolveUser: chatSheetController.resolveUser,
        chatController: chatSheetController.chatController,
        onMessageSend: chatSheetController.handleSendPressed,
        onAttachmentTap: chatSheetController.handleAttachmentPressed,
        onMessageTap: chatSheetController.handleMessageTap,
        onMessageLongPress:
            (context, message, {required index, required details}) => unawaited(
              chatSheetController.showMessageMenu(
                context,
                message,
                details.globalPosition,
              ),
            ),
        theme: _chatTheme,
        timeFormat: _timeFormat,
        builders: core.Builders(
          // Hard cap at HC.EventMessage.MessageContent's width (4,000); the SP
          // refuses more, this keeps a long message in the box instead.
          // A reply shows who and what is being answered above the box, with
          // an × to drop it (E9.F1.S21). The Rx is read before anything
          // else so the Obx always tracks it.
          // The reply bar rides in the Composer's own topWidget slot. NEVER
          // wrap the Composer: it returns a Positioned that must sit directly
          // in the chat's Stack (738 wrapped it in a Column: grey screen).
          composerBuilder: (BuildContext context) => Obx(() {
            final core.Message? target = chatSheetController.replyingTo.value;
            return Composer(
              maxLength: 4000,
              topWidget: target == null ? null : _replyBar(target),
            );
          }),
          // Photo (kind 1) and location (kind 2) — E9.F1.S11/S12.
          imageMessageBuilder:
              (context, message, index, {required isSentByMe, groupStatus}) =>
                  _photoBubble(message, isSentByMe: isSentByMe),
          customMessageBuilder:
              (context, message, index, {required isSentByMe, groupStatus}) =>
                  _locationBubble(message, isSentByMe: isSentByMe),
          chatMessageBuilder:
              (
                context,
                message,
                index,
                animation,
                child, {
                isRemoved,
                required isSentByMe,
                groupStatus,
              }) {
                // A "group start" is either a standalone message or the first in
                // a consecutive run from the same sender.
                final isGroupStart = groupStatus == null || groupStatus.isFirst;
                // A "group end" is either standalone or the last in the run —
                // this is where we anchor the avatar (WhatsApp style).
                final isGroupEnd = groupStatus == null || groupStatus.isLast;

                final menu = _menuButton(message);
                return MouseRegion(
                  onEnter: (_) =>
                      chatSheetController.hoveredId.value = message.id,
                  onExit: (_) {
                    if (chatSheetController.hoveredId.value == message.id) {
                      chatSheetController.hoveredId.value = null;
                    }
                  },
                  child: ChatMessage(
                    message: message,
                    index: index,
                    animation: animation,
                    isRemoved: isRemoved,
                    groupStatus: groupStatus,
                    // Avatar anchored to the bottom of each received group.
                    // A fixed-width spacer keeps bubbles aligned for non-end messages.
                    // Sent: the hover menu (Copy / Delete) sits to the left
                    // of the bubble, away from the edge.
                    leadingWidget: isSentByMe
                        ? menu
                        : isGroupEnd
                        ? Padding(
                            padding: const EdgeInsets.only(
                              right: _avatarMargin,
                            ),
                            child: Avatar(
                              userId: message.authorId,
                              size: _avatarSize,
                            ),
                          )
                        : const SizedBox(width: _leadingSlot),
                    // Sender name shown once above the first bubble of each group.
                    headerWidget: !isSentByMe && isGroupStart
                        ? Padding(
                            padding: const EdgeInsets.only(
                              left: _nameLeftPad,
                              bottom: 2,
                            ),
                            child: Username(userId: message.authorId),
                          )
                        : null,
                    // Received: the hover menu sits to the right of the bubble.
                    trailingWidget: isSentByMe ? null : menu,
                    // The quote strip and the reaction chips wrap the bubble
                    // itself, so they stay aligned with it rather than with
                    // the avatar / menu column (E9.F1.S21/S22).
                    child: _decorated(message, child, isSentByMe: isSentByMe),
                  ),
                );
              },
        ),
      ),
    );
  }

  // ── Replies and reactions (E9.F1.S21/S22) ────────────────────────────────

  static const Color _slate = Color(0xFF475569);
  static const Color _blue = Color(0xFF1D4ED8);

  /// The bubble with, when it has them, the reply quote above and the
  /// reaction chips below.
  Widget _decorated(
    core.Message message,
    Widget bubble, {
    required bool isSentByMe,
  }) {
    final meta = message.metadata;
    final bool isReply = meta?[chatMetaReplyTo] != null;
    final reactions = chatReactionsOf(meta);
    if (!isReply && reactions.isEmpty) return bubble;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isSentByMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (isReply) _quoteStrip(message, isSentByMe: isSentByMe),
        bubble,
        if (reactions.isNotEmpty) _reactionChips(message, reactions),
      ],
    );
  }

  /// "↳ Author · one line of what they said" over a reply, as every
  /// messenger draws it: a bar down the left, the name bold and small.
  Widget _quoteStrip(core.Message message, {required bool isSentByMe}) {
    final String? snippet = chatReplySnippet(message.metadata);
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        borderRadius: BorderRadius.all(Radius.circular(10)),
        border: Border(left: BorderSide(color: _blue, width: 3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chatSheetController.replyAuthorNameOf(message),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _blue,
            ),
          ),
          Text(
            snippet ?? 'Message deleted',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: _slate,
              fontStyle: snippet == null ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// `🍺 3` per code, mine outlined in blue; a click toggles my own.
  Widget _reactionChips(
    core.Message message,
    Map<String, List<String>> reactions,
  ) {
    final mine = chatSheetController.myReactionCodes(message);
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final r in chatReactionPalette)
            if ((reactions[r.code]?.isNotEmpty ?? false))
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => unawaited(
                  chatSheetController.toggleReaction(message, r.code),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: mine.contains(r.code)
                        ? const Color(0xFFDBEAFE)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: mine.contains(r.code)
                          ? _blue
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Text(
                    '${r.emoji} ${reactions[r.code]!.length}',
                    style: const TextStyle(fontSize: 13, color: _slate),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  /// Above the composer while a reply is being written: who and what, and
  /// an × that drops the reply without losing the typed text.
  Widget _replyBar(core.Message target) {
    final String? snippet = chatReplySnippet(
      chatSheetController.replyQuoteOf(target),
    );
    final String author =
        (chatSheetController.replyQuoteOf(target)[chatMetaReplyAuthor]
            as String?) ??
        'A hasher';
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                borderRadius: BorderRadius.all(Radius.circular(10)),
                border: Border(left: BorderSide(color: _blue, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Replying to $author',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _blue,
                    ),
                  ),
                  Text(
                    snippet ?? 'Message deleted',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: _slate,
                      fontStyle: snippet == null
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cancel reply',
            icon: const Icon(Icons.close, size: 20, color: _slate),
            onPressed: () => chatSheetController.replyingTo.value = null,
          ),
        ],
      ),
    );
  }

  // ── Message menu (E9.F1.S13-S15) ─────────────────────────────────────────

  /// A ⋮ button that shows while the mouse is over its message. It keeps its
  /// space when hidden so the bubble does not jump.
  Widget _menuButton(core.Message message) => Obx(
    () => Visibility(
      visible: chatSheetController.hoveredId.value == message.id,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: PopupMenuButton<String>(
        tooltip: 'Message options',
        icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF64748B)),
        padding: EdgeInsets.zero,
        itemBuilder: (_) => chatSheetController.menuItemsFor(message),
        onSelected: (choice) =>
            unawaited(chatSheetController.onMenuSelected(choice, message)),
      ),
    ),
  );

  // ── Photo and location bubbles ───────────────────────────────────────────

  static const double _photoMaxWidth = 280;
  static const double _photoMaxHeight = 320;

  /// The photo whole, at its own aspect ratio (BoxFit.contain) — never
  /// cropped. Click opens the carousel (handleMessageTap).
  Widget _photoBubble(core.ImageMessage message, {required bool isSentByMe}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: _photoMaxWidth,
              maxHeight: _photoMaxHeight,
            ),
            child: Image.network(
              message.source,
              fit: BoxFit.contain,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : const SizedBox(
                      width: 160,
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    ),
              errorBuilder: (_, _, _) => Container(
                width: 160,
                height: 80,
                alignment: Alignment.center,
                color: const Color(0xFFE2E8F0),
                child: const Text(
                  'Photo unavailable',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF475569)),
                ),
              ),
            ),
          ),
          _statusBadge(message.status),
        ],
      ),
    );
  }

  /// Pin, "Location", the coordinates. Click opens the map in a new tab.
  Widget _locationBubble(
    core.CustomMessage message, {
    required bool isSentByMe,
  }) {
    final meta = message.metadata ?? const <String, dynamic>{};
    if (meta[chatMetaKind] != chatMetaLocation) {
      return const SizedBox.shrink();
    }
    final lat = (meta[chatMetaLat] as num).toDouble();
    final lng = (meta[chatMetaLng] as num).toDouble();
    final fg = isSentByMe ? Colors.white : const Color(0xFF1E293B);
    final sub = isSentByMe ? Colors.white70 : const Color(0xFF475569);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSentByMe
                  ? const Color(0xFF1D4ED8)
                  : const Color(0xFFE2E8F0),
              borderRadius: const BorderRadius.all(Radius.circular(18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.place,
                  color: isSentByMe ? Colors.white : const Color(0xFFB91C1C),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location',
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        chatLocationLabel(lat, lng),
                        style: TextStyle(color: sub, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.open_in_new, size: 16, color: sub),
              ],
            ),
          ),
          _statusBadge(message.status),
        ],
      ),
    );
  }

  /// Sending spinner / failed mark over a photo or location bubble (text
  /// bubbles draw their own).
  Widget _statusBadge(core.MessageStatus? status) => switch (status) {
    core.MessageStatus.sending => const Positioned(
      right: 6,
      bottom: 6,
      child: SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
    core.MessageStatus.error => const Positioned(
      right: 6,
      bottom: 6,
      child: Tooltip(
        message: 'Not sent',
        child: Icon(Icons.error, size: 18, color: Color(0xFFB91C1C)),
      ),
    ),
    _ => const SizedBox.shrink(),
  };
}
