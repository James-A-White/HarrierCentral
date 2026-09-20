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
    this.roomType,
  });

  /// For a KENNEL thread, [eventId] carries the kennel id and [publicEventId]
  /// carries the public kennel id (the thread's roomId) — the SPs mirror the
  /// event-thread rowset shapes so everything downstream is unchanged.
  final String eventId;
  final String publicEventId;
  final bool isKennelThread;

  /// A platform-wide room from HC6.ChatRoomCatalog() — admins, GMs, RAs and
  /// so on. Belongs to no kennel and no run, so [eventId] and [publicEventId]
  /// are both empty for it, and the room is named by this id alone.
  ///
  /// Held as the SERVER's room id rather than an app-side enum, so a room
  /// added to the catalog needs no change here at all. Null for the two
  /// existing thread kinds.
  ///
  /// Added alongside [isKennelThread] rather than turning it into an enum:
  /// that flag reaches NotificationService and the run list too, and a
  /// working chat with 1,227 real messages is not worth a sweeping refactor
  /// (James, 2026-09-13). Both collapse into ONE [_ThreadKind] immediately
  /// below, so every decision switches on a single value and a fourth kind
  /// cannot be half-added.
  final int? roomType;

  _ThreadKind get _kind => roomType != null
      ? _ThreadKind.room
      : isKennelThread
      ? _ThreadKind.kennel
      : _ThreadKind.event;

  /// The request field naming the thread. The admin room has no id — it is
  /// THE room — so it sends none.
  String? get _idKey => switch (_kind) {
    _ThreadKind.event => 'eventId',
    _ThreadKind.kennel => 'kennelId',
    _ThreadKind.room => null,
  };

  String get _getQueryType => switch (_kind) {
    _ThreadKind.event => 'getEventMessages',
    _ThreadKind.kennel => 'getKennelMessages',
    _ThreadKind.room => 'getRoomMessages',
  };

  String get _getProcName => switch (_kind) {
    _ThreadKind.event => 'hcapp_getEventMessages',
    _ThreadKind.kennel => 'hcapp_getKennelMessages',
    _ThreadKind.room => 'hcapp_getRoomMessages',
  };

  String get _sendQueryType => switch (_kind) {
    _ThreadKind.event => 'sendEventMessage',
    _ThreadKind.kennel => 'sendKennelMessage',
    _ThreadKind.room => 'sendRoomMessage',
  };

  String get _sendProcName => switch (_kind) {
    _ThreadKind.event => 'hcapp_sendEventMessage',
    _ThreadKind.kennel => 'hcapp_sendKennelMessage',
    _ThreadKind.room => 'hcapp_sendRoomMessage',
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
    if (Get.isRegistered<NotificationService>()) {
      final NotificationService notifications = Get.find<NotificationService>();
      if (roomType != null) {
        // A room has no publicEventId to key a local badge on — its roomType
        // IS the key. The server read still happens through the GET's
        // @markRead; this is the optimistic half, and without it the app-bar
        // bubble kept a count for a room that was already open.
        notifications.clearUnreadForRoom(roomType!);
      } else {
        notifications.clearUnreadForThread(
          publicEventId,
          isKennelThread: isKennelThread,
        );
      }
    }

    _fcmSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Only act on (and log) pushes for THIS chat — every other foreground push
      // used to hit an error-level log with a full data interpolation.
      if (!_pushIsForThisThread(message.data)) return;
      BootLogger.logBreadcrumb('[ChatPage FCM] delta for ${_kind.name}');
      // The sender's OWN echo is what turns their single tick into a double,
      // so this must fire for every thread kind, not just runs.
      _upgradeOwnMessagesToDelivered();
      unawaited(_fetchDelta());
    });
  }

  /// Is this push about the thread this page is showing?
  ///
  /// The three kinds identify themselves differently on the wire, and until
  /// 2026-09-18 this only ever looked for an EventId. A kennel push carries a
  /// KennelId and a room push carries a RoomType — the shim sends the room in
  /// its own key BECAUSE MessageType is pinned to 0 for these two, since the
  /// app parses that key through MessageType.fromId, which throws above 2.
  /// The effect of matching on EventId alone was that a kennel or room
  /// message never upgraded its sender's tick and never pulled its own delta.
  bool _pushIsForThisThread(Map<String, dynamic> data) {
    switch (_kind) {
      case _ThreadKind.room:
        final int? pushed = int.tryParse('${data['RoomType'] ?? ''}');
        return pushed != null && pushed == roomType;
      case _ThreadKind.kennel:
        // eventId holds the KENNEL id for a kennel thread (see the chat list).
        final String? pushed = data['KennelId'] as String?;
        return pushed != null && pushed.asUuid == eventId.asUuid;
      case _ThreadKind.event:
        final String? pushed = data['EventId'] as String?;
        return pushed != null && pushed.asUuid == eventId.asUuid;
    }
  }

  void _upgradeOwnMessagesToDelivered() {
    // onClose cancels the FCM subscription WITHOUT awaiting it, so an event
    // already in flight can still land here after chatController.dispose().
    // Writing to a disposed InMemoryChatController throws "Cannot add new
    // events after calling close" — the same fault _fetchDelta was fixed for
    // on 2026-09-14, from the one path that was not covered.
    if (isClosed) return;
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
      // The page can be gone by the time the fetch lands — open a chat and
      // leave again inside the round trip and the InMemoryChatController has
      // been closed, so setMessages throws "Cannot add new events after
      // calling close" into the void. Seen on 3.1.0+1358 while opening and
      // closing rooms quickly (2026-09-14). isClosed is the GetxController's
      // own disposal flag, checked after EVERY await below, because each one
      // is a fresh chance for the page to have gone.
      if (isClosed) return;
      if (result == null || result.startsWith(ERROR_PREFIX)) return;
      final outerItem = jsonDecode(result) as List<dynamic>;
      final rawMessages = outerItem[0] as List<dynamic>;
      if (rawMessages.isEmpty) return;

      final newSeq = _extractMaxSequenceCount(rawMessages);
      if (newSeq != null) _lastKnownSequenceCount = newSeq;

      final messages = _parseMessages(rawMessages);
      if (isClosed) return;
      if (sinceSeq == null) {
        await chatController.setMessages(messages);
      } else {
        // Delta: _parseMessages returns oldest-first; insertMessage appends
        // at the newest end, so iterating oldest→newest is correct.
        // Guard against re-inserting optimistically-added sent messages whose
        // sequence count the sender never received back from the server.
        for (final msg in messages) {
          if (isClosed) return;
          if (!chatController.messages.any((m) => m.id == msg.id)) {
            await chatController.insertMessage(msg);
          }
        }
      }
    } finally {
      _isFetching = false;
      if (_pendingFetch && !isClosed) {
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
    // A room has no id to name, so there is no separate mark-read SP for it
    // — hcapp_getRoomMessages does the job with @markRead. Without this guard
    // `_idKey!` below is a null check on null, thrown inside the unawaited()
    // call in onInitAsync and surfacing as an unhandled async error every
    // single time the room is opened.
    if (roomType != null) return;

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
      // A room is named by its type, and is marked read by the same call
      // that reads it.
      if (roomType != null) 'roomType': roomType,
      if (roomType != null) 'markRead': 1,
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
        // A message the server hands back IS on the server, so my own come
        // back with both ticks rather than sitting on one for ever. Messages
        // I sent from another device — or from the portal, or straight into
        // the table — only ever arrive this way, and showed no tick at all.
        status: authorId == currentUser.id
            ? core.MessageStatus.delivered
            : core.MessageStatus.sent,
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
      // Picking an image and decoding it are both long awaits, and the
      // hasher can leave the chat inside either one.
      if (isClosed) return;
      unawaited(chatController.insertMessage(message));
    }
  }

  Future<void> handleSendPressed(String text) async {
    // A blank composer must never reach the server. The send SPs refuse an
    // empty message, and ServiceCommon.sendHttpPost turns any error envelope
    // into an alert — so pressing send on nothing produced a dialog rather
    // than nothing happening.
    //
    // Dart's trim() strips whitespace ONLY. An emoji-only message is not
    // blank here and must still send: the server used to disagree, because
    // in the database's collation a surrogate pair compares equal to '',
    // which is what refused Kilty's single wave on 2026-09-19. That was
    // fixed in hcapp_sendRoomMessage; this guard must not reintroduce it,
    // so it stays a trim() test and never a length-in-characters one.
    if (text.trim().isEmpty) return;

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
        if (roomType != null) 'roomType': roomType,
        'messageId': uuid,
        'messageContent': text,
        // Every body key becomes an SP parameter in the shim, so a key the
        // SP does not declare is a "too many arguments" failure, not an
        // ignored extra. A room has no kennel or run to be releasable to —
        // hcapp_sendRoomMessage stores the all-audiences value itself rather
        // than accepting a parameter it would never branch on.
        if (roomType == null)
          'messageReleasabilityFlags': kChatReleasabilityAll,
      }),
    );

    final failed = result.startsWith(ERROR_PREFIX);
    // Same disposal race as _fetchDelta: send, leave, and the reply lands on
    // a closed controller.
    if (isClosed) return;
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
enum _ThreadKind { event, kennel, room }
