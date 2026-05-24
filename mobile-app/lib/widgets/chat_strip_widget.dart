import 'package:harrier_central/imports.dart';

final class ChatStripMessage {
  const ChatStripMessage({required this.authorName, required this.text});
  final String authorName;
  final String text;
}

class ChatStripController extends GetxController {
  ChatStripController({required this.eventId, required this.publicEventId});

  final String eventId;
  final String publicEventId;

  final RxBool isLoading = true.obs;
  final RxList<ChatStripMessage> messages = <ChatStripMessage>[].obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_loadMessages());
  }

  Future<void> _loadMessages() async {
    isLoading.value = true;
    try {
      final userId = currentUserId;
      final deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
      final deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

      final jsonResult = await ServiceCommon.sendHttpPost(
        () => jsonEncode(<String, String>{
          'queryType': 'getEventMessages',
          'deviceId': deviceId,
          'accessToken': Utilities.generateToken(
            userId,
            'hcapp_getEventMessages',
            paramString: deviceSecret,
          ),
          'eventId': eventId,
        }),
      );

      if (!jsonResult.startsWith(ERROR_PREFIX)) {
        final outerItem = jsonDecode(jsonResult) as List<dynamic>;
        messages.value = _parseMessages(outerItem[0] as List<dynamic>);
      } else {
        debugPrint('ChatStripController: getEventMessages error: $jsonResult');
      }
    } catch (e) {
      debugPrint('ChatStripController: load error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<ChatStripMessage> _parseMessages(List<dynamic> rawMessages) {
    return rawMessages.map((item) {
      final msg = Map<String, dynamic>.from(item as Map<String, dynamic>);

      String authorName;
      if (msg['author'] is String) {
        final author = jsonDecode(msg['author'].toString()) as Map<String, dynamic>;
        authorName = (author['firstName'] as String?) ?? 'Unknown';
      } else if (msg.containsKey('authorId')) {
        authorName = (msg['authorFirstName'] as String?) ?? 'Unknown';
      } else if (msg['author'] is Map) {
        final author = msg['author'] as Map<String, dynamic>;
        authorName = (author['firstName'] as String?) ?? 'Unknown';
      } else {
        authorName = 'Unknown';
      }

      final text = (msg['text'] as String?) ?? '📎 Attachment';
      return ChatStripMessage(authorName: authorName, text: text);
    }).toList();
  }
}

class ChatStripWidget extends StatelessWidget {
  ChatStripWidget({
    required this.eventId,
    required this.publicEventId,
    super.key,
  }) : controller = Get.put(
         ChatStripController(eventId: eventId, publicEventId: publicEventId),
         tag: 'chat-strip-$eventId',
       );

  final String eventId;
  final String publicEventId;
  final ChatStripController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Obx(() {
          final msgs = controller.messages;
          final count = msgs.length;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 4, 2),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 16),
                    const SizedBox(width: 6),
                    Text('Chat', style: ts_button),
                    if (!controller.isLoading.value && count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: hc_blue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: ts_bodySmall.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 14),
                      label: Text('Open Chat', style: ts_bodySmall),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () =>
                          Get.find<LiveRunShellController>().setTab(1),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Body
              if (controller.isLoading.value)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (msgs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  child: Text(
                    'No messages yet — tap Open Chat to start the conversation.',
                    style: ts_bodySmall.copyWith(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                )
              else ...[
                // Show last 3 messages oldest→newest (messages list is newest-first)
                for (final msg in msgs.take(3).toList().reversed)
                  _MessageRow(message: msg),
                if (count > 3)
                  InkWell(
                    onTap: () =>
                        Get.find<LiveRunShellController>().setTab(1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        '${count - 3} more message${count - 3 == 1 ? '' : 's'} — Open Chat',
                        style: ts_bodySmall.copyWith(
                          color: hc_blue,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ],
          );
        }),
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.message});

  final ChatStripMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 3, 12, 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${message.authorName}: ',
            style: ts_bodySmall.copyWith(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              message.text,
              style: ts_bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
