import 'package:flutter_chat_core/flutter_chat_core.dart' as core;
import 'package:intl/intl.dart';
import 'package:hcportal/imports.dart';

class ChatSheetPage extends StatelessWidget {
  ChatSheetPage({
    required this.publicEventId,
    required this.messageTitle,
    required this.eventName,
    super.key,
  });

  final String publicEventId;
  final String messageTitle;
  final String eventName;

  late final ChatSheetController chatSheetController = Get.put(
    ChatSheetController(
      publicEventId: publicEventId,
      messageTitle: messageTitle,
    ),
  );

  static final _chatTheme = () {
    final base = core.ChatTheme.light();
    return base.copyWith(
      colors: base.colors.copyWith(
        primary: const Color(0xFF1D4ED8),           // sent bubble — portal blue-700
        onPrimary: Colors.white,
        surfaceContainer: const Color(0xFFE2E8F0),  // received bubble — slate-200
        surfaceContainerHigh: const Color(0xFFCBD5E1),
        onSurface: const Color(0xFF1E293B),          // text — slate-800
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
        actions: [
          Obx(() {
            final lastEcho = chatSheetController.lastFcmEchoAt.value;
            final label = lastEcho == null
                ? 'Awaiting FCM echo...'
                : 'FCM echo: ${lastEcho.hour.toString().padLeft(2, '0')}:${lastEcho.minute.toString().padLeft(2, '0')}:${lastEcho.second.toString().padLeft(2, '0')}';
            return Tooltip(
              message: label,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  MaterialCommunityIcons.signal,
                  color:
                      lastEcho == null ? Colors.grey.shade400 : Colors.green,
                ),
              ),
            );
          }),
        ],
      ),
      body: Chat(
        currentUserId: chatSheetController.currentUser.id,
        resolveUser: chatSheetController.resolveUser,
        chatController: chatSheetController.chatController,
        onMessageSend: chatSheetController.handleSendPressed,
        onAttachmentTap: chatSheetController.handleAttachmentPressed,
        onMessageTap: chatSheetController.handleMessageTap,
        theme: _chatTheme,
        timeFormat: _timeFormat,
        builders: core.Builders(
          chatMessageBuilder: (
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

            return ChatMessage(
              message: message,
              index: index,
              animation: animation,
              isRemoved: isRemoved,
              groupStatus: groupStatus,
              // Avatar anchored to the bottom of each received group.
              // A fixed-width spacer keeps bubbles aligned for non-end messages.
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
              child: child,
            );
          },
        ),
      ),
    );
  }
}
