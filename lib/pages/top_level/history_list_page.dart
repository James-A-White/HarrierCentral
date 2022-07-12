// @dart=2.11
import 'package:harrier_central/imports.dart';

final GlobalKey<HistoryListPageState> historyListPageKey = GlobalKey<HistoryListPageState>();

class HistoryListPage extends StatefulWidget {
  HistoryListPage() : super(key: historyListPageKey);

  @override
  HistoryListPageState createState() => HistoryListPageState();
}

class HistoryListResults {
  HistoryListResults({
    this.totalRunsThisKennel,
    this.totalHaringThisKennel,
    this.kennelName,
    this.kennelShortName,
    this.kennelId,
    this.kennelLogo,
    this.historicalTotalRunCount,
    this.historicalHaringCount,
    this.historicalCountIsEstimate,
    this.following,
  });

  final int totalRunsThisKennel;
  final int totalHaringThisKennel;
  final String kennelName;
  final String kennelShortName;
  final String kennelId;
  final String kennelLogo;
  final int historicalHaringCount;
  final int historicalTotalRunCount;
  final int historicalCountIsEstimate;
  final int following;

  static HistoryListResults fromMap(Map<String, dynamic> map) {
    final HistoryListResults item = HistoryListResults(
        totalRunsThisKennel: map['totalRunsThisKennel'],
        totalHaringThisKennel: map['totalHaringThisKennel'],
        kennelId: map['kennelId'],
        historicalTotalRunCount: map['historicalTotalRunCount'],
        historicalHaringCount: map['historicalHaringCount'],
        historicalCountIsEstimate: map['historicalCountIsEstimate'],
        kennelLogo: map['kennelLogo'],
        kennelName: map['kennelName'],
        kennelShortName: map['kennelShortName'],
        following: map['following']);
    return item;
  }
}

class HistoryListPageState extends State<HistoryListPage> {
  HistoryListPageState();

  bool _isLoading = false;
  int _totalRuns = 0;
  int _totalHaring = 0;

  List<HistoryListResults> _runCountsList = <HistoryListResults>[];

  @override
  void initState() {
    refreshRunHistoryFromTable(true);
    //_handleRefresh();
    super.initState();
  }

  Future<void> refreshRunHistoryFromTable(bool forceRefresh) async {
    final String userId = getStringPref(StringPrefsEnum.userId);

    final String query = '''  
          SELECT 
          coalesce(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalTotalRunCount} + hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHcTotalRunCount},0) as totalRunsThisKennel,
          coalesce(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalHaringCount} + ${G0<TableModel>().hasherKennelMapTableHelper.colHcHaringCount},0) as totalHaringThisKennel,
          k.${G0<TableModel>().kennelsTableHelper.colKennelShortName},
          k.${G0<TableModel>().kennelsTableHelper.colKennelName},
          k.${G0<TableModel>().kennelsTableHelper.colKennelId},
          k.${G0<TableModel>().kennelsTableHelper.colKennelLogo},
          coalesce(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalTotalRunCount},0) as ${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalTotalRunCount},
          coalesce(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalHaringCount},0) as ${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalHaringCount},
          coalesce(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalCountIsEstimate},0) as ${G0<TableModel>().hasherKennelMapTableHelper.colHistoricalCountIsEstimate},
          coalesce(hkm.${G0<TableModel>().hasherKennelMapTableHelper.colFollowing},0) as ${G0<TableModel>().hasherKennelMapTableHelper.colFollowing}
          FROM ${G0<TableModel>().kennelsTableHelper.getTableName(AppDomainType.user)} k
          LEFT OUTER JOIN ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.user)} hkm on hkm.${G0<TableModel>().hasherKennelMapTableHelper.colUserId} = "$userId"  and hkm.${G0<TableModel>().hasherKennelMapTableHelper.colKennelId} = k.${G0<TableModel>().kennelsTableHelper.colKennelId}
          ORDER BY totalRunsThisKennel desc
          ''';

    _runCountsList = <HistoryListResults>[];
    try {
      final List<Map<String, dynamic>> results = await G0<Database>().rawQuery(query);

      _totalHaring = 0;
      _totalRuns = 0;

      for (int i = 0; i < results.length; i++) {
        final HistoryListResults hlrItem = HistoryListResults.fromMap(results[i]);
        _totalHaring += hlrItem.totalHaringThisKennel;
        _totalRuns += hlrItem.totalRunsThisKennel;
        if (((hlrItem.totalRunsThisKennel ?? 0) > 0) || (hlrItem.following == 1)) {
          _runCountsList.add(hlrItem);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _isLoading ? _buildCircularProgressIndicator() : _buildListView());
  }

  Widget _buildCircularProgressIndicator() {
    return const Center(
      child: HcCircularProgressIndicator(key: Key('600193968')),
    );
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isLoading = true;
    });

    await G0<TableModel>().syncUserDataService.updateFromBackend(
          SyncUserDataService.flagHasherEventMapTable | SyncUserDataService.flagHasherKennelMapTable | SyncUserDataService.flagNarrowEventsTable | SyncUserDataService.flagKennelsTable,
          true,
          debugText: 'history_list_page: HEM,HKM,Events,Kennels',
        );
    //final String resultStr = result ? 'successfully' : 'unsuccessfully';
    //print('Hasher data synchronized $resultStr');
    await refreshRunHistoryFromTable(true);
    setState(() {
      _isLoading = false;
    });
  }

