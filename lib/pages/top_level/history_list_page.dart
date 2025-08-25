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
      countryId: map['countryId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'runCount': runCount,
      'hareCount': hareCount,
      'countryName': countryName,
      'flagFile': flagFile,
    };
  }
}

final GlobalKey<HistoryListPageState> historyListPageKey =
    GlobalKey<HistoryListPageState>();

class HistoryListPage extends StatefulWidget {
  HistoryListPage() : super(key: historyListPageKey);

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    refreshRunHistoryFromTable(true);
    refreshStatsFromTable(true);
  }

  Future<void> refreshStatsFromTable(bool forceRefresh) async {
    final String hcRunsQuery = '''
          SELECT
          COUNT(case when hem.${tableModel.hasherEventMapTableHelper.colAttendenceState} >= ${attendenceAtHash.value} then 1 else null end) as runCount,
          COUNT(case when hem.${tableModel.hasherEventMapTableHelper.colIsHare} != 0 AND hem.${tableModel.hasherEventMapTableHelper.colAttendenceState} >= ${attendenceAtHash.value} then 1 else null end) as hareCount,
          countries.${tableModel.countriesTableHelper.colCountryName},
          countries.${tableModel.countriesTableHelper.colCountryId},
          countries.${tableModel.countriesTableHelper.colFlagFile}
          FROM ${tableModel.hasherEventMapTableHelper.getTableName(AppDomainType.user)} hem
          INNER JOIN ${tableModel.countriesTableHelper.getTableName(AppDomainType.user)} countries on hem.${tableModel.hasherEventMapTableHelper.colCountryId} = countries.${tableModel.countriesTableHelper.colCountryId}
          INNER JOIN ${tableModel.eventsTableHelper.getTableName(AppDomainType.user)} evt on hem.${tableModel.hasherEventMapTableHelper.colEventId} = evt.${tableModel.eventsTableHelper.colEventId}
          WHERE evt.${tableModel.eventsTableHelper.colRemoved} = 0 
          AND evt.${tableModel.eventsTableHelper.colIsCountedRun} != 0
          AND evt.${tableModel.eventsTableHelper.colIsVisible} != 0
          AND evt.${tableModel.eventsTableHelper.colEventStartDatetime} <= DateTime('now') 
          GROUP BY countries.${tableModel.countriesTableHelper.colCountryName}, countries.${tableModel.countriesTableHelper.colFlagFile}
          ORDER BY runCount desc
          ''';

    final String historicalRunsQuery = '''
          SELECT
          SUM(hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalTotalRunCount}) as runCount,
          SUM(hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalHaringCount})  as hareCount,
          countries.${tableModel.countriesTableHelper.colCountryName},
          countries.${tableModel.countriesTableHelper.colCountryId},
          countries.${tableModel.countriesTableHelper.colFlagFile}
          FROM ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.user)} hkm
          INNER JOIN ${tableModel.kennelsTableHelper.getTableName(AppDomainType.user)} ken on hkm.${tableModel.hasherKennelMapTableHelper.colKennelId} = ken.${tableModel.kennelsTableHelper.colKennelId}
          INNER JOIN ${tableModel.countriesTableHelper.getTableName(AppDomainType.user)} countries on ken.${tableModel.kennelsTableHelper.colCountryId} = countries.${tableModel.countriesTableHelper.colCountryId}
          GROUP BY countries.${tableModel.countriesTableHelper.colCountryName}, countries.${tableModel.countriesTableHelper.colFlagFile}
          ORDER BY runCount desc
          ''';

    // final String query = '''
    //       SELECT
    //       10 as runCount,
    //       5 as hareCount,
    //       countries.${tableModel.countriesTableHelper.colCountryName},
    //       countries.${tableModel.countriesTableHelper.colFlagFile}
    //       FROM ${tableModel.countriesTableHelper.getTableName(AppDomainType.user)}
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

          _runCountsListByCountry[historicItem.countryName] = (historicItem);
        }
      }

      for (int i = 0; i < hcResults.length; i++) {
        final CountryStats hcItem = CountryStats.fromMap(hcResults[i]);

        if (hcItem.runCount > 0) {
          // print(
          //   'HC - Country = ${hcItem.countryName} / Count = ${hcItem.runCount} / Hare = ${hcItem.hareCount}',
          // );

          if (_runCountsListByCountry[hcItem.countryName] != null) {
            _runCountsListByCountry[hcItem.countryName]!.hareCount +=
                hcItem.hareCount;
            _runCountsListByCountry[hcItem.countryName]!.runCount +=
                hcItem.runCount;
          } else {
            _runCountsListByCountry[hcItem.countryName] = hcItem;
          }
        }
      }

      // if (forceRefresh && (i == results.length - 1)) {
      //   setState(() {});
      // }
      //}
    } catch (e) {
      //print(e);
    }
  }

  Future<void> refreshRunHistoryFromTable(bool forceRefresh) async {
    final String userId = getStringPref(StringPrefsEnum.userId)!;

    final String query = '''
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
          FROM ${tableModel.kennelsTableHelper.getTableName(AppDomainType.user)} k
          INNER JOIN ${tableModel.countriesTableHelper.getTableName(AppDomainType.user)} c on c.${tableModel.countriesTableHelper.colCountryId} = k.${tableModel.kennelsTableHelper.colCountryId}
          LEFT OUTER JOIN ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.user)} hkm on hkm.${tableModel.hasherKennelMapTableHelper.colUserId} = "$userId"  and hkm.${tableModel.hasherKennelMapTableHelper.colKennelId} = k.${tableModel.kennelsTableHelper.colKennelId}
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
          setState(() {
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
      setState(() {});
    } else if (_tabController.index != _tabController.previousIndex) {
      // This is triggered after the tab has finished changing.
      //print('Tab changed to index: ${_tabController.index}');
      //_refreshRunHistoryFromTable(true);
      setState(() {});
    }
  }

  Widget _buildCircularProgressIndicator() {
    return const Center(
      child: HcCircularProgressIndicator(key: Key('600193968')),
    );
  }

  Widget _buildCountryStatsList() {
    final sortedEntries =
        _runCountsListByCountry.entries.toList()
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
              await refreshRunHistoryFromTable(true);
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
    setState(() {
      _isLoading = true;
    });

    await tableModel.syncUserDataService.updateFromBackend(
      SyncUserDataService.flagHasherEventMapTable |
          SyncUserDataService.flagHasherKennelMapTable |
          SyncUserDataService.flagNarrowEventsTable |
          SyncUserDataService.flagKennelsTable,
      true,
      debugText: 'history_list_page: HEM,HKM,Events,Kennels',
    );
    //final String resultStr = result ? 'successfully' : 'unsuccessfully';
    //print('Hasher data synchronized $resultStr');
    await refreshRunHistoryFromTable(true);
    await refreshStatsFromTable(true);
    setState(() {
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
          child:
              _runCountsListByKennel.isEmpty
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
                              // reviewed for 2.0
                              child: TabBar(
                                onTap: (void _) {
                                  setState(() {});
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
                                          color:
                                              _tabController.index == 0
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
                                          color:
                                              _tabController.index == 1
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
            width: MediaQuery.of(context).size.width,
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
    return Scaffold(
      body: _isLoading ? _buildCircularProgressIndicator() : _buildListView(),
    );
  }
}
