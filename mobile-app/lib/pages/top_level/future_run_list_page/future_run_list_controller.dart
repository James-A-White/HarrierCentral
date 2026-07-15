import 'package:harrier_central/imports.dart';

/// Marker item inserted into the displayed run list to separate the user's
/// attended past runs (above) from their upcoming/future runs (below).
/// Rendered as the "Past Runs" divider. Kept as a dedicated type rather than a
/// magic int so it never collides with the run-classification header ints.
class PastRunsDivider {
  const PastRunsDivider();
}

class FutureRunListPageController extends GetxController {
  FutureRunListPageController();

  StreamSubscription<DataChangeEvent>? _dataChangeSub;

  RxDouble width = 0.0.obs;
  RxDouble height = 0.0.obs;

  int pageIndex = 1;
  List<RunDetailsAggregate>? allRuns;
  RxList<RunDetailsAggregate> preFilteredRuns = <RunDetailsAggregate>[].obs;
  RxList<dynamic> filteredRuns = [].obs;

  /// All past runs in the local common domain (followed-kennel history +
  /// attended), loaded alongside [allRuns]. Source for the inline past section;
  /// the "My" chip narrows it to the user's own runs.
  List<RunDetailsAggregate>? allPastRuns;

  /// Chip- and search-filtered past runs, sorted oldest -> newest so the most
  /// recent sits just above the divider. Merged ahead of [filteredRuns] at
  /// display time — see [displayRuns].
  RxList<RunDetailsAggregate> pastRuns = <RunDetailsAggregate>[].obs;
  RxInt resultCount = 0.obs;
  RxString searchRunsText = ''.obs;
  Rx<RunsToDisplay> runsToDisplay = RunsToDisplay.allRuns.obs;
  RxBool runsToDisplayLoading = false.obs;
  RxBool showRunToDisplaySpinner = false.obs;
  RxBool runsTimeScopeLoading = false.obs;
  RxBool showRunsTimeScopeSpinner = false.obs;

  // Background sync state
  final RxBool isSyncing = false.obs;
  final RxInt newRunsAboveViewport = 0.obs;
  final RxList<String> flashingRunIds = <String>[].obs;
  bool _isSyncInProgress = false;
  DateTime? _lastSyncCompleted;
  Map<String, RunDetailsAggregate> _previousRuns = {};
  Rx<RunsTimeScope> runsTimeScope = RunsTimeScope.future.obs;
  Rx<DateTime> dateFilterStart = DateTime.now()
      .subtract(const Duration(days: 7))
      .obs;
  Rx<DateTime> dateFilterEnd = DateTime.now().add(const Duration(days: 7)).obs;
  RxBool multiYearDateFilter = false.obs;

  // ── Filter chips (stackable) ───────────────────────────────────────────────
  // Independent on/off filters layered over the combined past+future list:
  //   My     = only the user's runs (RSVP'd upcoming / attended past)
  //   Events = only special events (geographic scope >= local event)
  //   Map    = only runs within the Explore map's visible bounds
  final RxBool filterMy = false.obs;
  final RxBool filterEvents = false.obs;
  final RxBool filterMap = false.obs;

  // The run list is rendered with a ScrollablePositionedList so it can open
  // anchored on the "Past Runs" divider (index-based) with the user's attended
  // past runs scrollable above it. That list manages its own controllers, so we
  // use ItemScrollController/ItemPositionsListener instead of a ScrollController.
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  /// Chats mode is the only non-chip list mode (reached via the top-bar chat
  /// badge); it shows unread-chat runs across all time. Otherwise the list is
  /// driven by the My/Events/Map chips.
  bool get isChatsMode => runsToDisplay.value == RunsToDisplay.unreadChats;

  /// True when the combined past+future list (with the "My past runs" divider)
  /// is shown — i.e. normal chip mode in future scope. A date range or chats
  /// mode disables it and shows a single flat list instead.
  bool get showsInlinePast =>
      !isChatsMode && runsTimeScope.value == RunsTimeScope.future;

  // "My" = runs the user is actually part of: RSVP'd Yes (going), or attended.
  // NOTE: "attended" means attendenceState >= attendenceAtHash (20). Lower
  // values are NOT attendance — attendenceNo (10) means the opposite — so a
  // simple ">= 3" wrongly counts a "did not attend" row as attended.
  bool _isMyRun(RunDetailsAggregate a) =>
      a.extensions.rsvpState >= rsvpYes.value ||
      a.extensions.attendenceState >= attendenceAtHash.value;

  /// Whether a past run should appear in the past section. Excludes runs the
  /// user declined (RSVP No) or was unsure about (RSVP Maybe) — unless they
  /// actually attended (attendenceState >= attendenceAtHash), in which case it's
  /// kept regardless of the stale RSVP.
  bool _keepPastRun(RunDetailsAggregate a) {
    if (a.extensions.attendenceState >= attendenceAtHash.value) return true;
    final rsvp = a.extensions.rsvpState;
    return rsvp != rsvpNo.value && rsvp != rsvpMaybe.value;
  }

