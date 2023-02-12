// @dart=2.11
// ignore_for_file: constant_identifier_names

import 'package:harrier_central/imports.dart';

class DrinksList extends StatefulWidget {
  const DrinksList({Key key, @required this.eventAggregate}) : super(key: key);

  final RunAdminAggregate eventAggregate;

  @override
  DrinksListState createState() => DrinksListState();
}

class DrinksResults {
  DrinksResults({
    this.hasherId,
    this.dispName,
    this.nameForSort,
    this.photo,
    this.totalRunsThisKennel,
    this.totalHaringThisKennel,
    this.specialRunCount,
    this.specialHaringCount,
  });

  final String hasherId;
  final String dispName;
  final String nameForSort;
  final String photo;
  final int totalRunsThisKennel;
  final int totalHaringThisKennel;
  int specialRunCount;
  int specialHaringCount;

  static DrinksResults fromMap(Map<String, dynamic> map) {
    final DrinksResults item = DrinksResults(
      hasherId: map['hasherId'],
      dispName: map['dispName'],
      nameForSort: map['nameForSort'],
      photo: map['photo'],
      totalRunsThisKennel: map['totalRunsThisKennel'],
      totalHaringThisKennel: map['totalHaringThisKennel'],
      specialHaringCount: 0,
      specialRunCount: 0,
    );
    return item;
  }
}

// Mismanagement get mismanagement {
//   return Mismanagement(mismanagementRoles);
// }

// AppAccess get appAccess {
//   return AppAccess(appAccessFlags);
// }
//}

class DrinksListState extends State<DrinksList> with SingleTickerProviderStateMixin {
  DrinksListState();

  bool _isLoading = false;

  final int LIST_ITEM_HEIGHT = 84;
  final int LIST_ITEM_ELEMENT_HEIGHT = 84;

  final List<DrinksResults> _awards = <DrinksResults>[];

