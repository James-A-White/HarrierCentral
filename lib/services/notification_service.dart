import 'package:harrier_central/imports.dart';
import 'package:harrier_central/firebase_options.dart';

class NotificationService extends GetxService with WidgetsBindingObserver {
  // --- Reactive State for Badges ---

  // Map to track the unread count for each Public Event ID.
  // Key: PublicEventId, Value: Unread Message Count
  final RxMap<String, RxInt> unreadEventCounts = <String, RxInt>{}.obs;

  // Derived RxInt for the *Global* App Icon Badge Count (sum of all events)
  final RxInt globalTotalBadgeCount = 0.obs;

  // --- Core Dependencies ---

  FirebaseMessaging? _messaging;
  StreamSubscription<RemoteMessage>? _fcmSubscription;

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

      if (!(getBoolPref(BoolPrefsEnum.notificationPreferencesRequested) ??
          false)) {
        await requestPermission();
      }

      await _setupInitialMessage();
      _setupFirebaseListeners();
      _ensureFcmListener();
    }

    await getEventChatMessageCounts();
    _recalculateGlobalBadgeCount();

    return this;
  }

  Future<void> getEventChatMessageCounts() async {
    final userId = getStringPref(StringPrefsEnum.userId);
    if (userId == null || userId.isEmpty) {
      return;
    }
    String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    String deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final accessToken = Utilities.generateToken(
      userId,
      'hcapp_getEventMessageCounts',
      paramString: deviceSecret,
    );

    final body = <String, dynamic>{
      'queryType': 'getEventMessageCounts',
      'deviceId': deviceId,
      'accessToken': accessToken,
    };

    String responseBody = await ServiceCommon.sendHttpPostV2(jsonEncode(body));

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

      final Map<String, int> serverChatCounts = {
        for (var summary in serverChatSummary)
          summary.publicEventId: summary.eventChatMessageCount,
      };

      await setMapIntPref(MapPrefsEnum.serverChatCounts, serverChatCounts);

      final clientChatCounts = getMapIntPref(MapPrefsEnum.clientChatCounts);

      // 1. Combine all unique keys from both maps (Union of keys)
      final allKeys = serverChatCounts.keys.toSet().union(
        clientChatCounts.keys.toSet(),
      );

      // 2. Create a standard Map by iterating over all keys, calculating the difference
      // and ensuring each value is an RxInt. We use ?? 0 to handle missing keys.
      unreadEventCounts.value = {
        for (final key in allKeys)
          key:
              ((serverChatCounts[key] ?? 0) - (clientChatCounts[key] ?? 0)).obs,
      }.obs;
    }

    if (Get.isRegistered<FutureRunListPageController>()) {
      Get.find<FutureRunListPageController>().refreshRunListUi();
    }
  }

  // --- FCM Listener Management ---

  void _ensureFcmListener() {
    _fcmSubscription
        ?.cancel(); // Cancel any existing listener to prevent duplicates

    _fcmSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );
  }

  void refreshFcmListenerOnResume() {
    if (kDebugMode) {
      print("App resumed – refreshing FCM listener");
    }
    _ensureFcmListener();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshFcmListenerOnResume();
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
            (userId.isNotEmpty)) {
          final String accessToken = Utilities.generateToken(
            userId,
            'hcapp_setFcmTokens',
            paramString: deviceSecret,
          );

          Map<String, String> params = (<String, String>{
            'queryType': 'setFcmTokens',
            'deviceId': deviceId,
            'accessToken': accessToken,
          });

          if (apnsToken != null) {
            params.addAll({'apnsToken': apnsToken});
          }

          if (fcmToken != null) {
            params.addAll({'fcmToken': fcmToken});
          }

          final String body = jsonEncode(params);

          try {
            await ServiceCommon.sendHttpPostV2(body);
            await setBoolPref(BoolPrefsEnum.fcmTokenSavedToServer, true);
          } catch (e) {
            if (kDebugMode) {
              print('Connection error: ${e.toString()}');
            }
          }
        }

        setBoolPref(BoolPrefsEnum.notificationPreferencesRequested, true);

        if (kDebugMode) {
          print(
            'Notification permission status: ${settings.authorizationStatus}',
          );
        }
      } else {
        setBoolPref(BoolPrefsEnum.notificationPreferencesRequested, false);
        if (kDebugMode) {
          print(
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
        _handleNotificationClick(initialMessage);
        if (kDebugMode) {
          print('Initial message received: ${initialMessage.data}');
        }
      }
    }
  }

  void _setupFirebaseListeners() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message);
      if (kDebugMode) {
        print('Message opened app received: ${message.data}');
      }
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print("Foreground message received: ${message.data}");
    }

    // 1. Badge Update Logic: Calculate and update unread counts
    final publicEventId = message.data['PublicEventId'] as String?;
    final chatCount =
        (int.tryParse(message.data['EventChatMessageCount'] as String) ?? 0);
    _updateChatCountBadges(publicEventId, chatCount);

    // 2. Dispatch to internal controllers
    _dispatchMessageToControllers(message);
  }

  void _handleNotificationClick(RemoteMessage message) {
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
      Get.find<FutureRunListPageController>().processNotificationClickOnResume(
        message,
      );
    } else {
      if (kDebugMode) {
        print(
          "FutureRunListPageController not found, cannot process notification click.",
        );
      }
    }
  }

  void _dispatchMessageToControllers(RemoteMessage message) {
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

          if (Get.isRegistered<ChatPageController>()) {
            Get.find<ChatPageController>().notificationReceived(message);
          }

          if (kDebugMode) {
            print('Handling chat message: ${message.data}');
          }
        } catch (e) {
          if (kDebugMode) {
            print("ChatController not found: $e");
          }
        }
        break;

      default:
        if (kDebugMode) {
          print("Unhandled message type: $messageType");
        }
    }
  }

  // --- GetStorage and Badge Logic ---

  void _recalculateGlobalBadgeCount() {
    final clientChatCounts = getMapIntPref(MapPrefsEnum.clientChatCounts);
    final serverChatCounts = getMapIntPref(MapPrefsEnum.serverChatCounts);

    // 1. Combine all unique keys from both maps (Union of keys)
    final allKeys = serverChatCounts.keys.toSet().union(
      clientChatCounts.keys.toSet(),
    );

    // 2. Create a standard Map by iterating over all keys, calculating the difference
    // and ensuring each value is an RxInt. We use ?? 0 to handle missing keys.
    unreadEventCounts.value = {
      for (final key in allKeys)
        key: ((serverChatCounts[key] ?? 0) - (clientChatCounts[key] ?? 0)).obs,
    }.obs;

    globalTotalBadgeCount.value = unreadEventCounts.values.fold<int>(
      0,
      (sum, rxInt) => sum + rxInt.value,
    );
  }

  void _updateChatCountBadges(String? publicEventId, int serverChatCount) {
    // 1. Initial Checks and Guard Clauses
    if (publicEventId == null || publicEventId.isEmpty) {
      if (kDebugMode) {
        print('Badge Update: PublicEventId is null or empty. Skipping.');
      }
      return;
    }

    // 2. Calculations
    final clientChatCounts = getMapIntPref(MapPrefsEnum.clientChatCounts);
    final localViewedCount = clientChatCounts[publicEventId] ?? 0;

    // Update the stored server count for this event
    final serverChatCounts = getMapIntPref(MapPrefsEnum.serverChatCounts);
    serverChatCounts[publicEventId] = serverChatCount;
    setMapIntPref(MapPrefsEnum.serverChatCounts, serverChatCounts);

    // Calculate the new unread count (Server Total - Local Viewed).
    // Use max(0, ...) to ensure the count never goes below zero.
    final newUnreadCount = max(0, serverChatCount - localViewedCount);

    // Get the unread count recorded just before this update.
    final previouslyUnread = unreadEventCounts[publicEventId] ?? 0;

    // 3. Reactivity and Update Logic

    // Only proceed if the effective unread count for this event has actually changed.
    if (newUnreadCount != previouslyUnread) {
      // The event has unread messages and needs to be in the map.
      if (unreadEventCounts.containsKey(publicEventId)) {
        unreadEventCounts[publicEventId]!.value = newUnreadCount;

        if (kDebugMode) {
          print(
            'Badge Update: Event $publicEventId count changed from $previouslyUnread to $newUnreadCount via .update().',
          );
        }
      } else {
        unreadEventCounts[publicEventId] = newUnreadCount.obs;
        if (kDebugMode) {
          print(
            'Badge Update: Event $publicEventId added with count $newUnreadCount.',
          );
        }
      }

      // 4. Global Recalculation
      // Recalculate the sum of all unread counts to update the app icon badge.
      _recalculateGlobalBadgeCount();
    } else {
      if (kDebugMode) {
        print(
          'Badge Update: Event $publicEventId count is unchanged ($newUnreadCount).',
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
    int badgeCount = await getData(publicEventId, true);
    print('Badge count after marking as viewed: $badgeCount');
  }

  Future<int> getData(String publicEventId, bool resetBadgeCount) async {
    final String userId = getStringPref(StringPrefsEnum.userId)!;
    String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    String deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    var badgeCount = 0;

    final accessToken = Utilities.generateToken(
      userId,
      'hcapp_setEventMessagesRead',
      paramString: deviceSecret + publicEventId,
    );

    final body = <String, String>{
      'queryType': 'setEventMessagesRead',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'publicEventId': publicEventId,
      'resetBadgeCount': resetBadgeCount ? '1' : '0',
    };

    final responseBody = await ServiceCommon.sendHttpPostV2(jsonEncode(body));

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      json.decode(responseBody).forEach((dynamic item) {
        badgeCount = json.decode(responseBody)[0][0]['badgeCount'];
      });
    }

    return badgeCount;
  }

  /// To be called when a user views a chat page and marks all messages as read.
  void resetAllEventChatCounts() {
    final serverChatCounts = getMapIntPref(MapPrefsEnum.serverChatCounts);
    setMapIntPref(MapPrefsEnum.clientChatCounts, serverChatCounts);

    // 2. Create a standard Map by iterating over all keys, calculating the difference
    // and ensuring each value is an RxInt. We use ?? 0 to handle missing keys.
    unreadEventCounts.value = {
      for (final key in serverChatCounts.keys) key: 0.obs,
    }.obs;

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
      print("Clearing native badge.");
    }
  }

  // --- Disposal ---

  @override
  void onClose() {
    _fcmSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