  /// Applies the active chip filters (Events, Map, My) to [runs], reusing the
  /// existing per-view predicates for Events/Map. Map is skipped while the map
  /// bounds aren't known yet (nothing to filter against — the View Map button
  /// lets the user set them).
  List<RunDetailsAggregate> _applyChipFilters(List<RunDetailsAggregate> runs) {
    var r = runs;
    if (filterEvents.value) {
      r = QueryRuns.applyDisplayScopeFilter(r, RunsToDisplay.events);
    }
    if (filterMap.value && mapBounds != null) {
      r = QueryRuns.applyDisplayScopeFilter(
        r,
        RunsToDisplay.onMap,
        mapBounds: mapBounds,
      );
    }
    if (filterMy.value) {
      r = r.where(_isMyRun).toList();
    }
    return r;
  }

  // ── Titles derived from the active chips ───────────────────────────────────
  String get _chipNoun => filterEvents.value ? 'Events' : 'Runs';
  String get _chipMapSuffix => filterMap.value ? ' on Map' : '';

  /// Upcoming-half title, e.g. "All Runs", "My Events", "My Runs on Map".
  String get futureSectionTitle =>
      '${filterMy.value ? 'My' : 'All'} $_chipNoun$_chipMapSuffix';

  /// Past-half title, e.g. "Past Runs", "My past Events". Also the divider label.
  String get pastSectionTitle =>
      '${filterMy.value ? 'My past' : 'Past'} $_chipNoun$_chipMapSuffix';

  /// The middle description text: the current filter state (no past/future
  /// wording — not enough room in the bar), or the chats label.
  String get barTitle {
    if (isChatsMode) return 'Unseen Chats';
    return futureSectionTitle;
  }

  /// The list actually rendered: attended past (oldest -> newest) + divider +
  /// future. Falls back to [filteredRuns] when the inline-past section doesn't
  /// apply or there are no past attended runs.
  List<dynamic> get displayRuns {
    if (!showsInlinePast || pastRuns.isEmpty) {
      return filteredRuns;
    }
    return <dynamic>[
      ...pastRuns,
      const PastRunsDivider(),
      ...filteredRuns,
    ];
  }

  /// Index the list should open at: the divider, so the next run sits just
  /// below it and the past runs are scrollable above. 0 when there's no past.
  int get initialScrollIndex =>
      (showsInlinePast && pastRuns.isNotEmpty)
      ? pastRuns.length
      : 0;

  /// Toggles a filter chip and re-filters. In normal mode the chips are pure
  /// in-memory filters over already-loaded data, so this just re-filters and
  /// re-anchors on the divider. Toggling a chip while in chats mode leaves it
  /// (which changes scope all -> future), so a reload is needed there.
  Future<void> toggleChip(RxBool chip) async {
    final wasChatsMode = isChatsMode;
    if (wasChatsMode) {
      runsToDisplay.value = RunsToDisplay.allRuns;
      runsTimeScope.value = RunsTimeScope.future;
    }
    chip.value = !chip.value;
    if (wasChatsMode) {
      await refreshFromTable(true);
    } else {
      filterRuns(false);
    }
    scrollToInitialAnchor();
  }

