import 'package:harrier_central/imports.dart';

class UserRunHistoryListPage extends StatefulWidget {
  const UserRunHistoryListPage({
    super.key,
    required this.kennelInfo,
    required this.refreshKennelInfo,
    required this.appDomain,
    this.hasherId,
    this.hashName,
  });

  final RunHistoryModel kennelInfo;
  final Function refreshKennelInfo;
  final AppDomainType appDomain;
  final String? hasherId;
  final String? hashName;

  @override
  UserRunHistoryPageState createState() => UserRunHistoryPageState();
}

class UserRunHistoryPageState extends State<UserRunHistoryListPage>
    with SingleTickerProviderStateMixin {
  UserRunHistoryPageState();
  bool _isLoading = false;

  List<UserRunHistoryModel> _runCountsList = <UserRunHistoryModel>[];
  int _countryCount = 1;
  late final String userId;

  RunHistoryModel? _kennelInfo;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    userId = widget.hasherId ?? getStringPref(StringPrefsEnum.userId)!;
    _refreshRunHistoryFromTable(true);
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      // This means the user tapped a new tab, but the animation hasn't finished yet.
      //('Tab is changing to index: ${_tabController.index}');
      _refreshRunHistoryFromTable(true);
      //setState(() {});
    } else if (_tabController.index != _tabController.previousIndex) {
      // This is triggered after the tab has finished changing.
      //print('Tab changed to index: ${_tabController.index}');
      _refreshRunHistoryFromTable(true);
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

    String query = '''
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
          k.${tableModel.kennelsTableHelper.colKennelLogo} as kennelLogo,
          coalesce(k.${tableModel.kennelsTableHelper.colDigitsAfterDecimal},n.${tableModel.countriesTableHelper.colDigitsAfterDecimal},2) as digitsAfterDecimal, 
          coalesce(k.${tableModel.kennelsTableHelper.colCurrencySymbol},n.${tableModel.countriesTableHelper.colCurrencySymbol},"$dollarSign") as currencySymbol,
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
          FROM narrowEvents e
          INNER JOIN kennels k on e.${tableModel.eventsTableHelper.colKennelId} = k.${tableModel.kennelsTableHelper.colKennelId}
          INNER JOIN ${tableModel.countriesTableHelper.getTableName(widget.appDomain)} n on e.${tableModel.eventsTableHelper.colCountryId} = n.${tableModel.countriesTableHelper.colCountryId}
          LEFT OUTER JOIN ${tableModel.hasherEventMapTableHelper.getTableName(widget.appDomain)} hem on hem.${tableModel.hasherEventMapTableHelper.colEventId} = e.${tableModel.eventsTableHelper.colEventId} 
          AND hem.${tableModel.hasherEventMapTableHelper.colUserId}  = "$userId"
          LEFT OUTER JOIN ${tableModel.paymentsTableHelper.getTableName(widget.appDomain)} pay on pay.${tableModel.paymentsTableHelper.colHemId} = hem.${tableModel.hasherEventMapTableHelper.colHemId} AND pay.${tableModel.paymentsTableHelper.colCancelledBy} IS NULL
          WHERE e.${tableModel.eventsTableHelper.colIsCountedRun} = 1 
          AND e.${tableModel.eventsTableHelper.colIsVisible} = 1 
          AND e.${tableModel.eventsTableHelper.colRemoved} = 0
          AND e.${tableModel.eventsTableHelper.colKennelId} = "${(_kennelInfo ?? widget.kennelInfo).kennelId}" 
          AND coalesce(hem.${tableModel.hasherEventMapTableHelper.colAttendenceState},0) >= $attendenceState 
          AND DateTime(e.${tableModel.eventsTableHelper.colEventStartDatetime}) <= DateTime('now')
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
          k.${tableModel.kennelsTableHelper.colKennelLogo} as kennelLogo,
          coalesce(k.${tableModel.kennelsTableHelper.colDigitsAfterDecimal},n.${tableModel.countriesTableHelper.colDigitsAfterDecimal},2) as digitsAfterDecimal, 
          coalesce(k.${tableModel.kennelsTableHelper.colCurrencySymbol},n.${tableModel.countriesTableHelper.colCurrencySymbol},"$dollarSign") as currencySymbol,
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
          INNER JOIN ${tableModel.kennelsTableHelper.getTableName(widget.appDomain)} k on k.${tableModel.kennelsTableHelper.colKennelId} = ${tableModel.hasherEventMapTableHelper.colEventKennelId}
          INNER JOIN ${tableModel.countriesTableHelper.getTableName(widget.appDomain)} n on n.${tableModel.countriesTableHelper.colCountryId} = ${tableModel.hasherEventMapTableHelper.colCountryId}
          LEFT OUTER JOIN ${tableModel.paymentsTableHelper.getTableName(widget.appDomain)} pay on pay.${tableModel.paymentsTableHelper.colHemId} = hem.${tableModel.hasherEventMapTableHelper.colHemId} AND pay.${tableModel.paymentsTableHelper.colCancelledBy} IS NULL
          WHERE 
          hem.${tableModel.hasherEventMapTableHelper.colEventId} NOT IN (SELECT eventId FROM NarrowEvents)
          AND hem.${tableModel.hasherEventMapTableHelper.colUserId} = "$userId"
          AND hem.${tableModel.hasherEventMapTableHelper.colEventIsCountedAndVisible} = 1 
          AND hem.${tableModel.hasherEventMapTableHelper.colRemoved} = 0 
          AND hem.${tableModel.hasherEventMapTableHelper.colEventKennelId} = "${(_kennelInfo ?? widget.kennelInfo).kennelId}" 
          AND coalesce(hem.${tableModel.hasherEventMapTableHelper.colAttendenceState},0) >= $attendenceState 
          AND DateTime(hem.${tableModel.hasherEventMapTableHelper.colEventStartDatetime}) <= DateTime('now') 
          ORDER BY eventStartDatetime desc
          ''';

    _runCountsList = <UserRunHistoryModel>[];
    try {
      final List<Map<String, dynamic>> results = await database.rawQuery(query);

      for (int i = 0; i < results.length; i++) {
        final UserRunHistoryModel hlrItem = UserRunHistoryModel.fromMap(
          results[i],
        );
        // hlrItem.totalHaringThisKennel = -1;
        // hlrItem.totalRunsThisKennel = -1;
        _runCountsList.add(hlrItem);

        if (forceRefresh && (i == results.length - 1)) {
          _countryCount =
              _runCountsList.map((run) => run.flagFile).toSet().length;
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

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
          child: Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              centerTitle: true,
              backgroundColor: themeAppBarBackground,
              iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
              title: Text(
                widget.hashName ??
                    'My runs for ${(_kennelInfo ?? widget.kennelInfo).kennelShortName}',
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
              heroTag: 'speed-dial-hero-tag-4312315',
              backgroundColor:
                  Theme.of(context).buttonTheme.colorScheme?.primary ?? hc_red,
              foregroundColor: Colors.white,
              elevation: 8.0,
              shape: const CircleBorder(),
              children: <SpeedDialChild>[
                SpeedDialChild(
                  child: const Icon(
                    MaterialCommunityIcons.email,
                    color: Colors.white,
                  ),
                  backgroundColor: Colors.teal[800],
                  label: 'Email run counts\r\n(this kennel)',
                  labelStyle: const TextStyle(fontSize: 18.0),
                  onTap: () {
                    tableModel.hasherEventMapService
                        .sendRunCountReportByEmail(
                          kennelId: (_kennelInfo ?? widget.kennelInfo).kennelId,
                          kennelName:
                              (_kennelInfo ?? widget.kennelInfo).kennelName,
                        )
                        .then((Map<String, String> result) {
                          ScaffoldMessenger.of(
                            navigatorKey.currentContext!,
                          ).hideCurrentSnackBar();
                          if ((result['result'] != null) &&
                              (result['result']!.toLowerCase().startsWith(
                                'success',
                              ))) {
                            Utilities.showAlert(
                              'E-mail successfully sent',
                              'Your run count report has been successfully e-mailed to:\r\n\r\n${result['email']}\r\n\r\nIf you do not see it in the next few minutes, check your spam folder.',
                              'OK',
                            );
                          }
                        });
                    IveCoreUtilities.showInSnackBar(
                      context,
                      _scaffoldKey,
                      'Run count report being processed...',
                      durationInSeconds: 10,
                    );
                  },
                ),
                SpeedDialChild(
                  child: const Icon(
                    MaterialCommunityIcons.email_plus,
                    color: Colors.white,
                  ),
                  backgroundColor: hc_blue,
                  label: 'Email run counts\r\n(all kennels)',
                  labelStyle: const TextStyle(fontSize: 18.0),
                  onTap: () {
                    tableModel.hasherEventMapService
                        .sendRunCountReportByEmail(
                          kennelId: GUID_EMPTY,
                          kennelName: 'All of your Hash Kennels',
                        )
                        .then((Map<String, String> result) {
                          ScaffoldMessenger.of(
                            navigatorKey.currentContext!,
                          ).hideCurrentSnackBar();
                          if ((result['result'] != null) &&
                              (result['result']!.toLowerCase().startsWith(
                                'success',
                              ))) {
                            Utilities.showAlert(
                              'E-mail successfully sent',
                              'Your run count report has been successfully e-mailed to:\r\n\r\n${result['email']}\r\n\r\nIf you do not see it in the next few minutes, check your spam folder.',
                              'OK',
                            );
                          }
                        });
                    IveCoreUtilities.showInSnackBar(
                      context,
                      _scaffoldKey,
                      'Run count report being processed...',
                      durationInSeconds: 10,
                    );
                  },
                ),
              ],
            ),
            body:
                _isLoading
                    ? _buildCircularProgressIndicator()
                    : _buildListView(widget.appDomain),
          ),
        ),
        OfflineModeRibbon(
          lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSyncAsDate),
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
      child: HcCircularProgressIndicator(key: Key('88230302')),
    );
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isLoading = true;
    });

    //final bool result = await tableModel
    await tableModel.syncUserDataService.updateFromBackend(
      SyncUserDataService.flagHasherEventMapTable |
          SyncUserDataService.flagNarrowEventsTable |
          SyncUserDataService.flagKennelsTable |
          SyncUserDataService.flagPaymentsTable |
          SyncUserDataService.flagHasherKennelMapTable,
      true,
      debugText: 'user_run_history_list_page: HEM, Events, Kennels',
    );
    //final String resultStr = result ? 'successfully' : 'unsuccessfully';
    //print('User data synchronized $resultStr');
    await _refreshRunHistoryFromTable(true);
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
  //     child: HcCircularProgressIndicator(key: Key('yyyyyyy')),
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
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(right: 12.0),
                    height: 90,
                    child: KennelLogo(
                      kennelId: (_kennelInfo ?? widget.kennelInfo).kennelId,
                      kennelLogoUrl:
                          (_kennelInfo ?? widget.kennelInfo).kennelLogo,
                      kennelShortName:
                          (_kennelInfo ?? widget.kennelInfo).kennelShortName,
                      logoHeight: 60.0 * deviceInfo.deviceWidthScaleFactor,
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
                          style: ts_boldTitleStyle,
                          textAlign: TextAlign.left,
                        ),
                        AutoSizeText(
                          'My verified run count: ${(_kennelInfo ?? widget.kennelInfo).hcRunsThisKennel}',
                          //'Super fucking long text thats sure to overflow and more',
                          //'999',
                          overflow: TextOverflow.ellipsis,
                          minFontSize: 12.0,
                          maxLines: 1,
                          style: ts_numberStyle,
                          textAlign: TextAlign.center,
                        ),
                        AutoSizeText(
                          'My verified haring count: ${(_kennelInfo ?? widget.kennelInfo).hcHaringThisKennel}',
                          //'Super fucking long text thats sure to overflow and more',
                          //'999',
                          overflow: TextOverflow.ellipsis,
                          minFontSize: 12.0,
                          maxLines: 1,
                          style: ts_numberStyle,
                          textAlign: TextAlign.center,
                        ),
                        AutoSizeText(
                          'Kennel credit: ${IveCoreUtilities.getFormattedMoney((_kennelInfo ?? widget.kennelInfo).kennelCredit, widget.kennelInfo.digitsAfterDecimal, widget.kennelInfo.currencySymbol)}',
                          //'Super fucking long text thats sure to overflow and more',
                          //'999',
                          overflow: TextOverflow.ellipsis,
                          minFontSize: 12.0,
                          maxLines: 1,
                          style: ts_numberStyle,
                          textAlign: TextAlign.center,
                        ),
                        ((_kennelInfo ?? widget.kennelInfo)
                                    .historicalTotalRunCount) ==
                                0
                            ? Container()
                            : AutoSizeText(
                              'Historical run count: ${(_kennelInfo ?? widget.kennelInfo).historicalCountIsEstimate != 0 ? '~' : ''}${(_kennelInfo ?? widget.kennelInfo).historicalTotalRunCount}',
                              //'Super fucking long text thats sure to overflow and more',
                              //'999',
                              overflow: TextOverflow.ellipsis,
                              minFontSize: 18.0,
                              maxLines: 1,
                              style: ts_numberStyle,
                              textAlign: TextAlign.center,
                            ),
                        ((_kennelInfo ?? widget.kennelInfo)
                                    .historicalTotalRunCount) ==
                                0
                            ? Container()
                            : AutoSizeText(
                              'Historical haring count ${(_kennelInfo ?? widget.kennelInfo).historicalCountIsEstimate != 0 ? '~' : ''}${(_kennelInfo ?? widget.kennelInfo).historicalHaringCount}',
                              //'Super fucking long text thats sure to overflow and more',
                              //'999',
                              overflow: TextOverflow.ellipsis,
                              minFontSize: 18.0,
                              maxLines: 1,
                              style: ts_numberStyle,
                              textAlign: TextAlign.center,
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              // color: Colors.red,
              width: 100,
              padding: const EdgeInsets.only(left: 60, right: 60, top: 10.0),
              child: DefaultTabController(
                length: 2,
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
                  indicatorSize: TabBarIndicatorSize.label,
                  indicator: BubbleTabIndicator(
                    indicatorHeight: 30.0,
                    indicatorColor: hc_red,
                    tabBarIndicatorSize: TabBarIndicatorSize.label,
                    indicatorRadius: 15.0,
                    padding: EdgeInsets.only(top: 5),
                  ),
                  tabs: <Tab>[
                    Tab(
                      child: Container(
                        alignment: Alignment.center,
                        width: 120,
                        child: Text(
                          'My Runs',
                          style: ts_numberStyle.copyWith(
                            color:
                                _tabController.index == 0
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
                            color:
                                _tabController.index == 1
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
            Expanded(
              child:
                  _runCountsList.isEmpty
                      ? Center(
                        child: Text('No runs logged yet.', style: ts_regular),
                      )
                      : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _runCountsList.length,
                        padding: const EdgeInsets.only(top: 5),
                        separatorBuilder:
                            (BuildContext context, int index) => const Divider(
                              height: 1.0,
                              color: Colors.black45,
                            ),
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
                                    _runCountsList[index] =
                                        _runCountsList[index].copyWith(
                                          isUpdating: true,
                                        );
                                    item = _runCountsList[index];
                                    await _setAttendenceState(
                                      item,
                                      rsvpYes,
                                      attendenceAtHash,
                                      isHareNo,
                                      appDomain,
                                    );
                                  } else {
                                    _runCountsList[index] =
                                        _runCountsList[index].copyWith(
                                          isUpdating: true,
                                        );
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

                                _kennelInfo = await widget.refreshKennelInfo();

                                // await historyListPageKey.currentState.refreshRunHistoryFromTable(true);

                                setState(() {});
                              }
                              return Future<bool>.value(false);
                            },
                            background:
                                item.canEditRunAttendence == 0
                                    ? Container(
                                      color: Colors.grey,
                                      child: Row(
                                        children: <Widget>[
                                          const Padding(
                                            padding: EdgeInsets.only(
                                              left: 10.0,
                                            ),
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
                                            padding: EdgeInsets.only(
                                              left: 10.0,
                                            ),
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
                            secondaryBackground:
                                item.canEditRunAttendence == 0
                                    ? Container(
                                      color: Colors.grey,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                          const Padding(
                                            padding: EdgeInsets.only(
                                              right: 15.0,
                                            ),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                          const Padding(
                                            padding: EdgeInsets.only(
                                              right: 15.0,
                                            ),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                          const Padding(
                                            padding: EdgeInsets.only(
                                              right: 15.0,
                                            ),
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
                                historicalHaringCount:
                                    (_kennelInfo ?? widget.kennelInfo)
                                        .historicalHaringCount,
                                historicalTotalRunCount:
                                    (_kennelInfo ?? widget.kennelInfo)
                                        .historicalTotalRunCount,
                                showCountry: _countryCount > 1,
                                showKennel: false,
                                setAttendenceStateCallback: (
                                  EnumAttendenceState<int> attendenceState,
                                  EnumIsHare<int> isHare,
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
    EnumRsvpState<int> rsvpState,
    EnumAttendenceState<int> attendenceState,
    EnumIsHare<int> isHare,
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
