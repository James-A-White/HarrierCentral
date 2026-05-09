import 'package:harrier_central/imports.dart';

class FutureRunListPageController extends GetxController {
  FutureRunListPageController();

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

  @override
  void onInit() {
    super.onInit();

    // showOnlyEventsWithMessages.listen((bool value) async {
    //   showChatBubbleLoading.value = true;
    //   update(['main_nav_page']);
    //   Future<void>.delayed(const Duration(seconds: 1)).then((value) {
    //     showChatBubbleLoading.value = false;
    //     update(['main_nav_page']);
    //   });

    //   // for some reason,we need to put this little delay in otherwise the
    //   // update to the main_nav_page does not get fired before the filterRuns
    //   // starts executing.
    //   await Future<void>.delayed(const Duration(milliseconds: 100));
    //   filterRuns(false);
    // });

    // 👇 Debounce: waits 400ms after last change before calling filterRuns
    debounce<String>(
      searchRunsText,
      (_) => filterRuns(true),
      time: const Duration(milliseconds: 1000),
    );

    debounce<bool>(
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

    debounce<bool>(
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
    searchController.text = '';
    searchRunsText.value = '';

    // do an immediate refresh from table to quickly display data already cached in the app
    refreshFromTable(true).then((_) {
      // then do any updates that require a trip to the server.
      _onInitAsync().then((_) {
        // _updateTotalNotificationCounter();
        update(['runList', 'main_nav_page']);
      });
    });
  }

  void refreshRunListUi() {
    filterRuns(false);
    update(['runList', 'main_nav_page']);
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

  //   update(['runList', 'chatTab', 'main_nav_page']);
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

  //   update(['runList', 'chatTab', 'main_nav_page']);
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

  Future<void> _onInitAsync() async {
    appModel.hasLocationPermissions = await Permission.location.isGranted;

    //await refreshFromBackend();
    //await refreshFromTable(true);
    //chatSummaryMap = await getEventChatMessageCounts();

    if (Firebase.apps.isEmpty) {
      await Get.putAsync(() => NotificationService().init());
    }

    if (Firebase.apps.isNotEmpty) {
      final msg = await FirebaseMessaging.instance.getInitialMessage();
      if (msg != null) {
        await _processMessage(msg.data);
      }
    }
  }

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
          .where((dynamic a) => a.event?.eventId?.toUpperCase() == eventId)
          .toList();

      if ((runs != null) && (runs.length > 0)) {
        var run = runs[0];

        RunTab? openToTab;

        switch (messageType) {
          case MessageType.chat:
            openToTab = RunTab.chat;
            break;
          case MessageType.checkinReminder:
            await Utilities.checkAreWeAtRunStart(eventId: eventId);
            break;
          case MessageType.rsvpReminder:
            openToTab = RunTab.rsvp;
            break;
        }

        if (openToTab != null) {
          openRun(run, openToTab: openToTab);
        }
      }
    }
  }

  void openList() {
    final controller = Get.find<MainNavigationController>();
    controller.bottomNavigationKey.currentState?.setPage(0);
    runsToDisplay.value = RunsToDisplay.onMap;
    runsTimeScope.value = RunsTimeScope.all;
    refreshFromTable(true);
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

    update(['runList', 'chatTab', 'main_nav_page']);

    //setState(() {});

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

    //     setState(() {});
    //   });
    // });
  }

  DateTime _toDateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  Future<void> refreshFromTable(bool forceRefresh) async {
    if (forceRefresh || (allRuns == null) || (allRuns!.isEmpty)) {
      allRuns = await QueryRuns.getRunDetailsAggregates(
        true,
        runsTimeScope: runsTimeScope.value,
        runsToDisplay: runsToDisplay.value,
      );
      filterRuns(false);
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
    showRsvpInstructions = true;

    // if we are only changing the search text, then we don't need to
    // re-filter the runs by time scope and runs to display
    if (!searchTextChanged) {
      Map<String, RxInt> unseenChats = {};

      if (Get.isRegistered<NotificationService>()) {
        final controller = Get.find<NotificationService>();
        unseenChats = controller.unreadEventCounts;
      }

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
    }

    filteredRuns.value = QueryRuns.doRunsSearchTextFilter(
      searchRunsText.value,
      preFilteredRuns,
    );

    if (runsTimeScope.value == RunsTimeScope.future) {
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

      int lastInsertedClassification = 4;

      final int listLength = filteredRuns.length;
      resultCount.value = filteredRuns.length;

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

    update(['runList']);
  }

  Future<void> refreshFromBackend({bool clearLocalTables = false}) async {
    if (clearLocalTables) {
      allRuns = null;
      update(['runList']);

      String query =
          'DELETE FROM ${tableModel.hasherEventMapTableHelper.getTableName(AppDomainType.user)}';
      try {
        await database.rawQuery(query);
      } catch (e) {
        //print(e);
      }

      query =
          'DELETE FROM ${tableModel.paymentsTableHelper.getTableName(AppDomainType.user)}';
      try {
        await database.rawQuery(query);
      } catch (e) {
        //print(e);
      }

      query =
          'DELETE FROM ${tableModel.eventsTableHelper.getTableName(AppDomainType.user)}';
      try {
        await database.rawQuery(query);
      } catch (e) {
        //print(e);
      }
    }

    await tableModel.syncUserDataService.updateFromBackend(
      SyncUserDataService.flagsAllData,
      true,
      debugText: 'future_run_list_page: HEM, Events, Kennels',
    );

    await refreshFromTable(true);
    //final String resultStr = result ? 'successfully' : 'unsuccessfully';
    //print('Events user data synchronized $resultStr');
  }
}
