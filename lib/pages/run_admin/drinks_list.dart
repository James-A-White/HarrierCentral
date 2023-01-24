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
        ' Members',
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
          coalesce(h.${G0<TableModel>().hashersTableHelper.colDispName},h.${G0<TableModel>().hashersTableHelper.colHashName},h.${G0<TableModel>().hashersTableHelper.colFirstName} || " " || h.${G0<TableModel>().hashersTableHelper.colLastName},"<no name>") as dispName,
          lower(" " || coalesce(h.${G0<TableModel>().hashersTableHelper.colHashName},"") || " " || coalesce(h.${G0<TableModel>().hashersTableHelper.colDispName},"") || " " || coalesce(h.${G0<TableModel>().hashersTableHelper.colFirstName},"") || " " || coalesce(h.${G0<TableModel>().hashersTableHelper.colLastName},"") || " ") as nameForSort,
          h.${G0<TableModel>().hashersTableHelper.colPhoto},         
          hem.${G0<TableModel>().hasherEventMapTableHelper.colTotalHaringThisKennel},
          hem.${G0<TableModel>().hasherEventMapTableHelper.colTotalRunsThisKennel}
          FROM ${G0<TableModel>().hasherEventMapTableHelper.getTableName(AppDomainType.event)} hem 
          INNER JOIN ${G0<TableModel>().hashersTableHelper.getTableName(AppDomainType.user)} h on hem.${G0<TableModel>().hasherEventMapTableHelper.colUserId} = h.${G0<TableModel>().hashersTableHelper.colHasherId}  
          WHERE hem.${G0<TableModel>().hasherEventMapTableHelper.colEventId} = '${widget.eventAggregate.event.eventId}' 
          AND hem.${G0<TableModel>().hasherEventMapTableHelper.colAttendenceState} >= 20
          AND h.${G0<TableModel>().hashersTableHelper.colRemoved} = 0 
          ''';

    //_DrinksListFuture = Future<List<dynamic>>.value(<DrinksResults>[]);

    // final List<dynamic> kList = <dynamic>[];
    // int lastMemberType = 0;

    try {
      List<DrinksResults> awards = <DrinksResults>[];

      final List<Map<String, dynamic>> results = await G0<Database>().rawQuery(query);
      for (int i = 0; i < results.length; i++) {
        final DrinksResults hlrItem = DrinksResults.fromMap(results[i]);

        hlrItem.specialRunCount = Utilities.checkSpecialRun(hlrItem.totalRunsThisKennel);

        hlrItem.specialHaringCount = Utilities.checkSpecialHaring(hlrItem.totalHaringThisKennel);

        if ((hlrItem.specialRunCount != specialRunNo) || (hlrItem.specialHaringCount != specialRunNo)) {
          awards.add(hlrItem);
        }
      }
      int xxx = 0;
    } catch (e) {
      print(e);
    }
  }

  String sortBySpeedDialLabel = '';
  IconData sortBySpeedDialIcon;
  EnumSortByType sortBySpeedDialType;

  AppBar appBar;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: appBar, key: _scaffoldKey, body: Container(color: Colors.purple));
  }
}
