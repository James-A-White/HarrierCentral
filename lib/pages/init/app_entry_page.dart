// @dart=2.11
import 'package:harrier_central/imports.dart';

class AppEntryPage extends StatefulWidget {
  const AppEntryPage({Key key}) : super(key: key);
  @override
  _AppEntryPageState createState() => _AppEntryPageState();
}

class _AppEntryPageState extends State<AppEntryPage> with SingleTickerProviderStateMixin {
  AnimationController _iconAnimationController;
  CurvedAnimation _iconAnimation;

  Future<void> handleStartup(BuildContext context) async {
    final PackageInfo p = await PackageInfo.fromPlatform();
    final String hcVersion = 'HC Ver: ${p.version}, Bld: ${p.buildNumber}';

    await setStringPref(StringPrefsEnum.harrierCentralVersion, hcVersion);

    await setupLocalServices(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);

    await G0.allReady();

    G0<AppModel>().appStartTime = DateTime.now();

    G0<DeviceInfo>().deviceWidthScaleFactor ??= MediaQuery.of(context).size.width / BASE_DEVICE_WIDTH;
    G0<DeviceInfo>().deviceHeightScaleFactor ??= MediaQuery.of(context).size.height / BASE_DEVICE_HEIGHT;
    G0<DeviceInfo>().deviceMaxScaleFactor ??= max(G0<DeviceInfo>().deviceWidthScaleFactor, G0<DeviceInfo>().deviceHeightScaleFactor);
    G0<DeviceInfo>().deviceMinScaleFactor ??= min(G0<DeviceInfo>().deviceWidthScaleFactor, G0<DeviceInfo>().deviceHeightScaleFactor);

    G0<DeviceInfo>().deviceWidth ??= MediaQuery.of(context).size.width;
    G0<DeviceInfo>().deviceHeight ??= MediaQuery.of(context).size.height;

    // await PermissionHandler().requestPermissions(<PermissionGroup>[PermissionGroup.camera, PermissionGroup.location]);

    await Utilities.subscribeToGeoLocationStream();

    final String userId = getStringPref(StringPrefsEnum.userId);

    String facebookAccessToken = await _checkFacebookLogin();

    final ApproveLoginService svc = ApproveLoginService();
    ApproveLoginModel loginResult = await svc.approveLogin(context, facebookAccessToken);

    if (loginResult != null) {
      await setStringPref(StringPrefsEnum.iosDownloadLink, loginResult.iosDownloadLink);
      await setStringPref(StringPrefsEnum.androidDownloadLink, loginResult.androidDownloadLink);
      await setStringPref(StringPrefsEnum.imageRootUrl, loginResult.imageRootUrl);
      await setIntPref(IntPrefsEnum.isBetaTester, loginResult.isBetaTester ?? 0);
      await setStringPref(StringPrefsEnum.email, loginResult.email);
      await setStringPref(StringPrefsEnum.homeKennelId, loginResult.homeKennelId ?? '');

      if ((loginResult.thirdPartyForceTokenRefresh.year != 2000) && (loginResult.thirdPartyForceTokenRefresh.toString() != getStringPref(StringPrefsEnum.thirdPartyForceTokenRefresh))) {
        await setStringPref(StringPrefsEnum.thirdPartyForceTokenRefresh, loginResult.thirdPartyForceTokenRefresh.toString());

        await IveCoreUtilities.showAlert(
            context,
            'Facebook Login Required',
            'Our system indicates that you are an admin of a Facebook Group that uses Facebook integration.\r\n\r\nIt appears as though the Facebook Authorization Token we have in our system for your group has expired.\r\n\r\nTo refresh the token, Harrier Central will now ask you to log in to Facebook. Once you log in, your token will be refreshed and Facebook integration will continue to work for your Kennel.\r\n\r\nIf you have questions, please contact us at connect@harriercentral.com.',
            'OK');

        await setDatePref(DatePrefsEnum.lastFbTokenUpdate, DateTime(2020));
        await setDatePref(DatePrefsEnum.fbLoginCancelled, DateTime(2020));
        facebookAccessToken = await _checkFacebookLogin();
        loginResult = await svc.approveLogin(context, facebookAccessToken);
      }
    }

    if ((loginResult == null) && ((userId == null) || (userId.isEmpty))) {
      // we get here if we are disconnected and the app has never been run before
      // we can't operate in offline mode because there is no data in the cache
      await IveCoreUtilities.showAlert(context, 'Network Error',
          'The first time you run Harrier Central, you must be connected to the network\r\n\r\nPlease check your network connection and re-run Harrier Central when the network is connected.', 'Quit');
      exit(0);
    } else if (loginResult == null) {
      G0<AppModel>().connectionStatus = EnumConnectionStatus.not_connected;
      await Navigator.pushReplacement<dynamic, dynamic>(context, MaterialPageRoute<dynamic>(builder: (BuildContext context) => const MainNavigationPage()));
      return;
    } else {
      const bool allowContinueFromMessage = true;

      if (loginResult.messageDisplayType != loginMessageTypeNone.value) {
        if (loginResult.messageDisplayType == loginMessageTypeAlert.value) {
          await _displayAlert(context, loginResult.loginMessage, loginResult.loginMessageTitle);
        }
      }

      if (allowContinueFromMessage) {
        if (loginResult.serverStatusCode == serverStatusUp.value) {
          if (loginResult.approvalCode == loginApprovalApproved.value) {
            G0<AppModel>().connectionStatus = EnumConnectionStatus.connected;
            //if (true) {
            if (userId == null) {
              // first time the app has run
              await Navigator.of(context).pushReplacementNamed(RouteNames.INTRO_SLIDER.toString());
            } else {
              // app has been run before... let's check the DB version.
              final int installedDbVersion = getIntPref(IntPrefsEnum.databaseVersion) ?? 0;
              if ((installedDbVersion != DB_VERSION) && ((installedDbVersion + 9) < DB_VERSION)) {
                // the installed DB version is not up to date
                // if the version numbers are greater than 10 apart,
                // reload the entire DB.

                final String resetCode = getStringPref(StringPrefsEnum.resetCode);

                await DBProvider.deleteDb(DB_NAME);
                G0<AppModel>().dbStatus = EdbStatus.uninitialized;

                //bool isLoading = true;
                String userName;

                final AuthorizeDeviceService srv = AuthorizeDeviceService();

                final Map<String, String> result = await srv.authorizeDevice(context, resetCode.toUpperCase());

                setState(() {
                  //isLoading = false;
                });

                if (result['result'] != 'failed') {
                  userName = getStringPref(StringPrefsEnum.displayName);

                  await setIntPref(IntPrefsEnum.databaseVersion, DB_VERSION);

                  await IveCoreUtilities.showAlert(context, 'Profile Load Successful', 'The app has been successfully updated for $userName.', 'OK').then((void _) {
                    Navigator.pushReplacement<dynamic, dynamic>(context, MaterialPageRoute<dynamic>(builder: (BuildContext context) => const MainNavigationPage()));
                  });
                } else {
                  // TODO(James): Do something here if the auth device fails
                }
              } else {
                await Navigator.pushReplacement<dynamic, dynamic>(context, MaterialPageRoute<dynamic>(builder: (BuildContext context) => const MainNavigationPage()));
              }
            }
          } else {
            // TODO(James): Handle cases where login is disapproved
          }
        } else {
          // TODO(James): Handle cases where server is down
        }
      } else {
        // TODO(James): Handle case where not allowed to continue after a message
      }
    }

    //// return Future<void>(() {});((){});
  }

