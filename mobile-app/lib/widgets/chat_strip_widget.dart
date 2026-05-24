import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:harrier_central/imports.dart';

class ChatStripController extends GetxController {
  ChatStripController({required this.eventId, required this.publicEventId});

  final String eventId;
  final String publicEventId;

  final RxBool isLoading = true.obs;
  final RxList<types.Message> messages = <types.Message>[].obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_loadMessages());
  }

  Future<void> _loadMessages() async {
    isLoading.value = true;
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
      final rawMessages = outerItem[0] as List<dynamic>;
      messages.value = _parseMessages(rawMessages);
    }
    isLoading.value = false;
  }

  List<types.Message> _parseMessages(List<dynamic> rawMessages) {
    return rawMessages.map((item) {
      final msg = Map<String, dynamic>.from(item as Map<String, dynamic>);
      if (msg['author'] is String) {
        msg['author'] = jsonDecode(msg['author'].toString());
      } else if (msg.containsKey('authorId')) {
        msg['author'] = <String, dynamic>{
          'id': msg['authorId'],
          'firstName': msg['authorFirstName'],
          'imageUrl': msg['authorImageUrl'],
          'type': 'user',
        };
        msg.remove('authorId');
        msg.remove('authorFirstName');
        msg.remove('authorImageUrl');
      }
      msg['showStatus'] = true;
      return types.Message.fromJson(msg);
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

  final types.Message message;

  @override
  Widget build(BuildContext context) {
    final authorName = message.author.firstName ?? 'Unknown';

    final String text;
    if (message is types.TextMessage) {
      text = (message as types.TextMessage).text;
    } else if (message is types.ImageMessage) {
      text = '📷 Image';
    } else {
      text = '📎 Attachment';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 3, 12, 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$authorName: ',
            style: ts_bodySmall.copyWith(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              text,
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
