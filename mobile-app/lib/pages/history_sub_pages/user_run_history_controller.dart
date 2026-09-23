import 'package:harrier_central/imports.dart';

/// State for a hasher's run list scoped to ONE kennel or ONE country: the
/// rows, the My Runs / All Runs tab, and the swipe-to-set-attendance writes.
///
/// One controller serves both UserRunHistoryListPage (kennel) and
/// UserCountryHistoryListPage (country); before 2026-09-23 each page carried
/// its own 800-line copy of the same State and the same query, differing in
/// one WHERE clause. The list is built locally and assigned in one step — the
/// old code emptied the field BEFORE the await and refilled it after.
class UserRunHistoryController extends GetxController
    with GetSingleTickerProviderStateMixin {
  UserRunHistoryController({
    required this.appDomain,
    this.hasherId,
    RunHistoryModel? kennelInfo,
    this.countryId,
    this.refreshKennelInfo,
  }) : assert(kennelInfo != null || countryId != null),
       kennel = Rxn<RunHistoryModel>(kennelInfo),
       _kennelId = kennelInfo?.kennelId;

  final AppDomainType appDomain;
  final String? hasherId;

  /// Kennel scope: the header card, refreshed through [refreshKennelInfo]
  /// after every attendance change (the parent list owns that query).
  final Rxn<RunHistoryModel> kennel;
  final String? _kennelId;
  final Function? refreshKennelInfo;

  /// Country scope.
  final String? countryId;

  static String tagFor({String? kennelId, String? countryId, String? hasherId}) =>
      'runhist-${kennelId ?? countryId}-${hasherId ?? 'me'}';

  late final String userId = hasherId ?? currentUserId;

  late final TabController tabController;
  final RxInt tabIndex = 0.obs;

  final RxBool isLoading = false.obs;
  final RxList<UserRunHistoryModel> runs = <UserRunHistoryModel>[].obs;
  final RxInt countryCount = 1.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(_onTab);
    unawaited(refreshFromTable());
  }

  @override
  void onClose() {
    tabController.removeListener(_onTab);
    tabController.dispose();
    super.onClose();
  }

  void _onTab() {
    // Fires when the tap starts the animation and again when it settles; the
    // list re-reads on both, as it always did, and the labels follow.
    if (tabController.indexIsChanging ||
        tabController.index != tabController.previousIndex) {
      tabIndex.value = tabController.index;
      unawaited(refreshFromTable());
    }
  }

  String get _scopeEvents => countryId != null
      ? 'AND lower(e.${tableModel.eventsTableHelper.colCountryId}) = "${normalizeUuid(countryId!)}"'
      : 'AND e.${tableModel.eventsTableHelper.colKennelId} = "$_kennelId"';

  String get _scopeHem => countryId != null
      ? 'AND lower(hem.${tableModel.hasherEventMapTableHelper.colCountryId}) = "${normalizeUuid(countryId!)}"'
      : 'AND hem.${tableModel.hasherEventMapTableHelper.colEventKennelId} = "$_kennelId"';

  Future<void> refreshFromTable() async {
    // This query looks at two places for historical runs. First it looks at all
    // of the current runs cached on the phone and joins to HEM. But for runs
    // that are old and no longer cached on the phone, it looks at the HEM
    // record only, in the second half of the UNION.

    // Tab 0 is My Runs (attended, >= 20); tab 1 is All Runs.
    final int attendenceState = tabController.index == 0 ? 20 : 0;

    const String dollarSign = r'$^';
    final offsetFromGmtToLocal = Utilities.getSqfliteTimeOffset();
    final String hemTable = tableModel.hasherEventMapTableHelper.getTableName(
      appDomain,
    );
    final String payTable = tableModel.paymentsTableHelper.getTableName(
      appDomain,
    );

    final String query =
        '''
          SELECT
          hem.${tableModel.hasherEventMapTableHelper.colTotalRunsThisKennel} as totalRunsThisKennel,
          hem.${tableModel.hasherEventMapTableHelper.colTotalHaringThisKennel} as totalHaringThisKennel,
          e.${tableModel.eventsTableHelper.colEventId} as eventId,
          e.${tableModel.eventsTableHelper.colEventName} as eventName,
          e.${tableModel.eventsTableHelper.colEventNumber} as eventNumber,
          n.${tableModel.countriesTableHelper.colCountryName} as countryName,
          coalesce(n.${tableModel.countriesTableHelper.colFlagFile},'') as flagFile,
          k.${tableModel.kennelsTableHelper.colKennelName} as kennelName,
          k.${tableModel.kennelsTableHelper.colKennelShortName} as kennelShortName,
          k.${tableModel.kennelsTableHelper.colKennelLogo} as kennelLogo,
          coalesce(k.${tableModel.kennelsTableHelper.colDigitsAfterDecimal},n.${tableModel.countriesTableHelper.colDigitsAfterDecimal},2) as digitsAfterDecimal,
          coalesce(k.${tableModel.kennelsTableHelper.colCurrencySymbol},n.${tableModel.countriesTableHelper.colCurrencySymbol},"$dollarSign") as currencySymbol,
          e.${tableModel.eventsTableHelper.colEventStartDatetime} as eventStartDatetime,
          e.${tableModel.eventsTableHelper.colExtrasDescription} as extrasDescription,
          e.${tableModel.eventsTableHelper.colEventPriceForExtras} as extrasPrice,
          coalesce(e.${tableModel.eventsTableHelper.colCanEditRunAttendence},k.${tableModel.kennelsTableHelper.colCanEditRunAttendence}) as canEditRunAttendence,
          hem.${tableModel.hasherEventMapTableHelper.colHemId} as hemId,
          coalesce(hem.${tableModel.hasherEventMapTableHelper.colAttendenceState},0) as attendenceState,
          coalesce(hem.${tableModel.hasherEventMapTableHelper.colIsHare},0) as isHare,
          pay.${tableModel.paymentsTableHelper.colCreditAmount} as creditAmount,
          pay.${tableModel.paymentsTableHelper.colDebitAmount} as debitAmount,
          pay.${tableModel.paymentsTableHelper.colCreditAvailable} as creditAvailable,
          pay.${tableModel.paymentsTableHelper.colPaymentType} as paymentType,
          pay.${tableModel.paymentsTableHelper.colDoPayForExtras} as doPayForExtras
          FROM ${EnumDataTables.events.commonTableName} e
          INNER JOIN ${EnumDataTables.kennels.commonTableName} k on e.${tableModel.eventsTableHelper.colKennelId} = k.${tableModel.kennelsTableHelper.colKennelId}
          INNER JOIN ${EnumDataTables.countries.commonTableName} n on e.${tableModel.eventsTableHelper.colCountryId} = n.${tableModel.countriesTableHelper.colCountryId}
          LEFT OUTER JOIN $hemTable hem on hem.${tableModel.hasherEventMapTableHelper.colEventId} = e.${tableModel.eventsTableHelper.colEventId}
          AND hem.${tableModel.hasherEventMapTableHelper.colUserId}  = "$userId"
          LEFT OUTER JOIN $payTable pay on pay.${tableModel.paymentsTableHelper.colHemId} = hem.${tableModel.hasherEventMapTableHelper.colHemId} AND pay.${tableModel.paymentsTableHelper.colCancelledBy} IS NULL
          WHERE e.${tableModel.eventsTableHelper.colIsCountedRun} = 1
          AND e.${tableModel.eventsTableHelper.colIsVisible} = 1
          AND e.${tableModel.eventsTableHelper.colRemoved} = 0
          $_scopeEvents
          AND coalesce(hem.${tableModel.hasherEventMapTableHelper.colAttendenceState},0) >= $attendenceState
          AND julianday(e.${tableModel.eventsTableHelper.colEventStartDatetime}) <= julianday('now','$offsetFromGmtToLocal')
        UNION
          -- Covers old runs no longer in the events cache — HEM-only records.
          SELECT
          hem.${tableModel.hasherEventMapTableHelper.colTotalRunsThisKennel} as totalRunsThisKennel,
          hem.${tableModel.hasherEventMapTableHelper.colTotalHaringThisKennel} as totalHaringThisKennel,
          hem.${tableModel.hasherEventMapTableHelper.colEventId} as eventId,
          coalesce(hem.${tableModel.hasherEventMapTableHelper.colEventName},'') as eventName,
          hem.${tableModel.hasherEventMapTableHelper.colEventNumber} as eventNumber,
          n.${tableModel.countriesTableHelper.colCountryName} as countryName,
          coalesce(n.${tableModel.countriesTableHelper.colFlagFile},'') as flagFile,
          k.${tableModel.kennelsTableHelper.colKennelName} as kennelName,
          k.${tableModel.kennelsTableHelper.colKennelShortName} as kennelShortName,
          k.${tableModel.kennelsTableHelper.colKennelLogo} as kennelLogo,
          coalesce(k.${tableModel.kennelsTableHelper.colDigitsAfterDecimal},n.${tableModel.countriesTableHelper.colDigitsAfterDecimal},2) as digitsAfterDecimal,
          coalesce(k.${tableModel.kennelsTableHelper.colCurrencySymbol},n.${tableModel.countriesTableHelper.colCurrencySymbol},"$dollarSign") as currencySymbol,
          hem.${tableModel.hasherEventMapTableHelper.colEventStartDatetime} as eventStartDatetime,
          null as extrasDescription,
          null as extrasPrice,
          hem.${tableModel.hasherEventMapTableHelper.colCanEditRunAttendence} as canEditRunAttendence,
          hem.${tableModel.hasherEventMapTableHelper.colHemId} as hemId,
          coalesce(hem.${tableModel.hasherEventMapTableHelper.colAttendenceState},0) as attendenceState,
          coalesce(hem.${tableModel.hasherEventMapTableHelper.colIsHare},0) as isHare,
          pay.${tableModel.paymentsTableHelper.colCreditAmount} as creditAmount,
          pay.${tableModel.paymentsTableHelper.colDebitAmount} as debitAmount,
          pay.${tableModel.paymentsTableHelper.colCreditAvailable} as creditAvailable,
          pay.${tableModel.paymentsTableHelper.colPaymentType} as paymentType,
          pay.${tableModel.paymentsTableHelper.colDoPayForExtras} as doPayForExtras
          FROM $hemTable hem
          INNER JOIN ${EnumDataTables.kennels.commonTableName} k on k.${tableModel.kennelsTableHelper.colKennelId} = hem.${tableModel.hasherEventMapTableHelper.colEventKennelId}
          INNER JOIN ${EnumDataTables.countries.commonTableName} n on n.${tableModel.countriesTableHelper.colCountryId} = hem.${tableModel.hasherEventMapTableHelper.colCountryId}
          LEFT OUTER JOIN $payTable pay on pay.${tableModel.paymentsTableHelper.colHemId} = hem.${tableModel.hasherEventMapTableHelper.colHemId} AND pay.${tableModel.paymentsTableHelper.colCancelledBy} IS NULL
          WHERE
          hem.${tableModel.hasherEventMapTableHelper.colEventId} NOT IN (SELECT eventId FROM ${EnumDataTables.events.commonTableName})
          AND hem.${tableModel.hasherEventMapTableHelper.colUserId} = "$userId"
          AND hem.${tableModel.hasherEventMapTableHelper.colEventIsCountedAndVisible} = 1
          AND hem.${tableModel.hasherEventMapTableHelper.colRemoved} = 0
          $_scopeHem
          AND coalesce(hem.${tableModel.hasherEventMapTableHelper.colAttendenceState},0) >= $attendenceState
          AND julianday(hem.${tableModel.hasherEventMapTableHelper.colEventStartDatetime}) <= julianday('now','$offsetFromGmtToLocal')
          ORDER BY eventStartDatetime desc
          ''';

    final List<UserRunHistoryModel> next = <UserRunHistoryModel>[];
    try {
      final List<Map<String, dynamic>> results = await database.rawQuery(query);
      for (int i = 0; i < results.length; i++) {
        try {
          next.add(UserRunHistoryModel.fromMap(results[i]));
        } catch (e, s) {
          // One bad row must not blank the whole list.
          BootLogger.logError(
            '[UserRunHistory] row $i parse error userId=$userId scope=${countryId ?? _kennelId}',
            e,
            s,
          );
        }
      }
    } catch (e, s) {
      BootLogger.logError(
        '[UserRunHistory] query failed userId=$userId scope=${countryId ?? _kennelId}',
        e,
        s,
      );
    }
    if (isClosed) return;
    runs.assignAll(next);
    countryCount.value = next.map((run) => run.flagFile).toSet().length;
    isLoading.value = false;
  }

  Future<void> _refreshKennel() async {
    final Function? refresh = refreshKennelInfo;
    if (refresh == null) return;
    final dynamic fresh = await refresh();
    if (isClosed) return;
    if (fresh is RunHistoryModel) kennel.value = fresh;
  }

  Future<void> pullToRefresh() async {
    isLoading.value = true;
    await tableModel.syncUserDataService.updateFromBackend(
      EnumDataTables.hasherEventMap.flag |
          EnumDataTables.events.flag |
          EnumDataTables.kennels.flag |
          EnumDataTables.payments.flag |
          EnumDataTables.hasherKennelMap.flag,
      true,
      debugText: 'user_run_history: HEM, Events, Kennels',
    );
    if (isClosed) return;
    await refreshFromTable();
    await _refreshKennel();
    if (isClosed) return;
    isLoading.value = false;
  }

  void _markUpdating(UserRunHistoryModel item) {
    final int i = runs.indexWhere((r) => r.eventId == item.eventId);
    if (i >= 0) runs[i] = runs[i].copyWith(isUpdating: true);
  }

  Future<void> setAttendence(
    UserRunHistoryModel item,
    EnumAttendenceState attendenceState,
    EnumIsHare isHare,
  ) async {
    _markUpdating(item);
    await tableModel.hasherEventMapService.setEventAttendence(
      item.eventId,
      userId,
      appDomain,
      attendenceState.value,
      isHare: isHare.value,
      hemId: item.hemId,
    );
    if (isClosed) return;
    await refreshFromTable();
    await _refreshKennel();
  }

  /// A swipe on a row. Right-to-left: "I was at the Hash" — and, if already
  /// there, toggles the hare flag. Left-to-right: "I was not at the Hash".
  Future<void> onSwipe(UserRunHistoryModel item, DismissDirection direction) {
    if (item.canEditRunAttendence == 0) return Future<void>.value();
    if (direction == DismissDirection.endToStart) {
      if (item.attendenceState < attendenceAtHash.value) {
        // Not at the Hash → at the Hash; assume not a hare.
        return setAttendence(item, attendenceAtHash, isHareNo);
      }
      return setAttendence(
        item,
        attendenceAtHash,
        item.isHare == 1 ? isHareNo : isHareYes,
      );
    }
    return setAttendence(item, attendenceNo, isHareNo);
  }

  /// The row's own buttons.
  Future<void> onSetAttendence(
    UserRunHistoryModel item,
    EnumAttendenceState attendenceState,
    EnumIsHare isHare,
  ) {
    if (attendenceState == attendenceNo) {
      return setAttendence(item, attendenceNo, isHareNo);
    }
    return setAttendence(
      item,
      attendenceAtHash,
      isHare == isHareYes ? isHareYes : isHareNo,
    );
  }
}
