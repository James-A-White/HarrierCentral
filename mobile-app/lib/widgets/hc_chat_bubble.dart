import 'package:harrier_central/imports.dart';
import 'package:harrier_central/widgets/hc_badges.dart' as badges;

/// Three-state chat bubble used on the kennel and run cards, read
/// reactively off [NotificationService]:
///
///   unread → solid bubble in HC red with an unread-count badge
///   read   → solid bubble, grey (same as the three-dots)
///   none   → outline bubble, lighter grey (thread has no messages yet)
///
/// [threadId] is the publicEventId (run thread) or publicKennelId (kennel
/// thread); matching is UUID-normalised inside the service.
///
/// [onDark] is for an app bar: the read and empty greys are chosen for a
/// white card and disappear on the maroon bar, so there the bubble is white
/// (solid when the thread has messages, outline when it has none) and an
/// unread one keeps its red count badge.
class HcChatBubble extends StatelessWidget {
  const HcChatBubble({
    required this.threadId,
    required this.isKennelThread,
    this.kennelThread = 0,
    this.onDark = false,
    super.key,
  });

  final String threadId;
  final bool isKennelThread;

  /// 1 = the kennel's Mismanagement chat (E9.F1.S33): its own count, and a
  /// different glyph so the two kennel bubbles side by side are told apart.
  final int kennelThread;
  final bool onDark;

  bool get _misman => isKennelThread && kennelThread == 1;

  @override
  Widget build(BuildContext context) {
    final NotificationService? ns = notificationServiceOrNull;
    // No service, or no thread, means nothing reactive to read — and an Obx
    // whose builder reads no Rx throws "improper use". Draw the plain icon
    // outside one.
    if (ns == null || threadId.isEmpty) {
      return _forState(ChatThreadState.none, 0);
    }
    return Obx(() {
      final ChatThreadState state = ns.chatThreadState(
        threadId,
        isKennelThread: isKennelThread,
        kennelThread: kennelThread,
      );
      final int count = state == ChatThreadState.unread
          ? ns.unreadCountFor(
              _misman ? NotificationService.mismanBadgeKey(threadId) : threadId,
            )
          : 0;
      return _forState(state, count);
    });
  }

  /// A shield for the Mismanagement chat, the chat bubble for every other.
  IconData get _solid => _misman ? Icons.admin_panel_settings : MaterialCommunityIcons.chat;
  IconData get _outline =>
      _misman ? Icons.admin_panel_settings_outlined : MaterialCommunityIcons.chat_outline;

  Widget _forState(ChatThreadState state, int count) {
    switch (state) {
      case ChatThreadState.unread:
        return badges.Badge(
          position: badges.BadgePosition.topEnd(top: -6, end: -8),
          badgeContent: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            constraints: const BoxConstraints(minWidth: 14),
            height: 13,
            child: AutoSizeText(
              count.toString(),
              textAlign: TextAlign.center,
              maxLines: 1,
              minFontSize: 10,
              maxFontSize: 13,
              style: ts_badge,
            ),
          ),
          badgeStyle: badges.BadgeStyle(
            badgeColor: Colors.red.shade800,
            padding: const EdgeInsets.all(4),
          ),
          child: Icon(
            _solid,
            color: onDark ? Colors.white : hc_red,
          ),
        );
      case ChatThreadState.read:
        return Icon(
          _solid,
          color: onDark ? Colors.white : Colors.black54,
        );
      case ChatThreadState.none:
        return Icon(
          _outline,
          color: onDark ? Colors.white70 : Colors.grey.shade500,
        );
    }
  }
}

/// Opens a chat thread standalone (outside RunDetailsPage), with its own
/// Scaffold + AppBar so there is a back button and the input stays above the
/// keyboard, then refreshes unread counts on return so card bubbles update.
Future<void> openChatThread({
  required String title,
  required String threadId,
  required String publicThreadId,
  required bool isKennelThread,
  int kennelThread = 0,
}) async {
  await Get.to(
    () => ChatScaffold(
      title: title,
      eventId: threadId,
      publicEventId: publicThreadId,
      isKennelThread: isKennelThread,
      kennelThread: kennelThread,
    ),
  );
  if (Get.isRegistered<NotificationService>()) {
    unawaited(Get.find<NotificationService>().getEventChatMessageCounts());
  }
}
