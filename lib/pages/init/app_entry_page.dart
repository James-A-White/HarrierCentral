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

  Future<void> _handleStartup(BuildContext context) async {
    final PackageInfo p = await PackageInfo.fromPlatform();
    final String hcVersion = 'HC Ver: ${p.version}, Bld: ${p.buildNumber}';

    await setStringPref(StringPrefsEnum.harrierCentralVersion, hcVersion);

    await setupLocalServices(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);

    await G0.allReady();

    G0<AppModel>().appStartTime = DateTime.now();

    G0<AppModel>().hasLocationPermissions = await Permission.location.isGranted;

    G0<DeviceInfo>().deviceWidthScaleFactor ??= MediaQuery.of(context).size.width / BASE_DEVICE_WIDTH;
    G0<DeviceInfo>().deviceHeightScaleFactor ??= MediaQuery.of(context).size.height / BASE_DEVICE_HEIGHT;
    G0<DeviceInfo>().deviceMaxScaleFactor ??= max(G0<DeviceInfo>().deviceWidthScaleFactor, G0<DeviceInfo>().deviceHeightScaleFactor);
    G0<DeviceInfo>().deviceMinScaleFactor ??= min(G0<DeviceInfo>().deviceWidthScaleFactor, G0<DeviceInfo>().deviceHeightScaleFactor);

    G0<DeviceInfo>().deviceWidth ??= MediaQuery.of(context).size.width;
    G0<DeviceInfo>().deviceHeight ??= MediaQuery.of(context).size.height;

    final String userId = getStringPref(StringPrefsEnum.userId);

    final InternetConnectionChecker checker = InternetConnectionChecker();

    while (!await checker.hasConnection) {
      final bool useOffline = await IveCoreUtilities.showAlert(
          context,
          'Check Network',
          'Harrier Central is unable to detect a network connection.\r\n\r\nPlease check the network connection on your phone and try again, or you can continue to use the app in Offline Mode.',
          'Use Offline',
          showCancelButton: true,
          cancelButtonText: 'Try again');
      if (useOffline) {
        break;
      }

      await Future<void>.delayed(const Duration(seconds: 2));
    }

    if (await checker.hasConnection) {
      G0<AppModel>().connectionStatus = EnumConnectionStatus.connected;

      final List<AddressCheckOptions> addressesToCheck = <AddressCheckOptions>[];

      final List<InternetAddress> hcAddress = await InternetAddress.lookup(BASE_URL);

      for (InternetAddress address in hcAddress) {
        final AddressCheckOptions aco = AddressCheckOptions(
          address: address,
          timeout: const Duration(milliseconds: 10000),
          port: 80,
        );
        addressesToCheck.add(aco);
      }

      checker.addresses = addressesToCheck;

      if (!await checker.hasConnection) {
        await IveCoreUtilities.showAlert(
            context,
            'Server Offline',
            'The Harrier Central App is able to access the network but is unable to connect to our backend server.\r\n\r\nThis can happen if there is a problem with the network or our service is down for maintenance.\r\n\r\nYou can use the app offline or close the app and try again later.',
            'OK');

        G0<AppModel>().connectionStatus = EnumConnectionStatus.not_connected;
      }
    } else {
      G0<AppModel>().connectionStatus = EnumConnectionStatus.not_connected;
    }

    ApproveLoginModel loginResult;
    List<PromoModel> promoResult;
    String facebookAccessToken;
    final ApproveLoginService svc = ApproveLoginService();

    await Utilities.subscribeToGeoLocationStream();

    if (G0<AppModel>().connectionStatus == EnumConnectionStatus.connected) {
      facebookAccessToken = await _checkFacebookLogin();
      final String responseBody = await svc.approveLogin(context, facebookAccessToken);
      loginResult = ApproveLoginModel.itemFromJson(responseBody);
      promoResult = PromoModel.itemsFromJson(responseBody);
    }

    if (loginResult != null) {
      await setStringPref(StringPrefsEnum.iosDownloadLink, loginResult.iosDownloadLink);
      await setStringPref(StringPrefsEnum.androidDownloadLink, loginResult.androidDownloadLink);
      await setStringPref(StringPrefsEnum.imageRootUrl, loginResult.imageRootUrl);
      await setIntPref(IntPrefsEnum.isBetaTester, loginResult.isBetaTester ?? 0);
      await setStringPref(StringPrefsEnum.email, loginResult.email);
      await setStringPref(StringPrefsEnum.homeKennelId, loginResult.homeKennelId ?? '');

      if ((loginResult.thirdPartyForceTokenRefresh.year != 2000) && (loginResult.thirdPartyForceTokenRefresh.toString() != getStringPref(StringPrefsEnum.thirdPartyForceTokenRefresh))) {
        if (DateTime.now().difference(loginResult.thirdPartyForceTokenRefresh).inDays > 2) {
          final DateTime fbLoginCancelled = getDatePref(DatePrefsEnum.fbLoginCancelled) ?? DateTime(2020);
          final Duration timeSinceFbCancellaction = DateTime.now().difference(fbLoginCancelled);

          if (timeSinceFbCancellaction.inDays > 1) {
            await IveCoreUtilities.showAlert(
                context,
                'Facebook Login Required',
                'Our system indicates that you are an admin of a Facebook Group that uses Facebook integration.\r\n\r\nIt appears as though the Facebook Authorization Token we have in our system for your group has expired.\r\n\r\nTo refresh the token, Harrier Central will now ask you to log in to Facebook. Once you log in, your token will be refreshed and Facebook integration will continue to work for your Kennel.\r\n\r\nIf you have questions, please contact us at connect@harriercentral.com.',
                'OK');

            await setDatePref(DatePrefsEnum.lastFbTokenUpdate, DateTime(2020));
            await setDatePref(DatePrefsEnum.fbLoginCancelled, DateTime(2020));
            facebookAccessToken = await _checkFacebookLogin();
            if (facebookAccessToken != null) {
              await setStringPref(StringPrefsEnum.thirdPartyForceTokenRefresh, loginResult.thirdPartyForceTokenRefresh.toString());
              final String responseBody = await svc.approveLogin(context, facebookAccessToken);
              loginResult = ApproveLoginModel.itemFromJson(responseBody);
            }
          }
        }
      }
    }

    if ((loginResult == null) && ((userId == null) || (userId.isEmpty))) {
      // we get here if we are disconnected and the app has never been run before
      // we can't operate in offline mode because there is no data in the cache
      await IveCoreUtilities.showAlert(context, 'Network Error',
          'The first time you run Harrier Central, you must be connected to the network\r\n\r\nPlease check your network connection and re-run Harrier Central when the network is connected.', 'Quit');
      exit(0);
    } else if (loginResult == null) {
      // open app in offline mode
      G0<AppModel>().connectionStatus = EnumConnectionStatus.not_connected;

      await Navigator.pushReplacement<dynamic, dynamic>(
          context,
          MaterialPageRoute<dynamic>(
              builder: (BuildContext context) => const MainNavigationPage(
                    promos: <PromoModel>[],
                    firstPromoImage: null,
                  )));

      return;
    } else {
      // No userId was present, this must be the first time the app has been run
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
                    Navigator.pushReplacement<dynamic, dynamic>(
                        context,
                        MaterialPageRoute<dynamic>(
                            builder: (BuildContext context) => const MainNavigationPage(
                                  promos: <PromoModel>[],
                                  firstPromoImage: null,
                                )));
                  });
                } else {
                  // TODO(James): Do something here if the auth device fails
                }
              } else {
                if ((promoResult != null) && (promoResult.isNotEmpty)) {
                  Image promoImage;

                  try {
                    promoImage = Image.network(
                      promoResult[0].promoImage + promoResult[0].promoImageExtension,
                      fit: BoxFit.fitWidth,
                      errorBuilder: (BuildContext context, Object exception, StackTrace stackTrace) {
                        // Appropriate logging or analytics, e.g.
                        // myAnalytics.recordError(
                        //   'An error occurred loading "https://example.does.not.exist/image.jpg"',
                        //   exception,
                        //   stackTrace,
                        // );
                        return Image.asset('images/other/white_square.jpg', width: 1, height: 1, fit: BoxFit.fitHeight);
                      },
                    );
                  } catch (error) {
                    promoImage = Image.asset('images/other/white_square.jpg', width: 1, height: 1, fit: BoxFit.fitHeight);
                  }

                  promoImage.image.resolve(const ImageConfiguration()).addListener(
                    ImageStreamListener(
                      (ImageInfo info, bool syncCall) async {
                        await Navigator.pushReplacement<dynamic, dynamic>(
                            context,
                            MaterialPageRoute<dynamic>(
                                builder: (BuildContext context) => MainNavigationPage(
                                      promos: promoResult,
                                      firstPromoImage: promoImage,
                                    )));
                      },
                    ),
                  );
                } else {
                  await Navigator.pushReplacement<dynamic, dynamic>(
                      context,
                      MaterialPageRoute<dynamic>(
                          builder: (BuildContext context) => MainNavigationPage(
                                promos: promoResult,
                                firstPromoImage: null,
                              )));
                }
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

  Future<void> _startTimeout() async {
    await initPrefs();
    await Future<dynamic>.delayed(const Duration(seconds: SPLASH_SCREEN_DISPLAY_TIME));
    await _handleStartup(context);
    return;
  }

  @override
  void initState() {
    _iconAnimationController = AnimationController(duration: const Duration(milliseconds: 3000), vsync: this);
    _iconAnimation = CurvedAnimation(parent: _iconAnimationController, curve: Curves.easeIn);
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
