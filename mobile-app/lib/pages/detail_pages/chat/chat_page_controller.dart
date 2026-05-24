import 'package:flutter_chat_core/flutter_chat_core.dart' as core;
import 'package:harrier_central/imports.dart';

const int kChatReleasabilityAll = 63;

class ChatPageController extends GetxController {
  ChatPageController({required this.eventId, required this.publicEventId});

  final String eventId;
  final String publicEventId;

  final chatController = core.InMemoryChatController();
  final _userCache = <String, core.User>{};

  late core.User currentUser;
  StreamSubscription<RemoteMessage>? _fcmSubscription;

  @override
  void onClose() {
    unawaited(_fcmSubscription?.cancel());
    chatController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();

    final String? publicHasherId = getStringPref(StringPrefsEnum.publicHasherId);
    if (publicHasherId == null || publicHasherId.isEmpty) {
      debugPrint('ChatPageController: publicHasherId not available, cannot open chat');
      currentUser = const core.User(id: '');
      WidgetsBinding.instance.addPostFrameCallback((_) => Get.back<void>());
      return;
    }

    final String hashName =
        getStringPref(StringPrefsEnum.displayName) ??
        getStringPref(StringPrefsEnum.firstName) ??
        '';
    final String photo = getStringPref(StringPrefsEnum.profilePhotoUrl) ?? '';

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

  Future<void> onAppResumed() async {
    final result = await _getEventMessages(eventId);
    if (result == null || result.startsWith(ERROR_PREFIX)) return;
    final outerItem = jsonDecode(result) as List<dynamic>;
    final messages = _parseMessages(outerItem[0] as List<dynamic>);
    await chatController.setMessages(messages);
  }

  Future<void> onInitAsync() async {
    await onAppResumed();

    unawaited(_markEventChatRead());

    _fcmSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final incomingEventId = message.data['EventId'] as String?;
      if (incomingEventId != null &&
          eventId.asUuid == incomingEventId.asUuid) {
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
            unawaited(chatController.updateMessage(
              existing,
              existing.copyWith(
                status: core.MessageStatus.sent,
                sentAt: DateTime.now(),
              ),
            ));
          }
        }
      }
    });
  }

  Future<void> _markEventChatRead() async {
    final userId = currentUserId;
    final deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'markEventChatRead',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          userId,
          'hcapp_markEventChatRead',
          paramString: deviceSecret,
        ),
        'eventId': eventId,
      }),
    );

    debugPrint(result.startsWith(ERROR_PREFIX)
        ? 'SP [markEventChatRead] called — FAILED'
        : 'SP [markEventChatRead] called — success');
  }

  Future<String?> _getEventMessages(String eventId) async {
    final String userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    return ServiceCommon.sendHttpPost(
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
    // SP returns newest-first; 2.x chat displays index 0 at top, so reverse.
    return result.reversed.toList();
  }

  void handleAttachmentPressed() {
    unawaited(
      Get.bottomSheet<void>(
        SafeArea(
          child: SizedBox(
            height: 96,
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
      ),
    );
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

    final userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'sendEventMessage',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          userId,
          'hcapp_sendEventMessage',
          paramString: deviceSecret,
        ),
        'eventId': eventId,
        'messageId': uuid,
        'messageContent': text,
        'messageReleasabilityFlags': kChatReleasabilityAll,
      }),
    );

    final failed = result.startsWith(ERROR_PREFIX);
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
