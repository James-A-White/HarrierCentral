import 'dart:async';

import 'package:flutter/material.dart';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:harrier_central/database/query_kennels.dart';
import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/data/hc3_services/base_service.dart';
import 'package:harrier_central/data/hc3_services/sync_user_data_service.dart';
import 'package:harrier_central/data/hc3_services/events_service.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/pages/kennel_admin/run_number_popup.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/widgets/kennel_logo.dart';
import 'package:harrier_central/widgets/filter_event_list_item.dart';
import 'package:harrier_central/widgets/circular_progress_indicator.dart';

enum FilterEventsPageType { past, future }

class FilterEventsPage extends StatefulWidget {
  const FilterEventsPage({Key key, @required this.kennel, @required this.pageType}) : super(key: key);

  final KennelListAggregate kennel;
  final FilterEventsPageType pageType;

  @override
  FilterEventsPageState createState() => FilterEventsPageState();
}

class FilterEventsPageState extends State<FilterEventsPage> {
  FilterEventsPageState();

  @override
  void initState() {
    _refreshSqlTablesFromBackend(true);
    super.initState();
  }

  bool _isLoading = true;

  Future<void> _refreshSqlTablesFromBackend(bool showLoadingIndicator) async {
    if (showLoadingIndicator) {
      setState(() {
        _isLoading = true;
      });
    }

    final bool result = await syncUserDataService.updateFromBackend(SyncUserDataService.flagNarrowEventsTable, true);
    final String resultStr = result ? 'successfully' : 'unsuccessfully';
    print('Events data synchronized $resultStr');

    _refreshEventFromTables(true).then((void dummy) {});
  }

  List<Map<String, dynamic>> events = <Map<String, dynamic>>[];

  Future<void> _refreshEventFromTables(bool forceRefresh) async {
    final String sortOrder = widget.pageType == FilterEventsPageType.future ? 'ASC' : 'DESC';
    final String dateComparer = widget.pageType == FilterEventsPageType.future ? '>=' : '<=';
    final String dateOffset = widget.pageType == FilterEventsPageType.future ? '-5 minutes' : '+5 minutes';

    final String userId = getStringPref(StringPrefsEnum.userId);

    try {
      final String sql = ''' 

          SELECT
            evt.eventId,
            evt.isVisible,
            evt.isCountedRun,
            evt.absoluteEventNumber,
            evt.eventFacebookId,
            evt.eventName,
            evt.eventNumber,
            evt.eventStartDatetime,
            hkm.mismanagementRoleFlags,
            evt.canEditRunAttendence,
            (SELECT COUNT(*) FROM ${eventsTableHelper.tableName} evt2 where kennelId = "${widget.kennel.kennel.kennelId}" AND isVisible = 1) as publishedRunCount
          FROM ${eventsTableHelper.tableName} evt
          INNER JOIN ${hasherKennelMapTableHelper.getTableName(TableType.hkmUser)} hkm on hkm.kennelId = "${widget.kennel.kennel.kennelId}" and hkm.userId = "$userId"
          WHERE evt.kennelId = "${widget.kennel.kennel.kennelId}"
          AND datetime(evt.eventStartDatetime) $dateComparer datetime('now','localtime','$dateOffset')
          ORDER BY evt.eventStartDatetime $sortOrder
        
          ''';

      internalSqlDb.rawQuery(sql).then((List<Map<String, dynamic>> results) {
        events = results;
        setState(() {
          _isLoading = false;
        });
      });
    } catch (e) {
      print(e);
    }
  }

  int pageIndex = 1;

