import 'package:harrier_central/imports.dart';

class AppEntryPage extends StatefulWidget {
  const AppEntryPage({super.key});

  @override
  AppEntryPageState createState() => AppEntryPageState();
}

class AppEntryPageState extends State<AppEntryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _iconAnimationController;
  late CurvedAnimation _iconAnimation;

  Future<void> _handleStartup(BuildContext context) async {
    print('App startup called...');

    String? userId = getStringPref(StringPrefsEnum.userId);
    final String? deviceId = getStringPref(StringPrefsEnum.deviceId);

    if ((userId == null) && (deviceId == null)) {
      // this will occur when migrating from 1.x to 2.x software because
      // I've changed getStringPref from SharedPreferences to GetStorage.
      // So, let's check to see if the userId exists using the
      // old SharedPreferences.

      userId = await getStringPrefLegacy(StringPrefsEnum.userId);
    }

    await Utilities.checkForInternetConnection(false);

    if ((userId != null) && (deviceId == null)) {
      // we hit this case when people are migrating from a 1.xx release to the 2.xx
      // release. In 1.xx we didn't have the concept of a DeviceId. In 2.xx we use
      // the DeviceId so that we can maintain separate FCN tokens on the server, and
      // so we can implement a deviceSecret for increased security

      // call Authorize device first to get the device secret and device ID
      final AuthorizeDeviceService srv = AuthorizeDeviceService();
      await srv.authorizeDevice(userId: userId);

      // now tear down the database GetIt instance and Get data
      await DBProvider.deleteDb(DB_NAME);
      await Get.deleteAll(force: true);

      // Now let's rebuild the services and then re-run the app
      await initPrefs(); // if services read prefs during init()
      await initServices(); // GetX DI registration (see services_init.dart)

      // Use Navigator with context since Get.offAll() now lacks a key
      Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppEntryPage()),
        (route) => false,
      );

      // stop it from falling through and continuing to run.
      // this shouldn't be needed, but I'll put it in for now for testing
      await Future.delayed(const Duration(milliseconds: 5000));

      // if (result.isNotEmpty) {
      //   await Utilities.showAlert(
      //     'Upgraded to 2.0',
      //     'Congratulations! Your app has been successfully upgraded to Harrier Central 2.0.',
      //     'OK',
      //   );
      // }
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

    deviceInfo.deviceWidth =
        MediaQuery.of(navigatorKey.currentContext!).size.width;
    deviceInfo.deviceHeight =
        MediaQuery.of(navigatorKey.currentContext!).size.height;

    ApproveLoginModel? loginResult;

    final ApproveLoginService svc = ApproveLoginService();

    await Utilities.subscribeToGeoLocationStream();

    if (appModel.connectionStatus == EnumConnectionStatus2.connected) {
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
      appModel.connectionStatus = EnumConnectionStatus2.notConnected;

      Get.off(() => MainNavigationPage(), routeName: '/main');

      // await Navigator.pushReplacement<dynamic, dynamic>(
      //   navigatorKey.currentContext!,
      //   MaterialPageRoute<dynamic>(
      //     builder: (BuildContext context) => MainNavigationPage(),
      //   ),
      // );

      return;
    } else {
      // No userId was present, this must be the first time the app has been run
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
            appModel.connectionStatus = EnumConnectionStatus2.connected;
            //if (true) {
            if (((userId == null) ||
                (userId.isEmpty) ||
                (userId == GUID_EMPTY))) {
              // first time the app has run
              if (!mounted) return;
              await Navigator.of(
                navigatorKey.currentContext!,
              ).pushReplacementNamed(RouteNames.INTRO_SLIDER.toString());
            } else {
              // it is not normal for this condition to happen
              // but if for some reason, notification permissions
              // have not been requested at this point,
              // go ahead and ask for them. This could happen
              // on a profile reload

              // bool? notificationsConfigured = getBoolPref(
              //   BoolPrefsEnum.notificationPreferencesRequested,
              // );

              // if (notificationsConfigured == null || !notificationsConfigured) {
              //   await Get.putAsync(
              //     () => NotificationService().init(),
              //   ); // Initialize and wait for the notification service
              // }

              // app has been run before... let's check the DB version.
              final int installedDbVersion =
                  getIntPref(IntPrefsEnum.databaseVersion) ?? 0;

              if ((installedDbVersion != DB_VERSION) &&
                  ((installedDbVersion + 9) < DB_VERSION)) {
                // the installed DB version is not up to date
                // if the version numbers are greater than 10 apart,
                // reload the entire DB.

                final String resetCode =
                    getStringPref(StringPrefsEnum.resetCode) ?? '';

                if (resetCode.isNotEmpty) {
                  await DBProvider.deleteDb(DB_NAME);
                  appModel.dbStatus = EdbStatus.uninitialized;

                  //bool isLoading = true;
                  String userName;

                  final AuthorizeDeviceService srv = AuthorizeDeviceService();

                  if (!mounted) return;
                  final Map<String, String> result = await srv.authorizeDevice(
                    scanText: resetCode.toUpperCase(),
                  );

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

                    final PackageInfo p = await PackageInfo.fromPlatform();
                    if (p.version.startsWith('2.0.0')) {
                      dialogTitle = 'Upgraded to Harrier Central 2.0';
                      dialogMessage =
                          'Congratulations $userName. You'
                          'v just received the long awaited 2.0 version upgrade of Harrier Central! We hope you enjoy the many new features and improvements.';
                    }

                    await Utilities.showAlert(
                      dialogTitle,
                      dialogMessage,
                      'OK',
                    ).then((void _) {
                      Get.off(() => MainNavigationPage(), routeName: '/main');

                      // Navigator.pushReplacement<dynamic, dynamic>(
                      //   navigatorKey.currentContext!,
                      //   MaterialPageRoute<dynamic>(
                      //     builder:
                      //         (BuildContext context) => MainNavigationPage(),
                      //   ),
                      // );
                    });
                  } else {
                    // TODO(James): Do something here if the auth device fails
                  }
                }
              } else {
                Get.off(() => MainNavigationPage(), routeName: '/main');

                // if (!mounted) return;
                // await Navigator.pushReplacement<dynamic, dynamic>(
                //   navigatorKey.currentContext!,
                //   MaterialPageRoute<dynamic>(
                //     builder: (BuildContext context) => MainNavigationPage(),
                //   ),
                // );
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

    //// return Future<void>(() {});((){});
  }

  // Future<String?> _checkFacebookLogin() async {
  //   final DateTime lastFbUpdate = getDatePref(DatePrefsEnum.lastFbTokenUpdate) ?? DateTime(2020);
  //   final Duration fbTokenUpdateDelta = DateTime.now().difference(lastFbUpdate);
  //   String? facebookAccessToken;

  //   if (fbTokenUpdateDelta.inDays > 30) {
  //     final DateTime fbLoginCancelled = getDatePref(DatePrefsEnum.fbLoginCancelled) ?? DateTime(2020);

  //     final Duration daysSinceCancellation = DateTime.now().difference(fbLoginCancelled);

  //     if (daysSinceCancellation.inDays > 30) {
  //       final String? facebookId = getStringPref(StringPrefsEnum.facebookId);

  //       if (((facebookId != null) && (facebookId.isNotEmpty)) || ((facebookAccessToken != null) && (facebookAccessToken.isNotEmpty))) {
  //         final LoginResult loginResult = await FacebookAuth.instance.login();
  //         if (loginResult.status == LoginStatus.success) {
  //           final AccessToken? accessToken = loginResult.accessToken;
  //           facebookAccessToken = accessToken?.token;
  //           if (facebookAccessToken != null) {
  //             await setStringPref(StringPrefsEnum.facebookAccessToken, facebookAccessToken);
  //             await setDatePref(DatePrefsEnum.lastFbTokenUpdate, DateTime.now());
  //             await setDatePref(DatePrefsEnum.fbLoginCancelled, DateTime(2020));
  //           }
  //         } else if (loginResult.status == LoginStatus.cancelled) {
  //           await setDatePref(DatePrefsEnum.fbLoginCancelled, DateTime.now());
  //         }
  //       }
  //     }
  //   }
  //   return facebookAccessToken;
  // }

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
    _iconAnimationController.dispose();
    super.dispose();
  }

  Future<void> _startTimeout() async {
    await Future<dynamic>.delayed(
      const Duration(seconds: SPLASH_SCREEN_DISPLAY_TIME),
    );

    if (!mounted) return;
    await _handleStartup(context);
    return;
  }

  @override
  void initState() {
    // precache the background image so it does not give a white flash
    // on the first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(
        const AssetAvifImage('images/backgrounds/hash_foot_background.avif'),
        navigatorKey.currentState!.context,
      );
    });

    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _iconAnimation = CurvedAnimation(
      parent: _iconAnimationController,
      curve: Curves.easeIn,
    );
    _iconAnimation.addListener(() => setState(() {}));
    _iconAnimationController.forward();

    _startTimeout();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset('images/init/splash_screen.jpg');
  }
}
