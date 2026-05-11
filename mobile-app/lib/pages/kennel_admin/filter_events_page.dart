import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

enum FilterEventsPageType { past, future }

class AddEditEventsPage extends StatefulWidget {
  const AddEditEventsPage({
    super.key,
    required this.kennel,
    required this.pageType,
  });

  final KennelListAggregate kennel;
  final FilterEventsPageType pageType;

  @override
  AddEditEventsPageState createState() => AddEditEventsPageState();
}

class AddEditEventsPageState extends State<AddEditEventsPage>
    with TickerProviderStateMixin {
  AddEditEventsPageState();

  @override
  void dispose() {
    //_pageController?.dispose();
    _tabController.dispose();
    //_calendarController.dispose();
    _selectedEvents.dispose();
    _animationController.dispose();
    _focusedDay.dispose();
    _selectedDay.dispose();
    super.dispose();
  }

  static final DateTime _dateTimeUnassigned = DateTime(1900);

  @override
  void initState() {
    super.initState();
    _initTabs();
    //_pageController = PageController(initialPage: 0, keepPage: true);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _tabController = TabController(vsync: this, length: _tabs.length);
    _tabController.addListener(() {
      setState(() {});
    });
    unawaited(
      _refreshSqlTablesFromBackend(true).then((void _) {
        _refreshList(
          selectedDay: _focusedDay.value,
          focusedDay: _focusedDay.value,
        );
        unawaited(
          Future<void>.delayed(const Duration(milliseconds: 500)).then((
            void _,
          ) {
            setState(() {
              // force the buttons on the calendar to be drawn
            });
          }),
        );
      }),
    );

    unawaited(_animationController.forward());
  }

  void _initTabs() {
    if (_tabs.isEmpty) {
      _tabs.add(const Tab(text: 'Calendar'));
      _tabs.add(const Tab(text: 'List'));
    }
  }

  final List<Tab> _tabs = <Tab>[];

  late TabController _tabController;

  //PageController _pageController;
  late AnimationController _animationController;

  final List<LiteEventModel> _allEvents = <LiteEventModel>[];
  List<Map<String, dynamic>> _publishedRunCountSqlResult =
      <Map<String, dynamic>>[];
  final ValueNotifier<List<LiteEventModel>> _selectedEvents =
      ValueNotifier<List<LiteEventModel>>(<LiteEventModel>[]);
  final Map<DateTime, List<LiteEventModel>> _calendarEvents =
      <DateTime, List<LiteEventModel>>{};
  Future<DateTime> _dateBeingUpdated = Future<DateTime>.value(
    _dateTimeUnassigned,
  );

  //PageController _pageController;

  bool _isLoading = true;

  Future<void> _refreshSqlTablesFromBackend(bool showLoadingIndicator) async {
    if (showLoadingIndicator) {
      setState(() {
        _isLoading = true;
      });
    }

    await tableModel.syncUserDataService.updateFromBackend(
      EnumDataTables.events.flag,
      true,
      debugText: 'filter_events_page: Events',
    );
    //final String resultStr = result ? 'successfully' : 'unsuccessfully';
    //print('Events data synchronized $resultStr');

    await _refreshEventFromTables(true);
    if (showLoadingIndicator) {
      setState(() {
        _isLoading = false;
      });
    }
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
  //                 onTap: () => //print('$event tapped!'),
  //               ),
  //             ))
  //         .toList(),
  //   );
  // }

  // void _onDaySelected(DateTime day, List<dynamic> events, List<dynamic> holidays) {
  //   setState(() {
  //     _selectedDate = day;
  //     _selectedEvents = events.cast<Map<String, dynamic>>();
  //   });
  // }

  Future<void> _refreshEventFromTables(bool forceRefresh) async {
    final String sortOrder = widget.pageType == FilterEventsPageType.future
        ? 'ASC'
        : 'DESC';
    final String dateComparer = widget.pageType == FilterEventsPageType.future
        ? '>='
        : '<=';
    //final String dateOffset = widget.pageType == FilterEventsPageType.future ? '-5 minutes' : '+5 minutes';

    final String userId = getStringPref(StringPrefsEnum.userId)!;

    //       (SELECT COUNT(*) FROM ${EnumDataTables.events.commonTableName} evt2 where kennelId = "${widget.kennel.kennel.kennelId}" AND isVisible = 1) as publishedRunCount//

    final offsetFromGmtToLocal = Utilities.getSqfliteTimeOffset();
    try {
      final String sql =
          '''

          SELECT COUNT(*) as publishedRunCount  
          FROM ${EnumDataTables.events.commonTableName} evt 
          WHERE kennelId = "${widget.kennel.kennel.kennelId}" AND isVisible = 1
          AND date(datetime(evt.eventStartDatetime)) $dateComparer date(datetime('now','$offsetFromGmtToLocal'))
          ''';

      _publishedRunCountSqlResult = await database.rawQuery(sql);
    } catch (e) {
      //print(e);
    }

    try {
      final String sql =
          '''

          SELECT
            evt.${tableModel.eventsTableHelper.colEventId},
            evt.${tableModel.eventsTableHelper.colIsVisible},
            evt.${tableModel.eventsTableHelper.colIsCountedRun},
            evt.${tableModel.eventsTableHelper.colAbsoluteEventNumber},
            evt.${tableModel.eventsTableHelper.colEventFacebookId},
            evt.${tableModel.eventsTableHelper.colEventName},
            evt.${tableModel.eventsTableHelper.colEventNumber},
            evt.${tableModel.eventsTableHelper.colEventStartDatetime},
            evt.${tableModel.eventsTableHelper.colEventInboundIntegrationId},
            hkm.${tableModel.hasherKennelMapTableHelper.colAppAccessFlags},
            evt.${tableModel.eventsTableHelper.colCanEditRunAttendence}
          FROM ${EnumDataTables.events.commonTableName} evt
          INNER JOIN ${EnumDataTables.hasherKennelMap.commonTableName} hkm on hkm.${tableModel.hasherKennelMapTableHelper.colKennelId} = "${widget.kennel.kennel.kennelId}" and hkm.${tableModel.hasherKennelMapTableHelper.colUserId} = "$userId"
          WHERE evt.${tableModel.eventsTableHelper.colKennelId} = "${widget.kennel.kennel.kennelId}"
          AND date(datetime(evt.${tableModel.eventsTableHelper.colEventStartDatetime})) $dateComparer date(datetime('now','$offsetFromGmtToLocal'))
          ORDER BY evt.${tableModel.eventsTableHelper.colEventStartDatetime} $sortOrder, evt.${tableModel.eventsTableHelper.colEventNumber} $sortOrder
        
          ''';

      final List<Map<String, dynamic>> allEventsSqlResult = await database
          .rawQuery(sql);

      _calendarEvents.clear();
      _allEvents.clear();
      if (_selectedEvents.value.isNotEmpty) {
        _selectedEvents.value.clear();
      }

      for (int i = 0; i < allEventsSqlResult.length; i++) {
        final LiteEventModel event = LiteEventModel.fromJson(
          allEventsSqlResult[i],
        );
        _allEvents.add(event);
        DateTime? eventDate = event.eventStartDatetime;
        eventDate = _toDateOnly(eventDate);
        if (_calendarEvents[eventDate] == null) {
          _calendarEvents[eventDate] = <LiteEventModel>[];
        }
        _calendarEvents[eventDate]!.add(event);

        // rebuild the items in _selectedDate so that state changes
        // are reflected in the UI when someone changes an event's
        // properties
        // if (_calendarController?.selectedDay != null) {
        //   if (eventDate == _toDateOnly(_calendarController.selectedDay)) {
        //     _selectedEvents.add(event);
        //   }
        // }
      }

      _isLoading = false;
    } catch (e) {
      //print(e);
    }
  }

  int pageIndex = 1;

  // void refreshListFromDb(bool showLoadingIndicator) {
  //   model.getUserEventsFromBackend(showLoadingIndicator, 0, 1,1).then((void _) {
  //     myRunCount = model.userEventList
  //         .where(
  //             (Event ueh) => ueh.attendenceState >= attendenceAtHash.value)
  //         .length;
  //     updateRunCounts();
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
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
      //   onOpen: () => //print('OPENING DIAL'),
      //   onClose: () => //print('DIAL CLOSED'),
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
      //                 await Utilities.showAlert(
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
      //       backgroundColor: hc_blue,
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
      //                 await Utilities.showAlert(
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
        iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
        title: Text(
          'Events for ${widget.kennel.kennel.kennelShortName}',
          style: ts_appBarTitle,
        ),
      ),
      body: _isLoading
          ? const HcAppCircularProgressIndicator(key: Key('9844430132'))
          : _buildListView(),
    );
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isLoading = true;
    });

    await tableModel.syncUserDataService.updateFromBackend(
      EnumDataTables.events.flag,
      true,
      debugText: 'filter_events_page: Events',
    );
    //final String resultStr = result ? 'successfully' : 'unsuccessfully';
    //print('Receipts data synchronized $resultStr');
    await _refreshEventFromTables(true);
  }

  Widget _buildListView() {
    int publishedRunCount = 0;
    if (_publishedRunCountSqlResult.isNotEmpty) {
      publishedRunCount = _publishedRunCountSqlResult[0]['publishedRunCount'];
    }

    return Container(
      decoration: Backgrounds.defaultHcBackgroundLight(),
      padding: const EdgeInsets.only(top: 0.0),
      child: RefreshIndicator(
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
              padding: const EdgeInsets.only(
                left: 5,
                top: 5,
                right: 0,
                bottom: 5,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    height: 75,
                    child: KennelLogo(
                      kennelId: widget.kennel.kennel.kennelId,
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
                        AutoSizeText(
                          widget.kennel.kennel.kennelName,
                          //'Super fucking long text thats sure to overflow and more',
                          //'999',
                          overflow: TextOverflow.ellipsis,
                          minFontSize: 18.0,
                          maxLines: 1,
                          style: ts_titleCondensedBlack,
                          textAlign: TextAlign.left,
                        ),
                        AutoSizeText(
                          widget.pageType == FilterEventsPageType.past
                              ? 'Past run count: ${publishedRunCount.toString()}'
                              : 'Future run count: ${publishedRunCount.toString()}',
                          //'Super fucking long text thats sure to overflow and more',
                          //'999',
                          overflow: TextOverflow.ellipsis,
                          minFontSize: 18.0,
                          maxLines: 1,
                          style: ts_titleCondensedBlack,
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 50.0,
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
              child: Padding(
                padding: const EdgeInsets.only(left: 1.0, right: 1.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),

                  // reviewed for 2.0+
                  child: TabBar(
                    labelStyle: ts_tabSelected,
                    unselectedLabelStyle: ts_tabUnselected,
                    isScrollable: false,
                    unselectedLabelColor: Colors.black,
                    labelColor: Colors.white,
                    labelPadding: const EdgeInsets.only(top: 5),
                    indicatorPadding: EdgeInsetsGeometry.only(
                      top: 8,
                      bottom: 8,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: hc_red,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    tabs: _tabs,
                    controller: _tabController,
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[_calendarView(), _listView(_allEvents)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditButton() {
    return Column(
      children: <Widget>[
        ElevatedButton(
          child: Text('Edit run', style: ts_button),
          onPressed: () async {
            final LiteEventModel? rawEvent =
                _calendarEvents[_toDateOnly(_selectedDay.value)]?[0];
            if (rawEvent != null) {
              RunAdminAggregate? rda =
                  await CommonQueries.getEventAdminInfoFromLocalCache(
                    rawEvent.eventId,
                    getStringPref(StringPrefsEnum.userId)!,
                  );

              if (rda != null) {
                if (!mounted) return;
                await Navigator.push<dynamic>(
                  context,
                  MaterialPageRoute<dynamic>(
                    builder: (BuildContext context) => EditRunDetailsPage(
                      false,
                      rda!,
                      (String eventId) async {
                        final String userId = getStringPref(
                          StringPrefsEnum.userId,
                        )!;
                        rda =
                            await CommonQueries.getEventAdminInfoFromLocalCache(
                              eventId,
                              userId,
                            );
                        _isLoading = false;
                        return rda;
                      },
                    ),
                  ),
                );
                await _refreshSqlTablesFromBackend(true);
              }
            }
          },
        ),
        const SizedBox(height: 10.0),
      ],
    );
  }

  Widget _buildAddButtons() {
    return OverflowBar(
      alignment: MainAxisAlignment.center,
      spacing: 20.0,
      overflowAlignment: OverflowBarAlignment.center,
      children: <Widget>[
        ElevatedButton(
          style: ButtonStyle(
            padding: WidgetStateProperty.all<EdgeInsets>(
              const EdgeInsets.symmetric(horizontal: 15.0),
            ),
          ),
          onPressed: () async {
            RunAdminAggregate? rda = await CommonQueries.getNewEvent(
              widget.kennel.kennel.kennelId,
              getStringPref(StringPrefsEnum.userId)!,
              _selectedDay.value,
            );
            //RunAdminAggregate rda = null;

            if (rda != null) {
              if (!mounted) return;
              await Navigator.push<dynamic>(
                context,
                MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) => EditRunDetailsPage(
                    true,
                    rda!,
                    (String eventId) async {
                      final String userId = getStringPref(
                        StringPrefsEnum.userId,
                      )!;
                      rda = await CommonQueries.getEventAdminInfoFromLocalCache(
                        eventId,
                        userId,
                      );
                      _isLoading = false;
                      return rda;
                    },
                  ),
                ),
              );
            }

            await _refreshSqlTablesFromBackend(true);
            await _refreshEventFromTables(true);
            _refreshList();
          },
          child: Text('Add run', style: ts_button),
        ),
        ElevatedButton(
          style: ButtonStyle(
            padding: WidgetStateProperty.all<EdgeInsets>(
              const EdgeInsets.symmetric(horizontal: 15.0, vertical: 0.0),
            ),
          ),
          onPressed: () async {
            await _showEventPopup(_selectedDay.value);
            setState(() {});
          },
          child: Text('Add run placeholder', style: ts_button),
        ),
      ],
    );
  }

  Future<void> _showEventPopup(DateTime eventStartDate) async {
    final String title =
        'Create new event on ${DateFormat('E, MMM d').format(eventStartDate)}';

    final CreateNewEventPopup newEventPopup = CreateNewEventPopup(title);

    final Map<String, String>? x = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return newEventPopup;
      },
    );

    final String eventName = x?['eventName'] ?? '';
    final String type = x?['type'] ?? 'cancel';

    if (type != 'cancel') {
      setState(() {
        _dateBeingUpdated = Future<DateTime>.value(eventStartDate);
      });

      final EventsService nSvc = EventsService();
      await nSvc.addEditEvent(
        kennelId: widget.kennel.kennel.kennelId,
        isVisible: true,
        isCountedRun: type == eventFilterType_countEvent.value.toString()
            ? true
            : false,
        eventName: eventName,
        eventStartDatetime: _toDateOnly(eventStartDate),
      );

      await _refreshEventFromTables(true);
      setState(() {
        _dateBeingUpdated = Future<DateTime>.value(_dateTimeUnassigned);
        _refreshList();
      });
    }
  }

  String _itemBeingUpdatedId = '';

  Widget _listView(List<LiteEventModel> listEvents) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: listEvents.length,
      padding: const EdgeInsets.only(top: 5),
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(height: 1.0, color: Colors.black45),
      //itemExtent: 58.0,
      //shrinkWrap: true,
      itemBuilder: (BuildContext context, int index) {
        final LiteEventModel event = listEvents[index];
        return Dismissible(
          key: Key(event.eventId),
          confirmDismiss: (DismissDirection direction) async {
            if ((event.appAccessFlags & authCanManageRuns) != 0) {
              // the hasher either attended the run as a pack
              // member or as a hare
              final bool isVisible = direction == DismissDirection.endToStart;
              await _updateEvent(eventId: event.eventId, isVisible: isVisible);
              setState(() {
                // swipe from right to left to indicate that
              });
            }
            return Future<bool>.value(false);
          },
          background: Container(
            color: ((event.appAccessFlags & authCanManageRuns) == 0)
                ? Colors.grey[350]
                : hc_red,
            child: Row(
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(left: 10.0),
                  child: Icon(
                    Ionicons.ios_eye_off,
                    color: Colors.white,
                    size: 35.0,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 15.0),
                  child: Text(
                    // '${IveCoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Bank Transfer',
                    'Hide event',
                    style: ts_titleMedium,
                  ),
                ),
              ],
            ),
          ),
          secondaryBackground: Container(
            color: ((event.appAccessFlags & authCanManageRuns) == 0)
                ? Colors.grey[350]
                : Colors.green,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(right: 15.0),
                  child: Icon(
                    Ionicons.ios_eye,
                    color: Colors.white,
                    size: 35.0,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 15.0),
                  child: Text(
                    //'${IveCoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Cash',
                    'Show event',
                    style: ts_titleMedium,
                  ),
                ),
              ],
            ),
          ),
          onDismissed: (DismissDirection direction) {
            //print(direction.toString() + ' NOTE: We should never reach this point');
          },
          child: Stack(
            children: <Widget>[
              if (_itemBeingUpdatedId == event.eventId) ...<Widget>[
                const HcAppCircularProgressIndicator(key: Key('5050202')),
              ],
              Opacity(
                opacity: _itemBeingUpdatedId == event.eventId ? 0.4 : 1,
                child: FilterEventListItem(
                  event: event,
                  kennelShortName: widget.kennel.kennel.kennelShortName,
                  updateEvent: (dynamic retVal) async {
                    final EnumEventFilterType ft = retVal;
                    //print(ft);
                    setState(() {
                      _itemBeingUpdatedId = event.eventId;
                    });

                    switch (ft) {
                      case eventFilterType_showEvent:
                        await _updateEvent(
                          eventId: event.eventId,
                          isVisible: true,
                        );
                        break;
                      case eventFilterType_hideEvent:
                        await _updateEvent(
                          eventId: event.eventId,
                          isVisible: false,
                        );
                        break;
                      case eventFilterType_countEvent:
                        await _updateEvent(
                          eventId: event.eventId,
                          isCountedRun: true,
                        );
                        break;
                      case eventFilterType_doNotCountEvent:
                        await _updateEvent(
                          eventId: event.eventId,
                          isCountedRun: false,
                        );
                        break;
                      case eventFilterType_setRunNumber:
                        await setRunNumber(event, context);
                        break;
                      case eventFilterType_refreshOnly:
                        await _refreshSqlTablesFromBackend(false);
                        await _refreshEventFromTables(true);
                        _refreshList();
                        break;
                    }

                    setState(() {
                      _itemBeingUpdatedId = '';
                    });
                  },
                ),
              ),
            ],
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

  Future<void> setRunNumber(LiteEventModel event, BuildContext context) async {
    final RunNumberPopup newEventPopup = RunNumberPopup(
      runNumber: event.absoluteEventNumber,
    );

    final Map<String, String>? x = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return newEventPopup;
      },
    );

    final String runNumber =
        x?['runNumber'] ??
        event.absoluteEventNumber?.toString() ??
        event.eventNumber.toString();

    if (runNumber != 'cancel') {
      int rn = -1;
      if (runNumber == 'auto') {
        rn = 0;
      } else {
        rn = int.parse(runNumber);
      }

      await _updateEvent(eventId: event.eventId, asboluteEventNumber: rn);
    }
  }

  Future<void> _updateEvent({
    required String eventId,
    bool? isVisible,
    bool? isCountedRun,
    int? asboluteEventNumber,
    String? kennelId,
  }) async {
    await database.transaction<dynamic>((Transaction txn) async {
      final int flag =
          isVisible ?? isCountedRun ?? (asboluteEventNumber != null) ? -3 : -2;
      final String sql =
          'UPDATE ${EnumDataTables.events.commonTableName} SET canEditRunAttendence = "$flag" where eventId = "$eventId"';
      await txn.rawUpdate(sql);
      //print(result.toString() + ' update to events table @ ${DateTime.now().millisecondsSinceEpoch.toString()}');
    });

    final EventsService nSvc = EventsService();
    await nSvc.addEditEvent(
      eventId: eventId,
      kennelId: kennelId,
      isVisible: isVisible,
      isCountedRun: isCountedRun,
      absoluteEventNumber: asboluteEventNumber,
    );
    await _refreshEventFromTables(true);
    _refreshList();
  }

  final ValueNotifier<DateTime> _focusedDay = ValueNotifier<DateTime>(
    DateTime.now(),
  );
  final ValueNotifier<DateTime> _selectedDay = ValueNotifier<DateTime>(
    DateTime.now(),
  );
  CalendarFormat _calendarFormat = CalendarFormat.month;

  Widget _calendarView() {
    return Column(
      children: <Widget>[
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
                child: TableCalendar<dynamic>(
                  onCalendarCreated: (PageController controller) => controller,
                  firstDay: DateTime(2010, 1, 1),
                  lastDay: DateTime(2030, 1, 1),
                  focusedDay: _focusedDay.value,
                  calendarFormat: _calendarFormat,
                  rowHeight: 35.0,
                  rangeSelectionMode: RangeSelectionMode.toggledOff,
                  headerStyle: HeaderStyle(
                    rightChevronIcon: const Icon(
                      Icons.chevron_right,
                      color: Colors.black,
                    ),
                    leftChevronIcon: const Icon(
                      Icons.chevron_left,
                      color: Colors.black,
                    ),
                    formatButtonDecoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    formatButtonTextStyle: const TextStyle().copyWith(
                      color: Colors.white,
                    ),
                  ),
                  onFormatChanged: (CalendarFormat format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (DateTime focusedDay) {
                    _focusedDay.value = focusedDay;
                  },

                  //onDayLongPressed: (DateTime selectedDay, DateTime focusedDay) {},
                  // onDayLongPressed: (DateTime datePressed, List<dynamic> list1, List<dynamic> list2) {
                  //   _calendarController.setSelectedDay(datePressed);
                  //   _selectedDate = datePressed;

                  //   // only allow the date popup if the conditions allowing for new runs is met
                  //   if (datePressed != null &&
                  //       _toDateOnly(datePressed).difference(_toDateOnly(DateTime.now())).inDays >= 0 &&
                  //       (_calendarEvents[_toDateOnly(datePressed)]?.length ?? 0) == 0) {
                  //     _showEventPopup(datePressed);
                  //   }
                  // },
                  eventLoader: (DateTime dt) {
                    return _calendarEvents[_toDateOnly(dt)] as List<dynamic>? ??
                        [];
                  },
                  onDaySelected: _onDaySelected,

                  availableCalendarFormats: const <CalendarFormat, String>{
                    CalendarFormat.month: 'Week',
                    CalendarFormat.twoWeeks: 'Month',
                    CalendarFormat.week: '2 weeks',
                  },
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: Colors.deepOrange[400],
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.deepOrange[200],
                    ),
                    markerDecoration: BoxDecoration(color: Colors.brown[700]),
                    outsideDaysVisible: false,
                  ),
                  calendarBuilders: CalendarBuilders<dynamic>(
                    // selectedBuilder: (BuildContext context, DateTime date, DateTime focusedDay) {
                    //   return FutureBuilder<DateTime>(
                    //       future: _dateBeingUpdated,
                    //       builder: (BuildContext context, AsyncSnapshot<DateTime> snapshot) {
                    //         return ((snapshot.hasData) && (_toDateOnly(snapshot.data) == _toDateOnly(date)))
                    //             ? Container(
                    //                 decoration: BoxDecoration(
                    //                   color: (_calendarEvents[_toDateOnly(date)]?.length ?? 0) == 0
                    //                       ? _toDateOnly(date).difference(_toDateOnly(DateTime.now())).inDays == 0
                    //                           ? Colors.blue.shade100
                    //                           : _toDateOnly(date).difference(_toDateOnly(DateTime.now())).inDays >= 0
                    //                               ? Colors.white
                    //                               : Colors.grey.shade200
                    //                       : (_calendarEvents[_toDateOnly(date)]?.length ?? 0) > 1
                    //                           ? hc_red.shade100
                    //                           : _calendarEvents[_toDateOnly(date)][0]['isVisible'] == 0
                    //                               ? Colors.grey.shade300
                    //                               : _calendarEvents[_toDateOnly(date)][0]['isCountedRun'] == 1
                    //                                   ? Colors.green.shade100
                    //                                   : Colors.yellow.shade200,
                    //                   border: Border.all(
                    //                     color:hc_red,
                    //                     width: 3.0,
                    //                   ),
                    //                 ),
                    //                 // margin: const EdgeInsets.all(4.0),
                    //                 // padding: const EdgeInsets.only(top: 5.0, left: 6.0),
                    //                 //color: Colors.deepOrange[300],
                    //                 width: 100,
                    //                 height: 50,
                    //                 child: Icon(delayIcon, color: hc_blue),
                    //               )
                    //             : FadeTransition(
                    //                 opacity: Tween<double>(begin: 0.0, end: 1.0).animate(_animationController),
                    //                 child: Container(
                    //                   decoration: BoxDecoration(
                    //                     color: (_calendarEvents[_toDateOnly(date)]?.length ?? 0) == 0
                    //                         ? _toDateOnly(date).difference(_toDateOnly(DateTime.now())).inDays == 0
                    //                             ? Colors.blue.shade100
                    //                             : _toDateOnly(date).difference(_toDateOnly(DateTime.now())).inDays >= 0
                    //                                 ? Colors.white
                    //                                 : Colors.grey.shade200
                    //                         : (_calendarEvents[_toDateOnly(date)]?.length ?? 0) > 1
                    //                             ? hc_red.shade100
                    //                             : _calendarEvents[_toDateOnly(date)][0]['isVisible'] == 0
                    //                                 ? Colors.grey.shade300
                    //                                 : _calendarEvents[_toDateOnly(date)][0]['isCountedRun'] == 1
                    //                                     ? Colors.green.shade100
                    //                                     : Colors.yellow.shade200,
                    //                     border: Border.all(
                    //                       color:hc_red,
                    //                       width: 3.0,
                    //                     ),
                    //                   ),
                    //                   // margin: const EdgeInsets.all(4.0),
                    //                   // padding: const EdgeInsets.only(top: 5.0, left: 6.0),
                    //                   //color: Colors.deepOrange[300],
                    //                   width: 100,
                    //                   height: 50,
                    //                   child: Text(
                    //                     '${date.day}',
                    //                     style: const TextStyle().copyWith(fontSize: 16.0),
                    //                   ),
                    //                 ),
                    //               );
                    //       });
                    // },
                    todayBuilder:
                        (
                          BuildContext context,
                          DateTime date,
                          DateTime focusedDay,
                        ) {
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

                    outsideBuilder:
                        (
                          BuildContext context,
                          DateTime date,
                          DateTime focusedDay,
                        ) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              border: Border.all(
                                color: Colors.black12,
                                width: 1.0,
                              ),
                            ),
                            width: 100,
                            height: 50,
                            child: Text(
                              '${date.day}',
                              style: const TextStyle().copyWith(
                                fontSize: 16.0,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          );
                        },

                    defaultBuilder:
                        (
                          BuildContext context,
                          DateTime date,
                          DateTime focusedDay,
                        ) {
                          return FutureBuilder<DateTime>(
                            future: _dateBeingUpdated,
                            builder:
                                (
                                  BuildContext context,
                                  AsyncSnapshot<DateTime> snapshot,
                                ) {
                                  return Container(
                                    // margin: const EdgeInsets.all(4.0),
                                    // padding: const EdgeInsets.only(top: 5.0, left: 6.0),
                                    decoration: BoxDecoration(
                                      color:
                                          (_calendarEvents[_toDateOnly(date)]
                                                      ?.length ??
                                                  0) ==
                                              0
                                          ? _toDateOnly(date)
                                                        .difference(
                                                          _toDateOnly(
                                                            DateTime.now(),
                                                          ),
                                                        )
                                                        .inDays >=
                                                    0
                                                ? Colors.white
                                                : Colors.grey.shade200
                                          : (_calendarEvents[_toDateOnly(date)]
                                                        ?.length ??
                                                    0) >
                                                1
                                          ? Colors.red.shade100
                                          : _calendarEvents[_toDateOnly(
                                                      date,
                                                    )]![0]
                                                    .isVisible ==
                                                0
                                          ? Colors.grey.shade300
                                          : _calendarEvents[_toDateOnly(
                                                      date,
                                                    )]![0]
                                                    .isCountedRun ==
                                                1
                                          ? Colors.green.shade100
                                          : Colors.yellow.shade200,
                                      border:
                                          _toDateOnly(date) !=
                                              _toDateOnly(_focusedDay.value)
                                          ? Border.all(
                                              color: Colors.black26,
                                              width: 1.0,
                                            )
                                          : Border.all(
                                              color: hc_red,
                                              width: 3.0,
                                            ),
                                    ),
                                    width: 100,
                                    height: 50,
                                    child: Stack(
                                      alignment: AlignmentDirectional.center,
                                      children: <Widget>[
                                        Positioned(
                                          top: 1.0,
                                          left: 1.0,
                                          child: Text(
                                            '${date.day}',
                                            style: const TextStyle().copyWith(
                                              fontSize: 16.0,
                                              color:
                                                  _toDateOnly(date)
                                                          .difference(
                                                            _toDateOnly(
                                                              DateTime.now(),
                                                            ),
                                                          )
                                                          .inDays >=
                                                      0
                                                  ? Colors.black
                                                  : Colors.grey.shade500,
                                            ),
                                          ),
                                        ),
                                        if ((snapshot.hasData) &&
                                            _toDateOnly(snapshot.data!) ==
                                                _toDateOnly(date)) ...<Widget>[
                                          Positioned(
                                            right: 1.0,
                                            child: Icon(
                                              delayIcon,
                                              color: hc_blue,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                          );
                        },
                    markerBuilder:
                        (
                          BuildContext context,
                          DateTime date,
                          List<dynamic> events,
                        ) {
                          final List<Widget> children = <Widget>[];

                          if (events.isNotEmpty) {
                            if (events.length <= 5) {
                              for (int i = 0; i < events.length; i++) {
                                children.add(
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 5.0),
                                    child: Icon(
                                      FontAwesome.circle,
                                      size: 8.0,
                                      color: events[i].isVisible == 0
                                          ? Colors.grey
                                          : events[i].isCountedRun == 0
                                          ? hc_red
                                          : hc_blue,
                                    ),
                                  ),
                                );
                              }
                            } else {
                              children.add(Text(events.length.toString()));
                            }
                          }

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: children,
                          );
                        },
                  ),
                ),
              ),
              const SizedBox(height: 5.0),

              // if (_selectedDay.value != null &&
              //     _toDateOnly(_selectedDay.value).difference(_toDateOnly(DateTime.now())).inDays >= 0 &&
              //     (_calendarEvents[_toDateOnly(_selectedDay.value)]?.length ?? 0) == 0) ...<Widget>[_buildAddButtons()],
              if (_toDateOnly(
                        _selectedDay.value,
                      ).difference(_toDateOnly(DateTime.now())).inDays >=
                      0 &&
                  (_calendarEvents[_toDateOnly(_selectedDay.value)]?.length ??
                          0) ==
                      1) ...<Widget>[_buildEditButton()],
              _buildAddButtons(),
            ],
          ),
        ),
        Expanded(child: _listView(_selectedEvents.value)),
      ],
    );
  }

  DateTime _toDateOnly(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }

  void _refreshList({DateTime? selectedDay, DateTime? focusedDay}) {
    setState(() {
      if (selectedDay != null) {
        _selectedDay.value = selectedDay;
      }

      if (focusedDay != null) {
        _focusedDay.value = focusedDay;
      }
      _selectedEvents.value =
          _calendarEvents[_toDateOnly(_selectedDay.value)] ??
          <LiteEventModel>[];
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay.value, selectedDay)) {
      _refreshList(selectedDay: selectedDay, focusedDay: focusedDay);
    }
  }
}
