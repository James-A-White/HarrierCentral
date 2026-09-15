import 'package:flutter_chat_core/flutter_chat_core.dart' as core;
import 'package:intl/intl.dart';
import 'package:harrier_central/imports.dart';

class ChatPage extends StatelessWidget {
  ChatPage({
    required this.eventId,
    required this.publicEventId,
    this.isKennelThread = false,
    this.roomType,
    super.key,
  });

  /// A platform-wide room from HC6.ChatRoomCatalog(). Belongs to no kennel
  /// and no run, so [eventId] and [publicEventId] are both empty for it, and
  /// [roomType] is the server's id for the room.
  factory ChatPage.room({required int roomType, Key? key}) => ChatPage(
    eventId: '',
    publicEventId: '',
    roomType: roomType,
    key: key,
  );

  /// Kennel thread: [eventId]=kennelId, [publicEventId]=publicKennelId.
  final String eventId;
  final String publicEventId;
  final bool isKennelThread;
  final int? roomType;

  late final ChatPageController controller = Get.put(
    ChatPageController(
      eventId: eventId,
      publicEventId: publicEventId,
      isKennelThread: isKennelThread,
      roomType: roomType,
    ),
  );

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
    return Chat(
      currentUserId: controller.currentUser.id,
      resolveUser: controller.resolveUser,
      chatController: controller.chatController,
      onMessageSend: controller.handleSendPressed,
      onAttachmentTap: controller.handleAttachmentPressed,
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
            child: child,
          );
        },
      ),
    );
  }
}
