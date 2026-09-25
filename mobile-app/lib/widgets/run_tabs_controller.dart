// ignore_for_file: constant_identifier_names

import 'package:harrier_central/imports.dart';
import 'package:latlong2/latlong.dart' as latlng;

class PackListAggregate {
  PackListAggregate({
    required this.hem,
    required this.hasher,
    required this.displayName,
    this.homeKennelName,
  });

  final HasherEventMapModel hem;
  final HashersModel hasher;
  final String displayName;
  final String? homeKennelName;
}

/// State for the run detail's six tabs: the tab controllers, the RSVP pack
/// list and counts, the RSVP write, the live-run button, the map centre and
/// north lock, and the logo strip that slides away on the RSVP and Chat tabs.
///
/// Migrated from a 3000-line State on 2026-09-23. The pack list used to be a
/// FUTURE held in a field behind a FutureBuilder; it is an RxList assigned in
/// one step now. The two TabControllers, the scroll controller and the map
/// preference notifier are owned here (GetTickerProviderStateMixin) and
/// disposed in onClose, which also clears the event-domain tables as the
/// State's dispose did.
class RunTabsController extends GetxController
    with GetTickerProviderStateMixin {
  RunTabsController({
    required this.futureRun,
    required this.relayActiveTab,
    required this.openToTab,
    String? mapTag,
  }) : mapTag = mapTag ?? futureRun.event.eventId;

  final RunDetailsAggregate futureRun;
  final Function relayActiveTab;
  final RunTab openToTab;

  /// Tag of THIS page's embedded map controller. Route-scoped by RunTabs
  /// (see routeScopedTag) so two pages for one run never share a
  /// MapController; defaults to the event id where no page supplies one.
  final String mapTag;

  static String tagFor(String eventId) => 'runtabs-$eventId';

  static const String LABEL_DETAILS = 'Details';
  static const String LABEL_MAP = 'Map';
  static const String LABEL_RSVP = 'RSVP';
  static const String LABEL_STATS = 'Stats';
  static const String LABEL_CHAT = 'Chat';
  static const String LABEL_PHOTOS = 'Photos';

  /// Six tabs share the width. On a 360 dp phone the selected label (bold,
  /// so wider) was clipped inside its pill: "Detai", "Photo" (2026-09-25).
  /// Each label shrinks only when it cannot fit, so larger phones, where
  /// every label fits, are unchanged.
  static const List<Tab> tabs = <Tab>[
    Tab(child: _FitLabel(LABEL_DETAILS)),
    Tab(child: _FitLabel(LABEL_RSVP)),
    Tab(child: _FitLabel(LABEL_MAP)),
    Tab(child: _FitLabel(LABEL_STATS)),
    Tab(child: _FitLabel(LABEL_CHAT)),
    Tab(child: _FitLabel(LABEL_PHOTOS)),
  ];

  static int DISPLAY_LOGO_IN_RSVP_DURATION = 15;

  String get _eventId => futureRun.event.eventId;

  final LiveRunService liveRunService = LiveRunService.ensure();
  final Rx<LiveRunButtonStatus> liveRunStatus = LiveRunButtonStatus.hidden.obs;
  final RxBool liveRunLoading = false.obs;

  final ScrollController scrollController = ScrollController();
  final ValueNotifier<bool> saveUserMapPreference = ValueNotifier<bool>(false);

  late final bool isAdmin;
  final String userId = currentUserId;

  /// Not reactive on purpose: the map reports every pan through mapMoved,
  /// and a rebuild per pan would redraw the whole page. The recentre buttons
  /// call update().
  latlng.LatLng mapCenter = latlng.LatLng(
    deviceInfo.deviceLat ?? DEFAULT_LATITUDE,
    deviceInfo.deviceLon ?? DEFAULT_LONGITUDE,
  );

  final RxBool trueNorthLock = true.obs;
  final RxBool isExportingTrack = false.obs;

  /// False until the RSVP tab has loaded once; the tab shows a spinner.
  final RxBool packListLoaded = false.obs;
  final RxList<PackListAggregate> packList = <PackListAggregate>[].obs;
  final RxMap<String, dynamic> packCount = <String, dynamic>{}.obs;
  final RxInt thisUserIndex = (-1).obs;
  final Rx<EnumRsvpState> rsvpRequested = rsvpUnknown.obs;

  late final TabController tabController;
  late final TabController gridListTabController;
  final RxInt tabIndex = 0.obs;
  final RxInt gridListIndex = 0.obs;

  final RxBool showTopWidget = true.obs;
  final RxBool slideTopWidget = false.obs;
  final RxBool fabIsVisible = false.obs;

  @override
  void onInit() {
    super.onInit();
    isAdmin = AppAccess(futureRun.extensions.appAccessFlags).isAdmin;
    unawaited(refreshLiveRunButton());

    tabController = TabController(
      vsync: this,
      length: tabs.length,
      // Opens on the chat tab when a notification was tapped.
      initialIndex: openToTab.id,
    );
    tabIndex.value = openToTab.id;
    tabController.addListener(_onTab);
    gridListTabController = TabController(vsync: this, length: 2);
    gridListTabController.addListener(
      () => gridListIndex.value = gridListTabController.index,
    );
    // The listener above fires on CHANGES; a page opened straight onto the
    // RSVP tab still needs its load.
    if (openToTab == RunTab.rsvp) unawaited(_onTabSettled());

    final List<double?> coords = Utilities.getLatLongFromString(<String?>[
      futureRun.event.locationOneLineDesc,
      futureRun.event.eventDescription,
      futureRun.event.eventName,
    ]);
    final double xLat =
        futureRun.extensions.evtLat ??
        coords[0] ??
        futureRun.kennel.kennelLatitude ??
        deviceInfo.deviceLon ??
        DEFAULT_LATITUDE;
    final double xLon =
        futureRun.extensions.evtLon ??
        coords[1] ??
        futureRun.kennel.kennelLongitude ??
        deviceInfo.deviceLon ??
        DEFAULT_LONGITUDE;
    mapCenter = latlng.LatLng(xLat, xLon);
    saveUserMapPreference.addListener(update);
  }

  @override
  void onClose() {
    tabController.removeListener(_onTab);
    tabController.dispose();
    gridListTabController.dispose();
    saveUserMapPreference.removeListener(update);
    saveUserMapPreference.dispose();
    scrollController.dispose();
    unawaited(_clearEventTables());
    unawaited(Get.delete<ChatPageController>());
    super.onClose();
  }

  void _onTab() {
    tabIndex.value = tabController.index;
    unawaited(_onTabSettled());
  }

  /// Moves an already-open run page to [tab]. A RunTabs instance is bound to
  /// its controller by event id, so a second open of the same run — a tapped
  /// RSVP or chat notification while that run's page is already in the stack
  /// — reuses this controller, and onInit's initialIndex never runs again.
  /// The old State animated to its tab on every instance; this is that.
  void showTab(RunTab tab) {
    if (isClosed || tabController.index == tab.id) return;
    tabController.animateTo(tab.id);
    tabIndex.value = tab.id;
    unawaited(_onTabSettled());
  }

  Future<void> _onTabSettled() async {
    FocusManager.instance.primaryFocus?.unfocus();
    // By POSITION, never by label text. This read `tabs[i].text` until
    // 28b89472 (2026-09-25) gave the tabs a `child:` so the labels could
    // shrink on a small phone — `.text` became null for every tab, and the
    // RSVP tab spun forever (its load never ran), its speed dial never showed
    // and the chat tab's header never faded. No error, just a spinner.
    final RunTab tab = RunTab.fromId(tabController.index);

    // The speed dial IS the RSVP actions ("I'm coming" / "I might come" /
    // "I'm not coming"), so it goes on a past run too — otherwise hiding
    // the three buttons would just move the same dead choice into a
    // floating button.
    fabIsVisible.value = tab == RunTab.rsvp && !isRunPast(futureRun);

    if (tab == RunTab.rsvp) {
      await refreshHemTableFromBackend(false);
      if (isClosed) return;
      showTopWidget.value = true;
      slideTopWidget.value = false;
      await Future.delayed(Duration(seconds: DISPLAY_LOGO_IN_RSVP_DURATION));
      if (isClosed) return;
      showTopWidget.value = false;
    }
    if (tab == RunTab.chat) {
      showTopWidget.value = true;
      slideTopWidget.value = false;
      unawaited(
        Future.delayed(Duration(seconds: DISPLAY_LOGO_IN_RSVP_DURATION)).then((
          _,
        ) {
          if (isClosed) return;
          showTopWidget.value = false;
        }),
      );
    }

    if ((tabController.previousIndex == RunTab.chat.id) ||
        (tabController.index == RunTab.chat.id)) {
      if (Get.isRegistered<NotificationService>()) {
        await Get.find<NotificationService>().markEventMessagesAsViewed(
          futureRun.event.publicEventId,
        );
      }
    }
    if (isClosed) return;
    relayActiveTab(tabController.index);
  }

  /// The logo strip has faded out; collapse its space.
  void onTopWidgetFaded() => slideTopWidget.value = true;

  Future<void> _clearEventTables() async {
    for (final table in EnumDataTables.values.where((t) => t.hasEventTable)) {
      final helper = table.helperFrom(tableModel);
      await tableModel.baseService.clearTable(
        database,
        helper,
        table.eventTableName,
      );
    }
    await setStringPref(StringPrefsEnum.adminEventId, '');
  }

  Future<void> refreshHemTableFromBackend(bool showLoadingIndicator) async {
    if (isAdmin) {
      await tableModel.syncEventAdminService.updateFromBackend(
        EnumDataTables.hasherEventMap.flag,
        true,
        _eventId,
      );
    } else {
      await tableModel.syncEventAdminService.updateRsvpsFromBackend(_eventId);
    }
    if (isClosed) return;
    final List<PackListAggregate> next = await _refreshPackListFromTable();
    if (isClosed) return;
    packList.assignAll(next);
    packListLoaded.value = true;
    await _refreshPackCountFromTable();
  }

  Future<List<PackListAggregate>> _refreshPackListFromTable() async {
    final List<PackListAggregate> pla = <PackListAggregate>[];

    final String query =
        '''
        SELECT
          hem.*,
          h.*,
          ken.${tableModel.kennelsTableHelper.colKennelName} as kennelName
          FROM ${EnumDataTables.hasherEventMap.eventTableName} hem
          LEFT OUTER JOIN ${EnumDataTables.hashers.commonTableName} h on h.${tableModel.hashersTableHelper.colHasherId} = hem.${tableModel.hasherEventMapTableHelper.colUserId}
          LEFT OUTER JOIN ${EnumDataTables.kennels.commonTableName} ken on h.${tableModel.hashersTableHelper.colHomeKennelId} = ken.${tableModel.kennelsTableHelper.colKennelId}
          WHERE hem.${tableModel.hasherEventMapTableHelper.colEventId} = "$_eventId"
          AND hem.${tableModel.hasherEventMapTableHelper.colRsvpState} >= 1 AND hem.${tableModel.hasherEventMapTableHelper.colRsvpState} <= 3
          ''';

    try {
      final List<Map<String, dynamic>> results = await database.rawQuery(query);
      int missingHasherRecords = 0;

      for (int i = 0; i < results.length; i++) {
        final HasherEventMapModel packItem = tableModel
            .hasherEventMapTableHelper
            .fromMap(results[i]);

        // The hashers join is a LEFT OUTER: a HEM row can name someone this
        // device has no hasher record for — a virgin/visitor who was never
        // given one, or somebody created since the last sync. Every h.* column
        // is NULL then, and the generated fromJson throws on the first
        // non-nullable cast (hasherId), which took the ENTIRE pack list down
        // rather than one row. Seen five times over the GNH 2026 weekend.
        final bool hasHasherRecord = results[i]['hasherId'] != null;
        if (!hasHasherRecord) missingHasherRecords++;
        final HashersModel hasherItem = hasHasherRecord
            ? HashersModel.fromJson(results[i])
            // Keep the real user id: several unknown hashers must not collapse
            // onto one another (HashersModel.empty() is all-GUID_EMPTY).
            : HashersModel.empty().copyWith(hasherId: packItem.userId);

        String displayName = hasHasherRecord
            ? hasherItem.dispName
            : (packItem.displayName ?? 'Unknown hasher');
        if (packItem.virginVisitorType != 0) {
          displayName = packItem.displayName ?? 'Virgin / Visitor';
        }

        pla.add(
          PackListAggregate(
            hem: packItem,
            hasher: hasherItem,
            displayName: displayName,
            homeKennelName: results[i]['kennelName'] as String?,
          ),
        );
      }

      // Not fatal any more, but still a sync gap worth seeing: the pack list
      // is naming people this device holds no hasher row for.
      if (missingHasherRecords > 0) {
        BootLogger.logBreadcrumb(
          'RunTabs: pack list has $missingHasherRecords of ${results.length} '
          'attendees with no local hasher record '
          '(eventId=$_eventId)',
        );
      }
    } catch (e, s) {
      BootLogger.logError(
        '[RunTabs._refreshPackListFromTable] eventId=$_eventId',
        e,
        s,
      );
    }

    pla.sort(
      (PackListAggregate a, PackListAggregate b) =>
          (a.hem.hemKennelHashName ?? a.displayName).compareTo(
            b.hem.hemKennelHashName ?? b.displayName,
          ),
    );

    thisUserIndex.value = pla.indexWhere((p) => p.hasher.hasherId == userId);
    return pla;
  }

  Future<void> _refreshPackCountFromTable() async {
    final String query =
        '''
        SELECT
          count(case when hem.rsvpState = 3 then 1 else null end) as rsvpYesCount,
          count(case when hem.rsvpState = 2 then 1 else null end) as rsvpMaybeCount,
          count(case when hem.rsvpState = 1 then 1 else null end) as rsvpNoCount,
          count(case when hem.isHare = 1 then 1 else null end) as isHareCount
          FROM ${EnumDataTables.hasherEventMap.eventTableName} hem
          WHERE hem.eventId = "$_eventId"
          AND hem.${tableModel.hasherEventMapTableHelper.colRsvpState} >= 1 AND hem.${tableModel.hasherEventMapTableHelper.colRsvpState} <= 3
          ''';

    try {
      final List<Map<String, dynamic>> results = await database.rawQuery(query);
      if (isClosed) return;
      packCount.assignAll(
        results.isNotEmpty ? results[0] : <String, dynamic>{},
      );
    } catch (e, s) {
      BootLogger.logError(
        '[RunTabs._refreshPackCountFromTable] eventId=$_eventId',
        e,
        s,
      );
    }
  }

  Future<void> setRsvpState(EnumRsvpState rsvpState) async {
    // Optimistic: this user's row goes blue while the server answers.
    final int i = thisUserIndex.value;
    if (packListLoaded.value && i >= 0 && i < packList.length) {
      final PackListAggregate a = packList[i];
      packList[i] = PackListAggregate(
        hasher: a.hasher,
        displayName: a.displayName,
        hem: a.hem.copyWith(rsvpState: -1, isHare: 0),
      );
    }
    rsvpRequested.value = rsvpState;

    final List<dynamic> adHocData = await tableModel.hasherEventMapService
        .setEventRsvp(_eventId, userId, AppDomainType.user, rsvpState.value);
    if (isClosed) return;

    await refreshHemTableFromBackend(false);
    if (kDebugMode) {
      debugPrint(
        '[_setRsvpState] adHocData length: ${adHocData.length}, contents: $adHocData',
      );
    }
    // An error envelope or a sync-only reply carries no adHocData row
    // (RangeError seen 2026-09-05 on 3.0.12).
    final String serverMessage = firstRow(adHocData)?['serverMessage'] ?? '';
    if (serverMessage.isNotEmpty) {
      await Utilities.showAlert('RSVP Result', serverMessage, 'OK');
    }
  }

  /// The run's own RSVP / paid state changed on the Details tab.
  void onPaymentProcessed(int rsvpState, int paid) {
    futureRun.extensions = futureRun.extensions.copyWith(
      rsvpState: rsvpState,
      isPaid: paid != -1 ? paid : futureRun.extensions.isPaid,
    );
    update();
  }

  void toggleTrueNorthLock() => trueNorthLock.value = !trueNorthLock.value;

  void recenterMapOnEvent() {
    mapCenter = latlng.LatLng(
      futureRun.extensions.evtLat ??
          futureRun.kennel.kennelLatitude ??
          DEFAULT_LATITUDE,
      futureRun.extensions.evtLon ??
          futureRun.kennel.kennelLongitude ??
          DEFAULT_LONGITUDE,
    );
    update();
  }

  void recenterMapOnDevice() {
    if ((deviceInfo.deviceLat != null) && (deviceInfo.deviceLon != null)) {
      mapCenter = latlng.LatLng(deviceInfo.deviceLat!, deviceInfo.deviceLon!);
    }
    update();
  }

  /// The run-detail map creates its controller BELOW the tabs, so this
  /// resolves it lazily at tap time rather than while the column builds.
  void recenterMapOnUser() {
    if (!Get.isRegistered<RunTrackerMapController>(tag: mapTag)) return;
    Get.find<RunTrackerMapController>(tag: mapTag).recenterOnUser();
  }

  /// The admin trim editor for THIS embedded map. Its own controller,
  /// targeting the embedded map's controller ([mapTag]), so it and the
  /// full-screen route's editor never fight over one MapController.
  PackTrackTrimController trimController() {
    final String trimTag = 'trim-$mapTag';
    return Get.isRegistered<PackTrackTrimController>(tag: trimTag)
        ? Get.find<PackTrackTrimController>(tag: trimTag)
        : Get.put(
            PackTrackTrimController(run: futureRun, mapControllerTag: mapTag),
            tag: trimTag,
          );
  }

  RunTrackerMapController? get mapControllerOrNull =>
      Get.isRegistered<RunTrackerMapController>(tag: mapTag)
      ? Get.find<RunTrackerMapController>(tag: mapTag)
      : null;

  UserTrack? currentUserTrack(RunTrackerMapController controller) {
    final String? id = getStringPref(StringPrefsEnum.userId);
    if (id == null || id.isEmpty) return null;
    for (final track in controller.userPositions) {
      if (track.id == id && RunTrackerMapController.hasTrack(track)) {
        return track;
      }
    }
    return null;
  }

  void startLiveRun() {
    liveRunService.startRun(
      eventId: _eventId,
      eventName: futureRun.event.eventName,
    );
    liveRunStatus.value = LiveRunButtonStatus.active;
  }

  Future<void> refreshLiveRunButton() async {
    liveRunLoading.value = true;
    try {
      final now = DateTime.now();
      final eventStart = futureRun.event.eventStartDatetime;
      final windowStart = eventStart.subtract(const Duration(minutes: 30));
      final windowEnd = eventStart.add(const Duration(hours: 6));
      final String? activeId = liveRunService.activeRunEventId.value;

      if (activeId != null) {
        liveRunStatus.value = activeId == _eventId
            ? LiveRunButtonStatus.active
            : LiveRunButtonStatus.hidden;
        return;
      }
      if (now.isBefore(windowStart) || now.isAfter(windowEnd)) {
        liveRunStatus.value = LiveRunButtonStatus.hidden;
        return;
      }
      final bool isCheckedIn =
          futureRun.extensions.attendenceState >= attendenceAtHash.value;
      final bool hasRsvpYes = futureRun.extensions.rsvpState == rsvpYes.value;
      if (isCheckedIn) {
        liveRunStatus.value = LiveRunButtonStatus.eligible;
        return;
      }
      // Being AT the start qualifies on its own — see the matching comment in
      // RunListItemController.refreshLiveRunButton. An RSVP'd hasher keeps the
      // old, laxer test; anyone else has to actually be here.
      final results = await CommonQueries.isAtRunStart(
        eventId: _eventId,
        requireProximity: !hasRsvpYes,
      );
      if (isClosed) return;
      final bool atStart = results.any((item) => item.eventId == _eventId);
      liveRunStatus.value = atStart
          ? LiveRunButtonStatus.eligible
          : LiveRunButtonStatus.hidden;
    } catch (e, s) {
      debugPrint('Live run button check failed: $e');
      BootLogger.logError(
        '[RunTabs._checkLiveRunStatus] eventId=$_eventId',
        e,
        s,
      );
      if (!isClosed) liveRunStatus.value = LiveRunButtonStatus.hidden;
    } finally {
      if (!isClosed) liveRunLoading.value = false;
    }
  }
}

