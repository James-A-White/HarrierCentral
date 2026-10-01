import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:harrier_central/imports.dart';
import 'package:harrier_central/firebase_options.dart';

/// A push's data with every GUID lowercased. Payloads are built in SQL, which
/// writes ids in UPPERCASE, while the phone's database holds them in
/// lowercase — reading `message.payload` directly is how a chat tap came to
/// open nothing (2026-09-27). Read payloads through this, never `.data`.
extension HcPushPayload on RemoteMessage {
  Map<String, dynamic> get payload =>
      lowerGuidsInPlace(Map<String, dynamic>.of(data)) as Map<String, dynamic>;
}

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

  /// Key for a platform-wide room in [unreadEventCounts], which is otherwise
  /// keyed by publicEventId / publicKennelId. A room has no id of its own, and
  /// a colon cannot appear in a UUID, so this can never collide with one.
  static String roomBadgeKey(int roomType) => 'room:$roomType';

  /// Key for a direct message thread (E9.F1.S7) in [unreadEventCounts]. A
  /// DM is named by its ThreadId, which is a GUID that could collide with a
  /// publicEventId only in theory; the prefix removes the theory.
  static String dmBadgeKey(HcId threadId) => 'dm:$threadId';

  /// Hashers asking to message this one (E9.F1.S19), newest first, from
  /// hcapp_getDirectMessageRequests. Refreshed with the badge counts, so a
  /// request push and a resume both bring it up to date.
  final RxList<DirectMessageRequest> dmRequests = <DirectMessageRequest>[].obs;

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

  /// A notification tap that arrived before the app had a screen to put it on.
  /// Held here and replayed by [onMainReady]; see [_handleNotificationClick].
  RemoteMessage? _pendingTap;

  /// Set once MainNavigationPage has built its pages — i.e. the '/main' route
  /// exists and can safely be popped back to.
  bool _mainReady = false;

  // --- Initialization ---

  Future<NotificationService> init() async {
    WidgetsBinding.instance.addObserver(this);

    // The app icon is NOT cleared here any more (2026-09-28): the chat pushes
    // now set it to the true unread total while the app is closed, and
    // clearing it at start would throw that away. The first badge fetch below
    // writes the real number (see _recalculateGlobalBadgeCount).

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
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: false,
            badge: false,
            sound: false,
          );

      if (!(getBoolPref(BoolPrefsEnum.notificationPreferencesRequested) ??
          false)) {
        await requestPermission();
      }

      // What the OS actually allows, in the uploaded log: iOS keeps Badges
      // as its own switch, and a badge it refuses fails silently. Tuna's icon
      // showed no number on 1429 with everything server-side correct
      // (2026-10-01) — this says whether the phone is refusing it.
      unawaited(
        FirebaseMessaging.instance.getNotificationSettings().then(
          (NotificationSettings n) => BootLogger.logBreadcrumb(
            '[NOTIF] permission=${n.authorizationStatus.name} '
            'badge=${n.badge.name} alert=${n.alert.name} '
            'sound=${n.sound.name} lockScreen=${n.lockScreen.name}',
          ),
          onError: (Object e) =>
              BootLogger.logBreadcrumb('[NOTIF] settings unavailable: $e'),
        ),
      );

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

    // The DM request list rides alongside, in parallel, so it costs no
    // latency; it is joined below before the list UI is refreshed.
    final Future<void> requests = _refreshDmRequests();

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
        if (summary.isKennelThread &&
            (summary.publicKennelId ?? '').isNotEmpty) {
          unreadEventCounts[summary.publicKennelId!] = summary.badgeCount.obs;
          if ((summary.messageCount ?? 0) > 0) {
            withMessages.add(summary.publicKennelId!.asUuid);
          }
        }
      }

      // Room rows too, and they are the THIRD kind of thread — a room has
      // neither a publicEventId nor a publicKennelId (both are NULL by design;
      // a room is identified by its RoomType alone), so neither branch above
      // can ever match one. Without this the room's unread count reaches the
      // chat list, which reads summary.badgeCount directly, but never reaches
      // unreadEventCounts — so globalTotalBadgeCount folds a map that has never
      // heard of it and the app-bar bubble stays hidden. That is how kennel and
      // role-room chat shipped on 2026-09-14 with no top-level badge at all:
      // rooms were threaded through the list-building path and the per-row
      // badge, and the one place that AGGREGATES was missed (James saw it on
      // 2026-09-19 — "I'm not seeing the badge count").
      //
      // Keyed by roomBadgeKey(), not by a UUID. The key space is shared with
      // event and kennel threads and every lookup here matches on .asUuid,
      // which is only toLowerCase(), so a 'room:N' key is compared safely and
      // can never collide with a real id.
      for (final summary in serverChatSummary) {
        if (summary.isRoomThread) {
          unreadEventCounts[roomBadgeKey(summary.roomType!)] =
              summary.badgeCount.obs;
        }
      }
      // And the FOURTH kind, a direct message (E9.F1.S7): no run, no kennel,
      // no room — its ThreadId is its whole identity. Folded into the same
      // map so the app-bar bubble and the icon count it like any thread.
      for (final summary in serverChatSummary) {
        if (summary.isDmThread) {
          unreadEventCounts[dmBadgeKey(summary.threadId!)] =
              summary.badgeCount.obs;
        }
      }
      // Which threads have any content at all (read or not).
      threadsWithMessages
        ..clear()
        ..addAll(withMessages);

      // Every thread that HAS something in it, read or not (James,
      // 2026-09-13). A chat used to vanish from this list the moment it was
      // read, which made the one you had just read the hardest to find again
      // — you had to remember which run it was on. A read thread stays,
      // simply without a badge.
      //
      // Sorted by when the thread last had a message, NOT by the run's start
      // time: people talk about a run before and long after it, and a list
      // that keeps read threads needs a real most-recent order to stay
      // useful. Falls back to the run's start where a thread somehow has no
      // last-message time.
      final withData =
          serverChatSummary
              .where(
                (s) =>
                    // A PINNED thread stays listed even with nothing in it —
                    // that is what makes the home kennel and the role rooms
                    // discoverable, since almost none of them has a message
                    // yet (E9.F1.S8). Everything else still needs traffic to
                    // earn a row.
                    // A DM is listed even with nothing in it yet: an
                    // accepted request needs somewhere to go (E9.F1.S19).
                    ((s.messageCount ?? 0) > 0 || s.pinned || s.isDmThread) &&
                    (s.eventId != null ||
                        s.isKennelThread ||
                        s.isRoomThread ||
                        s.isDmThread),
              )
              .toList()
            ..sort((a, b) {
              // Pinned chats sit above everything else (E9.F1.S8) — your home
              // kennel and your role rooms by default, plus whatever you
              // pinned by hand. Within each group the existing order stands:
              // most recently spoken in first.
              if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
              final String ak =
                  a.lastMessageAt ?? a.eventStartDatetimeGmt ?? '';
              final String bk =
                  b.lastMessageAt ?? b.eventStartDatetimeGmt ?? '';
              return bk.compareTo(ak);
            });
      unreadChatRuns.value = withData;

      // Fold the app-bar bubble here, not at the call site. Only init() did
      // it, so the other four callers — the run list's two refreshes, the
      // nav bar and the chat bubble — rebuilt every per-thread count and left
      // globalTotalBadgeCount reading whatever it happened to hold.
      _recalculateGlobalBadgeCount();
    }

    await requests;

    if (Get.isRegistered<FutureRunListPageController>()) {
      Get.find<FutureRunListPageController>().refreshRunListUi();
    }
  }

  /// The pending DM requests, from the server. A FAILED call leaves the
  /// list as it was: a request that was there a moment ago has not gone
  /// away because the phone lost signal.
  Future<void> _refreshDmRequests() async {
    final List<DirectMessageRequest>? list =
        await DirectMessageService.fetchRequests();
    if (list == null) return;
    dmRequests.value = list;
    _recalculateGlobalBadgeCount();
  }

  /// Re-counts the badges after a request is answered locally (the chat
  /// list removes it from [dmRequests] before the server is asked again).
  void recalculateBadges() => _recalculateGlobalBadgeCount();

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
    if (kUiTest) return; // headless screen walk: no native alert
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
            BootLogger.logError(
              '[NotificationService] FCM token save failed',
              e,
              s,
            );
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
    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      RemoteMessage message,
    ) async {
      await _handleNotificationClick(message);
      if (kDebugMode) {
        debugPrint('Message opened app received: ${message.payload}');
      }
    });
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint("Foreground message received: ${message.payload}");
    }

    // Song notifications bypass badge logic — dispatch immediately so the
    // songbook updates without the badge HTTP round-trip adding latency.
    final String? silentType = message.payload['Type'] as String?;
    if (silentType == 'song_selected') {
      _dispatchMessageToControllers(message);
      return;
    }

    // 1. Badge Update Logic: refresh every thread kind's unread counts.
    //
    // This used to key on message.payload['PublicEventId'], which ONLY a run
    // chat carries: AppApiHC6.SendChatNotifications sends RoomType for a room
    // and KennelId for a kennel thread, by design. With the id null,
    // _updateChatCountBadges returns at its first guard and nothing else in
    // the foreground path reads the server — so with the app OPEN, a kennel
    // or room message moved no badge at all. Closing the app hid the fault:
    // reopening runs this same refresh from the resume path, and every badge
    // appears at once (James, 2026-09-19: "when the app is open, none of the
    // badges update").
    //
    // Even for a run chat the old path was half a refresh — it wrote
    // unreadEventCounts and the global fold, but never unreadChatRuns or
    // threadsWithMessages, so the chat LIST kept its old rows and badges
    // while the number above it moved.
    //
    // getEventChatMessageCounts() is the refresh boot and resume already use:
    // the same SP and the same request body as the single-count call it
    // replaces, rebuilding all four fields from the returned rows. Every
    // thread kind is handled because the rows say what they are — a fourth
    // kind needs no branch here, which is the mistake this file has now made
    // twice (see the room aggregation note above).
    // Somebody pressed Send Help: beep and buzz before anything else, so
    // the runner looks at the phone (James, 2026-09-30). Keyed on the
    // message id so the map's sighting of the same mark does not ring again.
    if (DistressAlert.isHelpMessage(message.payload['Message'])) {
      unawaited(
        DistressAlert.ring(
          'msg:${message.payload['MessageId'] ?? message.payload['Message']}',
        ),
      );
    }
    await getEventChatMessageCounts();

    // 2. Dispatch to internal controllers
    _dispatchMessageToControllers(message);
  }

  Future<void> _handleNotificationClick(RemoteMessage message) async {
    // Two defences, because this path has already been wrong once.
    //
    // FIRST, and unconditionally: every Get.until below stops at
    // route.isFirst as well as at '/main'. popUntil pops until its predicate
    // matches and empties the stack when nothing does — an empty navigator
    // is a black, frozen app that only a force-quit clears. isFirst makes
    // that outcome impossible whatever the timing, so a mistake in the
    // holding logic below can cost a missed navigation but never a hang.
    //
    // SECOND: nothing here may touch the navigator until '/main' exists.
    //
    // Both entry points can fire before it does. getInitialMessage() is
    // awaited from init(), which main() awaits BEFORE runApp() — there is no
    // Navigator at all at that point — and onMessageOpenedApp can land while
    // the boot/splash screen is still the only route on the stack. Either way
    // the Get.until below pops until it finds '/main', and finding nothing it
    // pops EVERY route, leaving an empty navigator: a black, frozen app that
    // only a force-quit clears. Opening from the icon instead is fine, which
    // is exactly how this was reported (Tuna Melt's phone, 2026-09-19,
    // tapping a role-room push; three launches on 3.1.0+1388 whose logs stop
    // dead after [VERSION] with no paused/resumed metric following).
    //
    // So an early tap is HELD, not dropped — [onMainReady] replays it once the
    // run list is on screen, which also fixes the other half of the same
    // fault: a cold-start tap never navigated anywhere, because
    // FutureRunListPageController was not registered yet when it was handled.
    if (!_mainReady) {
      _pendingTap = message;
      BootLogger.logBreadcrumb(
        '[NotificationService] tap held until /main exists',
      );
      return;
    }

    // Song notification tap — update session state then navigate to the songbook.
    // onSongSelected() must be called first so pendingSongId is set before the
    // SongsPageController's ever() worker fires on navigation.
    final String? silentType = message.payload['Type'] as String?;
    if (silentType == 'song_selected') {
      final String? eventId = message.payload['EventId'] as String?;
      final String? songId = message.payload['SongId'] as String?;
      if (eventId != null && songId != null) {
        SongSessionNotifier.ensure().onSongSelected(
          eventId: eventId.toLowerCase(),
          songId: songId.toLowerCase(),
          songTitle: message.payload['SongTitle'] as String? ?? '',
          selectedByName:
              message.payload['SelectedByName'] as String? ?? 'Someone',
        );
        Get.until((route) => route.isFirst || route.settings.name == '/main');
        _navigateToSongbook(eventId.toLowerCase());
      }
      return;
    }

    // The app icon is not cleared on a tap any more (2026-09-28): the tap
    // opens ONE chat, and the others may still be unread. Reading it moves the
    // server count, and the refresh that follows sets the icon to what is left.

    //pop all the way back to the main page
    Get.until((route) => route.isFirst || route.settings.name == '/main');

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

  /// Called by MainNavigationPageController once its pages exist and '/main'
  /// is on the stack. Replays a tap that arrived during boot.
  void onMainReady() {
    _mainReady = true;
    final RemoteMessage? held = _pendingTap;
    if (held == null) return;
    _pendingTap = null;
    BootLogger.logBreadcrumb('[NotificationService] replaying held tap');
    unawaited(_handleNotificationClick(held));
  }

  void _dispatchMessageToControllers(RemoteMessage message) {
    // Data-only silent messages use a string Type field rather than MessageType.
    final String? silentType = message.payload['Type'] as String?;
    if (silentType == 'song_selected') {
      _handleSongSelected(message);
      return;
    }

    // A DM EVENT — somebody asked to message you, or accepted your ask — is
    // not a chat message and opens no thread by itself. The request list
    // was refreshed by the caller; this is the in-app banner for it.
    final Map<String, dynamic> payload = message.payload;
    if ('${payload['ThreadKind'] ?? ''}' == 'dm' &&
        payload['DmEvent'] != null) {
      _showDmEventToast(payload);
      return;
    }

    // `?? 0` only guards a FAILED parse — it does not guard a null INPUT, and
    // int.tryParse takes a String, so a push with no 'MessageType' key threw
    // "type 'Null' is not a subtype of type 'String'" and aborted the whole
    // dispatch (seen twice in production on 2026-08-30). Data-only pushes that
    // are not song_selected reach here without the field. Stringify first so
    // an absent key, a null, or a numeric value all fall back to 0.
    final MessageType messageType = MessageType.fromId(
      int.tryParse('${message.payload['MessageType'] ?? ''}') ?? 0,
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
            debugPrint('Handling chat message: ${message.payload}');
          }
        } catch (e, s) {
          if (kDebugMode) {
            debugPrint("ChatController not found: $e");
          }
          BootLogger.logError(
            '[NotificationService] chat message dispatch failed',
            e,
            s,
          );
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
    // // Populate unreadEventCounts with RxInt values derived from clientChatCounts.
    //     key: (clientChatCounts[key] ?? 0).obs,
    // };

    globalTotalBadgeCount.value =
        unreadEventCounts.values.fold<int>(
          0,
          // A thread never takes the total down: the server's unread count can
          // dip below zero when a message is removed, and HC6.UserUnreadChatTotal
          // (the number the pushes put on the icon) counts only the positives.
          (sum, rxInt) => sum + (rxInt.value > 0 ? rxInt.value : 0),
        ) +
        // A request to message this hasher is something to act on, so it
        // counts like an unread message until answered — the same rule
        // HC6.UserUnreadChatTotal applies to the number a push puts on the
        // icon (James, 2026-09-29).
        dmRequests.length;
    // Every refresh ends here — boot, resume, a chat push, a read_sync, mark
    // all read — so this is the one place the app ICON is set. Written every
    // time, not only on a change: a push may have left a number on the icon
    // that the app has not seen, and 0 → 0 would never correct it.
    unawaited(setAppIconBadge(globalTotalBadgeCount.value));
  }

  /// The number on the app icon (2026-09-28). iOS shows it as given; Android
  /// shows it where the launcher supports a number (Samsung and others) and a
  /// dot elsewhere. Never throws: a badge is not worth an error.
  static Future<void> setAppIconBadge(int count) async {
    try {
      await AppBadgePlus.updateBadge(count < 0 ? 0 : count);
    } catch (e) {
      if (kDebugMode) debugPrint('setAppIconBadge($count) failed: $e');
    }
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

    // // Update the stored server count for this event

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

    // Clear the badge on the row but KEEP it in the list (James, 2026-09-13):
    // reading a chat used to delete it from the list, which made the chat you
    // had just read the hardest one to find again. It stays, unbadged, in its
    // place in the most-recent order.
    for (int i = 0; i < unreadChatRuns.length; i++) {
      final EventChatSummary s = unreadChatRuns[i];
      final bool match = isKennelThread
          ? (s.isKennelThread && (s.publicKennelId ?? '').asUuid == id)
          : (s.publicEventId.asUuid == id);
      if (!match || s.badgeCount == 0) continue;
      unreadChatRuns[i] = s.withBadgeCount(0);
      changed = true;
    }

    if (changed && Get.isRegistered<FutureRunListPageController>()) {
      Get.find<FutureRunListPageController>().refreshRunListUi();
    }
  }

  /// The room counterpart of [clearUnreadForThread]: zeroes a platform-wide
  /// room's unread badge the instant the room is opened, so the app-bar bubble
  /// drops without waiting for the next server fetch.
  ///
  /// A room needs its own entry point because it has no publicEventId or
  /// publicKennelId to pass as a threadId — [roomBadgeKey] is the whole
  /// identity. Server-side the read is already durable: hcapp_getRoomMessages
  /// is called with markRead, so this is purely the optimistic half.
  void clearUnreadForRoom(int roomType) {
    final String key = roomBadgeKey(roomType);
    var changed = false;

    final RxInt? count = unreadEventCounts[key];
    if (count != null && count.value != 0) {
      count.value = 0;
      changed = true;
    }
    if (changed) _recalculateGlobalBadgeCount();

    // Same rule as every other thread (James, 2026-09-13): the row loses its
    // badge but KEEPS its place in the list, so the chat you just read is not
    // the hardest one to find again.
    for (int i = 0; i < unreadChatRuns.length; i++) {
      final EventChatSummary s = unreadChatRuns[i];
      if (!s.isRoomThread || s.roomType != roomType || s.badgeCount == 0) {
        continue;
      }
      unreadChatRuns[i] = s.withBadgeCount(0);
      changed = true;
    }

    if (changed && Get.isRegistered<FutureRunListPageController>()) {
      Get.find<FutureRunListPageController>().refreshRunListUi();
    }
  }

  /// The DM counterpart of [clearUnreadForRoom]: zeroes a direct message
  /// thread's badge the instant it is opened. Server-side the read is
  /// already durable — hcapp_getDirectMessages is called with markRead —
  /// so this is purely the optimistic half.
  void clearUnreadForDm(HcId threadId) {
    final String key = dmBadgeKey(threadId);
    var changed = false;

    final RxInt? count = unreadEventCounts[key];
    if (count != null && count.value != 0) {
      count.value = 0;
      changed = true;
    }
    if (changed) _recalculateGlobalBadgeCount();

    // The row loses its badge but KEEPS its place (James, 2026-09-13).
    for (int i = 0; i < unreadChatRuns.length; i++) {
      final EventChatSummary s = unreadChatRuns[i];
      if (!s.isDmThread || s.threadId != threadId || s.badgeCount == 0) {
        continue;
      }
      unreadChatRuns[i] = s.withBadgeCount(0);
      changed = true;
    }

    if (changed && Get.isRegistered<FutureRunListPageController>()) {
      Get.find<FutureRunListPageController>().refreshRunListUi();
    }
  }

  /// The in-app banner for a DM event push while the app is open. A tap on
  /// the system notification goes through the run list's tap handler
  /// instead; this mirrors where that lands.
  void _showDmEventToast(Map<String, dynamic> payload) {
    final String event = '${payload['DmEvent'] ?? ''}';
    final String rawName = '${payload['FromDisplayName'] ?? ''}'.trim();
    final String name = rawName.isEmpty ? 'A hasher' : rawName;
    if (event == 'request') {
      hcSnack(
        '$name wants to message you.',
        seconds: 8,
        actionLabel: 'View',
        onAction: () {
          if (Get.isRegistered<FutureRunListPageController>()) {
            unawaited(Get.find<FutureRunListPageController>().openChatsView());
          }
        },
      );
      return;
    }
    if (event == 'accepted') {
      final HcId? threadId = HcId.tryParse(payload['ThreadId']);
      final HcId other = HcId('${payload['FromPublicHasherId'] ?? ''}');
      final Object? rawPhoto = payload['FromPhoto'];
      hcSnack(
        '$name accepted your request.',
        seconds: 8,
        actionLabel: threadId == null ? null : 'Open',
        onAction: threadId == null
            ? null
            : () => unawaited(
                ChatPageController.openDirectMessage(
                  threadId: threadId,
                  otherPublicHasherId: other,
                  otherDisplayName: name,
                  otherPhoto: rawPhoto is String ? rawPhoto : null,
                ),
              ),
      );
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

    // The double-tick RESETS BADGES AND LEAVES THE ROWS (James, 2026-09-15).
    // The rows carry their own badgeCount, so zeroing the map above is not
    // enough — without this the list still shows every badge it just claimed
    // to clear. withBadgeCount exists for exactly this: same thread, no
    // badge, still listed.
    unreadChatRuns.value = unreadChatRuns
        .map((EventChatSummary s) => s.withBadgeCount(0))
        .toList();

    _recalculateGlobalBadgeCount();

    if (Get.isRegistered<FutureRunListPageController>()) {
      Get.find<FutureRunListPageController>().refreshRunListUi();
    }
  }

  // --- External App Badge Interface (Needs Implementation) ---

  // /// Updates the native platform application badge count.
  // void _updateAppBadge() {
  //   // ⚠️ IMPLEMENT EXTERNAL BADGE LOGIC HERE

  /// Clears the native platform application badge.
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
    final String? eventId = message.payload['EventId'] as String?;
    final String? songId = message.payload['SongId'] as String?;
    final String songTitle = message.payload['SongTitle'] as String? ?? '';
    final String selectedByName =
        message.payload['SelectedByName'] as String? ?? 'Someone';

    if (eventId == null || songId == null) return;

    final String eid = eventId.toLowerCase();
    final String sid = songId.toLowerCase();

    SongSessionNotifier.ensure().onSongSelected(
      eventId: eid,
      songId: sid,
      songTitle: songTitle,
      selectedByName: selectedByName,
    );

    // If the user is already on the interactive songbook for this event,
    // the ever() reaction in SongsPageController handles the update directly.
    // Otherwise, show an in-app toast so they can navigate there.
    final bool onSongbook = Get.isRegistered<SongsPageController>(tag: eid);
    if (!onSongbook) {
      _showSongToast(eid, songTitle, selectedByName);
    }

    if (kDebugMode) {
      debugPrint(
        '[NotificationService] song_selected: "$songTitle" by $selectedByName (onSongbook=$onSongbook)',
      );
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
          // Best-effort, and its future would otherwise fail uncaught.
          unawaited(Get.closeCurrentSnackbar().catchError((_) {}));
          _navigateToSongbook(eventId);
        },
        child: const Text(
          'Go to song',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _navigateToSongbook(String eventId) {
    Get.to<void>(
      () => AppScaffold(
        appBar: AppBar(
          backgroundColor: themeAppBarBackground,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text('Songbook', style: ts_appBarTitle),
        ),
        body: SongsPage(eventId: eventId),
      ),
    );
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
