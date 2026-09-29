// ignore_for_file: require_trailing_commas

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as core;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hcportal/admin_pages/chat_page/chat_message_kinds.dart';
import 'package:hcportal/admin_pages/chat_page/chat_photo_carousel.dart';
import 'package:hcportal/admin_pages/chat_page/chat_pin_picker.dart';
import 'package:hcportal/imports.dart';
import 'package:web/web.dart' as web;

class ChatSheetController extends GetxController {
  ChatSheetController({
    required this.publicEventId,
    required this.messageTitle,
    this.runLat,
    this.runLng,
  });

  String publicEventId;
  String messageTitle;

  /// Where the pin picker opens (the run's location, when it has one).
  final double? runLat;
  final double? runLng;

  /// Ids of messages this user may delete (their own, or any when they
  /// moderate this run's chat) — the SP's `canDelete` (E9.F1.S13/S14).
  final _canDeleteIds = <String>{};

  /// The message the mouse is over — its menu button shows (web hover menu).
  final RxnString hoveredId = RxnString();

  /// True while a photo is being resized and uploaded.
  final RxBool isUploading = false.obs;

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
      if (result != null) {
        final outerItem = jsonDecode(result) as List<dynamic>;
        final rawMessages = outerItem.isEmpty
            ? const <dynamic>[]
            : outerItem[0] as List<dynamic>;

        final newSeq = _extractMaxSequenceCount(rawMessages);
        if (newSeq != null) _lastKnownSequenceCount = newSeq;

        final removed = _removedIds(outerItem);
        final messages = _parseMessages(
          rawMessages,
        ).where((m) => !removed.contains(m.id)).toList();
        await chatController.setMessages(messages);

        final chatsCounts =
            (box.get(HIVE_CHATS_COUNT) as Map?)?.cast<String, int>() ?? {};
        chatsCounts[publicEventId] = messages.length;
        await box.put(HIVE_CHATS_COUNT, chatsCounts);
      }

