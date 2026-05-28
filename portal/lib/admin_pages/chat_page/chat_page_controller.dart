// ignore_for_file: require_trailing_commas

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as core;
import 'package:hcportal/imports.dart';
import 'package:web/web.dart' as web;

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
  Timer? _pollTimer;

  int? _lastKnownSequenceCount;
  bool _isRefreshing = false;
  bool _pendingRefresh = false;

  // Message IDs sent by this user whose FCM echo arrived before the SP
  // response returned. When the SP then sets status to `sent`, we check
  // this set and immediately upgrade to `delivered` rather than waiting
  // for a second FCM event that will never come.
  final _pendingDeliveryIds = <String>{};

  bool get _isSafari {
    final ua = web.window.navigator.userAgent.toLowerCase();
    return ua.contains('safari') &&
        !ua.contains('chrome') &&
        !ua.contains('chromium');
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    unawaited(_fcmSubscription?.cancel());
    chatController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    publicEventId = normalizeUuid(publicEventId);

    final publicHasherId = box.get(HIVE_HASHER_ID) as String;
    final hashName =
        box.get(HIVE_DISPLAY_NAME) as String? ??
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
    try {
      final result = await _getEventMessages(publicEventId);
      if (result != null && !result.startsWith(ERROR_PREFIX)) {
        final outerItem = jsonDecode(result) as List<dynamic>;
        final rawMessages = outerItem[0] as List<dynamic>;

        final newSeq = _extractMaxSequenceCount(rawMessages);
        if (newSeq != null) _lastKnownSequenceCount = newSeq;

        final messages = _parseMessages(rawMessages);
        await chatController.setMessages(messages);

        final chatsCounts =
            (box.get(HIVE_CHATS_COUNT) as Map?)?.cast<String, int>() ?? {};
        chatsCounts[publicEventId] = messages.length;
        await box.put(HIVE_CHATS_COUNT, chatsCounts);
      }

      unawaited(_markEventChatRead(publicEventId));
    } catch (e) {
      debugPrint('[ChatSheetController] onInitAsync load error: $e');
    }

    // FCM subscription always registered, even if initial load failed.
    _subscribeFcm();

    // Safari enforces a silent push quota (~3 messages) before stopping
    // service-worker-to-page delivery. Poll as a reliable fallback.
    _startPollTimer();
  }

  void _subscribeFcm() {
    unawaited(_fcmSubscription?.cancel());
    _fcmSubscription = FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        try {
          final incomingEventId = normalizeUuid(
            message.data['PublicEventId']?.toString(),
          );
          if (incomingEventId.isEmpty || publicEventId != incomingEventId) {
            return;
          }
          unawaited(
            _refreshMessages().catchError((Object e, StackTrace st) {
              debugPrint('[ChatSheetController] _refreshMessages error: $e');
            }),
          );
        } catch (e) {
          debugPrint('[ChatSheetController] onMessage handler error: $e');
        }
      },
      onError: (Object e, StackTrace st) {
        debugPrint('[ChatSheetController] FCM stream error: $e');
      },
      onDone: _subscribeFcm,
      cancelOnError: false,
    );
  }

  void _startPollTimer() {
    // Only needed on Safari — Chrome/Firefox get reliable FCM delivery.
    if (!_isSafari) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(
        _refreshMessages().catchError((Object e, StackTrace st) {
          debugPrint('[ChatSheetController] poll error: $e');
        }),
      );
    });
  }

  Future<void> _refreshMessages() async {
    if (_isRefreshing) {
      _pendingRefresh = true;
      return;
    }
    _isRefreshing = true;
    try {
      final sinceSeq = _lastKnownSequenceCount;
      final result = await _getEventMessages(
        publicEventId,
        sinceSequenceCount: sinceSeq,
      );
      if (result == null || result.startsWith(ERROR_PREFIX)) return;
      final outerItem = jsonDecode(result) as List<dynamic>;
      final rawMessages = outerItem[0] as List<dynamic>;
      if (rawMessages.isEmpty) return;

      final newSeq = _extractMaxSequenceCount(rawMessages);
      if (newSeq != null) _lastKnownSequenceCount = newSeq;

      final messages = _parseMessages(rawMessages);
      for (final msg in messages) {
        final existing =
            chatController.messages.firstWhereOrNull((m) => m.id == msg.id);
        if (existing == null) {
          await chatController.insertMessage(msg);
        } else if (existing.authorId == currentUser.id) {
          // Our own message appeared in the DB delta — the SP confirmed it.
          if (existing.status == core.MessageStatus.sent) {
            // Normal path: SP returned before FCM, upgrade to delivered now.
            _upgradeToDelivered(existing);
          } else if (existing.status == core.MessageStatus.sending) {
            // Race: FCM/poll beat the SP response. Defer the upgrade until
            // handleSendPressed sets the status to `sent`.
            _pendingDeliveryIds.add(existing.id);
          }
        }
      }
    } catch (e, st) {
      debugPrint('[ChatSheetController] _refreshMessages exception: $e\n$st');
    } finally {
      _isRefreshing = false;
      if (_pendingRefresh) {
        _pendingRefresh = false;
        unawaited(_refreshMessages());
      }
    }
  }

  void _upgradeToDelivered(core.Message msg) {
    core.Message? updated;
    if (msg is core.TextMessage) {
      updated = msg.copyWith(status: core.MessageStatus.delivered);
    } else if (msg is core.ImageMessage) {
      updated = msg.copyWith(status: core.MessageStatus.delivered);
    } else if (msg is core.FileMessage) {
      updated = msg.copyWith(status: core.MessageStatus.delivered);
    }
    if (updated != null) unawaited(chatController.updateMessage(msg, updated));
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
    debugPrint(
      result.startsWith(ERROR_PREFIX)
          ? 'SP [markEventChatRead] called — FAILED'
          : 'SP [markEventChatRead] called — success',
    );
  }

  Future<String?> _getEventMessages(
    String publicEventId, {
    int? sinceSequenceCount,
  }) async {
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
    if (sinceSequenceCount != null) {
      body['sinceSequenceCount'] = sinceSequenceCount;
    }

    final jsonResult = await ServiceCommon.sendHttpPostToHC6Api(body);
    debugPrint(
      jsonResult.startsWith(ERROR_PREFIX)
          ? 'SP 9 [getEventMessages] called — FAILED'
          : 'SP 9 [getEventMessages] called — success',
    );
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
      result.add(
        core.Message.text(
          id: (msg['id'] as String).asUuid,
          authorId: authorId,
          text: msg['text'] as String,
          createdAt: createdAtMs is int
              ? DateTime.fromMillisecondsSinceEpoch(createdAtMs)
              : null,
          status: core.MessageStatus.sent,
        ),
      );
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
    debugPrint(
      failed
          ? 'SP 17 [sendEventMessage] called — FAILED'
          : 'SP 17 [sendEventMessage] called — success',
    );

    final sent =
        chatController.messages.firstWhereOrNull((m) => m.id == uuid);
    if (sent is! core.TextMessage) return;

    if (failed) {
      await chatController.updateMessage(
        sent,
        sent.copyWith(status: core.MessageStatus.error),
      );
      _pendingDeliveryIds.remove(uuid);
      return;
    }

    if (_isSafari) {
      // Safari FCM delivery is unreliable after the browser's silent push
      // quota (~3 messages). Go directly to delivered so the sender always
      // gets confirmation without waiting up to 15 seconds for the poll.
      await chatController.updateMessage(
        sent,
        sent.copyWith(
          status: core.MessageStatus.delivered,
          sentAt: DateTime.now(),
        ),
      );
    } else {
      // Chrome/Firefox: SP confirm → single tick. The sender's FCM echo
      // (from Rowset 2 of hcportal_sendEventMessage) will trigger the
      // delta fetch that upgrades to double tick.
      await chatController.updateMessage(
        sent,
        sent.copyWith(
          status: core.MessageStatus.sent,
          sentAt: DateTime.now(),
        ),
      );

      // Handle race: if the FCM echo arrived and ran _refreshMessages()
      // before the SP response returned, the message was still in `sending`
      // state and the upgrade was deferred into _pendingDeliveryIds.
      if (_pendingDeliveryIds.remove(uuid)) {
        final updated =
            chatController.messages.firstWhereOrNull((m) => m.id == uuid);
        if (updated is core.TextMessage) {
          await chatController.updateMessage(
            updated,
            updated.copyWith(status: core.MessageStatus.delivered),
          );
        }
      }
    }
  }
}
