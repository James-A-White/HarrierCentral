import 'package:harrier_central/imports.dart';
import 'package:get/get.dart';

class ChatUi extends StatelessWidget {
  ChatUi({
    required this.eventId,
    super.key,
  });

  final String eventId;

  // Initialize the controller with the provided arguments
  late final ChatSheetController chatSheetController = Get.put(
    ChatSheetController(eventId: eventId),
    // permanent: true,
  );

  @override
  Widget build(BuildContext context) {
    final messages = chatSheetController.messages;
    return GetBuilder<ChatSheetController>(builder: (controller) {
      return Column(
        children: [
          Expanded(
              child: Chat(
            messages: messages, // Convert RxList to List
            onAttachmentPressed: chatSheetController.handleAttachmentPressed,
            onMessageTap: chatSheetController.handleMessageTap,
            onPreviewDataFetched: chatSheetController.handlePreviewDataFetched,
            onSendPressed: chatSheetController.handleSendPressed,
            showUserAvatars: true,
            showUserNames: true,
            user: chatSheetController.user,
          )),
        ],
      );
    });
  }
}
