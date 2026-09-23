// ignore_for_file: constant_identifier_names

import 'package:harrier_central/imports.dart';

enum EnumSortByType {
  sortByName,
  sortByLastRunDate,
  sortByMembershipExpirationDate,
}

/// State for the kennel admin's members list: the grouped member rows, the
/// search and filter panel, the counters, the sort order and every
/// membership / role / access write a swipe or popup can make.
///
/// Migrated from a 1240-line State on 2026-09-23. It used to hold the list as
/// a FUTURE in a field and rebuild through a FutureBuilder, which is the same
/// family as clear-before-await: a frame could paint the old count over the
/// new list. The rows are an RxList assigned in one step now, and a row in
/// flight is found by hasherId, not by an index that a refresh can move.
///
/// The filter-panel animation, the search focus node and text controller are
/// owned here too (GetSingleTickerProviderStateMixin) and disposed in onClose.
class KennelMembersController extends GetxController
    with GetSingleTickerProviderStateMixin {
  KennelMembersController({required this.kennelListAggregate});

  final KennelListAggregate kennelListAggregate;

  static String tagFor(String kennelId) => 'members-$kennelId';

  String get _kennelId => kennelListAggregate.kennel.kennelId;

  static const int FILTER_IS_MEMBER = 0;
  static const int FILTER_IS_FOLLOWING = 1;
  static const int FILTER_IS_HOME_KENNEL = 2;
  static const int FILTER_RUNS_IN_LAST_YEAR = 3;

  final Rx<EnumSortByType> sortBy = EnumSortByType.sortByName.obs;

  /// Section headers (an int, the memberFollowingStatus) interleaved with
  /// KennelMemberResultsModel rows, in display order.
  List<dynamic> _members = <dynamic>[];
  final RxList<dynamic> filteredMembers = <dynamic>[].obs;
  final RxBool isLoading = true.obs;

  final RxBool showFilter = false.obs;

  /// Tri-state per filter cell (0 off, 1 must, -1 must not). KennelFilterCell
  /// mutates this list in place and then calls back, so it is a plain list.
  final List<int> filterValues = <int>[0, 0, 0, 0, 0, 0, 0];
  String searchText = '';

  final RxInt countIsMember = 0.obs;
  final RxInt countIsFollowing = 0.obs;
  final RxInt countHasRecentRuns = 0.obs;

  late final AnimationController animationController;
  late final Animation<double> buttonAnimation;
  late final Animation<Offset> filterPanelAnimation;
  late final Animation<RelativeRect> hasherListAnimation;
  final GlobalKey packListBoxKey = GlobalKey();
  final FocusNode searchFocusNode = FocusNode();
  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    filterPanelAnimation = Tween<Offset>(
      begin: const Offset(0, -.35),
      end: const Offset(0, .71),
    ).animate(animationController);
    hasherListAnimation = RelativeRectTween(
      begin: const RelativeRect.fromLTRB(0, 86, 0, 0),
      end: const RelativeRect.fromLTRB(0, 204, 0, 0),
    ).animate(animationController);
    // Consumed by RotationTransition, which animates itself each frame — no
    // per-frame rebuild needed. (filterPanelAnimation and hasherListAnimation
    // likewise drive Slide/PositionedTransition.)
    buttonAnimation = Tween<double>(
      begin: 0,
      end: 90.0 / 360.0,
    ).animate(animationController);

    unawaited(refreshAll());
  }

  @override
  void onClose() {
    animationController.dispose();
    searchFocusNode.dispose();
    searchController.dispose();
    super.onClose();
  }

  /// The speed dial's sort entry names the NEXT order — what a tap will do.
  ({String label, EnumSortByType next, IconData icon}) get nextSort {
    switch (sortBy.value) {
      case EnumSortByType.sortByName:
        return (
          label: 'Sort by Date\r\nof last run',
          next: EnumSortByType.sortByLastRunDate,
          icon: FontAwesome.sort_numeric_desc,
        );
      case EnumSortByType.sortByLastRunDate:
        return (
          label: 'Sort by Date\r\nmembership expires',
          next: EnumSortByType.sortByMembershipExpirationDate,
          icon: FontAwesome.sort_numeric_desc,
        );
      case EnumSortByType.sortByMembershipExpirationDate:
        return (
          label: 'Sort by Name',
          next: EnumSortByType.sortByName,
          icon: FontAwesome.sort_alpha_asc,
        );
    }
  }

  Future<void> cycleSort() async {
    sortBy.value = nextSort.next;
    // The speed dial is built by the page's GetBuilder, not an Obx.
    update();
    await refreshAll();
  }

  /// Re-read the rows and the counters from the local kennel-domain tables.
  Future<void> refreshAll() async {
    await _refreshMembersFromTable();
    await _refreshCounters();
    if (isClosed) return;
    isLoading.value = false;
  }

  Future<void> pullToRefresh() async {
    await tableModel.syncKennelAdminService.updateFromBackend(
      EnumDataTables.kennels.flag |
          EnumDataTables.hashers.flag |
          EnumDataTables.hasherKennelMap.flag,
      true,
      _kennelId,
    );
    if (isClosed) return;
    await refreshAll();
  }

  Future<void> _refreshMembersFromTable() async {
    String orderBy = 'lower(h.${tableModel.hashersTableHelper.colDispName})';
    switch (sortBy.value) {
      case EnumSortByType.sortByName:
        orderBy = 'lower(h.${tableModel.hashersTableHelper.colDispName})';
        break;
      case EnumSortByType.sortByLastRunDate:
        orderBy =
            'hkm.${tableModel.hasherKennelMapTableHelper.colDateOfLastRun}';
        break;
      case EnumSortByType.sortByMembershipExpirationDate:
        orderBy =
            'hkm.${tableModel.hasherKennelMapTableHelper.colMembershipExpirationDate} asc';
        break;
    }

    if (kDebugMode) {
      final String message = (await CommonQueries.countRecords(
        EnumDataTables.hasherKennelMap.kennelTableName,
      )).toString();
      debugPrint('HKM count = $message');
    }

    final String query =
        '''
        SELECT 
          h.${tableModel.hashersTableHelper.colHasherId},
          coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colKennelHashName},coalesce(h.${tableModel.hashersTableHelper.colDispName},h.${tableModel.hashersTableHelper.colHashName},h.${tableModel.hashersTableHelper.colFirstName} || " " || h.${tableModel.hashersTableHelper.colLastName},"<no name>")) as dispName,
          lower(coalesce(" " || hkm.${tableModel.hasherKennelMapTableHelper.colKennelHashName} || " ",(" " || coalesce(h.${tableModel.hashersTableHelper.colHashName},"") || " " || coalesce(h.${tableModel.hashersTableHelper.colDispName},"") || " " || coalesce(h.${tableModel.hashersTableHelper.colFirstName},"") || " " || coalesce(h.${tableModel.hashersTableHelper.colLastName},"") || " "))) as nameForSort,
          coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colKennelUserPhoto},h.${tableModel.hashersTableHelper.colPhoto}) as photo,
          hkm.${tableModel.hasherKennelMapTableHelper.colFollowing},
          hkm.${tableModel.hasherKennelMapTableHelper.colDateOfLastRun},
          hkm.${tableModel.hasherKennelMapTableHelper.colKennelEmailAlertPreference},
          hkm.${tableModel.hasherKennelMapTableHelper.colMembershipExpirationDate},
          hkm.${tableModel.hasherKennelMapTableHelper.colMemberSince},
          hkm.${tableModel.hasherKennelMapTableHelper.colAppAccessFlags},
          hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalTotalRunCount},
          hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalHaringCount},          
          hkm.${tableModel.hasherKennelMapTableHelper.colHcHaringCount},
          hkm.${tableModel.hasherKennelMapTableHelper.colHcTotalRunCount},
          hkm.${tableModel.hasherKennelMapTableHelper.colAppAccessFlags},
          hkm.${tableModel.hasherKennelMapTableHelper.colMismanagementRoles},
          hkm.${tableModel.hasherKennelMapTableHelper.colKennelCredit},
          k.${tableModel.kennelsTableHelper.colMembershipDurationInMonths},
          k.${tableModel.kennelsTableHelper.colKennelShortName},
          k.${tableModel.kennelsTableHelper.colKennelId}
          ,case 
            when hkm.${tableModel.hasherKennelMapTableHelper.colMembershipExpirationDate} >= date('now') then 1
            when ((hkm.${tableModel.hasherKennelMapTableHelper.colDateOfLastRun} is not null) AND (hkm.${tableModel.hasherKennelMapTableHelper.colDateOfLastRun} >= date('now','-182 day'))) then 2
            when hkm.${tableModel.hasherKennelMapTableHelper.colDateOfLastRun} is not null then 3
            when hkm.${tableModel.hasherKennelMapTableHelper.colFollowing} = 1 then 4
            else 5
          end as memberFollowingStatus
          FROM ${EnumDataTables.hashers.commonTableName} h
          LEFT OUTER JOIN ${EnumDataTables.hasherKennelMap.kennelTableName} hkm on hkm.${tableModel.hasherKennelMapTableHelper.colUserId} = h.${tableModel.hashersTableHelper.colHasherId} AND hkm.${tableModel.hasherKennelMapTableHelper.colKennelId} = '$_kennelId'
          LEFT OUTER JOIN ${EnumDataTables.kennels.commonTableName} k on k.${tableModel.kennelsTableHelper.colKennelId} = '$_kennelId'
          WHERE h.${tableModel.hashersTableHelper.colRemoved} = 0 
          AND h.${tableModel.hashersTableHelper.colDispName} not like 'Placeholder user for%'
          ORDER BY memberFollowingStatus,$orderBy
          
          ''';

    final List<dynamic> kList = <dynamic>[];
    int lastMemberType = 0;
    try {
      final List<Map<String, dynamic>> results = await database.rawQuery(query);
      for (int i = 0; i < results.length; i++) {
        final KennelMemberResultsModel hlrItem =
            KennelMemberResultsModel.fromMap(results[i]);
        if (hlrItem.memberFollowingStatus != lastMemberType) {
          lastMemberType = hlrItem.memberFollowingStatus;
          kList.add(lastMemberType);
        }
        kList.add(hlrItem);
      }
    } catch (e, s) {
      BootLogger.logError(
        '[KennelMembers._refreshKennelMembersFromTable] kennelId=$_kennelId',
        e,
        s,
      );
    }
    if (isClosed) return;
    _members = kList;
    _applyFilter();
  }

  Future<void> _refreshCounters() async {
    try {
      final String sql =
          '''

          SELECT 
              COUNT(CASE WHEN ${tableModel.hasherKennelMapTableHelper.colFollowing} > 0 THEN 1 ELSE NULL END) as isFollowing,
              COUNT(CASE WHEN ${tableModel.hasherKennelMapTableHelper.colMembershipExpirationDate} > date('now') THEN 1 ELSE NULL END) as isMember,
          
              COUNT(CASE WHEN ${tableModel.hasherKennelMapTableHelper.colDateOfLastRun} >= date('now','-365 day') THEN 1 ELSE NULL END) as hasRecentRuns
              FROM ${EnumDataTables.hasherKennelMap.kennelTableName} hkm
              INNER JOIN ${EnumDataTables.hashers.commonTableName} h on h.${tableModel.hashersTableHelper.colHasherId} = hkm.${tableModel.hasherKennelMapTableHelper.colUserId}
  
          ''';
      final List<Map<String, dynamic>> results = await database.rawQuery(sql);
      if (isClosed) return;
      if (results.isNotEmpty) {
        countIsMember.value = (results[0]['isMember'] as num?)?.toInt() ?? 0;
        countIsFollowing.value =
            (results[0]['isFollowing'] as num?)?.toInt() ?? 0;
        countHasRecentRuns.value =
            (results[0]['hasRecentRuns'] as num?)?.toInt() ?? 0;
      }
    } catch (e, s) {
      BootLogger.logError(
        '[KennelMembers._refreshCounters] kennelId=$_kennelId',
        e,
        s,
      );
    }
  }

  /// The filter panel's tri-state cells, then the search text, applied to
  /// the grouped list. Section headers (ints) always pass. An active panel
  /// that matches nobody falls back to the full list, as it always did.
  /// Pure, so it is unit-tested.
  static List<dynamic> filterMembers(
    List<dynamic> full, {
    required List<int> filterValues,
    required bool showFilter,
    required String searchText,
    required DateTime now,
  }) {
    final DateTime never = DateTime.parse('19900101');
    final DateTime yearAgo = now.add(const Duration(days: -365));
    List<dynamic> filtered = <dynamic>[];

    if (showFilter) {
      filtered = full.where((dynamic a) {
        if (a is int) return true;
        final KennelMemberResultsModel m = a as KennelMemberResultsModel;
        final DateTime expires = m.membershipExpirationDate ?? never;
        final DateTime lastRun = m.dateOfLastRun ?? never;
        final bool memberOk =
            (filterValues[FILTER_IS_MEMBER] == 0) ||
            (filterValues[FILTER_IS_MEMBER] == -1 && expires.isBefore(now)) ||
            (filterValues[FILTER_IS_MEMBER] == 1 && expires.isAfter(now));
        final bool followOk =
            (filterValues[FILTER_IS_FOLLOWING] == 0) ||
            (filterValues[FILTER_IS_FOLLOWING] == -1 &&
                m.following == 0) ||
            (filterValues[FILTER_IS_FOLLOWING] == 1 && m.following == 1);
        final bool runsOk =
            (filterValues[FILTER_RUNS_IN_LAST_YEAR] == 0) ||
            (filterValues[FILTER_RUNS_IN_LAST_YEAR] == -1 &&
                lastRun.isBefore(yearAgo)) ||
            (filterValues[FILTER_RUNS_IN_LAST_YEAR] == 1 &&
                lastRun.isAfter(yearAgo));
        return memberOk && followOk && runsOk;
      }).toList();
    }

    if (filtered.isEmpty) filtered = full;

    if (searchText.isNotEmpty) {
      final String needle = searchText.toLowerCase();
      filtered = filtered
          .where(
            (dynamic a) =>
                a is int ||
                (a as KennelMemberResultsModel).nameForSort
                    .toLowerCase()
                    .contains(needle),
          )
          .toList();
    }
    return filtered;
  }

  void _applyFilter() {
    filteredMembers.assignAll(
      filterMembers(
        _members,
        filterValues: filterValues,
        showFilter: showFilter.value,
        searchText: searchText,
        now: DateTime.now(),
      ),
    );
  }

  Future<void> toggleFilterPanel() async {
    searchFocusNode.unfocus();
    if (showFilter.value) {
      await animationController.reverse();
    } else {
      await animationController.forward();
    }
    if (isClosed) return;
    showFilter.value = !showFilter.value;
    searchController.text = '';
    searchText = '';
    await refreshAll();
  }

  void setSearchText(String text) {
    searchText = text;
    _applyFilter();
  }

  /// The X beside the search box. It used to clear the text but not the
  /// list (the re-filter was commented out), so the list stayed narrowed
  /// until the next keystroke.
  void clearSearch() {
    searchController.text = '';
    setSearchText('');
  }

  KennelMemberResultsModel? rowAt(int index) {
    if (index < 0 || index >= filteredMembers.length) return null;
    final dynamic row = filteredMembers[index];
    return row is KennelMemberResultsModel ? row : null;
  }

  /// Replace a row wherever it is now — a refresh may have moved it.
  void _replaceById(
    String hasherId,
    KennelMemberResultsModel Function(KennelMemberResultsModel) change,
  ) {
    final int i = filteredMembers.indexWhere(
      (dynamic r) => r is KennelMemberResultsModel && r.hasherId == hasherId,
    );
    if (i >= 0) filteredMembers[i] = change(filteredMembers[i]);
  }

  /// "Find Hasher and add": make them a member for the kennel's default
  /// membership length.
  Future<void> addMember(String hasherId) async {
    kennelListAggregate.extensions.followingRequested = -1;
    try {
      await HasherKennelMapService().updateHasherKennelStatus(
        _kennelId,
        AppDomainType.kennel,
        monthsToAddToMembership:
            kennelListAggregate.kennel.membershipDurationInMonths,
        targetUserId: hasherId,
      );
      if (isClosed) return;
      await refreshAll();
    } catch (e, s) {
      BootLogger.logError(
        '[KennelMembers.SpeedDial.updateStatus] kennelId=$_kennelId',
        e,
        s,
      );
    }
  }

  /// After a member's profile was edited from their row.
  Future<void> afterProfileEdit(
    int index, {
    required bool refreshThisUserData,
    required String dispName,
    required String photo,
  }) async {
    // If the user of this device is changing their own run counts, also
    // refresh the HKM users table so the run history page is accurate.
    if (refreshThisUserData) {
      await tableModel.syncUserDataService.updateFromBackend(
        EnumDataTables.hasherKennelMap.flag,
        true,
        debugText: 'kennel_members: HKM',
      );
      if (isClosed) return;
    }
    final KennelMemberResultsModel? m = rowAt(index);
    if (m != null) {
      _replaceById(
        m.hasherId,
        (KennelMemberResultsModel r) =>
            r.copyWith(dispName: dispName, photo: photo),
      );
    }
    await refreshAll();
  }

  /// After a membership was charged through the payment sheet. The payment
  /// SP's bundled sync returns user-domain rowsets; the target's HKM lives in
  /// the KENNEL domain, so pull it explicitly.
  Future<void> afterMembershipCharged() async {
    await tableModel.syncKennelAdminService.updateFromBackend(
      EnumDataTables.hasherKennelMap.flag,
      true,
      _kennelId,
    );
    if (isClosed) return;
    await refreshAll();
  }

  Future<void> modifyMembership(int index, int monthsToAddToMembership) async {
    final KennelMemberResultsModel? m = rowAt(index);
    if (m == null) return;
    final HasherKennelMapService srv = HasherKennelMapService();
    kennelListAggregate.extensions.followingRequested = -1;
    _replaceById(m.hasherId, (r) => r.copyWith(memberInfoBeingUpdated: true));

    List<dynamic> result = [];
    try {
      result = await srv.updateHasherKennelStatus(
        _kennelId,
        AppDomainType.kennel,
        monthsToAddToMembership: monthsToAddToMembership,
        targetUserId: m.hasherId,
      );
    } catch (e, s) {
      debugPrint('_modifyMembership: updateHasherKennelStatus error: $e');
      BootLogger.logError(
        '[KennelMembers._modifyMembership] kennelId=$_kennelId months=$monthsToAddToMembership',
        e,
        s,
      );
    } finally {
      if (!isClosed) {
        await _refreshMembersFromTable();
        _replaceById(
          m.hasherId,
          (r) => r.copyWith(memberInfoBeingUpdated: false),
        );
      }
    }
    if (isClosed) return;

    showHcSnackbar(
      result.isNotEmpty
          ? 'Membership updated.'
          : 'Could not update membership — check your connection.',
      isError: result.isEmpty,
    );

    await _refreshCounters();
  }

  Future<void> setUserProperties(
    int index, {
    int appAccessFlags = -1,
    int mismanagementRoles = -1,
    int kennelStandingSet = -1,
    int kennelStandingClear = -1,
  }) async {
    final KennelMemberResultsModel? m = rowAt(index);
    if (m == null) return;
    final HasherKennelMapService srv = HasherKennelMapService();
    kennelListAggregate.extensions.followingRequested = -1;
    _replaceById(m.hasherId, (r) => r.copyWith(memberInfoBeingUpdated: true));

    List<dynamic> result = [];
    try {
      result = await srv.updateHasherKennelStatus(
        _kennelId,
        AppDomainType.kennel,
        targetUserId: m.hasherId,
        appAccessFlags: appAccessFlags,
        mismanagementRoles: mismanagementRoles,
        kennelStandingSet: kennelStandingSet,
        kennelStandingClear: kennelStandingClear,
      );
    } catch (e, s) {
      debugPrint('_setUserProperties: updateHasherKennelStatus error: $e');
      BootLogger.logError(
        '[KennelMembers._setUserProperties] kennelId=$_kennelId appAccessFlags=$appAccessFlags mismanagementRoles=$mismanagementRoles',
        e,
        s,
      );
    } finally {
      if (!isClosed) {
        await _refreshMembersFromTable();
        _replaceById(
          m.hasherId,
          (r) => r.copyWith(memberInfoBeingUpdated: false),
        );
      }
    }
    if (isClosed) return;

    if (mismanagementRoles != -1) {
      showHcSnackbar(
        result.isNotEmpty
            ? 'Mismanagement role updated.'
            : 'Could not save role — check your connection.',
        isError: result.isEmpty,
      );
    }
    if (appAccessFlags != -1) {
      showHcSnackbar(
        result.isNotEmpty
            ? 'App access updated.'
            : 'Could not save access — check your connection.',
        isError: result.isEmpty,
      );
    }

    await _refreshCounters();
  }

  Future<void> toggleEmailPreference(int index) async {
    final KennelMemberResultsModel? m = rowAt(index);
    if (m == null) return;
    if (!Utilities.isConnected(
      showDialog: true,
      message:
          'Setting Kennel email alerts is not available in offline mode. Please connect to the Internet to change the notification preferences for a kennel.',
    )) {
      return;
    }
    final int emailAlertStatus = m.kennelEmailAlertPreference != 1 ? 1 : 2;
    // -1 draws the row's spinner. KennelMemberResultsModel is @freezed — it
    // has no setters, so assigning the field threw NoSuchMethodError and the
    // envelope did nothing at all (seen in production on 3.0.12, 2026-09-20).
    _replaceById(m.hasherId, (r) => r.copyWith(kennelEmailAlertPreference: -1));
    final List<dynamic> queryResults = await HasherKennelMapService()
        .updateHasherKennelStatus(
          _kennelId,
          AppDomainType.kennel,
          emailAlertState: emailAlertStatus,
          targetUserId: m.hasherId,
        );
    if (isClosed) return;
    // A failed call used to leave the spinner up for good; put the old value
    // back instead.
    final int next = queryResults.isNotEmpty
        ? (queryResults[0]['kennelEmailAlertPreference'] as num?)?.toInt() ?? 0
        : m.kennelEmailAlertPreference;
    _replaceById(
      m.hasherId,
      (r) => r.copyWith(kennelEmailAlertPreference: next),
    );
  }
}
