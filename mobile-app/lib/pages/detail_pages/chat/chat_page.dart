import 'package:flutter_chat_core/flutter_chat_core.dart' as core;
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:harrier_central/imports.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({
    required this.eventId,
    required this.publicEventId,
    this.isKennelThread = false,
    this.roomType,
    this.threadId,
    this.dmState,
    super.key,
  });

  /// A platform-wide room from HC6.ChatRoomCatalog(). Belongs to no kennel
  /// and no run, so [eventId] and [publicEventId] are both empty for it, and
  /// [roomType] is the server's id for the room.
  factory ChatPage.room({required int roomType, Key? key}) =>
      ChatPage(eventId: '', publicEventId: '', roomType: roomType, key: key);

  /// A direct message thread (E9.F1.S7): named by its ThreadId alone, with
  /// the other party's name and photo carried in [dmState] so the first
  /// paint has them before the server answers.
  factory ChatPage.dm({required DmThreadState state, Key? key}) => ChatPage(
    eventId: '',
    publicEventId: '',
    threadId: state.threadId,
    dmState: state,
    key: key,
  );

  /// Kennel thread: [eventId]=kennelId, [publicEventId]=publicKennelId.
  final String eventId;
  final String publicEventId;
  final bool isKennelThread;
  final int? roomType;
  final HcId? threadId;
  final DmThreadState? dmState;

  static final _chatTheme = () {
    final base = core.ChatTheme.light();
    return base.copyWith(
      colors: base.colors.copyWith(
        primary: hc_blue,
        onPrimary: Colors.white,
        surfaceContainer: const Color(0xFFE2E8F0),
        surfaceContainerHigh: const Color(0xFFCBD5E1),
        onSurface: const Color(0xFF1E293B),
      ),
      shape: const BorderRadius.all(Radius.circular(18)),
      // Bigger text throughout (James, 2026-09-15). ChatTypography.standard
      // is 16/14/12 for body and 14/12/10 for labels — fine on a desk, small
      // on a phone held at arm's length after a run. Each step up by 3, which
      // keeps the relative scale the layout is built around rather than
      // enlarging one line and leaving the rest behind.
      typography: base.typography.copyWith(
        bodyLarge: base.typography.bodyLarge.copyWith(fontSize: 19),
        bodyMedium: base.typography.bodyMedium.copyWith(fontSize: 17),
        bodySmall: base.typography.bodySmall.copyWith(fontSize: 15),
        labelLarge: base.typography.labelLarge.copyWith(fontSize: 17),
        labelMedium: base.typography.labelMedium.copyWith(fontSize: 15),
        labelSmall: base.typography.labelSmall.copyWith(fontSize: 13),
      ),
    );
  }();

  static final _timeFormat = DateFormat('HH:mm');

  static const double _avatarSize = 32;
  static const double _avatarMargin = 6;
  static const double _leadingSlot = _avatarSize + _avatarMargin;
  static const double _nameLeftPad = 8 + _leadingSlot;

  @override
  Widget build(BuildContext context) {
    // Each chat page OWNS its controller (2026-09-28). It used to be one
    // untagged Get.put shared by every chat page in the app — run, kennel,
    // room and the live-run tab — so closing any of them (or a run page,
    // whose controller deleted "the" chat controller) disposed the chat
    // still on screen, and every send from it threw "Cannot add new events
    // after calling close" (James, 1419). global: false keeps it out of the
    // registry; the dispose hook closes it with this page and no other —
    // GetBuilder does not close a non-global controller by itself. The key
    // is the thread: a ChatPage rebuilt in the same slot for a DIFFERENT
    // thread gets a new controller rather than inheriting the old one.
    return GetBuilder<ChatPageController>(
      key: ValueKey<String>(
        '$eventId|$publicEventId|$isKennelThread|$roomType|$threadId',
      ),
      init: ChatPageController(
        eventId: eventId,
        publicEventId: publicEventId,
        isKennelThread: isKennelThread,
        roomType: roomType,
        threadId: threadId,
        dmState: dmState,
      ),
      global: false,
      dispose: (state) => state.controller?.onDelete(),
      builder: (controller) => _chat(controller),
    );
  }

  Widget _chat(ChatPageController controller) {
    final DmThreadState? dm = dmState;
    return Chat(
      currentUserId: controller.currentUser.id,
      resolveUser: controller.resolveUser,
      chatController: controller.chatController,
      onMessageSend: controller.handleSendPressed,
      onAttachmentTap: controller.handleAttachmentPressed,
      // Tap: a photo opens the carousel, a location the map app. Long press:
      // Copy, and Delete where allowed (E9.F1.S11-S15).
      onMessageTap: controller.handleMessageTap,
      onMessageLongPress: controller.handleMessageLongPress,
      theme: _chatTheme,
      timeFormat: _timeFormat,
      builders: core.Builders(
        // A spinner until the first fetch has answered; the package's own
        // 'No messages yet' only once we know the chat is empty.
        emptyChatListBuilder: (BuildContext context) => Obx(() {
          final bool loaded = controller.initialLoadDone.value;
          if (!loaded) {
            return const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            );
          }
          return Center(
            child: Text(
              'No messages yet',
              style: _chatTheme.typography.bodyLarge.copyWith(
                color: _chatTheme.colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }),
        // The stock Composer with one addition: a hard cap at the column
        // width, so a long message is stopped in the box rather than cut on
        // the server (or refused by it). A DM whose sending is refused — the
        // other side ended it, or somebody blocks — shows why instead.
        // The reply bar sits above the stock composer while a reply is
        // being written (E9.F1.S21); the composer itself is as before.
        composerBuilder: (BuildContext context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ChatReplyBar(
              replyingTo: controller.replyingTo,
              authorName: controller.replyAuthorName,
              onCancel: controller.cancelReply,
            ),
            dm == null
                ? Composer(
                    maxLength: kChatMessageMaxLength,
                    // Purple, not the theme's blue, once there is something to
                    // send (James, 2026-09-29); greyed while the field is empty.
                    sendIconColor: themeAppBarBackground,
                  )
                : Obx(() {
                    // Both Rx reads come first, before the branch (obx_scan).
                    final bool canSend = dm.canSend.value;
                    final String name = dm.otherDisplayName.value;
                    if (canSend) {
                      return Composer(
                        maxLength: kChatMessageMaxLength,
                        // Purple, not the theme's blue, once there is something to
                        // send (James, 2026-09-29); greyed while the field is empty.
                        sendIconColor: themeAppBarBackground,
                      );
                    }
                    return _CannotMessageBar(name: name);
                  }),
          ],
        ),
        // Links in a bubble are tappable, and a hashruns.org run link opens
        // the run IN the app. The stock bubble renders plain text — there is
        // no url_launcher anywhere in flutter_chat_ui 2.11 — and even if it
        // launched, iOS never routes a universal link back into the app that
        // owns the domain: it opens Safari. So in-app links go through
        // DeepLinkService directly (James, 2026-09-15: "links in the chat
        // are still opening HashRuns.org in Safari").
        textMessageBuilder:
            (context, message, index, {required isSentByMe, groupStatus}) =>
                _LinkAwareTextMessage(
                  message: message,
                  isSentByMe: isSentByMe,
                  theme: _chatTheme,
                  timeFormat: _timeFormat,
                ),
        // A photo, whole and at its own aspect ratio (E9.F1.S11).
        imageMessageBuilder:
            (context, message, index, {required isSentByMe, groupStatus}) =>
                ChatImageBubble(
                  message: message,
                  isSentByMe: isSentByMe,
                  theme: _chatTheme,
                  timeFormat: _timeFormat,
                ),
        // The only custom message is a location card (E9.F1.S12). Anything
        // else custom — none today — shows nothing rather than throwing.
        customMessageBuilder:
            (context, message, index, {required isSentByMe, groupStatus}) {
              final ChatLocation? at = chatLocationOf(message);
              if (at == null) return const SizedBox.shrink();
              return ChatLocationCard(
                message: message,
                location: at,
                isSentByMe: isSentByMe,
                theme: _chatTheme,
                timeFormat: _timeFormat,
              );
            },
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
              final isGroupStart = groupStatus == null || groupStatus.isFirst;
              final isGroupEnd = groupStatus == null || groupStatus.isLast;

              return ChatMessage(
                message: message,
                index: index,
                animation: animation,
                isRemoved: isRemoved,
                groupStatus: groupStatus,
                leadingWidget: isSentByMe
                    ? null
                    : isGroupEnd
                    ? Padding(
                        padding: const EdgeInsets.only(right: _avatarMargin),
                        child: Avatar(
                          userId: message.authorId,
                          size: _avatarSize,
                        ),
                      )
                    : const SizedBox(width: _leadingSlot),
                headerWidget: !isSentByMe && isGroupStart
                    ? Padding(
                        padding: const EdgeInsets.only(
                          left: _nameLeftPad,
                          bottom: 2,
                        ),
                        child: Username(userId: message.authorId),
                      )
                    : null,
                // The quote above and the reaction chips below (E9.F1.S21/S22).
                child: ChatMessageDecor(
                  message: message,
                  isSentByMe: isSentByMe,
                  myId: controller.currentUser.id,
                  onToggleReaction: (core.Message m, String code) =>
                      unawaited(controller.toggleReaction(m, code)),
                  child: child,
                ),
              );
            },
      ),
    );
  }
}