      unawaited(_markEventChatRead(publicEventId));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ChatSheetController] onInitAsync load error: $e');
      }
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
              if (kDebugMode) {
                debugPrint('[ChatSheetController] _refreshMessages error: $e');
              }
            }),
          );
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[ChatSheetController] onMessage handler error: $e');
          }
        }
      },
      onError: (Object e, StackTrace st) {
        if (kDebugMode) {
          debugPrint('[ChatSheetController] FCM stream error: $e');
        }
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
          if (kDebugMode) debugPrint('[ChatSheetController] poll error: $e');
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
      if (result == null) return;
      final outerItem = jsonDecode(result) as List<dynamic>;
      // A deletion changes no sequence number, so the delta never carries it:
      // every fetch returns the removed ids and we drop any we still show.
      await _applyRemoved(_removedIds(outerItem));
      if (outerItem.isEmpty) return;
      final rawMessages = outerItem[0] as List<dynamic>;
      if (rawMessages.isEmpty) return;

      final newSeq = _extractMaxSequenceCount(rawMessages);
      if (newSeq != null) _lastKnownSequenceCount = newSeq;

      final messages = _parseMessages(rawMessages);
      for (final msg in messages) {
        final existing = chatController.messages.firstWhereOrNull(
          (m) => m.id == msg.id,
        );
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
      if (kDebugMode) {
        debugPrint('[ChatSheetController] _refreshMessages exception: $e\n$st');
      }
    } finally {
      _isRefreshing = false;
      if (_pendingRefresh) {
        _pendingRefresh = false;
        unawaited(_refreshMessages());
      }
    }
  }

  void _upgradeToDelivered(core.Message msg) {
    final updated = _withStatus(msg, core.MessageStatus.delivered);
    if (updated != null) unawaited(chatController.updateMessage(msg, updated));
  }

  /// [msg] with a new status, for the kinds this chat draws.
  core.Message? _withStatus(
    core.Message msg,
    core.MessageStatus status, {
    DateTime? sentAt,
  }) => switch (msg) {
    core.TextMessage() => msg.copyWith(
      status: status,
      sentAt: sentAt ?? msg.sentAt,
    ),
    core.ImageMessage() => msg.copyWith(
      status: status,
      sentAt: sentAt ?? msg.sentAt,
    ),
    core.CustomMessage() => msg.copyWith(
      status: status,
      sentAt: sentAt ?? msg.sentAt,
    ),
    core.FileMessage() => msg.copyWith(
      status: status,
      sentAt: sentAt ?? msg.sentAt,
    ),
    _ => null,
  };

  /// The ids in the reply's `{ removedId }` rowset (the last one). Lowercase,
  /// like every id this controller holds.
  Set<String> _removedIds(List<dynamic> outerItem) {
    final ids = <String>{};
    for (var i = 1; i < outerItem.length; i++) {
      final rowset = outerItem[i];
      if (rowset is! List) continue;
      for (final row in rowset) {
        if (row is Map && row['removedId'] is String) {
          ids.add((row['removedId'] as String).asUuid);
        }
      }
    }
    return ids;
  }

  Future<void> _applyRemoved(Set<String> removed) async {
    if (removed.isEmpty || isClosed) return;
    final gone = chatController.messages
        .where((m) => removed.contains(m.id))
        .toList();
    for (final m in gone) {
      await chatController.removeMessage(m);
      _canDeleteIds.remove(m.id);
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

  Future<void> _markEventChatRead(String publicEventId) async {
    final deviceId = box.get(HIVE_DEVICE_ID) as String;
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
    final accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_markEventChatRead',
      paramString: '$deviceSecret:$publicEventId',
    );
    final body = <String, dynamic>{
      'queryType': 'markEventChatRead',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'publicEventId': publicEventId,
    };
    final result = await ServiceCommon.sendHttpPostToHC6Api(body);
    if (kDebugMode) {
      debugPrint(
        result is ApiError
            ? 'SP [markEventChatRead] called — FAILED'
            : 'SP [markEventChatRead] called — success',
      );
    }
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
      paramString: '$deviceSecret:$publicEventId',
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

    final result = await ServiceCommon.sendHttpPostToHC6Api(body);
    if (kDebugMode) {
      debugPrint(
        result is ApiError
            ? 'SP 9 [getEventMessages] called — FAILED'
            : 'SP 9 [getEventMessages] called — success',
      );
    }
    return result is ApiSuccess ? result.body : null;
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
      final id = (msg['id'] as String).asUuid;
      final createdAt = createdAtMs is int
          ? DateTime.fromMillisecondsSinceEpoch(createdAtMs)
          : null;
      final content = (msg['text'] as String?) ?? '';
      final kind = (msg['messageKind'] as num?)?.toInt() ?? chatKindText;
      if (msg['canDelete'] == 1 || msg['canDelete'] == true) {
        _canDeleteIds.add(id);
      }
      result.add(
        _buildMessage(
          id: id,
          authorId: authorId,
          kind: kind,
          content: content,
          createdAt: createdAt,
          status: core.MessageStatus.sent,
        ),
      );
    }
    // SP returns newest-first (ORDER BY createdAt DESC); v2 chat displays
    // index 0 at top, so reverse to oldest-first for correct display order.
    return result.reversed.toList();
  }

  /// One message of any kind. An unknown kind — or a photo / location whose
  /// content is not what the server would have accepted — is drawn as text.
  core.Message _buildMessage({
    required String id,
    required String authorId,
    required int kind,
    required String content,
    required DateTime? createdAt,
    required core.MessageStatus status,
  }) {
    if (kind == chatKindPhoto && isChatPhotoUrl(content)) {
      return core.Message.image(
        id: id,
        authorId: authorId,
        source: content,
        createdAt: createdAt,
        status: status,
      );
    }
    if (kind == chatKindLocation) {
      final p = parseChatLocationUrl(content);
      if (p != null) {
        return core.Message.custom(
          id: id,
          authorId: authorId,
          createdAt: createdAt,
          status: status,
          metadata: <String, dynamic>{
            chatMetaKind: chatMetaLocation,
            chatMetaUrl: content,
            chatMetaLat: p.lat,
            chatMetaLng: p.lng,
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
    );
  }

  // ── Attach: photo or location ─────────────────────────────────────────────

  Future<void> handleAttachmentPressed() async {
    await Get.bottomSheet<void>(
      SafeArea(
        child: ColoredBox(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Builder(
                builder: (ctx) => ListTile(
                  leading: const Icon(Icons.photo_outlined),
                  title: const Text('Photo'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    unawaited(handleImageSelection());
                  },
                ),
              ),
              Builder(
                builder: (ctx) => ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: const Text('Drop a pin'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    unawaited(handleLocationSelection());
                  },
                ),
              ),
              Builder(
                builder: (ctx) => ListTile(
                  leading: const Icon(Icons.close),
                  title: const Text('Cancel'),
                  onTap: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierColor: Colors.black54,
    );
  }

  /// Picks an image, resizes it to at most 1600 px as a JPEG, uploads it to
  /// `chat-photos` and sends it as a kind-1 message (E9.F1.S11).
  Future<void> handleImageSelection() async {
    if (isUploading.value) return;
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final bytes = picked?.files.single.bytes;
    if (bytes == null) return;

    isUploading.value = true;
    try {
      final jpeg = chatPhotoJpeg(bytes);
      if (jpeg == null) {
        _toast('That file could not be read as a photo. Try a JPEG or PNG.');
        return;
      }
      final url = await ServiceCommon.uploadChatPhoto(jpeg);
      if (url == null) {
        _toast('The photo could not be uploaded. Please try again.');
        return;
      }
      if (isClosed) return;
      await _send(kind: chatKindPhoto, content: url);
    } finally {
      if (!isClosed) isUploading.value = false;
    }
  }

  /// Opens the pin picker and sends the point as a kind-2 message (E9.F1.S12).
  Future<void> handleLocationSelection() async {
    final pin = await showChatPinPicker(lat: runLat, lng: runLng);
    if (pin == null || isClosed) return;
    final url = chatLocationUrl(pin.lat, pin.lng);
    if (url == null) {
      _toast('That point is not on the map.');
      return;
    }
    await _send(kind: chatKindLocation, content: url);
  }

  // ── Tap, copy, delete ────────────────────────────────────────────────────

  void handleMessageTap(
    BuildContext _,
    core.Message message, {
    required int index,
    required TapUpDetails details,
  }) {
    if (message is core.ImageMessage) {
      openPhoto(message);
    } else if (_locationUrlOf(message) case final url?) {
      unawaited(launchUrl(Uri.parse(url), webOnlyWindowName: '_blank'));
    }
  }

  /// Opens every photo in this chat, oldest first, at the one clicked.
  void openPhoto(core.ImageMessage message) {
    final photos = chatController.messages
        .whereType<core.ImageMessage>()
        .toList();
    final urls = photos.map((m) => m.source).toList();
    final start = photos.indexWhere((m) => m.id == message.id);
    unawaited(
      Get.to<void>(
        () => ChatPhotoCarouselPage(
          urls: urls,
          initialIndex: start < 0 ? 0 : start,
          title: 'Trail Chat photos',
        ),
      ),
    );
  }

  String? _locationUrlOf(core.Message m) {
    if (m is! core.CustomMessage) return null;
    final meta = m.metadata;
    if (meta == null || meta[chatMetaKind] != chatMetaLocation) return null;
    return meta[chatMetaUrl] as String?;
  }

  /// What Copy puts on the clipboard: the text, or the photo / map URL.
  String copyTextOf(core.Message m) => switch (m) {
    core.TextMessage() => m.text,
    core.ImageMessage() => m.source,
    _ => _locationUrlOf(m) ?? '',
  };

  bool canDelete(core.Message m) =>
      _canDeleteIds.contains(m.id) &&
      m.status != core.MessageStatus.sending &&
      m.status != core.MessageStatus.error;

  Future<void> copyMessage(core.Message m) async {
    final text = copyTextOf(m);
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    _toast(switch (m) {
      core.ImageMessage() => 'Photo link copied',
      core.CustomMessage() => 'Location link copied',
      _ => 'Copied',
    });
  }

  /// Long-press menu at [position] (global coordinates).
  Future<void> showMessageMenu(
    BuildContext context,
    core.Message m,
    Offset position,
  ) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: menuItemsFor(m),
    );
    await onMenuSelected(choice, m);
  }

  List<PopupMenuEntry<String>> menuItemsFor(core.Message m) => [
    const PopupMenuItem(
      value: 'copy',
      child: ListTile(
        dense: true,
        leading: Icon(Icons.copy),
        title: Text('Copy'),
      ),
    ),
    if (canDelete(m))
      const PopupMenuItem(
        value: 'delete',
        child: ListTile(
          dense: true,
          leading: Icon(Icons.delete_outline, color: Color(0xFFB91C1C)),
          title: Text('Delete', style: TextStyle(color: Color(0xFFB91C1C))),
        ),
      ),
  ];

  Future<void> onMenuSelected(String? choice, core.Message m) async {
    switch (choice) {
      case 'copy':
        await copyMessage(m);
      case 'delete':
        await deleteMessage(m);
    }
  }

  /// Confirms, removes the bubble at once, and asks the server; the bubble
  /// comes back if the server refuses (E9.F1.S13/S14). The SP's refusal text
  /// is shown by sendHttpPostToHC6Api's error dialog.
  Future<void> deleteMessage(core.Message m) async {
    final someoneElses = m.authorId != currentUser.id;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete this message?', textAlign: TextAlign.center),
        content: Text(
          someoneElses
              ? 'It will disappear from this chat for everyone. '
                    "You are deleting another hasher's message as a chat "
                    'administrator.'
              : 'It will disappear from this chat for everyone.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Builder(
            builder: (ctx) => ElevatedButton(
              style: hcDialogButtonStyle(hcDialogCancelColor),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', textAlign: TextAlign.center),
            ),
          ),
          Builder(
            builder: (ctx) => ElevatedButton(
              style: hcDialogButtonStyle(HcButtonTokens.destructive),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete', textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || isClosed) return;

    final index = chatController.messages.indexWhere((x) => x.id == m.id);
    if (index < 0) return;
    final shown = chatController.messages[index];
    await chatController.removeMessage(shown);

    final deviceId = box.get(HIVE_DEVICE_ID) as String;
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
    // The SP binds the token to CAST(@messageId AS NVARCHAR(40)), which SQL
    // renders UPPERCASE; generateToken upper-cases the whole access string and
    // ValidatePortalAuth UPPERs its side, so the case of m.id does not matter
    // (the same as sendEventMessage's publicEventId:messageId).
    final accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_deleteChatMessage',
      paramString: '$deviceSecret:${m.id}',
    );
    final result = await ServiceCommon.sendHttpPostToHC6Api(<String, dynamic>{
      'queryType': 'deleteChatMessage',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'messageId': m.id,
    });
    if (kDebugMode) {
      debugPrint(
        'SP [deleteChatMessage] called — '
        '${result is ApiError ? 'FAILED' : 'success'}',
      );
    }
    if (isClosed) return;
    if (result is ApiError) {
      if (chatController.messages.every((x) => x.id != m.id)) {
        await chatController.insertMessage(
          shown,
          index: min(index, chatController.messages.length),
        );
      }
      _toast('The message was not deleted.');
      return;
    }
    _canDeleteIds.remove(m.id);
  }

  /// A short notice. A ScaffoldMessenger SnackBar, not a GetX one: GetX's
  /// Get.back() will not pop the page while its own snackbar is open.
  void _toast(String text) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    ScaffoldMessenger.maybeOf(ctx)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text, textAlign: TextAlign.center),
          behavior: SnackBarBehavior.floating,
          width: 360,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  // ── Send ─────────────────────────────────────────────────────────────────

  Future<void> handleSendPressed(String text) =>
      _send(kind: chatKindText, content: text);

  /// Sends one message of [kind]. It appears at once (sending), then turns
  /// sent / delivered, or error if the SP refuses.
  Future<void> _send({required int kind, required String content}) async {
    final uuid = const Uuid().v4();
    final newMsg = _buildMessage(
      id: uuid,
      authorId: currentUser.id,
      kind: kind,
      content: content,
      createdAt: DateTime.now(),
      status: core.MessageStatus.sending,
    );
    _canDeleteIds.add(uuid);

    unawaited(chatController.insertMessage(newMsg));

    final deviceId = box.get(HIVE_DEVICE_ID) as String;
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';

    // Compound token: binds to the specific event AND message UUID, preventing
    // a captured token from being replayed to send a different message.
    final accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_sendEventMessage',
      paramString: '$deviceSecret:$publicEventId:$uuid',
    );

    final body = <String, dynamic>{
      'queryType': 'sendEventMessage',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'publicEventId': publicEventId,
      'messageId': uuid,
      'messageContent': content,
      'messageReleasabilityFlags': 63,
      'messageTitle': messageTitle,
      // Only sent when not text, so a text send is exactly as before.
      if (kind != chatKindText) 'messageKind': kind,
    };

    final sendResult = await ServiceCommon.sendHttpPostToHC6Api(body);
    final failed = sendResult is ApiError;
    if (kDebugMode) {
      debugPrint(
        failed
            ? 'SP 17 [sendEventMessage] called — FAILED'
            : 'SP 17 [sendEventMessage] called — success',
      );
    }
    if (isClosed) return;

    final sent = chatController.messages.firstWhereOrNull((m) => m.id == uuid);
    if (sent == null) return;

    if (failed) {
      _canDeleteIds.remove(uuid);
      final errored = _withStatus(sent, core.MessageStatus.error);
      if (errored != null) await chatController.updateMessage(sent, errored);
      _pendingDeliveryIds.remove(uuid);
      return;
    }

    if (_isSafari) {
      // Safari FCM delivery is unreliable after the browser's silent push
      // quota (~3 messages). Go directly to delivered so the sender always
      // gets confirmation without waiting up to 15 seconds for the poll.
      final delivered = _withStatus(
        sent,
        core.MessageStatus.delivered,
        sentAt: DateTime.now(),
      );
      if (delivered != null) {
        await chatController.updateMessage(sent, delivered);
      }
    } else {
      // Chrome/Firefox: SP confirm → single tick. The sender's FCM echo
      // (from Rowset 2 of hcportal_sendEventMessage) will trigger the
      // delta fetch that upgrades to double tick.
      final confirmed = _withStatus(
        sent,
        core.MessageStatus.sent,
        sentAt: DateTime.now(),
      );
      if (confirmed != null) {
        await chatController.updateMessage(sent, confirmed);
      }

      // Handle race: if the FCM echo arrived and ran _refreshMessages()
      // before the SP response returned, the message was still in `sending`
      // state and the upgrade was deferred into _pendingDeliveryIds.
      if (_pendingDeliveryIds.remove(uuid)) {
        final updated = chatController.messages.firstWhereOrNull(
          (m) => m.id == uuid,
        );
        if (updated != null) _upgradeToDelivered(updated);
      }
    }
  }
}
