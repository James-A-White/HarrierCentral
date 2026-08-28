import 'package:harrier_central/imports.dart';
import 'package:harrier_central/firebase_options.dart';

class NotificationService extends GetxService with WidgetsBindingObserver {
  // --- Reactive State for Badges ---

  // Map to track the unread count for each Public Event ID.
  // Key: PublicEventId, Value: Unread Message Count
  final RxMap<String, RxInt> unreadEventCounts = <String, RxInt>{}.obs;

  /// The full set of runs that currently have unread chat messages, as returned
  /// by the server (Mode 3), carrying enough display data to render the Unseen
  /// Chats list even for runs that aren't locally synced. Sorted newest-first.
  final RxList<EventChatSummary> unreadChatRuns = <EventChatSummary>[].obs;
  // final Map<String, int> clientChatCounts = <String, int>{};

  // Derived RxInt for the *Global* App Icon Badge Count (sum of all events)
  final RxInt globalTotalBadgeCount = 0.obs;

  /// Threads that contain at least one message, keyed by **lowercase**
  /// publicEventId (run threads) / publicKennelId (kennel threads). Populated
  /// from the Mode 3 badge fetch (SP v1.1.0 returns every visible thread with
  /// messages, read or not). Drives the card chat bubbles: unread → read →
  /// no chats.
  final RxSet<String> threadsWithMessages = <String>{}.obs;

  // --- Core Dependencies ---

  FirebaseMessaging? _messaging;
  StreamSubscription<RemoteMessage>? _fcmSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;

  // --- Initialization ---

  Future<NotificationService> init() async {
    WidgetsBinding.instance.addObserver(this);

    // Initial Badge Setup (Clear on service start)
    _clearAppBadge();

    if (getStringPref(StringPrefsEnum.bootType) == BOOT_TYPE_UPGRADE_1_2) {
      return this;
    }

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    if (Firebase.apps.isNotEmpty) {
      _messaging = FirebaseMessaging.instance;

      // Suppress the system notification banner when the app is already in the
      // foreground. onMessage still fires — the app shows its own in-app UI
      // (listening banner, toast). Without this, visible song pushes pop up as
      // iOS banners even while the user is looking at the songbook.
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );

      if (!(getBoolPref(BoolPrefsEnum.notificationPreferencesRequested) ??
          false)) {
        await requestPermission();
      }

      await _setupInitialMessage();
      _setupFirebaseListeners();
      await _ensureFcmListener();
    }

    await getEventChatMessageCounts();
    _recalculateGlobalBadgeCount();

