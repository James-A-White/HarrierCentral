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

  // Initialize the controller with the provided arguments
  late final ChatSheetController chatSheetController = Get.put(
    ChatSheetController(
      publicEventId: publicEventId,
      messageTitle: messageTitle,
    ),
    // permanent: true,
  );

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
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(
              () {
                return Chat(
                  messages: chatSheetController.messages
                      .toList(), // Convert RxList to List
                  onAttachmentPressed:
                      chatSheetController.handleAttachmentPressed,
                  onMessageTap: chatSheetController.handleMessageTap,
                  onPreviewDataFetched:
                      chatSheetController.handlePreviewDataFetched,
                  onSendPressed: chatSheetController.handleSendPressed,
                  showUserAvatars: true,
                  showUserNames: true,
                  user: chatSheetController.user,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
