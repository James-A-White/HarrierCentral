import 'package:harrier_central/imports.dart';

class CountryStats {
  int runCount;
  int hareCount;
  String countryName;
  String flagFile;
  String countryId;

  CountryStats({
    required this.runCount,
    required this.hareCount,
    required this.countryName,
    required this.flagFile,
    required this.countryId,
  });

  factory CountryStats.fromMap(Map<String, dynamic> map) {
    return CountryStats(
      runCount: map['runCount'] ?? 0,
      hareCount: map['hareCount'] ?? 0,
      countryName: map['countryName'] ?? '',
      flagFile: map['flagFile'] ?? '',
      countryId: normalizeUuid((map['countryId'] ?? '').toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'runCount': runCount,
      'hareCount': hareCount,
      'countryName': countryName,
      'flagFile': flagFile,
      'countryId': countryId,
    };
  }
}

/// State for the History tab: run counts by kennel and by country, the
/// totals in the header, the By Kennel / By Country tab, and the re-read when
/// the returning-user background sync lands.
///
/// Migrated from a State on 2026-09-23. The tab is created once by the main
/// navigation controller and lives in an IndexedStack for the whole session,
/// so this controller does too. Both lists are built locally and swapped in
/// with one assignAll — the field is never left inconsistent across an await
/// (the RangeError on this tab, 2026-07-31, came from exactly that).
class HistoryListController extends GetxController
    with GetSingleTickerProviderStateMixin {
  static const String tag = 'history';

  late final TabController tabController;
  final RxInt tabIndex = 0.obs;

  final RxBool isLoading = false.obs;
  final RxList<RunHistoryModel> kennels = <RunHistoryModel>[].obs;
  final RxList<CountryStats> countries = <CountryStats>[].obs;
  final RxInt totalRuns = 0.obs;
  final RxInt totalHaring = 0.obs;

  StreamSubscription<DataChangeEvent>? _dataChangeSub;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(_onTab);

    unawaited(setupInitialValues());

    // The History tab does its one-time load at boot against cached data. When
    // the returning-user background sync lands fresh data, re-read the stats.
    if (Get.isRegistered<DataChangeService>()) {
      _dataChangeSub = Get.find<DataChangeService>().stream.listen((event) {
        if (event.type == DataChangeType.fullSyncCompleted && !isClosed) {
          unawaited(setupInitialValues());
        }
      });
    }
  }

  @override
  void onClose() {
    unawaited(_dataChangeSub?.cancel());
    tabController.removeListener(_onTab);
    tabController.dispose();
    super.onClose();
  }

  void _onTab() {
    // Fires while the animation runs and again when it settles; either way
    // the label colours and the list follow the controller's index.
    tabIndex.value = tabController.index;
  }

  Future<void> setupInitialValues() async {
    await queryKennelStats(true);
    await queryCountryStats(true);
  }

  /// Kennel rows → the list the tab shows and the header totals. Totals count
  /// EVERY kennel; the list keeps only those with runs or being followed.
  /// Pure, so it is unit-tested.
  static ({List<RunHistoryModel> kennels, int totalRuns, int totalHaring})
  kennelStatsFrom(List<Map<String, dynamic>> rows) {
    final List<RunHistoryModel> next = <RunHistoryModel>[];
    int totalHaring = 0;
    int totalRuns = 0;
    for (final Map<String, dynamic> row in rows) {
      final RunHistoryModel hlrItem = RunHistoryModel.fromMap(row);
      totalHaring += hlrItem.totalHaringThisKennel;
      totalRuns += hlrItem.totalRunsThisKennel;
      if ((hlrItem.totalRunsThisKennel > 0) || (hlrItem.following == 1)) {
        next.add(hlrItem);
      }
    }
    return (kennels: next, totalRuns: totalRuns, totalHaring: totalHaring);
  }

