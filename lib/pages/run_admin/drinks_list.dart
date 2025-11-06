// ignore_for_file: constant_identifier_names

import 'package:harrier_central/imports.dart';

class DrinksList extends StatefulWidget {
  const DrinksList({super.key, required this.eventAggregate});

  final RunAdminAggregate eventAggregate;

  @override
  DrinksListState createState() => DrinksListState();
}

class DrinksResults {
  DrinksResults({
    required this.hasherId,
    required this.dispName,
    required this.nameForSort,
    required this.photo,
    required this.totalRunsThisKennel,
    required this.totalHaringThisKennel,
    this.specialRunCount = 0,
    this.specialHaringCount = 0,
    this.isHare = 0,
  });

  final String hasherId;
  final String dispName;
  final String nameForSort;
  final String photo;
  final int totalRunsThisKennel;
  final int totalHaringThisKennel;
  int specialRunCount;
  int specialHaringCount;
  int isHare;

  static DrinksResults fromMap(Map<String, dynamic> map) {
    final DrinksResults item = DrinksResults(
      hasherId: map['hasherId'],
      dispName: map['dispName'],
      nameForSort: map['nameForSort'],
      photo: map['photo'],
      totalRunsThisKennel: map['totalRunsThisKennel'],
      totalHaringThisKennel: map['totalHaringThisKennel'],
      isHare: map['isHare'],
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

class DrinksListState extends State<DrinksList>
    with SingleTickerProviderStateMixin {
  DrinksListState();

  bool _isLoading = false;

  // ignore: non_constant_identifier_names
  final double LIST_ITEM_HEIGHT = 84.0;
  // ignore: non_constant_identifier_names
  final double LIST_ITEM_ELEMENT_HEIGHT = 84.0;

  final List<DrinksResults> _awards = <DrinksResults>[];

  Future<void> _refreshSqlTablesFromBackend(bool showLoadingIndicator) async {
    if (Utilities.isConnected()) {
      if (showLoadingIndicator) {
        setState(() {
          _isLoading = true;
        });
      }

      await tableModel.syncEventAdminService.updateFromBackend(
        SyncEventAdminService.flagHashersTable |
            SyncEventAdminService.flagPaymentsTable |
            SyncEventAdminService.flagHasherEventMapTable |
            SyncEventAdminService.flagHasherKennelMapTable,
        true,
        widget.eventAggregate.event.eventId,
      );
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
      iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
      title: Text('Drink chug-a-lug', style: ts_appBarTitle),
    );

    _refreshSqlTablesFromBackend(true);

    super.initState();
  }

  Future<void> _refreshDrinksFromTable(bool forceRefresh) async {
    final String query =
        '''
        SELECT 
          h.${tableModel.hashersTableHelper.colHasherId},
          coalesce(
            hem.${tableModel.hasherEventMapTableHelper.colDisplayName},
            h.${tableModel.hashersTableHelper.colDispName},
            h.${tableModel.hashersTableHelper.colHashName},
            h.${tableModel.hashersTableHelper.colFirstName} || " " || h.${tableModel.hashersTableHelper.colLastName},"<no name>") as dispName,
          lower(" " || coalesce(h.${tableModel.hashersTableHelper.colHashName},"") || " " || coalesce(h.${tableModel.hashersTableHelper.colDispName},"") || " " || coalesce(h.${tableModel.hashersTableHelper.colFirstName},"") || " " || coalesce(h.${tableModel.hashersTableHelper.colLastName},"") || " ") as nameForSort,
          h.${tableModel.hashersTableHelper.colPhoto},         
          coalesce(hem.${tableModel.hasherEventMapTableHelper.colTotalHaringThisKennel},0) 
          + coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalHaringCount},0)
          as totalHaringThisKennel,
          coalesce(hem.${tableModel.hasherEventMapTableHelper.colTotalRunsThisKennel},0) 
          + coalesce(hkm.${tableModel.hasherKennelMapTableHelper.colHistoricalTotalRunCount},0)
          as totalRunsThisKennel,
          hem.${tableModel.hasherEventMapTableHelper.colIsHare}
          FROM ${tableModel.hasherEventMapTableHelper.getTableName(AppDomainType.event)} hem 
          INNER JOIN ${tableModel.hashersTableHelper.getTableName(AppDomainType.user)} h on hem.${tableModel.hasherEventMapTableHelper.colUserId} = h.${tableModel.hashersTableHelper.colHasherId}  
          LEFT OUTER JOIN ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.event)} hkm on hkm.${tableModel.hasherKennelMapTableHelper.colUserId} = h.${tableModel.hashersTableHelper.colHasherId} AND hkm.${tableModel.hasherKennelMapTableHelper.colKennelId} = hem.${tableModel.hasherEventMapTableHelper.colEventKennelId}
          WHERE hem.${tableModel.hasherEventMapTableHelper.colEventId} = '${widget.eventAggregate.event.eventId}' 
          AND hem.${tableModel.hasherEventMapTableHelper.colAttendenceState} >= 20
          AND h.${tableModel.hashersTableHelper.colRemoved} = 0 
          AND h.${tableModel.hashersTableHelper.colHashName} not like '👣 Anonymous%' 
          ORDER BY totalHaringThisKennel, totalRunsThisKennel
          ''';

    try {
      _awards.clear();

      final List<Map<String, dynamic>> results = await database.rawQuery(query);
      for (int i = 0; i < results.length; i++) {
        final DrinksResults hlrItem = DrinksResults.fromMap(results[i]);

        hlrItem.specialRunCount = Utilities.checkSpecialRun(
          hlrItem.totalRunsThisKennel,
        );

        if (hlrItem.isHare == 1) {
          hlrItem.specialHaringCount = Utilities.checkSpecialHaring(
            hlrItem.totalHaringThisKennel,
          );
        }

        if ((hlrItem.specialRunCount != specialRunNo) ||
            (hlrItem.specialHaringCount != specialRunNo)) {
          _awards.add(hlrItem);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  late AppBar appBar;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: appBar,
      body: SafeArea(
        child: Container(
          decoration: Backgrounds.defaultHcBackgroundLight(),
          child: _isLoading
              ? const HcAppCircularProgressIndicator(key: Key('52039320'))
              : _awards.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Text(
                      'No awards yet for this Hash',
                      textAlign: TextAlign.center,
                      style: ts_headingVeryLarge.copyWith(
                        color: themeBackgroundColor,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _awards.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const Divider(height: 1.0, color: Colors.black45),
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
                        SizedBox(height: LIST_ITEM_HEIGHT, width: 10.0),
                        Utilities.getProfilePic(
                          _awards[index].photo,
                          LIST_ITEM_ELEMENT_HEIGHT,
                          LIST_ITEM_ELEMENT_HEIGHT,
                          context,
                          _awards[index].dispName,
                        ),
                        Expanded(
                          child: Column(
                            children: <Widget>[
                              FittedBox(
                                child: Text(
                                  _awards[index].dispName,
                                  style: ts_titleLargeCondensedBlack,
                                ),
                              ),
                              if (_awards[index].specialRunCount ==
                                  1) ...<Widget>[
                                FittedBox(
                                  child: Text(
                                    '1 run',
                                    style: ts_titleLargeCondensedBlack,
                                  ),
                                ),
                              ],
                              if (_awards[index].specialRunCount >
                                  1) ...<Widget>[
                                FittedBox(
                                  child: Text(
                                    '${_awards[index].totalRunsThisKennel.toString()} runs',
                                    style: ts_titleLargeCondensedBlack,
                                  ),
                                ),
                              ],
                              if (_awards[index].specialHaringCount ==
                                  1) ...<Widget>[
                                FittedBox(
                                  child: Text(
                                    'First time haring',
                                    style: ts_titleLargeCondensedBlack,
                                  ),
                                ),
                              ],
                              if (_awards[index].specialHaringCount >
                                  1) ...<Widget>[
                                FittedBox(
                                  child: Text(
                                    '${_awards[index].totalHaringThisKennel.toString()} hared runs',
                                    style: ts_titleLargeCondensedBlack,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (_awards[index].specialRunCount > 0) ...<Widget>[
                          Image.asset(
                            'images/run_count_icons/run_${_awards[index].specialRunCount}.png',
                            height: LIST_ITEM_ELEMENT_HEIGHT,
                            width: LIST_ITEM_ELEMENT_HEIGHT,
                          ),
                        ],
                        if (_awards[index].specialHaringCount > 0) ...<Widget>[
                          Image.asset(
                            'images/run_count_icons/rabbit_with_beer.png',
                            height: LIST_ITEM_ELEMENT_HEIGHT,
                            width: LIST_ITEM_ELEMENT_HEIGHT,
                          ),
                        ],
                        const Divider(),
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
      ),
    );
  }
}
