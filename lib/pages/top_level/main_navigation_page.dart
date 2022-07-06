// @dart=2.11
import 'package:harrier_central/imports.dart';
import 'package:harrier_central/pages/top_level/drawer_menu.dart';
import 'package:harrier_central/pages/top_level/select_run_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({Key key}) : super(key: key);

  @override
  _MainNavigationPageState createState() => _MainNavigationPageState();
}

final GlobalKey<RunAndKennelMapPageState> _runAndKennelMapPageKey = GlobalKey<RunAndKennelMapPageState>();
final GlobalKey<KennelsListPageState> _kennelLocationsPageKey = GlobalKey<KennelsListPageState>();

class _MainNavigationPageState extends State<MainNavigationPage> {
  //MainNavigationScopedModel homePageModel = MainNavigationScopedModel();

  //final List<Widget> _tabs = <Widget>[];
  final List<String> _tabTitles = <String>[];

  final List<List<String>> _tutorials = <List<String>>[_tutorialUpcomingRuns, _tutorialKennelsView, _tutorialRunLocations, _tutorialRunCounts];

  // ignore: prefer_final_fields
  static List<String> _tutorialRunLocations = <String>[
    'images/tutorial/run_locations_help_1.jpg',
    'images/tutorial/run_locations_help_2.jpg',
    'images/tutorial/run_locations_help_3.jpg',
    'images/tutorial/run_locations_help_4.jpg',
  ];

  // ignore: prefer_final_fields
  static List<String> _tutorialUpcomingRuns = <String>[
    'images/tutorial/upcoming_runs_page_1.jpg',
    'images/tutorial/upcoming_runs_page_2.jpg',
    'images/tutorial/upcoming_runs_page_3.jpg',
    'images/tutorial/upcoming_runs_page_4.jpg',
    'images/tutorial/upcoming_runs_page_5.jpg',
    'images/tutorial/upcoming_runs_page_6.jpg',
    'images/tutorial/upcoming_runs_page_7.jpg',
  ];

  // static List<String> helpNotAvailable = <String>[
  //   'images/tutorial/help_not_available.jpg',
  // ];

  // ignore: prefer_final_fields
  static List<String> _tutorialRunCounts = <String>[
    'images/tutorial/run_counts_tutorial_1.jpg',
    'images/tutorial/run_counts_tutorial_2.jpg',
    'images/tutorial/run_counts_tutorial_3.jpg',
  ];

  // ignore: prefer_final_fields
  static List<String> _tutorialKennelsView = <String>[
    'images/tutorial/kennels_tutorial_1.jpg',
    'images/tutorial/kennels_tutorial_2.jpg',
    'images/tutorial/kennels_tutorial_3.jpg',
    'images/tutorial/kennels_tutorial_4.jpg',
    'images/tutorial/kennels_tutorial_5.jpg',
    'images/tutorial/kennels_tutorial_6.jpg',
    'images/tutorial/kennels_tutorial_7.jpg',
  ];

  String _appBarText;
  String _initializationMessage = '';

  bool _isFlipped = false;

  // TODO(James): Investigate Page Storage Bucket / PageView

  FutureRunsListPage _futureRunsListPage;
  KennelsListPage _kennelsListPage;
  HistoryListPage _historyListPage;
  //final UserQrCodePage userQrCodePage = const UserQrCodePage();
  RunAndKennelMapPage _runAndKennelMapPage;

  Future<bool> _dbReady;

