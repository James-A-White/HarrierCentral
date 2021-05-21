import 'dart:async';

import 'package:flutter/material.dart';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:harrier_central/data/hc3_services/sync_user_data_service.dart';
import 'package:harrier_central/database/tables.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:ive_flutter_core/util/core_utilities.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:ive_flutter_core/widgets/offline_mode_ribbon.dart';

import 'package:harrier_central/widgets/kennel_logo.dart';
import 'package:harrier_central/widgets/user_event_list_item.dart';
import 'package:ive_flutter_core/widgets/circular_progress_indicator.dart';
import 'package:harrier_central/pages/top_level/history_list_page.dart';
import 'package:ive_flutter_core/util/connection.dart';

class UserRunHistoryListPage extends StatefulWidget {
  const UserRunHistoryListPage({Key key, @required this.kennelInfo})
      : super(key: key);

  final HistoryListResults kennelInfo;

  @override
  UserRunHistoryPageState createState() =>
      UserRunHistoryPageState(kennelId: kennelInfo.kennelId);
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
      eventStartDatetime:
          DateTime.parse(map['eventStartDatetime'].toString().substring(0, 19)),
      canEditRunAttendence: map['canEditRunAttendence'],
      hemId: map['hemId'],
      attendenceState: map['attendenceState'],
      isHare: map['isHare'],
    );
    return item;
  }
}

class UserRunHistoryPageState extends State<UserRunHistoryListPage> {
  UserRunHistoryPageState({@required this.kennelId});

  String kennelId;

  bool _isLoading = false;

  List<UserRunHistoryResults> runCountsList = <UserRunHistoryResults>[];
  final String userId = getStringPref(StringPrefsEnum.userId);

  @override
  void initState() {
    refreshRunHistoryFromTable(true);
    super.initState();
  }

