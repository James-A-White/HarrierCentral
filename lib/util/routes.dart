import 'package:flutter/material.dart';

import 'package:harrier_central/pages/facebook_login.dart';
import 'package:harrier_central/pages/init/get_started_slider.dart';
import 'package:harrier_central/pages/init/login_page.dart';
import 'package:harrier_central/pages/init/avatar_icons_page.dart';
import 'package:harrier_central/pages/init/intro_slider.dart';
import 'package:harrier_central/pages/init/permissions_photo.dart';
import 'package:harrier_central/pages/init/permissions_notification.dart';
import 'package:harrier_central/pages/top_level/main_navigation_page.dart';
import 'package:harrier_central/pages/top_level/user_qr_code_page.dart';

enum RouteNames {
  FACEBOOK_LOGIN,
  MAIN_LANDING_PAGE,
  AVATAR_ICON_PAGE,
  NEW_ACCOUNT,
  INTRO_SLIDER,
  PERMISSION_PHOTO_SLIDER,
  PERMISSION_NOTIFICATION_SLIDER,
  GET_STARTED_SLIDER,
  USER_QR_CODE,
}

final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
  RouteNames.FACEBOOK_LOGIN.toString(): (BuildContext context) => FbLoginPage(),
  RouteNames.MAIN_LANDING_PAGE.toString(): (BuildContext context) =>
      const MainNavigationPage(),
  RouteNames.NEW_ACCOUNT.toString(): (BuildContext context) =>
      const LoginPage(),
  RouteNames.INTRO_SLIDER.toString(): (BuildContext context) =>
      const IntroSliderPage(),
  RouteNames.PERMISSION_PHOTO_SLIDER.toString(): (BuildContext context) =>
      const PhotoPermissionSliderPage(),
  RouteNames.PERMISSION_NOTIFICATION_SLIDER.toString(): (BuildContext context) =>
      const NotificationPermissionSliderPage(),
  RouteNames.GET_STARTED_SLIDER.toString(): (BuildContext context) =>
      const GetStartedSliderPage(),
  RouteNames.USER_QR_CODE.toString(): (BuildContext context) =>
      const UserQrCodePage(),
  RouteNames.AVATAR_ICON_PAGE.toString(): (BuildContext context) =>
      const AvatarIconsPage(),
};
