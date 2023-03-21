import 'package:harrier_central/imports_null_safe.dart';
import 'package:harrier_central/pages/top_level/drawer_menu.dart';
import 'package:harrier_central/pages/top_level/select_run_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({
    Key? key,
    required this.promos,
    required this.firstPromoImage,
  }) : super(key: key);

  final List<PromoModel> promos;
  final Image firstPromoImage;

  @override
  MainNavigationPageState createState() => MainNavigationPageState();
}

final GlobalKey<RunAndKennelMapPageState> _runAndKennelMapPageKey = GlobalKey<RunAndKennelMapPageState>();
final GlobalKey<KennelsListPageState> _kennelLocationsPageKey = GlobalKey<KennelsListPageState>();

class MainNavigationPageState extends State<MainNavigationPage> {
  //MainNavigationScopedModel homePageModel = MainNavigationScopedModel();

  //final List<Widget> _tabs = <Widget>[];
  static final List<String> _tabTitles = <String>[
    'Upcoming Runs',
    'Kennels',
    'Explore Runs',
    'Run Counts',
  ];

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

  String _appBarText = _tabTitles[0];
  String _initializationMessage = '';

  bool _isFlipped = false;
  bool _showMainScreen = false;
  bool _showPromoScreenTools = false;

  int _steps = 10;

  // TODO(James): Investigate Page Storage Bucket / PageView

  late FutureRunsListPage _futureRunsListPage;
  late KennelsListPage _kennelsListPage;
  late HistoryListPage _historyListPage;
  late RunAndKennelMapPage _runAndKennelMapPage;

  PausableTimer? _promoTimer;
  Duration _promoDisplayDuration = const Duration(seconds: 3);
  int? _timeRemaining;

  Image? _promoImage;