  Future<void> refreshRunHistoryFromTable(bool forceRefresh) async {
    final String query = ''' 
        SELECT 
          e.eventId,
          e.eventName,
          e.eventNumber,
          e.eventStartDatetime,
          e.canEditRunAttendence,
          hem.hemId,
          coalesce(hem.attendenceState,0) as attendenceState,
          coalesce(hem.isHare,0) as isHare
          FROM narrowEvents e
          LEFT OUTER JOIN hasherEventMap hem on hem.eventId = e.eventId AND hem.userId = "$userId"
          WHERE e.isCountedRun = 1 AND e.isVisible = 1 AND e.kennelId = "${widget.kennelInfo.kennelId}" 
          AND e.eventStartDatetime <= DateTime('now')
          ORDER BY e.eventStartDatetime desc
          
          ''';

    runCountsList = <UserRunHistoryResults>[];
    try {
      final List<Map<String, dynamic>> results =
          await internalSqlDb.rawQuery(query);

      for (int i = 0; i < results.length; i++) {
        final UserRunHistoryResults hlrItem =
            UserRunHistoryResults.fromMap(results[i]);
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
      print(e);
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width),
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
                'My runs for ${widget.kennelInfo.kennelShortName}',
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            floatingActionButton: SpeedDial(
              // both default to 16
              marginEnd: 18,
              marginBottom: 30,
              animatedIcon: AnimatedIcons.menu_close,
              animatedIconTheme: const IconThemeData(size: 22.0),
              // this is ignored if animatedIcon is non null
              // child:const  Icon(Icons.add),
              visible: true,
              curve: Curves.bounceIn,
              overlayColor: Colors.black,
              overlayOpacity: 0.5,
              onOpen: () {
                _scaffoldKey.currentState.hideCurrentSnackBar();
              },
              onClose: () => print('DIAL CLOSED'),
              tooltip: 'Speed Dial',
              heroTag: 'speed-dial-hero-tag',
              backgroundColor: Theme.of(context).accentColor,
              foregroundColor: Colors.white,
              elevation: 8.0,
              shape: const CircleBorder(),
              children: <SpeedDialChild>[
                SpeedDialChild(
                  child: const Icon(MaterialCommunityIcons.email),
                  backgroundColor: Colors.teal[800],
                  label: 'Email run counts\r\n(this kennel)',
                  labelStyle: const TextStyle(fontSize: 18.0),
                  onTap: () {
                    hasherEventMapService
                        .sendRunCountReportByEmail(
                            kennelId: kennelId,
                            kennelName: widget.kennelInfo.kennelName)
                        .then((Map<String, String> result) {
                      _scaffoldKey.currentState?.hideCurrentSnackBar();
                      if (result['result']
                          .toLowerCase()
                          .startsWith('success')) {
                        CoreUtilities.showAlert(
                            context,
                            'E-mail successfully sent',
                            'Your run count report has been successfully e-mailed to:\r\n\r\n${result['email']}\r\n\r\nIf you do not see it in the next few minutes, check your spam folder.',
                            'OK');
                      }
                    });
                    CoreUtilities.showInSnackBar(context, _scaffoldKey,
                        'Run count report being processed...',
                        durationInSeconds: 10);
                  },
                ),
                SpeedDialChild(
                  child: const Icon(MaterialCommunityIcons.email_plus),
                  backgroundColor: Colors.blue[900],
                  label: 'Email run counts\r\n(all kennels)',
                  labelStyle: const TextStyle(fontSize: 18.0),
                  onTap: () {
                    hasherEventMapService
                        .sendRunCountReportByEmail(
                            kennelId: GUID_EMPTY,
                            kennelName: 'All of your Hash Kennels')
                        .then((Map<String, String> result) {
                      _scaffoldKey.currentState?.hideCurrentSnackBar();
                      if (result['result']
                          .toLowerCase()
                          .startsWith('success')) {
                        CoreUtilities.showAlert(
                            context,
                            'E-mail successfully sent',
                            'Your run count report has been successfully e-mailed to:\r\n\r\n${result['email']}\r\n\r\nIf you do not see it in the next few minutes, check your spam folder.',
                            'OK');
                      }
                    });
                    CoreUtilities.showInSnackBar(context, _scaffoldKey,
                        'Run count report being processed...',
                        durationInSeconds: 10);
                  },
                ),
              ],
            ),
            body: _isLoading
                ? _buildCircularProgressIndicator()
                : _buildListView(),
          ),
        ),
        OfflineModeRibbon(
          showRibbon: globalConnectionStatus == connectionStatus_notConnected,
          lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSyncAsDate),
          ribbonImage: 'images/icons/offline_mode.png',
        ),
      ],
    );
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
    print('User data synchronized $resultStr');
    refreshRunHistoryFromTable(true);
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
  //         onOpen: () => print('OPENING DIAL'),
  //         onClose: () => print('DIAL CLOSED'),
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
  //                       CoreUtilities.showAlert(context, 'E-mail successfully sent', 'Your payment report has been successfully e-mailed to:\r\n\r\n${result['email']}\r\n\r\nIf you do not see it in the next few minutes, check your spam folder.', 'OK');
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
  //                       CoreUtilities.showAlert(context, 'E-mail successfully sent', 'Your payment report has been successfully e-mailed to:\r\n\r\n${result['email']}\r\n\r\nIf you do not see it in the next few minutes, check your spam folder.', 'OK');
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
  //     child: HcCircularProgressIndicator(),
  //   );
  // }

  // Future<void> _handleRefresh() async {
  //   model.clearKennelList();
  //   model.getUserEventsFromBackend(false, 1, 0, 0);
  //   //model.notifyListeners();
  // }

  static const TextStyle headingStyle = TextStyle(
      fontFamily: 'AvenirNextCondensedDemiBold',
      fontStyle: FontStyle.normal,
      fontSize: 22.0,
      height: 1.0);

  static TextStyle numberStyle = TextStyle(
      color: Colors.black87,
      fontFamily: 'AvenirNextDemiBold',
      fontStyle: FontStyle.normal,
      fontSize: 16.0 * deviceWidthScaleFactor,
      height: 1.0);

  static TextStyle boldTitleStyle = TextStyle(
      color: Colors.black87,
      fontFamily: 'AvenirNextBold',
      fontStyle: FontStyle.normal,
      fontSize: 16.0 * deviceWidthScaleFactor,
      height: 1.0);

  int myRunCount = 0;
  int myHaringCount = 0;

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
      runCountsList[i].totalHaringThisKennel =
          haringCount + widget.kennelInfo.historicalHaringCount;
      runCountsList[i].totalRunsThisKennel =
          runCount + widget.kennelInfo.historicalPackRunCount;
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
              onRefresh: () => _handleRefresh(),
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
                    padding: const EdgeInsets.only(
                        left: 5, top: 5, right: 0, bottom: 5),

                    child: Row(children: <Widget>[
                      Container(
                        margin: const EdgeInsets.only(right: 12.0),
                        height: 90,
                        child: KennelLogo(
                          kennelLogoUrl: widget.kennelInfo.kennelLogo,
                          kennelShortName: widget.kennelInfo.kennelShortName,
                          logoHeight: 60.0 * deviceWidthScaleFactor,
                          leftPadding: 5.0,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              child: AutoSizeText(
                                '${widget.kennelInfo.kennelName}',
                                //'Super fucking long text thats sure to overflow and more',
                                //'999',
                                overflow: TextOverflow.ellipsis,
                                minFontSize: 18.0,
                                maxLines: 1,
                                style: boldTitleStyle,
                                textAlign: TextAlign.left,
                              ),
                              //color: Colors.green,
                            ),
                            Container(
                              child: AutoSizeText(
                                'My verified run count: ${myRunCount.toString()}',
                                //'Super fucking long text thats sure to overflow and more',
                                //'999',
                                overflow: TextOverflow.ellipsis,
                                minFontSize: 12.0,
                                maxLines: 1,
                                style: numberStyle,
                                textAlign: TextAlign.center,
                              ),
                              //color: Colors.green,
                            ),
                            Container(
                              child: AutoSizeText(
                                'My verified haring count: ${myHaringCount.toString()}',
                                //'Super fucking long text thats sure to overflow and more',
                                //'999',
                                overflow: TextOverflow.ellipsis,
                                minFontSize: 12.0,
                                maxLines: 1,
                                style: numberStyle,
                                textAlign: TextAlign.center,
                              ),
                              //color: Colors.green,
                            ),
                            widget.kennelInfo.historicalPackRunCount == 0
                                ? Container()
                                : Container(
                                    child: AutoSizeText(
                                      'Historical run count: ${widget.kennelInfo.historicalCountIsEstimate != 0 ? '~' : ''}${widget.kennelInfo.historicalPackRunCount}',
                                      //'Super fucking long text thats sure to overflow and more',
                                      //'999',
                                      overflow: TextOverflow.ellipsis,
                                      minFontSize: 18.0,
                                      maxLines: 1,
                                      style: numberStyle,
                                      textAlign: TextAlign.center,
                                    ),
                                    //color: Colors.green,
                                  ),
                            widget.kennelInfo.historicalPackRunCount == 0
                                ? Container()
                                : Container(
                                    child: AutoSizeText(
                                      'Historical haring coung ${widget.kennelInfo.historicalCountIsEstimate != 0 ? '~' : ''}${widget.kennelInfo.historicalHaringCount}',
                                      //'Super fucking long text thats sure to overflow and more',
                                      //'999',
                                      overflow: TextOverflow.ellipsis,
                                      minFontSize: 18.0,
                                      maxLines: 1,
                                      style: numberStyle,
                                      textAlign: TextAlign.center,
                                    ),
                                    //color: Colors.green,
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
                      separatorBuilder: (BuildContext context, int index) =>
                          const Divider(
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
                                  if (item.attendenceState <
                                      attendenceAtHash.value) {
                                    item.isLoading = true;
                                    final Future<List<dynamic>> retVal =
                                        hasherEventMapService.joinEvent(
                                      item.eventId,
                                      userId,
                                      item.hemId,
                                      AppDomainType.user,
                                      rsvpState: rsvpYes.value,
                                      attendenceState: attendenceAtHash.value,
                                      isHare: isHareNo.value,
                                    );

                                    retVal.then((List<dynamic> adHocData) {
                                      refreshRunHistoryFromTable(true)
                                          .then((void dummy) {});
                                    });
                                  } else {
                                    item.isLoading = true;
                                    final Future<List<dynamic>> retVal =
                                        hasherEventMapService.joinEvent(
                                      item.eventId,
                                      userId,
                                      item.hemId,
                                      AppDomainType.user,
                                      rsvpState: rsvpYes.value,
                                      attendenceState: attendenceAtHash.value,
                                      isHare: item.isHare == 1
                                          ? isHareNo.value
                                          : isHareYes.value,
                                    );

                                    retVal.then((List<dynamic> adHocData) {
                                      refreshRunHistoryFromTable(true)
                                          .then((void dummy) {});
                                    });
                                  }
                                } else {
                                  // swipe from left to right to
                                  // indicate that the hasher did
                                  // not participate in this event
                                  final Future<List<dynamic>> retVal =
                                      hasherEventMapService.joinEvent(
                                    item.eventId,
                                    userId,
                                    item.hemId,
                                    AppDomainType.user,
                                    rsvpState: rsvpNo.value,
                                    attendenceState: attendenceNo.value,
                                    isHare: isHareNo.value,
                                  );

                                  retVal.then((List<dynamic> adHocData) {
                                    refreshRunHistoryFromTable(true)
                                        .then((void dummy) {});
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
                                      child: Icon(FontAwesome.lock,
                                          color: Colors.white, size: 35.0),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 15.0),
                                      child: Text(
                                          // '${CoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Bank Transfer',
                                          'Run locked',
                                          style: TextStyle(
                                              fontFamily: 'AvenirNextDemiBold',
                                              fontStyle: FontStyle.normal,
                                              color: Colors.white,
                                              fontSize: 17.0,
                                              height: 1.0)),
                                    )
                                  ]))
                              : Container(
                                  color: Colors.red,
                                  child: Row(children: const <Widget>[
                                    Padding(
                                      padding: EdgeInsets.only(left: 10.0),
                                      child: Icon(FontAwesome.times_circle,
                                          color: Colors.white, size: 35.0),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 15.0),
                                      child: Text(
                                          // '${CoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Bank Transfer',
                                          'I was not\r\nat the Hash',
                                          maxLines: 2,
                                          style: TextStyle(
                                              fontFamily: 'AvenirNextDemiBold',
                                              fontStyle: FontStyle.normal,
                                              color: Colors.white,
                                              fontSize: 17.0,
                                              height: 1.0)),
                                    )
                                  ])),
                          secondaryBackground: item.canEditRunAttendence == 0
                              ? Container(
                                  color: Colors.grey,
                                  child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: const <Widget>[
                                        Padding(
                                          padding: EdgeInsets.only(right: 15.0),
                                          child: Icon(FontAwesome.lock,
                                              color: Colors.white, size: 35.0),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(right: 15.0),
                                          child: Text(
                                              //'${CoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Cash',
                                              'Run locked',
                                              style: TextStyle(
                                                  fontFamily:
                                                      'AvenirNextDemiBold',
                                                  fontStyle: FontStyle.normal,
                                                  color: Colors.white,
                                                  fontSize: 17.0,
                                                  height: 1.0)),
                                        )
                                      ]))
                              : (item.attendenceState <
                                          attendenceAtHash.value) ||
                                      ((item.attendenceState >=
                                              attendenceAtHash.value) &&
                                          (item.isHare == isHareYes.value))
                                  ? Container(
                                      color: Colors.green,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: const <Widget>[
                                          Padding(
                                            padding:
                                                EdgeInsets.only(right: 15.0),
                                            child: Icon(
                                                FontAwesome.check_circle,
                                                color: Colors.white,
                                                size: 35.0),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsets.only(right: 15.0),
                                            child: Text(
                                                //'${CoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Cash',
                                                'I was at\r\nthe Hash',
                                                maxLines: 2,
                                                textAlign: TextAlign.right,
                                                style: TextStyle(
                                                    fontFamily:
                                                        'AvenirNextDemiBold',
                                                    fontStyle: FontStyle.normal,
                                                    color: Colors.white,
                                                    fontSize: 17.0,
                                                    height: 1.0)),
                                          )
                                        ],
                                      ),
                                    )
                                  : Container(
                                      color: Colors.purple,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: const <Widget>[
                                          Padding(
                                            padding:
                                                EdgeInsets.only(right: 15.0),
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                  left: 2.5, right: 2.5),
                                              child: ImageIcon(
                                                  AssetImage(
                                                      'images/icons/hare_icon.png'),
                                                  color: Colors.white,
                                                  size: 30.0),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsets.only(right: 15.0),
                                            child: Text(
                                                //'${CoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Cash',
                                                'I was a Hare',
                                                style: TextStyle(
                                                    fontFamily:
                                                        'AvenirNextDemiBold',
                                                    fontStyle: FontStyle.normal,
                                                    color: Colors.white,
                                                    fontSize: 17.0,
                                                    height: 1.0)),
                                          )
                                        ],
                                      ),
                                    ),
                          onDismissed: (DismissDirection direction) {
                            print(direction.toString() +
                                ' NOTE: We should never reach this point');
                          },
                          child: UserEventListItem(
                            item: item,
                            kennelShortName: widget.kennelInfo.kennelShortName,
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