  @override
  void initState() {
    _tabTitles.add('Upcoming Runs');
    _tabTitles.add('Kennels');
    _tabTitles.add('Explore Runs');
    _tabTitles.add('Run Counts');

    //_tabTitles.add('Scanner');
    // _tabTitles.add('Friends');

    _appBarText = _tabTitles[0];

    // final bool result = await G0<TableModel>().syncUserDataService.updateFromBackend(SyncUserDataService.flagsAllData, false);
    // final String resultStr = result ? 'successfully' : 'unsuccessfully';
    // //print('Master data synchronized $resultStr');

    // this is here to force the database to be instnatiated upon startup.
    // the first time this is run, the database will be created. On subsequent
    // runs, the database will simply be opened.

    Tables.migrationList.sort((MigrationsModel a, MigrationsModel b) => a.dbVersion.compareTo(b.dbVersion));

    // make sure the DB_VERSION is equal to the maximum migration in the list
    assert(DB_VERSION == Tables.migrationList.last.dbVersion);

    // DANGER - need to look into definition of ClientApp

    // print('****** > Starting DB Setup');

    _dbReady = setupDatabase(informUser, 'PRO_APP').then((bool _) async {
      // print('****** > Finished DB Setup');
      // final NotificationSupport notifications = NotificationSupport();
      // await notifications.configureNotifications(true);
      // G0<TableModel>().syncUserDataService.updateFromBackend(SyncUserDataService.flagsAllData, false, informUser: informUser).then((bool result) {
      //   final String resultStr = result ? 'successfully' : 'unsuccessfully';
      //   //print('Master data synchronized $resultStr');

      //   setIntPref(IntPrefsEnum.databaseVersion, DB_VERSION);

      // create pages after database is loaded
      _futureRunsListPage = FutureRunsListPage();
      _kennelsListPage = KennelsListPage(key: _kennelLocationsPageKey);
      _historyListPage = HistoryListPage();
      //final UserQrCodePage userQrCodePage = const UserQrCodePage();
      _runAndKennelMapPage = RunAndKennelMapPage(key: _runAndKennelMapPageKey);

      setState(() {});

      final bool hasLoc = await _checkLocationPermissions();
      if (hasLoc) {
        await _checkAreWeAtRunStart();
      }

      return true;
    });

    FlutterStatusbarcolor.setStatusBarColor(themeStatusBarBackground).then((void _) {
      FlutterStatusbarcolor.setStatusBarWhiteForeground(true);
    });

    super.initState();
  }

  Future<void> _checkAreWeAtRunStart() async {
    //final Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.lowest);
    final List<AreWeAtRunResult> resultList = await CommonQueries.areWeAtRunStart();
    final String userId = getStringPref(StringPrefsEnum.userId);

    if (resultList.length == 1) {
      final AreWeAtRunResult result = resultList[0];
      if ((result.eventId != EMPTY_RESULT) && (result.distanceInMeters <= GEOFENCE_IN_METERS_AROUND_RUN_START_FOR_AUTO_CHECKIN) && (result.attendenceState < attendenceAtHash.value)) {
        final ConfirmAutoCheckinPopup popup = ConfirmAutoCheckinPopup(
          title: 'Check-in to Run',
          eventImage: result.eventImage,
          eventName: result.eventName,
          kennelLogo: result.kennelLogo,
          okButtonTitle: 'Yes',
          cancelButtonTitle: 'No',
          kennelShortName: result.kennelShortName,
          eventNumber: result.eventNumber,
          kennelCredit: result.kennelCredit,
          extrasCost: result.extrasCost,
          eventPrice: result.membershipExpirationDate.isAfter(DateTime.now()) ? result.memberPrice : result.nonMemberPrice,
          extrasDescription: result.extrasDescription,
          digitsAfterDecimal: result.digitsAfterDecimal,
          currencySymbol: result.currencySymbol,
        );

        final EnumCheckinOptions<int> retVal = await showDialog<EnumCheckinOptions<int>>(
            context: context,
            barrierDismissible: false, // user must tap button!
            builder: (BuildContext context) {
              return popup;
            });

        if (retVal == enumCheckInOption_Yes) {
          await _checkInAtEvent(result.eventId, userId);
        } else if (retVal == enumCheckInOption_YesAndPay) {
          final PaymentsService paySrv = PaymentsService();
          await paySrv.payForEvent(
            result.eventId,
            userId,
            GUID_EMPTY,
            paymentHashCredit.value,
            result.membershipExpirationDate.isAfter(DateTime.now()) ? result.memberPrice : result.nonMemberPrice,
            attendenceAtHash.value,
            payForRunOnly,
            AppDomainType.user,
          );
        } else if (retVal == enumCheckInOption_YesAndPayPlusExtras) {
          final PaymentsService paySrv = PaymentsService();
          await paySrv.payForEvent(
              result.eventId,
              userId,
              GUID_EMPTY,
              paymentHashCredit.value,
              result.extrasCost + (result.membershipExpirationDate.isAfter(DateTime.now()) ? result.memberPrice : result.nonMemberPrice),
              attendenceAtHash.value,
              payForRunAndExtras,
              AppDomainType.user);
        }
      }
    } else if (resultList.length > 1) {
      // look through the list of runs and determine if this hasher is
      // at any of the runs on the list. If so, don't show the
      // selection view
      bool showRunList = true;

      for (AreWeAtRunResult result in resultList) {
        if (result.attendenceState >= attendenceAtHash.value) {
          showRunList = false;
          break;
        }
      }

      if (showRunList) {
        final dynamic doCheckIn = await Navigator.push<dynamic>(
          context,
          MaterialPageRoute<dynamic>(
            builder: (BuildContext context) => SelectRunPage(runList: resultList),
          ),
        );
        if ((doCheckIn as bool) == true) {
          for (AreWeAtRunResult result in resultList) {
            if (result.selected) {
              await _checkInAtEvent(result.eventId, userId);
            }
          }
        }
      }
    }
  }

