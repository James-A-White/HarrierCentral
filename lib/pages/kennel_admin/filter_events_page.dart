import 'package:harrier_central/imports.dart';

enum FilterEventsPageType { past, future }

class FilterEventsPage extends StatefulWidget {
  const FilterEventsPage({Key key, @required this.kennel, @required this.pageType}) : super(key: key);

  final KennelListAggregate kennel;
  final FilterEventsPageType pageType;

  @override
  FilterEventsPageState createState() => FilterEventsPageState();
}

class FilterEventsPageState extends State<FilterEventsPage> with SingleTickerProviderStateMixin {
  FilterEventsPageState();

  @override
  void dispose() {
    //_pageController?.dispose();
    _tabController.dispose();
    _calendarController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _initTabs();
    //_pageController = PageController(initialPage: 0, keepPage: true);
    _tabController = TabController(vsync: this, length: tabs.length);
    _refreshSqlTablesFromBackend(true);

    super.initState();
    _calendarController = CalendarController();
  }

  void _initTabs() {
    if (tabs.isEmpty) {
      tabs.add(const Tab(text: 'List'));
      tabs.add(const Tab(text: 'Calendar'));
    }
  }

  List<Tab> tabs = <Tab>[];

  TabController _tabController;
  CalendarController _calendarController;

  List<Map<String, dynamic>> _allEvents = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _selectedEvents = <Map<String, dynamic>>[];
  Map<DateTime, List<Map<String, dynamic>>> _calendarEvents = <DateTime, List<Map<String, dynamic>>>{};

  //PageController _pageController;

  GlobalKey tabKey;

  bool _isLoading = true;

  Future<void> _refreshSqlTablesFromBackend(bool showLoadingIndicator) async {
    if (showLoadingIndicator) {
      setState(() {
        _isLoading = true;
      });
    }

    final bool result = await G0<TableModel>().syncUserDataService.updateFromBackend(SyncUserDataService.flagNarrowEventsTable, true);
    final String resultStr = result ? 'successfully' : 'unsuccessfully';
    print('Events data synchronized $resultStr');

    _refreshEventFromTables(true).then((void dummy) {
      _calendarEvents = <DateTime, List<Map<String, dynamic>>>{};

      setState(() {
        for (int i = 0; i < _allEvents.length; i++) {
          final Map<String, dynamic> event = _allEvents[i];
          DateTime eventDate = DateTime.tryParse(event['eventStartDatetime']);
          if (eventDate != null) {
            eventDate = DateTime(eventDate.year, eventDate.month, eventDate.day);
            if (_calendarEvents[eventDate] == null) {
              _calendarEvents[eventDate] = <Map<String, dynamic>>[];
            }
            _calendarEvents[eventDate].add(event);
          }
        }
      });
    });
  }

  // Widget _buildEventList() {
  //   return ListView(
  //     children: _selectedEvents
  //         .map((dynamic event) => Container(
  //               decoration: BoxDecoration(
  //                 border: Border.all(width: 0.8),
  //                 borderRadius: BorderRadius.circular(12.0),
  //               ),
  //               margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
  //               child: ListTile(
  //                 title: Text(event['eventName'].toString()),
  //                 onTap: () => print('$event tapped!'),
  //               ),
  //             ))
  //         .toList(),
  //   );
  // }

  void _onDaySelected(DateTime day, List<dynamic> events, List<dynamic> holidays) {
    setState(() {
      _selectedEvents = events;
    });
  }

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
            (SELECT COUNT(*) FROM ${G0<TableModel>().eventsTableHelper.getTableName(AppDomainType.user)} evt2 where kennelId = "${widget.kennel.kennel.kennelId}" AND isVisible = 1) as publishedRunCount
          FROM ${G0<TableModel>().eventsTableHelper.getTableName(AppDomainType.user)} evt
          INNER JOIN ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.user)} hkm on hkm.kennelId = "${widget.kennel.kennel.kennelId}" and hkm.userId = "$userId"
          WHERE evt.kennelId = "${widget.kennel.kennel.kennelId}"
          AND datetime(evt.eventStartDatetime) $dateComparer datetime('now','localtime','$dateOffset')
          ORDER BY evt.eventStartDatetime $sortOrder
        
          ''';

      _allEvents = await G0<Database>().rawQuery(sql);
      setState(() {
        _isLoading = false;
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
        //   marginEnd: 18,
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
        //                 IveCoreUtilities.showAlert(
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
        //                 IveCoreUtilities.showAlert(
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
        body: _isLoading ? HcCircularProgressIndicator(key: UniqueKey()) : _buildListView());
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isLoading = true;
    });

    final bool result = await G0<TableModel>().syncUserDataService.updateFromBackend(SyncUserDataService.flagNarrowEventsTable, true);
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
    if (_allEvents.isNotEmpty) {
      publishedRunCount = _allEvents[0]['publishedRunCount'];
    }

    return Container(
      decoration: Backgrounds.defaultHcBackgroundLight(),
      padding: const EdgeInsets.only(top: 0.0),
      child: _allEvents.isEmpty
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
                  Container(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 1.0, right: 1.0),
                      child: TabBar(
                        labelStyle: const TextStyle(fontFamily: 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
                        unselectedLabelStyle: const TextStyle(fontFamily: 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
                        isScrollable: false,
                        unselectedLabelColor: Colors.black,
                        labelColor: Colors.white,
                        labelPadding: const EdgeInsets.only(top: 5, left: 20, right: 20),
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BubbleTabIndicator(
                          indicatorHeight: 35.0,
                          indicatorColor: Theme.of(context).buttonColor,
                          tabBarIndicatorSize: TabBarIndicatorSize.tab,
                          indicatorRadius: 20.0,
                        ),
                        tabs: tabs,
                        controller: _tabController,
                      ),
                    ),
                    height: 55.0,
                    //padding: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      // border: new Border.all(width: 1.0, color: Colors.black),
                      //shape: BoxShape.circle,
                      color: Colors.yellow.shade100,
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color.fromARGB(70, 0, 0, 0),
                          offset: Offset(0.0, 6.0),
                          blurRadius: 10.0,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: <Widget>[_listView(_allEvents), _calendarView()],
                    ),
                  ),
                ],
              )),
    );
  }

  Widget _calendarView() {
    return Container(
        color: Colors.transparent,
        padding: const EdgeInsets.only(top: 5),
        child: Column(
          children: <Widget>[
            TableCalendar(
              calendarController: _calendarController,
              events: _calendarEvents.cast<DateTime, List<dynamic>>(),
              onDaySelected: _onDaySelected,
            ),
            Expanded(child: _listView(_selectedEvents)),
          ],
        ));
  }

  Widget _listView(List<Map<String, dynamic>> listEvents) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: listEvents.length,
      padding: const EdgeInsets.only(top: 5),
      separatorBuilder: (BuildContext context, int index) => const Divider(
        height: 1.0,
        color: Colors.black45,
      ),
      //itemExtent: 58.0,
      //shrinkWrap: true,
      itemBuilder: (BuildContext context, int index) {
        final Map<String, dynamic> event = listEvents[index];
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
                      // '${IveCoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Bank Transfer',
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
                      //'${IveCoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Cash',
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
    await G0<Database>().transaction<dynamic>((Transaction txn) async {
      final int guidFlag = isVisible ?? isCountedRun ?? (asboluteEventNumber != null) ? -3 : -2;
      final String sql =
          'UPDATE ${G0<TableModel>().eventsTableHelper.getTableName(AppDomainType.user)} SET canEditRunAttendence = "$guidFlag" where eventId = "${event['eventId']}"';
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
