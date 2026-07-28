import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';

enum EnumSortKennelListBy {
  distance,
  kennelName,
  cityName,
  countryRegionName,
  following,
}

class KennelsListPageController extends GetxController {
  final RxList<KennelListAggregate> filteredList = <KennelListAggregate>[].obs;
  final Rx<EnumSortKennelListBy> sortByType =
      EnumSortKennelListBy.following.obs;
  final RxBool isLoading = false.obs;
  final RxString searchText = ''.obs;

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  final ScrollController scrollController = ScrollController(
    initialScrollOffset: 0,
  );

  StreamSubscription<DataChangeEvent>? _dataChangeSub;
  Worker? _searchWorker;

  @override
  void onInit() {
    super.onInit();
    searchController.text = '';
    _searchWorker = debounce<String>(
      searchText,
      (_) => _filterResults(),
      time: const Duration(milliseconds: 400),
    );
    _dataChangeSub = Get.find<DataChangeService>().stream.listen(_onDataChange);
    unawaited(onInitAsync());
  }

  Future<void> onInitAsync() async {
    await refreshFromTable(false);
  }

  @override
  void onClose() {
    _searchWorker?.dispose();
    searchController.dispose();
    searchFocusNode.dispose();
    scrollController.dispose();
    _dataChangeSub?.cancel();
    super.onClose();
  }

  void _onDataChange(DataChangeEvent event) {
    if (event.type == DataChangeType.kennelFollowStatusChanged) {
      _filterResults();
    } else if (event.type == DataChangeType.fullSyncCompleted) {
      unawaited(refreshFromTable(true));
    }
  }

  Future<void> refreshFromTable(bool forceRefresh) async {
    if (forceRefresh ||
        (tableModel.globalKennelMainPageList == null) ||
        (tableModel.globalKennelMainPageList!.isEmpty)) {
      if (tableModel.globalKennelMainPageList != null) {
        tableModel.globalKennelMainPageList!.clear();
      }

      final String hasherId = currentUserId;
      tableModel.globalKennelMainPageList = <KennelListAggregate>[];

      try {
        final List<Map<String, dynamic>> results =
            await QueryKennels.queryKennels(
              EnumKennelQueryType.topKennelPage,
              EnumKennelQueryContext.user,
              hasherId: hasherId,
            );

        double? dist;

        for (int i = 0; i < results.length; i++) {
          try {
            final KennelsModel kennelItem = tableModel.kennelsTableHelper
                .fromMap(results[i]);
            final KennelListQueryExtenstions extensionsItem =
                KennelListQueryExtenstions.fromMap(results[i]);

            HasherKennelMapModel? hkmItem;
            if (results[i][tableModel.hasherKennelMapTableHelper.colHkmId] !=
                null) {
              hkmItem = tableModel.hasherKennelMapTableHelper.fromMap(
                results[i],
              );
            }

            if ((deviceInfo.deviceLat != null) &&
                (deviceInfo.deviceLon != null) &&
                (extensionsItem.cityLat != null) &&
                (extensionsItem.cityLon != null)) {
              dist = Geolocator.distanceBetween(
                deviceInfo.deviceLat!,
                deviceInfo.deviceLon!,
                extensionsItem.cityLat!,
                extensionsItem.cityLon!,
              );
            }

            extensionsItem.distToKennel = dist;
            extensionsItem.followingRequested = -1;
            extensionsItem.notificationsRequested = -1;
            extensionsItem.emailAlertRequested = -1;

            final bool isHomeKennel =
                kennelItem.kennelId.toLowerCase() ==
                getStringPref(StringPrefsEnum.homeKennelId)?.toLowerCase();

            tableModel.globalKennelMainPageList!.add(
              KennelListAggregate(
                kennel: kennelItem,
                extensions: extensionsItem,
                hkm: hkmItem,
                isHomeKennel: isHomeKennel,
              ),
            );
          } catch (e, s) {
            if (kDebugMode) print(e);
            BootLogger.logError('[KennelListController._buildList] row parse error', e, s);
          }
        }
      } catch (e, s) {
        if (kDebugMode) print(e);
        BootLogger.logError('[KennelListController._buildList] query error', e, s);
      }
    }
    _filterResults();
  }

