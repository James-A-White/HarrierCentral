import 'package:harrier_central/imports.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';

enum MainPageContent { initial, loading, splashSequence, appContent, help }

class MainNavigationController extends GetxController
    with WidgetsBindingObserver {
  MainNavigationController();

  // Tab titles
  static const List<String> tabTitles = <String>[
    'Hash Runs',
    'Kennels',
    'Hash Run Map',
    'Run Counts',
    'Songs',
  ];

  final List<List<String>> tutorials = <List<String>>[
    _tutorialUpcomingRuns,
    _tutorialKennelsView,
    _tutorialRunLocations,
    _tutorialRunCounts,
    _tutorialSongs,
  ];

  // ignore: prefer_final_fields
  static List<String> _tutorialSongs = <String>[];

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
  final mainScreenContent = MainPageContent.initial.obs;
  final showPromoTools = false.obs;
  final steps = 10.obs;
  final timeRemaining = RxnInt();
  final currentPage = 0.obs;
  final GlobalKey<CurvedNavigationBarState> bottomNavigationKey = GlobalKey();

  final GlobalKey<ScaffoldState> ScaffoldKey = GlobalKey();

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
  Widget songsPage = Container();

  // Screen unlock listener
  Screen? _screen;
  StreamSubscription<ScreenStateEvent>? _screenWatcherSub;

  @override
  void onInit() {
    super.onInit();
    unawaited(onInitAsync());
    WidgetsBinding.instance.addObserver(this);
  }

  var hcCurrentVersion = '';
  var hcPreviousVersion = '';

  Image? splashBackground;
  var splashImages = <Image>[];
  var isLoadingImages = false.obs;
  var isLoadingData = true;

  var reportSplashSequenceViewed = false;

  Future<void> onInitAsync() async {
    final stopwatch = Stopwatch()..start();

    if (Utilities.isConnected()) {
      hcCurrentVersion = _trimToMinorVersionString(
        getStringPref(StringPrefsEnum.harrierCentralVersion) ?? '',
      );
      hcPreviousVersion = _trimToMinorVersionString(
        getStringPref(StringPrefsEnum.harrierCentralPreviousVersion) ?? '',
      );

      String? splashSequenceRootName = getStringPref(
        StringPrefsEnum.splashSequenceRootName,
      );

      var splashType = SplashSequenceType.fromId(
        getIntPref(IntPrefsEnum.splashSequenceType) ??
            SplashSequenceType.unknown.id,
      );

      // always display version change splash sequences if they exist on the server
      if (hcCurrentVersion != hcPreviousVersion) {
        if (await _preloadImages('version_$hcCurrentVersion') == 0) {
          // don't show any splah images if none have been loaded
          mainScreenContent.value = MainPageContent.loading;
        } else {
          mainScreenContent.value = MainPageContent.splashSequence;
        }
      } else if (splashSequenceRootName != null) {
        var timeSinceLastView = DateTime.now().difference(
          getDatePref(DatePrefsEnum.lastSplashSequenceDisplayed) ??
              DateTime(2000),
        );

        // only show a splash screen if enough time has elapsed
        // since the last time a splash screen was displayed
        if (timeSinceLastView.inHours > splashType.delayInHours) {
          if (await _preloadImages(splashSequenceRootName) == 0) {
            // don't show any splah images if none have been loaded
            mainScreenContent.value = MainPageContent.appContent;
          } else {
            mainScreenContent.value = MainPageContent.splashSequence;
          }
          await removePref(StringPrefsEnum.splashSequenceRootName);
          await setStringPref(
            StringPrefsEnum.splashSequenceRootNameViewed,
            splashSequenceRootName,
          );
          await setDatePref(
            DatePrefsEnum.splashSequenceViewedAt,
            DateTime.now(),
          );
          await setDatePref(
            DatePrefsEnum.lastSplashSequenceDisplayed,
            DateTime.now(),
          );
        } else {
          mainScreenContent.value = MainPageContent.loading;
          // getStringPref(StringPrefsEnum.bootType) != BOOT_TYPE_NORMAL
          //     ? mainScreenContent.value = MainPageContent.loading
          //     : mainScreenContent.value = MainPageContent.appContent;
        }
      } else {
        mainScreenContent.value = MainPageContent.loading;
        // getStringPref(StringPrefsEnum.bootType) != BOOT_TYPE_NORMAL
        //     ? mainScreenContent.value = MainPageContent.loading
        //     : mainScreenContent.value = MainPageContent.appContent;
      }
    } else {
      mainScreenContent.value = MainPageContent.appContent;
    }

    appBarText.value = tabTitles[0];

    // Force DB instantiation
    Tables.migrationList.sort((a, b) => a.dbVersion.compareTo(b.dbVersion));
    assert(DB_VERSION == Tables.migrationList.last.dbVersion);

    // Setup database
    await setupDatabase(informUser, 'PRO_APP');

    // Create pages
    futureRunsListPage = FutureRunsListPage();

    mainScreenReady.value = true;

    update(['AppScaffold']);

    kennelsListPage = KennelsListPage(key: kennelLocationsPageKey);
    historyListPage = HistoryListPage();
    runAndKennelMapPage = RunAndKennelMapPage(key: runAndKennelMapPageKey);
    songsPage = SongsPage();

    isLoadingData = false;

    final hasLoc = await _checkLocationPermissions();
    if (hasLoc) {
      await _checkAreWeAtRunStart();
    }
    _startScreenListening();

    // Calculate remaining time to reach 1500ms
    final remaining = 1500 - stopwatch.elapsedMilliseconds;
    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }

    if (mainScreenContent.value != MainPageContent.splashSequence) {
      mainScreenContent.value = MainPageContent.appContent;
    }

    update(['AppScaffold']);

    // don't configure notifications until here because
    // when a notification is clicked and the app launches,
    // we need to have the MainNavigationController initialized
    bool? notificationsConfigured = getBoolPref(
      BoolPrefsEnum.notificationPreferencesRequested,
    );

    if (notificationsConfigured != null && notificationsConfigured) {
      await Get.putAsync(
        () => NotificationService().init(),
      ); // Initialize and wait for the notification service
    }
  }

  String _trimToMinorVersionString(String version) {
    final parts = version.split('.');
    if (parts.length >= 2) {
      return '${parts[0]}.${parts[1]}';
    }
    // fallback if it doesn’t have two dots
    return version;
  }

  Future<int> _preloadImages(String splashSequenceRootName) async {
    isLoadingImages.value = true;
    int maxImages = 20;
    for (var i = 0; i <= maxImages; i++) {
      var url = '$BASE_NEW_VERSION_IMAGES_URL${splashSequenceRootName}_$i.avif';

      if (i == 0) {
        url =
            '$BASE_NEW_VERSION_IMAGES_URL${splashSequenceRootName}_background.avif';
      }

      final provider = NetworkAvifImage(url);
      final config = const ImageConfiguration(); // no context needed
      final stream = provider.resolve(config);

      final completer = Completer<void>();
      late final ImageStreamListener listener;

      listener = ImageStreamListener(
        (info, _) {
          // success: add the widget
          if (i == 0) {
            splashBackground = Image(image: provider);
          } else {
            splashImages.add(Image(image: provider));
          }

          completer.complete();
        },
        onError: (error, stack) {
          // stop on first failure (e.g. 404)
          if (i != 0) {
            completer.completeError(error);
          } else {
            completer.complete();
          }
        },
      );

      stream.addListener(listener);

      try {
        await completer.future;
      } catch (_) {
        // stop loading further images
        if (i != 0) {
          stream.removeListener(listener);
          break;
        }
      }

      // clean up the listener after success
      stream.removeListener(listener);
    }

    isLoadingImages.value = false;
    return splashImages.length;
  }

  void informUser(String message) {
    initializationMessage.value = message;
  }

  void toggleFlip() {
    isFlipped.value = !isFlipped.value;
  }

  Future<void> onTabChanged(int index) async {
    currentPage.value = index;
    appBarText.value = tabTitles[index];
    // Refresh runs on first tab
    if (index == 0) {
      if (Get.isRegistered<FutureRunListPageController>()) {
        final ctrl = Get.find<FutureRunListPageController>();
        await ctrl.refreshFromTable(true);
      }
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

  // Widget? get currentFab {
  //   if (!isFlipped.value) {
  //     if (currentPage.value == 2) {
  //       return runAndKennelMapPageKey.currentState?.getMapFab();
  //     }
  //     if (currentPage.value == 1) {
  //       return kennelLocationsPageKey.currentState?.getKennelFab();
  //     }
  //   }
  //   return null;
  // }

  Future<bool> _checkLocationPermissions() async {
    appModel.hasLocationPermissions = await Permission.location.isGranted;
    return appModel.hasLocationPermissions;
  }

  Future<void> resetNewVersionPromoScreen() async {
    await setStringPref(
      StringPrefsEnum.harrierCentralPreviousVersion,
      getStringPref(StringPrefsEnum.harrierCentralVersion) ?? '',
    );

    // if (isLoadingData ||
    //     getStringPref(StringPrefsEnum.bootType) != BOOT_TYPE_NORMAL) {
    //   mainScreenContent.value = MainPageContent.loading;
    // } else {
    //   mainScreenContent.value = MainPageContent.appContent;
    // }

    if (isLoadingData) {
      mainScreenContent.value = MainPageContent.loading;
    } else {
      mainScreenContent.value = MainPageContent.appContent;
    }

    // make sure app bar is drawn
    update(['AppScaffold']);

    // it's OK to not await this async call
    await requestNotificationPermission();
  }

  Future<void> requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // NotificationSettings settings = await messaging.requestPermission(
    //   alert: true,
    //   badge: true,
    //   sound: true,
    // );

    // if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    //   print('User granted permission');
    // } else {
    //   print('User declined or has not accepted permission');
    // }
  }

  void _startScreenListening() {
    _screen = Screen();
    try {
      _screenWatcherSub = _screen?.screenStateStream.listen((event) async {
        if (event == ScreenStateEvent.SCREEN_UNLOCKED) {
          if (appModel.hasLocationPermissions) await _checkAreWeAtRunStart();
        }
      });
    } catch (_) {}
  }

  Future<void> _checkAreWeAtRunStart() async {
    await Utilities.isAtRunStart();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_screenWatcherSub?.cancel());
    super.onClose();
  }
}
