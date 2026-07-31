import 'package:harrier_central/imports.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';

enum MainPageContent { initial, loading, splashSequence, appContent }

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

  // Reactive state
  final appBarText = tabTitles[0].obs;
  final initializationMessage = ''.obs;
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
  final runAndKennelMapPageKey = GlobalKey();
  final kennelLocationsPageKey = GlobalKey();

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
    try {
      await _onInitAsyncBody();
    } catch (e, stack) {
      // Last-resort safety net: any unhandled exception in the boot sequence
      // must not permanently hang the loading screen (this future is called
      // with unawaited(), so uncaught exceptions are silently discarded by the
      // Dart runtime and mainScreenContent never reaches appContent).
      if (kDebugMode) {
        debugPrint('onInitAsync unhandled error: $e');
        debugPrint(stack.toString());
      }
      mainScreenReady.value = true;
      mainScreenContent.value = MainPageContent.appContent;
      isLoadingData = false;
      update([UpdateIds.appScaffold]);
    }
  }

  Future<void> _onInitAsyncBody() async {
    final stopwatch = Stopwatch()..start();
    debugPrint('[BOOT] MainNavController: _onInitAsyncBody start: ${DateTime.now().millisecondsSinceEpoch}ms');

    appBarText.value = tabTitles[0];

    // Guard: DB_VERSION must have a matching entry at the end of migrationList.
    // A mismatch means a developer bumped DB_VERSION without adding a migration.
    Tables.migrationList.sort((a, b) => a.dbVersion.compareTo(b.dbVersion));
    final int lastMigration = Tables.migrationList.last.dbVersion;
    if (DB_VERSION != lastMigration) {
      await Utilities.showAlert(
        'Database Version Mismatch',
        'DB_VERSION is $DB_VERSION but the last migration record is $lastMigration.\n\n'
        'A migration record must be added to Tables.migrationList for every '
        'DB_VERSION change. The app cannot start until this is fixed.',
        'OK',
      );
      assert(DB_VERSION == lastMigration, 'DB_VERSION ($DB_VERSION) != last migration ($lastMigration) — add a MigrationsModel entry to Tables.migrationList.');
      return;
    }

    // Open the local DB and find out whether we already have cached runs BEFORE
    // deciding what to show. This is what lets returning users skip the
    // "Filling Your Mug" screen entirely — instead of showing it and then hiding
    // it once we discover there is cached data. "Cached data" = the local runs
    // table already has rows we can paint. We check the actual table (not a pref)
    // so this stays correct across the logout/reset paths that delete the DB
    // without erasing prefs — a freshly-created/empty DB yields a count of 0 and
    // still blocks on the first sync (which runs with a real progress callback).
    debugPrint('[BOOT] MainNavController: openAppDatabase start: ${DateTime.now().millisecondsSinceEpoch}ms');
    await openAppDatabase(informUser, 'PRO_APP');
    final int cachedEventCount =
        await CommonQueries.countRecords(EnumDataTables.events.commonTableName);
    final bool hasCachedData = cachedEventCount > 0;
    debugPrint('[BOOT] MainNavController: openAppDatabase done, cachedEventCount=$cachedEventCount, hasCachedData=$hasCachedData: ${DateTime.now().millisecondsSinceEpoch}ms');

    // Choose what fills the screen until appContent is ready. Returning users get
    // the blank app background (MainPageContent.initial, the default) — never the
    // loading screen. First launch still shows "Filling Your Mug" during the
    // blocking sync below. Version/promo splash sequences always show regardless.
    final MainPageContent waitingContent =
        hasCachedData ? MainPageContent.initial : MainPageContent.loading;
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
        debugPrint('[BOOT] MainNavController: version changed $hcPreviousVersion→$hcCurrentVersion, preloading images: ${DateTime.now().millisecondsSinceEpoch}ms');
        final imgCount = await _preloadImages('version_$hcCurrentVersion');
        debugPrint('[BOOT] MainNavController: preloadImages done, imgCount=$imgCount: ${DateTime.now().millisecondsSinceEpoch}ms');
        if (imgCount == 0) {
          // don't show any splah images if none have been loaded
          mainScreenContent.value = waitingContent;
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
          debugPrint('[BOOT] MainNavController: splashSequence preloading ($splashSequenceRootName): ${DateTime.now().millisecondsSinceEpoch}ms');
          final imgCount = await _preloadImages(splashSequenceRootName);
          debugPrint('[BOOT] MainNavController: preloadImages done, imgCount=$imgCount: ${DateTime.now().millisecondsSinceEpoch}ms');
          if (imgCount == 0) {
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
          mainScreenContent.value = waitingContent;
        }
      } else {
        mainScreenContent.value = waitingContent;
      }
    } else {
      mainScreenContent.value = MainPageContent.appContent;
    }
    debugPrint('[BOOT] MainNavController: mainScreenContent=${mainScreenContent.value.name}: ${DateTime.now().millisecondsSinceEpoch}ms');

    // First launch (no cached data): block on the full sync while "Filling Your
    // Mug" shows. Returning users skip this — they sync in the background below.
    if (!hasCachedData) {
      debugPrint('[BOOT] MainNavController: first launch — blocking full sync start: ${DateTime.now().millisecondsSinceEpoch}ms');
      await syncAllUserDataFromBackend(informUser: informUser);
      debugPrint('[BOOT] MainNavController: first-launch full sync done: ${DateTime.now().millisecondsSinceEpoch}ms');
    }

    // Drain any photos that were taken while offline.
    unawaited(KennelPhotoService().processPendingQueue());

    // Create all pages up front — these are cheap synchronous constructors, and
    // the IndexedStack needs every child present before we flip to appContent.
    debugPrint('[BOOT] MainNavController: creating pages: ${DateTime.now().millisecondsSinceEpoch}ms');
    futureRunsListPage = FutureRunsListPage();
    kennelsListPage = KennelsListPage(key: kennelLocationsPageKey);
    historyListPage = HistoryListPage();
    runAndKennelMapPage = RunAndKennelMapPage(key: runAndKennelMapPageKey);
    songsPage = SongsPage();
    mainScreenReady.value = true;
    isLoadingData = false;
    debugPrint('[BOOT] MainNavController: all pages created, mainScreenReady=true: ${DateTime.now().millisecondsSinceEpoch}ms');

    // The minimum-splash gate only applies when we actually blocked on a sync
    // (first launch). Returning users skip it so the runs page appears at once.
    if (!hasCachedData) {
      final elapsed = stopwatch.elapsedMilliseconds;
      final remaining = 1500 - elapsed;
      debugPrint('[BOOT] MainNavController: elapsed=${elapsed}ms, waiting ${remaining > 0 ? remaining : 0}ms to 1500ms gate: ${DateTime.now().millisecondsSinceEpoch}ms');
      if (remaining > 0) {
        await Future.delayed(Duration(milliseconds: remaining));
      }
      debugPrint('[BOOT] MainNavController: 1500ms gate passed: ${DateTime.now().millisecondsSinceEpoch}ms');
    }

    // Reveal the app as early as possible. For returning users nothing slow runs
    // before this point (no blocking sync, no 1500ms gate, no permission
    // round-trip), so the "Filling Your Mug" screen never gets a visible frame.
    if (mainScreenContent.value != MainPageContent.splashSequence) {
      mainScreenContent.value = MainPageContent.appContent;
    }
    update([UpdateIds.appScaffold]);
    debugPrint('[BOOT] MainNavController: appContent shown: ${DateTime.now().millisecondsSinceEpoch}ms');

    // --- everything below runs with the runs page already on screen ---

    // Location permission is a platform round-trip with variable latency, so we
    // check it AFTER the app is visible. Doing it before the flip is what let the
    // loading screen paint a frame on slower launches (the occasional flash).
    final hasLoc = await _checkLocationPermissions();
    debugPrint('[BOOT] MainNavController: hasLoc=$hasLoc: ${DateTime.now().millisecondsSinceEpoch}ms');
    _startScreenListening();

    // Returning users: the runs page is now visible with cached data. Run the
    // full user-data sync in the background and refresh the runs list when the
    // fresh data lands.
    if (hasCachedData) {
      unawaited(_runBackgroundFullSyncAndRefresh());
    }

    // Fire after app content is visible so the GPS wait loop (and any dialog)
    // never blocks the loading screen from clearing.
    if (hasLoc) {
      debugPrint('[BOOT] MainNavController: firing _checkAreWeAtRunStart (unawaited): ${DateTime.now().millisecondsSinceEpoch}ms');
      unawaited(_checkAreWeAtRunStart());
    }

    // don't configure notifications until here because
    // when a notification is clicked and the app launches,
    // we need to have the MainNavigationController initialized
    bool? notificationsConfigured = getBoolPref(
      BoolPrefsEnum.notificationPreferencesRequested,
    );
    debugPrint('[BOOT] MainNavController: notificationsConfigured=$notificationsConfigured: ${DateTime.now().millisecondsSinceEpoch}ms');

    // Only register NotificationService here if services_init.dart didn't already
    // do it at boot. Since Firebase is now initialised in main() before initServices(),
    // services_init registers it reliably and this path is the fallback for the
    // first-ever launch where notificationsConfigured was false at boot time.
    if ((notificationsConfigured ?? false) &&
        !Get.isRegistered<NotificationService>()) {
      debugPrint('[BOOT] MainNavController: NotificationService.init start: ${DateTime.now().millisecondsSinceEpoch}ms');
      await Get.putAsync(
        () => NotificationService().init(),
      );
      debugPrint('[BOOT] MainNavController: NotificationService.init done: ${DateTime.now().millisecondsSinceEpoch}ms');
    }
    debugPrint('[BOOT] MainNavController: _onInitAsyncBody COMPLETE: ${DateTime.now().millisecondsSinceEpoch}ms');
  }

  /// Returning-user boot path: runs the full user-data sync in the background
  /// (after the runs page is already visible with cached data), then repaints
  /// the runs list with the fresh results. Failures are swallowed so the app
  /// stays usable on whatever data is cached.
  Future<void> _runBackgroundFullSyncAndRefresh() async {
    debugPrint('[BOOT] MainNavController: background full sync start: ${DateTime.now().millisecondsSinceEpoch}ms');
    try {
      await syncAllUserDataFromBackend();
    } catch (e, stack) {
      debugPrint('[BOOT] MainNavController: background full sync error: $e');
      debugPrint(stack.toString());
    }
    debugPrint('[BOOT] MainNavController: background full sync done: ${DateTime.now().millisecondsSinceEpoch}ms');

    if (Get.isRegistered<FutureRunListPageController>()) {
      await Get.find<FutureRunListPageController>().reloadAndFlash();
      debugPrint('[BOOT] MainNavController: runs list reloaded (with flash) after background sync: ${DateTime.now().millisecondsSinceEpoch}ms');
    }

    // The runs tab was refreshed explicitly above (with the flash animation).
    // The other four tabs (Kennels, Map, Songs, History) did their one-time load
    // at boot against the *old* cached rows, so signal them to re-read now that
    // fresh data has landed in the common tables.
    if (Get.isRegistered<DataChangeService>()) {
      Get.find<DataChangeService>().notify(
        const DataChangeEvent(type: DataChangeType.fullSyncCompleted),
      );
      debugPrint('[BOOT] MainNavController: fullSyncCompleted broadcast to remaining tabs: ${DateTime.now().millisecondsSinceEpoch}ms');
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

  Future<void> onTabChanged(int index) async {
    currentPage.value = index;
    appBarText.value = tabTitles[index];
    if (index == 0 && Get.isRegistered<FutureRunListPageController>()) {
      final ctrl = Get.find<FutureRunListPageController>();
      await ctrl.refreshFromTable(true); // instant local refresh
      unawaited(ctrl.triggerBackgroundSync()); // background API sync (1-min debounce)
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-run the "are we at a run start?" check when the app returns to the
      // foreground. Boot and screen-unlock were the only triggers, so simply
      // reopening the app from the background — the most common way a user
      // brings it up while standing at the start line — never fired it.
      if (appModel.hasLocationPermissions) {
        unawaited(_checkAreWeAtRunStart());
      }

      if (currentPage.value == 0 &&
          Get.isRegistered<FutureRunListPageController>()) {
        unawaited(
          Get.find<FutureRunListPageController>()
              .triggerBackgroundSync(ignoreDebounce: true),
        );
      }
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
    update([UpdateIds.appScaffold]);

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
        if (event == ScreenStateEvent.screenUnlocked) {
          if (appModel.hasLocationPermissions) await _checkAreWeAtRunStart();
        }
      });
    } catch (e) {
      debugPrint('main_navigation_controller: screen state listener failed: $e');
    }
  }

  Future<void> _checkAreWeAtRunStart() async {
    debugPrint('[BOOT] _checkAreWeAtRunStart: start: ${DateTime.now().millisecondsSinceEpoch}ms');
    await Utilities.isAtRunStart();
    debugPrint('[BOOT] _checkAreWeAtRunStart: done: ${DateTime.now().millisecondsSinceEpoch}ms');
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_screenWatcherSub?.cancel());
    super.onClose();
  }
}