  /// HC-counted runs per country plus the historical (pre-app) counts per
  /// country, merged by country id and sorted by runs descending. A country
  /// with zero runs in both is dropped. Pure, so it is unit-tested.
  static List<CountryStats> mergeCountryStats(
    List<Map<String, dynamic>> hcRows,
    List<Map<String, dynamic>> historicRows,
  ) {
    final Map<String, CountryStats> byCountry = <String, CountryStats>{};
    for (final Map<String, dynamic> row in historicRows) {
      final CountryStats historicItem = CountryStats.fromMap(row);
      if (historicItem.runCount > 0) {
        byCountry[historicItem.countryId] = historicItem;
      }
    }
    for (final Map<String, dynamic> row in hcRows) {
      final CountryStats hcItem = CountryStats.fromMap(row);
      if (hcItem.runCount > 0) {
        final CountryStats? existing = byCountry[hcItem.countryId];
        if (existing != null) {
          existing.hareCount += hcItem.hareCount;
          existing.runCount += hcItem.runCount;
        } else {
          byCountry[hcItem.countryId] = hcItem;
        }
      }
    }
    final List<CountryStats> out = byCountry.values.toList()
      ..sort((b, a) => a.runCount.compareTo(b.runCount));
    return out;
  }

  Future<void> queryCountryStats(bool forceRefresh) async {
    final offsetFromGmtToLocal = Utilities.getSqfliteTimeOffset();
    final String userId = currentUserId;

    final String hcRunsQuery =
        '''
          SELECT
          COUNT(case when hem.${tableModel.hasherEventMapTableHelper.colAttendenceState} >= ${attendenceAtHash.value} then 1 else null end) as runCount,
          COUNT(case when hem.${tableModel.hasherEventMapTableHelper.colIsHare} != 0 AND hem.${tableModel.hasherEventMapTableHelper.colAttendenceState} >= ${attendenceAtHash.value} then 1 else null end) as hareCount,
          countries.${tableModel.countriesTableHelper.colCountryName},
          countries.${tableModel.countriesTableHelper.colCountryId},
          countries.${tableModel.countriesTableHelper.colFlagFile}
          FROM ${EnumDataTables.hasherEventMap.commonTableName} hem
          INNER JOIN ${EnumDataTables.countries.commonTableName} countries on hem.${tableModel.hasherEventMapTableHelper.colCountryId} = countries.${tableModel.countriesTableHelper.colCountryId}
          INNER JOIN ${EnumDataTables.events.commonTableName} evt on hem.${tableModel.hasherEventMapTableHelper.colEventId} = evt.${tableModel.eventsTableHelper.colEventId}
          WHERE evt.${tableModel.eventsTableHelper.colRemoved} = 0
          AND evt.${tableModel.eventsTableHelper.colIsCountedRun} != 0
          AND evt.${tableModel.eventsTableHelper.colIsVisible} != 0
          AND hem.${tableModel.hasherEventMapTableHelper.colUserId} = "$userId"
          AND julianday(evt.${tableModel.eventsTableHelper.colEventStartDatetime}) <= julianday('now','$offsetFromGmtToLocal') 
          GROUP BY countries.${tableModel.countriesTableHelper.colCountryName}, countries.${tableModel.countriesTableHelper.colCountryId}, countries.${tableModel.countriesTableHelper.colFlagFile}
          ORDER BY runCount desc
          ''';

    final String historicalRunsQuery =
        '''
          SELECT
          SUM(hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalTotalRunCount}) as runCount,
          SUM(hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalHaringCount})  as hareCount,
          countries.${tableModel.countriesTableHelper.colCountryName},
          countries.${tableModel.countriesTableHelper.colCountryId},
          countries.${tableModel.countriesTableHelper.colFlagFile}
          FROM ${EnumDataTables.hasherKennelMap.commonTableName} hkm
          INNER JOIN ${EnumDataTables.kennels.commonTableName} ken on hkm.${tableModel.hasherKennelMapTableHelper.colKennelId} = ken.${tableModel.kennelsTableHelper.colKennelId}
          INNER JOIN ${EnumDataTables.countries.commonTableName} countries on ken.${tableModel.kennelsTableHelper.colCountryId} = countries.${tableModel.countriesTableHelper.colCountryId}
          WHERE hkm.${tableModel.hasherKennelMapTableHelper.colUserId} = "$userId"
          GROUP BY countries.${tableModel.countriesTableHelper.colCountryName}, countries.${tableModel.countriesTableHelper.colCountryId}, countries.${tableModel.countriesTableHelper.colFlagFile}
          ORDER BY runCount desc
          ''';

    try {
      final List<Map<String, dynamic>> hcResults = await database.rawQuery(
        hcRunsQuery,
      );
      final List<Map<String, dynamic>> historicResults = await database
          .rawQuery(historicalRunsQuery);
      if (isClosed) return;
      countries.assignAll(mergeCountryStats(hcResults, historicResults));
    } catch (e, s) {
      BootLogger.logError('[HistoryList.queryCountryStats]', e, s);
    }
  }