/// What a DM shows in place of its composer once sending is refused: the
/// conversation was ended by either side, or one of them blocks the other.
/// The line names nobody's reason, on purpose — a block must not show.
class _CannotMessageBar extends StatelessWidget {
  const _CannotMessageBar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        color: const Color(0xFFE2E8F0),
        child: Text(
          "You can't message $name.",
          style: ts_footnoteBlack,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// The text bubble, with links. Mirrors SimpleTextMessage's shape and
/// colours from the same ChatTheme so nothing else on the page changes.
///
/// A StatefulWidget only because TapGestureRecognizers have to be disposed;
/// there is no business logic here (see CLAUDE.md on Stateless→Stateful).
class _LinkAwareTextMessage extends StatefulWidget {
  const _LinkAwareTextMessage({
    required this.message,
    required this.isSentByMe,
    required this.theme,
    required this.timeFormat,
  });

  final core.TextMessage message;
  final bool isSentByMe;
  final core.ChatTheme theme;
  final DateFormat timeFormat;

  @override
  State<_LinkAwareTextMessage> createState() => _LinkAwareTextMessageState();
}

class _LinkAwareTextMessageState extends State<_LinkAwareTextMessage> {
  final List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final TapGestureRecognizer r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _openLink(Uri uri) async {
    // Ours → the run, in the app. Anything else → the browser.
    if (DeepLinkService.parse(uri) != null) {
      await DeepLinkService.instance.open(uri);
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final core.ChatTheme t = widget.theme;
    final bool mine = widget.isSentByMe;
    final Color bg = mine ? t.colors.primary : t.colors.surfaceContainer;
    final Color fg = mine ? t.colors.onPrimary : t.colors.onSurface;
    final TextStyle body = t.typography.bodyMedium.copyWith(color: fg);
    final TextStyle link = body.copyWith(
      decoration: TextDecoration.underline,
      decorationColor: fg,
      fontWeight: FontWeight.w600,
    );
    final TextStyle time = t.typography.labelSmall.copyWith(
      color: fg.withValues(alpha: 0.7),
    );

    for (final TapGestureRecognizer r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final List<InlineSpan> spans = <InlineSpan>[];
    for (final TextRun run in splitLinks(widget.message.text)) {
      if (run.isLink) {
        final TapGestureRecognizer r = TapGestureRecognizer()
          ..onTap = () => unawaited(_openLink(run.url!));
        _recognizers.add(r);
        spans.add(TextSpan(text: run.text, style: link, recognizer: r));
      } else {
        spans.add(TextSpan(text: run.text, style: body));
      }
    }

    final Widget? stamp = chatTimeAndStatus(
      widget.message,
      isSentByMe: mine,
      style: time,
      timeFormat: widget.timeFormat,
    );
    return ClipRRect(
      borderRadius: t.shape,
      child: Container(
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            RichText(text: TextSpan(children: spans)),
            if (stamp != null)
              Padding(
                // Only MY bubbles carry a tick — it reports what became of
                // something I sent. The stock SimpleTextMessage draws this
                // through TimeAndStatus; this bubble replaced it for
                // tappable links (2026-09-15) and dropped the tick with it,
                // so no chat message showed one until it was put back here.
                padding: const EdgeInsets.only(top: 4),
                child: stamp,
              ),
          ],
        ),
      ),
    );
  }
}
