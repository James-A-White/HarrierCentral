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
    return Obx(() {
      final NotificationService? ns = notificationServiceOrNull;
      final ChatThreadState state =
          ns?.chatThreadState(threadId, isKennelThread: isKennelThread) ??
          ChatThreadState.none;
      switch (state) {
        case ChatThreadState.unread:
          final int count = ns?.unreadCountFor(threadId) ?? 0;
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
    });
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
    () => Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: themeButtonColors,
        foregroundColor: Colors.white,
      ),
      body: ChatPage(
        eventId: threadId,
        publicEventId: publicThreadId,
        isKennelThread: isKennelThread,
      ),
    ),
  );
  if (Get.isRegistered<NotificationService>()) {
    unawaited(Get.find<NotificationService>().getEventChatMessageCounts());
  }
}