  Future<String> _checkFacebookLogin() async {
    final DateTime lastFbUpdate = getDatePref(DatePrefsEnum.lastFbTokenUpdate) ?? DateTime(2020);
    final Duration fbTokenUpdateDelta = DateTime.now().difference(lastFbUpdate);
    String facebookAccessToken;

    if (fbTokenUpdateDelta.inDays > 30) {
      final DateTime fbLoginCancelled = getDatePref(DatePrefsEnum.fbLoginCancelled) ?? DateTime(2020);

      final Duration daysSinceCancellation = DateTime.now().difference(fbLoginCancelled);

      if (daysSinceCancellation.inDays > 30) {
        final String facebookId = getStringPref(StringPrefsEnum.facebookId);

        if (((facebookId != null) && (facebookId.isNotEmpty)) || ((facebookAccessToken != null) && (facebookAccessToken.isNotEmpty))) {
          final LoginResult loginResult = await FacebookAuth.instance.login();
          if (loginResult != null) {
            if (loginResult.status == LoginStatus.success) {
              final AccessToken accessToken = loginResult.accessToken;
              facebookAccessToken = accessToken?.token;
              if (facebookAccessToken != null) {
                await setStringPref(StringPrefsEnum.facebookAccessToken, facebookAccessToken);
                await setDatePref(DatePrefsEnum.lastFbTokenUpdate, DateTime.now());
                await setDatePref(DatePrefsEnum.fbLoginCancelled, DateTime(2020));
              }
            } else if (loginResult.status == LoginStatus.cancelled) {
              await setDatePref(DatePrefsEnum.fbLoginCancelled, DateTime.now());
            }
          }
        }
      }
    }
    return facebookAccessToken;
  }

  Future<bool> _displayAlert(BuildContext context, String alertText, String alertTitle) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(alertTitle),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  alertText,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 16.0, height: 1.0),
                )
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK, Got it!'),
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

  Future<void> startTimeout() async {
    await initPrefs();
    await Future<dynamic>.delayed(const Duration(seconds: SPLASH_SCREEN_DISPLAY_TIME));
    await handleStartup(context);
    return;
  }

  //bool _visible = true;
  @override
  void initState() {
    super.initState();

    _iconAnimationController = AnimationController(duration: const Duration(milliseconds: 3000), vsync: this);

    _iconAnimation = CurvedAnimation(parent: _iconAnimationController, curve: Curves.easeIn);
    _iconAnimation.addListener(() => setState(() {}));

    _iconAnimationController.forward();

    startTimeout();
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset('images/init/splash_screen.jpg');
  }
}
