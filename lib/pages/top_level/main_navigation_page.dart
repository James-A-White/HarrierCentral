import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter_swiper/flutter_swiper.dart';

import 'package:harrier_central/database/common_queries.dart';
import 'package:harrier_central/pages/top_level/run_locations.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/widgets/confirm_auto_checkin_popup.dart';

import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:fancy_bottom_navigation/fancy_bottom_navigation.dart';
import 'package:location_permissions/location_permissions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:harrier_central/database/notifications_table.dart';
import 'package:harrier_central/data/hc3_services/sync_user_data_service.dart';
import 'package:harrier_central/database/migrations.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/widgets/offline_mode_ribbon.dart';
import 'package:harrier_central/widgets/flippable_box.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/pages/top_level/history_list_page.dart';
import 'package:harrier_central/pages/top_level/future_run_list_page.dart';
import 'package:harrier_central/pages/top_level/drawer_menu.dart';
import 'package:harrier_central/pages/top_level/kennel_list_page.dart';
import 'package:harrier_central/data/hc3_services/base_service.dart';
import 'package:harrier_central/notifications/notification_support.dart';

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

  static List<String> helpNotAvailable = <String>[
    'images/tutorial/help_not_available.jpg',
  ];

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

    // final bool result = await syncUserDataService.updateFromBackend(SyncUserDataService.flagsAllData, false);
    // final String resultStr = result ? 'successfully' : 'unsuccessfully';
    // print('Master data synchronized $resultStr');

    // this is here to force the database to be instnatiated upon startup.
    // the first time this is run, the database will be created. On subsequent
    // runs, the database will simply be opened.

    Future<void> createTables(Database db, int version) async {
      await hashersTableHelper.createTable(db, version, null);
      await citiesTableHelper.createTable(db, version, null);
      await regionsTableHelper.createTable(db, version, null);
      await countriesTableHelper.createTable(db, version, null);
      await kennelsTableHelper.createTable(db, version, null);
      await hasherKennelMapTableHelper.createTable(db, version, TableType.hkmUser);
      await hasherEventMapTableHelper.createTable(db, version, TableType.hemUser);
      await eventsTableHelper.createTable(db, version, null);
      await paymentsTableHelper.createTable(db, version, TableType.paymentsUser);
      await NotificationsTableHelper.createTable(db, version);
      await MigrationsTableHelper.createTable(db, version);

      // create event admin tables
      await hasherEventMapTableHelper.createTable(db, version, TableType.hemEventAdmin);
      await hasherKennelMapTableHelper.createTable(db, version, TableType.hkmEventAdmin);
      await paymentsTableHelper.createTable(db, version, TableType.paymentsEvent);
      await receiptsTableHelper.createTable(db, version, null);
      await kennelCreditsTableHelper.createTable(db, version, null);

      // create kennel admin tables
      await hasherKennelMapTableHelper.createTable(db, version, TableType.hkmKennelAdmin);

      if (informUser != null) {
        informUser('Loading city data\r\n0% complete');
      }
      // first load the cities from the static text file into SQFLITE
      final String cityJson = await rootBundle.loadString('database/cities.json');
      final BaseService citySrv = BaseService();
      await citySrv.bulkUpdateDatabase(citiesTableHelper, cityJson, db, informUser);

      if (informUser != null) {
        informUser('Loading region data\r\n0% complete');
      }
      // first load the regions from the static text file into SQFLITE
      final String regionJson = await rootBundle.loadString('database/regions.json');
      await baseService.bulkUpdateDatabase(regionsTableHelper, regionJson, db, informUser);

      if (informUser != null) {
        informUser('Loading country data\r\n0% complete');
      }

      final String countriesJson = await rootBundle.loadString('database/countries.json');
      await baseService.bulkUpdateDatabase(countriesTableHelper, countriesJson, db, informUser);
    }

    migrationList.sort((MigrationsModel a, MigrationsModel b) => a.dbVersion.compareTo(b.dbVersion));

    // make sure the DB_VERSION is equal to the maximum migration in the list
    assert(DB_VERSION == migrationList.last.dbVersion);

    openOrInitializeDb(DB_NAME, DB_VERSION, informUser, migrations: migrationList, createTables: createTables).then((void dummy) {
      final NotificationSupport notifications = NotificationSupport();
      notifications.configureNotifications(true);

      syncUserDataService.updateFromBackend(SyncUserDataService.flagsAllData, false, informUser: informUser).then((bool result) {
        final String resultStr = result ? 'successfully' : 'unsuccessfully';
        print('Master data synchronized $resultStr');

        setIntPref(IntPrefsEnum.dbCreated, 1);
        setIntPref(IntPrefsEnum.databaseVersion, DB_VERSION);

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
                  hasherEventMapService.joinEvent(result.eventId, TableType.hemUser, userId, null, AppDomainType.user, rsvpState: rsvpYes.value, attendenceState: attendenceAtHash.value).then((List<dynamic> svcResult) {
                    futureRunsListPageKey.currentState.forceRefreshFromTableExternal();
                  });
                }
              }
            });
          }
        });
      });
    });
  }

  Future<bool> checkLocationPermissions() async {
    bool hasLocPermission = true;

    final LocationPermissions permissions = LocationPermissions();

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

    PermissionStatus locationPermission = await permissions.checkPermissionStatus(level: LocationPermissionLevel.location);
    if (locationPermission != PermissionStatus.granted) {
      locationPermission = await permissions.checkPermissionStatus(level: LocationPermissionLevel.locationWhenInUse);
      if (locationPermission != PermissionStatus.granted) {
        locationPermission = await permissions.checkPermissionStatus(level: LocationPermissionLevel.locationAlways);
        if (locationPermission != PermissionStatus.granted) {
          hasLocPermission = false;
        }
      }
    }

    setIntPref(IntPrefsEnum.hasLocationPermissions, hasLocPermission ? 1 : 0);
    hasLocationPermissions = hasLocPermission;
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
    final int dbCreated = getIntPref(IntPrefsEnum.dbCreated) ?? 0;

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
                child: dbCreated == 0
                    ? Container(
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
                      )
                    : FlippableBox(
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
                                            child: DotSwiperPaginationBuilder(
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
                                  overflow: Overflow.clip,
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
                      )),
            bottomNavigationBar: FlippableBox(
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
        const OfflineModeRibbon(),
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

  // *****************
  // DB migrations & version

  static List<MigrationsModel> migrationList = <MigrationsModel>[
    // MIGRATION 221
    MigrationsModel(dbVersion: 221, migrationText: '''
            ALTER TABLE ${hashersTableHelper.tableName} ADD COLUMN ${hashersTableHelper.colHomeKennelId} TEXT;
         '''),

    // MIGRATION 222
    MigrationsModel(dbVersion: 222, migrationText: '''
            ALTER TABLE ${hasherKennelMapTableHelper.getTableName(TableType.hkmUser)} ADD COLUMN ${hasherKennelMapTableHelper.colKennelEmailAlertPreference} INT;
            ALTER TABLE ${hasherKennelMapTableHelper.getTableName(TableType.hkmEventAdmin)} ADD COLUMN ${hasherKennelMapTableHelper.colKennelEmailAlertPreference} INT;
            ALTER TABLE ${hasherKennelMapTableHelper.getTableName(TableType.hkmKennelAdmin)} ADD COLUMN ${hasherKennelMapTableHelper.colKennelEmailAlertPreference} INT;
         '''),

    // MIGRATION 223
    MigrationsModel(dbVersion: 223, migrationText: '''
            ALTER TABLE ${hasherEventMapTableHelper.getTableName(TableType.hemUser)} ADD COLUMN ${hasherEventMapTableHelper.colEventEmailAlertPreference} INT;
            ALTER TABLE ${hasherEventMapTableHelper.getTableName(TableType.hemEventAdmin)} ADD COLUMN ${hasherKennelMapTableHelper.colKennelEmailAlertPreference} INT;
         '''),

    // MIGRATION 224
    MigrationsModel(dbVersion: 224, migrationText: '''
            ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colEventPriceForExtras} NUM;
            ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colExtrasDescription} TEXT;
            ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colDoTrackHashCash} INT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelMismanagementTeam} TEXT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colDistancePreference} INT;
            ALTER TABLE ${hasherKennelMapTableHelper.getTableName(TableType.hkmKennelAdmin)} ADD COLUMN ${hasherKennelMapTableHelper.colIsKennelFollowing} INT;
            ALTER TABLE ${hasherKennelMapTableHelper.getTableName(TableType.hkmKennelAdmin)} ADD COLUMN ${hasherKennelMapTableHelper.colMismanagementRoles} INT;
            ALTER TABLE ${hasherKennelMapTableHelper.getTableName(TableType.hkmUser)} ADD COLUMN ${hasherKennelMapTableHelper.colIsKennelFollowing} INT;
            ALTER TABLE ${hasherKennelMapTableHelper.getTableName(TableType.hkmUser)} ADD COLUMN ${hasherKennelMapTableHelper.colMismanagementRoles} INT;
            ALTER TABLE ${hashersTableHelper.tableName} ADD COLUMN ${hashersTableHelper.colIncludeInGlobalHashDirectory} INT;
            ALTER TABLE ${countriesTableHelper.tableName} ADD COLUMN ${countriesTableHelper.colDistancePreference} INT NOT NULL DEFAULT 0;
         '''),

    // MIGRATION 225
    MigrationsModel(dbVersion: 225, migrationText: '''
            ALTER TABLE ${hashersTableHelper.tableName} ADD COLUMN ${hashersTableHelper.colPreferences} INT;
         '''),

    // MIGRATION 226
    MigrationsModel(dbVersion: 226, migrationText: '''
            ALTER TABLE ${hasherKennelMapTableHelper.getTableName(TableType.hkmEventAdmin)} ADD COLUMN ${hasherKennelMapTableHelper.colIsKennelFollowing} INT;
            ALTER TABLE ${hasherKennelMapTableHelper.getTableName(TableType.hkmEventAdmin)} ADD COLUMN ${hasherKennelMapTableHelper.colMismanagementRoles} INT;
         '''),

    // MIGRATION 227
    MigrationsModel(dbVersion: 227, migrationText: '''
            ALTER TABLE ${paymentsTableHelper.getTableName(TableType.paymentsEvent)} ADD COLUMN ${paymentsTableHelper.colDoPayForExtras} INT;
         '''),

    // MIGRATION 228
    MigrationsModel(dbVersion: 228, migrationText: '''
            ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colTags1} INT;
            ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colTags2} INT;
            ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colTags3} INT;
         '''),

    MigrationsModel(dbVersion: 229, migrationText: '''
            ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colEventPaymentScheme} TEXT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentScheme} TEXT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentScheme2} TEXT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentScheme3} TEXT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentUrl2} TEXT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentUrl3} TEXT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentUrlExpires2} TEXT;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentUrlExpires3} TEXT;
         '''),

    MigrationsModel(dbVersion: 230, migrationText: '''
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentMemberSurcharge} NUM;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentNonMemberSurcharge} NUM;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentMemberSurcharge2} NUM;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentNonMemberSurcharge2} NUM;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentMemberSurcharge3} NUM;
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPaymentNonMemberSurcharge3} NUM;
         '''),

    MigrationsModel(dbVersion: 231, migrationText: '''
            ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colAllowSelfPayment} INT;
         '''),

    MigrationsModel(dbVersion: 232, migrationText: '''
            ALTER TABLE ${paymentsTableHelper.getTableName(TableType.paymentsEvent)} ADD COLUMN ${paymentsTableHelper.colSurcharge} INT;
            ALTER TABLE ${paymentsTableHelper.getTableName(TableType.paymentsEvent)} ADD COLUMN ${paymentsTableHelper.colPaymentProvider} INT;
         '''),

    MigrationsModel(dbVersion: 251, migrationText: '''
            ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colLocationCountry} TEXT;
         '''),

    MigrationsModel(dbVersion: 252, migrationText: '''
                  ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colLocationRegion} TEXT;
                  ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colLocationSubRegion} TEXT;         
         '''),

    MigrationsModel(dbVersion: 253, migrationText: '''
                  ALTER TABLE ${kennelsTableHelper.tableName} ADD COLUMN ${kennelsTableHelper.colKennelPinColor} INT;    
         '''),

    MigrationsModel(dbVersion: DB_VERSION, migrationText: '''
                  ALTER TABLE ${eventsTableHelper.tableName} ADD COLUMN ${eventsTableHelper.colEventGeographicScope} INT;          
         '''),
  ];

  
}
