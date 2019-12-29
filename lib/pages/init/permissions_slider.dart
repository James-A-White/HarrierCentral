import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:intro_slider/intro_slider.dart';
import 'package:intro_slider/slide_object.dart';

import 'package:permission_handler/permission_handler.dart';

import 'package:harrier_central/notifications/notification_support.dart';
import 'package:harrier_central/util/routes.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/globals.dart';

class PermissionSliderPage extends StatefulWidget {
  const PermissionSliderPage({Key key}) : super(key: key);

  @override
  _PermissionSliderPageState createState() => _PermissionSliderPageState();
}

class _PermissionSliderPageState extends State<PermissionSliderPage> {
  List<Slide> slides = <Slide>[];

  TextStyle titleStyle;

  TextStyle descriptionStyle;

  TextStyle navStyle;

  Function goToTab;

  @override
  void initState() {
    super.initState();

    descriptionStyle = TextStyle(color: Colors.black, fontSize: 24.0 * deviceWidthScaleFactor, fontFamily: 'AvenirNextRegular');
    titleStyle = TextStyle(color: Colors.black, fontSize: 32.0 * deviceWidthScaleFactor, fontFamily: 'AvenirNextRegular');
    navStyle = TextStyle(color: themeAppBarBackground, fontSize: 18.0 * deviceWidthScaleFactor, fontFamily: 'AvenirNextDemiBold');

    slides.add(
      Slide(
        title: 'Let us know where you are!',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description: 'This lets us find the Hash events closest to you',
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_phone_location.png',
        heightImage: 140 * deviceMaxScaleFactor,
        colorBegin: const Color.fromARGB(255, 230, 203, 203),
        colorEnd: const Color.fromARGB(255, 230, 203, 203),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );

    slides.add(
      Slide(
        title: 'Smile for the camera!',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description: 'Can we access your camera for your profile photo and to scan QR codes?',
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_old_camera.png',
        heightImage: 120 * deviceMaxScaleFactor,
        colorBegin: const Color.fromARGB(255, 222, 215, 252),
        colorEnd: const Color.fromARGB(255, 222, 215, 252),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );

    slides.add(
      Slide(
        title: 'Keep up to date',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description: 'Let us notify you about changes to runs you are following',
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_notification.png',
        heightImage: 150 * deviceMaxScaleFactor,
        colorBegin: const Color.fromARGB(255, 252, 212, 212),
        colorEnd: const Color.fromARGB(255, 252, 212, 212),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );

    slides.add(
      Slide(
        title: 'Some Last\r\nDetails',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description: 'Please Provide Just a Tiny Bit of Personal Information...',
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_pen.png',
        heightImage: 150 * deviceMaxScaleFactor,
        colorBegin: const Color.fromARGB(255, 227, 227, 227),
        colorEnd: const Color.fromARGB(255, 227, 227, 227),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
  }

  Future<void> onDonePress() async {
    Navigator.of(context).pushReplacementNamed(RouteNames.NEW_ACCOUNT.toString());
  }

  bool permission1requested = false;
  bool permission2requested = false;
  bool permission3requested = false;

  int activeTab = 0;

  void onTabChangeCompleted(num index) {
    activeTab = index;
  }

  Widget renderNextBtn() {
    return GestureDetector(
        child: Text('Allow', style: navStyle),
        onTap: () {
          if (activeTab == 0) {
            PermissionHandler().requestPermissions(<PermissionGroup>[PermissionGroup.location]).then((Map<PermissionGroup, PermissionStatus> e) {
              goToTab(1);
            });
          }

          if (activeTab == 1) {
            PermissionHandler().requestPermissions(<PermissionGroup>[PermissionGroup.camera, PermissionGroup.photos]).then((Map<PermissionGroup, PermissionStatus> e) {
              goToTab(2);
            });
          }

          if (activeTab == 2) {
            final NotificationSupport notifications = NotificationSupport();
            notifications.configureNotifications(false);
            goToTab(3);
          }
        });
  }

  Widget renderDoneBtn() {
    return Text('OK', style: navStyle);
  }

  IntroSlider slider;

  Widget renderSkipBtn() {
    return Text('Skip', style: navStyle);
  }

  Future<void> onSkipPress() async {
    if (activeTab == 0) {
      Utilities.showAlert(context, 'Location Preference', 'if you do not allow Harrier Central to detect your location the app will not be able to find the closest Hash runs along with other important features.', 'Allow', showCancelButton: true, cancelButtonText: 'Disallow').then((bool allow) {
        if (allow) {
          PermissionHandler().requestPermissions(<PermissionGroup>[PermissionGroup.location]).then((Map<PermissionGroup, PermissionStatus> e) {
            goToTab(1);
          });
        } else {
          goToTab(1);
        }
      });
    }

    if (activeTab == 1) {
      Utilities.showAlert(context, 'Camera Preference', 'if you do not allow Harrier Central to access your camera you will not be able to scan QR codes to check in to runs or take a profile photo.', 'Allow', showCancelButton: true, cancelButtonText: 'Disallow').then((bool allow) {
        if (allow) {
          PermissionHandler().requestPermissions(<PermissionGroup>[PermissionGroup.camera, PermissionGroup.photos]).then((Map<PermissionGroup, PermissionStatus> e) {
            goToTab(2);
          });
        } else {
          goToTab(2);
        }
      });
    }

    if (activeTab == 2) {
      Utilities.showAlert(context, 'Notification Preference', 'if you do not allow Harrier Central to send notification you will not be alerted when details of upcomign runs change', 'Allow', showCancelButton: true, cancelButtonText: 'Disallow').then((bool allow) {
        if (allow) {
          final NotificationSupport notifications = NotificationSupport();
          notifications.configureNotifications(false);
        }
        goToTab(3);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntroSlider(
      // List slides
      slides: slides,

      // Skip button
      renderSkipBtn: renderSkipBtn(),
      colorSkipBtn: const Color(0x00000000),
      highlightColorSkipBtn: const Color(0xff000000),
      onSkipPress: onSkipPress,
      isShowSkipBtn: true,

      onTabChangeCompleted: onTabChangeCompleted,

      // Dot indicator
      isShowDotIndicator: true,
      colorDot: themeAppBarBackground40,
      colorActiveDot: themeAppBarBackground,
      sizeDot: 6.0,

      // Next button
      renderNextBtn: renderNextBtn(),

      // Done button
      renderDoneBtn: renderDoneBtn(),
      onDonePress: onDonePress,
      colorDoneBtn: const Color(0x00000000),
      highlightColorDoneBtn: const Color(0xff000000),

      // Show or hide status bar
      shouldHideStatusBar: true,

      refFuncGoToTab: (dynamic refFunc) {
        goToTab = refFunc;
      },
    );
  }
}