  void _filterResults() {
    final globalList = tableModel.globalKennelMainPageList;
    if (globalList == null || globalList.isEmpty) {
      filteredList.value = [];
      return;
    }

    List<KennelListAggregate> result;
    if (searchController.text.isEmpty) {
      result = List<KennelListAggregate>.from(globalList);
    } else {
      result = QueryKennels.doFilter(searchText.value, globalList);
    }

    // Defunct (-1) and Inactive-Hidden (4) kennels are excluded at the query
    // layer (QueryKennels.queryKennels, topKennelPage). Run history is
    // unaffected — these kennels still sync and appear in history.
    _sortList(result);
    filteredList.value = result;
  }

  void _sortList(List<KennelListAggregate> list) {
    final sort = sortByType.value;

    if (sort == EnumSortKennelListBy.distance &&
        appModel.hasLocationPermissions) {
      list.sort(
        (a, b) => (a.isHomeKennel ? 0.0 : a.extensions.distToKennel ?? 0)
            .compareTo(b.isHomeKennel ? 0.0 : b.extensions.distToKennel ?? 0),
      );
    } else if (sort == EnumSortKennelListBy.distance ||
        sort == EnumSortKennelListBy.kennelName) {
      list.sort(
        (a, b) => (a.isHomeKennel ? ' ' : a.kennel.kennelName.trim()).compareTo(
          b.isHomeKennel ? ' ' : b.kennel.kennelName.trim(),
        ),
      );
    } else if (sort == EnumSortKennelListBy.cityName) {
      list.sort(
        (a, b) => (a.isHomeKennel ? ' ' : (a.extensions.cityName ?? '').trim())
            .compareTo(
              b.isHomeKennel ? ' ' : (b.extensions.cityName ?? '').trim(),
            ),
      );
    } else if (sort == EnumSortKennelListBy.countryRegionName) {
      list.sort((a, b) {
        int result =
            (a.isHomeKennel ? ' ' : (a.extensions.countryName ?? '').trim())
                .compareTo(
                  b.isHomeKennel
                      ? ' '
                      : (b.extensions.countryName ?? '').trim(),
                );
        if (result == 0) {
          result = (a.extensions.regionName ?? '').trim().compareTo(
            (b.extensions.regionName ?? '').trim(),
          );
        }
        if (result == 0) {
          result = (a.extensions.cityName ?? '').trim().compareTo(
            (b.extensions.cityName ?? '').trim(),
          );
        }
        return result;
      });
    } else {
      // following (default)
      list.sort((a, b) {
        if (a.isHomeKennel) return -1;
        if (b.isHomeKennel) return 1;

        final int aFollow = a.hkm?.following ?? 0;
        final int bFollow = b.hkm?.following ?? 0;

        int result =
            (aFollow == 1
                    ? 0
                    : aFollow == 2
                    ? 2
                    : 1)
                .compareTo(
                  bFollow == 1
                      ? 0
                      : bFollow == 2
                      ? 2
                      : 1,
                );

        if (result == 0) {
          result = appModel.hasLocationPermissions
              ? (a.extensions.distToKennel ?? 0.0).compareTo(
                  b.extensions.distToKennel ?? 0.0,
                )
              : a.kennel.kennelName.trim().compareTo(
                  b.kennel.kennelName.trim(),
                );
        }
        return result;
      });
    }
  }

