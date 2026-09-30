import 'package:flutter_chat_core/flutter_chat_core.dart' as core;
import 'package:harrier_central/imports.dart';
import 'package:geolocator/geolocator.dart';
import 'package:map_launcher/map_launcher.dart' as maps;

const int kChatReleasabilityAll = 63;

/// HC.EventMessage.MessageContent is NVARCHAR(4000) and the send SPs refuse
/// more. The composer stops typing at this length, so the server's refusal
/// is a backstop, not something a hasher meets. (The old NVARCHAR(500) cut
/// the first admin-room announcement in half, silently — 2026-09-23.)
const int kChatMessageMaxLength = 4000;

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
    this.threadId,
    this.dmState,
  });

  /// For a KENNEL thread, [eventId] carries the kennel id and [publicEventId]
  /// carries the public kennel id (the thread's roomId) — the SPs mirror the
  /// event-thread rowset shapes so everything downstream is unchanged.
  final String eventId;
  final String publicEventId;
  final bool isKennelThread;

  /// A direct message thread (E9.F1.S7) between this hasher and one other,
  /// named by its ThreadId alone — no run, no kennel, no room. Read and
  /// written through hcapp_getDirectMessages / hcapp_sendDirectMessage,
  /// which answer in the room reader's shape, so the page is unchanged.
  final HcId? threadId;

  /// The DM thread's live state (who the other party is, can we still send,
  /// is it muted), shared with the scaffold that draws the app-bar menu.
  /// Updated from rowset 1 of every read.
  final DmThreadState? dmState;

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

  _ThreadKind get _kind => threadId != null
      ? _ThreadKind.dm
      : roomType != null
      ? _ThreadKind.room
      : isKennelThread
      ? _ThreadKind.kennel
      : _ThreadKind.event;

  bool get isDirectMessage => _kind == _ThreadKind.dm;

  /// The request field naming the thread. The admin room has no id — it is
  /// THE room — so it sends none.
  String? get _idKey => switch (_kind) {
    _ThreadKind.event => 'eventId',
    _ThreadKind.kennel => 'kennelId',
    _ThreadKind.room => null,
    _ThreadKind.dm => 'threadId',
  };

  /// What [_idKey] carries: the run or kennel id, or the DM's ThreadId.
  String? get _idValue => switch (_kind) {
    _ThreadKind.event || _ThreadKind.kennel => eventId,
    _ThreadKind.room => null,
    _ThreadKind.dm => threadId,
  };

  /// A room and a DM are marked read by the same call that reads them; the
  /// run and kennel threads have their own mark-read SPs.
  bool get _readMarksRead => switch (_kind) {
    _ThreadKind.room || _ThreadKind.dm => true,
    _ThreadKind.event || _ThreadKind.kennel => false,
  };

  String get _getQueryType => switch (_kind) {
    _ThreadKind.event => 'getEventMessages',
    _ThreadKind.kennel => 'getKennelMessages',
    _ThreadKind.room => 'getRoomMessages',
    _ThreadKind.dm => 'getDirectMessages',
  };

  String get _getProcName => switch (_kind) {
    _ThreadKind.event => 'hcapp_getEventMessages',
    _ThreadKind.kennel => 'hcapp_getKennelMessages',
    _ThreadKind.room => 'hcapp_getRoomMessages',
    _ThreadKind.dm => 'hcapp_getDirectMessages',
  };

  String get _sendQueryType => switch (_kind) {
    _ThreadKind.event => 'sendEventMessage',
    _ThreadKind.kennel => 'sendKennelMessage',
    _ThreadKind.room => 'sendRoomMessage',
    _ThreadKind.dm => 'sendDirectMessage',
  };

  String get _sendProcName => switch (_kind) {
    _ThreadKind.event => 'hcapp_sendEventMessage',
    _ThreadKind.kennel => 'hcapp_sendKennelMessage',
    _ThreadKind.room => 'hcapp_sendRoomMessage',
    _ThreadKind.dm => 'hcapp_sendDirectMessage',
  };

  final chatController = core.InMemoryChatController();
  final _userCache = <String, core.User>{};

  late core.User currentUser;
  StreamSubscription<RemoteMessage>? _fcmSubscription;

  int? _lastKnownSequenceCount;

  /// The server's clock at the last fetch, echoed back as reactionsSince so
  /// the readers hand back reactions on messages this page already holds
  /// (E9.F1.S22) — a reaction changes an OLD row, which the sequence-count
  /// delta would never see. Server time, never the phone's.
  String? _reactionsAsOf;

  /// The message a reply is being written to, or null (E9.F1.S21). The
  /// composer shows a quote bar while it is set; sending clears it.
  final Rxn<core.Message> replyingTo = Rxn<core.Message>();

  void cancelReply() => replyingTo.value = null;

  /// The author's name as the chat shows it — "You" for one's own.
  String replyAuthorName(core.Message m) =>
      m.authorId == currentUser.id ? 'You' : _authorNameOf(m);

  /// False until the FIRST full fetch has answered (with rows, none, or an
  /// error). The page shows a spinner until then: 'No messages yet' while
  /// the load is in flight reads as an empty chat (James, 2026-09-30).
  final RxBool initialLoadDone = false.obs;

  bool _isFetching = false;
  bool _pendingFetch = false;

  /// The next fetch asks for the WHOLE thread (since = null), not a delta.
  /// A flag rather than nulling [_lastKnownSequenceCount]: a fetch already
  /// in flight would write its own sequence count back over the null, and
  /// the queued fetch would go out as a delta after all.
  bool _fullFetchWanted = false;

  /// "Always use this map app", for a location card's tap — the same
  /// chooser the run pin uses (Utilities.showOnMap).
  final ValueNotifier<bool> saveUserMapPreference = ValueNotifier<bool>(false);

  /// Every chat page on screen. Each page owns its controller (see
  /// ChatPage.build), so the app's resume handler cannot look one up in the
  /// GetX registry; it refreshes all of these instead.
  static final Set<ChatPageController> open = <ChatPageController>{};

  @override
  void onClose() {
    open.remove(this);
    unawaited(_fcmSubscription?.cancel());
    chatController.dispose();
    saveUserMapPreference.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    open.add(this);

    final String? publicHasherId = getStringPref(
      StringPrefsEnum.publicHasherId,
    );
    if (publicHasherId == null || publicHasherId.isEmpty) {
      debugPrint(
        'ChatPageController: publicHasherId not available, cannot open chat',
      );
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

  /// Fetch the whole thread again and replace what is on screen.
  ///
  /// A delta by sequence number can only ADD messages, and a block (or an
  /// unblock) changes which of the existing ones the server will show this
  /// hasher at all — so after either, the thread is asked for in full.
  Future<void> refetchAll() async {
    _fullFetchWanted = true;
    await _fetchDelta();
  }

  /// Every chat on screen, in full — for the Blocked Hashers page, whose
  /// Unblock changes what a chat open underneath it should be showing.
  static void refetchOpenThreads() {
    for (final ChatPageController c in List.of(open)) {
      if (!c.isClosed) unawaited(c.refetchAll());
    }
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
      if (threadId != null) {
        // A DM is keyed by its ThreadId, like a room by its type.
        notifications.clearUnreadForDm(threadId!);
      } else if (roomType != null) {
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

    _fcmSubscription = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) {
      // Only act on (and log) pushes for THIS chat — every other foreground push
      // used to hit an error-level log with a full data interpolation.
      if (!_pushIsForThisThread(message.payload)) return;
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
      case _ThreadKind.dm:
        // The payload is read through message.payload, which lowercases every
        // GUID, and threadId is an HcId — so a plain == is the right test.
        if ('${data['ThreadKind'] ?? ''}' != 'dm') return false;
        final HcId? pushed = HcId.tryParse(data['ThreadId']);
        return pushed != null && pushed == threadId;
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
      } else if (msg is core.CustomMessage) {
        // A location card (E9.F1.S12).
        updated = msg.copyWith(status: core.MessageStatus.delivered);
      }
      if (updated != null)
        unawaited(chatController.updateMessage(msg, updated));
    }
  }

  Future<void> _fetchDelta() async {
    if (_isFetching) {
      _pendingFetch = true;
      return;
    }
    _isFetching = true;
    try {
      final int? sinceSeq = _fullFetchWanted ? null : _lastKnownSequenceCount;
      _fullFetchWanted = false;
      final result = await _getEventMessages(sinceSequenceCount: sinceSeq);
      // The page can be gone by the time the fetch lands — open a chat and
      // leave again inside the round trip and the InMemoryChatController has
      // been closed, so setMessages throws "Cannot add new events after
      // calling close" into the void. Seen on 3.1.0+1358 while opening and
      // closing rooms quickly (2026-09-14). isClosed is the GetxController's
      // own disposal flag, checked after EVERY await below, because each one
      // is a fresh chance for the page to have gone.
      if (isClosed) return;
      if (sinceSeq == null) initialLoadDone.value = true;
      if (result == null || result.startsWith(ERROR_PREFIX)) return;
      final outerItem = jsonDecode(result) as List<dynamic>;
      if (outerItem.isEmpty) return;
      // Deletions first, and before the empty-delta return below: a delta
      // that brings no new message can still carry a removal (E9.F1.S13).
      await _applyRemovedIds(outerItem);
      if (isClosed) return;
      _applyDmThreadRow(outerItem);
      // Reactions on messages already drawn, and the watermark for next time
      // — before the empty-delta return, as with removals.
      await _applyReactionRowsets(outerItem);
      if (isClosed) return;
      final rawMessages = outerItem[0] as List<dynamic>;
      if (rawMessages.isEmpty) {
        // A FULL fetch that comes back empty is an answer, not a no-op: the
        // thread has nothing this hasher may see (every message was from
        // someone they just blocked), so the screen must empty too.
        if (sinceSeq == null && chatController.messages.isNotEmpty) {
          await chatController.setMessages(<core.Message>[]);
        }
        return;
      }

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

  /// A DM read ends with `{ canSend, muted, otherDisplayName, ... }` between
  /// the messages and the removed ids. Found by its column name, never by
  /// position, for the same reason as [_applyRemovedIds].
  void _applyDmThreadRow(List<dynamic> rowsets) {
    final DmThreadState? state = dmState;
    if (state == null) return;
    for (final dynamic rowset in rowsets.skip(1)) {
      if (rowset is! List || rowset.isEmpty) continue;
      final dynamic first = rowset.first;
      if (first is! Map<String, dynamic> || !first.containsKey('canSend')) {
        continue;
      }
      state.applyThreadRow(first);
      // The other party's name and photo as the chat draws them.
      final HcId other = state.otherPublicHasherId.value;
      if (other.isValid) {
        _userCache[other] = core.User(
          id: other,
          name: state.otherDisplayName.value,
          imageSource: state.otherPhoto.value.isEmpty
              ? null
              : state.otherPhoto.value,
        );
      }
      return;
    }
  }

  Future<void> _markEventChatRead() async {
    // A room has no id to name, so there is no separate mark-read SP for it
    // — hcapp_getRoomMessages does the job with @markRead, and a DM's reader
    // does the same. Without this guard `_idKey!` below is a null check on
    // null, thrown inside the unawaited() call in onInitAsync and surfacing
    // as an unhandled async error every single time the room is opened.
    if (_readMarksRead) return;

    final userId = currentUserId;
    final deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': isKennelThread
            ? 'markKennelChatRead'
            : 'markEventChatRead',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          userId,
          isKennelThread
              ? 'hcapp_markKennelChatRead'
              : 'hcapp_markEventChatRead',
          paramString: deviceSecret,
        ),
        _idKey!: eventId,
      }),
    );

    debugPrint(
      result.startsWith(ERROR_PREFIX)
          ? 'SP [markEventChatRead] called — FAILED'
          : 'SP [markEventChatRead] called — success',
    );
  }

  Future<String?> _getEventMessages({int? sinceSequenceCount}) async {
    final String userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final body = <String, dynamic>{
      'queryType': _getQueryType,
      'deviceId': deviceId,
      ?_idKey: _idValue,
      // A room is named by its type. A room and a DM are marked read by the
      // same call that reads them.
      if (roomType != null) 'roomType': roomType,
      if (_readMarksRead) 'markRead': 1,
    };
    if (sinceSequenceCount != null) {
      body['sinceSequenceCount'] = sinceSequenceCount;
    }
    if (_reactionsAsOf != null) {
      body['reactionsSince'] = _reactionsAsOf;
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
      result.add(
        _messageFor(
          id: HcId((msg['id'] as String?) ?? ''),
          authorId: authorId,
          content: (msg['text'] as String?) ?? '',
          // An older reader has no messageKind and no canDelete: text, and
          // not deletable — the server decides that, never this side.
          kind: ChatMessageKind.fromJson(msg['messageKind']),
          canDelete: msg['canDelete'] == 1 || msg['canDelete'] == true,
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
          extraMeta: _replyAndReactionMeta(msg),
        ),
      );
    }
    // SP returns newest-first; reverse to oldest-first for display and
    // for oldest→newest insertMessage ordering on delta loads.
    return result.reversed.toList();
  }

  // ── Message kinds (E9.F1.S11/S12) ────────────────────────────────────────

  /// Metadata keys every message this controller builds carries. The chat
  /// library's message types say how a bubble LOOKS; these say what the
  /// server knows about it.
  static const String _kKind = 'hcKind';
  static const String _kCanDelete = 'hcCanDelete';

  /// The message's content as the server holds it: the text, the photo's
  /// blob URL, or the location's maps link. '' for a photo still uploading.
  static const String _kContent = 'hcContent';

  /// One message, drawn the way its kind asks. A kind this build does not
  /// know — or a photo / location whose content is not what this app would
  /// have sent — falls back to a text bubble showing the content, so nothing
  /// is ever silently dropped.
  core.Message _messageFor({
    required String id,
    required String authorId,
    required String content,
    required int kind,
    required bool canDelete,
    DateTime? createdAt,
    core.MessageStatus? status,
    String? localPath,
    double? width,
    double? height,
    int? size,
    Map<String, dynamic>? extraMeta,
  }) {
    final Map<String, dynamic> meta = <String, dynamic>{
      _kKind: kind,
      _kCanDelete: canDelete,
      _kContent: content,
      ...?extraMeta,
    };
    if (kind == ChatMessageKind.photo &&
        (localPath != null || isChatPhotoUrl(content))) {
      return core.Message.image(
        id: id,
        authorId: authorId,
        source: localPath ?? content,
        createdAt: createdAt,
        status: status,
        width: width,
        height: height,
        size: size,
        metadata: meta,
      );
    }
    if (kind == ChatMessageKind.location) {
      final ChatLocation? at = ChatLocation.parseUrl(content);
      if (at != null) {
        return core.Message.custom(
          id: id,
          authorId: authorId,
          createdAt: createdAt,
          status: status,
          metadata: <String, dynamic>{
            ...meta,
            kChatLocationLatKey: at.latitude,
            kChatLocationLngKey: at.longitude,
          },
        );
      }
    }
    return core.Message.text(
      id: id,
      authorId: authorId,
      text: content,
      createdAt: createdAt,
      status: status,
      metadata: meta,
    );
  }

  // ── Replies and reactions (E9.F1.S21 / S22) ───────────────────────────────

  /// The reply and reaction fields of one reader row, as message metadata.
  /// Older readers have none of them: nothing is added and nothing breaks.
  static Map<String, dynamic> _replyAndReactionMeta(Map<String, dynamic> msg) {
    final Map<String, dynamic> out = <String, dynamic>{};
    final String? replyTo = msg['replyToMessageId'] as String?;
    if (replyTo != null && replyTo.isNotEmpty) {
      out[kChatReplyToKey] = replyTo.toLowerCase();
      out[kChatReplyTextKey] = msg['replyToText'] as String?;
      out[kChatReplyKindKey] = (msg['replyToKind'] as num?)?.toInt() ?? 0;
      out[kChatReplyAuthorKey] = msg['replyToAuthor'] as String?;
      out[kChatReplyRemovedKey] =
          (msg['replyToRemoved'] == 1 || msg['replyToRemoved'] == true) ? 1 : 0;
    }
    final Map<String, List<String>> reactions = parseChatReactions(
      msg['reactions'],
    );
    if (reactions.isNotEmpty) out[kChatReactionsKey] = reactions;
    return out;
  }

  /// The two rowsets every reader now ends with: `{ id, reactions }` for
  /// messages this page already holds whose reactions changed, then
  /// `{ reactionsAsOf }`. Found by column, never by position — the room and
  /// DM readers have a badge rowset in the middle and older builds' rowsets
  /// must keep their places.
  Future<void> _applyReactionRowsets(List<dynamic> rowsets) async {
    for (final dynamic rowset in rowsets.skip(1)) {
      if (rowset is! List || rowset.isEmpty) continue;
      final dynamic first = rowset.first;
      if (first is! Map<String, dynamic>) continue;
      if (first.containsKey('reactionsAsOf')) {
        final Object? asOf = first['reactionsAsOf'];
        if (asOf != null) _reactionsAsOf = asOf.toString();
        continue;
      }
      if (!first.containsKey('reactions') ||
          !first.containsKey('id') ||
          first.containsKey('sequenceCount')) {
        continue;
      }
      for (final dynamic row in rowset) {
        if (row is! Map<String, dynamic>) continue;
        final String id = ((row['id'] as String?) ?? '').toLowerCase();
        if (id.isEmpty) continue;
        await _setReactions(id, parseChatReactions(row['reactions']));
        if (isClosed) return;
      }
    }
  }

  /// Repaint one message with [reactions] (empty = none, key dropped).
  Future<void> _setReactions(
    String messageId,
    Map<String, List<String>> reactions,
  ) async {
    final core.Message? m = chatController.messages
        .where((x) => x.id == messageId)
        .firstOrNull;
    if (m == null) return;
    final Map<String, dynamic> meta = <String, dynamic>{...?m.metadata};
    if (reactions.isEmpty) {
      meta.remove(kChatReactionsKey);
    } else {
      meta[kChatReactionsKey] = reactions;
    }
    await chatController.updateMessage(m, m.copyWith(metadata: meta));
  }

  /// The reactions a message carries, as the decorations read them.
  static Map<String, List<String>> reactionsOf(core.Message m) {
    final Object? raw = m.metadata?[kChatReactionsKey];
    if (raw is Map<String, List<String>>) return raw;
    return parseChatReactions(raw is Map ? jsonEncode(raw) : raw);
  }

  /// The codes the signed-in hasher has put on [m].
  Set<String> myReactionsOn(core.Message m) => <String>{
    for (final MapEntry<String, List<String>> e in reactionsOf(m).entries)
      if (e.value.contains(currentUser.id)) e.key,
  };

  /// Add or remove my [code] on [m]: the chip changes at once, the server is
  /// asked, and its answer replaces the guess — or the guess is undone and
  /// the refusal toasted.
  Future<void> toggleReaction(core.Message m, String code) async {
    if (!ChatReaction.isKnown(code) || m.status == core.MessageStatus.sending) {
      return;
    }
    final Map<String, List<String>> before = reactionsOf(m);
    final bool on = !(before[code] ?? const <String>[]).contains(
      currentUser.id,
    );
    final Map<String, List<String>> guess = <String, List<String>>{
      for (final MapEntry<String, List<String>> e in before.entries)
        e.key: List<String>.of(e.value),
    };
    if (on) {
      (guess[code] ??= <String>[]).add(currentUser.id);
    } else {
      guess[code]?.remove(currentUser.id);
      if ((guess[code] ?? const <String>[]).isEmpty) guess.remove(code);
    }
    await _setReactions(m.id, guess);
    if (isClosed) return;

    final ReactionOutcome outcome = await ChatReactionService.react(
      HcId(m.id),
      code,
      on: on,
    );
    if (isClosed) return;
    if (outcome.ok) {
      await _setReactions(m.id, outcome.reactions!);
      return;
    }
    await _setReactions(m.id, before);
    if (isClosed) return;
    final String? why = outcome.refusal;
    hcSnack(
      (why == null || why.isEmpty)
          ? 'That reaction could not be saved. Please try again.'
          : why,
      error: true,
    );
  }

  /// What Copy puts on the clipboard: the text, or the photo / location URL.
  String _copyTextFor(core.Message m) {
    final Object? content = m.metadata?[_kContent];
    if (content is String && content.isNotEmpty) return content;
    if (m is core.TextMessage) return m.text;
    return '';
  }

  /// The photo's public URL, once it has one — null while it is still only
  /// on this phone.
  String? _photoUrlFor(core.ImageMessage m) {
    final Object? content = m.metadata?[_kContent];
    if (content is String && isChatPhotoUrl(content)) return content;
    return isChatPhotoUrl(m.source) ? m.source : null;
  }

  /// Delete is offered when the server said this caller may delete the row
  /// (their own, or they moderate the thread), or it is a message they sent
  /// from this screen. Never while it is still sending: until the server
  /// has it there is nothing there to delete.
  bool _canDelete(core.Message m) =>
      m.metadata?[_kCanDelete] == true &&
      m.status != core.MessageStatus.sending;

  // ── Removed messages (E9.F1.S13/S14) ──────────────────────────────────────

  /// Drop every message on screen that the server lists as removed.
  ///
  /// Every reader ends with a rowset whose one column is `removedId`; the
  /// room reader has its badge rowset in between, so it is found by the
  /// column name, never by position. A delta fetch by sequence number never
  /// sees a deletion otherwise — the removed row simply stops coming back —
  /// so without this a message deleted elsewhere stayed on this phone for
  /// as long as the chat was open. Ids come UPPERCASE from SQL; HcId
  /// lowercases them to match the ids on screen.
  Future<void> _applyRemovedIds(List<dynamic> rowsets) async {
    final Set<String> removed = <String>{};
    for (final dynamic rowset in rowsets.skip(1)) {
      if (rowset is! List || rowset.isEmpty) continue;
      final dynamic first = rowset.first;
      if (first is! Map || !first.containsKey('removedId')) continue;
      for (final dynamic row in rowset) {
        final Object? id = (row as Map<String, dynamic>)['removedId'];
        if (id is String && id.isNotEmpty) removed.add(HcId(id));
      }
    }
    if (removed.isEmpty) return;
    for (final core.Message m in List.of(chatController.messages)) {
      if (isClosed) return;
      if (removed.contains(m.id.asUuid)) {
        await chatController.removeMessage(m);
      }
    }
  }

  // ── Sending ───────────────────────────────────────────────────────────────

  /// Post one message to the thread's send SP. True when the server took it.
  Future<bool> _postMessage({
    required String id,
    required String content,
    int kind = ChatMessageKind.text,
    String? replyToMessageId,
  }) async {
    final userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    String? refusal;
    num? refusalType;
    final result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': _sendQueryType,
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          userId,
          _sendProcName,
          paramString: deviceSecret,
        ),
        ?_idKey: _idValue,
        if (roomType != null) 'roomType': roomType,
        'messageId': id,
        'messageContent': content,
        // Every body key becomes an SP parameter in the shim, so a key the
        // SP does not declare is a "too many arguments" failure, not an
        // ignored extra. A room has no kennel or run to be releasable to —
        // hcapp_sendRoomMessage stores the all-audiences value itself rather
        // than accepting a parameter it would never branch on; a DM has one
        // reader and no audience at all.
        if (roomType == null && !isDirectMessage)
          'messageReleasabilityFlags': kChatReleasabilityAll,
        // Optional on all the send SPs (default 0), so text leaves it out
        // and a text send is byte-for-byte what it was before photos.
        if (kind != ChatMessageKind.text) 'messageKind': kind,
        // Optional on every send SP: a quoted message (E9.F1.S21).
        'replyToMessageId': ?replyToMessageId,
      }),
      // A DM's refusal — "You can't message <name>." (2013) — is an answer
      // about the conversation, not a fault: it goes in a toast under the
      // bubble, and the composer closes. The other kinds keep the generic
      // error dialog they have always had.
      errorCallback: isDirectMessage
          ? (DbErrorModel e) async {
              refusal = e.errorUserMessage;
              refusalType = e.errorType;
              return true;
            }
          : null,
    );
    final bool ok = !result.startsWith(ERROR_PREFIX);
    if (!ok && isDirectMessage && !isClosed) {
      if (refusal != null && refusal!.isNotEmpty) {
        hcSnack(refusal!, error: true, seconds: 5);
        // Only "not open" (errorType 3: ended, or somebody blocks) closes
        // the composer — a message that was too long, or a dropped
        // connection, is not "you can't message them".
        if (refusalType == 3) dmState?.canSend.value = false;
      } else {
        hcSnack(
          'The message could not be sent. Please try again.',
          error: true,
        );
      }
    }
    return ok;
  }

  /// Settle an optimistic bubble: one tick when the server took it, the
  /// warning when it did not. [content] records the server-side content
  /// once known (a photo's blob URL, after its upload).
  Future<void> _settle(String id, {required bool ok, String? content}) async {
    if (isClosed) return;
    final core.Message? m = chatController.messages
        .where((m) => m.id == id)
        .firstOrNull;
    if (m == null) return;
    await chatController.updateMessage(
      m,
      m.copyWith(
        status: ok ? core.MessageStatus.sent : core.MessageStatus.error,
        sentAt: ok ? DateTime.now() : null,
        metadata: <String, dynamic>{...?m.metadata, _kContent: ?content},
      ),
    );
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

    // Taken and cleared BEFORE the await: a second send while this one is
    // in flight must not quote the same message again.
    final core.Message? target = replyingTo.value;
    replyingTo.value = null;
    final Map<String, dynamic>? replyMeta = target == null
        ? null
        : <String, dynamic>{
            kChatReplyToKey: target.id,
            kChatReplyTextKey: chatMessageSnippet(target),
            kChatReplyKindKey: target.metadata?[_kKind] ?? ChatMessageKind.text,
            kChatReplyAuthorKey: replyAuthorName(target),
            kChatReplyRemovedKey: 0,
          };

    final uuid = const Uuid().v4();
    unawaited(
      chatController.insertMessage(
        _messageFor(
          id: uuid,
          authorId: currentUser.id,
          content: text,
          kind: ChatMessageKind.text,
          canDelete: true,
          createdAt: DateTime.now(),
          status: core.MessageStatus.sending,
          extraMeta: replyMeta,
        ),
      ),
    );

    final bool ok = await _postMessage(
      id: uuid,
      content: text,
      replyToMessageId: target?.id,
    );
    // Same disposal race as _fetchDelta: send, leave, and the reply lands on
    // a closed controller.
    if (isClosed) return;
    await _settle(uuid, ok: ok);
  }

  // ── The 📎 sheet ──────────────────────────────────────────────────────────

  /// A white sheet of choices; returns the chosen key, or null. Closed with
  /// hcPop, never Get.back(): with a GetX toast up, Get.back() closes the
  /// toast and leaves the sheet open (CLAUDE.md).
  Future<String?> _chooseFrom(List<_SheetChoice> choices, {Widget? header}) {
    return Get.bottomSheet<String>(
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ?header,
            for (final _SheetChoice c in choices)
              ListTile(
                leading: Icon(c.icon, color: c.colour ?? hc_blue),
                title: Text(
                  c.label,
                  style: ts_titleBlack.copyWith(color: c.colour),
                ),
                onTap: () => hcPop<String>(result: c.key),
              ),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.black54),
              title: Text('Cancel', style: ts_titleBlack),
              onTap: () => hcPop<String>(),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      barrierColor: Colors.black54,
    );
  }

  void handleAttachmentPressed() => unawaited(_attachmentMenu());

  Future<void> _attachmentMenu() async {
    final String? choice = await _chooseFrom(const <_SheetChoice>[
      _SheetChoice('library', 'Photo from library', Icons.photo_library),
      _SheetChoice('camera', 'Take a photo', Icons.photo_camera),
      _SheetChoice('location', 'Location', Icons.location_on),
    ]);
    if (isClosed) return;
    switch (choice) {
      case 'library':
        await handleImageSelection(ImageSource.gallery);
      case 'camera':
        await handleImageSelection(ImageSource.camera);
      case 'location':
        await _locationMenu();
    }
  }

  // ── Photos (E9.F1.S11) ────────────────────────────────────────────────────

  /// Pick, shrink, upload, send. The bubble appears at once with a spinner
  /// (drawn from the file on this phone), becomes one tick when the server
  /// has the message, or the warning if the upload or the send failed.
  Future<void> handleImageSelection(ImageSource source) async {
    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: ChatPhotoService.maxEdge.toDouble(),
        maxHeight: ChatPhotoService.maxEdge.toDouble(),
        // No imageQuality here: prepareJpeg encodes once, at jpegQuality.
        // Asking the picker too would compress the photo twice.
      );
    } catch (e, s) {
      // Camera or library access refused, or no camera (a simulator).
      BootLogger.logError('[ChatPageController.handleImageSelection]', e, s);
      hcSnack(
        source == ImageSource.camera
            ? 'The camera could not be opened.'
            : 'Your photos could not be opened.',
        error: true,
      );
      return;
    }
    // Picking is a long await, and the hasher can leave the chat inside it.
    if (picked == null || isClosed) return;

    final Uint8List? jpeg = await ChatPhotoService.prepareJpeg(picked);
    if (isClosed) return;
    if (jpeg == null) {
      hcSnack('That photo could not be read.', error: true);
      return;
    }

    double? width;
    double? height;
    try {
      final image = await decodeImageFromList(jpeg);
      width = image.width.toDouble();
      height = image.height.toDouble();
      image.dispose();
    } catch (_) {
      // Only the bubble's placeholder size; the upload does not need it.
    }
    if (isClosed) return;

    final String id = const Uuid().v4();
    await chatController.insertMessage(
      _messageFor(
        id: id,
        authorId: currentUser.id,
        content: '',
        kind: ChatMessageKind.photo,
        canDelete: true,
        localPath: picked.path,
        createdAt: DateTime.now(),
        status: core.MessageStatus.sending,
        width: width,
        height: height,
        size: jpeg.length,
      ),
    );

    final String? blobUrl = await ChatPhotoService.upload(jpeg);
    if (isClosed) return;
    if (blobUrl == null) {
      await _settle(id, ok: false);
      hcSnack(
        'That photo could not be uploaded. Please try again.',
        error: true,
      );
      return;
    }
    final bool ok = await _postMessage(
      id: id,
      content: blobUrl,
      kind: ChatMessageKind.photo,
    );
    if (isClosed) return;
    await _settle(id, ok: ok, content: blobUrl);
  }

  /// Every photo in this chat that has a public URL, oldest first, in a
  /// carousel starting at [tapped] — on the jungle, like every photo viewer
  /// in the app (CLAUDE.md photo rule).
  Future<void> _openPhotoCarousel(core.ImageMessage tapped) async {
    final List<core.ImageMessage> photos = chatController.messages
        .whereType<core.ImageMessage>()
        .where((core.ImageMessage m) => _photoUrlFor(m) != null)
        .toList();
    final int index = photos.indexWhere((m) => m.id == tapped.id);
    // Still uploading: nothing to show beyond the bubble itself.
    if (index < 0) return;
    final List<MapPhotoItem> items = <MapPhotoItem>[
      for (final core.ImageMessage m in photos)
        MapPhotoItem(
          imageUrl: _photoUrlFor(m)!,
          caption: '',
          uploaderName: _userCache[m.authorId]?.name ?? '',
          uploaderPhotoUrl: _userCache[m.authorId]?.imageSource ?? '',
          capturedAt: m.createdAt?.toUtc(),
        ),
    ];
    await Get.to<void>(
      () => MapPhotoPage(
        pageTitle: 'Chat photos',
        photos: items,
        initialIndex: index,
        background: Backgrounds.defaultHcBackground(),
      ),
    );
  }

  // ── Locations (E9.F1.S12) ─────────────────────────────────────────────────

  Future<void> _locationMenu() async {
    final String? choice = await _chooseFrom(const <_SheetChoice>[
      _SheetChoice('here', 'Where I am now', Icons.my_location),
      _SheetChoice('pin', 'Drop a pin', Icons.push_pin),
    ]);
    if (isClosed) return;
    switch (choice) {
      case 'here':
        await _sendCurrentLocation();
      case 'pin':
        final ChatLocation? at = await Get.to<ChatLocation>(
          () => const ChatLocationPickerPage(),
        );
        if (at == null || isClosed) return;
        await _sendLocation(at.latitude, at.longitude);
    }
  }

  /// One fresh fix, through LocationService.freshFix — which reuses the live
  /// stream's fix when it has one, so this never opens a second geolocator
  /// stream (memory: lost-compass-local-track).
  Future<void> _sendCurrentLocation() async {
    Position? fix;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (isClosed) return;
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        hcSnack(
          'Harrier Central is not allowed to see your location. '
          'You can drop a pin instead.',
          error: true,
          seconds: 5,
        );
        return;
      }
      fix = await LocationService.ensure().freshFix().timeout(
        const Duration(seconds: 20),
      );
    } catch (e, s) {
      BootLogger.logError('[ChatPageController._sendCurrentLocation]', e, s);
    }
    if (isClosed) return;
    if (fix == null) {
      hcSnack(
        'Your location could not be found. You can drop a pin instead.',
        error: true,
        seconds: 5,
      );
      return;
    }
    await _sendLocation(fix.latitude, fix.longitude);
  }

  Future<void> _sendLocation(double latitude, double longitude) async {
    final String? url = ChatLocation.buildUrl(latitude, longitude);
    if (url == null) {
      hcSnack('That location could not be sent.', error: true);
      return;
    }
    final String id = const Uuid().v4();
    await chatController.insertMessage(
      _messageFor(
        id: id,
        authorId: currentUser.id,
        content: url,
        kind: ChatMessageKind.location,
        canDelete: true,
        createdAt: DateTime.now(),
        status: core.MessageStatus.sending,
      ),
    );
    final bool ok = await _postMessage(
      id: id,
      content: url,
      kind: ChatMessageKind.location,
    );
    if (isClosed) return;
    await _settle(id, ok: ok);
  }

  // ── Taps on a message ─────────────────────────────────────────────────────

  /// A photo opens the carousel; a location opens the map app, through the
  /// same chooser as the run pin. Text taps are the links' business (their
  /// own recognizers win the gesture), so they end here doing nothing.
  void handleMessageTap(
    BuildContext context,
    core.Message message, {
    required int index,
    required TapUpDetails details,
  }) {
    if (message is core.ImageMessage) {
      unawaited(_openPhotoCarousel(message));
      return;
    }
    final ChatLocation? at = chatLocationOf(message);
    if (at != null) {
      unawaited(
        Utilities.showOnMap(
          context,
          'Location',
          maps.Coords(at.latitude, at.longitude),
          at.display,
          saveUserMapPreference,
        ),
      );
    }
  }

  /// Copy always; Delete when this caller may (E9.F1.S13-S15); Report and
  /// Block on anyone else's message (E9.F1.S16/S17).
  void handleMessageLongPress(
    BuildContext context,
    core.Message message, {
    required int index,
    required LongPressStartDetails details,
  }) => unawaited(_messageMenu(message));

  /// Someone else's message — the only kind that can be reported or whose
  /// author can be blocked. The server refuses both for one's own, so the
  /// menu does not offer them.
  bool _isFromSomeoneElse(core.Message m) =>
      m.authorId.isNotEmpty && m.authorId != currentUser.id;

  /// The author's name as the chat shows it, for the "Block …?" line.
  String _authorNameOf(core.Message m) {
    final String? name = _userCache[m.authorId]?.name;
    return (name == null || name.trim().isEmpty) ? 'this hasher' : name.trim();
  }

  Future<void> _messageMenu(core.Message message) async {
    final String copyText = _copyTextFor(message);
    final bool canDelete = _canDelete(message);
    final bool fromSomeoneElse = _isFromSomeoneElse(message);
    // A message the server has is one that can be replied to or reacted to
    // — never one still on its way up.
    final bool onServer =
        message.status != core.MessageStatus.sending &&
        message.status != core.MessageStatus.error;
    if (copyText.isEmpty && !canDelete && !fromSomeoneElse && !onServer) return;
    final String? choice = await _chooseFrom(
      <_SheetChoice>[
        if (onServer) const _SheetChoice('reply', 'Reply', Icons.reply),
        // The only door to a direct message (E9.F1.S19): the people you can
        // already see. Not offered inside a DM — you are already talking.
        if (fromSomeoneElse && !isDirectMessage)
          _SheetChoice(
            'message',
            'Message ${_authorNameOf(message)}',
            Icons.mail_outline,
          ),
        if (copyText.isNotEmpty) const _SheetChoice('copy', 'Copy', Icons.copy),
        if (fromSomeoneElse) ...<_SheetChoice>[
          const _SheetChoice('report', 'Report', Icons.flag_outlined),
          _SheetChoice(
            'block',
            'Block ${_authorNameOf(message)}',
            Icons.block,
            colour: hc_red,
          ),
        ],
        if (canDelete)
          _SheetChoice(
            'delete',
            'Delete',
            Icons.delete_outline,
            colour: hc_red,
          ),
      ],
      header: onServer
          ? ChatReactionPicker(
              mine: myReactionsOn(message),
              onPick: (String code) => hcPop<String>(result: 'react:$code'),
            )
          : null,
    );
    if (isClosed) return;
    if (choice != null && choice.startsWith('react:')) {
      await toggleReaction(message, choice.substring('react:'.length));
      return;
    }
    switch (choice) {
      case 'reply':
        replyingTo.value = message;
      case 'message':
        await _startDirectMessage(message);
      case 'copy':
        await Clipboard.setData(ClipboardData(text: copyText));
        hcSnack('Copied');
      case 'report':
        await _reportMessage(message);
      case 'block':
        await _confirmAndBlock(message);
      case 'delete':
        await _confirmAndDelete(message.id);
    }
  }

  // ── Direct messages (E9.F1.S19) ───────────────────────────────────────────

  /// "Message `<name>`". The server answers open / requested / refused /
  /// blocked from THEIR preference and the friendship rows; this only shows
  /// what it said. A block is never revealed to the blocked side: that case
  /// comes back as "requested", by design.
  Future<void> _startDirectMessage(core.Message message) async {
    if (!_isFromSomeoneElse(message)) return;
    final String name = _authorNameOf(message);
    String? refusal;
    final DmStartResult? result = await DirectMessageService.start(
      HcId(message.authorId),
      onRefused: (String? why) => refusal = why,
    );
    if (isClosed) return;

    if (result == null) {
      hcSnack(
        (refusal == null || refusal!.isEmpty)
            ? '$name could not be messaged. Please try again.'
            : refusal!,
        error: true,
        seconds: 5,
      );
      return;
    }

    final String other = result.otherDisplayName;
    switch (result.outcome) {
      case DmOutcome.open:
        final HcId? thread = result.threadId;
        if (thread == null) {
          hcSnack(
            '$other could not be messaged. Please try again.',
            error: true,
          );
          return;
        }
        await openDirectMessage(
          threadId: thread,
          otherPublicHasherId: result.otherPublicHasherId,
          otherDisplayName: other,
          otherPhoto: result.otherPhoto,
        );
      case DmOutcome.requested:
        hcSnack(
          "$other will be asked. You'll be told when they accept.",
          seconds: 5,
        );
      case DmOutcome.refused:
        hcSnack("$other isn't accepting messages.", error: true, seconds: 5);
      case DmOutcome.blocked:
        hcSnack(
          "You've blocked $other.",
          error: true,
          seconds: 6,
          actionLabel: 'Unblock',
          onAction: () =>
              unawaited(_unblock(result.otherPublicHasherId, other)),
        );
      case DmOutcome.declined:
      case DmOutcome.unknown:
        hcSnack('$other could not be messaged right now.', error: true);
    }
  }

  Future<void> _unblock(HcId publicHasherId, String name) async {
    final BlockOutcome outcome = await HasherBlockService.setBlock(
      publicHasherId,
      blocked: false,
    );
    if (isClosed) return;
    if (!outcome.ok) {
      final String? why = outcome.refusal;
      hcSnack(
        (why == null || why.isEmpty)
            ? '$name could not be unblocked. Please try again.'
            : why,
        error: true,
        seconds: 5,
      );
      return;
    }
    hcSnack('$name unblocked');
    // Their messages come back into every chat, including this one.
    refetchOpenThreads();
  }

  /// Open a DM thread standalone, then refresh the badges on return so the
  /// chat list and the app-bar bubble agree with what was read.
  static Future<void> openDirectMessage({
    required HcId threadId,
    required HcId otherPublicHasherId,
    required String otherDisplayName,
    String? otherPhoto,
  }) async {
    await Get.to<void>(
      () => ChatScaffold.dm(
        threadId: threadId,
        otherPublicHasherId: otherPublicHasherId,
        otherDisplayName: otherDisplayName,
        otherPhoto: otherPhoto,
        key: UniqueKey(),
      ),
    );
    if (Get.isRegistered<NotificationService>()) {
      unawaited(Get.find<NotificationService>().getEventChatMessageCounts());
    }
  }

  // ── Block (E9.F1.S16) ─────────────────────────────────────────────────────

  /// "Block `<name>`?" — shared with the DM app bar, which blocks the other
  /// party without a message to long-press.
  static Future<bool> confirmBlock(String name) async {
    final bool? yes = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Block $name?', style: ts_alertDialogTitle),
        content: Text(
          "You won't see their messages in any chat, and they won't be told.",
          style: ts_alertDialogBody,
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.blueGrey),
            onPressed: () => hcPop<bool>(result: false),
            child: Text(
              'Cancel',
              style: ts_button,
              textAlign: TextAlign.center,
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(backgroundColor: hc_red),
            onPressed: () => hcPop<bool>(result: true),
            child: Text('Block', style: ts_button, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
    return yes ?? false;
  }

  /// Block the message's author, then fetch the thread again in full: the
  /// server now leaves out everything they wrote, and only a full fetch
  /// takes what is already on screen away.
  Future<void> _confirmAndBlock(core.Message message) async {
    if (isClosed || !_isFromSomeoneElse(message)) return;
    final String name = _authorNameOf(message);
    if (!await confirmBlock(name) || isClosed) return;

    // authorId is already an HcId-shaped lowercase string (parsed through
    // asUuid); the SP accepts either case, HcId keeps it to one.
    final BlockOutcome outcome = await HasherBlockService.setBlock(
      HcId(message.authorId),
      blocked: true,
    );
    if (isClosed) return;

    if (!outcome.ok) {
      final String? why = outcome.refusal;
      hcSnack(
        (why == null || why.isEmpty)
            ? '$name could not be blocked. Please try again.'
            : why,
        error: true,
        seconds: 5,
      );
      return;
    }
    hcSnack('Blocked');
    await refetchAll();
  }

  // ── Report (E9.F1.S17) ────────────────────────────────────────────────────

  /// A white sheet: what a report does, an optional reason (capped where the
  /// SP caps it), Send. Returns the reason ('' for none), or null if the
  /// hasher backed out.
  Future<String?> _reportSheet() async {
    final TextEditingController reason = TextEditingController();
    final String? result = await Get.bottomSheet<String>(
      // The sheet rises with the keyboard: viewInsets read from a context
      // INSIDE the sheet, which is the one that rebuilds when it opens.
      Builder(
        builder: (BuildContext context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Report this message',
                    style: ts_alertDialogTitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "This sends the message to Harrier Central's reviewers. "
                    'Nobody at Harrier Central reads chats otherwise.',
                    style: ts_alertDialogBody,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reason,
                    autofocus: true,
                    maxLength: kChatReportReasonMaxLength,
                    maxLines: 4,
                    minLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    style: ts_alertDialogBody,
                    decoration: const InputDecoration(
                      hintText: 'Why are you reporting it? (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Wrap, not Row: two buttons at a large text size are
                  // wider than a phone.
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: <Widget>[
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                        ),
                        onPressed: () => hcPop<String>(),
                        child: Text(
                          'Cancel',
                          style: ts_button,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.flag, color: Colors.white),
                        label: Text(
                          'Send report',
                          style: ts_button,
                          textAlign: TextAlign.center,
                        ),
                        onPressed: () =>
                            hcPop<String>(result: reason.text.trim()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      barrierColor: Colors.black54,
      isScrollControlled: true,
    );
    // The route's future completes as the sheet starts to leave; its
    // TextField is still drawn for the exit animation.
    unawaited(Future<void>.delayed(const Duration(seconds: 1), reason.dispose));
    return result;
  }

  Future<void> _reportMessage(core.Message message) async {
    if (!_isFromSomeoneElse(message)) return;
    final String? reason = await _reportSheet();
    if (reason == null || isClosed) return;

    final ReportOutcome outcome = await ChatReportService.report(
      HcId(message.id),
      reason: reason,
    );
    if (isClosed) return;

    if (!outcome.ok) {
      final String? why = outcome.refusal;
      hcSnack(
        (why == null || why.isEmpty)
            ? 'The report could not be sent. Please try again.'
            : why,
        error: true,
        seconds: 5,
      );
      return;
    }
    // Block offered as the follow-up: a report changes nothing on this
    // phone, and the hasher most likely wants to stop seeing this person.
    hcSnack(
      'Reported — thank you.',
      seconds: 6,
      actionLabel: 'Block',
      onAction: () => unawaited(_confirmAndBlock(message)),
    );
  }

  Future<bool> _confirmDelete() async {
    final bool? yes = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Delete this message?', style: ts_alertDialogTitle),
        content: Text(
          'It will be removed for everyone in this chat.',
          style: ts_alertDialogBody,
        ),
        actions: <Widget>[
          // hcPop, not Get.back(): a "Copied" toast still up would make
          // Get.back() close the toast and leave this dialog open.
          TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.blueGrey),
            onPressed: () => hcPop<bool>(result: false),
            child: Text(
              'Cancel',
              style: ts_button,
              textAlign: TextAlign.center,
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(backgroundColor: hc_red),
            onPressed: () => hcPop<bool>(result: true),
            child: Text(
              'Delete',
              style: ts_button,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
    return yes ?? false;
  }

  /// Remove the bubble at once, then ask the server; put it back, in the
  /// same place, if the server refuses.
  Future<void> _confirmAndDelete(String id) async {
    if (!await _confirmDelete() || isClosed) return;
    final List<core.Message> before = List.of(chatController.messages);
    final int position = before.indexWhere((m) => m.id == id);
    if (position < 0) return; // gone already — removed by a fetch meanwhile
    final core.Message message = before[position];
    await chatController.removeMessage(message);

    // Never reached the server: removing it here is the whole job.
    if (message.status == core.MessageStatus.error) return;

    String? refusal;
    final String result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'deleteChatMessage',
        'deviceId': getStringPref(StringPrefsEnum.deviceId) ?? '',
        'accessToken': Utilities.generateToken(
          currentUserId,
          'hcapp_deleteChatMessage',
          paramString: getStringPref(StringPrefsEnum.deviceSecret) ?? '',
        ),
        'messageId': id,
      }),
      // The server's reason goes in a toast under the restored bubble,
      // rather than the generic error dialog on top of it.
      errorCallback: (DbErrorModel e) async {
        refusal = e.errorUserMessage;
        return true;
      },
    );
    if (isClosed) return;

    bool ok = false;
    if (!result.startsWith(ERROR_PREFIX)) {
      try {
        final List<dynamic> rowsets = jsonDecode(result) as List<dynamic>;
        final Map<String, dynamic>? row = rowsets.isEmpty
            ? null
            : firstRow(rowsets[0] as List<dynamic>?);
        ok = row?['success'] == 1 || row?['success'] == true;
      } catch (_) {}
    }
    if (ok) return;

    if (!chatController.messages.any((m) => m.id == id)) {
      await chatController.insertMessage(
        message,
        index: position.clamp(0, chatController.messages.length),
        animated: false,
      );
    }
    hcSnack(
      (refusal == null || refusal!.isEmpty)
          ? 'That message could not be deleted. Please try again.'
          : refusal!,
      error: true,
      seconds: 5,
    );
  }
}

/// One line of a [ChatPageController] choice sheet.
class _SheetChoice {
  const _SheetChoice(this.key, this.label, this.icon, {this.colour});
  final String key;
  final String label;
  final IconData icon;
  final Color? colour;
}

/// The four kinds of thread [ChatPageController] serves. Private: callers
/// pass the public flags, and this is how the controller reasons about them.
enum _ThreadKind { event, kennel, room, dm }
