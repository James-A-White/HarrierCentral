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

  String get publicHasherId => box.get(HIVE_HASHER_ID) as String;

  Worker? _worker;
  bool firstLoad = true;
  bool _isDebounceRunning = false;

  int? messageCount;

  late StreamSubscription<RemoteMessage> _fcmSubscription;
  Map<String, int> thisEventChatCount = {};

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
    _fcmSubscription =
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final publicEventId =
          normalizeUuid(message.data['PublicEventId'] as String?);

      if (publicEventId.isNotEmpty) {
        thisEventChatCount[publicEventId] =
            int.tryParse(message.data['EventChatMessageCount'] as String) ?? 0;

        final chatsCounts =
            (box.get(HIVE_CHATS_COUNT) as Map?)?.cast<String, int>();

        if (chatsCounts != null) {
          thisEventChatCount[publicEventId] =
              thisEventChatCount[publicEventId]! -
                  (chatsCounts[publicEventId] ?? 0);
        }

        //_prepareBadgeCounts(publicEventId,rlm.eventChatMessageCount);

        update(['chatCountBadge']);
      }
    });

    _worker = debounce(
      width,
      (_) async {
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
          if (kDebugMode) debugPrint('RunListPageController debounce error: $e');
        } finally {
          _isDebounceRunning = false;
        }
      },
      time: const Duration(milliseconds: 50),
    );
  }

  @override
  void onClose() {
    unawaited(_fcmSubscription.cancel());
    _worker?.dispose();
    tabController.dispose();
    kennelPickerScrollController
      ..removeListener(_onKennelPickerScroll)
      ..dispose();
    kennelPickerSearchController.dispose();
    super.onClose();
  }

  RxDouble width = 0.0.obs;
  RxDouble height = 0.0.obs;

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

  Future<void> _getEvents({bool getAllEventDetails = false, int? weeks}) async {
    isLoaded.value = false;

    var weeksToDisplay = weeks ?? 9999;

    final deviceId = box.get(HIVE_DEVICE_ID) as String;
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
    final accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_getEvents',
      paramString: deviceSecret,
    );

    if (!getAllEventDetails) {
      displayRuns = EDisplayRuns.all;
    } else {
      displayRuns = EDisplayRuns.future;
      weeksToDisplay = 52;
    }

    final body = <String, dynamic>{
      'queryType': 'getEvents',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'publicKennelIds': kennel.publicKennelId,
      'fullDetails': getAllEventDetails ? 1 : 0,
      'weeksToDisplay': weeksToDisplay,
      'pastOrFuture': displayRuns == EDisplayRuns.future
          ? 'future'
          : displayRuns == EDisplayRuns.past
              ? 'past'
              : 'all',
    };

    final jsonResult = await ServiceCommon.sendHttpPostToHC6Api(body);
    debugPrint(jsonResult.startsWith(ERROR_PREFIX)
        ? 'SP 10 [getEvents] called — FAILED'
        : 'SP 10 [getEvents] called — success');
    eventForSingleEventDetailsView = EventDetailsResult.empty().obs;
    displayedEvents.clear();
    allEvents.clear();
    allEventsDetails.clear();

    if (jsonResult.length > 10) {
      if (getAllEventDetails) {
        final jsonItems = json.decode(jsonResult) as List<dynamic>;
        for (var i = 0; i < (jsonItems[0] as List<dynamic>).length; i++) {
          final eventDetails = EventDetailsResult(
            runDetails: RunDetailsModel.fromJson(
              (jsonItems[0] as List<dynamic>)[i] as Map<String, dynamic>,
            ),
            participants: [],
          );

          final publicEventId = eventDetails.runDetails.publicEventId;

          _prepareBadgeCounts(
            publicEventId,
            eventDetails.runDetails.eventChatMessageCount,
          );

          allEventsDetails.add(eventDetails);
        }
      } else {
        final jsonItems = json.decode(jsonResult) as List<dynamic>;
        for (var i = 0; i < (jsonItems[0] as List<dynamic>).length; i++) {
          final map =
              (jsonItems[0] as List<dynamic>)[i] as Map<String, dynamic>;
          map['eventChatMessageCount'] ??= 0; // removed in HC6 (was hardcoded 0)
          var rlm = RunListModel.fromJson(map);
          _prepareBadgeCounts(rlm.publicEventId, rlm.eventChatMessageCount);
          rlm = rlm.copyWith(
            searchText: '~ ${rlm.eventName} ${rlm.kennelShortName} ~',
          );
          allEvents.add(rlm);
        }
      }

      setDisplayedEvents();

      if (!getAllEventDetails) {
        // If there are no future events, fall back to the most recent past run.
        if (displayedEvents.isEmpty && allEvents.isNotEmpty) {
          displayRuns = EDisplayRuns.past;
          tabController.animateTo(1);
          setDisplayedEvents();
        }

        // Auto-select the first displayed event so the detail panel is populated.
        if (displayedEvents.isNotEmpty) {
          eventForSingleEventDetailsView.value =
              await querySingleEvent(displayedEvents.first.publicEventId);
        }
      }
    }

    isLoaded.value = true;
  }

  void resetBadgeCount(String publicEventId) {
    publicEventId = normalizeUuid(publicEventId);
    thisEventChatCount[publicEventId] = 0;
    update(['chatCountBadge']);
  }

  void _prepareBadgeCounts(String? publicEventId, int? eventChatMessageCount) {
    if (publicEventId == null) return;
    thisEventChatCount[publicEventId.asUuid] = eventChatMessageCount ?? 0;

    final chatsCounts =
        (box.get(HIVE_CHATS_COUNT) as Map?)?.cast<String, int>();

    if (chatsCounts != null) {
      thisEventChatCount[publicEventId.asUuid] =
          thisEventChatCount[publicEventId.asUuid]! -
              (chatsCounts[publicEventId.asUuid] ?? 0);
    }
  }

  Future<void> deleteEvent(String? eventId) async {
    if (eventId != null) {
      final deviceId = box.get(HIVE_DEVICE_ID) as String;
      final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
      final accessToken = Utilities.generateToken(
        deviceId,
        'hcportal_deleteEvent',
        paramString: deviceSecret,
      );

      final body = <String, dynamic>{
        'queryType': 'deleteEvent',
        'deviceId': deviceId,
        'accessToken': accessToken,
        'publicEventId': eventId,
      };

      final jsonResult = await ServiceCommon.sendHttpPostToHC6Api(body);
      debugPrint(jsonResult.startsWith(ERROR_PREFIX)
          ? 'SP 5 [deleteEvent] called — FAILED'
          : 'SP 5 [deleteEvent] called — success');

      if (!jsonResult.startsWith(ERROR_PREFIX)) {
        final jsonItems = json.decode(jsonResult) as List<dynamic>;
        final result = ((jsonItems[0] as List<dynamic>)[0]
            as Map<String, dynamic>)['Result'] as String;

        await CoreUtilities.showAlert(
          'Delete result',
          result,
          'OK',
        );

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
          doRunsFilter(searchRunsText, allEventsDetails)
              .where((EventDetailsResult element) {
            // converge the "all" and "future" cases for display purposes
            if ((displayRuns != EDisplayRuns.past) &&
                (element.runDetails.eventStartDatetime
                    .isAfter(getTodayAsDateOnly()))) {
              return true;
            } else if ((displayRuns == EDisplayRuns.past) &&
                (element.runDetails.eventStartDatetime
                    .isBefore(getTodayAsDateOnly()))) {
              return true;
            }
            return false;
          }) as Iterable<EventDetailsResult>,
        )
        ..sort(
          (EventDetailsResult a, EventDetailsResult b) =>
              (a.runDetails.eventStartDatetime)
                  .compareTo(b.runDetails.eventStartDatetime),
        );
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
        }) as Iterable<RunListModel>,
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
      dynamic filteredRuns =
          (isNarrowScreen.value) ? <EventDetailsResult>[] : <RunListModel>[];

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
    selectedKennelId.value = newKennel.publicKennelId;
    displayRuns = EDisplayRuns.future;
    tabController.animateTo(0);
    update(['appBar']);
    firstLoad = true;
    await refreshEvents();
  }

  Future<void> refreshEvents() async {
    isNarrowScreen.value = Get.mediaQuery.size.width < NARROW_SCREEN_WIDTH;
    await _getEvents(
      getAllEventDetails: isNarrowScreen.value ||
          displayType.toLowerCase() == RUN_DISPLAY_TYPE_DETAIL_ONLY,
    );

    if (isNarrowScreen.value) {
      displayRuns = EDisplayRuns.future;
    }
  }
}
