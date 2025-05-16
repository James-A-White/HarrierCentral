import 'package:get/get.dart';
import 'package:harrier_central/imports.dart';
import 'package:harrier_central/pages/top_level/select_run_page.dart';

enum MainPageContent { loading, newVersion, promo, appContent, help }

class MainNavigationController extends GetxController
    with WidgetsBindingObserver {
  MainNavigationController({required this.promos, this.firstPromoImage});

  final List<PromoModel> promos;
  final Image? firstPromoImage;

  // Tab titles
  static const List<String> tabTitles = <String>[
    'Upcoming Runs',
    'Kennels',
    'Explore Runs',
    'Run Counts',
  ];

  final List<List<String>> tutorials = <List<String>>[
    _tutorialUpcomingRuns,
    _tutorialKennelsView,
    _tutorialRunLocations,
    _tutorialRunCounts,
  ];

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

  // Reactive state
  final appBarText = tabTitles[0].obs;
  final initializationMessage = ''.obs;
  final isFlipped = false.obs;
  final mainScreenReady = false.obs;
  final mainScreenContent = MainPageContent.loading.obs;
  final showPromoTools = false.obs;
  final steps = 10.obs;
  final timeRemaining = RxnInt();
  final currentPage = 0.obs;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();

  // Notifications state (moved from AppBar badge)
  final totalNotifications = 0.obs;
  final showChatBubbleLoading = false.obs;

  // Page keys
  final runAndKennelMapPageKey = GlobalKey<RunAndKennelMapPageState>();
  final kennelLocationsPageKey = GlobalKey<KennelsListPageState>();

  // Pages
  Widget futureRunsListPage = Container();
  Widget kennelsListPage = Container();
  Widget historyListPage = Container();
  Widget runAndKennelMapPage = Container();

  // Promo timer
  PausableTimer? _promoTimer;
  Duration promoDisplayDuration = const Duration(seconds: 3);

  // Screen unlock listener
  Screen? _screen;
  StreamSubscription<ScreenStateEvent>? _screenWatcherSub;

  @override
  void onInit() {
    super.onInit();
    initialize();
    WidgetsBinding.instance.addObserver(this);
  }

  var hcCurrentVersion = '';
  var hcPreviousVersion = '';

  var newVersionImages = <Image>[];
  var isLoadingImages = false.obs;

  Future<void> initialize() async {
    // Status bar color
    FlutterStatusbarcolor.setStatusBarColor(themeStatusBarBackground).then((_) {
      FlutterStatusbarcolor.setStatusBarWhiteForeground(true);
    });

    hcCurrentVersion = _trimToMinorVersionString(
      getStringPref(StringPrefsEnum.harrierCentralVersion) ?? '',
    );
    hcPreviousVersion = _trimToMinorVersionString(
      getStringPref(StringPrefsEnum.harrierCentralPreviousVersion) ?? '',
    );

    if (hcCurrentVersion != hcPreviousVersion) {
      await _preloadImages();
    }

    appBarText.value = tabTitles[0];

    // Force DB instantiation
    Tables.migrationList.sort((a, b) => a.dbVersion.compareTo(b.dbVersion));
    assert(DB_VERSION == Tables.migrationList.last.dbVersion);

    // Setup database
    await setupDatabase(informUser, 'PRO_APP');

    // Create pages
    futureRunsListPage = FutureRunsListPage();
    kennelsListPage = KennelsListPage(key: kennelLocationsPageKey);
    historyListPage = HistoryListPage();
    runAndKennelMapPage = RunAndKennelMapPage(key: runAndKennelMapPageKey);

    final hasLoc = await _checkLocationPermissions();
    if (hasLoc) _checkAreWeAtRunStart();
    _startScreenListening();

    if (hcCurrentVersion != hcPreviousVersion) {
      mainScreenContent.value = MainPageContent.newVersion;
    } else if (promos.isNotEmpty) {
      mainScreenContent.value = MainPageContent.promo;
      showPromoTools.value = true;
      final first = promos.first;
      timeRemaining.value = first.promoDisplayTimeInMs;
      steps.value = first.promoDisplayTimingDotsToDisplay;
      promoDisplayDuration = Duration(
        milliseconds: first.promoDisplayTimeInMs ~/ steps.value,
      );
      _startPromoTimer(first);
    } else {
      mainScreenContent.value = MainPageContent.appContent;
    }

    update(['scaffold']);

    mainScreenReady.value = true;
  }

  String _trimToMinorVersionString(String version) {
    final parts = version.split('.');
    if (parts.length >= 2) {
      return '${parts[0]}.${parts[1]}';
    }
    // fallback if it doesn’t have two dots
    return version;
  }

  void _startPromoTimer(PromoModel promo) {
    _promoTimer = PausableTimer(promoDisplayDuration, () {
      timeRemaining.value =
          timeRemaining.value! - (promo.promoDisplayTimeInMs ~/ steps.value);
      if (timeRemaining.value! < 0) {
        _promoTimer?.cancel();
        mainScreenContent.value = MainPageContent.appContent;
      } else {
        _promoTimer
          ?..reset()
          ..start();
      }
    })..start();
  }

  Future<void> _preloadImages() async {
    isLoadingImages.value = true;
    int maxImages = 20;
    for (var i = 1; i <= maxImages; i++) {
      final url =
          '${BASE_NEW_VERSION_IMAGES_URL}version_${hcCurrentVersion}_$i.avif';
      final provider = NetworkImage(url);
      final config = const ImageConfiguration(); // no context needed
      final stream = provider.resolve(config);

      final completer = Completer<void>();
      late final ImageStreamListener listener;

      listener = ImageStreamListener(
        (info, _) {
          // success: add the widget
          newVersionImages.add(Image(image: provider));
          completer.complete();
        },
        onError: (error, stack) {
          // stop on first failure (e.g. 404)
          completer.completeError(error);
        },
      );

      stream.addListener(listener);

      try {
        await completer.future;
      } catch (_) {
        // stop loading further images
        stream.removeListener(listener);
        break;
      }

      // clean up the listener after success
      stream.removeListener(listener);
    }

    isLoadingImages.value = false;
  }

  void informUser(String message) {
    initializationMessage.value = message;
  }

  void toggleFlip() {
    isFlipped.value = !isFlipped.value;
  }

  void onTabChanged(int index) {
    currentPage.value = index;
    appBarText.value = tabTitles[index];
    // Refresh runs on first tab
    if (index == 0) {
      final ctrl = Get.find<FutureRunListPageController>();
      ctrl.refreshFromTable(true);
    }
    // Delay setState for map FAB
    if (!isFlipped.value && index == 2) {
      Future.delayed(const Duration(milliseconds: 250), () {});
    }
  }

  // Widget get currentPageWidget {
  //   switch (currentPage.value) {
  //     case 0:
  //       return futureRunsListPage;
  //     case 1:
  //       return kennelsListPage;
  //     case 2:
  //       return runAndKennelMapPage;
  //     case 3:
  //       return historyListPage;
  //     default:
  //       return futureRunsListPage;
  //   }
  // }

  Widget? get currentFab {
    if (!isFlipped.value) {
      if (currentPage.value == 2) {
        return runAndKennelMapPageKey.currentState?.getMapFab();
      }
      if (currentPage.value == 1) {
        return kennelLocationsPageKey.currentState?.getKennelFab();
      }
    }
    return null;
  }

  Future<bool> _checkLocationPermissions() async {
    G0<AppModel>().hasLocationPermissions = await Permission.location.isGranted;
    return G0<AppModel>().hasLocationPermissions;
  }

  void resetNewVersionPromoScreen() {
    setStringPref(
      StringPrefsEnum.harrierCentralPreviousVersion,
      getStringPref(StringPrefsEnum.harrierCentralVersion) ?? '',
    );

    mainScreenContent.value = MainPageContent.appContent;
    // make sure app bar is drawn
    update(['scaffold']);
  }

  void _startScreenListening() {
    _screen = Screen();
    try {
      _screenWatcherSub = _screen?.screenStateStream.listen((event) {
        if (event == ScreenStateEvent.SCREEN_UNLOCKED) {
          if (G0<AppModel>().hasLocationPermissions) _checkAreWeAtRunStart();
        }
      });
    } catch (_) {}
  }

  Future<void> _checkInAtEvent(String eventId, String userId) async {
    await G0<TableModel>().hasherEventMapService.setEventAttendence(
      eventId,
      userId,
      AppDomainType.user,
      attendenceAtHash.value,
    );

    // if (futureRunsListPageKey.currentState != null) {
    //   await futureRunsListPageKey.currentState!.forceRefreshFromTableExternal();
    // }
  }

  Future<void> _checkAreWeAtRunStart() async {
    //final Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.lowest);

    var lastRunStartCheck = getDatePref(DatePrefsEnum.lastRunStartCheck);
    if (lastRunStartCheck == null) {
      await setDatePref(DatePrefsEnum.lastRunStartCheck, DateTime(2000));
      lastRunStartCheck = DateTime(2000);
    }

    if (DateTime.now().difference(lastRunStartCheck).inMinutes < 2) {
      return;
    }

    await setDatePref(DatePrefsEnum.lastRunStartCheck, DateTime.now());

    final List<AreWeAtRunModel> resultList =
        await CommonQueries.areWeAtRunStart();
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

        final EnumCheckinOptions<int>? retVal =
            await showDialog<EnumCheckinOptions<int>>(
              context: navigatorKey.currentContext!,
              barrierDismissible: false, // user must tap button!
              builder: (BuildContext context) {
                return popup;
              },
            );

        if (retVal == enumCheckInOption_Yes) {
          await _checkInAtEvent(result.eventId, userId);
          final controller = Get.find<FutureRunListPageController>();
          await controller.refreshFromTable(true);
        } else if ((retVal == enumCheckInOption_YesAndPayByCredit) ||
            (retVal == enumCheckInOption_YesAndPayByBankXfer)) {
          final PaymentsService paySrv = PaymentsService();
          await paySrv.payForEvent(
            result.eventId,
            userId,
            GUID_EMPTY,
            retVal == enumCheckInOption_YesAndPayByCredit
                ? paymentHashCredit.value
                : paymentBankTransfer.value,
            result.membershipExpirationDate.isAfter(DateTime.now())
                ? result.memberPrice
                : result.nonMemberPrice,
            attendenceAtHash.value,
            payForRunOnly,
            AppDomainType.user,
          );
        } else if ((retVal == enumCheckInOption_YesAndPayPlusExtrasByCredit) ||
            (retVal == enumCheckInOption_YesAndPayPlusExtrasByBankXfer)) {
          final PaymentsService paySrv = PaymentsService();
          await paySrv.payForEvent(
            result.eventId,
            userId,
            GUID_EMPTY,
            retVal == enumCheckInOption_YesAndPayPlusExtrasByCredit
                ? paymentHashCredit.value
                : paymentBankTransfer.value,
            result.extrasCost +
                (result.membershipExpirationDate.isAfter(DateTime.now())
                    ? result.memberPrice
                    : result.nonMemberPrice),
            attendenceAtHash.value,
            payForRunAndExtras,
            AppDomainType.user,
          );
        }
      }
    } else if (resultList.length > 1) {
      // look through the list of runs and determine if this hasher is
      // at any of the runs on the list. If so, don't show the
      // selection view
      bool showRunList = true;
      final Map<String, bool> selectedRuns = <String, bool>{};

      for (AreWeAtRunModel result in resultList) {
        selectedRuns[result.eventId] =
            false; //prepare the selection result list
        if (result.attendenceState >= attendenceAtHash.value) {
          showRunList = false;
          break;
        }
      }

      if (showRunList) {
        // if (!mounted) return;
        // final dynamic doCheckIn = await Navigator.push<dynamic>(
        //   context,
        //   MaterialPageRoute<dynamic>(
        //     builder:
        //         (BuildContext context) =>
        //             SelectRunPage(runList: resultList, selected: selectedRuns),
        //   ),
        // );

        var doCheckIn =
            await Get.to<bool?>(
              SelectRunPage(runList: resultList, selected: selectedRuns),
            ) ??
            false;

        if (doCheckIn) {
          for (AreWeAtRunModel result in resultList) {
            if ((selectedRuns.containsKey(result.eventId)) &&
                (selectedRuns[result.eventId] == true)) {
              await _checkInAtEvent(result.eventId, userId);
            }
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _screenWatcherSub?.cancel();
    super.dispose();
  }
}
