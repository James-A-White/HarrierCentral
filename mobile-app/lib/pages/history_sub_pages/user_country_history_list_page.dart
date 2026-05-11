import 'package:harrier_central/imports.dart';

class UserCountryHistoryListPage extends StatefulWidget {
  const UserCountryHistoryListPage({
    super.key,
    required this.countryId,
    required this.countryName,
    required this.appDomain,
    this.hasherId,
    this.hashName,
  });

  final String countryId;
  final String countryName;
  final AppDomainType appDomain;
  final String? hasherId;
  final String? hashName;

  @override
  UserCountryHistoryPageState createState() => UserCountryHistoryPageState();
}

class UserCountryHistoryPageState extends State<UserCountryHistoryListPage>
    with SingleTickerProviderStateMixin {
  UserCountryHistoryPageState();
  bool _isLoading = false;

  List<UserRunHistoryModel> _runCountsList = <UserRunHistoryModel>[];

  late final String userId;

  //RunHistoryModel? _kennelInfo;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    userId = widget.hasherId ?? getStringPref(StringPrefsEnum.userId)!;
    unawaited(_refreshRunHistoryFromTable(true));
  }

  Future<void> _handleTabSelection() async {
    if (_tabController.indexIsChanging) {
      // This means the user tapped a new tab, but the animation hasn't finished yet.
      //print('Tab is changing to index: ${_tabController.index}');
      await _refreshRunHistoryFromTable(true);
      //setState(() {});
    } else if (_tabController.index != _tabController.previousIndex) {
      // This is triggered after the tab has finished changing.
      //print('Tab changed to index: ${_tabController.index}');
      await _refreshRunHistoryFromTable(true);
      //setState(() {});
    }
  }

  Future<void> _refreshRunHistoryFromTable(bool forceRefresh) async {
    // This query looks at two places for historical runs. First it looks at all
    // of the current runs for a kennel that are cached on the phone and joins to HEM.
    // But for runs that are old and no longer cached on the phone, it looks at the
    // HEM record only in the second half of the UNION statement.

    int attendenceState = 0;

    if (_tabController.index == 0) {
      attendenceState = 20;
    }

    const String dollarSign = r'$^';

    final offsetFromGmtToLocal = Utilities.getSqfliteTimeOffset();

    String query =
        '''
          SELECT
          hem.${tableModel.hasherEventMapTableHelper.colTotalRunsThisKennel} as totalRunsThisKennel,
          hem.${tableModel.hasherEventMapTableHelper.colTotalHaringThisKennel} as totalHaringThisKennel,
          e.${tableModel.eventsTableHelper.colEventId} as eventId,
          e.${tableModel.eventsTableHelper.colEventName} as eventName,
          e.${tableModel.eventsTableHelper.colEventNumber} as eventNumber,
          n.${tableModel.countriesTableHelper.colCountryName} as countryName,
          n.${tableModel.countriesTableHelper.colFlagFile} as flagFile,
          k.${tableModel.kennelsTableHelper.colKennelName} as kennelName,
          k.${tableModel.kennelsTableHelper.colKennelShortName} as kennelShortName,
          coalesce(k.${tableModel.kennelsTableHelper.colDigitsAfterDecimal},n.${tableModel.countriesTableHelper.colDigitsAfterDecimal},2) as digitsAfterDecimal, 
          coalesce(k.${tableModel.kennelsTableHelper.colCurrencySymbol},n.${tableModel.countriesTableHelper.colCurrencySymbol},"$dollarSign") as currencySymbol,
          k.${tableModel.kennelsTableHelper.colKennelLogo} as kennelLogo,
          e.${tableModel.eventsTableHelper.colEventStartDatetime} as eventStartDatetime,
          e.${tableModel.eventsTableHelper.colExtrasDescription} as extrasDescription,
          e.${tableModel.eventsTableHelper.colEventPriceForExtras} as extrasPrice,
          coalesce(e.${tableModel.eventsTableHelper.colCanEditRunAttendence},k.${tableModel.kennelsTableHelper.colCanEditRunAttendence}) as canEditRunAttendence,
          hem.${tableModel.hasherEventMapTableHelper.colHemId} as hemId,
          coalesce(hem.${tableModel.hasherEventMapTableHelper.colAttendenceState},0) as attendenceState,
          coalesce(hem.${tableModel.hasherEventMapTableHelper.colIsHare},0) as isHare,
          pay.${tableModel.paymentsTableHelper.colCreditAmount} as creditAmount,
          pay.${tableModel.paymentsTableHelper.colDebitAmount} as debitAmount,
          pay.${tableModel.paymentsTableHelper.colCreditAvailable} as creditAvailable,
          pay.${tableModel.paymentsTableHelper.colPaymentType} as paymentType,
          pay.${tableModel.paymentsTableHelper.colDoPayForExtras} as doPayForExtras
          FROM ${EnumDataTables.events.commonTableName} e
          INNER JOIN kennels k on e.${tableModel.eventsTableHelper.colKennelId} = k.${tableModel.kennelsTableHelper.colKennelId}
          INNER JOIN ${EnumDataTables.countries.commonTableName} n on e.${tableModel.eventsTableHelper.colCountryId} = n.${tableModel.countriesTableHelper.colCountryId}
          LEFT OUTER JOIN ${tableModel.hasherEventMapTableHelper.getTableName(widget.appDomain)} hem on hem.${tableModel.hasherEventMapTableHelper.colEventId} = e.${tableModel.eventsTableHelper.colEventId} 
          AND hem.${tableModel.hasherEventMapTableHelper.colUserId}  = "$userId"
          LEFT OUTER JOIN ${tableModel.paymentsTableHelper.getTableName(widget.appDomain)} pay on pay.${tableModel.paymentsTableHelper.colHemId} = hem.${tableModel.hasherEventMapTableHelper.colHemId} AND pay.${tableModel.paymentsTableHelper.colCancelledBy} IS NULL
          WHERE e.${tableModel.eventsTableHelper.colIsCountedRun} = 1 
          AND e.${tableModel.eventsTableHelper.colIsVisible} = 1 
          AND e.${tableModel.eventsTableHelper.colRemoved} = 0
          AND e.${tableModel.eventsTableHelper.colCountryId} = "${widget.countryId}" 
          AND coalesce(hem.${tableModel.hasherEventMapTableHelper.colAttendenceState},0) >= $attendenceState 
          AND julianday(e.${tableModel.eventsTableHelper.colEventStartDatetime}) <= julianday('now','$offsetFromGmtToLocal')
        UNION
          -- this part of the query is for where we want to cache run details in cases
          -- where the user is not following the Kennel and the run detail information will
          -- not be present on the device as a part of a run record
          SELECT 
          hem.${tableModel.hasherEventMapTableHelper.colTotalRunsThisKennel} as totalRunsThisKennel,
          hem.${tableModel.hasherEventMapTableHelper.colTotalHaringThisKennel} as totalHaringThisKennel,
          hem.${tableModel.hasherEventMapTableHelper.colEventId} as eventId,
          hem.${tableModel.hasherEventMapTableHelper.colEventName} as eventName,
          hem.${tableModel.hasherEventMapTableHelper.colEventNumber} as eventNumber,
          n.${tableModel.countriesTableHelper.colCountryName} as countryName,
          n.${tableModel.countriesTableHelper.colFlagFile} as flagFile,
          k.${tableModel.kennelsTableHelper.colKennelName} as kennelName,
          k.${tableModel.kennelsTableHelper.colKennelShortName} as kennelShortName,
          coalesce(k.${tableModel.kennelsTableHelper.colDigitsAfterDecimal},n.${tableModel.countriesTableHelper.colDigitsAfterDecimal},2) as digitsAfterDecimal, 
          coalesce(k.${tableModel.kennelsTableHelper.colCurrencySymbol},n.${tableModel.countriesTableHelper.colCurrencySymbol},"$dollarSign") as currencySymbol,
          k.${tableModel.kennelsTableHelper.colKennelLogo} as kennelLogo,
          hem.${tableModel.hasherEventMapTableHelper.colEventStartDatetime} as eventStartDatetime,
          null as extrasDescription,
          null as extrasPrice,
          hem.${tableModel.hasherEventMapTableHelper.colCanEditRunAttendence} as canEditRunAttendence,
          hem.${tableModel.hasherEventMapTableHelper.colHemId} as hemId,
          coalesce(hem.${tableModel.hasherEventMapTableHelper.colAttendenceState},0) as attendenceState,
          coalesce(hem.${tableModel.hasherEventMapTableHelper.colIsHare},0) as isHare,
          pay.${tableModel.paymentsTableHelper.colCreditAmount} as creditAmount,
          pay.${tableModel.paymentsTableHelper.colDebitAmount} as debitAmount,
          pay.${tableModel.paymentsTableHelper.colPaymentType} as paymentType,
          pay.${tableModel.paymentsTableHelper.colCreditAvailable} as creditAvailable,
          pay.${tableModel.paymentsTableHelper.colDoPayForExtras} as doPayForExtras
          FROM ${tableModel.hasherEventMapTableHelper.getTableName(widget.appDomain)} hem
          INNER JOIN ${EnumDataTables.kennels.commonTableName} k on k.${tableModel.kennelsTableHelper.colKennelId} = ${tableModel.hasherEventMapTableHelper.colEventKennelId}
          INNER JOIN ${EnumDataTables.countries.commonTableName} n on n.${tableModel.countriesTableHelper.colCountryId} = ${tableModel.hasherEventMapTableHelper.colCountryId}
          LEFT OUTER JOIN ${tableModel.paymentsTableHelper.getTableName(widget.appDomain)} pay on pay.${tableModel.paymentsTableHelper.colHemId} = hem.${tableModel.hasherEventMapTableHelper.colHemId} AND pay.${tableModel.paymentsTableHelper.colCancelledBy} IS NULL
          WHERE 
          hem.${tableModel.hasherEventMapTableHelper.colEventId} NOT IN (SELECT eventId FROM ${EnumDataTables.events.commonTableName})
          AND hem.${tableModel.hasherEventMapTableHelper.colUserId} = "$userId"
          AND hem.${tableModel.hasherEventMapTableHelper.colEventIsCountedAndVisible} = 1 
          AND hem.${tableModel.hasherEventMapTableHelper.colRemoved} = 0 
          AND hem.${tableModel.hasherEventMapTableHelper.colCountryId} = "${widget.countryId}" 
          AND coalesce(hem.${tableModel.hasherEventMapTableHelper.colAttendenceState},0) >= $attendenceState 
          AND julianday(hem.${tableModel.hasherEventMapTableHelper.colEventStartDatetime}) <= julianday('now','$offsetFromGmtToLocal') 
          ORDER BY eventStartDatetime desc
          ''';

    _runCountsList = <UserRunHistoryModel>[];
    try {
      final List<Map<String, dynamic>> results = await database.rawQuery(query);

      for (int i = 0; i < results.length; i++) {
        final UserRunHistoryModel hlrItem = UserRunHistoryModel.fromMap(
          results[i],
        );
        _runCountsList.add(hlrItem);

        // hlrItem.totalHaringThisKennel = -1;
        // hlrItem.totalRunsThisKennel = -1;

        if (forceRefresh && (i == results.length - 1)) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
        ),
        Positioned(
          top: 0,
          left: 0,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: AppScaffold(
            appBar: AppBar(
              centerTitle: true,
              backgroundColor: themeAppBarBackground,
              iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
              title: Text(
                widget.hashName ?? 'My runs for ${widget.countryName}',
                style: ts_appBarTitle,
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
              heroTag: 'speed-dial-hero-tag-234234',
              backgroundColor:
                  Theme.of(context).buttonTheme.colorScheme?.primary ?? hc_red,
              foregroundColor: Colors.white,
              elevation: 8.0,
              shape: const CircleBorder(),
              children: <SpeedDialChild>[
                // SpeedDialChild(
                //   child: const Icon(MaterialCommunityIcons.email,
                //       color: Colors.white),
                //   backgroundColor: Colors.teal[800],
                //   label: 'Email run counts\r\n(this kennel)',
                //   labelStyle: const TextStyle(fontSize: 18.0),
                //   onTap: () {
                //     tableModel
                //         .hasherEventMapService
                //         .sendRunCountReportByEmail(
                //             kennelId:
                //                 (_kennelInfo ?? widget.kennelInfo).kennelId,
                //             kennelName:
                //                 (_kennelInfo ?? widget.kennelInfo).kennelName)
                //         .then((Map<String, String> result) {
                //       ScaffoldMessenger.of(navigatorKey.currentContext!)
                //           .hideCurrentSnackBar();
                //       if ((result['result'] != null) &&
                //           (result['result']!
                //               .toLowerCase()
                //               .startsWith('success'))) {
                //         Utilities.showAlert(
                //             'E-mail successfully sent',
                //             'Your run count report has been successfully e-mailed to:\r\n\r\n${result['email']}\r\n\r\nIf you do not see it in the next few minutes, check your spam folder.',
                //             'OK');
                //       }
                //     });
                //     IveCoreUtilities.showInSnackBar(context, _ScaffoldKey,
                //         'Run count report being processed...',
                //         durationInSeconds: 10);
                //   },
                // ),
                SpeedDialChild(
                  child: const Icon(
                    MaterialCommunityIcons.email_plus,
                    color: Colors.white,
                  ),
                  backgroundColor: hc_blue,
                  label: 'Email run counts\r\n(all kennels)',
                  labelStyle: const TextStyle(fontSize: 18.0),
                  onTap: () async {
                    await tableModel.hasherEventMapService
                        .sendRunCountReportByEmail(
                          kennelId: GUID_EMPTY,
                          kennelName: 'All of your Hash Kennels',
                        )
                        .then((Map<String, String> result) async {
                          ScaffoldMessenger.of(
                            navigatorKey.currentContext!,
                          ).hideCurrentSnackBar();
                          if ((result['result'] != null) &&
                              (result['result']!.toLowerCase().startsWith(
                                'success',
                              ))) {
                            await Utilities.showAlert(
                              'E-mail successfully sent',
                              'Your run count report has been successfully e-mailed to:\r\n\r\n${result['email']}\r\n\r\nIf you do not see it in the next few minutes, check your spam folder.',
                              'OK',
                            );
                          }
                        });
                    if (navigatorKey.currentContext != null) {
                      IveCoreUtilities.showInSnackBar(
                        navigatorKey.currentContext!,
                        'Run count report being processed...',
                        durationInSeconds: 10,
                      );
                    }
                  },
                ),
              ],
            ),
            body: _isLoading
                ? _buildCircularProgressIndicator()
                : _buildListView(widget.appDomain),
          ),
        ),
        OfflineModeRibbon(
          lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSync),
          ribbonImage: 'images/icons/offline_mode.png',
          refreshFunction: () {
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildCircularProgressIndicator() {
    return const Center(
      child: HcAppCircularProgressIndicator(key: Key('88230302')),
    );
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isLoading = true;
    });

    //final bool result = await tableModel
    await tableModel.syncUserDataService.updateFromBackend(
      EnumDataTables.hasherEventMap.flag |
          EnumDataTables.events.flag |
          EnumDataTables.kennels.flag |
          EnumDataTables.payments.flag |
          EnumDataTables.hasherKennelMap.flag,
      true,
      debugText: 'user_run_history_list_page: HEM, Events, Kennels',
    );
    //final String resultStr = result ? 'successfully' : 'unsuccessfully';
    //print('User data synchronized $resultStr');
    await _refreshRunHistoryFromTable(true);
    //_kennelInfo = await widget.refreshKennelInfo();
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
  //   return  AppScaffold(
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
  //                       await Utilities.showAlert( 'E-mail successfully sent', 'Your payment report has been successfully e-mailed to:\r\n\r\n${result['email']}\r\n\r\nIf you do not see it in the next few minutes, check your spam folder.', 'OK');
  //                     }
  //                   });
  //                 },
  //           ),
  //           SpeedDialChild(
  //             child: const Icon(MaterialCommunityIcons.email_plus),
  //             backgroundColor: hc_blue,
  //             label: 'Email all kennels run history',
  //             labelStyle: const TextStyle(fontSize: 18.0),
  //             onTap: ()  {
  //                   model.sendRunCountReportByEmail(kennelId: GUID_EMPTY, kennelName: 'All of your Hash Kennels').then((Map<String, String> result) {
  //                     if (result['result'].toLowerCase().startsWith('success')) {
  //                       await Utilities.showAlert( 'E-mail successfully sent', 'Your payment report has been successfully e-mailed to:\r\n\r\n${result['email']}\r\n\r\nIf you do not see it in the next few minutes, check your spam folder.', 'OK');
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
  //     child: HcAppCircularProgressIndicator(key: Key('yyyyyyy')),
  //   );
  // }

  // Future<void> _handleRefresh() async {
  //   model.clearKennelList();
  //   model.getUserEventsFromBackend(false, 1, 0, 0);
  //   //model.notifyListeners();
  // }

  int myRunCount = 0;
  int myHaringCount = 0;

  // // T0D0(James): Update this to simply pull data already provided by the server
  // void _updateMyRunCounts() {
  //   int haringCount = 0;
  //   int runCount = 0;

  //   for (int i = _runCountsList.length - 1; i >= 0; i--) {
  //     if (_runCountsList[i].isHare == 1) {
  //       haringCount++;
  //     }
  //     if (_runCountsList[i].attendenceState >= 20) {
  //       runCount++;
  //     }
  //     _runCountsList[i].totalHaringThisKennel = haringCount + (_kennelInfo ?? widget.kennelInfo).historicalHaringCount;
  //     _runCountsList[i].totalRunsThisKennel = runCount + (_kennelInfo ?? widget.kennelInfo).historicalTotalRunCount;
  //   }

  //   myRunCount = runCount;
  //   myHaringCount = haringCount;
  // }

  Widget _buildListView(AppDomainType appDomain) {
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
              // color: Colors.red,
              width: 100,
              padding: const EdgeInsets.only(left: 60, right: 60, top: 0.0),
              child: DefaultTabController(
                length: 2,
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  width: 140.0,
                  height: 75.0,
                  // reviewed for 2.0+
                  child: TabBar(
                    onTap: (void _) {
                      setState(() {});
                    },
                    labelStyle: ts_tabSelected,
                    unselectedLabelStyle: ts_tabUnselected,
                    isScrollable: false,
                    unselectedLabelColor: Colors.white,
                    labelColor: Colors.white,
                    //labelPadding: const EdgeInsets.only(top: 3, left: 20, right: 20),
                    labelPadding: const EdgeInsets.only(
                      top: 5,
                      left: 0,
                      right: 0,
                    ),
                    indicatorSize: TabBarIndicatorSize.label,
                    // labelPadding: EdgeInsets.symmetric(
                    //   horizontal: 20.0,
                    // ),
                    indicatorPadding: EdgeInsets.symmetric(
                      horizontal: -5.0,
                      vertical: 13.0,
                    ),
                    indicator: BoxDecoration(
                      color: hc_red,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    tabs: <Tab>[
                      Tab(
                        child: Container(
                          alignment: Alignment.center,
                          width: 120,
                          child: Text(
                            'My Runs',
                            style: ts_numberStyle.copyWith(
                              color: _tabController.index == 0
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                      Tab(
                        child: Container(
                          alignment: Alignment.center,
                          width: 120,
                          child: Text(
                            'All Runs',
                            style: ts_numberStyle.copyWith(
                              color: _tabController.index == 1
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                    controller: _tabController,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _runCountsList.isEmpty
                  ? Center(
                      child: Text('No runs logged yet.', style: ts_regular),
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _runCountsList.length,
                      padding: const EdgeInsets.only(top: 5),
                      separatorBuilder: (BuildContext context, int index) =>
                          const Divider(height: 1.0, color: Colors.black45),
                      //itemExtent: 58.0,
                      //shrinkWrap: true,
                      itemBuilder: (BuildContext context, int index) {
                        UserRunHistoryModel item = _runCountsList[index];

                        return Dismissible(
                          key: Key(item.eventId),
                          confirmDismiss: (DismissDirection direction) async {
                            if (item.canEditRunAttendence != 0) {
                              // swipe from right to left to indicate that
                              // the hasher either attended the run as a pack
                              // member or as a hare
                              if (direction == DismissDirection.endToStart) {
                                // here, we're going from an attendence state of
                                // not at the Hash to being at the Hash,
                                // so assume that the person was not a hare
                                if (item.attendenceState <
                                    attendenceAtHash.value) {
                                  _runCountsList[index] = _runCountsList[index]
                                      .copyWith(isUpdating: true);
                                  item = _runCountsList[index];
                                  await _setAttendenceState(
                                    item,
                                    rsvpYes,
                                    attendenceAtHash,
                                    isHareNo,
                                    appDomain,
                                  );
                                } else {
                                  _runCountsList[index] = _runCountsList[index]
                                      .copyWith(isUpdating: true);
                                  item = _runCountsList[index];
                                  await _setAttendenceState(
                                    item,
                                    rsvpYes,
                                    attendenceAtHash,
                                    item.isHare == 1 ? isHareNo : isHareYes,
                                    appDomain,
                                  );
                                }
                              } else {
                                // swipe from left to right to
                                // indicate that the hasher did
                                // not participate in this event
                                await _setAttendenceState(
                                  item,
                                  rsvpNo,
                                  attendenceNo,
                                  isHareNo,
                                  appDomain,
                                );
                              }

                              //_kennelInfo = await widget.refreshKennelInfo();

                              // await historyListPageKey.currentState.refreshRunHistoryFromTable(true);

                              setState(() {});
                            }
                            return Future<bool>.value(false);
                          },
                          background: item.canEditRunAttendence == 0
                              ? Container(
                                  color: Colors.grey,
                                  child: Row(
                                    children: <Widget>[
                                      const Padding(
                                        padding: EdgeInsets.only(left: 10.0),
                                        child: Icon(
                                          FontAwesome.lock,
                                          color: Colors.white,
                                          size: 35.0,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 15.0,
                                        ),
                                        child: Text(
                                          // '${IveCoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Bank Transfer',
                                          'Run locked',
                                          style: ts_titleMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  color: hc_red,
                                  child: Row(
                                    children: <Widget>[
                                      const Padding(
                                        padding: EdgeInsets.only(left: 10.0),
                                        child: Icon(
                                          FontAwesome.times_circle,
                                          color: Colors.white,
                                          size: 35.0,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 15.0,
                                        ),
                                        child: Text(
                                          // '${IveCoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Bank Transfer',
                                          'I was not\r\nat the Hash',
                                          maxLines: 2,
                                          style: ts_titleMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          secondaryBackground: item.canEditRunAttendence == 0
                              ? Container(
                                  color: Colors.grey,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: <Widget>[
                                      const Padding(
                                        padding: EdgeInsets.only(right: 15.0),
                                        child: Icon(
                                          FontAwesome.lock,
                                          color: Colors.white,
                                          size: 35.0,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 15.0,
                                        ),
                                        child: Text(
                                          //'${IveCoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Cash',
                                          'Run locked',
                                          style: ts_titleMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : (item.attendenceState <
                                        attendenceAtHash.value) ||
                                    ((item.attendenceState >=
                                            attendenceAtHash.value) &&
                                        (item.isHare == isHareYes.value))
                              ? Container(
                                  color: Colors.green,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: <Widget>[
                                      const Padding(
                                        padding: EdgeInsets.only(right: 15.0),
                                        child: Icon(
                                          FontAwesome.check_circle,
                                          color: Colors.white,
                                          size: 35.0,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 15.0,
                                        ),
                                        child: Text(
                                          //'${IveCoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Cash',
                                          'I was at\r\nthe Hash',
                                          maxLines: 2,
                                          textAlign: TextAlign.right,
                                          style: ts_titleMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  color: Colors.purple,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: <Widget>[
                                      const Padding(
                                        padding: EdgeInsets.only(right: 15.0),
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            left: 2.5,
                                            right: 2.5,
                                          ),
                                          child: ImageIcon(
                                            AssetImage(
                                              'images/icons/hare_icon.png',
                                            ),
                                            color: Colors.white,
                                            size: 30.0,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 15.0,
                                        ),
                                        child: Text(
                                          //'${IveCoreUtilities.getFormattedMoney(filteredList[index].debitAmount, widget.digitsAfterDecimal, widget.currencySymbol)} Cash',
                                          'I was a Hare',
                                          style: ts_titleMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          onDismissed: (DismissDirection direction) {
                            //print(direction.toString() + ' NOTE: We should never reach this point');
                          },
                          child: GestureDetector(
                            onTapUp: (TapUpDetails details) async {
                              final List<dynamic> run =
                                  await QueryRuns.getRunDetailsAggregates(
                                    true,
                                    eventId: item.eventId,
                                    queryType: EnumRunQueryType.singleRun,
                                    runsTimeScope: RunsTimeScope.future,
                                    runsToDisplay: RunsToDisplay.allRuns,
                                  );

                              if (run.isNotEmpty) {
                                if (!mounted) return;
                                await Navigator.push<dynamic>(
                                  navigatorKey.currentContext!,
                                  MaterialPageRoute<dynamic>(
                                    builder: (BuildContext context) {
                                      return RunDetailsPage(
                                        futureRun: run[0],
                                        //refreshPage: () async {},
                                      );
                                    },
                                  ),
                                );
                              }
                            },
                            child: UserEventListItem(
                              item: item,
                              historicalHaringCount: 0,
                              historicalTotalRunCount: 0,
                              showCountry: false,
                              showKennel: true,
                              setAttendenceStateCallback:
                                  (
                                    EnumAttendenceState attendenceState,
                                    EnumIsHare isHare,
                                  ) async {
                                    setState(() {
                                      _runCountsList[index] =
                                          _runCountsList[index].copyWith(
                                            isUpdating: true,
                                          );
                                      item = _runCountsList[index];
                                    });

                                    if (attendenceState == attendenceNo) {
                                      await _setAttendenceState(
                                        item,
                                        rsvpNo,
                                        attendenceNo,
                                        isHareNo,
                                        appDomain,
                                      );
                                    } else {
                                      if (isHare == isHareYes) {
                                        await _setAttendenceState(
                                          item,
                                          rsvpYes,
                                          attendenceAtHash,
                                          isHareYes,
                                          appDomain,
                                        );
                                      } else {
                                        await _setAttendenceState(
                                          item,
                                          rsvpYes,
                                          attendenceAtHash,
                                          isHareNo,
                                          appDomain,
                                        );
                                      }
                                    }

                                    setState(() {
                                      _runCountsList[index] =
                                          _runCountsList[index].copyWith(
                                            isUpdating: false,
                                          );
                                    });
                                  },
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
        ),
      ),
    );
  }

  Future<void> _setAttendenceState(
    UserRunHistoryModel item,
    EnumRsvpState rsvpState,
    EnumAttendenceState attendenceState,
    EnumIsHare isHare,
    AppDomainType appDomain,
  ) async {
    await tableModel.hasherEventMapService.setEventAttendence(
      item.eventId,
      userId,
      appDomain,
      attendenceState.value,
      isHare: isHare.value,
      hemId: item.hemId,
    );

    await _refreshRunHistoryFromTable(true);
    setState(() {
      _isLoading = false;
    });
  }
}