  // void refreshListFromDb(bool showLoadingIndicator) {
  //   model.getUserEventsFromBackend(showLoadingIndicator, 0, 1,1).then((void dummy) {
  //     myRunCount = model.userEventList
  //         .where(
  //             (Event ueh) => ueh.attendenceState >= attendenceAtHash.value)
  //         .length;
  //     updateRunCounts();
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // floatingActionButton: SpeedDial(
        //   // both default to 16
        //   marginRight: 18,
        //   marginBottom: 30,
        //   animatedIcon: AnimatedIcons.menu_close,
        //   animatedIconTheme: const IconThemeData(size: 22.0),
        //   // this is ignored if animatedIcon is non null
        //   // child:const  Icon(Icons.add),
        //   visible: true,
        //   curve: Curves.bounceIn,
        //   overlayColor: Colors.black,
        //   overlayOpacity: 0.5,
        //   onOpen: () => print('OPENING DIAL'),
        //   onClose: () => print('DIAL CLOSED'),
        //   tooltip: 'Speed Dial',
        //   heroTag: 'speed-dial-hero-tag',
        //   backgroundColor: Theme.of(context).accentColor,
        //   foregroundColor: Colors.white,
        //   elevation: 8.0,
        //   shape: CircleBorder(),
        //   children: <SpeedDialChild>[
        //     SpeedDialChild(
        //       child: const Icon(MaterialCommunityIcons.email),
        //       backgroundColor: Colors.teal[800],
        //       label: 'Email this kennel\'s run history',
        //       labelStyle: const TextStyle(fontSize: 18.0),
        //       onTap: () => {
        //             model
        //                 .sendRunCountReportByEmail(
        //                     kennelId: widget.kennel.kennelId,
        //                     kennelName: widget.kennel.kennelName)
        //                 .then((Map<String, String> result) {
        //               if (result['result']
        //                   .toLowerCase()
        //                   .startsWith('success')) {
        //                 Utilities.showAlert(
        //                     context,
        //                     'E-mail successfully sent',
        //                     'Your payment report has been successfully e-mailed to:\r\n\r\n${result['email']}\r\n\r\nIf you do not see it in the next few minutes, check your spam folder.',
        //                     'OK');
        //               }
        //             })
        //           },
        //     ),
        //     SpeedDialChild(
        //       child: const Icon(MaterialCommunityIcons.email_plus),
        //       backgroundColor: Colors.blue[900],
        //       label: 'Email all kennels run history',
        //       labelStyle: const TextStyle(fontSize: 18.0),
        //       onTap: () => {
        //             model
        //                 .sendRunCountReportByEmail(
        //                     kennelId: GUID_EMPTY,
        //                     kennelName: 'All of your Hash Kennels')
        //                 .then((Map<String, String> result) {
        //               if (result['result']
        //                   .toLowerCase()
        //                   .startsWith('success')) {
        //                 Utilities.showAlert(
        //                     context,
        //                     'E-mail successfully sent',
        //                     'Your payment report has been successfully e-mailed to:\r\n\r\n${result['email']}\r\n\r\nIf you do not see it in the next few minutes, check your spam folder.',
        //                     'OK');
        //               }
        //             })
        //           },
        //     ),
        //   ],
        // ),
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: themeAppBarBackground,
          title: Text(
            'Events for ${widget.kennel.kennel.kennelShortName}',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        body: _isLoading ? const HcCircularProgressIndicator() : _buildListView());
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isLoading = true;
    });

    final bool result = await syncUserDataService.updateFromBackend(SyncUserDataService.flagNarrowEventsTable, true);
    final String resultStr = result ? 'successfully' : 'unsuccessfully';
    print('Receipts data synchronized $resultStr');
    _refreshEventFromTables(true);
  }

  static const TextStyle headingStyle = TextStyle(fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 22.0, height: 0.6);

  static const TextStyle numberStyle = TextStyle(
    fontFamily: 'AvenirNextCondensedDemiBold',
    fontStyle: FontStyle.normal,
    fontSize: 22.0,
  );

  Widget _buildListView() {
    int publishedRunCount = 0;
    if (events.isNotEmpty) {
      publishedRunCount = events[0]['publishedRunCount'];
    }

    return Container(
      decoration: Backgrounds.defaultHcBackgroundLight(),
      padding: const EdgeInsets.only(top: 0.0),
      child: events.isEmpty
          ? Center(child: Text('No events found', style: headingStyleBlack))
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
                    padding: const EdgeInsets.only(left: 5, top: 5, right: 0, bottom: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          height: 75,
                          child: KennelLogo(
                            kennelLogoUrl: widget.kennel.kennel.kennelLogo,
                            kennelShortName: widget.kennel.kennel.kennelShortName,
                            logoHeight: 75.0,
                            rightPadding: 15.0,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                child: AutoSizeText(
                                  '${widget.kennel.kennel.kennelName}',
                                  //'Super fucking long text thats sure to overflow and more',
                                  //'999',
                                  overflow: TextOverflow.ellipsis,
                                  minFontSize: 18.0,
                                  maxLines: 1,
                                  style: numberStyle,
                                  textAlign: TextAlign.left,
                                ),
                                //color: Colors.green,
                              ),
                              Container(
                                child: AutoSizeText(
                                  'Published run count: ${publishedRunCount.toString()}',
                                  //'Super fucking long text thats sure to overflow and more',
                                  //'999',
                                  overflow: TextOverflow.ellipsis,
                                  minFontSize: 18.0,
                                  maxLines: 1,
                                  style: numberStyle,
                                  textAlign: TextAlign.left,
                                ),
                                //color: Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: events.length,
                      padding: const EdgeInsets.only(top: 5),
                      separatorBuilder: (BuildContext context, int index) => const Divider(
                        height: 1.0,
                        color: Colors.black45,
                      ),
                      //itemExtent: 58.0,
                      //shrinkWrap: true,
                      itemBuilder: (BuildContext context, int index) {
                        final Map<String, dynamic> event = events[index];
                        return Dismissible(
                          key: Key(event['eventId']),
                          confirmDismiss: (DismissDirection direction) {
                            if ((event['mismanagementRoleFlags'] & mmAuthCanEditRunVisibility) != 0) {
                              setState(() {
                                // swipe from right to left to indicate that
                                // the hasher either attended the run as a pack
                                // member or as a hare
                                final bool isVisible = direction == DismissDirection.endToStart;
                                updateEvent(event, isVisible: isVisible);
                              });
                            }
                            return Future<bool>.value(false);
                          },
                          background: Container(
                              color: ((event['mismanagementRoleFlags'] & mmAuthCanEditRunVisibility) == 0) ? Colors.grey[350] : Colors.red,
                              child: Row(children: const <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(left: 10.0),
                                  child: Icon(Ionicons.ios_eye_off, color: Colors.white, size: 35.0),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: 15.0),
                                  child: Text(
                                      // '${Utilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Bank Transfer',
                                      'Hide event',
                                      style: TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 17.0, height: 1.0)),
                                )
                              ])),
                          secondaryBackground: Container(
                            color: ((event['mismanagementRoleFlags'] & mmAuthCanEditRunVisibility) == 0) ? Colors.grey[350] : Colors.green,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: const <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(right: 15.0),
                                  child: Icon(Ionicons.ios_eye, color: Colors.white, size: 35.0),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(right: 15.0),
                                  child: Text(
                                      //'${Utilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Cash',
                                      'Show event',
                                      style: TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 17.0, height: 1.0)),
                                )
                              ],
                            ),
                          ),
                          onDismissed: (DismissDirection direction) {
                            print(direction.toString() + ' NOTE: We should never reach this point');
                          },
                          child: FilterEventListItem(
                            event: event,
                            kennelShortName: widget.kennel.kennel.kennelShortName,
                            updateEvent: (dynamic retVal) {
                              final EnumEventFilterType<int> ft = retVal;
                              switch (ft) {
                                case eventFilterType_showEvent:
                                  updateEvent(event, isVisible: true);
                                  break;
                                case eventFilterType_hideEvent:
                                  updateEvent(event, isVisible: false);
                                  break;
                                case eventFilterType_countEvent:
                                  updateEvent(event, isCountedRun: true);
                                  break;
                                case eventFilterType_doNotCountEvent:
                                  updateEvent(event, isCountedRun: false);
                                  break;
                                case eventFilterType_setRunNumber:
                                  setRunNumber(event, context);
                                  break;
                              }
                            },
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

  void setRunNumber(Map<String, dynamic> event, BuildContext context) {
    final RunNumberPopup otherPaymentPopup = RunNumberPopup(runNumber: event['absoluteEventNumber']);

    final Future<Map<String, String>> dlg = showDialog<Map<String, String>>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return otherPaymentPopup;
        });

    dlg.then((Map<String, String> x) {
      final String runNumber = x['runNumber'];

      if ((runNumber != null) && (runNumber != 'cancel')) {
        int rn = -1;
        if (runNumber == 'auto') {
          rn = 0;
        } else {
          rn = int.parse(runNumber);
        }

        updateEvent(event, asboluteEventNumber: rn);
      }
    });
  }

  Future<void> updateEvent(Map<String, dynamic> event, {bool isVisible, bool isCountedRun, int asboluteEventNumber}) async {
    await internalSqlDb.transaction<dynamic>((Transaction txn) async {
      final int guidFlag = isVisible ?? isCountedRun ?? (asboluteEventNumber != null) ? -3 : -2;
      final String sql = 'UPDATE ${eventsTableHelper.tableName} SET canEditRunAttendence = "$guidFlag" where eventId = "${event['eventId']}"';
      final int result = await txn.rawUpdate(sql);
      print(result.toString() + ' update to receipts table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
      _refreshEventFromTables(true);
    });

    final EventsService nSvc = EventsService();
    nSvc.updateEventDetails(event['eventId'], isVisible: isVisible, isCountedRun: isCountedRun, absoluteEventNumber: asboluteEventNumber).then((void dummy) {
      _refreshEventFromTables(true).then((void dummy) {
        setState(() {});
      });
    });
  }
}