    return this;
  }

  Future<void> getEventChatMessageCounts() async {
    final String? userId = getStringPref(StringPrefsEnum.userId);
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    if (!_hasCompleteAuthBundle(
      userId: userId,
      deviceId: deviceId,
      deviceSecret: deviceSecret,
    )) {
      return;
    }

    final body = <String, dynamic>{
      'queryType': 'getEventBadgeCount',
      'deviceId': deviceId,
    };

    // Background badge fetch during boot — never show an error dialog for it
    // (initServices runs pre-overlay; and a badge count is not worth an alert).
    String responseBody = await ServiceCommon.sendHttpPost(() {
      body['accessToken'] = Utilities.generateToken(
        userId!,
        'hcapp_getEventBadgeCount',
        paramString: deviceSecret,
      );
      return jsonEncode(body);
    }, errorCallback: (_) async => true);

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      final decoded = json.decode(responseBody) as List;
      List<EventChatSummary> serverChatSummary = decoded
          .map<List<EventChatSummary>>((innerList) {
            return (innerList as List)
                .map<EventChatSummary>(
                  (item) => EventChatSummary.fromJson(item),
                )
                .toList();
          })
          .toList()[0];

      // clientChatCounts.clear();
      // clientChatCounts.addAll({
      //   for (var summary in serverChatSummary)
      //     summary.publicEventId: summary.eventChatMessageCount,
      // });

      // Populate unreadEventCounts with RxInt values derived from clientChatCounts.
      final Set<String> withMessages = <String>{};
      unreadEventCounts.value = {
        for (final summary in serverChatSummary)
          if (summary.publicEventId.isNotEmpty)
            summary.publicEventId: summary.badgeCount.obs,
      };
      for (final summary in serverChatSummary) {
        if (summary.publicEventId.isNotEmpty &&
            (summary.messageCount ?? 0) > 0) {
          withMessages.add(summary.publicEventId.asUuid);
        }
      }

      // Kennel-thread rows contribute to the global badge separately.
      for (final summary in serverChatSummary) {
        if (summary.isKennelThread && (summary.publicKennelId ?? '').isNotEmpty) {
          unreadEventCounts[summary.publicKennelId!] = summary.badgeCount.obs;
          if ((summary.messageCount ?? 0) > 0) {
            withMessages.add(summary.publicKennelId!.asUuid);
          }
        }
      }
      // Which threads have any content at all (read or not).
      threadsWithMessages
        ..clear()
        ..addAll(withMessages);

      // Keep the display-bearing rows (those that carry event data) for the
      // Unseen Chats list, newest-first.
      final withData =
          serverChatSummary
              .where((s) =>
                  s.badgeCount > 0 && (s.eventId != null || s.isKennelThread))
              .toList()
            ..sort(
              (a, b) => (b.eventStartDatetimeGmt ?? '').compareTo(
                a.eventStartDatetimeGmt ?? '',
              ),
            );
      unreadChatRuns.value = withData;
    }

    if (Get.isRegistered<FutureRunListPageController>()) {
      Get.find<FutureRunListPageController>().refreshRunListUi();
    }
  }

  // --- FCM Listener Management ---

  Future<void> _ensureFcmListener() async {
    await _fcmSubscription
        ?.cancel(); // Cancel any existing listener to prevent duplicates

    _fcmSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );
  }

  Future<void> refreshFcmListenerOnResume() async {
    if (kDebugMode) {
      debugPrint("App resumed – refreshing FCM listener");
    }
    await _ensureFcmListener();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await refreshFcmListenerOnResume();
    }
  }

  // --- Permission and Token Management ---

  Future<void> requestPermission() async {
    // ... (Your existing permission and token saving logic remains here) ...
    if (Firebase.apps.isNotEmpty) {
      _messaging ??= FirebaseMessaging.instance;

      if (_messaging != null) {
        NotificationSettings settings = await _messaging!.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        String? apnsToken = await _messaging!.getAPNSToken();
        String? fcmToken;

        if (apnsToken != null) {
          apnsToken = apnsToken.trim();
          await setStringPref(StringPrefsEnum.apnsToken, apnsToken);

          fcmToken = await _messaging!.getToken();

          if (fcmToken != null && fcmToken.isNotEmpty) {
            await setStringPref(StringPrefsEnum.fcmToken, fcmToken);
          }
        }

        final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
        final String deviceSecret =
            getStringPref(StringPrefsEnum.deviceSecret) ?? '';
        final String userId = getStringPref(StringPrefsEnum.userId) ?? '';

        if ((deviceId.isNotEmpty) &&
            (deviceSecret.isNotEmpty) &&
            (userId.isNotEmpty) &&
            (userId != GUID_EMPTY)) {
          final Map<String, String> params = <String, String>{
            'queryType': 'setFcmTokens',
            'deviceId': deviceId,
          };

          if (apnsToken != null) {
            params.addAll({'apnsToken': apnsToken});
          }

          if (fcmToken != null) {
            params.addAll({'fcmToken': fcmToken});
          }

          try {
            await ServiceCommon.sendHttpPost(() {
              params['accessToken'] = Utilities.generateToken(
                userId,
                'hcapp_setFcmTokens',
                paramString: deviceSecret,
              );
              return jsonEncode(params);
            });
            await setBoolPref(BoolPrefsEnum.fcmTokenSavedToServer, true);
          } catch (e, s) {
            if (kDebugMode) {
              debugPrint('Connection error: ${e.toString()}');
            }
            BootLogger.logError('[NotificationService] FCM token save failed', e, s);
          }
        }

        await setBoolPref(BoolPrefsEnum.notificationPreferencesRequested, true);

        if (kDebugMode) {
          debugPrint(
            'Notification permission status: ${settings.authorizationStatus}',
          );
        }
      } else {
        await setBoolPref(
          BoolPrefsEnum.notificationPreferencesRequested,
          false,
        );
        if (kDebugMode) {
          debugPrint(
            'Firebase not initialized, cannot request notification permission.',
          );
        }
      }
    }
  }

  // --- FCM Message Handlers ---

  Future<void> _setupInitialMessage() async {
    if (_messaging != null) {
      RemoteMessage? initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        await _handleNotificationClick(initialMessage);
        if (kDebugMode) {
          debugPrint('Initial message received: ${initialMessage.data}');
        }
      }
    }
  }

  void _setupFirebaseListeners() {
    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      await _handleNotificationClick(message);
      if (kDebugMode) {
        debugPrint('Message opened app received: ${message.data}');
      }
    });
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint("Foreground message received: ${message.data}");
    }

    // Song notifications bypass badge logic — dispatch immediately so the
    // songbook updates without the badge HTTP round-trip adding latency.
    final String? silentType = message.data['Type'] as String?;
    if (silentType == 'song_selected') {
      _dispatchMessageToControllers(message);
      return;
    }

    // 1. Badge Update Logic: Calculate and update unread counts
    final publicEventId = message.data['PublicEventId'] as String?;

    int badgeCount = await _getAndResetBadgeCount(
      publicEventId: publicEventId,
      resetBadgeCount: false,
      resetAllBadgeCounts: false,
    );

    _updateChatCountBadges(publicEventId, badgeCount);

    // 2. Dispatch to internal controllers
    _dispatchMessageToControllers(message);
  }

  Future<void> _handleNotificationClick(RemoteMessage message) async {
    // Song notification tap — update session state then navigate to the songbook.
    // onSongSelected() must be called first so pendingSongId is set before the
    // SongsPageController's ever() worker fires on navigation.
    final String? silentType = message.data['Type'] as String?;
    if (silentType == 'song_selected') {
      final String? eventId = message.data['EventId'] as String?;
      final String? songId  = message.data['SongId']  as String?;
      if (eventId != null && songId != null) {
        SongSessionNotifier.ensure().onSongSelected(
          eventId: eventId.toLowerCase(),
          songId: songId.toLowerCase(),
          songTitle: message.data['SongTitle'] as String? ?? '',
          selectedByName: message.data['SelectedByName'] as String? ?? 'Someone',
        );
        Get.until((route) => route.settings.name == '/main');
        _navigateToSongbook(eventId.toLowerCase());
      }
      return;
    }

    // 2. Badge Clear Logic: Reset badge counts when user interacts with notification
    final publicEventId = message.data['PublicEventId'] as String?;

    // Attempt to clear the badges for the specific event if possible.
    if (publicEventId != null) {
      // We don't know the total server count here, so we assume the user has read all known messages
      // by setting the viewed count to a very high number or by using the current unread count.
      // Since this is a click, we rely on the receiving controller (ChatPageController)
      // to call markEventMessagesAsViewed() when the page is fully loaded.
      // For now, we clear the global badge since the app is being opened.
      // Note: This might be too aggressive if the notification isn't chat-related.
      _clearAppBadge(); // Clear external badge immediately for a clean look
    }

    //pop all the way back to the main page
    Get.until((route) => route.settings.name == '/main');

    if (Get.isRegistered<FutureRunListPageController>()) {
      await Get.find<FutureRunListPageController>()
          .processNotificationClickOnResume(message);
    } else {
      if (kDebugMode) {
        debugPrint(
          "FutureRunListPageController not found, cannot process notification click.",
        );
      }
    }
  }

  void _dispatchMessageToControllers(RemoteMessage message) {
    // Data-only silent messages use a string Type field rather than MessageType.
    final String? silentType = message.data['Type'] as String?;
    if (silentType == 'song_selected') {
      _handleSongSelected(message);
      return;
    }

    MessageType messageType = MessageType.fromId(
      int.tryParse(message.data['MessageType']) ?? 0,
    );

    switch (messageType) {
      case MessageType.chat:
        try {
          if (Get.isRegistered<FutureRunListPageController>()) {
            Get.find<FutureRunListPageController>().notificationReceived(
              message,
            );
          }

          if (kDebugMode) {
            debugPrint('Handling chat message: ${message.data}');
          }
        } catch (e, s) {
          if (kDebugMode) {
            debugPrint("ChatController not found: $e");
          }
          BootLogger.logError('[NotificationService] chat message dispatch failed', e, s);
        }
        break;

      default:
        if (kDebugMode) {
          debugPrint("Unhandled message type: $messageType");
        }
    }
  }

  // --- GetStorage and Badge Logic ---

  void _recalculateGlobalBadgeCount() {
    // final clientChatCounts = getMapIntPref(MapPrefsEnum.clientChatCounts);
    // final serverChatCounts = getMapIntPref(MapPrefsEnum.serverChatCounts);

    // // 1. Combine all unique keys from both maps (Union of keys)
    // final allKeys = serverChatCounts.keys.toSet().union(
    //   clientChatCounts.keys.toSet(),
    // );

    // // Populate unreadEventCounts with RxInt values derived from clientChatCounts.
    // unreadEventCounts.value = {
    //   for (final key in clientChatCounts.keys)
    //     key: (clientChatCounts[key] ?? 0).obs,
    // };

    globalTotalBadgeCount.value = unreadEventCounts.values.fold<int>(
      0,
      (sum, rxInt) => sum + rxInt.value,
    );
  }

  void _updateChatCountBadges(String? publicEventId, int serverChatCount) {
    // 1. Initial Checks and Guard Clauses
    if (publicEventId == null || publicEventId.isEmpty) {
      if (kDebugMode) {
        debugPrint('Badge Update: PublicEventId is null or empty. Skipping.');
      }
      return;
    }

    // 2. Calculations
    // final clientChatCounts = getMapIntPref(MapPrefsEnum.clientChatCounts);
    //final localViewedCount = clientChatCounts[publicEventId] ?? 0;

    // // Update the stored server count for this event
    // final serverChatCounts = getMapIntPref(MapPrefsEnum.serverChatCounts);
    // serverChatCounts[publicEventId] = serverChatCount;
    // setMapIntPref(MapPrefsEnum.serverChatCounts, serverChatCounts);

    // Calculate the new unread count (Server Total - Local Viewed).
    // Use max(0, ...) to ensure the count never goes below zero.
    //final newUnreadCount = max(0, localViewedCount);

    // Get the unread count recorded just before this update.
    final previouslyUnread = unreadEventCounts[publicEventId] ?? 0;

    // 3. Reactivity and Update Logic

    // Only proceed if the effective unread count for this event has actually changed.
    if (serverChatCount != (unreadEventCounts[publicEventId] ?? 0)) {
      // The event has unread messages and needs to be in the map.
      if (unreadEventCounts.containsKey(publicEventId)) {
        unreadEventCounts[publicEventId]!.value = serverChatCount;

        if (kDebugMode) {
          debugPrint(
            'Badge Update: Event $publicEventId count changed from $previouslyUnread to $serverChatCount via .update().',
          );
        }
      } else {
        unreadEventCounts[publicEventId] = serverChatCount.obs;
        if (kDebugMode) {
          debugPrint(
            'Badge Update: Event $publicEventId added with count $serverChatCount.',
          );
        }
      }

      // 4. Global Recalculation
      // Recalculate the sum of all unread counts to update the app icon badge.
      _recalculateGlobalBadgeCount();
    } else {
      if (kDebugMode) {
        debugPrint(
          'Badge Update: Event $publicEventId count is unchanged ($serverChatCount).',
        );
      }
    }
  }

  // /// To be called when a user views a chat page and marks all messages as read.
  // void markEventMessagesAsViewed(String publicEventId) {
  //   if (unreadEventCounts.containsKey(publicEventId)) {
  //     unreadEventCounts[publicEventId]!.value = 0;
  //   } else {
  //     unreadEventCounts[publicEventId] = 0.obs;
  //   }

  //   final clientChatCounts = getMapIntPref(MapPrefsEnum.clientChatCounts);
  //   final serverChatCounts = getMapIntPref(MapPrefsEnum.serverChatCounts);

  //   clientChatCounts[publicEventId] = serverChatCounts[publicEventId] ?? 0;
  //   setMapIntPref(MapPrefsEnum.clientChatCounts, clientChatCounts);
  //   _recalculateGlobalBadgeCount();
  // }

  /// To be called when a user views a chat page and marks all messages as read.
  Future<void> markEventMessagesAsViewed(String publicEventId) async {
    int badgeCount = await _getAndResetBadgeCount(
      publicEventId: publicEventId,
      resetBadgeCount: true,
    );
    _updateChatCountBadges(publicEventId, badgeCount);

    if (kDebugMode) {
      debugPrint('Badge count after marking as viewed: $badgeCount');
    }
  }

  /// Optimistically clears the unread badge for a single chat thread the instant
  /// the user opens it, without waiting for the next server badge fetch. Zeroes
  /// the thread's entry in [unreadEventCounts] (which recomputes
  /// [globalTotalBadgeCount] — the top chat-bubble badge) and drops its row from
  /// [unreadChatRuns] (the Unseen Chats list), so both update immediately.
  ///
  /// [threadId] is the publicEventId for an event thread, or the publicKennelId
  /// for a kennel thread (ChatPageController carries the kennel's public id in
  /// its publicEventId field). Matching is UUID-normalised because the
  /// server-sourced keys arrive uppercase while callers may pass a lowercased id.
  ///
  /// This is the local counterpart to the server-side markEventChatRead write —
  /// it makes the UI correct instantly; the SP is the durable backstop.
  void clearUnreadForThread(String threadId, {bool isKennelThread = false}) {
    if (threadId.isEmpty) return;
    final String id = threadId.asUuid;

    var changed = false;

    // Zero the per-thread count (case-insensitive key match), then recompute the
    // global badge from the remaining unread threads.
    for (final key in unreadEventCounts.keys) {
      if (key.asUuid == id) {
        if (unreadEventCounts[key]!.value != 0) {
          unreadEventCounts[key]!.value = 0;
          changed = true;
        }
        break;
      }
    }
    if (changed) _recalculateGlobalBadgeCount();

    // Drop the matching row from the Unseen Chats list.
    final int before = unreadChatRuns.length;
    unreadChatRuns.removeWhere(
      (s) => isKennelThread
          ? (s.isKennelThread && (s.publicKennelId ?? '').asUuid == id)
          : (s.publicEventId.asUuid == id),
    );
    if (unreadChatRuns.length != before) changed = true;

    if (changed && Get.isRegistered<FutureRunListPageController>()) {
      Get.find<FutureRunListPageController>().refreshRunListUi();
    }
  }

  /// Unread count for one thread ([threadId] = publicEventId or
  /// publicKennelId). UUID-normalised — the badge map keys arrive from the
  /// server uppercase while callers may pass a lowercased id.
  int unreadCountFor(String threadId) {
    if (threadId.isEmpty) return 0;
    final String id = threadId.asUuid;
    for (final key in unreadEventCounts.keys) {
      if (key.asUuid == id) return unreadEventCounts[key]?.value ?? 0;
    }
    return 0;
  }

  /// Three-state summary of a chat thread for the card bubbles. Kennel and
  /// run threads share the same key space (publicKennelId / publicEventId);
  /// [isKennelThread] is kept on the signature for call-site clarity.
  ChatThreadState chatThreadState(
    String threadId, {
    required bool isKennelThread,
  }) {
    if (threadId.isEmpty) return ChatThreadState.none;
    if (unreadCountFor(threadId) > 0) return ChatThreadState.unread;
    return threadsWithMessages.contains(threadId.asUuid)
        ? ChatThreadState.read
        : ChatThreadState.none;
  }

  Future<int> _getAndResetBadgeCount({
    String? publicEventId,
    bool? resetBadgeCount,
    bool? resetAllBadgeCounts,
  }) async {
    final String? userId = getStringPref(StringPrefsEnum.userId);
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    if (!_hasCompleteAuthBundle(
      userId: userId,
      deviceId: deviceId,
      deviceSecret: deviceSecret,
    )) {
      return 0;
    }

    var badgeCount = 0;

    String paramString = deviceSecret;
    // if (publicEventId != null) {
    //   paramString = deviceSecret + publicEventId;
    // }

    final body = <String, dynamic>{
      'queryType': 'getEventBadgeCount',
      'deviceId': deviceId,
    };

    if (publicEventId != null) {
      body.addAll({'publicEventId': publicEventId});
    }

    if (resetBadgeCount != null) {
      body.addAll({'resetBadgeCount': resetBadgeCount ? 1 : 0});
    }

    if (resetAllBadgeCounts != null) {
      body.addAll({'resetAllBadgeCounts': resetAllBadgeCounts ? 1 : 0});
    }

    final responseBody = await ServiceCommon.sendHttpPost(() {
      body['accessToken'] = Utilities.generateToken(
        userId!,
        'hcapp_getEventBadgeCount',
        paramString: paramString,
      );
      return jsonEncode(body);
    });

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      // Decode the JSON string into a Dart object (likely a List of Lists or a List of Maps)
      final decodedBody = json.decode(responseBody);

      if (decodedBody is List &&
          decodedBody.isNotEmpty &&
          decodedBody[0] is List &&
          (decodedBody[0] as List).isNotEmpty) {
        final row = (decodedBody[0] as List)[0];
        if (row is Map) {
          badgeCount = (row[BADGE_COUNT_JSON_KEY] as num?)?.toInt() ?? 0;
        }
      }
    }

    return badgeCount;
  }

  /// To be called when a user views a chat page and marks all messages as read.
  Future<void> resetAllEventChatCounts() async {
    await _getAndResetBadgeCount(resetAllBadgeCounts: true);

    unreadEventCounts.value = {
      for (final key in unreadEventCounts.keys) key: 0.obs,
    }.obs;

    // clientChatCounts.clear();
    // clientChatCounts.addAll({for (final key in unreadEventCounts.keys) key: 0});

    _recalculateGlobalBadgeCount();

    if (Get.isRegistered<FutureRunListPageController>()) {
      Get.find<FutureRunListPageController>().refreshRunListUi();
    }
  }

  // --- External App Badge Interface (Needs Implementation) ---

  // /// Updates the native platform application badge count.
  // void _updateAppBadge() {
  //   // ⚠️ IMPLEMENT EXTERNAL BADGE LOGIC HERE
  //   if (globalBadgeCount.value > 0) {
  //     // Example: FlutterAppBadger.updateBadgeCount(globalBadgeCount.value);
  //     if (kDebugMode) {
  //       print("Updating native badge to: ${globalBadgeCount.value}");
  //     }
  //   }
  // }

  /// Clears the native platform application badge.
  void _clearAppBadge() {
    // ⚠️ IMPLEMENT EXTERNAL BADGE CLEAR LOGIC HERE
    // Example: FlutterAppBadger.removeBadge();
    if (kDebugMode) {
      debugPrint("Clearing native badge.");
    }
  }

  bool _hasCompleteAuthBundle({
    required String? userId,
    required String? deviceId,
    required String? deviceSecret,
  }) {
    final String normalizedUserId = (userId ?? '').trim();
    final String normalizedDeviceId = (deviceId ?? '').trim();
    final String normalizedDeviceSecret = (deviceSecret ?? '').trim();

    return normalizedUserId.isNotEmpty &&
        normalizedUserId != GUID_EMPTY &&
        normalizedDeviceId.isNotEmpty &&
        normalizedDeviceSecret.isNotEmpty;
  }

  // --- Disposal ---

  @override
  void onClose() {
    unawaited(_fcmSubscription?.cancel());
    unawaited(_openedAppSubscription?.cancel());
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  void _handleSongSelected(RemoteMessage message) {
    final String? eventId = message.data['EventId'] as String?;
    final String? songId  = message.data['SongId']  as String?;
    final String songTitle     = message.data['SongTitle']      as String? ?? '';
    final String selectedByName = message.data['SelectedByName'] as String? ?? 'Someone';

    if (eventId == null || songId == null) return;

    final String eid = eventId.toLowerCase();
    final String sid = songId.toLowerCase();

    SongSessionNotifier.ensure().onSongSelected(
      eventId: eid,
      songId:  sid,
      songTitle: songTitle,
      selectedByName: selectedByName,
    );

    // If the user is already on the interactive songbook for this event,
    // the ever() reaction in SongsPageController handles the update directly.
    // Otherwise, show an in-app toast so they can navigate there.
    final bool onSongbook =
        Get.isRegistered<SongsPageController>(tag: eid);
    if (!onSongbook) {
      _showSongToast(eid, songTitle, selectedByName);
    }

    if (kDebugMode) {
      debugPrint('[NotificationService] song_selected: "$songTitle" by $selectedByName (onSongbook=$onSongbook)');
    }
  }

  void _showSongToast(String eventId, String songTitle, String selectedByName) {
    Get.snackbar(
      '🎵 Song Time!',
      '$selectedByName is leading "$songTitle"',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade800,
      colorText: Colors.white,
      duration: const Duration(seconds: 10),
      isDismissible: true,
      mainButton: TextButton(
        onPressed: () {
          Get.closeCurrentSnackbar();
          _navigateToSongbook(eventId);
        },
        child: const Text(
          'Go to song',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _navigateToSongbook(String eventId) {
    Get.to<void>(() => AppScaffold(
      appBar: AppBar(
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Songbook', style: ts_appBarTitle),
      ),
      body: SongsPage(eventId: eventId),
    ));
  }
}

/// State of a chat thread (run or kennel) as seen by the current user.
enum ChatThreadState {
  /// The thread has no messages yet.
  none,

  /// The thread has messages and the user has seen them all.
  read,

  /// The thread has messages the user hasn't seen.
  unread,
}