  Future<void> _refreshSqlTablesFromBackend(bool showLoadingIndicator) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus.connected) {
      if (showLoadingIndicator) {
        setState(() {
          _isLoading = true;
        });
      }

      await G0<TableModel>().syncEventAdminService.updateFromBackend(
          SyncEventAdminService.flagHashersTable | SyncEventAdminService.flagPaymentsTable | SyncEventAdminService.flagHasherEventMapTable | SyncEventAdminService.flagHasherKennelMapTable,
          true,
          widget.eventAggregate.event.eventId);
      //final String resultStr = result ? 'successfully' : 'unsuccessfully';
      //print('Payments data synchronized $resultStr');

      await _refreshDrinksFromTable(true);

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    appBar = AppBar(
      centerTitle: true,
      backgroundColor: themeAppBarBackground,
      title: const Text(
        'Awards',
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );

    _refreshSqlTablesFromBackend(true);

    super.initState();
  }

  Future<void> _refreshDrinksFromTable(bool forceRefresh) async {
    final String query = ''' 
        SELECT 
          h.${G0<TableModel>().hashersTableHelper.colHasherId},
          coalesce(
            hem.${G0<TableModel>().hasherEventMapTableHelper.colDisplayName},
            h.${G0<TableModel>().hashersTableHelper.colDispName},
            h.${G0<TableModel>().hashersTableHelper.colHashName},
            h.${G0<TableModel>().hashersTableHelper.colFirstName} || " " || h.${G0<TableModel>().hashersTableHelper.colLastName},"<no name>") as dispName,
          lower(" " || coalesce(h.${G0<TableModel>().hashersTableHelper.colHashName},"") || " " || coalesce(h.${G0<TableModel>().hashersTableHelper.colDispName},"") || " " || coalesce(h.${G0<TableModel>().hashersTableHelper.colFirstName},"") || " " || coalesce(h.${G0<TableModel>().hashersTableHelper.colLastName},"") || " ") as nameForSort,
          h.${G0<TableModel>().hashersTableHelper.colPhoto},         
          coalesce(hem.${G0<TableModel>().hasherEventMapTableHelper.colTotalHaringThisKennel},0) as totalHaringThisKennel,
          coalesce(hem.${G0<TableModel>().hasherEventMapTableHelper.colTotalRunsThisKennel},0) as totalRunsThisKennel
          FROM ${G0<TableModel>().hasherEventMapTableHelper.getTableName(AppDomainType.event)} hem 
          INNER JOIN ${G0<TableModel>().hashersTableHelper.getTableName(AppDomainType.user)} h on hem.${G0<TableModel>().hasherEventMapTableHelper.colUserId} = h.${G0<TableModel>().hashersTableHelper.colHasherId}  
          WHERE hem.${G0<TableModel>().hasherEventMapTableHelper.colEventId} = '${widget.eventAggregate.event.eventId}' 
          AND hem.${G0<TableModel>().hasherEventMapTableHelper.colAttendenceState} >= 20
          AND h.${G0<TableModel>().hashersTableHelper.colRemoved} = 0 
          ORDER BY totalHaringThisKennel, totalRunsThisKennel
          ''';

    try {
      _awards.clear();

      final List<Map<String, dynamic>> results = await G0<Database>().rawQuery(query);
      for (int i = 0; i < results.length; i++) {
        final DrinksResults hlrItem = DrinksResults.fromMap(results[i]);

        hlrItem.specialRunCount = Utilities.checkSpecialRun(hlrItem.totalRunsThisKennel);

        hlrItem.specialHaringCount = Utilities.checkSpecialHaring(hlrItem.totalHaringThisKennel);

        if ((hlrItem.specialRunCount != specialRunNo) || (hlrItem.specialHaringCount != specialRunNo)) {
          _awards.add(hlrItem);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  String sortBySpeedDialLabel = '';
  IconData sortBySpeedDialIcon;
  EnumSortByType sortBySpeedDialType;

  AppBar appBar;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      key: _scaffoldKey,
      body: SafeArea(
        child: _isLoading
            ? const HcCircularProgressIndicator(key: Key('52039320'))
            : _awards.isEmpty
                ? Center(
                    child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Text('No awards yet for this Hash', textAlign: TextAlign.center, style: largeTitleStyle.copyWith(color: themeBackgroundColor)),
                  ))
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _awards.length,
                    separatorBuilder: (BuildContext context, int index) => const Divider(
                      height: 1.0,
                      color: Colors.black45,
                    ),
                    //padding: const EdgeInsets.only(top: 5),
                    // separatorBuilder: (BuildContext context, int index) => const Divider(
                    //   height: 1.0,
                    //   color: Colors.black45,
                    // ),

                    //itemExtent: 58.0,
                    //shrinkWrap: true,
                    itemBuilder: (BuildContext context, int index) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            height: LIST_ITEM_HEIGHT + .0,
                            width: 10.0,
                          ),
                          Utilities.getProfilePic(_awards[index].photo, LIST_ITEM_ELEMENT_HEIGHT, LIST_ITEM_ELEMENT_HEIGHT, context, _awards[index].dispName),
                          Expanded(
                              child: Column(
                            children: <Widget>[
                              FittedBox(
                                child: Text(
                                  _awards[index].dispName,
                                  style: const TextStyle(fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 25.0, height: 1.0),
                                ),
                              ),
                              if (_awards[index].specialRunCount == 1) ...<Widget>[
                                const FittedBox(
                                  child: Text(
                                    '1 run',
                                    style: TextStyle(fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 25.0, height: 1.0),
                                  ),
                                ),
                              ],
                              if (_awards[index].specialRunCount > 1) ...<Widget>[
                                FittedBox(
                                  child: Text(
                                    '${_awards[index].totalRunsThisKennel.toString()} runs',
                                    style: const TextStyle(fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 25.0, height: 1.0),
                                  ),
                                ),
                              ],
                              if (_awards[index].specialHaringCount == 1) ...<Widget>[
                                const FittedBox(
                                  child: Text(
                                    'First time haring',
                                    style: TextStyle(fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 25.0, height: 1.0),
                                  ),
                                ),
                              ],
                              if (_awards[index].specialHaringCount > 1) ...<Widget>[
                                FittedBox(
                                  child: Text(
                                    '${_awards[index].totalHaringThisKennel.toString()} hared runs',
                                    style: const TextStyle(fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 25.0, height: 1.0),
                                  ),
                                ),
                              ],
                            ],
                          )),
                          if (_awards[index].specialRunCount > 0) ...<Widget>[
                            Image.asset(
                              'images/run_count_icons/run_${_awards[index].specialRunCount}.png',
                              height: LIST_ITEM_ELEMENT_HEIGHT + .0,
                              width: LIST_ITEM_ELEMENT_HEIGHT + .0,
                            ),
                          ],
                          if (_awards[index].specialHaringCount > 0) ...<Widget>[
                            Image.asset(
                              'images/run_count_icons/rabbit_with_beer.png',
                              height: LIST_ITEM_ELEMENT_HEIGHT + .0,
                              width: LIST_ITEM_ELEMENT_HEIGHT + .0,
                            ),
                          ],
                          const Divider()
                        ],
                      );

                      // return Container(
                      //   height: 120.0,
                      //   child: ListTile(
                      //     dense: false,
                      //     visualDensity: VisualDensity(vertical: 4), // to expand
                      //     leading: SizedBox(height: 120.0, child: Utilities.getProfilePic(_awards[index].photo, 120.0, 120.0)),
                      //     title: Text(_awards[index].dispName),
                      //   ),
                      // );
                    },
                  ),
      ),
    );
  }
}
