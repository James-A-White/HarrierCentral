import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:package_info/package_info.dart';
import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/database/migrations.dart';
import 'package:harrier_central/data/models/approve_login_model.dart';
import 'package:harrier_central/data/hc3_services/sync_user_data_service.dart';
import 'package:harrier_central/pages/top_level/main_navigation_page.dart';
import 'package:harrier_central/data/services/approve_login_service.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/routes.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/notifications/notification_support.dart';
import 'package:harrier_central/data/services/authorize_device_service.dart';

class AppEntryPage extends StatefulWidget {
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

    // await PermissionHandler().requestPermissions(<PermissionGroup>[PermissionGroup.camera, PermissionGroup.location]);

    final String userId = getStringPref(StringPrefsEnum.userId);

    final ApproveLoginService svc = ApproveLoginService();
    final ApproveLoginModel loginResult = await svc.approveLogin(context);

    if (loginResult != null) {
      await setStringPref(StringPrefsEnum.iosDownloadLink, loginResult.iosDownloadLink);
      await setStringPref(StringPrefsEnum.androidDownloadLink, loginResult.androidDownloadLink);
      await setStringPref(StringPrefsEnum.imageRootUrl, loginResult.imageRootUrl);
    }

    if ((loginResult == null) && ((userId == null) || (userId.isEmpty))) {
      // we get here if we are disconnected and the app has never been run before
      // we can't operate in offline mode because there is no data in the cache
      Utilities.showAlert(context, 'Network Error', 'Harrier Central was not able to contact the server. Please try again later.\r\n\r\nPlease check your network connection.', 'Quit').then((void dummy) async {
        await SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');
        return null;
      });
    } else if (loginResult == null) {
      globalConnectionStatus = connectionStatus_notConnected;
      Navigator.pushReplacement<dynamic, dynamic>(context, MaterialPageRoute<dynamic>(builder: (BuildContext context) => const MainNavigationPage()));
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
            globalConnectionStatus = connectionStatus_connected;
            //if (true) {
            if (userId == null) {
              // first time the app has run
              Navigator.of(context).pushReplacementNamed(RouteNames.INTRO_SLIDER.toString());
            } else {
              // app has been run before... let's check the DB version.
              final int installedDbVersion = getIntPref(IntPrefsEnum.databaseVersion) ?? 0;
              if ((installedDbVersion != MigrationsTableHelper.dbVersion) && ((installedDbVersion + 9) < MigrationsTableHelper.dbVersion)) {
                // the installed DB version is not up to date
                // if the version numbers are greater than 10 apart,
                // reload the entire DB.

                final String resetCode = getStringPref(StringPrefsEnum.resetCode);

                DBProvider.db.deleteDb();
                await setIntPref(IntPrefsEnum.dbCreated,0);

                //bool isLoading = true;
                String userName;

                final AuthorizeDeviceService srv = AuthorizeDeviceService();
                final Future<Map<String, String>> apiCall = srv.authorizeDevice(context, resetCode.toUpperCase());
                apiCall.then((Map<String, String> result) async {
                  setState(() {
                    //isLoading = false;
                  });

                  if (result['result'] != 'failed') {
                    userName = getStringPref(StringPrefsEnum.displayName);

                    await setIntPref(IntPrefsEnum.databaseVersion, MigrationsTableHelper.dbVersion);

                    Utilities.showAlert(context, 'Profile Load Successful', 'The app has been successfully updated for $userName.', 'OK').then((void dummy) {
                      Navigator.pushReplacement<dynamic, dynamic>(context, MaterialPageRoute<dynamic>(builder: (BuildContext context) => const MainNavigationPage()));
                    });
                  } else {
                    // TODO(James): Do something here if the auth device fails
                  }
                });
              } else {
                final Database db = await DBProvider.db.database;

                final SyncUserDataService cSrv = SyncUserDataService();
                final bool result = await cSrv.updateFromBackend(db, SyncUserDataService.flagsAllData, false);
                final String resultStr = result ? 'successfully' : 'unsuccessfully';
                print('Master data synchronized $resultStr');

                final NotificationSupport notifications = NotificationSupport();
                notifications.configureNotifications(true);

                Navigator.pushReplacement<dynamic, dynamic>(context, MaterialPageRoute<dynamic>(builder: (BuildContext context) => const MainNavigationPage()));
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
            FlatButton(
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

    _iconAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));

    _iconAnimation = CurvedAnimation(parent: _iconAnimationController, curve: Curves.easeIn);
    _iconAnimation.addListener(() => setState(() {}));

    _iconAnimationController.forward();

    startTimeout();
  }

  @override
  Widget build(BuildContext context) {
    deviceWidthScaleFactor ??= MediaQuery.of(context).size.width / BASE_DEVICE_WIDTH;
    deviceHeightScaleFactor ??= MediaQuery.of(context).size.height / BASE_DEVICE_HEIGHT;
    deviceMaxScaleFactor ??= max(deviceWidthScaleFactor, deviceHeightScaleFactor);
    deviceMinScaleFactor ??= min(deviceWidthScaleFactor, deviceHeightScaleFactor);

    deviceWidth ??= MediaQuery.of(context).size.width;
    return Image.asset('images/init/splash_screen.jpg');
  }
}