  /// Jumps the list to the "My past runs" divider (or the top when there's no
  /// past section) after the next frame. Used when switching views so the
  /// divider lands at the top of the viewport with the next run just below —
  /// [initialScrollIndex] only auto-applies on the list's first build, not on
  /// later view switches where the widget's state persists.
  void scrollToInitialAnchor() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (itemScrollController.isAttached) {
        itemScrollController.jumpTo(index: initialScrollIndex);
      }
    });
  }

  /// Whether the topmost visible row is in the attended-past section (above the
  /// divider). Drives the page title — "Past Runs" while scrolled into history,
  /// "Future Runs" otherwise. Maintained by [_updateViewingSection]; only
  /// meaningful when [showsInlinePast].
  final RxBool isViewingPastSection = false.obs;

  /// Updates [isViewingPastSection] from the list's current item positions.
  /// Cheap and guarded so it only flips state when the boundary is crossed.
  void _updateViewingSection() {
    if (!showsInlinePast || pastRuns.isEmpty) {
      if (isViewingPastSection.value) isViewingPastSection.value = false;
      return;
    }
    final positions = itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;
    final firstVisible = positions
        .map((p) => p.index)
        .reduce((a, b) => a < b ? a : b);
    // Indices below the divider (pastRuns.length) are past runs.
    final viewingPast = firstVisible < pastRuns.length;
    if (isViewingPastSection.value != viewingPast) {
      isViewingPastSection.value = viewingPast;
    }
  }

  LatLngBounds? mapBounds;

  //RxBool showOnlyEventsWithMessages = false.obs;

  final FocusNode searchFocusNode = FocusNode();
  final TextEditingController searchController = TextEditingController();

  bool showRsvpInstructions = false;

  Worker? _searchWorker;
  Worker? _displayLoadingWorker;
  Worker? _timeScopeLoadingWorker;

  @override
  void onClose() {
    _searchWorker?.dispose();
    _displayLoadingWorker?.dispose();
    _timeScopeLoadingWorker?.dispose();
    _dataChangeSub?.cancel();
    itemPositionsListener.itemPositions.removeListener(_updateViewingSection);
    searchController.dispose();
    searchFocusNode.dispose();
    flashingRunIds.clear();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();

    itemPositionsListener.itemPositions.addListener(_updateViewingSection);

    _searchWorker = debounce<String>(
      searchRunsText,
      (_) => filterRuns(true),
      time: const Duration(milliseconds: 1000),
    );

    _displayLoadingWorker = debounce<bool>(
      runsToDisplayLoading,
      (isLoading) async {
        if (isLoading) {
          await Future.delayed(const Duration(milliseconds: 500));
          // still loading? then show it
          if (runsToDisplayLoading.value) showRunToDisplaySpinner.value = true;
        } else {
          showRunToDisplaySpinner.value = false;
        }
      },
      time: const Duration(milliseconds: 0), // immediate trigger
    );

    _timeScopeLoadingWorker = debounce<bool>(
      runsTimeScopeLoading,
      (isLoading) async {
        if (isLoading) {
          await Future.delayed(const Duration(milliseconds: 500));
          // still loading? then show it
          if (runsTimeScopeLoading.value) showRunsTimeScopeSpinner.value = true;
        } else {
          showRunsTimeScopeSpinner.value = false;
        }
      },
      time: const Duration(milliseconds: 0), // immediate trigger
    );

    IveCoreUtilities.logTiming('initState called', appModel.appStartTime);
    debugPrint('[BOOT] FutureRunListController.onInit: ${DateTime.now().millisecondsSinceEpoch}ms');
    searchController.text = '';
    searchRunsText.value = '';

    _dataChangeSub = Get.find<DataChangeService>().stream.listen(_onDataChange);

    debugPrint('[BOOT] FutureRunListController.onInit: firing onInitAsync: ${DateTime.now().millisecondsSinceEpoch}ms');
    unawaited(onInitAsync());
  }

  Future<void> onInitAsync() async {
    debugPrint('[BOOT] onInitAsync: start: ${DateTime.now().millisecondsSinceEpoch}ms');
    // do an immediate refresh from table to quickly display data already cached in the app
    debugPrint('[BOOT] onInitAsync: refreshFromTable start: ${DateTime.now().millisecondsSinceEpoch}ms');
    await refreshFromTable(true);
    debugPrint('[BOOT] onInitAsync: refreshFromTable done: ${DateTime.now().millisecondsSinceEpoch}ms — runCount=${allRuns?.length ?? 0}');
    // then do any updates that require a trip to the server.
    debugPrint('[BOOT] onInitAsync: Permission.location.isGranted check: ${DateTime.now().millisecondsSinceEpoch}ms');
    appModel.hasLocationPermissions = await Permission.location.isGranted;
    debugPrint('[BOOT] onInitAsync: hasLocationPermissions=${appModel.hasLocationPermissions}: ${DateTime.now().millisecondsSinceEpoch}ms');

    //await refreshFromBackend();
    //await refreshFromTable(true);
    //chatSummaryMap = await getEventChatMessageCounts();

    // NotificationService is registered in initServices(). If Firebase was not
    // ready at boot time, register it now on first use.
    debugPrint('[BOOT] onInitAsync: Firebase.apps.isNotEmpty=${Firebase.apps.isNotEmpty}: ${DateTime.now().millisecondsSinceEpoch}ms');
    if (Firebase.apps.isNotEmpty && !Get.isRegistered<NotificationService>()) {
      debugPrint('[BOOT] onInitAsync: registering NotificationService: ${DateTime.now().millisecondsSinceEpoch}ms');
      await Get.putAsync<NotificationService>(
        () => NotificationService().init(),
        permanent: false,
      );
      debugPrint('[BOOT] onInitAsync: NotificationService registered: ${DateTime.now().millisecondsSinceEpoch}ms');
    }

    if (Firebase.apps.isNotEmpty) {
      debugPrint('[BOOT] onInitAsync: getInitialMessage start: ${DateTime.now().millisecondsSinceEpoch}ms');
      final msg = await FirebaseMessaging.instance.getInitialMessage();
      debugPrint('[BOOT] onInitAsync: getInitialMessage done: ${DateTime.now().millisecondsSinceEpoch}ms — msg=${msg != null ? "present" : "null"}');
      if (msg != null) {
        await _processMessage(msg.data);
      }
    }
    // _updateTotalNotificationCounter();
    debugPrint('[BOOT] onInitAsync: calling update(runList, mainNavPage): ${DateTime.now().millisecondsSinceEpoch}ms');
    update([UpdateIds.runList, UpdateIds.mainNavPage]);
    debugPrint('[BOOT] onInitAsync: COMPLETE: ${DateTime.now().millisecondsSinceEpoch}ms');
  }

  void _onDataChange(DataChangeEvent event) {
    if (event.type == DataChangeType.runUpdated ||
        event.type == DataChangeType.runCreated) {
      unawaited(reloadAndFlash());
    }
  }

  /// Reloads runs from the local DB and flashes any rows whose data changed
  /// since the current in-memory list. Use for background refreshes (data-change
  /// events, boot/background sync) so the user can see which runs updated — the
  /// plain [refreshFromTable] used on initial load has nothing to diff against.
  Future<void> reloadAndFlash() async {
    _previousRuns = {
      for (final r in allRuns ?? <RunDetailsAggregate>[])
        normalizeUuid(r.event.eventId): r,
    };
    final newAllRuns = await QueryRuns.getRunDetailsAggregates(
      true,
      runsTimeScope: runsTimeScope.value,
      runsToDisplay: runsToDisplay.value,
    );
    await _loadPastRuns();
    _applyDataUpdate(newAllRuns);
  }

  void refreshRunListUi() {
    filterRuns(false);
    update([UpdateIds.runList, UpdateIds.mainNavPage]);
  }

  void notificationReceived(RemoteMessage message) {
    //final publicEventId = message.data['PublicEventId'] as String?;

    // // get the total amount of chats for this event from the message
    // final chatCount =
    //     (int.tryParse(message.data['EventChatMessageCount'] as String) ?? 0);

    //_updateChatCountBadges(publicEventId, chatCount);
    filterRuns(false);
  }

  // void _updateChatCountBadges(String? publicEventId, int chatCount) {
  //   if (publicEventId != null) {
  //     // get the number of chats last displayed in the chat window
  //     // when it was last shown
  //     final chatsCounts = getMapIntPref(MapPrefsEnum.unusedChatCounts);

  //     // calculate how many chats have not been seen yet
  //     if (thisEventUnseenChats[publicEventId] == null) {
  //       thisEventUnseenChats[publicEventId] =
  //           (chatCount - (chatsCounts[publicEventId] ?? 0)).obs;
  //     } else {
  //       thisEventUnseenChats[publicEventId]!.value =
  //           chatCount - (chatsCounts[publicEventId] ?? 0);
  //     }
  //   }

  //   _updateTotalNotificationCounter();

  //   update([UpdateIds.runList, UpdateIds.mainNavPage]);
  // }

  // void resetNotificationCounters() async {
  //   //chatSummaryMap = await getEventChatMessageCounts();
  //   final chatsCounts = getMapIntPref(MapPrefsEnum.unusedChatCounts);

  //   for (var run in filteredRuns) {
  //     if (run is! int) {
  //       String? publicEventId = run.event?.publicEventId as String?;
  //       if (publicEventId != null) {
  //         if (chatSummaryMap[publicEventId] != null) {
  //           chatsCounts[publicEventId] =
  //               chatSummaryMap[publicEventId]?.eventChatMessageCount ?? 0;
  //         }
  //         thisEventUnseenChats[publicEventId]?.value = 0;
  //       }
  //     }
  //   }

  //   setMapIntPref(MapPrefsEnum.unusedChatCounts, chatsCounts);

  //   _updateTotalNotificationCounter();

  //   //showOnlyEventsWithMessages.value = false;

  //   update([UpdateIds.runList, UpdateIds.mainNavPage]);
  // }

  // void _updateTotalNotificationCounter() {
  //   int total = 0;

  //   for (var run in filteredRuns) {
  //     if (run is! int) {
  //       String? publicEventId = run.event?.publicEventId as String?;
  //       if (publicEventId != null) {
  //         total +=
  //             (thisEventUnseenChats[publicEventId]?.value ??
  //             chatSummaryMap[publicEventId]?.eventChatMessageCount ??
  //             0);
  //       }
  //     }
  //   }

  //   totalNotifications.value = total;
  // }

  Future<void> processNotificationClickOnResume(RemoteMessage message) async {
    // if there was no initial message, check to see if there was
    // data from a message tap when the app was already opened but
    // in the background

    await _processMessage(message.data);
  }

  Future<void> _processMessage(Map<String, dynamic> data) async {
    String? eventId = data['EventId']?.toString().toUpperCase();
    MessageType messageType = MessageType.fromId(
      int.tryParse(data['MessageType']) ?? 0,
    );
    if ((eventId != null) && (allRuns != null)) {
      dynamic runs = allRuns!
          .where((dynamic a) => normalizeUuid(a.event?.eventId as String?) == normalizeUuid(eventId))
          .toList();

      if ((runs != null) && (runs.length > 0)) {
        var run = runs[0];

        RunTab? openToTab;

        switch (messageType) {
          case MessageType.chat:
            openToTab = RunTab.chat;
            break;
          case MessageType.checkinReminder:
            await Utilities.isAtRunStart(eventId: eventId);
            break;
          case MessageType.rsvpReminder:
            openToTab = RunTab.rsvp;
            break;
        }

        if (openToTab != null) {
          await openRun(run, openToTab: openToTab);
        }
      }
    }
  }

  Future<void> openList() async {
    final controller = Get.find<MainNavigationController>();
    controller.bottomNavigationKey.currentState?.setPage(0);
    // Return to normal chip mode with the Map chip on — NOT the legacy
    // onMap/all-scope view. Staying in future scope keeps the inline "Past Runs"
    // section alive (showsInlinePast requires future scope); the Map chip filters
    // the list to the map bounds the map controller already primed. Setting
    // all-scope here silently dropped the past section and left no way back to it.
    runsToDisplay.value = RunsToDisplay.allRuns;
    runsTimeScope.value = RunsTimeScope.future;
    filterMap.value = true;
    await refreshFromTable(true);
    scrollToInitialAnchor();
  }

  void openMap() {
    final controller = Get.find<MainNavigationController>();
    controller.bottomNavigationKey.currentState?.setPage(2);
  }

  Future<void> openRun(RunDetailsAggregate run, {RunTab? openToTab}) async {
    if (openToTab != null) {
      await Get.to(
        () => RunDetailsPage(
          futureRun: run,
          openToTab: openToTab,
          refreshPage: () async {
            // WARNING!!!!  We need to return the filtered run based
            // on it's ID and not the index
            // await controller.refreshFromBackend(
            //     clearLocalTables: true);
            await refreshFromTable(true);
            return run;
          },
        ),
      );
    }

    await refreshFromBackend(clearLocalTables: false);

    // _updateTotalNotificationCounter();

    update([UpdateIds.runList, UpdateIds.mainNavPage]);

    //setStateIfMounted(() {});

    // Navigator.push<dynamic>(
    //   context,
    //   MaterialPageRoute<dynamic>(
    //     builder: (BuildContext context) =>

    //     RunDetailsPage(
    //       futureRun: run,
    //       openToChatTab: openToChatTab,
    //       refreshPage: () async {
    //         // WARNING!!!!  We need to return the filtered run based
    //         // on it's ID and not the index
    //         // await controller.refreshFromBackend(
    //         //     clearLocalTables: true);
    //         await refreshFromTable(true);
    //         return run;
    //       },
    //     ),
    //   ),
    // ).then((void _) {
    //   refreshFromBackend(clearLocalTables: false).then((void _) {
    //     // this means the user went to the chat page, so reset to zero to hide the badge
    //     // I don't like this logic, but it will have to do for now.
    //     final chatsCounts2 = getMapIntPref(MapPrefsEnum.chatCounts);
    //     if ((chatsCounts2[run.event.publicEventId] ?? 0) !=
    //         (chatsCounts[run.event.publicEventId] ?? 0)) {
    //       thisEventChatCount[run.event.publicEventId] = 0;
    //     }

    //     setStateIfMounted(() {});
    //   });
    // });
  }

  DateTime _toDateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  Future<void> refreshFromTable(bool forceRefresh) async {
    debugPrint('[BOOT] refreshFromTable: forceRefresh=$forceRefresh, allRuns=${allRuns?.length ?? "null"}: ${DateTime.now().millisecondsSinceEpoch}ms');
    if (forceRefresh || (allRuns == null) || (allRuns!.isEmpty)) {
      debugPrint('[BOOT] refreshFromTable: calling getRunDetailsAggregates: ${DateTime.now().millisecondsSinceEpoch}ms');
      allRuns = await QueryRuns.getRunDetailsAggregates(
        true,
        runsTimeScope: runsTimeScope.value,
        runsToDisplay: runsToDisplay.value,
      );
      debugPrint('[BOOT] refreshFromTable: getRunDetailsAggregates done: ${DateTime.now().millisecondsSinceEpoch}ms — ${allRuns?.length ?? 0} runs');
      await _loadPastRuns();
      debugPrint('[BOOT] refreshFromTable: calling filterRuns: ${DateTime.now().millisecondsSinceEpoch}ms');
      filterRuns(false);
      debugPrint('[BOOT] refreshFromTable: filterRuns done: ${DateTime.now().millisecondsSinceEpoch}ms — filteredRuns=${filteredRuns.length}');
    }
    return;
  }

  /// Loads all past runs in the local common domain (no attendance filter — the
  /// "My" chip does that narrowing). Fully synced locally, so no backend trip.
  /// Cleared in chats mode (which shows its own all-time list).
  Future<void> _loadPastRuns() async {
    if (isChatsMode) {
      allPastRuns = <RunDetailsAggregate>[];
      return;
    }
    allPastRuns = await QueryRuns.getRunDetailsAggregates(
      true,
      runsTimeScope: RunsTimeScope.past,
      runsToDisplay: RunsToDisplay.allRuns,
    );
  }

  /// filterRuns() provides a complex filtering (search) option
  /// where the plus sign (+) is used as a logical OR allowing
  /// query results to be added together and commas (,) to be used
  /// to separate query options and act as a logical AND function, thus
  /// limiting the query results. Finally the text 'not ' at the beginning
  /// of a search term will negate the resdults.
  ///
  /// For example: "AH3 + FILTH, not Wednesday + Thursday" will show all
  /// Amsterdam and FILTH hashes that are not on a Wednesday or Thursday
  ///
  void filterRuns(bool searchTextChanged) {
    debugPrint('[BOOT] filterRuns: start, searchTextChanged=$searchTextChanged, allRuns=${allRuns?.length ?? "null"}: ${DateTime.now().millisecondsSinceEpoch}ms');
    showRsvpInstructions = true;

    // Chats mode is server-driven: render the runs the badge SP returned
    // (which includes runs the user hasn't synced locally) as lightweight chat
    // rows, so the list always matches the unread-chat badge.
    if (isChatsMode) {
      final all = Get.isRegistered<NotificationService>()
          ? Get.find<NotificationService>().unreadChatRuns.toList()
          : <EventChatSummary>[];
      final q = searchRunsText.value.trim().toLowerCase();
      final list = q.isEmpty
          ? all
          : all
                .where(
                  (s) =>
                      (s.kennelShortName ?? '').toLowerCase().contains(q) ||
                      (s.eventName ?? '').toLowerCase().contains(q) ||
                      (s.eventNumber?.toString() ?? '').contains(q),
                )
                .toList();
      filteredRuns.value = List<dynamic>.from(list);
      resultCount.value = filteredRuns.length;
      if (pastRuns.isNotEmpty) pastRuns.clear();
      update([UpdateIds.runList]);
      return;
    }

    // if we are only changing the search text, then we don't need to
    // re-filter the runs by time scope and runs to display
    if (!searchTextChanged) {
      // doRunsFilter does the time/date-range filter only (allRuns view = no
      // view predicate), then the chips are layered on top.
      final timeFiltered = QueryRuns.doRunsFilter(
        allRuns ?? <RunDetailsAggregate>[],
        RunsToDisplay.allRuns,
        runsTimeScope.value,
        dateRangeStart: dateFilterStart.value,
        dateRangeEnd: dateFilterEnd.value,
        useDatesForAllYears: multiYearDateFilter.value,
      );
      preFilteredRuns.value = _applyChipFilters(timeFiltered);
      debugPrint('[BOOT] filterRuns: doRunsFilter done: ${DateTime.now().millisecondsSinceEpoch}ms — preFiltered=${preFilteredRuns.length}');
    }

    debugPrint('[BOOT] filterRuns: doRunsSearchTextFilter start: ${DateTime.now().millisecondsSinceEpoch}ms');
    filteredRuns.value = QueryRuns.doRunsSearchTextFilter(
      searchRunsText.value,
      preFilteredRuns,
    );
    debugPrint('[BOOT] filterRuns: doRunsSearchTextFilter done: ${DateTime.now().millisecondsSinceEpoch}ms — filtered=${filteredRuns.length}');

    if (runsTimeScope.value == RunsTimeScope.future) {
      debugPrint('[BOOT] filterRuns: sort start: ${DateTime.now().millisecondsSinceEpoch}ms');
      filteredRuns.sort((dynamic a, dynamic b) {
        // start by sorting by run classification, closest runs should be listed first, then runs
        // from Kennels the user is following, then the rest
        int result = a.extensions.runClassification.compareTo(
          b.extensions.runClassification,
        );

        if (result == 0) {
          result = _toDateOnly(
            a.event.eventStartDatetime,
          ).compareTo(_toDateOnly(b.event.eventStartDatetime));
          // if the runs are on the same day then try to sort by distance
          // if there are no distances because location services are off, then sort by Kennel name
          if (result == 0) {
            if ((a.extensions.distToEvent != null) &&
                (b.extensions.distToEvent != null)) {
              final num distA = a.extensions.latitude == null
                  ? 99999999
                  : a.extensions.distToEvent;
              final num distB = b.extensions.latitude == null
                  ? 99999999
                  : b.extensions.distToEvent;
              result = distA.compareTo(distB);
            } else {
              result = a.kennel.kennelName.compareTo(b.kennel.kennelName);
            }
          }
        }

        return result;
      });

      debugPrint('[BOOT] filterRuns: sort done: ${DateTime.now().millisecondsSinceEpoch}ms');

      int lastInsertedClassification = 4;

      final int listLength = filteredRuns.length;
      resultCount.value = filteredRuns.length;
      debugPrint('[BOOT] filterRuns: header-insertion loop start: listLength=$listLength: ${DateTime.now().millisecondsSinceEpoch}ms');

      for (int i = listLength - 1; i >= 0; i--) {
        if (filteredRuns[i].extensions.runClassification == 1) {
          showRsvpInstructions = false;
        }

        int currentClassification = 1;
        if (i > 0) {
          currentClassification =
              filteredRuns[i - 1].extensions.runClassification ?? 1;
        }

        if (currentClassification != lastInsertedClassification) {
          for (
            int j = lastInsertedClassification - currentClassification - 1;
            j >= 0;
            j--
          ) {
            filteredRuns.insert(i, currentClassification + j + 1);
          }

          lastInsertedClassification = currentClassification;
        }
      }

      filteredRuns.insert(0, 1);
      debugPrint('[BOOT] filterRuns: header-insertion done: ${DateTime.now().millisecondsSinceEpoch}ms — finalListLength=${filteredRuns.length}');
    } else {
      // filteredRuns.sort((dynamic a, dynamic b) {
      //   int result = _toDateOnly(
      //     b.event.eventStartDatetime,
      //   ).compareTo(_toDateOnly(a.event.eventStartDatetime));
      //   if (result == 0) {
      //     if ((a.extensions.distToEvent != null) &&
      //         (b.extensions.distToEvent != null)) {
      //       final num distA = a.extensions.latitude == null
      //           ? 99999999
      //           : a.extensions.distToEvent;
      //       final num distB = b.extensions.latitude == null
      //           ? 99999999
      //           : b.extensions.distToEvent;
      //       result = distA.compareTo(distB);
      //     } else {
      //       result = a.kennel.kennelName.compareTo(b.kennel.kennelName);
      //     }
      //   }
      //   return result;
      // });
      resultCount.value = filteredRuns.length;
    }

    // Build the inline past section. Apply the SAME chip filters as the future
    // list (Events / Map / My), then search, then sort oldest -> newest so the
    // most recent sits just above the divider.
    if (showsInlinePast) {
      // Drop past runs the user declined / was unsure about (RSVP No/Maybe,
      // unless attended), then apply the active chips.
      final base = (allPastRuns ?? <RunDetailsAggregate>[])
          .where(_keepPastRun)
          .toList();
      final chipFiltered = _applyChipFilters(base);
      final past = QueryRuns.doRunsSearchTextFilter(
        searchRunsText.value,
        chipFiltered,
      ).whereType<RunDetailsAggregate>().toList();
      past.sort(
        (a, b) =>
            a.event.eventStartDatetime.compareTo(b.event.eventStartDatetime),
      );
      pastRuns.value = past;
    } else if (pastRuns.isNotEmpty) {
      pastRuns.clear();
    }

    debugPrint('[BOOT] filterRuns: update(runList) start: ${DateTime.now().millisecondsSinceEpoch}ms');
    update([UpdateIds.runList]);
    debugPrint('[BOOT] filterRuns: COMPLETE: ${DateTime.now().millisecondsSinceEpoch}ms');
  }

  Future<void> clearTables({
    required Database database,
    required TableModel tableModel,
    required List<EnumDataTables> tablesToClear,
    required AppDomainType domain,
  }) async {
    for (final table in tablesToClear) {
      final tableName = table.helperFrom(tableModel).getTableName(domain);

      final query = 'DELETE FROM $tableName';

      try {
        await database.rawQuery(query);
      } catch (e) {
        debugPrint('[FutureRunListPageController.clearTables] error: $e');
      }
    }
  }

  /// Background sync triggered by tab re-focus or app resume.
  /// Shows the banner overlay, syncs events/HEM/payments, diffs the result,
  /// then shows the pill or card flashes as appropriate.
  Future<void> triggerBackgroundSync({bool ignoreDebounce = false}) async {
    if (_isSyncInProgress) return;
    if (!ignoreDebounce && _lastSyncCompleted != null) {
      if (DateTime.now().difference(_lastSyncCompleted!).inSeconds < 60) return;
    }

    _isSyncInProgress = true;
    isSyncing.value = true;

    _previousRuns = {
      for (final r in allRuns ?? <RunDetailsAggregate>[])
        normalizeUuid(r.event.eventId): r,
    };

    try {
      await tableModel.syncUserDataService.updateFromBackend(
        EnumDataTables.hasherEventMap.flag |
            EnumDataTables.payments.flag |
            EnumDataTables.events.flag,
        true,
        debugText: 'background sync',
      );
    } catch (e) {
      debugPrint('[SYNC] triggerBackgroundSync error: $e');
    }

    // Enforce minimum banner display time in parallel with the data load
    final bannerTimer = Future.delayed(const Duration(milliseconds: 800));

    final newAllRuns = await QueryRuns.getRunDetailsAggregates(
      true,
      runsTimeScope: runsTimeScope.value,
      runsToDisplay: runsToDisplay.value,
    );

    await _loadPastRuns();
    _applyDataUpdate(newAllRuns);

    await bannerTimer;
    isSyncing.value = false;

    // Show pill only after banner is gone to avoid overlap
    _checkForNewRunsAboveViewport();

    _lastSyncCompleted = DateTime.now();
    _isSyncInProgress = false;
  }

  void _applyDataUpdate(List<RunDetailsAggregate>? newAllRuns) {
    if (newAllRuns == null) return;

    final changedIds = <String>{};
    for (final run in newAllRuns) {
      final id = normalizeUuid(run.event.eventId);
      final prev = _previousRuns[id];
      if (prev != null && _runHasChanged(prev, run)) {
        changedIds.add(id);
      }
    }

    allRuns = newAllRuns;
    filterRuns(false);

    if (changedIds.isNotEmpty) {
      unawaited(_triggerFlash(changedIds));
    }
  }

  Future<void> _triggerFlash(Set<String> ids) async {
    flashingRunIds.addAll(ids);
    await Future.delayed(const Duration(milliseconds: 450)); // 150ms in + 300ms hold
    flashingRunIds.removeWhere(ids.contains);
  }

  void _checkForNewRunsAboveViewport() {
    final positions = itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) {
      newRunsAboveViewport.value = 0;
      return;
    }

    // Index of the topmost visible item; anything before it is "above viewport".
    final firstVisible = positions
        .map((p) => p.index)
        .reduce((a, b) => a < b ? a : b);
    if (firstVisible <= 0) {
      newRunsAboveViewport.value = 0;
      return;
    }

    final items = displayRuns;
    // Only the future section feeds the "new runs above" pill. The attended-past
    // section above the divider is never "new" (and its baseline isn't tracked
    // in _previousRuns, which holds future runs only), so start counting after
    // the divider. When anchored on the divider this is 0 — the pill only fires
    // once genuinely new upcoming runs land above the user's position.
    final int futureStart = (showsInlinePast && pastRuns.isNotEmpty)
        ? pastRuns.length + 1
        : 0;
    int addedCount = 0;
    for (int i = futureStart; i < firstVisible && i < items.length; i++) {
      final item = items[i];
      if (item is RunDetailsAggregate) {
        final id = normalizeUuid(item.event.eventId);
        if (!_previousRuns.containsKey(id)) addedCount++;
      }
    }

    newRunsAboveViewport.value = addedCount;
  }

  void dismissPill() {
    newRunsAboveViewport.value = 0;
    if (itemScrollController.isAttached) {
      itemScrollController.scrollTo(
        index: initialScrollIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  bool _runHasChanged(RunDetailsAggregate old, RunDetailsAggregate next) {
    // updatedAt is the most reliable indicator; fall back to key visible fields
    final oldUpdated = old.event.updatedAt;
    final newUpdated = next.event.updatedAt;
    if (oldUpdated != null && newUpdated != null) {
      return oldUpdated != newUpdated;
    }
    return old.event.eventName != next.event.eventName ||
        old.event.eventStartDatetime != next.event.eventStartDatetime ||
        old.event.locationOneLineDesc != next.event.locationOneLineDesc ||
        old.event.eventImage != next.event.eventImage;
  }

  Future<void> refreshFromBackend({
    bool clearLocalTables = false,
    bool showOfflineMessage = false,
  }) async {
    // Offline guard. A manual refresh clears the local runs and re-fetches, so
    // running it with no connection would wipe the list and leave it empty (the
    // sync silently fails). Bail BEFORE clearing anything so the existing runs
    // stay put; only surface a message when the user triggered the refresh.
    if (!Utilities.isConnected(
      showDialog: showOfflineMessage,
      title: 'No Connection',
      message:
          "Can't refresh runs — you appear to be offline. Your runs are still "
          "here; pull to refresh again once you're back online.",
    )) {
      return;
    }

    const runTables = [
      EnumDataTables.events,
      EnumDataTables.hasherEventMap,
      EnumDataTables.payments,
    ];
    final int syncFlags = EnumDataTables.hasherEventMap.flag |
        EnumDataTables.payments.flag |
        EnumDataTables.events.flag;

    if (clearLocalTables) {
      // Full reload. Clearing resets each table's high-water mark (it is derived
      // from MAX(updatedAt) of the local rows) so the sync re-fetches the lot —
      // the clear therefore HAS to precede the fetch. To stay crash-safe we
      // snapshot the tables first and roll back if the fetch fails; otherwise a
      // failed fetch would leave the runs list empty.
      if (!await _backupRunTables(runTables)) {
        // Couldn't snapshot — abort rather than risk an unrecoverable clear.
        if (showOfflineMessage) {
          unawaited(
            Utilities.showAlert(
              'Refresh Failed',
              'Could not refresh right now. Please try again.',
              'OK',
            ),
          );
        }
        return;
      }

      allRuns = null;
      await clearTables(
        database: database,
        tableModel: tableModel,
        domain: AppDomainType.user,
        tablesToClear: runTables,
      );

      bool fetchOk;
      try {
        fetchOk = await tableModel.syncUserDataService.updateFromBackend(
          syncFlags,
          true,
          debugText: 'future_run_list_page: full reload (Events, HEM, Payments)',
        );
      } catch (e) {
        debugPrint('[RUNS] refreshFromBackend full reload fetch threw: $e');
        fetchOk = false;
      }

      if (fetchOk) {
        await _dropRunTableBackups(runTables);
      } else {
        // Fetch failed after the clear — roll back so the user keeps their runs.
        await _restoreRunTables(runTables);
        if (showOfflineMessage) {
          unawaited(
            Utilities.showAlert(
              'Refresh Failed',
              "Couldn't reach the server, so your runs are unchanged. "
                  'Pull to refresh to try again.',
              'OK',
            ),
          );
        }
      }
    } else {
      // Non-destructive delta sync (e.g. returning from a run detail page).
      // Upsert-only, so a failure can't empty the list — no snapshot needed.
      await tableModel.syncUserDataService.updateFromBackend(
        syncFlags,
        true,
        debugText: 'future_run_list_page: delta refresh (Events, HEM, Payments)',
      );
    }

    await refreshFromTable(true);
    update([UpdateIds.runList]);
  }

  // Resolve a run table's physical name the same way clearTables does, so the
  // snapshot/restore always targets exactly the tables that get cleared.
  String _runTableName(EnumDataTables t) =>
      t.helperFrom(tableModel).getTableName(AppDomainType.user);

  String _runBackupName(String tableName) => '${tableName}_refresh_bak';

  /// Snapshots the given common-domain tables into side tables so a failed full
  /// reload can be rolled back. Returns false if any snapshot fails (the caller
  /// should then abort the reload rather than risk an unrecoverable clear).
  Future<bool> _backupRunTables(List<EnumDataTables> tables) async {
    try {
      for (final t in tables) {
        final name = _runTableName(t);
        final bak = _runBackupName(name);
        await database.execute('DROP TABLE IF EXISTS $bak');
        await database.execute('CREATE TABLE $bak AS SELECT * FROM $name');
      }
      return true;
    } catch (e) {
      debugPrint('[RUNS] _backupRunTables failed: $e');
      await _dropRunTableBackups(tables); // clean any partial snapshots
      return false;
    }
  }

  /// Restores the given common-domain tables from their snapshots (and drops the
  /// snapshots). Used when a full reload fetch fails after the clear.
  Future<void> _restoreRunTables(List<EnumDataTables> tables) async {
    for (final t in tables) {
      final name = _runTableName(t);
      final bak = _runBackupName(name);
      try {
        await database.execute('DELETE FROM $name');
        await database.execute('INSERT INTO $name SELECT * FROM $bak');
      } catch (e) {
        debugPrint('[RUNS] _restoreRunTables: restore of $name failed: $e');
      }
    }
    await _dropRunTableBackups(tables);
  }

  Future<void> _dropRunTableBackups(List<EnumDataTables> tables) async {
    for (final t in tables) {
      final bak = _runBackupName(_runTableName(t));
      try {
        await database.execute('DROP TABLE IF EXISTS $bak');
      } catch (e) {
        debugPrint('[RUNS] _dropRunTableBackups failed for ${t.name}: $e');
      }
    }
  }
}
