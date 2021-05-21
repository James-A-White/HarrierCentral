import 'dart:async';

import 'package:flutter/material.dart';

import 'package:harrier_central/widgets/kennel_run_history_count_list_item.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/data/hc3_services/sync_user_data_service.dart';

import 'package:harrier_central/util/globals.dart';
import 'package:ive_flutter_core/widgets/circular_progress_indicator.dart';
import 'package:harrier_central/widgets/profile_photo.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:ive_flutter_core/util/core_utilities.dart';

//import 'package:auto_size_text/auto_size_text.dart';

class HistoryListPage extends StatefulWidget {
  const HistoryListPage({Key key}) : super(key: key);

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
    this.historicalPackRunCount,
    this.historicalHaringCount,
    this.historicalCountIsEstimate,
  });

  final int totalRunsThisKennel;
  final int totalHaringThisKennel;
  final String kennelName;
  final String kennelShortName;
  final String kennelId;
  final String kennelLogo;
  final int historicalHaringCount;
  final int historicalPackRunCount;
  final int historicalCountIsEstimate;

  static HistoryListResults fromMap(Map<String, dynamic> map) {
    final HistoryListResults item = HistoryListResults(
        totalRunsThisKennel: map['totalRunsThisKennel'],
        totalHaringThisKennel: map['totalHaringThisKennel'],
        kennelId: map['kennelId'],
        historicalPackRunCount: map['historicalPackRunCount'],
        historicalHaringCount: map['historicalHaringCount'],
        historicalCountIsEstimate: map['historicalCountIsEstimate'],
        kennelLogo: map['kennelLogo'],
        kennelName: map['kennelName'],
        kennelShortName: map['kennelShortName']);
    return item;
  }
}

class HistoryListPageState extends State<HistoryListPage> {
  HistoryListPageState();

  bool _isLoading = false;
  int _totalRuns = 0;
  int _totalHaring = 0;

  List<HistoryListResults> runCountsList = <HistoryListResults>[];

  @override
  void initState() {
    refreshRunHistoryFromTable(true);
    //_handleRefresh();
    super.initState();
  }

  Future<void> refreshRunHistoryFromTable(bool forceRefresh) async {
    final String userId = getStringPref(StringPrefsEnum.userId);

    final String query = '''  
          SELECT count(case when hem.attendenceState >= 20 then 1 else null end) + coalesce(hkm.historicalPackRunCount,0) as totalRunsThisKennel,
          count(case when hem.isHare = 1 then 1 else null end) + coalesce(hkm.historicalHaringCount,0) as totalHaringThisKennel,
          k.kennelShortName,
          k.kennelName,
          k.kennelId,
          k.kennelLogo,
          coalesce(hkm.historicalPackRunCount,0) as historicalPackRunCount,
          coalesce(hkm.historicalHaringCount,0) as historicalHaringCount,
          coalesce(hkm.historicalCountIsEstimate,0) as historicalCountIsEstimate
          FROM hasherEventMap hem
          INNER JOIN narrowEvents e on hem.eventId = e.eventId
          INNER JOIN kennels k on k.kennelId = e.kennelId
          LEFT OUTER JOIN hasherKennelMap hkm on hkm.userId = "$userId"  and hkm.kennelId = k.kennelId
          WHERE hem.userId = "$userId" AND e.isCountedRun = 1 AND e.isVisible = 1
          GROUP BY k.kennelId, k.kennelLogo,k.kennelShortName,k.kennelName
          ORDER BY totalRunsThisKennel desc
          ''';

    runCountsList = <HistoryListResults>[];
    try {
      final List<Map<String, dynamic>> results =
          await internalSqlDb.rawQuery(query);

      _totalHaring = 0;
      _totalRuns = 0;

      for (int i = 0; i < results.length; i++) {
        final HistoryListResults hlrItem =
            HistoryListResults.fromMap(results[i]);
        _totalHaring += hlrItem.totalHaringThisKennel;
        _totalRuns += hlrItem.totalRunsThisKennel;
        runCountsList.add(hlrItem);

        if (forceRefresh && (i == results.length - 1)) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body:
            _isLoading ? _buildCircularProgressIndicator() : _buildListView());
  }

  Widget _buildCircularProgressIndicator() {
    return const Center(
      child: HcCircularProgressIndicator(),
    );
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isLoading = true;
    });

    final bool result = await syncUserDataService.updateFromBackend(
        SyncUserDataService.flagHasherEventMapTable |
            SyncUserDataService.flagNarrowEventsTable |
            SyncUserDataService.flagKennelsTable,
        true);
    final String resultStr = result ? 'successfully' : 'unsuccessfully';
    print('Hasher data synchronized $resultStr');
    refreshRunHistoryFromTable(true);
  }

  TextStyle headingStyle = const TextStyle(
      fontFamily: 'AvenirNextCondensedDemiBold',
      fontStyle: FontStyle.normal,
      fontSize: 22.0,
      height: 0.6);

  Widget _buildListView() {
    final String _photo = getStringPref(StringPrefsEnum.profilePhotoUrl);
    return Stack(
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(top: 100),
          decoration: Backgrounds.defaultHcBackgroundLight(),
          padding: const EdgeInsets.only(top: 0.0),
          child: runCountsList.isEmpty
              ? const Center(child: Text('No runs logged yet.'))
              : RefreshIndicator(
                  onRefresh: () => _handleRefresh(),
                  displacement: 40.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Expanded(
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          //itemCount: runCountsList.length + 1,
                          itemCount: runCountsList.length,
                          padding: const EdgeInsets.only(top: 20),
                          itemExtent: 100.0,
                          itemBuilder: (BuildContext context, int index) {
                            // if (index == 0) {
                            //   return KennelRunHistoryMyRunsItem(refreshCounters: () {
                            //       refreshRunHistoryFromTable(true);
                            //     },);
                            // } else {

                            return KennelRunHistoryCountListItem(
                              //kennelInfo: runCountsList[index - 1],
                              kennelInfo: runCountsList[index],
                              refreshCounters: () {
                                refreshRunHistoryFromTable(true);
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
                    ProfilePhoto(
                        leftPadding: 20.0,
                        photoHeight: 80.0,
                        profilePhotoUrl: _photo),
                    const SizedBox(width: 20),
                    (runCountsList == null || runCountsList.isEmpty)
                        ? Container()
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                                const Text(
                                  'My total run counts',
                                  style: TextStyle(
                                      color: Colors.black87,
                                      fontFamily: 'AvenirNextBold',
                                      fontStyle: FontStyle.normal,
                                      fontSize: 18.0,
                                      height: 1.2),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  'Total runs: ' + _totalRuns.toString(),
                                  style: const TextStyle(
                                      color: Colors.black87,
                                      fontFamily: 'AvenirNextDemiBold',
                                      fontStyle: FontStyle.normal,
                                      fontSize: 18.0,
                                      height: 1.2),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  'Total times hared: ' +
                                      _totalHaring.toString(),
                                  style: const TextStyle(
                                      color: Colors.black87,
                                      fontFamily: 'AvenirNextDemiBold',
                                      fontStyle: FontStyle.normal,
                                      fontSize: 18.0,
                                      height: 1.2),
                                  textAlign: TextAlign.left,
                                ),
                              ])
                  ],
                ))),
      ],
    );
  }
}