  TextStyle headingStyle = const TextStyle(fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 22.0, height: 0.6);

  Widget _buildListView() {
    final String _photo = getStringPref(StringPrefsEnum.profilePhotoUrl);
    return Stack(
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(top: 100),
          decoration: Backgrounds.defaultHcBackgroundLight(),
          padding: const EdgeInsets.only(top: 0.0),
          child: _runCountsList.isEmpty
              ? const Center(child: Text('No runs logged yet.'))
              : RefreshIndicator(
                  onRefresh: _handleRefresh,
                  displacement: 40.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Expanded(
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          //itemCount: runCountsList.length + 1,
                          itemCount: _runCountsList.length,
                          padding: const EdgeInsets.only(top: 20),
                          itemExtent: 100.0,
                          itemBuilder: (BuildContext context, int index) {
                            // if (index == 0) {
                            //   return KennelRunHistoryMyRunsItem(refreshCounters: () {
                            //       refreshRunHistoryFromTable(true);
                            //     },);
                            // } else {

                            return KennelRunHistoryCountListItem(
                              kennelInfo: _runCountsList[index],
                              refreshCounters: (String kennelId) async {
                                await refreshRunHistoryFromTable(true);
                                if ((kennelId != null) && (kennelId.isNotEmpty)) {
                                  for (int i = 0; i < _runCountsList.length; i++)
                                    if (_runCountsList[i].kennelId == kennelId) {
                                      return _runCountsList[i];
                                    }
                                }
                              },
                            );
                            //}
                          },
                        ),
                      ),
                    ],
                  )),
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
                    ProfilePhoto(leftPadding: 20.0, photoHeight: 80.0, profilePhotoUrl: _photo),
                    const SizedBox(width: 20),
                    (_runCountsList == null || _runCountsList.isEmpty)
                        ? Container()
                        : Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                            const Text(
                              'My total run counts',
                              style: TextStyle(color: Colors.black87, fontFamily: 'AvenirNextBold', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.2),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'Total runs: ' + _totalRuns.toString(),
                              style: const TextStyle(color: Colors.black87, fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.2),
                              textAlign: TextAlign.left,
                            ),
                            Text(
                              'Total times hared: ' + _totalHaring.toString(),
                              style: const TextStyle(color: Colors.black87, fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.2),
                              textAlign: TextAlign.left,
                            ),
                          ])
                  ],
                ))),
      ],
    );
  }
}
