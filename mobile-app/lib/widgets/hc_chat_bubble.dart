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
class HcChatBubble extends StatelessWidget {
  const HcChatBubble({
    required this.threadId,
    required this.isKennelThread,
    super.key,
  });

  final String threadId;
  final bool isKennelThread;

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
      );
      final int count = state == ChatThreadState.unread
          ? ns.unreadCountFor(threadId)
          : 0;
      return _forState(state, count);
    });
  }

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
          child: Icon(MaterialCommunityIcons.chat, color: hc_red),
        );
      case ChatThreadState.read:
        return const Icon(MaterialCommunityIcons.chat, color: Colors.black54);
      case ChatThreadState.none:
        return Icon(
          MaterialCommunityIcons.chat_outline,
          color: Colors.grey.shade500,
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
}) async {
  await Get.to(
    () => ChatScaffold(
      title: title,
      eventId: threadId,
      publicEventId: publicThreadId,
      isKennelThread: isKennelThread,
    ),
  );
  if (Get.isRegistered<NotificationService>()) {
    unawaited(Get.find<NotificationService>().getEventChatMessageCounts());
  }
}
