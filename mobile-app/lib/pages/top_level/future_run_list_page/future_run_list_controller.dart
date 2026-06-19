import 'package:harrier_central/imports.dart';

class FutureRunListPageController extends GetxController {
  FutureRunListPageController();

  StreamSubscription<DataChangeEvent>? _dataChangeSub;

  RxDouble width = 0.0.obs;
  RxDouble height = 0.0.obs;

  int pageIndex = 1;
  List<RunDetailsAggregate>? allRuns;
  RxList<RunDetailsAggregate> preFilteredRuns = <RunDetailsAggregate>[].obs;
  RxList<dynamic> filteredRuns = [].obs;
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

  final ScrollController scrollController = ScrollController(
    initialScrollOffset: 0.0,
  );

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
    scrollController.dispose();
    searchController.dispose();
    searchFocusNode.dispose();
    flashingRunIds.clear();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();

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
      unawaited(refreshFromTable(true));
    }
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
    runsToDisplay.value = RunsToDisplay.onMap;
    runsTimeScope.value = RunsTimeScope.all;
    await refreshFromTable(true);
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
      debugPrint('[BOOT] refreshFromTable: calling filterRuns: ${DateTime.now().millisecondsSinceEpoch}ms');
      filterRuns(false);
      debugPrint('[BOOT] refreshFromTable: filterRuns done: ${DateTime.now().millisecondsSinceEpoch}ms — filteredRuns=${filteredRuns.length}');
    }
    return;
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

    // if we are only changing the search text, then we don't need to
    // re-filter the runs by time scope and runs to display
    if (!searchTextChanged) {
      Map<String, RxInt> unseenChats = {};

      if (Get.isRegistered<NotificationService>()) {
        final controller = Get.find<NotificationService>();
        unseenChats = controller.unreadEventCounts;
      }

      debugPrint('[BOOT] filterRuns: doRunsFilter start: ${DateTime.now().millisecondsSinceEpoch}ms');
      preFilteredRuns.value = QueryRuns.doRunsFilter(
        allRuns ?? <RunDetailsAggregate>[],
        runsToDisplay.value,
        runsTimeScope.value,
        mapBounds: mapBounds,
        unseenChats: unseenChats,
        dateRangeStart: dateFilterStart.value,
        dateRangeEnd: dateFilterEnd.value,
        useDatesForAllYears: multiYearDateFilter.value,
      );
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
    if (!scrollController.hasClients || scrollController.offset <= 0) {
      newRunsAboveViewport.value = 0;
      return;
    }

    final addedCount = filteredRuns.where((item) {
      if (item is int) return false;
      final id = normalizeUuid((item as RunDetailsAggregate).event.eventId);
      return !_previousRuns.containsKey(id);
    }).length;

    newRunsAboveViewport.value = addedCount;
  }

  void dismissPill() {
    newRunsAboveViewport.value = 0;
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
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

  Future<void> refreshFromBackend({bool clearLocalTables = false}) async {
    if (clearLocalTables) {
      allRuns = null;

      await clearTables(
        database: database,
        tableModel: tableModel,
        domain: AppDomainType.user,
        tablesToClear: [
          EnumDataTables.hasherEventMap,
          EnumDataTables.payments,
          EnumDataTables.events,
        ],
      );
    }

    await tableModel.syncUserDataService.updateFromBackend(
      EnumDataTables.hasherEventMap.flag |
          EnumDataTables.payments.flag |
          EnumDataTables.events.flag,
      true,
      debugText: 'future_run_list_page: HEM, Events, Kennels',
    );

    await refreshFromTable(true);
    update([UpdateIds.runList]);

    //final String resultStr = result ? 'successfully' : 'unsuccessfully';
    //print('Events user data synchronized $resultStr');
  }
}
