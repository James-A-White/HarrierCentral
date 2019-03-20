import 'dart:async';

import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart';

import 'package:harrier_central/data_models/approve_login_model.dart';
import 'package:harrier_central/pages/top_level/main_navigation_page.dart';
import 'package:harrier_central/services/approve_login_service.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/routes.dart';


class AppEntryPage extends StatefulWidget {
  @override
  _AppEntryPageState createState() => _AppEntryPageState();
}

class _AppEntryPageState extends State<AppEntryPage>
    with SingleTickerProviderStateMixin {
  AnimationController _iconAnimationController;
  CurvedAnimation _iconAnimation;

  void handleTimeout() async {

    await PermissionHandler()
        .requestPermissions([PermissionGroup.camera, PermissionGroup.location]);

    final String userId = Preferences.getStringPref(StringPrefsEnum.userId);

    ApproveLoginService svc = ApproveLoginService();
    await svc.approveLogin().then((ApproveLoginModel loginResult) async {
      bool allowContinueFromMessage = true;

      if (loginResult.messageDisplayType != loginMessageTypeNone.value) {
        if (loginResult.messageDisplayType == loginMessageTypeAlert.value) {
          bool buttonStatus = await _displayAlert(context,loginResult.loginMessage,loginResult.loginMessageTitle);
        }
      }

      if (allowContinueFromMessage) {
        if (loginResult.serverStatusCode == serverStatusUp.value) {
          if (loginResult.approvalCode == loginApprovalApproved.value) {
            if (userId == null) {
              //if (true) {
              Navigator.of(context)
                  .pushNamed(RouteNames.NEW_ACCOUNT.toString());
              //     .then<dynamic>((void test) {
              //   _iconAnimationController.dispose();
              // }
              // );
            } else {
              Navigator.pushReplacement<dynamic, dynamic>(
                  context,
                  MaterialPageRoute<dynamic>(
                      builder: (BuildContext context) => MainNavigationPage()));
              //     .then<dynamic>((void test) {
              //    _iconAnimationController.dispose();
              // });
            }
          } else {
            // TODO: Handle cases where login is disapproved
          }
        } else {
          // TODO: Handle cases where server is down
        }
      } else {
        // TODO: Handle case where not allowed to continue after a message
      }
    });
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
                  style: const TextStyle(
                      fontFamily: 'AvenirNextRegular',
                      fontStyle: FontStyle.normal,
                      fontSize: 16.0,
                      height: 1.0),
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

  dynamic startTimeout() async {
    Preferences.initPrefs().then((void dummy) {});




    return Timer(const Duration(seconds: SPLASH_SCREEN_DISPLAY_TIME), handleTimeout);
  }

  //bool _visible = true;
  @override
  void initState() {
    super.initState();

    _iconAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000));

    _iconAnimation =
        CurvedAnimation(parent: _iconAnimationController, curve: Curves.easeIn);
    _iconAnimation.addListener(() => setState(() {}));

    _iconAnimationController.forward();


    startTimeout();
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset('images/init/splash_screen.jpg');
  }
}
