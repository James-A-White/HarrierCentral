import 'package:flutter_chat_core/flutter_chat_core.dart' as core;
import 'package:harrier_central/imports.dart';

const int kChatReleasabilityAll = 63;

/// Assistance / all-clear broadcasts: Mismanagement (0x01) + RSVPs (0x08) +
/// Hares (0x10) — the people actually involved in the run, not every hasher
/// who ever had a kennel association.
const int kChatReleasabilityAssistance = 0x19;

class ChatPageController extends GetxController {
  ChatPageController({
    required this.eventId,
    required this.publicEventId,
    this.isKennelThread = false,
    this.isAdminThread = false,
  });

  /// For a KENNEL thread, [eventId] carries the kennel id and [publicEventId]
  /// carries the public kennel id (the thread's roomId) — the SPs mirror the
  /// event-thread rowset shapes so everything downstream is unchanged.
  final String eventId;
  final String publicEventId;
  final bool isKennelThread;

  /// The platform-wide Harrier Central admin room. Belongs to no kennel and
  /// no run, so [eventId] and [publicEventId] are both empty for it.
  ///
  /// Added as a separate flag rather than turning [isKennelThread] into an
  /// enum: that flag reaches NotificationService and the run list too, and a
  /// working chat with 1,227 real messages is not worth a sweeping refactor
  /// for a room 290 people will use (James, 2026-09-13). The two flags are
  /// collapsed into ONE [_ThreadKind] immediately below, so every decision
  /// below switches on a single value and a fourth kind cannot be half-added.
  final bool isAdminThread;

  _ThreadKind get _kind => isAdminThread
      ? _ThreadKind.admin
      : isKennelThread
      ? _ThreadKind.kennel
      : _ThreadKind.event;

  /// The request field naming the thread. The admin room has no id — it is
  /// THE room — so it sends none.
  String? get _idKey => switch (_kind) {
    _ThreadKind.event => 'eventId',
    _ThreadKind.kennel => 'kennelId',
    _ThreadKind.admin => null,
  };

  String get _getQueryType => switch (_kind) {
    _ThreadKind.event => 'getEventMessages',
    _ThreadKind.kennel => 'getKennelMessages',
    _ThreadKind.admin => 'getAdminMessages',
  };

  String get _getProcName => switch (_kind) {
    _ThreadKind.event => 'hcapp_getEventMessages',
    _ThreadKind.kennel => 'hcapp_getKennelMessages',
    _ThreadKind.admin => 'hcapp_getAdminMessages',
  };

  String get _sendQueryType => switch (_kind) {
    _ThreadKind.event => 'sendEventMessage',
    _ThreadKind.kennel => 'sendKennelMessage',
    _ThreadKind.admin => 'sendAdminMessage',
  };

  String get _sendProcName => switch (_kind) {
    _ThreadKind.event => 'hcapp_sendEventMessage',
    _ThreadKind.kennel => 'hcapp_sendKennelMessage',
    _ThreadKind.admin => 'hcapp_sendAdminMessage',
  };

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

    // Opening the chat IS reading it — clear this thread's unread badge locally
    // and immediately (top chat-bubble count + Unseen Chats list). This is
    // race-free where a post-close server refetch is not: markEventChatRead is
    // fired-and-forgotten above, so a refetch can beat its write and read back
    // the stale count. The SP remains the durable server-side backstop.
    if (!isAdminThread && Get.isRegistered<NotificationService>()) {
      // The admin room has no publicEventId to key a local badge on, and its
      // GET marks it read server-side via @markRead.
      Get.find<NotificationService>()
          .clearUnreadForThread(publicEventId, isKennelThread: isKennelThread);
    }

    _fcmSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final incomingEventId = message.data['EventId'] as String?;
      // Only act on (and log) pushes for THIS chat — every other foreground push
      // used to hit an error-level log with a full data interpolation.
      if (incomingEventId != null && eventId.asUuid == incomingEventId.asUuid) {
        BootLogger.logBreadcrumb('[ChatPage FCM] delta for $incomingEventId');
        _upgradeOwnMessagesToDelivered();
        unawaited(_fetchDelta());
      }
    });
  }

  void _upgradeOwnMessagesToDelivered() {
    for (final msg in List.of(chatController.messages)) {
      if (msg.authorId != currentUser.id) continue;
      if (msg.status != core.MessageStatus.sent) continue;
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
    // The admin room has no id to name, so there is no separate mark-read SP
    // for it — hcapp_getAdminMessages does the job with @markRead. Without
    // this guard `_idKey!` below is a null check on null, thrown inside the
    // unawaited() call in onInitAsync and surfacing as an unhandled async
    // error every single time the room is opened.
    if (isAdminThread) return;

    final userId = currentUserId;
    final deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType':
            isKennelThread ? 'markKennelChatRead' : 'markEventChatRead',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          userId,
          isKennelThread ? 'hcapp_markKennelChatRead' : 'hcapp_markEventChatRead',
          paramString: deviceSecret,
        ),
        _idKey!: eventId,
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
      'queryType': _getQueryType,
      'deviceId': deviceId,
      ?_idKey: eventId,
      // The admin room is marked read by the same call that reads it.
      if (isAdminThread) 'markRead': 1,
    };
    if (sinceSequenceCount != null) {
      body['sinceSequenceCount'] = sinceSequenceCount;
    }

    return ServiceCommon.sendHttpPost(() {
      // Minted inside the closure: fresh token per attempt (token retry).
      body['accessToken'] = Utilities.generateToken(
        userId,
        _getProcName,
        paramString: deviceSecret,
      );
      return jsonEncode(body);
    });
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
        'queryType': _sendQueryType,
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          userId,
          _sendProcName,
          paramString: deviceSecret,
        ),
        ?_idKey: eventId,
        'messageId': uuid,
        'messageContent': text,
        'messageReleasabilityFlags': kChatReleasabilityAll,
      }),
    );

    final failed = result.startsWith(ERROR_PREFIX);
    final sent = chatController.messages.where((m) => m.id == uuid).firstOrNull;
    if (sent is core.TextMessage) {
      await chatController.updateMessage(
        sent,
        sent.copyWith(
          status: failed ? core.MessageStatus.error : core.MessageStatus.sent,
          sentAt: failed ? null : DateTime.now(),
        ),
      );
    }
  }
}

/// The three kinds of thread [ChatPageController] serves. Private: callers
/// pass the public flags, and this is how the controller reasons about them.
enum _ThreadKind { event, kennel, admin }
