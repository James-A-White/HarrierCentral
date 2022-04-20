// @dart=2.11
import 'package:harrier_central/imports.dart';

// import 'package:flutter/material.dart';

// import 'package:auto_size_text/auto_size_text.dart';
// import 'package:flutter_speed_dial/flutter_speed_dial.dart';
// import 'package:flutter_vector_icons/flutter_vector_icons.dart';

// import 'package:harrier_central/data/hc3_services/sync_user_data_service.dart';
// import 'package:harrier_central/database/tables.dart';
// import 'package:harrier_central/util/enums.dart';
// import 'package:harrier_central/util/globals.dart';
// import 'package:ive_flutter_core/util/core_utilities.dart';

// import 'package:harrier_central/util/styles.dart';
// import 'package:harrier_central/util/constants.dart';
// import 'package:ive_flutter_core/widgets/offline_mode_ribbon.dart';

// import 'package:harrier_central/widgets/kennel_logo.dart';
// import 'package:harrier_central/widgets/user_event_list_item.dart';
// import 'package:ive_flutter_core/widgets/circular_progress_indicator.dart';
// import 'package:harrier_central/pages/top_level/history_list_page.dart';
// import 'package:ive_flutter_core_mobile/util/connection.dart';
// import 'package:harrier_central/util/secure_prefs.dart';

class UserRunHistoryListPage extends StatefulWidget {
  const UserRunHistoryListPage({
    Key key,
    @required this.kennelInfo,
    @required this.refreshKennelInfo,
  }) : super(key: key);

  final HistoryListResults kennelInfo;
  final Function refreshKennelInfo;

  @override
  UserRunHistoryPageState createState() => UserRunHistoryPageState();
}

class UserRunHistoryResults {
  UserRunHistoryResults(
      {this.eventId,
      this.eventName,
      this.eventNumber,
      this.eventStartDatetime,
      this.canEditRunAttendence,
      this.hemId,
      this.attendenceState,
      this.isHare,
      this.totalHaringThisKennel,
      this.totalRunsThisKennel,
      this.isLoading});

  final String eventId;
  final String eventName;
  final int eventNumber;
  final DateTime eventStartDatetime;
  final int canEditRunAttendence;
  final String hemId;
  final int attendenceState;
  final int isHare;
  int totalRunsThisKennel;
  int totalHaringThisKennel;
  bool isLoading;

  static UserRunHistoryResults fromMap(Map<String, dynamic> map) {
    final UserRunHistoryResults item = UserRunHistoryResults(
      eventName: map['eventName'],
      eventId: map['eventId'],
      eventNumber: map['eventNumber'],
      eventStartDatetime: DateTime.parse(map['eventStartDatetime'].toString().substring(0, 19)),
      canEditRunAttendence: map['canEditRunAttendence'],
      hemId: map['hemId'],
      attendenceState: map['attendenceState'],
      isHare: map['isHare'],
    );
    return item;
  }
}

class UserRunHistoryPageState extends State<UserRunHistoryListPage> {
  UserRunHistoryPageState();

  bool _isLoading = false;

  List<UserRunHistoryResults> runCountsList = <UserRunHistoryResults>[];
  final String userId = getStringPref(StringPrefsEnum.userId);

  HistoryListResults _kennelInfo;

  @override
  void initState() {
    refreshRunHistoryFromTable(true);
    super.initState();
  }

