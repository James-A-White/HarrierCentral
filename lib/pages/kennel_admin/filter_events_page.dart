import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

enum FilterEventsPageType { past, future }

class FilterEventsPage extends StatefulWidget {
  const FilterEventsPage({Key key, @required this.kennel, @required this.pageType}) : super(key: key);

  final KennelListAggregate kennel;
  final FilterEventsPageType pageType;

  @override
  FilterEventsPageState createState() => FilterEventsPageState();
}

class FilterEventsPageState extends State<FilterEventsPage> with TickerProviderStateMixin {
  FilterEventsPageState();

  @override
  void dispose() {
    //_pageController?.dispose();
    _tabController.dispose();
    _calendarController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _initTabs();
    //_pageController = PageController(initialPage: 0, keepPage: true);
    _tabController = TabController(vsync: this, length: _tabs.length);
    _tabController.addListener(() {
      setState(() {});
    });
    _refreshSqlTablesFromBackend(true);

    super.initState();
    _calendarController = CalendarController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _animationController.forward();
    Future<void>.delayed(const Duration(milliseconds: 500)).then((void dummy) {
      setState(() {
        // force the buttons on the calendar to be drawn
      });
    });
  }

  void _initTabs() {
    if (_tabs.isEmpty) {
      _tabs.add(const Tab(text: 'Calendar'));
      _tabs.add(const Tab(text: 'List'));
    }
  }

  final List<Tab> _tabs = <Tab>[];

  TabController _tabController;
  CalendarController _calendarController;
  AnimationController _animationController;

  List<Map<String, dynamic>> _allEventsSqlResult = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _publishedRunCountSqlResult = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _selectedEvents = <Map<String, dynamic>>[];
  final Map<DateTime, List<Map<String, dynamic>>> _calendarEvents = <DateTime, List<Map<String, dynamic>>>{};
  Future<DateTime> _dateBeingUpdated = Future<DateTime>.value(null);

  //PageController _pageController;

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

