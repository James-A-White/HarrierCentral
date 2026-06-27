// ignore_for_file: constant_identifier_names, avoid_web_libraries_in_flutter
import 'package:firebase_messaging/firebase_messaging.dart';
//import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hcportal/imports.dart';

enum EDisplayRuns { past, future, all }

const int NARROW_SCREEN_WIDTH = 950;

class RunListPageController extends GetxController
    with GetSingleTickerProviderStateMixin {
  RunListPageController(
    this.kennel, {
    this.backgroundColor = 'e0e0e0',
    this.textTheme = 'dark',
  }) {
    textThemeIsLight = textTheme.toLowerCase().contains('light');
    selectedKennelId = kennel.publicKennelId.asUuid.obs;
  }
  final String backgroundColor;
  final String textTheme;
  HasherKennelsModel kennel;

  late Rx<String> selectedKennelId;
  late TabController tabController;

  bool textThemeIsLight = true;
  String displayType = RUN_DISPLAY_TYPE_LIST_AND_DETAIL;
  String searchRunsText = '';

  Rx<EventDetailsResult> eventForSingleEventDetailsView =
      EventDetailsResult.empty().obs;

  final RxList<RunListModel> displayedEvents = <RunListModel>[].obs;
  final List<RunListModel> allEvents = <RunListModel>[];
  final List<EventDetailsResult> allEventsDetails = <EventDetailsResult>[];
  final RxList<EventDetailsResult> displayedEventsDetails =
      <EventDetailsResult>[].obs;

  RxBool isNarrowScreen = false.obs;

  RxBool isLoaded = false.obs;

  EDisplayRuns displayRuns = EDisplayRuns.future;

  // Lazy loading of past runs on the narrow (phone) layout. The phone fetches a
  // bounded window of past runs (1 year at a time) — fetching all history was
  // far too slow — and expands it as the user scrolls to the bottom of the
  // Past list. `_pastWeeksWindow` is how far back we currently fetch; each
  // "load more" adds another year. `hasMorePast` goes false once a wider fetch
  // returns nothing new.
  static const int _pastWeeksInitial = 17; // ~4 months on first load
  static const int _pastWeeksIncrement = 17; // load ~4 more months each time
  int _pastWeeksWindow = _pastWeeksInitial;
  final RxBool isLoadingMorePast = false.obs;
  bool hasMorePast = true;

  String get publicHasherId => box.get(HIVE_HASHER_ID) as String;
  bool get canViewMonitor =>
      (box.get(HIVE_PLATFORM_ADMIN_CAN_VIEW_MONITOR) as bool?) ?? false;
  bool get canManageNewsflash =>
      (box.get(HIVE_PLATFORM_ADMIN_CAN_MANAGE_NEWSFLASH) as bool?) ?? false;
  bool get canEditKennel =>
      (box.get(HIVE_PLATFORM_ADMIN_CAN_EDIT_KENNEL) as bool?) ?? false;
  bool get hasAnyPlatformAdminPrivilege =>
      canViewMonitor || canManageNewsflash || canEditKennel;

  Worker? _worker;
  bool firstLoad = true;
  bool _isDebounceRunning = false;
  bool _newsflashShown = false;

  int? messageCount;

  late StreamSubscription<RemoteMessage> _fcmSubscription;
  Map<String, int> thisEventChatCount = {};

  final FocusNode searchFocusNode = FocusNode();
  final TextEditingController searchController = TextEditingController();

  final ScrollController kennelPickerScrollController = ScrollController();
  final RxBool kennelPickerHasOverflow = false.obs;
  final RxBool kennelPickerAtStart = true.obs;
  final RxBool kennelPickerAtEnd = false.obs;
  final RxString kennelPickerSearch = ''.obs;
  final TextEditingController kennelPickerSearchController =
      TextEditingController();

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    kennelPickerScrollController.addListener(_onKennelPickerScroll);
    unawaited(onInitAsync());
  }

  Future<void> onInitAsync() async {
    _subscribeRunListFcm();

    _worker = debounce(width, (_) async {
      if (_isDebounceRunning) return;
      _isDebounceRunning = true;
      try {
        final narrow = Get.mediaQuery.size.width < NARROW_SCREEN_WIDTH;
        if (firstLoad || (isNarrowScreen.value != narrow)) {
          await _getEvents(getAllEventDetails: narrow);
          firstLoad = false;
        }
        isNarrowScreen.value = narrow;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('RunListPageController debounce error: $e');
        }
      } finally {
        _isDebounceRunning = false;
      }
    }, time: const Duration(milliseconds: 50));
  }

  @override
  void onClose() {
    unawaited(_fcmSubscription.cancel());
    _worker?.dispose();
    tabController.dispose();
    searchFocusNode.dispose();
    searchController.dispose();
    kennelPickerScrollController
      ..removeListener(_onKennelPickerScroll)
      ..dispose();
    kennelPickerSearchController.dispose();
    super.onClose();
  }

  RxDouble width = 0.0.obs;
  RxDouble height = 0.0.obs;

  void _subscribeRunListFcm() {
    _fcmSubscription = FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        try {
          final publicEventId = normalizeUuid(
            message.data['PublicEventId']?.toString(),
          );
          if (publicEventId.isEmpty) return;

          final type = message.data['Type']?.toString();
          if (type == 'read_sync') {
            thisEventChatCount[publicEventId] = 0;
          } else {
            thisEventChatCount[publicEventId] =
                (thisEventChatCount[publicEventId] ?? 0) + 1;
          }
          update(['chatCountBadge']);
        } catch (e) {
          if (kDebugMode) debugPrint('[RunListPageController] onMessage error: $e');
        }
      },
      onError: (Object e, StackTrace st) {
        if (kDebugMode) debugPrint('[RunListPageController] FCM stream error: $e');
      },
      onDone: _subscribeRunListFcm,
      cancelOnError: false,
    );
  }

  void _onKennelPickerScroll() {
    if (!kennelPickerScrollController.hasClients) return;
    final pos = kennelPickerScrollController.position;
    kennelPickerHasOverflow.value = pos.maxScrollExtent > 0;
    kennelPickerAtStart.value = pos.pixels <= 0;
    kennelPickerAtEnd.value = pos.pixels >= pos.maxScrollExtent - 0.5;
  }

  void updateKennelPickerOverflow(ScrollMetrics metrics) {
    kennelPickerHasOverflow.value = metrics.maxScrollExtent > 0;
    kennelPickerAtStart.value = metrics.pixels <= 0;
    kennelPickerAtEnd.value = metrics.pixels >= metrics.maxScrollExtent - 0.5;
  }

  // Each kennel item is ~104 px wide (76 logo + 20 padding + 8 gap).
  // Scroll by 5 items at a time.
  static const double _kennelPickerItemWidth = 104.0;
  static const int _kennelPickerScrollItems = 5;

  void scrollKennelPickerLeft() {
    if (!kennelPickerScrollController.hasClients) return;
    unawaited(
      kennelPickerScrollController.animateTo(
        (kennelPickerScrollController.offset -
                _kennelPickerItemWidth * _kennelPickerScrollItems)
            .clamp(0.0, kennelPickerScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }

  void scrollKennelPickerRight() {
    if (!kennelPickerScrollController.hasClients) return;
    unawaited(
      kennelPickerScrollController.animateTo(
        (kennelPickerScrollController.offset +
                _kennelPickerItemWidth * _kennelPickerScrollItems)
            .clamp(0.0, kennelPickerScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }

  void filterKennelPicker(String text) {
    kennelPickerSearch.value = text;
  }

  bool kennelMatchesSearch(HasherKennelsModel k, String lowerSearch) {
    return k.kennelName.toLowerCase().contains(lowerSearch) ||
        k.kennelShortName.toLowerCase().contains(lowerSearch) ||
        k.kennelUniqueShortName.toLowerCase().contains(lowerSearch) ||
        k.countryName.toLowerCase().contains(lowerSearch) ||
        (k.cityName?.toLowerCase().contains(lowerSearch) ?? false) ||
        (k.regionName?.toLowerCase().contains(lowerSearch) ?? false) ||
        (k.continentName?.toLowerCase().contains(lowerSearch) ?? false);
  }

  void updateSizeWithDebounce(double newWidth, double newHeight) {
    if (width.value != newWidth) {
      width.value = newWidth;
    }
    if (height.value != newHeight) {
      height.value = newHeight;
    }
  }

  /// True when the runs UI shows the full-detail card list (phone, or the
  /// detail-only display config) rather than the wide list+panel layout.
  bool get _detailMode =>
      isNarrowScreen.value ||
      displayType.toLowerCase() == RUN_DISPLAY_TYPE_DETAIL_ONLY;

  /// Lazy-load the next 4 months of older past runs (detail/phone layout).
  /// Triggered when the user scrolls near the bottom of the Past list. Widens
  /// the past window and re-fetches just the past set (keeping all future
  /// runs), without the full-screen loader.
  Future<void> loadMorePastRuns() async {
    if (!_detailMode ||
        isLoadingMorePast.value ||
        !hasMorePast ||
        displayRuns != EDisplayRuns.past) {
      return;
    }
    isLoadingMorePast.value = true;
    _pastWeeksWindow += _pastWeeksIncrement;
    final past = await _fetchDetailEvents('past', _pastWeeksWindow);
    final before =
        allEventsDetails.where((e) => _isPast(e.runDetails)).length;
    // Replace the past portion (the wider window is a superset), keep future.
    allEventsDetails
      ..removeWhere((e) => _isPast(e.runDetails))
      ..addAll(past);
    _dedupeDetails();
    // Nothing newer than what we already had → we've hit the start of history.
    if (past.length <= before) hasMorePast = false;
    setDisplayedEvents();
    isLoadingMorePast.value = false;
  }

  bool _isPast(RunDetailsModel rd) =>
      rd.eventStartDatetime.isBefore(getTodayAsDateOnly());

  void _dedupeDetails() {
    final seen = <String>{};
    allEventsDetails.retainWhere(
      (e) => seen.add(normalizeUuid(e.runDetails.publicEventId)),
    );
  }

  /// Detail-layout loader: fetches ALL future runs plus a bounded window of
  /// recent past runs (4 months by default). Fetching all history at once was
  /// far too slow on the phone, so older past runs are lazy-loaded on scroll
  /// (see [loadMorePastRuns]). Two calls are needed because the SP's window is
  /// symmetric — a single 'all' call can't combine all-future with a short past.
  Future<void> _loadDetailEvents() async {
    isLoaded.value = false;
    _pastWeeksWindow = _pastWeeksInitial;
    hasMorePast = true;

    eventForSingleEventDetailsView = EventDetailsResult.empty().obs;
    displayedEvents.clear();
    allEvents.clear();

    final future = await _fetchDetailEvents('future', 999);
    final past = await _fetchDetailEvents('past', _pastWeeksWindow);

    allEventsDetails
      ..clear()
      ..addAll(future)
      ..addAll(past);
    _dedupeDetails();

    displayRuns = EDisplayRuns.future;
    setDisplayedEvents();

    // If there are no upcoming runs, land on the most recent past runs instead
    // of an empty screen.
    if (displayedEventsDetails.isEmpty && allEventsDetails.isNotEmpty) {
      displayRuns = EDisplayRuns.past;
      tabController.animateTo(1);
      setDisplayedEvents();
    }

    isLoaded.value = true;
    await _maybeShowNewsflashes();
  }

  /// One detail (fullDetails=1) fetch for a direction ('future'/'past') and a
  /// week window. Returns the parsed events; does not mutate shared state apart
  /// from badge-count bookkeeping.
  Future<List<EventDetailsResult>> _fetchDetailEvents(
    String pastOrFuture,
    int weeks,
  ) async {
    final deviceId = box.get(HIVE_DEVICE_ID) as String;
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
    final accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_getEvents',
      paramString: deviceSecret,
    );

    final body = <String, dynamic>{
      'queryType': 'getEvents',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'publicKennelIds': kennel.publicKennelId,
      'fullDetails': 1,
      'weeksToDisplay': weeks,
      'pastOrFuture': pastOrFuture,
    };

    final apiResult = await ServiceCommon.sendHttpPostToHC6Api(body);
    if (kDebugMode) debugPrint(apiResult is ApiError
        ? 'SP 10 [getEvents:$pastOrFuture] called — FAILED'
        : 'SP 10 [getEvents:$pastOrFuture] called — success');

    final out = <EventDetailsResult>[];
    if (apiResult case ApiSuccess(body: final jsonResult)) {
      final jsonItems = json.decode(jsonResult) as List<dynamic>;
      for (final raw in jsonItems[0] as List<dynamic>) {
        final ed = EventDetailsResult(
          runDetails: RunDetailsModel.fromJson(raw as Map<String, dynamic>),
          participants: [],
        );
        _prepareBadgeCounts(
          ed.runDetails.publicEventId,
          ed.runDetails.eventChatMessageCount,
        );
        out.add(ed);
      }
    }
    return out;
  }

  Future<void> _maybeShowNewsflashes() async {
    if (_newsflashShown) return;
    _newsflashShown = true;
    final pending = await queryPendingNewsflashes();
    if (pending.isNotEmpty) {
      await showPendingNewsflashes(pending);
    }
  }

  /// Ensures the lightweight summary list (`allEvents`, all history) is loaded.
  /// The detail/phone layout only fills `allEventsDetails` for a recent window,
  /// leaving `allEvents` empty — which the location lookup depends on. Called
  /// on demand when the lookup opens so it has the full set of past locations.
  Future<void> ensureSummaryEventsLoaded() async {
    if (allEvents.isNotEmpty) return;

    final deviceId = box.get(HIVE_DEVICE_ID) as String;
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
    final accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_getEvents',
      paramString: deviceSecret,
    );

    final body = <String, dynamic>{
      'queryType': 'getEvents',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'publicKennelIds': kennel.publicKennelId,
      'fullDetails': 0,
      'weeksToDisplay': 9999,
      'pastOrFuture': 'all',
    };

    final apiResult = await ServiceCommon.sendHttpPostToHC6Api(body);
    if (apiResult case ApiSuccess(body: final jsonResult)) {
      final jsonItems = json.decode(jsonResult) as List<dynamic>;
      for (final raw in jsonItems[0] as List<dynamic>) {
        final map = raw as Map<String, dynamic>;
        map['eventChatMessageCount'] ??= 0;
        allEvents.add(RunListModel.fromJson(map));
      }
    }
  }

  Future<void> _getEvents({bool getAllEventDetails = false, int? weeks}) async {
    // The detail/phone layout uses its own loader (all future + paged past).
    if (getAllEventDetails) {
      await _loadDetailEvents();
      return;
    }

    isLoaded.value = false;

    final deviceId = box.get(HIVE_DEVICE_ID) as String;
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
    final accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_getEvents',
      paramString: deviceSecret,
    );

    // Wide layout pulls all history as light list rows and filters locally.
    displayRuns = EDisplayRuns.all;
    final weeksToDisplay = weeks ?? 9999;

    final body = <String, dynamic>{
      'queryType': 'getEvents',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'publicKennelIds': kennel.publicKennelId,
      'fullDetails': 0,
      'weeksToDisplay': weeksToDisplay,
      'pastOrFuture': 'all',
    };

    final apiResult = await ServiceCommon.sendHttpPostToHC6Api(body);
    if (kDebugMode) debugPrint(apiResult is ApiError
        ? 'SP 10 [getEvents] called — FAILED'
        : 'SP 10 [getEvents] called — success');
    eventForSingleEventDetailsView = EventDetailsResult.empty().obs;
    displayedEvents.clear();
    allEvents.clear();
    allEventsDetails.clear();

    if (apiResult case ApiSuccess(body: final jsonResult)) {
      final jsonItems = json.decode(jsonResult) as List<dynamic>;
      for (var i = 0; i < (jsonItems[0] as List<dynamic>).length; i++) {
        final map = (jsonItems[0] as List<dynamic>)[i] as Map<String, dynamic>;
        map['eventChatMessageCount'] ??= 0; // removed in HC6 (was hardcoded 0)
        final rlm = RunListModel.fromJson(map);
        _prepareBadgeCounts(rlm.publicEventId, rlm.eventChatMessageCount);
        allEvents.add(rlm);
      }

      setDisplayedEvents();

      // If there are no future events, fall back to past runs so the user
      // isn't left with an empty screen.
      if (displayedEvents.isEmpty && allEvents.isNotEmpty) {
        displayRuns = EDisplayRuns.past;
        tabController.animateTo(1);
        setDisplayedEvents();
      }

      // Auto-select the first displayed event so the detail panel populates.
      if (displayedEvents.isNotEmpty) {
        eventForSingleEventDetailsView.value = await querySingleEvent(
          displayedEvents.first.publicEventId,
        );
      }
    }

    isLoaded.value = true;
    await _maybeShowNewsflashes();
  }

  void resetBadgeCount(String publicEventId) {
    publicEventId = normalizeUuid(publicEventId);
    thisEventChatCount[publicEventId] = 0;
    update(['chatCountBadge']);
  }

  void _prepareBadgeCounts(String? publicEventId, int? eventChatMessageCount) {
    if (publicEventId == null) return;
    final total = eventChatMessageCount ?? 0;
    final chatsCounts = (box.get(HIVE_CHATS_COUNT) as Map?)
        ?.cast<String, int>();
    final seen = chatsCounts?[publicEventId.asUuid] ?? 0;
    thisEventChatCount[publicEventId.asUuid] = total - seen;
  }

  Future<void> deleteEvent(String? eventId) async {
    if (eventId != null) {
      final deviceId = box.get(HIVE_DEVICE_ID) as String;
      final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
      final accessToken = Utilities.generateToken(
        deviceId,
        'hcportal_deleteEvent',
        paramString: '$deviceSecret:$eventId',
      );

      final body = <String, dynamic>{
        'queryType': 'deleteEvent',
        'deviceId': deviceId,
        'accessToken': accessToken,
        'publicEventId': eventId,
      };

      final apiResult = await ServiceCommon.sendHttpPostToHC6Api(body);
      if (kDebugMode) debugPrint(apiResult is ApiError
          ? 'SP 5 [deleteEvent] called — FAILED'
          : 'SP 5 [deleteEvent] called — success');

      if (apiResult case ApiSuccess(:final body)) {
        final jsonItems = json.decode(body) as List<dynamic>;
        final result =
            ((jsonItems[0] as List<dynamic>)[0]
                    as Map<String, dynamic>)['Result']
                as String;

        await CoreUtilities.showAlert('Delete result', result, 'OK');

        eventForSingleEventDetailsView = EventDetailsResult.empty().obs;

        await refreshEvents();
      }
    }
  }

  DateTime getTodayAsDateOnly() {
    final dt = DateTime.now();
    return DateTime(dt.year, dt.month, dt.day);
  }

  //NOTE: Refactor to get rid of dynamic
  void setDisplayedEvents() {
    displayedEvents.clear();
    displayedEventsDetails.clear();

    if (isNarrowScreen.value) {
      // for narrow screens do the following
      displayedEventsDetails
        ..addAll(
          // ignore: avoid_dynamic_calls
          doRunsFilter(searchRunsText, allEventsDetails).where((
                EventDetailsResult element,
              ) {
                // converge the "all" and "future" cases for display purposes
                if ((displayRuns != EDisplayRuns.past) &&
                    (element.runDetails.eventStartDatetime.isAfter(
                      getTodayAsDateOnly(),
                    ))) {
                  return true;
                } else if ((displayRuns == EDisplayRuns.past) &&
                    (element.runDetails.eventStartDatetime.isBefore(
                      getTodayAsDateOnly(),
                    ))) {
                  return true;
                }
                return false;
              })
              as Iterable<EventDetailsResult>,
        )
        ..sort((EventDetailsResult a, EventDetailsResult b) {
          // Future: soonest first (ascending). Past: most recent first
          // (descending) so lazy-loaded older runs append at the bottom.
          final da = a.runDetails.eventStartDatetime;
          final db = b.runDetails.eventStartDatetime;
          return displayRuns == EDisplayRuns.past
              ? db.compareTo(da)
              : da.compareTo(db);
        });
    } else {
      displayedEvents.addAll(
        // ignore: avoid_dynamic_calls
        doRunsFilter(searchRunsText, allEvents).where((RunListModel element) {
              // converge the "all" and "future" cases for display purposes
              if ((displayRuns != EDisplayRuns.past) &&
                  (element.eventStartDatetime.isAfter(getTodayAsDateOnly()))) {
                return true;
              } else if ((displayRuns == EDisplayRuns.past) &&
                  (element.eventStartDatetime.isBefore(getTodayAsDateOnly()))) {
                return true;
              }
              return false;
            })
            as Iterable<RunListModel>,
      );

      if (displayRuns != EDisplayRuns.past) {
        displayedEvents.sort(
          (RunListModel a, RunListModel b) =>
              (a.eventStartDatetime).compareTo(b.eventStartDatetime),
        );
      } else {
        displayedEvents.sort(
          (RunListModel b, RunListModel a) =>
              (a.eventStartDatetime).compareTo(b.eventStartDatetime),
        );
      }
    }

    // converge the "all" and "future" cases for display purposes
  }

  dynamic doRunsFilter(String searchRunsText, dynamic allRuns) {
    if (searchRunsText.isEmpty) {
      return allRuns;
    } else {
      dynamic filteredRuns = (isNarrowScreen.value)
          ? <EventDetailsResult>[]
          : <RunListModel>[];

      // allow for comma separated search lists that act to narrow search results (i.e. logical AND)
      if (searchRunsText.isEmpty) {
        // ignore: avoid_dynamic_calls
        filteredRuns.addAll(allRuns);
      } else {
        final searchItems = searchRunsText.trim().toLowerCase().split(',');
        for (var st in searchItems) {
          if (st.trim().isEmpty) {
            continue;
          }
          var negate = false;
          if (st.trim().toLowerCase().startsWith('not ')) {
            negate = true;
            st = st.substring(4);
          }
          final orItems = st.split('+');

          // ignore: avoid_dynamic_calls
          filteredRuns = allRuns.where((dynamic a) {
            for (var orItem in orItems) {
              if (orItem.trim().isEmpty) {
                continue;
              }
              orItem = ' ${orItem.trim().toLowerCase()}';
              // ignore: avoid_dynamic_calls
              if (a.searchText.toLowerCase().contains(orItem) as bool) {
                return !negate;
              }
            }
            return negate;
          }).toList();
        }
      }

      return filteredRuns;
    }
  }

  Future<void> switchKennel(HasherKennelsModel newKennel) async {
    kennel = newKennel;
    selectedKennelId.value = newKennel.publicKennelId.asUuid;
    displayRuns = EDisplayRuns.future;
    tabController.animateTo(0);
    update(['appBar']);
    firstLoad = true;
    await refreshEvents();
  }

  Future<void> refreshEvents() async {
    isNarrowScreen.value = Get.mediaQuery.size.width < NARROW_SCREEN_WIDTH;
    await _getEvents(
      getAllEventDetails:
          isNarrowScreen.value ||
          displayType.toLowerCase() == RUN_DISPLAY_TYPE_DETAIL_ONLY,
    );

    if (isNarrowScreen.value) {
      displayRuns = EDisplayRuns.future;
    }
  }
}