  Future<void> _checkInAtEvent(String eventId, String userId) async {
    await G0<TableModel>().hasherEventMapService.joinEvent(eventId, userId, null, AppDomainType.user, rsvpState: rsvpYes.value, attendenceState: attendenceAtHash.value);
    if (futureRunsListPageKey?.currentState != null) {
      await futureRunsListPageKey.currentState.forceRefreshFromTableExternal();
    }
  }

  Future<bool> _checkLocationPermissions() async {
    G0<AppModel>().hasLocationPermissions = await Permission.location.isGranted;
    return G0<AppModel>().hasLocationPermissions;
  }

  void informUser(String message) {
    setState(() {
      _initializationMessage = message;
    });
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  int currentPage = 0;

  GlobalKey bottomNavigationKey = GlobalKey();

  Widget _getPage(int pageIndex) {
    Widget w;
    _appBarText = _tabTitles[pageIndex];

    switch (pageIndex) {
      case 0:
        w = _futureRunsListPage;
        break;
      case 1:
        w = _kennelsListPage;
        break;
      case 2:
        w = _runAndKennelMapPage;
        break;
      case 3:
        w = _historyListPage;
        break;
      // case 3:
      //   w = userQrCodePage;
      //   break;
    }
    return w;
  }

  Widget _getFab() {
    Widget fab;

    if ((_runAndKennelMapPageKey?.currentState != null) && !_isFlipped && (currentPage == 2)) {
      fab = _runAndKennelMapPageKey.currentState.getMapFab();
    }

    if ((_kennelLocationsPageKey?.currentState != null) && !_isFlipped && (currentPage == 1)) {
      fab = _kennelLocationsPageKey.currentState.getKennelFab();
    }

    return fab;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned(
          top: 0,
          left: 0,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              elevation: 3.0,
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: themeStatusBarBackground, // <-- SEE HERE
                statusBarIconBrightness: Brightness.light, //<-- For Android SEE HERE (dark icons)
                statusBarBrightness: Brightness.light, //<-- For iOS SEE HERE (dark icons)
              ),
              backgroundColor: themeAppBarBackground,
              title: Text(_appBarText),
              centerTitle: true,
              actions: <IconButton>[
                IconButton(
                    icon: const Icon(Icons.qr_code_scanner_sharp),
                    onPressed: () {
                      Navigator.push<dynamic>(
                        context,
                        MaterialPageRoute<dynamic>(
                          builder: (BuildContext context) => const UserQrCodePage(),
                        ),
                      );
                    }),
                IconButton(
                    icon: Icon(_isFlipped ? Icons.undo : Icons.info_outline),
                    onPressed: () {
                      setState(() {
                        _isFlipped = !_isFlipped;
                      });
                    }),
              ],
            ),
            floatingActionButton: _getFab(),
            body: Container(
              decoration: const BoxDecoration(color: Colors.white),
              child: FutureBuilder<void>(
                  future: _dbReady,
                  builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                    if (snapshot.hasData) {
                      return FlippableBox(
                        key: const Key('66193020'),
                        front: _front(),
                        // ignore: avoid_unnecessary_containers
                        back: Container(
                          child: Swiper(
                            pagination: SwiperCustomPagination(
                              builder: (BuildContext context, SwiperPluginConfig config) {
                                return Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: <Widget>[
                                    Expanded(child: Container()),
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Align(
                                            alignment: Alignment.bottomCenter,
                                            child: const DotSwiperPaginationBuilder(
                                              color: Colors.grey,
                                              activeColor: Colors.blue,
                                              size: 10.0,
                                              activeSize: 20.0,
                                            ).build(context, config),
                                          ),
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 20.0)
                                  ],
                                );
                              },
                            ),
                            itemCount: _tutorials[currentPage].length,
                            control: const SwiperControl(color: Colors.red, disableColor: Colors.blue),
                            itemBuilder: (BuildContext context, int index) {
                              // this configuration of LayoutBuilder is used to center images that do not
                              // overflow the height of the available render area, but align images
                              // to the top of the render space if they will overflow the available space.
                              return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                                return Stack(
                                  clipBehavior: Clip.hardEdge,
                                  fit: StackFit.passthrough,
                                  alignment: AlignmentDirectional.topCenter,
                                  children: <Widget>[
                                    Positioned(
                                      top: 15.0,
                                      left: 0.0,
                                      right: 0.0,
                                      child: Column(
                                        children: <Widget>[
                                          ConstrainedBox(
                                            constraints: BoxConstraints(minHeight: constraints.maxHeight > 60 ? constraints.maxHeight - 60 : constraints.maxHeight),
                                            child: Image.asset(
                                              _tutorials[currentPage][index],
                                              fit: BoxFit.fitWidth,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(bottom: 0.0, left: 0.0, right: 0.0, child: Container(height: 60.0, color: Colors.white))
                                  ],
                                );
                              });
                            },
                          ),
                        ),
                        isFlipped: _isFlipped,
                      );
                    } else {
                      return Container(
                        decoration: Backgrounds.defaultHcBackground(),
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        child: Center(
                            child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                'Filling your Harrier Central mug',
                                style: headingStyle,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Image.asset(
                                'images/other/beer_pour.gif',
                                // height: 250,
                                // width: 250,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                _initializationMessage,
                                style: headingStyle,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        )),
                      );
                    }
                  }),
            ),
            bottomNavigationBar: FlippableBox(
              key: const Key('667701326'),
              // ignore: avoid_unnecessary_containers
              front: Container(
                child: FancyBottomNavigation(
                  circleColor: themeButtonColors,
                  inactiveIconColor: themeBackgroundColor,
                  barBackgroundColor: themeNavBarBackground,
                  tabs: <TabData>[
                    TabData(
                      iconData: MaterialCommunityIcons.run_fast,
                      title: 'Runs',
                    ),
                    TabData(
                      iconData: FontAwesome.home,
                      title: 'Kennels',
                    ),
                    TabData(
                      iconData: FontAwesome.map,
                      title: 'Explore',
                    ),
                    TabData(
                      iconData: FontAwesome.list_ul,
                      title: 'History',
                    ),
                  ],
                  initialSelection: 0,
                  key: bottomNavigationKey,
                  onTabChangedListener: (int position) {
                    setState(() {
                      _appBarText = _tabTitles[position];
                      currentPage = position;

                      // this extra setState is here to ensure that the FAB
                      // displays properly when the map page is showing
                      if ((!_isFlipped) && (currentPage == 2)) {
                        Future<void>.delayed(const Duration(milliseconds: 250)).then((void _) {
                          setState(() {});
                        });
                      }
                    });
                  },
                ),
              ),
              // ignore: sized_box_for_whitespace
              back: Container(height: 0, width: 0),
              isFlipped: _isFlipped,
            ),
            drawer: DrawerMenu(
              scaffoldKey: _scaffoldKey,
              futureRunsListKey: futureRunsListPageKey,
            ),
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

  Container _front() {
    // ignore: avoid_unnecessary_containers
    return Container(
      child: Center(
        child: _getPage(currentPage),
      ),
    );
  }
}