    _refreshEventFromTables(true).then((void dummy) {});
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
      _selectedEvents = events.cast<Map<String, dynamic>>();
    });
  }

  Future<void> _refreshEventFromTables(bool forceRefresh) async {
    final String sortOrder = widget.pageType == FilterEventsPageType.future ? 'ASC' : 'DESC';
    final String dateComparer = widget.pageType == FilterEventsPageType.future ? '>=' : '<=';
    //final String dateOffset = widget.pageType == FilterEventsPageType.future ? '-5 minutes' : '+5 minutes';

    final String userId = getStringPref(StringPrefsEnum.userId);

    //       (SELECT COUNT(*) FROM ${G0<TableModel>().eventsTableHelper.getTableName(AppDomainType.user)} evt2 where kennelId = "${widget.kennel.kennel.kennelId}" AND isVisible = 1) as publishedRunCount//

    try {
      final String sql = ''' 

          SELECT COUNT(*) as publishedRunCount  
          FROM ${G0<TableModel>().eventsTableHelper.getTableName(AppDomainType.user)} evt 
          WHERE kennelId = "${widget.kennel.kennel.kennelId}" AND isVisible = 1
          AND date(datetime(evt.eventStartDatetime)) $dateComparer date(datetime('now','localtime'))
          ''';

      _publishedRunCountSqlResult = await G0<Database>().rawQuery(sql);
    } catch (e) {
      print(e);
    }

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
            hkm.appAccessFlags,
            evt.canEditRunAttendence
          FROM ${G0<TableModel>().eventsTableHelper.getTableName(AppDomainType.user)} evt
          INNER JOIN ${G0<TableModel>().hasherKennelMapTableHelper.getTableName(AppDomainType.user)} hkm on hkm.kennelId = "${widget.kennel.kennel.kennelId}" and hkm.userId = "$userId"
          WHERE evt.kennelId = "${widget.kennel.kennel.kennelId}"
          AND date(datetime(evt.eventStartDatetime)) $dateComparer date(datetime('now','localtime'))
          ORDER BY evt.${G0<TableModel>().eventsTableHelper.colEventStartDatetime} $sortOrder, evt.${G0<TableModel>().eventsTableHelper.colEventNumber} $sortOrder
        
          ''';

      _allEventsSqlResult = await G0<Database>().rawQuery(sql);
      setState(() {
        _calendarEvents.clear();
        _selectedEvents.clear();

        for (int i = 0; i < _allEventsSqlResult.length; i++) {
          final Map<String, dynamic> event = _allEventsSqlResult[i];
          DateTime eventDate = DateTime.tryParse(event['eventStartDatetime']);
          if (eventDate != null) {
            eventDate = _toDateOnly(eventDate);
            if (_calendarEvents[eventDate] == null) {
              _calendarEvents[eventDate] = <Map<String, dynamic>>[];
            }
            _calendarEvents[eventDate].add(event);

            // rebuild the items in _selectedDate so that state changes
            // are reflected in the UI when someone changes an event's
            // properties
            if (_calendarController?.selectedDay != null) {
              if (eventDate == _toDateOnly(_calendarController.selectedDay)) {
                _selectedEvents.add(event);
              }
            }
          }
        }

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
        resizeToAvoidBottomInset: false,
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
    if (_publishedRunCountSqlResult.isNotEmpty) {
      publishedRunCount = _publishedRunCountSqlResult[0]['publishedRunCount'];
    }

    return Container(
      decoration: Backgrounds.defaultHcBackgroundLight(),
      padding: const EdgeInsets.only(top: 0.0),
      child: RefreshIndicator(
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
                              widget.pageType == FilterEventsPageType.past
                                  ? 'Past run count: ${publishedRunCount.toString()}'
                                  : 'Future run count: ${publishedRunCount.toString()}',
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
                    tabs: _tabs,
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
                  children: <Widget>[_calendarView(), _listView(_allEventsSqlResult)],
                ),
              ),
            ],
          )),
    );
  }

  DateTime _toDateOnly(DateTime d) {
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }

  Widget _calendarView() {
    return Column(children: <Widget>[
      //
      Container(
        decoration: BoxDecoration(
          // border: new Border.all(width: 1.0, color: Colors.black),
          //shape: BoxShape.circle,
          color: Colors.grey.shade300,
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color.fromARGB(70, 0, 0, 0),
              offset: Offset(0.0, 6.0),
              blurRadius: 10.0,
            ),
          ],
        ),
        // TODO(James): Clean up builders to get rid of duplicate code
        child: Column(
          children: <Widget>[
            const Divider(color: Colors.black, height: 1.0),
            Container(
              //color: Colors.white,
              padding: const EdgeInsets.only(bottom: 10.0),
              child: TableCalendar(
                onCalendarCreated: (DateTime firstVisibleDay, DateTime lastVisibleDay, CalendarFormat calendarFormat) {
                  //if (_calendarController.selectedDay == null) {
                  _calendarController.setSelectedDay(DateTime.now().add(const Duration(days: 1)), runCallback: false);
                  //}
                },
                rowHeight: 35.0,
                //startDay: DateTime.now(),
                headerStyle: HeaderStyle(
                  rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.black),
                  leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.black),
                  centerHeaderTitle: true,
                  formatButtonDecoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  formatButtonTextStyle: const TextStyle().copyWith(color: Colors.white),
                ),
                onDayLongPressed: (DateTime datePressed, List<dynamic> list1, List<dynamic> list2) {
                  _calendarController.setSelectedDay(datePressed);

                  // only allow the date popup if the conditions allowing for new runs is met
                  if (datePressed != null &&
                      _toDateOnly(datePressed).difference(_toDateOnly(DateTime.now())).inDays >= 0 &&
                      (_calendarEvents[_toDateOnly(datePressed)]?.length ?? 0) == 0) {
                    _showEventPopup(datePressed);
                  }
                },
                calendarController: _calendarController,
                events: _calendarEvents.cast<DateTime, List<dynamic>>(),
                onDaySelected: _onDaySelected,
                availableCalendarFormats: const <CalendarFormat, String>{
                  CalendarFormat.month: 'Week',
                  CalendarFormat.week: 'Month',
                },
                calendarStyle: CalendarStyle(
                  selectedColor: Colors.deepOrange[400],
                  todayColor: Colors.deepOrange[200],
                  markersColor: Colors.brown[700],
                  outsideDaysVisible: false,
                ),
                builders: CalendarBuilders(
                  selectedDayBuilder: (BuildContext context, DateTime date, _) {
                    return FutureBuilder<DateTime>(
                        future: _dateBeingUpdated,
                        builder: (BuildContext context, AsyncSnapshot<DateTime> snapshot) {
                          return ((snapshot.hasData) && (_toDateOnly(snapshot.data) == _toDateOnly(date)))
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: (_calendarEvents[_toDateOnly(date)]?.length ?? 0) == 0
                                        ? _toDateOnly(date).difference(_toDateOnly(DateTime.now())).inDays == 0
                                            ? Colors.blue.shade100
                                            : _toDateOnly(date).difference(_toDateOnly(DateTime.now())).inDays >= 0
                                                ? Colors.white
                                                : Colors.grey.shade200
                                        : (_calendarEvents[_toDateOnly(date)]?.length ?? 0) > 1
                                            ? Colors.red.shade100
                                            : _calendarEvents[_toDateOnly(date)][0]['isVisible'] == 0
                                                ? Colors.grey.shade300
                                                : _calendarEvents[_toDateOnly(date)][0]['isCountedRun'] == 1
                                                    ? Colors.green.shade100
                                                    : Colors.yellow.shade200,
                                    border: Border.all(
                                      color: Colors.red,
                                      width: 3.0,
                                    ),
                                  ),
                                  // margin: const EdgeInsets.all(4.0),
                                  // padding: const EdgeInsets.only(top: 5.0, left: 6.0),
                                  //color: Colors.deepOrange[300],
                                  width: 100,
                                  height: 50,
                                  child: Icon(delayIcon, color: Colors.blue),
                                )
                              : FadeTransition(
                                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(_animationController),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: (_calendarEvents[_toDateOnly(date)]?.length ?? 0) == 0
                                          ? _toDateOnly(date).difference(_toDateOnly(DateTime.now())).inDays == 0
                                              ? Colors.blue.shade100
                                              : _toDateOnly(date).difference(_toDateOnly(DateTime.now())).inDays >= 0
                                                  ? Colors.white
                                                  : Colors.grey.shade200
                                          : (_calendarEvents[_toDateOnly(date)]?.length ?? 0) > 1
                                              ? Colors.red.shade100
                                              : _calendarEvents[_toDateOnly(date)][0]['isVisible'] == 0
                                                  ? Colors.grey.shade300
                                                  : _calendarEvents[_toDateOnly(date)][0]['isCountedRun'] == 1
                                                      ? Colors.green.shade100
                                                      : Colors.yellow.shade200,
                                      border: Border.all(
                                        color: Colors.red,
                                        width: 3.0,
                                      ),
                                    ),
                                    // margin: const EdgeInsets.all(4.0),
                                    // padding: const EdgeInsets.only(top: 5.0, left: 6.0),
                                    //color: Colors.deepOrange[300],
                                    width: 100,
                                    height: 50,
                                    child: Text(
                                      '${date.day}',
                                      style: const TextStyle().copyWith(fontSize: 16.0),
                                    ),
                                  ),
                                );
                        });
                  },
                  todayDayBuilder: (BuildContext context, DateTime date, _) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        border: Border.all(
                          color: Colors.black26,
                          width: 1.0,
                        ),
                      ),
                      width: 100,
                      height: 50,
                      child: Text(
                        '${date.day}',
                        style: const TextStyle().copyWith(fontSize: 16.0),
                      ),
                    );
                  },
                  dayBuilder: (BuildContext context, DateTime date, _) {
                    return FutureBuilder<DateTime>(
                        future: _dateBeingUpdated,
                        builder: (BuildContext context, AsyncSnapshot<DateTime> snapshot) {
                          return ((snapshot.hasData) && _toDateOnly(snapshot.data) == _toDateOnly(date))
                              ? Container(color: Colors.pink)
                              : Container(
                                  // margin: const EdgeInsets.all(4.0),
                                  // padding: const EdgeInsets.only(top: 5.0, left: 6.0),
                                  decoration: BoxDecoration(
                                    color: (_calendarEvents[_toDateOnly(date)]?.length ?? 0) == 0
                                        ? _toDateOnly(date).difference(_toDateOnly(DateTime.now())).inDays >= 0
                                            ? Colors.white
                                            : Colors.grey.shade200
                                        : (_calendarEvents[_toDateOnly(date)]?.length ?? 0) > 1
                                            ? Colors.red.shade100
                                            : _calendarEvents[_toDateOnly(date)][0]['isVisible'] == 0
                                                ? Colors.grey.shade300
                                                : _calendarEvents[_toDateOnly(date)][0]['isCountedRun'] == 1
                                                    ? Colors.green.shade100
                                                    : Colors.yellow.shade200,
                                    border: Border.all(
                                      color: Colors.black26,
                                      width: 1.0,
                                    ),
                                  ),
                                  width: 100,
                                  height: 50,
                                  child: Text(
                                    '${date.day}',
                                    style: const TextStyle().copyWith(
                                        fontSize: 16.0, color: _toDateOnly(date).difference(_toDateOnly(DateTime.now())).inDays >= 0 ? Colors.black : Colors.grey.shade500),
                                  ),
                                );
                        });
                  },
                  // markersBuilder: (context, date, events, holidays) {
                  //   final children = <Widget>[];

                  //   if (events.isNotEmpty) {
                  //     children.add(
                  //       Positioned(
                  //         right: 1,
                  //         bottom: 1,
                  //         child: _buildEventsMarker(date, events),
                  //       ),
                  //     );
                  //   }

                  //   if (holidays.isNotEmpty) {
                  //     children.add(
                  //       Positioned(
                  //         right: -2,
                  //         top: -2,
                  //         child: _buildHolidaysMarker(),
                  //       ),
                  //     );
                  //   }

                  //   return children;
                  // },
                ),
              ),
            ),
            const SizedBox(height: 5.0),
            if (_calendarController?.selectedDay != null &&
                _toDateOnly(_calendarController.selectedDay).difference(_toDateOnly(DateTime.now())).inDays >= 0 &&
                (_calendarEvents[_toDateOnly(_calendarController.selectedDay)]?.length ?? 0) == 0) ...<Widget>[_buildButtons()],
            if (_calendarController?.selectedDay != null &&
                _toDateOnly(_calendarController.selectedDay).difference(_toDateOnly(DateTime.now())).inDays >= 0 &&
                (_calendarEvents[_toDateOnly(_calendarController.selectedDay)]?.length ?? 0) == 1) ...<Widget>[_buildEditButton()],
          ],
        ),
      ),
      Expanded(child: _listView(_selectedEvents)),
    ]);
  }

  Widget _buildEditButton() {
    return Column(
      children: <Widget>[
        // ElevatedButton(
        //   child: Text(
        //     'Add run',
        //     style: buttonLabelStyleMedium,
        //   ),
        //   onPressed: () {
        //     setState(() {
        //       //_calendarController.setCalendarFormat(CalendarFormat.month);
        //     });
        //   },
        // ),

        ElevatedButton(
          child: Text('Edit event', style: buttonLabelStyleMedium),
          onPressed: () async {
            final dynamic rawEvent = _calendarEvents[_toDateOnly(_calendarController.selectedDay)][0];

            if ((rawEvent != null) && (rawEvent['eventId'] != null)) {
              RunDetailAggregate rda = await CommonQueries.getEventFromLocalCache(rawEvent['eventId'], getStringPref(StringPrefsEnum.userId));

              Navigator.push<dynamic>(
                  context,
                  MaterialPageRoute<dynamic>(
                      builder: (BuildContext context) => EditRunDetailsPage(rda, (String eventId) async {
                            final String userId = getStringPref(StringPrefsEnum.userId);
                            rda = await CommonQueries.getEventFromLocalCache(eventId, userId);
                            _isLoading = false;
                            return rda;
                          }))).then((void dummy) {
                _refreshSqlTablesFromBackend(true);
              });
            }
          },
        ),

        const SizedBox(height: 18.0),
      ],
    );
  }

  Widget _buildButtons() {
    return Column(
      children: <Widget>[
        // ElevatedButton(
        //   child: Text(
        //     'Add run',
        //     style: buttonLabelStyleMedium,
        //   ),
        //   onPressed: () {
        //     setState(() {
        //       //_calendarController.setCalendarFormat(CalendarFormat.month);
        //     });
        //   },
        // ),

        ElevatedButton(
          child: Text('Add event', style: buttonLabelStyleMedium),
          onPressed: () async {
            RunDetailAggregate rda = await CommonQueries.getNewEvent(widget.kennel.kennel.kennelId, getStringPref(StringPrefsEnum.userId), _calendarController?.selectedDay);

            Navigator.push<dynamic>(
                context,
                MaterialPageRoute<dynamic>(
                    builder: (BuildContext context) => EditRunDetailsPage(rda, (String eventId) async {
                          final String userId = getStringPref(StringPrefsEnum.userId);
                          rda = await CommonQueries.getEventFromLocalCache(eventId, userId);
                          _isLoading = false;
                          return rda;
                        }))).then((void dummy) {
              _refreshSqlTablesFromBackend(true);
            });
          },
        ),
        const SizedBox(height: 10.0),
        ElevatedButton(
          child: Text('Add event placeholder', style: buttonLabelStyleMedium),
          onPressed: () {
            setState(() {
              _showEventPopup(_calendarController.selectedDay);
            });
          },
        ),

        const SizedBox(height: 18.0),
      ],
    );
  }

  Future<void> _showEventPopup(DateTime eventStartDate) async {
    final String title = 'Create new event on ' + DateFormat('E, MMM d').format(eventStartDate);

    final CreateNewEventPopup newEventPopup = CreateNewEventPopup(title);

    final Map<String, String> x = await showDialog<Map<String, String>>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return newEventPopup;
        });

    final String eventName = x['eventName'];
    final String type = x['type'];

    if (type != 'cancel') {
      setState(() {
        _dateBeingUpdated = Future<DateTime>.value(eventStartDate);
      });

      final EventsService nSvc = EventsService();
      nSvc
          .addEditEvent(
        kennelId: widget.kennel.kennel.kennelId,
        isVisible: true,
        isCountedRun: type == eventFilterType_countEvent.value.toString() ? true : false,
        eventName: eventName,
        eventStartDatetime: _toDateOnly(eventStartDate),
      )
          .then((String eventId) {
        _refreshEventFromTables(true).then((void dummy) {
          setState(() {
            _dateBeingUpdated = Future<DateTime>.value(null);
          });
        });
      });
    }
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
            if ((event['appAccessFlags'] & authCanManageRuns) != 0) {
              setState(() {
                // swipe from right to left to indicate that
                // the hasher either attended the run as a pack
                // member or as a hare
                final bool isVisible = direction == DismissDirection.endToStart;
                updateEvent(eventId: event['eventId'], isVisible: isVisible);
              });
            }
            return Future<bool>.value(false);
          },
          background: Container(
              color: ((event['appAccessFlags'] & authCanManageRuns) == 0) ? Colors.grey[350] : Colors.red,
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
            color: ((event['appAccessFlags'] & authCanManageRuns) == 0) ? Colors.grey[350] : Colors.green,
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
                  updateEvent(eventId: event['eventId'], isVisible: true);
                  break;
                case eventFilterType_hideEvent:
                  updateEvent(eventId: event['eventId'], isVisible: false);
                  break;
                case eventFilterType_countEvent:
                  updateEvent(eventId: event['eventId'], isCountedRun: true);
                  break;
                case eventFilterType_doNotCountEvent:
                  updateEvent(eventId: event['eventId'], isCountedRun: false);
                  break;
                case eventFilterType_setRunNumber:
                  setRunNumber(event, context);
                  break;
                case eventFilterType_refreshOnly:
                  _refreshSqlTablesFromBackend(false);
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
    final RunNumberPopup newEventPopup = RunNumberPopup(runNumber: event['absoluteEventNumber']);

    final Future<Map<String, String>> dlg = showDialog<Map<String, String>>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return newEventPopup;
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

        updateEvent(eventId: event['eventId'], asboluteEventNumber: rn);
      }
    });
  }

  Future<void> updateEvent({String eventId, bool isVisible, bool isCountedRun, int asboluteEventNumber, String kennelId}) async {
    if (eventId != null) {
      await G0<Database>().transaction<dynamic>((Transaction txn) async {
        final int flag = isVisible ?? isCountedRun ?? (asboluteEventNumber != null) ? -3 : -2;
        final String sql = 'UPDATE ${G0<TableModel>().eventsTableHelper.getTableName(AppDomainType.user)} SET canEditRunAttendence = "$flag" where eventId = "$eventId"';
        final int result = await txn.rawUpdate(sql);
        print(result.toString() + ' update to events table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
        _refreshEventFromTables(true);
      });
    }

    final EventsService nSvc = EventsService();
    nSvc.addEditEvent(eventId: eventId, kennelId: kennelId, isVisible: isVisible, isCountedRun: isCountedRun, absoluteEventNumber: asboluteEventNumber).then((void dummy) {
      _refreshEventFromTables(true).then((void dummy) {
        setState(() {});
      });
    });
  }
}
