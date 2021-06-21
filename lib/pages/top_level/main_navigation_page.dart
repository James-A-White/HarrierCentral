import 'package:harrier_central/imports.dart';
import 'package:location_permissions/location_permissions.dart' as perms;
import 'package:harrier_central/pages/top_level/drawer_menu.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({Key key}) : super(key: key);

  @override
  _MainNavigationPageState createState() => _MainNavigationPageState();
}

final GlobalKey<RunLocationsPageState> runLocationsPageKey = GlobalKey<RunLocationsPageState>();

class _MainNavigationPageState extends State<MainNavigationPage> {
  //MainNavigationScopedModel homePageModel = MainNavigationScopedModel();

  List<Widget> tabs = <Widget>[];
  List<String> tabTitles = <String>[];

  List<List<String>> tutorials = <List<String>>[tutorialUpcomingRuns, tutorialKennelsView, tutorialRunLocations, tutorialRunCounts];

  static List<String> tutorialRunLocations = <String>[
    'images/tutorial/run_locations_help_1.jpg',
    'images/tutorial/run_locations_help_2.jpg',
    'images/tutorial/run_locations_help_3.jpg',
    'images/tutorial/run_locations_help_4.jpg',
  ];

  static List<String> tutorialUpcomingRuns = <String>[
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

  static List<String> tutorialRunCounts = <String>[
    'images/tutorial/run_counts_tutorial_1.jpg',
    'images/tutorial/run_counts_tutorial_2.jpg',
    'images/tutorial/run_counts_tutorial_3.jpg',
  ];

  static List<String> tutorialKennelsView = <String>[
    'images/tutorial/kennels_tutorial_1.jpg',
    'images/tutorial/kennels_tutorial_2.jpg',
    'images/tutorial/kennels_tutorial_3.jpg',
    'images/tutorial/kennels_tutorial_4.jpg',
    'images/tutorial/kennels_tutorial_5.jpg',
    'images/tutorial/kennels_tutorial_6.jpg',
    'images/tutorial/kennels_tutorial_7.jpg',
  ];

  String appBarText;
  String initializationMessage = '';

  bool isFlipped = false;
  bool fabFlipped = false;

  // TODO(James): Investigate Page Storage Bucket / PageView

  FutureRunsListPage futureRunsListPage;
  KennelsListPage kennelsListPage;
  HistoryListPage historyListPage;
  //final UserQrCodePage userQrCodePage = const UserQrCodePage();
  RunLocationsPage runLocationsPage;

  Future<bool> _dbReady;

  @override
  void initState() {
    tabTitles.add('Upcoming Runs');
    tabTitles.add('Kennels');
    tabTitles.add('Explore Runs');
    tabTitles.add('Run Counts');

    //tabTitles.add('Scanner');
    // tabTitles.add('Friends');

    appBarText = tabTitles[0];

    super.initState();

    // final bool result = await G0<TableModel>().syncUserDataService.updateFromBackend(SyncUserDataService.flagsAllData, false);
    // final String resultStr = result ? 'successfully' : 'unsuccessfully';
    // print('Master data synchronized $resultStr');

    // this is here to force the database to be instnatiated upon startup.
    // the first time this is run, the database will be created. On subsequent
    // runs, the database will simply be opened.

    Tables.migrationList.sort((MigrationsModel a, MigrationsModel b) => a.dbVersion.compareTo(b.dbVersion));

    // make sure the DB_VERSION is equal to the maximum migration in the list
    assert(DB_VERSION == Tables.migrationList.last.dbVersion);

    // DANGER - need to look into definition of ClientApp
    _dbReady = setupDatabase(informUser, 'PRO_APP').then((bool dummy) {
      final NotificationSupport notifications = NotificationSupport();
      notifications.configureNotifications(true);
      // G0<TableModel>().syncUserDataService.updateFromBackend(SyncUserDataService.flagsAllData, false, informUser: informUser).then((bool result) {
      //   final String resultStr = result ? 'successfully' : 'unsuccessfully';
      //   print('Master data synchronized $resultStr');

      //   setIntPref(IntPrefsEnum.databaseVersion, DB_VERSION);

      // create pages after database is loaded
      futureRunsListPage = FutureRunsListPage();
      kennelsListPage = const KennelsListPage();
      historyListPage = const HistoryListPage();
      //final UserQrCodePage userQrCodePage = const UserQrCodePage();
      runLocationsPage = RunLocationsPage(key: runLocationsPageKey);

      setState(() {});

      checkLocationPermissions().then((bool hasLoc) {
        if (hasLoc) {
          CommonQueries.areWeAtRunStart().then((AreWeAtRunResult result) async {
            if ((result.eventId != EMPTY_RESULT) && (result.distanceInMeters <= GEOFENCE_IN_METERS_AROUND_RUN_START_FOR_AUTO_CHECKIN)) {
              final ConfirmAutoCheckinPopup popup = ConfirmAutoCheckinPopup(
                title: 'Check-in to Run',
                eventImage: result.eventImage,
                eventName: result.eventName,
                kennelLogo: result.kennelLogo,
                okButtonTitle: 'Yes',
                cancelButtonTitle: 'No',
                kennelShortName: result.kennelShortName,
                eventNumber: result.eventNumber,
              );

              final EnumYesNo<int> retVal = await showDialog<EnumYesNo<int>>(
                  context: context,
                  barrierDismissible: false, // user must tap button!
                  builder: (BuildContext context) {
                    return popup;
                  });

              final String userId = getStringPref(StringPrefsEnum.userId);

              if (retVal == enumYesNo_Yes) {
                G0<TableModel>()
                    .hasherEventMapService
                    .joinEvent(result.eventId, userId, null, AppDomainType.user, rsvpState: rsvpYes.value, attendenceState: attendenceAtHash.value)
                    .then((
                  List<dynamic> svcResult,
                ) {
                  futureRunsListPageKey.currentState.forceRefreshFromTableExternal();
                });
              }
            }
          });
        }
      });
      return true;
    });
  }

  Future<bool> checkLocationPermissions() async {
    bool hasLocPermission = true;

    final perms.LocationPermissions permissions = perms.LocationPermissions();

    // ServiceStatus locationStatus = await permissions.checkServiceStatus(PermissionGroup.location);
    // if (locationStatus != ServiceStatus.enabled) {
    //   locationStatus = await permissions.checkServiceStatus(PermissionGroup.locationAlways);
    //   if (locationStatus != ServiceStatus.enabled) {
    //     locationStatus = await permissions.checkServiceStatus(PermissionGroup.locationWhenInUse);
    //     if (locationStatus != ServiceStatus.enabled) {
    //       hasLocPermission = false;
    //     }
    //   }
    // }

    perms.PermissionStatus locationPermission = await permissions.checkPermissionStatus(level: perms.LocationPermissionLevel.location);
    if (locationPermission != perms.PermissionStatus.granted) {
      locationPermission = await permissions.checkPermissionStatus(level: perms.LocationPermissionLevel.locationWhenInUse);
      if (locationPermission != perms.PermissionStatus.granted) {
        locationPermission = await permissions.checkPermissionStatus(level: perms.LocationPermissionLevel.locationAlways);
        if (locationPermission != perms.PermissionStatus.granted) {
          hasLocPermission = false;
        }
      }
    }

    setIntPref(IntPrefsEnum.hasLocationPermissions, hasLocPermission ? 1 : 0);
    G0<AppModel>().hasLocationPermissions = hasLocPermission;
    return hasLocPermission;
  }

  void informUser(String message) {
    setState(() {
      initializationMessage = message;
    });
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  int currentPage = 0;

  GlobalKey bottomNavigationKey = GlobalKey();

  Widget _getPage(int pageIndex) {
    Widget w;
    appBarText = tabTitles[pageIndex];

    switch (pageIndex) {
      case 0:
        //futureRunsListPage??= const FutureRunsListPage();
        w = futureRunsListPage;
        break;
      case 1:
        w = kennelsListPage;
        break;
      case 2:
        w = runLocationsPage;
        break;
      case 3:
        w = historyListPage;
        break;
      // case 3:
      //   w = userQrCodePage;
      //   break;
    }
    return w;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        // Container(
        //   height: MediaQuery.of(context).size.height,
        //   width: MediaQuery.of(context).size.width,
        //   color:Colors.red
        // ),
        Positioned(
          top: 0,
          left: 0,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: themeAppBarBackground,
              title: Text(appBarText),
              actions: <IconButton>[
                IconButton(
                    icon: Icon(isFlipped ? Icons.undo : Icons.info_outline),
                    onPressed: () {
                      isFlipped = !isFlipped;
                      if (isFlipped == true) {
                        fabFlipped = true;
                      }
                      setState(() {
                        // do this extra setState to ensure the FAB is displayed properly
                      });
                      Future<void>.delayed(const Duration(milliseconds: 250)).then((void dummy) {
                        fabFlipped = isFlipped;
                        setState(() {});
                      });
                    }),
              ],
            ),
            floatingActionButton: (runLocationsPageKey?.currentState == null) || (fabFlipped == true) ? null : runLocationsPageKey.currentState.getFab(),
            body: Container(
              decoration: const BoxDecoration(color: Colors.white),
              child: FutureBuilder<void>(
                  future: _dbReady,
                  builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                    if (snapshot.hasData) {
                      return FlippableBox(
                        key: UniqueKey(),
                        front: front(),
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
                            itemCount: tutorials[currentPage].length,
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
                                              tutorials[currentPage][index],
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
                        isFlipped: isFlipped,
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
                            Image.asset(
                              'images/other/creating_database.png',
                              height: 250,
                              width: 250,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                initializationMessage,
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
              key: UniqueKey(),
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
                    appBarText = tabTitles[position];
                    currentPage = position;
                    setState(() {});
                    Future<void>.delayed(const Duration(milliseconds: 100)).then((void dummy) {
                      setState(() {});
                    });
                  },
                ),
              ),
              back: Container(height: 0, width: 0),
              isFlipped: isFlipped,
            ),
            drawer: DrawerMenu(scaffoldKey: _scaffoldKey),
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

  Container front() {
    return Container(
      child: Center(
        child: _getPage(currentPage),
      ),
    );
  }
}
