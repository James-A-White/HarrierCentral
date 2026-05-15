import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

enum FilterEventsPageType { past, future }

class FilterEventsController extends GetxController {
  FilterEventsController({
    required this.kennel,
    required this.pageType,
  });

  final KennelListAggregate kennel;
  final FilterEventsPageType pageType;

  // ---------------------------------------------------------------------------
  // Reactive state
  // ---------------------------------------------------------------------------

  final RxBool isLoading = true.obs;
  final RxList<LiteEventModel> allEvents = <LiteEventModel>[].obs;
  final RxList<LiteEventModel> selectedEvents = <LiteEventModel>[].obs;
  final Rx<DateTime> focusedDay = DateTime.now().obs;
  final Rx<DateTime> selectedDay = DateTime.now().obs;

  /// The date currently being updated (calendar loading indicator).
  /// Set to [_dateTimeUnassigned] when no update is in progress.
  final Rx<DateTime> dateBeingUpdated = _dateTimeUnassigned.obs;

  /// Backing store for calendar event lookup by date (not observable directly —
  /// mutations trigger [allEvents] refresh which rebuilds anything watching it).
  final Map<DateTime, List<LiteEventModel>> calendarEvents =
      <DateTime, List<LiteEventModel>>{};

  List<Map<String, dynamic>> publishedRunCountSqlResult =
      <Map<String, dynamic>>[];

  /// ID of the list item currently being updated (for inline spinner).
  final RxString itemBeingUpdatedId = ''.obs;