  Future<void> refreshRunHistoryFromTable(bool forceRefresh) async {
    // This query looks at two places for historical runs. First it looks at all
    // of the current runs for a kennel that are cached on the phone and joins to HEM.
    // But for runs that are old and no longer cached on the phone, it looks at the
    // HEM record only in the second half of the UNION statement.
    final String query = ''' 
          SELECT
          e.${G0<TableModel>().eventsTableHelper.colEventId} as eventId,
          e.${G0<TableModel>().eventsTableHelper.colEventName} as eventName,
          e.${G0<TableModel>().eventsTableHelper.colEventNumber} as eventNumber,
          e.${G0<TableModel>().eventsTableHelper.colEventStartDatetime} as eventStartDatetime,
          coalesce(e.${G0<TableModel>().eventsTableHelper.colCanEditRunAttendence},k.${G0<TableModel>().kennelsTableHelper.colCanEditRunAttendence}) as canEditRunAttendence,
          hem.${G0<TableModel>().hasherEventMapTableHelper.colHemId} as hemId,
          coalesce(hem.${G0<TableModel>().hasherEventMapTableHelper.colAttendenceState},0) as attendenceState,
          coalesce(hem.${G0<TableModel>().hasherEventMapTableHelper.colIsHare},0) as isHare
          FROM narrowEvents e
          INNER JOIN kennels k on e.${G0<TableModel>().eventsTableHelper.colKennelId} = k.${G0<TableModel>().kennelsTableHelper.colKennelId}
          LEFT OUTER JOIN hasherEventMap hem on hem.${G0<TableModel>().hasherEventMapTableHelper.colEventId} = e.${G0<TableModel>().eventsTableHelper.colEventId} 
          AND hem.${G0<TableModel>().hasherEventMapTableHelper.colUserId}  = "$userId"
          WHERE e.${G0<TableModel>().eventsTableHelper.colIsCountedRun} = 1 
          AND e.${G0<TableModel>().eventsTableHelper.colIsVisible} = 1 
          AND e.${G0<TableModel>().eventsTableHelper.colKennelId} = "${(_kennelInfo ?? widget.kennelInfo).kennelId}" 
          AND e.${G0<TableModel>().eventsTableHelper.colEventStartDatetime} <= DateTime('now','+36 hours')
        UNION
          SELECT 
          hem.${G0<TableModel>().hasherEventMapTableHelper.colEventId} as eventId,
          hem.${G0<TableModel>().hasherEventMapTableHelper.colEventName} as eventName,
          hem.${G0<TableModel>().hasherEventMapTableHelper.colEventNumber} as eventNumber,
          hem.${G0<TableModel>().hasherEventMapTableHelper.colEventStartDatetime} as eventStartDatetime,
          hem.${G0<TableModel>().hasherEventMapTableHelper.colCanEditRunAttendence} as canEditRunAttendence,
          hem.${G0<TableModel>().hasherEventMapTableHelper.colHemId} as hemId,
          coalesce(hem.${G0<TableModel>().hasherEventMapTableHelper.colAttendenceState},0) as attendenceState,
          coalesce(hem.${G0<TableModel>().hasherEventMapTableHelper.colIsHare},0) as isHare
          FROM hasherEventMap hem
          WHERE 
          hem.${G0<TableModel>().hasherEventMapTableHelper.colEventId} NOT IN (SELECT eventId FROM NarrowEvents)
          AND hem.${G0<TableModel>().hasherEventMapTableHelper.colUserId} = "$userId"
          AND hem.${G0<TableModel>().hasherEventMapTableHelper.colEventIsCountedAndVisible} = 1 
          AND hem.${G0<TableModel>().hasherEventMapTableHelper.colEventKennelId} = "${(_kennelInfo ?? widget.kennelInfo).kennelId}" 
          AND hem.${G0<TableModel>().hasherEventMapTableHelper.colEventStartDatetime} <= DateTime('now','+36 hours')
          ORDER BY eventStartDatetime desc
          
          ''';

    runCountsList = <UserRunHistoryResults>[];
    try {
      final List<Map<String, dynamic>> results = await G0<Database>().rawQuery(query);

      for (int i = 0; i < results.length; i++) {
        final UserRunHistoryResults hlrItem = UserRunHistoryResults.fromMap(results[i]);
        hlrItem.totalHaringThisKennel = -1;
        hlrItem.totalRunsThisKennel = -1;
        hlrItem.isLoading = false;
        runCountsList.add(hlrItem);

        if (forceRefresh && (i == results.length - 1)) {
          updateMyRunCounts();
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      //print(e);
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        SizedBox(height: MediaQuery.of(context).size.height, width: MediaQuery.of(context).size.width),
        Positioned(
          top: 0,
          left: 0,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              centerTitle: true,
              backgroundColor: themeAppBarBackground,
              title: Text(
                'My runs for ${(_kennelInfo ?? widget.kennelInfo).kennelShortName}',
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            floatingActionButton: SpeedDial(
              // both default to 16

              // marginEnd: 18,
              // marginBottom: 30,
              animatedIcon: AnimatedIcons.menu_close,
              animatedIconTheme: const IconThemeData(size: 22.0),
              // this is ignored if animatedIcon is non null
              // child:const  Icon(Icons.add),
              visible: true,
              curve: Curves.bounceIn,
              overlayColor: Colors.black,
              overlayOpacity: 0.5,
              onOpen: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              //onClose: () => //print('DIAL CLOSED'),
              tooltip: 'Speed Dial',
              heroTag: 'speed-dial-hero-tag',
              backgroundColor: Theme.of(context).buttonTheme.colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 8.0,
              shape: const CircleBorder(),
              children: <SpeedDialChild>[
                SpeedDialChild(
                  child: const Icon(MaterialCommunityIcons.email, color: Colors.white),
                  backgroundColor: Colors.teal[800],
                  label: 'Email run counts\r\n(this kennel)',
                  labelStyle: const TextStyle(fontSize: 18.0),
                  onTap: () {
                    G0<TableModel>()
                        .hasherEventMapService
                        .sendRunCountReportByEmail(kennelId: (_kennelInfo ?? widget.kennelInfo).kennelId, kennelName: (_kennelInfo ?? widget.kennelInfo).kennelName)
                        .then((Map<String, String> result) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      if (result['result'].toLowerCase().startsWith('success')) {
                        IveCoreUtilities.showAlert(context, 'E-mail successfully sent',
                            'Your run count report has been successfully e-mailed to:\r\n\r\n${result['email']}\r\n\r\nIf you do not see it in the next few minutes, check your spam folder.', 'OK');
                      }
                    });
                    IveCoreUtilities.showInSnackBar(context, _scaffoldKey, 'Run count report being processed...', durationInSeconds: 10);
                  },
                ),
                SpeedDialChild(
                  child: const Icon(MaterialCommunityIcons.email_plus, color: Colors.white),
                  backgroundColor: Colors.blue[900],
                  label: 'Email run counts\r\n(all kennels)',
                  labelStyle: const TextStyle(fontSize: 18.0),
                  onTap: () {
                    G0<TableModel>().hasherEventMapService.sendRunCountReportByEmail(kennelId: GUID_EMPTY, kennelName: 'All of your Hash Kennels').then((Map<String, String> result) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      if (result['result'].toLowerCase().startsWith('success')) {
                        IveCoreUtilities.showAlert(context, 'E-mail successfully sent',
                            'Your run count report has been successfully e-mailed to:\r\n\r\n${result['email']}\r\n\r\nIf you do not see it in the next few minutes, check your spam folder.', 'OK');
                      }
                    });
                    IveCoreUtilities.showInSnackBar(context, _scaffoldKey, 'Run count report being processed...', durationInSeconds: 10);
                  },
                ),
              ],
            ),
            body: _isLoading ? _buildCircularProgressIndicator() : _buildListView(),
          ),
        ),
        OfflineModeRibbon(
          showRibbon: G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected,
          lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSyncAsDate),
          ribbonImage: 'images/icons/offline_mode.png',
        ),
      ],
    );
  }

  Widget _buildCircularProgressIndicator() {
    return const Center(
      child: HcCircularProgressIndicator(key: Key('88230302')),
    );
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isLoading = true;
    });

    //final bool result = await G0<TableModel>()
    await G0<TableModel>().syncUserDataService.updateFromBackend(
        SyncUserDataService.flagHasherEventMapTable | SyncUserDataService.flagNarrowEventsTable | SyncUserDataService.flagKennelsTable | SyncUserDataService.flagHasherKennelMapTable, true);
    //final String resultStr = result ? 'successfully' : 'unsuccessfully';
    //print('User data synchronized $resultStr');
    await refreshRunHistoryFromTable(true);
    _kennelInfo = await widget.refreshKennelInfo();
    setState(() {
      _isLoading = false;
    });
  }

  // bool _isLoading = true;

  // @override
  // void initState() {
  //   super.initState();

  // }

  // int pageIndex = 1;

  // @override
  // Widget build(BuildContext context) {
  //   return  Scaffold(
  //       floatingActionButton: SpeedDial(
  //         // both default to 16
  //         marginEnd: 18,
  //         marginBottom: 30,
  //         animatedIcon: AnimatedIcons.menu_close,
  //         animatedIconTheme: const IconThemeData(size: 22.0),
  //         // this is ignored if animatedIcon is non null
  //         // child:const  Icon(Icons.add),
  //         visible: true,
  //         curve: Curves.bounceIn,
  //         overlayColor: Colors.black,
  //         overlayOpacity: 0.5,
  //         onOpen: () => //print('OPENING DIAL'),
  //         onClose: () => //print('DIAL CLOSED'),
  //         tooltip: 'Speed Dial',
  //         heroTag: 'speed-dial-hero-tag',
  //         backgroundColor: Theme.of(context).accentColor,
  //         foregroundColor: Colors.white,
  //         elevation: 8.0,
  //         shape: CircleBorder(),
  //         children: <SpeedDialChild>[
  //           SpeedDialChild(
  //             child: const Icon(MaterialCommunityIcons.email),
  //             backgroundColor: Colors.teal[800],
  //             label: 'Email this kennel\'s run history',
  //             labelStyle: const TextStyle(fontSize: 18.0),
  //             onTap: () {
  //                   model.sendRunCountReportByEmail(kennelId: kennelId, kennelName: widget.kennelName).then((Map<String, String> result) {
  //                     if (result['result'].toLowerCase().startsWith('success')) {
  //                       await IveCoreUtilities.showAlert(context, 'E-mail successfully sent', 'Your payment report has been successfully e-mailed to:\r\n\r\n${result['email']}\r\n\r\nIf you do not see it in the next few minutes, check your spam folder.', 'OK');
  //                     }
  //                   });
  //                 },
  //           ),
  //           SpeedDialChild(
  //             child: const Icon(MaterialCommunityIcons.email_plus),
  //             backgroundColor: Colors.blue[900],
  //             label: 'Email all kennels run history',
  //             labelStyle: const TextStyle(fontSize: 18.0),
  //             onTap: ()  {
  //                   model.sendRunCountReportByEmail(kennelId: GUID_EMPTY, kennelName: 'All of your Hash Kennels').then((Map<String, String> result) {
  //                     if (result['result'].toLowerCase().startsWith('success')) {
  //                       await IveCoreUtilities.showAlert(context, 'E-mail successfully sent', 'Your payment report has been successfully e-mailed to:\r\n\r\n${result['email']}\r\n\r\nIf you do not see it in the next few minutes, check your spam folder.', 'OK');
  //                     }
  //                   });
  //                 },
  //           ),
  //         ],
  //       ),
  //       appBar: AppBar(
  //         centerTitle: true,
  //         backgroundColor: themeAppBarBackground,
  //         title: Text(
  //           'My runs for ${widget.kennelShortName}',
  //           style: const TextStyle(
  //             color: Colors.white,
  //           ),
  //         ),
  //       ),
  //       body:

  //         _isLoading ? _buildCircularProgressIndicator() : _buildListView()

  //     );

  // }

  // Widget _buildCircularProgressIndicator() {
  //   return const Center(
  //     child: HcCircularProgressIndicator(key: Key('yyyyyyy')),
  //   );
  // }

  // Future<void> _handleRefresh() async {
  //   model.clearKennelList();
  //   model.getUserEventsFromBackend(false, 1, 0, 0);
  //   //model.notifyListeners();
  // }

  static const TextStyle headingStyle = TextStyle(fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 22.0, height: 1.0);

  static TextStyle numberStyle = TextStyle(color: Colors.black87, fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, fontSize: 16.0 * G0<DeviceInfo>().deviceWidthScaleFactor, height: 1.0);

  static TextStyle boldTitleStyle = TextStyle(color: Colors.black87, fontFamily: 'AvenirNextBold', fontStyle: FontStyle.normal, fontSize: 16.0 * G0<DeviceInfo>().deviceWidthScaleFactor, height: 1.0);

  int myRunCount = 0;
  int myHaringCount = 0;

  // TODO(James): Update this to simply pull data already provided by the server
  void updateMyRunCounts() {
    int haringCount = 0;
    int runCount = 0;

    for (int i = runCountsList.length - 1; i >= 0; i--) {
      if (runCountsList[i].isHare == 1) {
        haringCount++;
      }
      if (runCountsList[i].attendenceState >= 20) {
        runCount++;
      }
      runCountsList[i].totalHaringThisKennel = haringCount + (_kennelInfo ?? widget.kennelInfo).historicalHaringCount;
      runCountsList[i].totalRunsThisKennel = runCount + (_kennelInfo ?? widget.kennelInfo).historicalTotalRunCount;
    }

    myRunCount = runCount;
    myHaringCount = haringCount;
  }

  Widget _buildListView() {
    return Container(
      decoration: Backgrounds.defaultHcBackgroundLight(),
      padding: const EdgeInsets.only(top: 0.0),
      child: runCountsList.isEmpty
          ? const Center(child: Text('No runs logged yet.'))
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              displacement: 130.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Container(
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
                    //color:Color.fromARGB(30, 0, 0, 0),
                    padding: const EdgeInsets.only(left: 5, top: 5, right: 0, bottom: 5),

                    child: Row(children: <Widget>[
                      Container(
                        margin: const EdgeInsets.only(right: 12.0),
                        height: 90,
                        child: KennelLogo(
                          kennelId: (_kennelInfo ?? widget.kennelInfo).kennelId,
                          kennelLogoUrl: (_kennelInfo ?? widget.kennelInfo).kennelLogo,
                          kennelShortName: (_kennelInfo ?? widget.kennelInfo).kennelShortName,
                          logoHeight: 60.0 * G0<DeviceInfo>().deviceWidthScaleFactor,
                          leftPadding: 5.0,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            AutoSizeText(
                              (_kennelInfo ?? widget.kennelInfo).kennelName,
                              //'Super fucking long text thats sure to overflow and more',
                              //'999',
                              overflow: TextOverflow.ellipsis,
                              minFontSize: 18.0,
                              maxLines: 1,
                              style: boldTitleStyle,
                              textAlign: TextAlign.left,
                            ),
                            AutoSizeText(
                              'My verified run count: ${myRunCount.toString()}',
                              //'Super fucking long text thats sure to overflow and more',
                              //'999',
                              overflow: TextOverflow.ellipsis,
                              minFontSize: 12.0,
                              maxLines: 1,
                              style: numberStyle,
                              textAlign: TextAlign.center,
                            ),
                            AutoSizeText(
                              'My verified haring count: ${myHaringCount.toString()}',
                              //'Super fucking long text thats sure to overflow and more',
                              //'999',
                              overflow: TextOverflow.ellipsis,
                              minFontSize: 12.0,
                              maxLines: 1,
                              style: numberStyle,
                              textAlign: TextAlign.center,
                            ),
                            ((_kennelInfo ?? widget.kennelInfo).historicalTotalRunCount ?? 0) == 0
                                ? Container()
                                : AutoSizeText(
                                    'Historical run count: ${(_kennelInfo ?? widget.kennelInfo).historicalCountIsEstimate != 0 ? '~' : ''}${(_kennelInfo ?? widget.kennelInfo).historicalTotalRunCount}',
                                    //'Super fucking long text thats sure to overflow and more',
                                    //'999',
                                    overflow: TextOverflow.ellipsis,
                                    minFontSize: 18.0,
                                    maxLines: 1,
                                    style: numberStyle,
                                    textAlign: TextAlign.center,
                                  ),
                            ((_kennelInfo ?? widget.kennelInfo).historicalTotalRunCount ?? 0) == 0
                                ? Container()
                                : AutoSizeText(
                                    'Historical haring count ${(_kennelInfo ?? widget.kennelInfo).historicalCountIsEstimate != 0 ? '~' : ''}${(_kennelInfo ?? widget.kennelInfo).historicalHaringCount ?? 0}',
                                    //'Super fucking long text thats sure to overflow and more',
                                    //'999',
                                    overflow: TextOverflow.ellipsis,
                                    minFontSize: 18.0,
                                    maxLines: 1,
                                    style: numberStyle,
                                    textAlign: TextAlign.center,
                                  ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  Expanded(
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: runCountsList.length,
                      padding: const EdgeInsets.only(top: 5),
                      separatorBuilder: (BuildContext context, int index) => const Divider(
                        height: 1.0,
                        color: Colors.black45,
                      ),
                      //itemExtent: 58.0,
                      //shrinkWrap: true,
                      itemBuilder: (BuildContext context, int index) {
                        final UserRunHistoryResults item = runCountsList[index];

                        return Dismissible(
                          key: Key(item.eventId),
                          confirmDismiss: (DismissDirection direction) {
                            if (item.canEditRunAttendence != 0) {
                              setState(() {
                                // swipe from right to left to indicate that
                                // the hasher either attended the run as a pack
                                // member or as a hare
                                if (direction == DismissDirection.endToStart) {
                                  // here, we're going from an attendence state of
                                  // not at the Hash to being at the Hash,
                                  // so assume that the person was not a hare
                                  if (item.attendenceState < attendenceAtHash.value) {
                                    item.isLoading = true;
                                    final Future<List<dynamic>> retVal = G0<TableModel>().hasherEventMapService.joinEvent(
                                          item.eventId,
                                          userId,
                                          item.hemId,
                                          AppDomainType.user,
                                          rsvpState: rsvpYes.value,
                                          attendenceState: attendenceAtHash.value,
                                          isHare: isHareNo.value,
                                        );

                                    retVal.then((List<dynamic> adHocData) {
                                      refreshRunHistoryFromTable(true).then((void _) {});
                                    });
                                  } else {
                                    item.isLoading = true;
                                    final Future<List<dynamic>> retVal = G0<TableModel>().hasherEventMapService.joinEvent(
                                          item.eventId,
                                          userId,
                                          item.hemId,
                                          AppDomainType.user,
                                          rsvpState: rsvpYes.value,
                                          attendenceState: attendenceAtHash.value,
                                          isHare: item.isHare == 1 ? isHareNo.value : isHareYes.value,
                                        );

                                    retVal.then((List<dynamic> adHocData) {
                                      refreshRunHistoryFromTable(true).then((void _) {});
                                    });
                                  }
                                } else {
                                  // swipe from left to right to
                                  // indicate that the hasher did
                                  // not participate in this event
                                  final Future<List<dynamic>> retVal = G0<TableModel>().hasherEventMapService.joinEvent(
                                        item.eventId,
                                        userId,
                                        item.hemId,
                                        AppDomainType.user,
                                        rsvpState: rsvpNo.value,
                                        attendenceState: attendenceNo.value,
                                        isHare: isHareNo.value,
                                      );

                                  retVal.then((List<dynamic> adHocData) {
                                    refreshRunHistoryFromTable(true).then((void _) {});
                                  });
                                }
                              });
                            }
                            return Future<bool>.value(false);
                          },
                          background: item.canEditRunAttendence == 0
                              ? Container(
                                  color: Colors.grey,
                                  child: Row(children: const <Widget>[
                                    Padding(
                                      padding: EdgeInsets.only(left: 10.0),
                                      child: Icon(FontAwesome.lock, color: Colors.white, size: 35.0),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 15.0),
                                      child: Text(
                                          // '${IveCoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Bank Transfer',
                                          'Run locked',
                                          style: TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 17.0, height: 1.0)),
                                    )
                                  ]))
                              : Container(
                                  color: Colors.red,
                                  child: Row(children: const <Widget>[
                                    Padding(
                                      padding: EdgeInsets.only(left: 10.0),
                                      child: Icon(FontAwesome.times_circle, color: Colors.white, size: 35.0),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 15.0),
                                      child: Text(
                                          // '${IveCoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Bank Transfer',
                                          'I was not\r\nat the Hash',
                                          maxLines: 2,
                                          style: TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 17.0, height: 1.0)),
                                    )
                                  ])),
                          secondaryBackground: item.canEditRunAttendence == 0
                              ? Container(
                                  color: Colors.grey,
                                  child: Row(mainAxisAlignment: MainAxisAlignment.end, children: const <Widget>[
                                    Padding(
                                      padding: EdgeInsets.only(right: 15.0),
                                      child: Icon(FontAwesome.lock, color: Colors.white, size: 35.0),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(right: 15.0),
                                      child: Text(
                                          //'${IveCoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Cash',
                                          'Run locked',
                                          style: TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 17.0, height: 1.0)),
                                    )
                                  ]))
                              : (item.attendenceState < attendenceAtHash.value) || ((item.attendenceState >= attendenceAtHash.value) && (item.isHare == isHareYes.value))
                                  ? Container(
                                      color: Colors.green,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: const <Widget>[
                                          Padding(
                                            padding: EdgeInsets.only(right: 15.0),
                                            child: Icon(FontAwesome.check_circle, color: Colors.white, size: 35.0),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(right: 15.0),
                                            child: Text(
                                                //'${IveCoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Cash',
                                                'I was at\r\nthe Hash',
                                                maxLines: 2,
                                                textAlign: TextAlign.right,
                                                style: TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 17.0, height: 1.0)),
                                          )
                                        ],
                                      ),
                                    )
                                  : Container(
                                      color: Colors.purple,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: const <Widget>[
                                          Padding(
                                            padding: EdgeInsets.only(right: 15.0),
                                            child: Padding(
                                              padding: EdgeInsets.only(left: 2.5, right: 2.5),
                                              child: ImageIcon(AssetImage('images/icons/hare_icon.png'), color: Colors.white, size: 30.0),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(right: 15.0),
                                            child: Text(
                                                //'${IveCoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Cash',
                                                'I was a Hare',
                                                style: TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 17.0, height: 1.0)),
                                          )
                                        ],
                                      ),
                                    ),
                          onDismissed: (DismissDirection direction) {
                            //print(direction.toString() + ' NOTE: We should never reach this point');
                          },
                          child: GestureDetector(
                            onTapUp: (TapUpDetails details) async {
                              final List<RunDetailsAggregate> run = await QueryRuns.getRunDetailsAggregates(
                                true,
                                eventId: item.eventId,
                                queryType: EnumRunQueryType.singleRun,
                              );

                              if ((run != null) && (run.isNotEmpty)) {
                                await Navigator.push<dynamic>(
                                  context,
                                  MaterialPageRoute<dynamic>(
                                    builder: (BuildContext context) {
                                      return RunDetailsPage(
                                        futureRun: run[0],
                                        refreshPage: () async {},
                                      );
                                    },
                                  ),
                                );
                              }
                            },
                            child: UserEventListItem(
                              item: item,
                              kennelShortName: (_kennelInfo ?? widget.kennelInfo).kennelShortName,
                            ),
                          ),
                        );

                        // Container(
                        //   height: 60.0,
                        //   //padding: const EdgeInsets.only(top: 10.0),
                        //   child:

                        // KennelRunHistoryCountListItem(
                        //     kennelRunHistoryCount:
                        //         model.kennelRunCountList[index]);

                        // );
                      },
                    ),
                  ),
                ],
              )),
    );
  }
}
