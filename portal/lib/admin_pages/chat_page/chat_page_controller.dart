// ignore_for_file: require_trailing_commas

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as core;
import 'package:hcportal/imports.dart';

class ChatSheetController extends GetxController {
  ChatSheetController({
    required this.publicEventId,
    required this.messageTitle,
  });

  String publicEventId;
  String messageTitle;

  final chatController = core.InMemoryChatController();
  final _userCache = <String, core.User>{};

  late core.User currentUser;
  StreamSubscription<RemoteMessage>? _fcmSubscription;
  final Rx<DateTime?> lastFcmEchoAt = Rx<DateTime?>(null);

  @override
  void onClose() {
    unawaited(_fcmSubscription?.cancel());
    chatController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    publicEventId = normalizeUuid(publicEventId);

    final publicHasherId = box.get(HIVE_HASHER_ID) as String;
    final hashName = box.get(HIVE_DISPLAY_NAME) as String? ??
        box.get(HIVE_HASH_NAME) as String;
    final photo = box.get(HIVE_HASHER_PHOTO) as String? ?? '';

    currentUser = core.User(
      id: publicHasherId.asUuid,
      name: hashName,
      imageSource: photo.isEmpty ? null : photo,
    );
    _userCache[currentUser.id] = currentUser;

    unawaited(onInitAsync());
  }

  Future<core.User?> resolveUser(String userId) async {
    return _userCache[userId.asUuid];
  }