  static final DateTime _dateTimeUnassigned = DateTime(1900);

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    unawaited(
      _refreshSqlTablesFromBackend(true).then((void _) {
        _refreshList(
          selectedDay: focusedDay.value,
          focusedDay: focusedDay.value,
        );
        unawaited(
          Future<void>.delayed(const Duration(milliseconds: 500)).then(
            (void _) {
              // Force calendar button repaint after data arrives.
              allEvents.refresh();
            },
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Data helpers
  // ---------------------------------------------------------------------------

  DateTime toDateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool get isDateBeingUpdated =>
      dateBeingUpdated.value != _dateTimeUnassigned;

  bool isDateCurrentlyUpdating(DateTime date) =>
      toDateOnly(dateBeingUpdated.value) == toDateOnly(date) &&
      dateBeingUpdated.value != _dateTimeUnassigned;

  // ---------------------------------------------------------------------------
  // Async data methods
  // ---------------------------------------------------------------------------

  Future<void> _refreshSqlTablesFromBackend(bool showLoadingIndicator) async {
    if (showLoadingIndicator) {
      isLoading.value = true;
    }

    await tableModel.syncUserDataService.updateFromBackend(
      EnumDataTables.events.flag,
      true,
      debugText: 'filter_events_page: Events',
    );

    await _refreshEventFromTables(true);

    if (showLoadingIndicator) {
      isLoading.value = false;
    }
  }

  Future<void> _refreshEventFromTables(bool forceRefresh) async {
    final String sortOrder =
        pageType == FilterEventsPageType.future ? 'ASC' : 'DESC';
    final String dateComparer =
        pageType == FilterEventsPageType.future ? '>=' : '<=';

    final String userId = getStringPref(StringPrefsEnum.userId)!;
    final offsetFromGmtToLocal = Utilities.getSqfliteTimeOffset();

    try {
      final String sql = '''
          SELECT COUNT(*) as publishedRunCount
          FROM ${EnumDataTables.events.commonTableName} evt
          WHERE kennelId = "${kennel.kennel.kennelId}" AND isVisible = 1
          AND date(datetime(evt.eventStartDatetime)) $dateComparer date(datetime('now','$offsetFromGmtToLocal'))
          ''';
      publishedRunCountSqlResult = await database.rawQuery(sql);
    } catch (e) {
      // swallow
    }

    try {
      final String sql = '''
          SELECT
            evt.${tableModel.eventsTableHelper.colEventId},
            evt.${tableModel.eventsTableHelper.colIsVisible},
            evt.${tableModel.eventsTableHelper.colIsCountedRun},
            evt.${tableModel.eventsTableHelper.colAbsoluteEventNumber},
            evt.${tableModel.eventsTableHelper.colEventFacebookId},
            evt.${tableModel.eventsTableHelper.colEventName},
            evt.${tableModel.eventsTableHelper.colEventNumber},
            evt.${tableModel.eventsTableHelper.colEventStartDatetime},
            evt.${tableModel.eventsTableHelper.colEventInboundIntegrationId},
            hkm.${tableModel.hasherKennelMapTableHelper.colAppAccessFlags},
            evt.${tableModel.eventsTableHelper.colCanEditRunAttendence}
          FROM ${EnumDataTables.events.commonTableName} evt
          INNER JOIN ${EnumDataTables.hasherKennelMap.commonTableName} hkm on hkm.${tableModel.hasherKennelMapTableHelper.colKennelId} = "${kennel.kennel.kennelId}" and hkm.${tableModel.hasherKennelMapTableHelper.colUserId} = "$userId"
          WHERE evt.${tableModel.eventsTableHelper.colKennelId} = "${kennel.kennel.kennelId}"
          AND date(datetime(evt.${tableModel.eventsTableHelper.colEventStartDatetime})) $dateComparer date(datetime('now','$offsetFromGmtToLocal'))
          ORDER BY evt.${tableModel.eventsTableHelper.colEventStartDatetime} $sortOrder, evt.${tableModel.eventsTableHelper.colEventNumber} $sortOrder
          ''';

      final List<Map<String, dynamic>> allEventsSqlResult =
          await database.rawQuery(sql);

      calendarEvents.clear();
      allEvents.clear();
      selectedEvents.clear();

      for (int i = 0; i < allEventsSqlResult.length; i++) {
        final LiteEventModel event =
            LiteEventModel.fromJson(allEventsSqlResult[i]);
        allEvents.add(event);
        final DateTime eventDate =
            toDateOnly(event.eventStartDatetime);
        if (calendarEvents[eventDate] == null) {
          calendarEvents[eventDate] = <LiteEventModel>[];
        }
        calendarEvents[eventDate]!.add(event);
      }

      isLoading.value = false;
    } catch (e) {
      // swallow
    }
  }

  Future<void> handleRefresh() async {
    isLoading.value = true;
    await tableModel.syncUserDataService.updateFromBackend(
      EnumDataTables.events.flag,
      true,
      debugText: 'filter_events_page: Events',
    );
    await _refreshEventFromTables(true);
    isLoading.value = false;
  }

  void refreshList({DateTime? selectedDay, DateTime? focusedDay}) {
    _refreshList(selectedDay: selectedDay, focusedDay: focusedDay);
  }

  void _refreshList({DateTime? selectedDay, DateTime? focusedDay}) {
    if (selectedDay != null) {
      this.selectedDay.value = selectedDay;
    }
    if (focusedDay != null) {
      this.focusedDay.value = focusedDay;
    }
    selectedEvents.value =
        calendarEvents[toDateOnly(this.selectedDay.value)] ??
        <LiteEventModel>[];
  }

  void onDaySelected(DateTime newSelectedDay, DateTime newFocusedDay) {
    if (!isSameDay(selectedDay.value, newSelectedDay)) {
      _refreshList(
        selectedDay: newSelectedDay,
        focusedDay: newFocusedDay,
      );
    }
  }

  Future<void> updateEvent({
    required String eventId,
    bool? isVisible,
    bool? isCountedRun,
    int? asboluteEventNumber,
    String? kennelId,
  }) async {
    await database.transaction<dynamic>((Transaction txn) async {
      final int flag =
          isVisible ?? isCountedRun ?? (asboluteEventNumber != null) ? -3 : -2;
      final String sql =
          'UPDATE ${EnumDataTables.events.commonTableName} SET canEditRunAttendence = "$flag" where eventId = "$eventId"';
      await txn.rawUpdate(sql);
    });

    final EventsService nSvc = EventsService();
    await nSvc.addEditEvent(
      eventId: eventId,
      kennelId: kennelId,
      isVisible: isVisible,
      isCountedRun: isCountedRun,
      absoluteEventNumber: asboluteEventNumber,
    );
    await _refreshEventFromTables(true);
    _refreshList();
  }

  Future<void> showEventPopup(
    DateTime eventStartDate,
    BuildContext context,
  ) async {
    final String title =
        'Create new event on ${DateFormat('E, MMM d').format(eventStartDate)}';

    final CreateNewEventPopup newEventPopup = CreateNewEventPopup(title);

    final Map<String, String>? x = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return newEventPopup;
      },
    );

    final String eventName = x?['eventName'] ?? '';
    final String type = x?['type'] ?? 'cancel';

    if (type != 'cancel') {
      dateBeingUpdated.value = eventStartDate;

      final EventsService nSvc = EventsService();
      await nSvc.addEditEvent(
        kennelId: kennel.kennel.kennelId,
        isVisible: true,
        isCountedRun: type == eventFilterType_countEvent.value.toString()
            ? true
            : false,
        eventName: eventName,
        eventStartDatetime: toDateOnly(eventStartDate),
      );

      await _refreshEventFromTables(true);
      dateBeingUpdated.value = _dateTimeUnassigned;
      _refreshList();
    }
  }

  Future<void> setRunNumber(
    LiteEventModel event,
    BuildContext context,
  ) async {
    final RunNumberPopup newEventPopup = RunNumberPopup(
      runNumber: event.absoluteEventNumber,
    );

    final Map<String, String>? x = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return newEventPopup;
      },
    );

    final String runNumber =
        x?['runNumber'] ??
        event.absoluteEventNumber?.toString() ??
        event.eventNumber.toString();

    if (runNumber != 'cancel') {
      int rn = -1;
      if (runNumber == 'auto') {
        rn = 0;
      } else {
        rn = int.parse(runNumber);
      }

      await updateEvent(eventId: event.eventId, asboluteEventNumber: rn);
    }
  }

  Future<void> refreshSqlTablesFromBackend(bool showLoadingIndicator) async {
    await _refreshSqlTablesFromBackend(showLoadingIndicator);
  }

  Future<void> refreshEventFromTables(bool forceRefresh) async {
    await _refreshEventFromTables(forceRefresh);
  }
}
