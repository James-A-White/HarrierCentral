import 'dart:async';

import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:package_info/package_info.dart';
import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/data/models/approve_login_model.dart';
import 'package:harrier_central/data/hc3_services/sync_user_data_service.dart';
import 'package:harrier_central/database/database.dart';
import 'package:harrier_central/pages/top_level/main_navigation_page.dart';
import 'package:harrier_central/data/services/approve_login_service.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/routes.dart';

class AppEntryPage extends StatefulWidget {
  @override
  _AppEntryPageState createState() => _AppEntryPageState();
}

class _AppEntryPageState extends State<AppEntryPage> with SingleTickerProviderStateMixin {
  AnimationController _iconAnimationController;
  CurvedAnimation _iconAnimation;

  Future<void> handleStartup(BuildContext context) async {
    final PackageInfo p = await PackageInfo.fromPlatform();
    final String hcVersion = 'AppName: ${p.appName}, Version: ${p.version}, Build: ${p.buildNumber}';

    await setStringPref(StringPrefsEnum.harrierCentralVersion, hcVersion);

    await PermissionHandler().requestPermissions(<PermissionGroup>[PermissionGroup.camera, PermissionGroup.location]);

    final String userId = getStringPref(StringPrefsEnum.userId);

    final ApproveLoginService svc = ApproveLoginService();
    final ApproveLoginModel loginResult = await svc.approveLogin(context);

      if (loginResult == null) {
        
        globalConnectionStatus =connectionStatus_notConnected;
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
               globalConnectionStatus =connectionStatus_connected;
              if (userId == null) {
                Navigator.of(context).pushReplacementNamed(RouteNames.INTRO_SLIDER.toString());
              } else {
                final Database db = await DBProvider.db.database;

                final SyncUserDataService cSrv = SyncUserDataService();
                final bool result = await cSrv.updateFromBackend(db, SyncUserDataService.flagAllMasterData, false);
                final String resultStr = result ? 'successfully' : 'unsuccessfully';
                print('Master data synchronized $resultStr');

                Navigator.pushReplacement<dynamic, dynamic>(context, MaterialPageRoute<dynamic>(builder: (BuildContext context) => const MainNavigationPage()));
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
    await Future<dynamic>.delayed(const Duration(seconds:SPLASH_SCREEN_DISPLAY_TIME));
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
    return Image.asset('images/init/splash_screen.jpg');
  }
}