  Future<void> updateFollowStatus(
    int index,
    int followValue,
    int isHomeKennel,
  ) async {
    final KennelListAggregate item = filteredList[index];

    // Show optimistic loading spinner
    item.extensions.followingRequested = followValue;
    filteredList.refresh();

    final HasherKennelMapService srv = HasherKennelMapService();
    final List<dynamic> queryResults = await srv.updateHasherKennelStatus(
      item.kennel.kennelId,
      AppDomainType.user,
      followingState: followValue,
      isHomeKennel: isHomeKennel,
    );

    // Validate API response — empty list means offline or server error
    if (queryResults.isEmpty) {
      item.extensions.followingRequested = -1;
      filteredList.refresh();
      Get.snackbar(
        'Connection error',
        'Unable to update follow status. Please check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: hc_red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    await setStringPref(
      StringPrefsEnum.homeKennelId,
      queryResults[0]['isHomeKennel'] == 1
          ? item.kennel.kennelId.toLowerCase()
          : '',
    );

    // Update this item's HKM data
    item.extensions.followingRequested = -1;
    item.extensions.notificationsRequested = -1;
    item.extensions.emailAlertRequested = -1;

    final int newFollowing = queryResults[0]['following'] as int;
    final int newNotif = queryResults[0]['kennelNotificationPreference'] as int;
    final int newEmail = queryResults[0]['kennelEmailAlertPreference'] as int;
    final int newIsHomeKennel = queryResults[0]['isHomeKennel'] as int;

    final newAggregate = KennelListAggregate(
      kennel: item.kennel,
      extensions: item.extensions,
      isHomeKennel: newIsHomeKennel == 1,
      hkm: item.hkm?.copyWith(
        following: newFollowing,
        kennelNotificationPreference: newNotif,
        kennelEmailAlertPreference: newEmail,
      ),
    );

    // Write to filteredList immediately for reactive UI feedback.
    filteredList[index] = newAggregate;

    // Sync globalKennelMainPageList — _filterResults() rebuilds filteredList from
    // this list, so without this update the new following state is overwritten.
    final globalList = tableModel.globalKennelMainPageList;
    if (globalList != null) {
      final globalIndex = globalList.indexWhere(
        (k) =>
            k.kennel.kennelId.toLowerCase() ==
            item.kennel.kennelId.toLowerCase(),
      );
      if (globalIndex != -1) {
        globalList[globalIndex] = newAggregate;
      }
    }

    // Handle home kennel flag — clear it on all other items if this one is now home
    if (newIsHomeKennel == 1) {
      for (int i = 0; i < filteredList.length; i++) {
        if (i != index) filteredList[i].isHomeKennel = false;
      }
      if (globalList != null) {
        for (final k in globalList) {
          k.isHomeKennel =
              k.kennel.kennelId.toLowerCase() ==
              item.kennel.kennelId.toLowerCase();
        }
      }
    } else {
      filteredList[index].isHomeKennel = false;
    }

    // Delete stale events and re-sync for this kennel
    final String sql =
        '''
      DELETE FROM ${EnumDataTables.events.commonTableName}
      WHERE ${tableModel.eventsTableHelper.colKennelId} = '${item.kennel.kennelId}'
    ''';
    await database.rawQuery(sql);

    await tableModel.syncUserDataService.updateFromBackend(
      EnumDataTables.events.flag,
      true,
      forceReplicateAllRunsForKennel: item.kennel.kennelId,
      debugText: 'kennel_list_controller: Events following update',
    );

    // Re-sort the list to reflect the new following status
    _filterResults();

    // Notify other controllers (e.g. FutureRunListPageController)
    Get.find<DataChangeService>().notify(
      DataChangeEvent(
        type: DataChangeType.kennelFollowStatusChanged,
        id: item.kennel.kennelId,
      ),
    );
  }

  Future<void> updateNotificationStatus(
    int index,
    NotificationState state,
  ) async {
    final KennelListAggregate item = filteredList[index];
    item.extensions.notificationsRequested = state.value;
    filteredList.refresh();

    final String userId = currentUserId;
    final List<dynamic> results = await tableModel.hasherKennelMapService
        .setEmailAndNotificationPreferences(
          item.kennel.kennelId,
          userId,
          AppDomainType.user,
          state,
          emailAlertsUnchanged,
        );

    item.extensions.notificationsRequested = -1;
    if (results.isNotEmpty) {
      final int newPref = results[0]['notificationPreference'] as int;
      final newAggregate = KennelListAggregate(
        kennel: item.kennel,
        extensions: item.extensions,
        isHomeKennel: item.isHomeKennel,
        hkm: item.hkm?.copyWith(kennelNotificationPreference: newPref),
      );
      filteredList[index] = newAggregate;
      final globalList = tableModel.globalKennelMainPageList;
      if (globalList != null) {
        final gi = globalList.indexWhere(
          (k) =>
              k.kennel.kennelId.toLowerCase() ==
              item.kennel.kennelId.toLowerCase(),
        );
        if (gi != -1) globalList[gi] = newAggregate;
      }
    } else {
      filteredList.refresh();
    }
  }

  Future<void> updateEmailStatus(int index, dynamic retVal) async {
    final KennelListAggregate item = filteredList[index];
    item.extensions.emailAlertRequested = retVal.value as int;
    filteredList.refresh();

    final String userId = currentUserId;
    final List<dynamic> results = await tableModel.hasherKennelMapService
        .setEmailAndNotificationPreferences(
          item.kennel.kennelId,
          userId,
          AppDomainType.user,
          NotificationState.unchanged,
          retVal,
        );

    item.extensions.emailAlertRequested = -1;
    if (results.isNotEmpty) {
      final int newPref = results[0]['emailAlertPreference'] as int;
      final newAggregate = KennelListAggregate(
        kennel: item.kennel,
        extensions: item.extensions,
        isHomeKennel: item.isHomeKennel,
        hkm: item.hkm?.copyWith(kennelEmailAlertPreference: newPref),
      );
      filteredList[index] = newAggregate;
      final globalList = tableModel.globalKennelMainPageList;
      if (globalList != null) {
        final gi = globalList.indexWhere(
          (k) =>
              k.kennel.kennelId.toLowerCase() ==
              item.kennel.kennelId.toLowerCase(),
        );
        if (gi != -1) globalList[gi] = newAggregate;
      }
    } else {
      filteredList.refresh();
    }
  }

  Future<void> handleRefresh() async {
    tableModel.globalKennelMainPageList = null;
    filteredList.value = [];

    String query = 'DELETE FROM ${EnumDataTables.kennels.commonTableName}';
    try {
      await database.rawQuery(query);
    } catch (e, s) {
      debugPrint('kennel_list_controller: DELETE kennels failed: $e');
      BootLogger.logError('[KennelListController.leaveKennel] DELETE kennels', e, s);
    }

    query = 'DELETE FROM ${EnumDataTables.hasherKennelMap.commonTableName}';
    try {
      await database.rawQuery(query);
    } catch (e, s) {
      debugPrint('kennel_list_controller: DELETE hasherKennelMap failed: $e');
      BootLogger.logError('[KennelListController.leaveKennel] DELETE hasherKennelMap', e, s);
    }

    await tableModel.syncUserDataService.updateFromBackend(
      EnumDataTables.kennels.flag | EnumDataTables.hasherKennelMap.flag,
      true,
      debugText: 'kennel_list_controller: Kennels, HKM (pull-to-refresh)',
    );
    await refreshFromTable(true);
  }

  Future<void> navigateToKennelAdmin(BuildContext context, int index) async {
    final KennelListAggregate kennel = filteredList[index];

    // Gate entry to kennel admin (hcapp_syncKennelAdminData). Mirrors the SP
    // auth exactly so we don't fire a request the server will reject. UI gate is
    // UX only — the SP is the real gate. See /hc-authorizations.
    if (!canEnterArea(
      PermissionArea.kennelTools,
      appAccessFlags: kennel.hkm?.appAccessFlags ?? 0,
      mismanagementRoles: kennel.hkm?.mismanagementRoles ?? 0,
      kennelOverrideJson: kennel.kennel.permissionOverrideJson,
    )) {
      showHcSnackbar(
        'You don\'t have admin access for this kennel.',
        isError: true,
      );
      return;
    }

    tableModel.globalKennelMainPageList!.clear();

    await Navigator.of(context).push<dynamic>(
      MaterialPageRoute<dynamic>(
        builder: (BuildContext context) =>
            KennelAdminMainPage(kennelAggregateItem: kennel),
      ),
    );

    await tableModel.syncUserDataService.updateFromBackend(
      EnumDataTables.hasherEventMap.flag |
          EnumDataTables.hasherKennelMap.flag |
          EnumDataTables.kennels.flag,
      true,
      debugText: 'kennel_list_controller: HEM, HKM, Kennels (post-admin)',
    );
    await refreshFromTable(true);
  }
}
