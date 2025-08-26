import 'package:harrier_central/imports.dart';

class ChatPage extends StatelessWidget {
  ChatPage({required this.eventId, required this.publicEventId, super.key});

  final String eventId;
  final String publicEventId;

  // Initialize the controller with the provided arguments
  late final ChatPageController chatSheetController = Get.put(
    ChatPageController(eventId: eventId, publicEventId: publicEventId),
    // permanent: true,
  );

  @override
  Widget build(BuildContext context) {
    final messages = chatSheetController.messages;
    return GetBuilder<ChatPageController>(
      id: 'chatMessages',
      builder: (controller) {
        return VisibilityDetector(
          key: Key('my-widget-key'),
          onVisibilityChanged: (visibilityInfo) {
            controller.visibility = visibilityInfo.visibleFraction;
            debugPrint(
              'Widget ${visibilityInfo.key} is ${controller.visibility * 100}% visible',
            );
          },
          child: Obx(() {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                controller.messagesLoading.value
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        HcAppCircularProgressIndicator(
                          key: ValueKey('1313515234'),
                        ),
                      ],
                    )
                    : Expanded(
                      child: Chat(
                        messages: messages, // Convert RxList to List
                        onAttachmentPressed:
                            chatSheetController.handleAttachmentPressed,
                        onMessageTap: chatSheetController.handleMessageTap,
                        onPreviewDataFetched:
                            chatSheetController.handlePreviewDataFetched,
                        onSendPressed: chatSheetController.handleSendPressed,
                        showUserAvatars: true,
                        showUserNames: true,
                        user: chatSheetController.user,
                      ),
                    ),
              ],
            );
          }),
        );
      },
    );
  }
}
