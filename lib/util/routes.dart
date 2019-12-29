import 'package:flutter/material.dart';

import 'package:harrier_central/pages/facebook_login.dart';
import 'package:harrier_central/pages/init/avatar_icons_page.dart';
import 'package:harrier_central/pages/init/intro_slider.dart';
import 'package:harrier_central/pages/init/new_account.dart';
import 'package:harrier_central/pages/init/permissions_slider.dart';
import 'package:harrier_central/pages/top_level/main_navigation_page.dart';
import 'package:harrier_central/pages/top_level/user_qr_code_page.dart';

enum RouteNames {
  FACEBOOK_LOGIN,
  MAIN_LANDING_PAGE,
  AVATAR_ICON_PAGE,
  NEW_ACCOUNT,
  INTRO_SLIDER,
  PERMISSIONS_SLIDER,
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
      const NewAccountPage(),
  RouteNames.INTRO_SLIDER.toString(): (BuildContext context) =>
      const IntroSliderPage(),
  RouteNames.PERMISSIONS_SLIDER.toString(): (BuildContext context) =>
      const PermissionSliderPage(),
  RouteNames.USER_QR_CODE.toString(): (BuildContext context) =>
      const UserQrCodePage(),
  RouteNames.AVATAR_ICON_PAGE.toString(): (BuildContext context) =>
      const AvatarIconsPage(),
};