  @override
  void initState() {
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

    // print('******* > Starting DB Setup');

    setupDatabase(informUser, 'PRO_APP').then((bool result) async {
      // print('******* > Finished DB Setup');
      // final NotificationSupport notifications = NotificationSupport();
      // await notifications.configureNotifications(true);
      // G0<TableModel>().syncUserDataService.updateFromBackend(SyncUserDataService.flagsAllData, false, informUser: informUser).then((bool result) {
      //   final String resultStr = result ? 'successfully' : 'unsuccessfully';
      //   //print('Master data synchronized $resultStr');

      //   setIntPref(IntPrefsEnum.databaseVersion, DB_VERSION);

      // create pages after database is loaded
      // print('******* > Init 1');

      _futureRunsListPage = FutureRunsListPage();
      // print('******* > Init 2');
      _kennelsListPage = KennelsListPage(key: _kennelLocationsPageKey);
      // print('******* > Init 3');
      _historyListPage = HistoryListPage();
      // print('******* > Init 4');
      //final UserQrCodePage userQrCodePage = const UserQrCodePage();
      _runAndKennelMapPage = RunAndKennelMapPage(key: _runAndKennelMapPageKey);
      // print('******* > Init 5');

      setState(() {});

      // print('******* > Init 6');
      final bool hasLoc = await _checkLocationPermissions();
      // print('******* > Init 7');
      if (hasLoc) {
        // print('******* > Init 8');
        // ignore: unawaited_futures
        _checkAreWeAtRunStart();
      }
      // print('******* > Init 9');

      setState(() {});

      if (widget.promos.isNotEmpty) {
        setState(() {
          _showPromoScreenTools = true;
        });
        _timeRemaining = widget.promos[0].promoDisplayTimeInMs;
        _steps = widget.promos[0].promoDisplayTimingDotsToDisplay;
        _promoDisplayDuration = Duration(milliseconds: _timeRemaining! ~/ _steps);

        if (widget.promos.isNotEmpty) {
          _promoTimer = PausableTimer(_promoDisplayDuration, () {
            _timeRemaining = _timeRemaining! - widget.promos[0].promoDisplayTimeInMs ~/ _steps;
            if (_timeRemaining! < 0) {
              _promoTimer!.cancel();
              _promoTimer = null;
              _showMainScreen = true;
            } else {
              if (_promoTimer != null) {
                _promoTimer!
                  ..reset()
                  ..start();
              }
            }
            setState(() {});
          })
            ..start();
        }
      } else {
        setState(() {
          _showMainScreen = true;
        });
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
    final List<AreWeAtRunModel> resultList = await CommonQueries.areWeAtRunStart();
    final String userId = getStringPref(StringPrefsEnum.userId)!;

    if (resultList.length == 1) {
      final AreWeAtRunModel result = resultList[0];

      if (result.eventId != EMPTY_RESULT) {
        final ConfirmAutoCheckinPopup popup = ConfirmAutoCheckinPopup(
          title: 'Check-in to Run',
          areWeAtRunData: result,
          okButtonTitle: 'Yes',
          cancelButtonTitle: 'No',
        );

        final EnumCheckinOptions<int>? retVal = await showDialog<EnumCheckinOptions<int>>(
            context: navigatorKey.currentContext!,
            barrierDismissible: false, // user must tap button!
            builder: (BuildContext context) {
              return popup;
            });

        if (retVal == enumCheckInOption_Yes) {
          await _checkInAtEvent(result.eventId, userId);
        } else if ((retVal == enumCheckInOption_YesAndPayByCredit) || (retVal == enumCheckInOption_YesAndPayByBankXfer)) {
          final PaymentsService paySrv = PaymentsService();
          await paySrv.payForEvent(
            result.eventId,
            userId,
            GUID_EMPTY,
            retVal == enumCheckInOption_YesAndPayByCredit ? paymentHashCredit.value : paymentBankTransfer.value,
            result.membershipExpirationDate.isAfter(DateTime.now()) ? result.memberPrice : result.nonMemberPrice,
            attendenceAtHash.value,
            payForRunOnly,
            AppDomainType.user,
          );
        } else if ((retVal == enumCheckInOption_YesAndPayPlusExtrasByCredit) || (retVal == enumCheckInOption_YesAndPayPlusExtrasByBankXfer)) {
          final PaymentsService paySrv = PaymentsService();
          await paySrv.payForEvent(
              result.eventId,
              userId,
              GUID_EMPTY,
              retVal == enumCheckInOption_YesAndPayPlusExtrasByCredit ? paymentHashCredit.value : paymentBankTransfer.value,
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
      final Map<String, bool> selectedRuns = <String, bool>{};

      for (AreWeAtRunModel result in resultList) {
        selectedRuns[result.eventId] = false; //prepare the selection result list
        if (result.attendenceState >= attendenceAtHash.value) {
          showRunList = false;
          break;
        }
      }

      if (showRunList) {
        if (!mounted) return;
        final dynamic doCheckIn = await Navigator.push<dynamic>(
          context,
          MaterialPageRoute<dynamic>(
            builder: (BuildContext context) => SelectRunPage(runList: resultList, selected: selectedRuns),
          ),
        );
        if ((doCheckIn as bool) == true) {
          for (AreWeAtRunModel result in resultList) {
            if ((selectedRuns.containsKey(result.eventId)) && (selectedRuns[result.eventId] == true)) {
              await _checkInAtEvent(result.eventId, userId);
            }
          }
        }
      }
    }
  }

  Future<void> _checkInAtEvent(String eventId, String userId) async {
    await G0<TableModel>().hasherEventMapService.setEventAttendence(
          eventId,
          userId,
          AppDomainType.user,
          attendenceAtHash.value,
        );

    if (futureRunsListPageKey.currentState != null) {
      await futureRunsListPageKey.currentState!.forceRefreshFromTableExternal();
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
      default:
        w = _futureRunsListPage;
        break;
      // case 3:
      //   w = userQrCodePage;
      //   break;
    }
    return w;
  }

  Widget? _getFab() {
    Widget? fab;

    if ((_runAndKennelMapPageKey.currentState != null) && !_isFlipped && (currentPage == 2)) {
      fab = _runAndKennelMapPageKey.currentState!.getMapFab();
    }

    if ((_kennelLocationsPageKey.currentState != null) && !_isFlipped && (currentPage == 1)) {
      fab = _kennelLocationsPageKey.currentState!.getKennelFab();
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
            key: _scaffoldKey,
            backgroundColor: Colors.white,
            appBar: (!_showMainScreen)
                ? null
                : AppBar(
                    elevation: 3.0,
                    backgroundColor: themeAppBarBackground,
                    title: Text(
                      _appBarText,
                      textScaleFactor: G0<DeviceInfo>().textClamp00,
                    ),
                    centerTitle: true,
                    actions: <IconButton>[
                      IconButton(
                          icon: const Icon(Icons.qr_code_scanner_sharp),
                          onPressed: () {
                            // NULLSAFETODO
                            // Navigator.push<dynamic>(
                            //   context,
                            //   MaterialPageRoute<dynamic>(
                            //     builder: (BuildContext context) => const UserQrCodePage(),
                            //   ),
                            // );
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
            body: (!_showMainScreen)
                ? (widget.promos.isNotEmpty)
                    ? _getPromoScreen()
                    : _getGenericLoadingScreen()
                : Container(
                    decoration: const BoxDecoration(color: Colors.white),
                    child: FlippableBox(
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
                    ),
                  ),

            // } else {
            //   if ((widget.promos != null) && (widget.promos.isNotEmpty)) {
            //     return _getPromoScreen();
            //   } else {
            //     return _getGenericLoadingScreen();
            //   }
            // }
            bottomNavigationBar: (!_showMainScreen)
                ? null
                : FlippableBox(
                    key: const Key('667701326'),
                    // ignore: avoid_unnecessary_containers
                    front: Container(
                      child: TextScaleFactorClamper(
                        textScaleFactor: G0<DeviceInfo>().textClamp00,
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
          refreshFunction: () {
            setState(() {});
          },
        ),
      ],
    );
  }

  Container _getGenericLoadingScreen() {
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

  final List<Widget> _overlays = <Widget>[];

  Widget _getPromoScreen() {
    final List<String> overlaysToDisplay = widget.promos[0].promoOverlayTiming.split(',');

    int currentStep = 0;

    if (_timeRemaining != null) {
      currentStep = _steps - ((_timeRemaining ?? 0) ~/ (widget.promos[0].promoDisplayTimeInMs / _steps));

      final List<int> overlaysToDisplayInt = overlaysToDisplay.map(int.parse).toList();

      if (overlaysToDisplayInt.contains(currentStep)) {
        _overlays.add(
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: Image.network('${widget.promos[0].promoImage}_$currentStep${widget.promos[0].promoImageExtension}'),
            ),
          ),
        );
      }
    }

    return Stack(
      alignment: AlignmentDirectional.topStart,
      children: <Widget>[
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: Backgrounds.defaultHcBackground(),
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: _promoImage ?? widget.firstPromoImage,
          ),
        ),
        if (_overlays.isNotEmpty) ..._overlays,
        if (!_showPromoScreenTools) ...<Widget>[
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                color: Colors.white60,
                child: Text(
                  _initializationMessage.isEmpty ? 'Loading data...' : _initializationMessage,
                  style: titleStyle.copyWith(color: const Color.fromARGB(255, 0, 2, 65)),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
        if (_showPromoScreenTools) ...<Widget>[
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: <Widget>[
                  ColorFiltered(
                    // colorFilter: const ColorFilter.mode(
                    //   Colors.transparent,
                    //   BlendMode.difference,
                    // ),
                    colorFilter: widget.promos[0].promoImageIsDark == 0
                        ? const ColorFilter.matrix(<double>[
                            1, 0, 0, 0, 0, //
                            0, 1, 0, 0, 0, //
                            0, 0, 1, 0, 0, //
                            0, 0, 0, 1, 0, //
                          ])
                        : const ColorFilter.matrix(<double>[
                            -1, 0, 0, 0, 255, //
                            0, -1, 0, 0, 255, //
                            0, 0, -1, 0, 255, //
                            0, 0, 0, 1, 0, //
                          ]),
                    child: Column(
                      children: <Widget>[
                        if (widget.promos[0].promoExternalUrl != null && widget.promos[0].promoExternalUrlButtonText != null && Utilities.isValidUrl(widget.promos[0].promoExternalUrl)) ...<Widget>[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 15.0),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(width: 2.0, color: Colors.black),
                                foregroundColor: Colors.black,
                                backgroundColor: Colors.white38,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(100))),
                              ),
                              onPressed: () async {
                                if (Utilities.isValidUrl(widget.promos[0].promoExternalUrl)) {
                                  await launchUrl(Uri.parse(widget.promos[0].promoExternalUrl!), mode: LaunchMode.externalApplication);
                                } else {
                                  await IveCoreUtilities.showAlert(
                                      navigatorKey.currentContext!, 'Unable to open link', 'Harrier Central was unable to open ${widget.promos[0].promoExternalUrl}', 'OK');
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                                child: Text(widget.promos[0].promoExternalUrlButtonText!, style: const TextStyle(fontSize: 20.0)),
                              ),
                            ),
                          ),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            GestureDetector(
                              onTap: () {
                                if (_promoTimer != null) {
                                  if (_promoTimer!.isPaused) {
                                    _promoTimer!.start();
                                  } else {
                                    _promoTimer!.pause();
                                  }
                                  setState(() {});
                                }
                              },
                              child: (_promoTimer?.isPaused ?? false)
                                  ? Image.asset(
                                      'images/icons/promo_play_icon.png',
                                      width: 40.0,
                                      height: 40.0,
                                    )
                                  : Image.asset(
                                      'images/icons/promo_pause_icon.png',
                                      width: 40.0,
                                      height: 40.0,
                                    ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                final SnoozePromotionService svc = SnoozePromotionService();
                                await svc.snoozePromotion(widget.promos[0].promotionId, true);
                                if (_promoTimer != null) {
                                  _promoTimer!.cancel();
                                  _promoTimer = null;
                                  _showMainScreen = true;
                                  setState(() {});
                                }
                              },
                              child: Image.asset(
                                'images/icons/promo_trash_icon.png',
                                width: 40,
                                height: 40,
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                final SnoozePromotionService svc = SnoozePromotionService();
                                await svc.snoozePromotion(widget.promos[0].promotionId, false);
                                if (_promoTimer != null) {
                                  _promoTimer!.cancel();
                                  _promoTimer = null;
                                  _showMainScreen = true;
                                  setState(() {});
                                }
                              },
                              child: Image.asset(
                                'images/icons/promo_snooze_icon.png',
                                width: 40,
                                height: 40,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (_promoTimer != null) {
                                  _promoTimer!.cancel();
                                  _promoTimer = null;
                                  _showMainScreen = true;
                                  setState(() {});
                                }
                              },
                              child: Image.asset(
                                'images/icons/promo_x_icon.png',
                                width: 40,
                                height: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Padding(
                    //color: Colors.yellow,
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: StepProgressIndicator(
                      totalSteps: _steps,
                      currentStep: _timeRemaining == null ? 0 : _steps - ((_timeRemaining ?? 0) ~/ (widget.promos[0].promoDisplayTimeInMs / _steps)),
                      //size: 10.0,
                      padding: 0.0,
                      // selectedSize: widget.promos[0].promoDisplayTimingDotsSize + 0.0,
                      // unselectedSize: widget.promos[0].promoDisplayTimingDotsSize + 0.0,
                      customSize: (int index, bool selected) {
                        return widget.promos[0].promoDisplayTimingDotsSize + 0.0;
                      },
                      selectedColor: widget.promos[0].promoImageIsDark == 0 ? Colors.black : Colors.white,
                      unselectedColor: widget.promos[0].promoImageIsDark == 0 ? Colors.black26 : Colors.white30,
                      customStep: (int index, Color color, _) => Container(
                        color: Colors.transparent,
                        height: 10.0,
                        child: widget.promos[0].promoDisplayTimingDotsShape == 'circle'
                            ? Icon(
                                FontAwesome.circle,
                                color: color,
                                size: widget.promos[0].promoDisplayTimingDotsSize + 0.0,
                              )
                            : widget.promos[0].promoDisplayTimingDotsShape == 'square'
                                ? Icon(
                                    FontAwesome.square,
                                    color: color,
                                    size: widget.promos[0].promoDisplayTimingDotsSize + 0.0,
                                  )
                                : ImageIcon(
                                    AssetImage(widget.promos[0].promoDisplayTimingDotsShape == 'chevron long'
                                        ? 'images/icons/chevron_long.png'
                                        : widget.promos[0].promoDisplayTimingDotsShape == 'chevron medium'
                                            ? 'images/icons/chevron_medium.png'
                                            : 'images/icons/chevron_short.png'),
                                    color: color,
                                    size: widget.promos[0].promoDisplayTimingDotsSize + 0.0,
                                  ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
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
