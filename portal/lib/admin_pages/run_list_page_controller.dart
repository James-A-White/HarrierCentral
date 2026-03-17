// ignore_for_file: constant_identifier_names, avoid_web_libraries_in_flutter
import 'package:firebase_messaging/firebase_messaging.dart';
//import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:hcportal/imports.dart';

enum EDisplayRuns { past, future, all }

const int NARROW_SCREEN_WIDTH = 950;

class RunListPageController extends GetxController {
  RunListPageController(
    this.kennel, {
    this.backgroundColor = 'e0e0e0',
    this.textTheme = 'dark',
  }) {
    textThemeIsLight = textTheme.toLowerCase().contains('light');
  }
  final String backgroundColor;
  final String textTheme;
  final HasherKennelsModel kennel;

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

  @override
  void onInit() {
    super.onInit();
    unawaited(onInitAsync());
  }

  Future<void> onInitAsync() async {
    _fcmSubscription =
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final publicEventId = message.data['PublicEventId'] as String?;

      if (publicEventId != null) {
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
        } catch (_) {
          // Debounce error
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
    _worker?.dispose(); // Dispose the worker manually
    super.onClose();
  }

  RxDouble width = 0.0.obs;
  RxDouble height = 0.0.obs;

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

    final accessToken =
        Utilities.generateToken(publicHasherId, 'hcportal_getEvents');

    if (!getAllEventDetails) {
      displayRuns = EDisplayRuns.all;
    } else {
      displayRuns = EDisplayRuns.future;
      weeksToDisplay = 52;
    }

    final body = <String, dynamic>{
      'queryType': 'getEvents',
      'publicHasherId': publicHasherId,
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

    final jsonResult = await ServiceCommon.sendHttpPostToAzureFunctionApi(body);
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
          var rlm = RunListModel.fromJson(
            (jsonItems[0] as List<dynamic>)[i] as Map<String, dynamic>,
          );
          _prepareBadgeCounts(rlm.publicEventId, rlm.eventChatMessageCount);
          rlm = rlm.copyWith(
            searchText: '~ ${rlm.eventName} ${rlm.kennelShortName} ~',
          );
          allEvents.add(rlm);
        }
      }

      setDisplayedEvents();
    }

    isLoaded.value = true;
  }

  void resetBadgeCount(String publicEventId) {
    thisEventChatCount[publicEventId] = 0;
    update(['chatCountBadge']);
  }

  void _prepareBadgeCounts(String? publicEventId, int? eventChatMessageCount) {
    if (publicEventId != null) {
      thisEventChatCount[publicEventId] = eventChatMessageCount ?? 0;

      final chatsCounts =
          (box.get(HIVE_CHATS_COUNT) as Map?)?.cast<String, int>();

      if (chatsCounts != null) {
        thisEventChatCount[publicEventId] = thisEventChatCount[publicEventId]! -
            (chatsCounts[publicEventId] ?? 0);
      }
    }
  }

  Future<void> deleteEvent(String? eventId) async {
    if (eventId != null) {
      final accessToken = Utilities.generateToken(
        publicHasherId,
        'hcportal_deleteEvent',
        paramString: eventId,
      );

      final body = <String, dynamic>{
        'queryType': 'deleteEvent',
        'publicHasherId': publicHasherId,
        'accessToken': accessToken,
        'publicEventId': eventId,
      };

      final jsonResult =
          await ServiceCommon.sendHttpPostToAzureFunctionApi(body);

      if (jsonResult.length > 10) {
        final jsonItems = json.decode(jsonResult) as List<dynamic>;
        final result = ((jsonItems[0] as List<dynamic>)[0]
            as Map<String, dynamic>)['result'] as String;

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