  Future<void> queryKennelStats(bool forceRefresh) async {
    final String userId = currentUserId;

    final String query =
        '''
          SELECT 
          coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalTotalRunCount} + hkm.${tableModel.hasherKennelMapTableHelper.colHcTotalRunCount},0) as totalRunsThisKennel,
          coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalHaringCount} + ${tableModel.hasherKennelMapTableHelper.colHcHaringCount},0) as totalHaringThisKennel,

          coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colHcTotalRunCount},0) as hcRunsThisKennel,
          coalesce(${tableModel.hasherKennelMapTableHelper.colHcHaringCount},0) as hcHaringThisKennel,

          k.${tableModel.kennelsTableHelper.colKennelShortName},
          k.${tableModel.kennelsTableHelper.colKennelName},
          k.${tableModel.kennelsTableHelper.colKennelId},
          k.${tableModel.kennelsTableHelper.colKennelLogo},
          coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalTotalRunCount},0) as ${tableModel.hasherKennelMapTableHelper.colHistoricalTotalRunCount},
          coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalHaringCount},0) as ${tableModel.hasherKennelMapTableHelper.colHistoricalHaringCount},
          coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalCountIsEstimate},0) as ${tableModel.hasherKennelMapTableHelper.colHistoricalCountIsEstimate},
          coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colFollowing},0) as ${tableModel.hasherKennelMapTableHelper.colFollowing},
          coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colKennelCredit},0) as kennelCredit,
          coalesce(k.${tableModel.kennelsTableHelper.colDigitsAfterDecimal},c.${tableModel.countriesTableHelper.colDigitsAfterDecimal}) as digitsAfterDecimal,
          coalesce(k.${tableModel.kennelsTableHelper.colCurrencySymbol},c.${tableModel.countriesTableHelper.colCurrencySymbol}) as currencySymbol
          FROM ${EnumDataTables.kennels.commonTableName} k
          INNER JOIN ${EnumDataTables.countries.commonTableName} c on c.${tableModel.countriesTableHelper.colCountryId} = k.${tableModel.kennelsTableHelper.colCountryId}
          LEFT OUTER JOIN ${EnumDataTables.hasherKennelMap.commonTableName} hkm on hkm.${tableModel.hasherKennelMapTableHelper.colUserId} = "$userId"  and hkm.${tableModel.hasherKennelMapTableHelper.colKennelId} = k.${tableModel.kennelsTableHelper.colKennelId}
          ORDER BY totalRunsThisKennel desc
          ''';

    try {
      final List<Map<String, dynamic>> results = await database.rawQuery(query);
      if (isClosed) return;
      final stats = kennelStatsFrom(results);
      kennels.assignAll(stats.kennels);
      totalRuns.value = stats.totalRuns;
      totalHaring.value = stats.totalHaring;
      // Previously only cleared inside the loop on the last row, so a user
      // with no qualifying kennels sat on the spinner forever.
      if (forceRefresh) isLoading.value = false;
    } catch (e, s) {
      BootLogger.logError('[ERROR][HISTORY]', 'queryKennelStats failed: $e', s);
      if (kDebugMode) debugPrint('[HistoryList] queryKennelStats failed: $e');
      if (isClosed) return;
      if (forceRefresh) isLoading.value = false;
    }
  }

  /// For a kennel row's own refresh: re-read the stats and hand back that
  /// kennel's fresh row (null if it no longer qualifies).
  Future<RunHistoryModel?> refreshKennelRow(String kennelId) async {
    await queryKennelStats(true);
    if (kennelId.isEmpty) return null;
    for (final RunHistoryModel k in kennels) {
      if (k.kennelId == kennelId) return k;
    }
    return null;
  }

  Future<void> pullToRefresh() async {
    isLoading.value = true;
    await tableModel.syncUserDataService.updateFromBackend(
      EnumDataTables.hasherEventMap.flag |
          EnumDataTables.hasherKennelMap.flag |
          EnumDataTables.events.flag |
          EnumDataTables.kennels.flag,
      true,
      debugText: 'history_list_page: HEM,HKM,Events,Kennels',
    );
    if (isClosed) return;
    await queryKennelStats(true);
    await queryCountryStats(true);
    if (isClosed) return;
    isLoading.value = false;
  }
}
