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

// final GlobalKey<HistoryListPageState> historyListPageKey =
//     GlobalKey<HistoryListPageState>();

class HistoryListPage extends StatefulWidget {
  const HistoryListPage({super.key});

  @override
  HistoryListPageState createState() => HistoryListPageState();
}

class HistoryListPageState extends State<HistoryListPage>
    with SingleTickerProviderStateMixin {
  HistoryListPageState();

  bool _isLoading = false;
  List<RunHistoryModel> _runCountsListByKennel = <RunHistoryModel>[];
  Map<String, CountryStats> _runCountsListByCountry = <String, CountryStats>{};
  late TabController _tabController;
  int _totalHaring = 0;
  int _totalRuns = 0;
  StreamSubscription<DataChangeEvent>? _dataChangeSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);

    unawaited(setupInitialValues());

    // The History tab does its one-time load at boot against cached data. When
    // the returning-user background sync lands fresh data, re-read the stats.
    if (Get.isRegistered<DataChangeService>()) {
      _dataChangeSub = Get.find<DataChangeService>().stream.listen((event) {
        if (event.type == DataChangeType.fullSyncCompleted && mounted) {
          unawaited(setupInitialValues());
        }
      });
    }
  }

  @override
  void dispose() {
    unawaited(_dataChangeSub?.cancel());
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> setupInitialValues() async {
    await queryKennelStats(true);
    await queryCountryStats(true);
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

    // final String query = '''
    //       SELECT
    //       10 as runCount,
    //       5 as hareCount,
    //       countries.${tableModel.countriesTableHelper.colCountryName},
    //       countries.${tableModel.countriesTableHelper.colFlagFile}
    //       FROM ${EnumDataTables.countries.commonTableName}
    //       -- GROUP BY countries.${tableModel.countriesTableHelper.colCountryName}, countries.${tableModel.countriesTableHelper.colFlagFile}
    //       ORDER BY runCount desc
    //       ''';

    _runCountsListByCountry = <String, CountryStats>{};
    try {
      final List<Map<String, dynamic>> hcResults = await database.rawQuery(
        hcRunsQuery,
      );

      final List<Map<String, dynamic>> historicResults = await database
          .rawQuery(historicalRunsQuery);

      for (int i = 0; i < historicResults.length; i++) {
        final CountryStats historicItem = CountryStats.fromMap(
          historicResults[i],
        );
        if (historicItem.runCount > 0) {
          // print(
          //   'Historic - Country = ${historicItem.countryName} / Count = ${historicItem.runCount} / Hare = ${historicItem.hareCount}',
          // );

          _runCountsListByCountry[historicItem.countryId] = historicItem;
        }
      }

      for (int i = 0; i < hcResults.length; i++) {
        final CountryStats hcItem = CountryStats.fromMap(hcResults[i]);

        if (hcItem.runCount > 0) {
          // print(
          //   'HC - Country = ${hcItem.countryName} / Count = ${hcItem.runCount} / Hare = ${hcItem.hareCount}',
          // );

          if (_runCountsListByCountry[hcItem.countryId] != null) {
            _runCountsListByCountry[hcItem.countryId]!.hareCount +=
                hcItem.hareCount;
            _runCountsListByCountry[hcItem.countryId]!.runCount +=
                hcItem.runCount;
          } else {
            _runCountsListByCountry[hcItem.countryId] = hcItem;
          }
        }
      }

      // if (forceRefresh && (i == results.length - 1)) {
      //   setStateIfMounted(() {});
      // }
      //}
    } catch (e) {
      //print(e);
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

    _runCountsListByKennel = <RunHistoryModel>[];
    try {
      final List<Map<String, dynamic>> results = await database.rawQuery(query);

      _totalHaring = 0;
      _totalRuns = 0;

      for (int i = 0; i < results.length; i++) {
        final RunHistoryModel hlrItem = RunHistoryModel.fromMap(results[i]);
        _totalHaring += hlrItem.totalHaringThisKennel;
        _totalRuns += hlrItem.totalRunsThisKennel;
        if ((hlrItem.totalRunsThisKennel > 0) || (hlrItem.following == 1)) {
          _runCountsListByKennel.add(hlrItem);
        }

        if (forceRefresh && (i == results.length - 1)) {
          setStateIfMounted(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      //print(e);
    }
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      // This means the user tapped a new tab, but the animation hasn't finished yet.
      //print('Tab is changing to index: ${_tabController.index}');
      //_refreshRunHistoryFromTable(true);
      setStateIfMounted(() {});
    } else if (_tabController.index != _tabController.previousIndex) {
      // This is triggered after the tab has finished changing.
      //print('Tab changed to index: ${_tabController.index}');
      //_refreshRunHistoryFromTable(true);
      setStateIfMounted(() {});
    }
  }

  Widget _buildCircularProgressIndicator() {
    return const Center(
      child: HcAppCircularProgressIndicator(key: Key('600193968')),
    );
  }

  Widget _buildCountryStatsList() {
    final sortedEntries = _runCountsListByCountry.entries.toList()
      ..sort((b, a) => a.value.runCount.compareTo(b.value.runCount));

    return Expanded(
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        //itemCount: runCountsList.length + 1,
        itemCount: sortedEntries.length,
        padding: const EdgeInsets.only(top: 20),
        itemExtent: 100.0,
        itemBuilder: (BuildContext context, int index) {
          //String countryNameKey = _runCountsListByCountry.keys.elementAt(index);

          if (sortedEntries[index].value.runCount == 0) {
            return Container();
          }

          return CountryRunHistoryCountListItem(
            countryId: sortedEntries[index].value.countryId,
            countryName: sortedEntries[index].value.countryName,
            flagFile: sortedEntries[index].value.flagFile,
            runCount: sortedEntries[index].value.runCount,
            hareCount: sortedEntries[index].value.hareCount,
          );
          //}
        },
      ),
    );
  }

  Widget _buildKennelStatsList() {
    return Expanded(
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        //itemCount: runCountsList.length + 1,
        itemCount: _runCountsListByKennel.length,
        padding: const EdgeInsets.only(top: 20),
        itemExtent: 100.0,
        itemBuilder: (BuildContext context, int index) {
          // if (index == 0) {
          //   return KennelRunHistoryMyRunsItem(refreshCounters: () {
          //       refreshRunHistoryFromTable(true);
          //     },);
          // } else {

          return KennelRunHistoryCountListItem(
            kennelInfo: _runCountsListByKennel[index],
            refreshCounters: (String kennelId) async {
              await queryKennelStats(true);
              if (kennelId.isNotEmpty) {
                for (int i = 0; i < _runCountsListByKennel.length; i++) {
                  if (_runCountsListByKennel[i].kennelId == kennelId) {
                    return _runCountsListByKennel[i];
                  }
                }
              }
            },
          );
          //}
        },
      ),
    );
  }

  Future<void> _handleRefresh() async {
    setStateIfMounted(() {
      _isLoading = true;
    });

    await tableModel.syncUserDataService.updateFromBackend(
      EnumDataTables.hasherEventMap.flag |
          EnumDataTables.hasherKennelMap.flag |
          EnumDataTables.events.flag |
          EnumDataTables.kennels.flag,
      true,
      debugText: 'history_list_page: HEM,HKM,Events,Kennels',
    );
    //final String resultStr = result ? 'successfully' : 'unsuccessfully';
    //print('Hasher data synchronized $resultStr');
    await queryKennelStats(true);
    await queryCountryStats(true);
    setStateIfMounted(() {
      _isLoading = false;
    });
  }

  Widget _buildListView() {
    final String? photo = getStringPref(StringPrefsEnum.profilePhotoUrl);
    return Stack(
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(top: 85),
          decoration: Backgrounds.defaultHcBackgroundLight(),
          padding: const EdgeInsets.only(top: 0.0),
          child: _runCountsListByKennel.isEmpty
              ? Center(child: Text('No runs logged yet.', style: ts_title))
              : RefreshIndicator(
                  onRefresh: _handleRefresh,
                  displacement: 40.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Container(
                        //color: Colors.red,
                        width: 200,
                        padding: const EdgeInsets.only(
                          left: 30,
                          right: 30,
                          top: 10.0,
                        ),
                        child: DefaultTabController(
                          length: 2,
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            width: 140.0,
                            height: 75.0,
                            // reviewed for 2.0+
                            child: TabBar(
                              onTap: (void _) {
                                setStateIfMounted(() {});
                              },
                              labelStyle: ts_tabSelected,
                              unselectedLabelStyle: ts_tabUnselected,
                              isScrollable: false,
                              unselectedLabelColor: Colors.white,
                              labelColor: Colors.white,
                              labelPadding: const EdgeInsets.only(
                                top: 5,
                                left: 0,
                                right: 0,
                              ),
                              indicatorSize: TabBarIndicatorSize.label,
                              // labelPadding: EdgeInsets.symmetric(
                              //   horizontal: 20.0,
                              // ),
                              indicatorPadding: EdgeInsets.symmetric(
                                horizontal: -5.0,
                                vertical: 13.0,
                              ),
                              indicator: BoxDecoration(
                                color: hc_red,
                                borderRadius: BorderRadius.circular(999),
                              ),

                              tabs: <Tab>[
                                Tab(
                                  child: Container(
                                    alignment: Alignment.center,
                                    width: 140,
                                    child: Text(
                                      'By Kennel',
                                      style: ts_numberStyle.copyWith(
                                        color: _tabController.index == 0
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                Tab(
                                  child: Container(
                                    alignment: Alignment.center,
                                    width: 140,
                                    child: Text(
                                      'By Country',
                                      style: ts_numberStyle.copyWith(
                                        color: _tabController.index == 1
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              controller: _tabController,
                            ),
                          ),
                        ),
                      ),
                      _tabController.index == 0
                          ? _buildKennelStatsList()
                          : _buildCountryStatsList(),
                    ],
                  ),
                ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            decoration: const BoxDecoration(
              // border: new Border.all(width: 1.0, color: Colors.black),
              //shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Color.fromARGB(70, 0, 0, 0),
                  offset: Offset(0.0, 6.0),
                  blurRadius: 10.0,
                ),
              ],
            ),
            height: 100,
            width: MediaQuery.sizeOf(context).width,
            child: Row(
              children: <Widget>[
                ProfilePhoto(
                  leftPadding: 20.0,
                  photoHeight: 80.0,
                  profilePhotoUrl: photo,
                ),
                const SizedBox(width: 20),
                _runCountsListByKennel.isEmpty
                    ? Container()
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'My total run counts',
                            style: ts_titleMediumBold.copyWith(
                              height: 1.2,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Total runs: $_totalRuns',
                            style: ts_titleMedium.copyWith(
                              height: 1.2,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.left,
                          ),
                          Text(
                            'Total times hared: $_totalHaring',
                            style: ts_titleMedium.copyWith(
                              height: 1.2,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: _isLoading ? _buildCircularProgressIndicator() : _buildListView(),
    );
  }
}
