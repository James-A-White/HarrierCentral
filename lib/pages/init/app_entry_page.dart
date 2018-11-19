import 'dart:async';

import 'package:flutter/material.dart';
import 'package:harrier_central/pages/top_level/main_navigation_page.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/routes.dart';
import 'package:harrier_central/util/preferences.dart';

class AppEntryPage extends StatefulWidget {

  @override
  _AppEntryPageState createState() => _AppEntryPageState();
}

class _AppEntryPageState extends State<AppEntryPage>
    with SingleTickerProviderStateMixin {
  AnimationController _iconAnimationController;
  CurvedAnimation _iconAnimation;

  void handleTimeout() {
    final String userId = Preferences.getStringPref(StringPrefsEnum.userId);

    if (userId == null) {
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
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    super.dispose();
  }

  dynamic startTimeout() async {
    Preferences.initPrefs().then((void dummy) {
    });

    return Timer(Duration(seconds: SPLASH_SCREEN_DISPLAY_TIME), handleTimeout);
  }

  //bool _visible = true;
  @override
  void initState() {
    super.initState();

    _iconAnimationController = AnimationController(
        vsync: this, duration: Duration(milliseconds: 3000));

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