  Future<void> onInitAsync() async {
    final result = await _getEventMessages(publicEventId);
    if (result != null) {
      final outerItem = jsonDecode(result) as List<dynamic>;
      final messages = _parseMessages(outerItem[0] as List<dynamic>);
      await chatController.setMessages(messages);

      final chatsCounts =
          (box.get(HIVE_CHATS_COUNT) as Map?)?.cast<String, int>() ?? {};
      chatsCounts[publicEventId] = messages.length;
      await box.put(HIVE_CHATS_COUNT, chatsCounts);
    }

    // Mark as read server-side and fan-out a silent read_sync to other
    // devices so their badges are zeroed immediately.
    unawaited(_markEventChatRead(publicEventId));

    _fcmSubscription =
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final incomingEventId = message.data['PublicEventId'] as String?;
      if (incomingEventId != null &&
          publicEventId == incomingEventId.asUuid) {
        final userId = message.data['UserId'].toString().asUuid;
        _userCache[userId] = core.User(
          id: userId,
          name: message.data['UserDisplayName'] as String?,
          imageSource: message.data['UserPhoto'] as String?,
        );

        final messageId = message.data['MessageId'].toString().asUuid;
        final existing = chatController.messages
            .where((m) => m.id == messageId)
            .firstOrNull;

        lastFcmEchoAt.value = DateTime.now();

        if (existing == null) {
          final newMsg = core.Message.text(
            id: messageId,
            authorId: userId,
            text: message.data['Message'] as String,
            createdAt: DateTime.now(),
            status: core.MessageStatus.sent,
          );
          unawaited(chatController.insertMessage(newMsg));
        } else {
          if (existing is core.TextMessage) {
            final updated = existing.copyWith(
              status: core.MessageStatus.sent,
              sentAt: DateTime.now(),
            );
            unawaited(chatController.updateMessage(existing, updated));
          }
        }
      }
    });
  }

  Future<void> _markEventChatRead(String publicEventId) async {
    final deviceId = box.get(HIVE_DEVICE_ID) as String;
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
    final accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_markEventChatRead',
      paramString: deviceSecret,
    );
    final body = <String, dynamic>{
      'queryType': 'markEventChatRead',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'publicEventId': publicEventId,
    };
    final result = await ServiceCommon.sendHttpPostToHC6Api(body);
    debugPrint(result.startsWith(ERROR_PREFIX)
        ? 'SP [markEventChatRead] called — FAILED'
        : 'SP [markEventChatRead] called — success');
  }

  Future<String?> _getEventMessages(String publicEventId) async {
    final deviceId = box.get(HIVE_DEVICE_ID) as String;
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
    final accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_getEventMessages',
      paramString: deviceSecret,
    );

    final body = <String, dynamic>{
      'queryType': 'getEventMessages',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'publicEventId': publicEventId,
    };

    final jsonResult = await ServiceCommon.sendHttpPostToHC6Api(body);
    debugPrint(jsonResult.startsWith(ERROR_PREFIX)
        ? 'SP 9 [getEventMessages] called — FAILED'
        : 'SP 9 [getEventMessages] called — success');
    return jsonResult;
  }

  List<core.Message> _parseMessages(List<dynamic> messageList) {
    final result = <core.Message>[];
    for (final item in messageList) {
      final msg = item as Map<String, dynamic>;

      dynamic authorRaw = msg['author'];
      if (authorRaw is String) {
        authorRaw = jsonDecode(authorRaw);
      }
      final author = authorRaw as Map<String, dynamic>;
      final authorId = (author['id'] as String).asUuid;

      _userCache[authorId] = core.User(
        id: authorId,
        name: author['firstName'] as String?,
        imageSource: author['imageUrl'] as String?,
      );

      final createdAtMs = msg['createdAt'];
      result.add(core.Message.text(
        id: (msg['id'] as String).asUuid,
        authorId: authorId,
        text: msg['text'] as String,
        createdAt: createdAtMs is int
            ? DateTime.fromMillisecondsSinceEpoch(createdAtMs)
            : null,
        status: core.MessageStatus.sent,
      ));
    }
    // SP returns newest-first (ORDER BY createdAt DESC); v2 chat displays
    // index 0 at top, so reverse to oldest-first for correct display order.
    return result.reversed.toList();
  }

  Future<void> handleAttachmentPressed() async {
    await Get.bottomSheet<void>(
      SafeArea(
        child: SizedBox(
          height: 144,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () async {
                  Get.back<void>();
                  await handleImageSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Photo'),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Get.back<void>();
                  await handleFileSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('File'),
                ),
              ),
              TextButton(
                onPressed: () => Get.back<void>(),
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierColor: Colors.black54,
    );
  }

  Future<void> handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      final message = core.Message.file(
        id: const Uuid().v4(),
        authorId: currentUser.id,
        source: result.files.single.path!,
        name: result.files.single.name,
        size: result.files.single.size,
        mimeType: lookupMimeType(result.files.single.path!),
      );
      unawaited(chatController.insertMessage(message));
    }
  }

  Future<void> handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      final message = core.Message.image(
        id: const Uuid().v4(),
        authorId: currentUser.id,
        source: result.path,
        width: image.width.toDouble(),
        height: image.height.toDouble(),
        size: bytes.length,
      );
      unawaited(chatController.insertMessage(message));
    }
  }

  void handleMessageTap(
    BuildContext _,
    core.Message message, {
    required int index,
    required TapUpDetails details,
  }) {
    // File tap handling reserved for future use
  }

  Future<void> handleSendPressed(String text) async {
    final uuid = const Uuid().v4();
    final newMsg = core.Message.text(
      id: uuid,
      authorId: currentUser.id,
      text: text,
      createdAt: DateTime.now(),
      status: core.MessageStatus.sending,
    );

    unawaited(chatController.insertMessage(newMsg));

    final deviceId = box.get(HIVE_DEVICE_ID) as String;
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';

    final accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_sendEventMessage',
      paramString: deviceSecret,
    );

    final body = <String, dynamic>{
      'queryType': 'sendEventMessage',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'publicEventId': publicEventId,
      'messageId': uuid,
      'messageContent': text,
      'messageReleasabilityFlags': 63,
      'messageTitle': messageTitle,
    };

    final sendResult = await ServiceCommon.sendHttpPostToHC6Api(body);
    final failed = sendResult.startsWith(ERROR_PREFIX);
    debugPrint(failed
        ? 'SP 17 [sendEventMessage] called — FAILED'
        : 'SP 17 [sendEventMessage] called — success');

    // Update message status immediately from the API response rather than
    // waiting for the FCM echo (which never arrives if notifications are off).
    final sent = chatController.messages.where((m) => m.id == uuid).firstOrNull;
    if (sent is core.TextMessage) {
      unawaited(chatController.updateMessage(
        sent,
        sent.copyWith(
          status: failed ? core.MessageStatus.error : core.MessageStatus.sent,
          sentAt: failed ? null : DateTime.now(),
        ),
      ));
    }
  }
}