/// The published Hash Trash for a run, on the Details tab.
class HashTrashViewController extends GetxController {
  HashTrashViewController({required this.kennelId, required this.eventId});

  final String kennelId;
  final String eventId;

  static String tagFor(String eventId) => 'hashtrash-$eventId';

  final Rxn<HashTrashModel> model = Rxn<HashTrashModel>();
  final RxBool loaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    if (!Utilities.isConnected()) return;
    try {
      final HashTrashModel? m = await RunContentService().getHashTrash(
        kennelId: kennelId,
        eventId: eventId,
      );
      if (isClosed) return;
      model.value = m;
    } catch (e, s) {
      BootLogger.logError('[ERROR][RUN]', 'tab load failed: $e', s);
    }
    if (!isClosed) loaded.value = true;
  }
}

/// Completed charges on the Details tab: while the run is upcoming or under
/// way, only the done ones; once it is past, every charge that was not
/// cancelled (the server draws that line, six hours after the start).
class DownDownsHistoryController extends GetxController {
  DownDownsHistoryController({required this.kennelId, required this.eventId});

  final String kennelId;
  final String eventId;

  static String tagFor(String eventId) => 'ddhistory-$eventId';

  final RxList<DownDownModel> charges = <DownDownModel>[].obs;
  final RxBool loaded = false.obs;
  final RxBool canManage = false.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    if (!Utilities.isConnected()) return;
    try {
      final kennelAgg = await QueryKennels.getSingleKennel(kennelId);
      if (isClosed) return;
      canManage.value = canAccessFeature(
        KennelFeature.manageDownDowns,
        appAccessFlags: kennelAgg?.hkm?.appAccessFlags ?? 0,
        mismanagementRoles: kennelAgg?.hkm?.mismanagementRoles ?? 0,
        kennelOverrideJson: kennelAgg?.kennel.permissionOverrideJson,
      );
      final result = await RunContentService().getCompletedDownDowns(
        kennelId: kennelId,
        eventId: eventId,
      );
      if (isClosed) return;
      if (result != null) {
        charges.assignAll(DownDownsController.withHashers(result));
      }
    } catch (e, s) {
      BootLogger.logError('[ERROR][RUN]', 'tab load failed: $e', s);
    }
    if (!isClosed) loaded.value = true;
  }
}

/// A tab label that scales down to fit its tab, and never up.
class _FitLabel extends StatelessWidget {
  const _FitLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(label, maxLines: 1, softWrap: false),
  );
}
