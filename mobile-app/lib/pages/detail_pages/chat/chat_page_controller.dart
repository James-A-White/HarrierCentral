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

  int? _lastKnownSequenceCount;
  bool _isFetching = false;
  bool _pendingFetch = false;

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
    await _fetchDelta();
  }

  Future<void> onInitAsync() async {
    await _fetchDelta();

    unawaited(_markEventChatRead());

    _fcmSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final incomingEventId = message.data['EventId'] as String?;
      BootLogger.logError('[ChatPage FCM] received', 'incomingEventId=$incomingEventId localEventId=$eventId data=${message.data}', null);
      if (incomingEventId != null && eventId.asUuid == incomingEventId.asUuid) {
        unawaited(_fetchDelta());
      }
    });
  }

  Future<void> _fetchDelta() async {
    if (_isFetching) {
      _pendingFetch = true;
      return;
    }
    _isFetching = true;
    try {
      final sinceSeq = _lastKnownSequenceCount;
      final result = await _getEventMessages(sinceSequenceCount: sinceSeq);
      if (result == null || result.startsWith(ERROR_PREFIX)) return;
      final outerItem = jsonDecode(result) as List<dynamic>;
      final rawMessages = outerItem[0] as List<dynamic>;
      if (rawMessages.isEmpty) return;

      final newSeq = _extractMaxSequenceCount(rawMessages);
      if (newSeq != null) _lastKnownSequenceCount = newSeq;

      final messages = _parseMessages(rawMessages);
      if (sinceSeq == null) {
        await chatController.setMessages(messages);
      } else {
        // Delta: _parseMessages returns oldest-first; insertMessage appends
        // at the newest end, so iterating oldest→newest is correct.
        // Guard against re-inserting optimistically-added sent messages whose
        // sequence count the sender never received back from the server.
        for (final msg in messages) {
          if (!chatController.messages.any((m) => m.id == msg.id)) {
            await chatController.insertMessage(msg);
          }
        }
      }
    } finally {
      _isFetching = false;
      if (_pendingFetch) {
        _pendingFetch = false;
        unawaited(_fetchDelta());
      }
    }
  }

  int? _extractMaxSequenceCount(List<dynamic> rawMessages) {
    int? max;
    for (final item in rawMessages) {
      final msg = item as Map<String, dynamic>;
      final seq = msg['sequenceCount'];
      final seqInt = seq is int ? seq : (seq as num?)?.toInt();
      if (seqInt != null && (max == null || seqInt > max)) max = seqInt;
    }
    return max;
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

  Future<String?> _getEventMessages({int? sinceSequenceCount}) async {
    final String userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final body = <String, dynamic>{
      'queryType': 'getEventMessages',
      'deviceId': deviceId,
      'accessToken': Utilities.generateToken(
        userId,
        'hcapp_getEventMessages',
        paramString: deviceSecret,
      ),
      'eventId': eventId,
    };
    if (sinceSequenceCount != null) {
      body['sinceSequenceCount'] = sinceSequenceCount;
    }

    return ServiceCommon.sendHttpPost(() => jsonEncode(body));
  }

  List<core.Message> _parseMessages(List<dynamic> messageList) {
    final result = <core.Message>[];
    for (final item in messageList) {
      final msg = item as Map<String, dynamic>;

      final String authorId;
      final String? authorName;
      final String? authorImageUrl;

      if (msg.containsKey('authorId')) {
        // HC6 app SP: flat columns
        authorId = (msg['authorId'] as String).asUuid;
        authorName = msg['authorFirstName'] as String?;
        authorImageUrl = msg['authorImageUrl'] as String?;
      } else {
        // HC5 legacy: nested author object (string or map)
        dynamic authorRaw = msg['author'];
        if (authorRaw is String) authorRaw = jsonDecode(authorRaw);
        final author =
            (authorRaw as Map<String, dynamic>?) ?? <String, dynamic>{};
        authorId = ((author['id'] as String?) ?? '').asUuid;
        authorName = author['firstName'] as String?;
        authorImageUrl = author['imageUrl'] as String?;
      }

      _userCache[authorId] = core.User(
        id: authorId,
        name: authorName,
        imageSource: authorImageUrl,
      );

      final createdAtMs = msg['createdAt'];
      result.add(core.Message.text(
        id: (msg['id'] as String).asUuid,
        authorId: authorId,
        text: (msg['text'] as String?) ?? '',
        createdAt: createdAtMs is int
            ? DateTime.fromMillisecondsSinceEpoch(createdAtMs)
            : (createdAtMs is num)
                ? DateTime.fromMillisecondsSinceEpoch(createdAtMs.toInt())
                : null,
        status: core.MessageStatus.sent,
      ));
    }
    // SP returns newest-first; reverse to oldest-first for display and
    // for oldest→newest insertMessage ordering on delta loads.
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
