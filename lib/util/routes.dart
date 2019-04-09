import 'package:flutter/material.dart';

import 'package:harrier_central/pages/facebook_login.dart';
import 'package:harrier_central/pages/init/login_page.dart';
import 'package:harrier_central/pages/init/avatar_icons_page.dart';
import 'package:harrier_central/pages/init/intro_slider.dart';
import 'package:harrier_central/pages/top_level/main_navigation_page.dart';
import 'package:harrier_central/pages/top_level/user_qr_code_page.dart';

enum RouteNames {
  FACEBOOK_LOGIN,
  MAIN_LANDING_PAGE,
  //CHOOSE_PROFILE_IMAGE,
  AVATAR_ICON_PAGE,
  NEW_ACCOUNT,
  INTRO_SLIDER,
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
  //RouteNames.CHOOSE_PROFILE_IMAGE.toString(): (BuildContext context) => ChooseProfileImage(isInitFlow: true),
  RouteNames.USER_QR_CODE.toString(): (BuildContext context) =>
      const UserQrCodePage(),
  RouteNames.AVATAR_ICON_PAGE.toString(): (BuildContext context) =>
      const AvatarIconsPage(),
};
