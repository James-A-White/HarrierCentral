import 'package:get/get_navigation/src/extension_navigation.dart' as nav;
import 'package:harrier_central/imports.dart';

class AppEntryPage extends StatefulWidget {
  const AppEntryPage({super.key});

  @override
  AppEntryPageState createState() => AppEntryPageState();
}

class AppEntryPageState extends State<AppEntryPage>
    with SingleTickerProviderStateMixin {
  // late AnimationController _iconAnimationController;
  // late CurvedAnimation _iconAnimation;

  var _launchCount = 0;

  Future<void> _handleStartup() async {
    await initPrefs(); // if services read prefs during init()

    String bootType =
        getStringPref(StringPrefsEnum.bootType) ?? BOOT_TYPE_UNKNOWN;

    if (bootType == BOOT_TYPE_RELOAD_DATA) {
      final String? userId = getStringPref(StringPrefsEnum.userId);
      final String? publicHasherId = getStringPref(
        StringPrefsEnum.publicHasherId,
      );
      final String? deviceId = getStringPref(StringPrefsEnum.deviceId);
      final String? resetCode = getStringPref(StringPrefsEnum.resetCode);
      final String? deviceSecret = getStringPref(StringPrefsEnum.deviceSecret);
      final String? displayName = getStringPref(StringPrefsEnum.displayName);
      final String? profilePhotoUrl = getStringPref(
        StringPrefsEnum.profilePhotoUrl,
      );
      final int? timeWindow = getIntPref(IntPrefsEnum.timeWindow);

      final String? thirdPartyAccessToken = getStringPref(
        StringPrefsEnum.thirdPartyAccessToken,
      );
      final String? thirdPartyAuthorizationCode = getStringPref(
        StringPrefsEnum.thirdPartyAuthorizationCode,
      );
      final String? thirdPartyEmail = getStringPref(
        StringPrefsEnum.thirdPartyEmail,
      );
      final String? thirdPartyForceTokenRefresh = getStringPref(
        StringPrefsEnum.thirdPartyForceTokenRefresh,
      );
      final String? thirdPartyLoginEmail = getStringPref(
        StringPrefsEnum.thirdPartyLoginEmail,
      );
      final String? thirdPartyLoginType = getStringPref(
        StringPrefsEnum.thirdPartyLoginType,
      );
      final String? thirdPartyUserId = getStringPref(
        StringPrefsEnum.thirdPartyUserId,
      );

      final String? betaFeaturesEnabled = getStringPref(
        StringPrefsEnum.betaFeaturesEnabled,
      );

      final DateTime? thirdPartyTokenLastUpdated = getDatePref(
        DatePrefsEnum.thirdPartyTokenLastUpdated,
      );
      final DateTime? thirdPartyTokenExpires = getDatePref(
        DatePrefsEnum.thirdPartyTokenExpires,
      );

      Get.reset();
      await clearPrefs();

      await setStringPref(StringPrefsEnum.userId, userId);
      await setStringPref(StringPrefsEnum.resetCode, resetCode);
      await setStringPref(StringPrefsEnum.deviceId, deviceId);
      await setStringPref(StringPrefsEnum.deviceSecret, deviceSecret);
      await setStringPref(StringPrefsEnum.displayName, displayName);
      await setStringPref(StringPrefsEnum.publicHasherId, publicHasherId);
      await setStringPref(StringPrefsEnum.profilePhotoUrl, profilePhotoUrl);
      await setStringPref(
        StringPrefsEnum.betaFeaturesEnabled,
        betaFeaturesEnabled,
      );
      await setIntPref(IntPrefsEnum.timeWindow, timeWindow);

      await setStringPref(
        StringPrefsEnum.thirdPartyAccessToken,
        thirdPartyAccessToken,
      );
      await setStringPref(
        StringPrefsEnum.thirdPartyAuthorizationCode,
        thirdPartyAuthorizationCode,
      );
      await setStringPref(StringPrefsEnum.thirdPartyEmail, thirdPartyEmail);
      await setStringPref(
        StringPrefsEnum.thirdPartyForceTokenRefresh,
        thirdPartyForceTokenRefresh,
      );
      await setStringPref(
        StringPrefsEnum.thirdPartyLoginEmail,
        thirdPartyLoginEmail,
      );
      await setStringPref(
        StringPrefsEnum.thirdPartyLoginType,
        thirdPartyLoginType,
      );
      await setStringPref(StringPrefsEnum.thirdPartyUserId, thirdPartyUserId);

      await setDatePref(
        DatePrefsEnum.thirdPartyTokenExpires,
        thirdPartyTokenExpires,
      );

      await setDatePref(
        DatePrefsEnum.thirdPartyTokenLastUpdated,
        thirdPartyTokenLastUpdated,
      );

      //print('Reloading all app data as requested...');

      await DBProvider.deleteDb(DB_NAME);
      await Future.delayed(const Duration(milliseconds: 500));

      //print('Clearing GetX state...');
      // 1. AGGRESSIVE GETX CLEANUP
      // This cleans the state that belonged to the GetMaterialApp we are about to destroy.
      Get.reset();

      //print('Re-initializing services...');
      // 2. RE-INITIALIZE ESSENTIAL SERVICES (AppLifecycleController, etc.)
      await initPrefs();
      await initServices();

      // 3. TRIGGER THE SWAP
      // This triggers the internal logic in RestartWidgetState:
      // a) Hides RootApp (forces unmount/disposal of old GetMaterialApp/Controller)
      // b) Waits for disposal to finish (microtask + delay)
      // c) Re-creates and shows the new RootApp with a fresh key.
      //print('Starting RootApp placeholder swap...');
      restartKey.currentState?.restartApp();

      return;
    }

    if (kDebugMode) {
      print('App startup called...');
    }

    // Let's rebuild the services and then re-run the app
    //await initServices(); // GetX DI registration (see services_init.dart)

    String? userId = getStringPref(StringPrefsEnum.userId);
    final String? deviceId = getStringPref(StringPrefsEnum.deviceId);

    if ((userId == null) && (deviceId == null)) {
      // this will occur when migrating from 1.x to 2.x software because
      // I've changed getStringPref from SharedPreferences to GetStorage.
      // So, let's check to see if the userId exists using the
      // old SharedPreferences.

      userId = await getStringPrefLegacy(StringPrefsEnum.userId);
      // userId = '0cdbb109-215e-4b5f-a405-f6c9fbcb18ec'; // TEMP FOR TESTING
    }

    await Utilities.checkForInternetConnection(false);

    if ((userId != null) && (deviceId == null)) {
      // we hit this case when people are migrating from a 1.xx release to the 2.xx
      // release. In 1.xx we didn't have the concept of a DeviceId. In 2.xx we use
      // the DeviceId so that we can maintain separate FCN tokens on the server, and
      // so we can implement a deviceSecret for increased security

      await setStringPref(StringPrefsEnum.bootType, BOOT_TYPE_UPGRADE_1_2);

      // // call Authorize device first to get the device secret and device ID
      final AuthorizeDeviceService srv = AuthorizeDeviceService();
      await srv.authorizeDevice(userId: userId);

      // now tear down the database GetIt instance and Get data
      await DBProvider.deleteDb(DB_NAME);
      await Get.deleteAll(force: true);

      // Use Navigator with context since Get.offAll() now lacks a key
      await Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppEntryPage()),
        (route) => false,
      );

      return;
    }

    final PackageInfo p = await PackageInfo.fromPlatform();
    final String hcVersionAndBuild =
        'HC Ver: ${p.version}, Bld: ${p.buildNumber}';

    await setStringPref(
      StringPrefsEnum.harrierCentralVersionAndBuild,
      hcVersionAndBuild,
    );

    await setStringPref(StringPrefsEnum.harrierCentralVersion, p.version);

    // await setupLocalServices(
    //   MediaQuery.of(navigatorKey.currentContext!).size.width,
    //   MediaQuery.of(navigatorKey.currentContext!).size.height,
    //   MediaQuery.of(navigatorKey.currentContext!).textScaler.scale(1.0),
    // );

    appModel.appStartTime = DateTime.now();

    appModel.hasLocationPermissions = await Permission.location.isGranted;

    deviceInfo.deviceWidthScaleFactor =
        MediaQuery.of(navigatorKey.currentContext!).size.width /
        BASE_DEVICE_WIDTH;
    deviceInfo.deviceHeightScaleFactor =
        MediaQuery.of(navigatorKey.currentContext!).size.height /
        BASE_DEVICE_HEIGHT;
    deviceInfo.deviceMaxScaleFactor = max(
      deviceInfo.deviceWidthScaleFactor,
      deviceInfo.deviceHeightScaleFactor,
    );
    deviceInfo.deviceMinScaleFactor = min(
      deviceInfo.deviceWidthScaleFactor,
      deviceInfo.deviceHeightScaleFactor,
    );

    deviceInfo.deviceWidth = MediaQuery.of(
      navigatorKey.currentContext!,
    ).size.width;
    deviceInfo.deviceHeight = MediaQuery.of(
      navigatorKey.currentContext!,
    ).size.height;

    ApproveLoginModel? loginResult;

    final ApproveLoginService svc = ApproveLoginService();

    await Utilities.subscribeToGeoLocationStream();

    if (Utilities.isConnected()) {
      final String responseBody = await svc.approveLogin(
        navigatorKey.currentContext!,
        null,
      );

      if (responseBody == ERROR_KEY_OK_BTN_PRESSED) {
        exit(0);
      } else if (!responseBody.startsWith(ERROR_PREFIX)) {
        List<dynamic> responseJson = jsonDecode(responseBody);

        loginResult = ApproveLoginModel.fromJson(responseJson[0][0]);
      }
    }

    if (loginResult != null) {
      // flag up this splash sequence for viewing
      // it will be viewed as long as there is not another
      // higher priority sequence, such as a Harrier Central
      // version upgrade. If the value is null, no splash screen
      // will be displayed
      await setStringPref(
        StringPrefsEnum.splashSequenceRootName,
        loginResult.splashSequenceRootName,
      );

      await setIntPref(
        IntPrefsEnum.splashSequenceType,
        loginResult.splashSequenceType,
      );

      await removePref(DatePrefsEnum.splashSequenceViewedAt);

      await setStringPref(
        StringPrefsEnum.iosDownloadLink,
        loginResult.iosDownloadLink,
      );
      await setStringPref(
        StringPrefsEnum.androidDownloadLink,
        loginResult.androidDownloadLink,
      );
      await setStringPref(
        StringPrefsEnum.imageRootUrl,
        loginResult.imageRootUrl,
      );

      await setStringPref(
        StringPrefsEnum.betaFeaturesEnabled,
        loginResult.betaFeaturesEnabled,
      );
      await setIntPref(
        IntPrefsEnum.isBetaTester,
        loginResult.isBetaTester ?? 0,
      );
      await setStringPref(StringPrefsEnum.email, loginResult.email);
      await setStringPref(
        StringPrefsEnum.homeKennelId,
        loginResult.homeKennelId?.toLowerCase() ?? '',
      );
    }

    if ((loginResult == null) &&
        (((userId ?? '').isEmpty) || (userId == GUID_EMPTY))) {
      // we get here if we are disconnected and the app has never been run before
      // we can't operate in offline mode because there is no data in the cache

      await Utilities.showAlert(
        'Network Error',
        'The first time you run Harrier Central, you must be connected to the network\r\n\r\nPlease check your network connection and re-run Harrier Central when the network is connected.',
        'Quit',
      );
      exit(0);
    } else if (loginResult == null) {
      // open app in offline mode
      //appModel.connectionStatus = EnumConnectionStatus2.notConnected;

      Get.off(() => MainNavigationPage(), routeName: '/main');

      // await Navigator.pushReplacement<dynamic, dynamic>(
      //   navigatorKey.currentContext!,
      //   MaterialPageRoute<dynamic>(
      //     builder: (BuildContext context) => MainNavigationPage(),
      //   ),
      // );

      return;
    } else {
      const bool allowContinueFromMessage = true;

      if (loginResult.messageDisplayType != loginMessageTypeNone.value) {
        if (loginResult.messageDisplayType == loginMessageTypeAlert.value) {
          await _displayAlert(
            navigatorKey.currentContext!,
            loginResult.loginMessage ?? 'Harrier Central status is normal',
            loginResult.loginMessageTitle ?? 'Harrier Central Status',
          );
        }
      }

      if (allowContinueFromMessage) {
        if (loginResult.serverStatusCode == serverStatusUp.value) {
          if (loginResult.approvalCode == loginApprovalApproved.value) {
            //appModel.connectionStatus = EnumConnectionStatus2.connected;
            //if (true) {
            if (((userId == null) ||
                (userId.isEmpty) ||
                (userId == GUID_EMPTY))) {
              await setStringPref(
                StringPrefsEnum.bootType,
                BOOT_TYPE_FIRST_TIME,
              );
              // No userId was present, this must be the first time the app has been run
              if (!mounted) return;
              await Navigator.of(
                navigatorKey.currentContext!,
              ).pushReplacementNamed(RouteNames.INTRO_SLIDER.toString());
            } else {
              // app has been run before... let's check the DB version.
              final int installedDbVersion =
                  getIntPref(IntPrefsEnum.databaseVersion) ?? 0;

              if ((installedDbVersion != DB_VERSION) &&
                  ((installedDbVersion + 9) < DB_VERSION)) {
                // the installed DB version is not up to date
                // if the version numbers are greater than 10 apart,
                // reload the entire DB.

                if (installedDbVersion != 0) {
                  // this is an upgrade of an existing DB
                  // if installedDbVersion is 0, it means
                  // that the DB was never initialized, so
                  // it is a first time boot and we won't
                  // set the boot type to upgrade.
                  await setStringPref(
                    StringPrefsEnum.bootType,
                    BOOT_TYPE_UPGRADE_DB,
                  );
                }

                final String resetCode =
                    getStringPref(StringPrefsEnum.resetCode) ?? '';

                if (resetCode.isNotEmpty) {
                  await DBProvider.deleteDb(DB_NAME);
                  appModel.dbStatus = EdbStatus.uninitialized;

                  //bool isLoading = true;
                  String userName;

                  final Map<String, String> result = <String, String>{
                    'result': 'succeeded',
                  };

                  // this logic is a bit messy. We want to ensure that we only
                  // call authorize device once. On an upgrade to 2.0 it will
                  // have been called above to get the deviceId and deviceSecret
                  // so we only call it here if the deviceId is not already set.
                  // If the deviceId is set, we can just continue to use it.

                  final String? deviceId = getStringPref(
                    StringPrefsEnum.deviceId,
                  );

                  if (deviceId == null) {
                    final AuthorizeDeviceService srv = AuthorizeDeviceService();

                    if (!mounted) return;
                    var r = await srv.authorizeDevice(
                      scanText: resetCode.toUpperCase(),
                    );
                    result['result'] = r['result'] ?? 'failed';
                  }

                  setState(() {
                    //isLoading = false;
                  });

                  if (result['result'] != 'failed') {
                    userName =
                        getStringPref(StringPrefsEnum.displayName) ??
                        '<no user name>';

                    await setIntPref(IntPrefsEnum.databaseVersion, DB_VERSION);

                    String dialogTitle = 'Profile Load Successful';
                    String dialogMessage =
                        'The app has been successfully updated for $userName.';

                    //String? loadType = getStringPref(StringPrefsEnum.bootType);

                    if (getStringPref(StringPrefsEnum.bootType) ==
                        BOOT_TYPE_UPGRADE_1_2) {
                      dialogTitle = 'Upgrade to Harrier Central 2.0';
                      dialogMessage =
                          'Congratulations $userName. You have just received the long awaited 2.0 version upgrade of Harrier Central!\r\n\r\nWe hope you enjoy the many new features and improvements.';
                    }

                    await Utilities.showAlert(dialogTitle, dialogMessage, 'OK');

                    await Get.off(
                      () => MainNavigationPage(),
                      routeName: '/main',
                    );
                    return;
                  } else {
                    // TODO(James): Do something here if the auth device fails
                  }
                }
              } else {
                // DB version is up to date, just continue with a normal boot
                await setStringPref(StringPrefsEnum.bootType, BOOT_TYPE_NORMAL);
                await Get.off(() => MainNavigationPage(), routeName: '/main');
                return;
              }
            }
          } else {
            // TODO(James): Handle cases where login is disapproved
          }
        } else {
          // TODO(James): Handle cases where server is down
        }
        // ignore: dead_code
      } else {
        // TODO(James): Handle case where not allowed to continue after a message
      }
    }
  }

  Future<bool?> _displayAlert(
    BuildContext context,
    String alertText,
    String alertTitle,
  ) async {
    return showDialog<bool?>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(alertTitle, style: ts_alertDialogTitle),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  alertText,
                  textAlign: TextAlign.justify,
                  style: ts_alertDialogBody,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: text_button_style,
              child: Text('OK, Got it!', style: ts_button),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    //_iconAnimationController.dispose();
    super.dispose();
  }

  Future<void> _startTimeout() async {
    if (_launchCount % DISPLAY_SPLASH_ON_LAUNCH == 0) {
      await Future<dynamic>.delayed(
        const Duration(seconds: SPLASH_SCREEN_DISPLAY_TIME),
      );
    }

    await _handleStartup();
    return;
  }

  @override
  void initState() {
    // precache the background image so it does not give a white flash
    // on the first load

    _launchCount = getIntPref(IntPrefsEnum.launchCount) ?? 0;
    setIntPref(IntPrefsEnum.launchCount, _launchCount + 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(
        const AssetAvifImage('images/backgrounds/hash_foot_background.avif'),
        navigatorKey.currentState!.context,
      );
    });

    // _iconAnimationController = AnimationController(
    //   duration: const Duration(milliseconds: 3000),
    //   vsync: this,
    // );
    // _iconAnimation = CurvedAnimation(
    //   parent: _iconAnimationController,
    //   curve: Curves.easeIn,
    // );
    // _iconAnimation.addListener(() => setState(() {}));
    // _iconAnimationController.forward();

    _startTimeout();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_launchCount % DISPLAY_SPLASH_ON_LAUNCH == 0) {
      return Image.asset('images/init/splash_screen.jpg');
    }

    return Image.asset('images/init/launcher_background.png');
  }
}
