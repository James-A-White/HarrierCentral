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

  // Derived once from the package's light defaults so all non-overridden
  // colours (e.g. error red, link colour) keep their sensible values.
  static final _chatTheme = () {
    final base = core.ChatTheme.light();
    return base.copyWith(
      colors: base.colors.copyWith(
        primary: const Color(0xFF1D4ED8),           // sent bubble  — portal blue-700
        onPrimary: Colors.white,                    // text on sent bubble
        surfaceContainer: const Color(0xFFE2E8F0),  // received bubble — slate-200
        surfaceContainerHigh: const Color(0xFFCBD5E1), // slight contrast for grouping
        onSurface: const Color(0xFF1E293B),         // received text — slate-800
      ),
      shape: const BorderRadius.all(Radius.circular(18)),
    );
  }();

  static final _timeFormat = DateFormat('HH:mm');

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
      ),
    );
  }
}
