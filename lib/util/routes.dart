import 'package:flutter/material.dart';

import 'package:harrier_central/pages/facebook_login.dart';
import 'package:harrier_central/pages/init/login_page.dart';
import 'package:harrier_central/pages/init/avatar_icons_page.dart';
import 'package:harrier_central/pages/init/choose_avatar.dart';
import 'package:harrier_central/pages/top_level/main_navigation_page.dart';
import 'package:harrier_central/pages/top_level/user_qr_code_page.dart';

enum RouteNames {
  FACEBOOK_LOGIN,
  MAIN_LANDING_PAGE,
  CHOOSE_AVATAR,
  AVATAR_ICON_PAGE,
  NEW_ACCOUNT,
  USER_QR_CODE,
}

class Routes {
  static final Map<String, WidgetBuilder>routes = <String, WidgetBuilder>{
    RouteNames.FACEBOOK_LOGIN.toString(): (BuildContext context) => FbLoginPage(),
    RouteNames.MAIN_LANDING_PAGE.toString(): (BuildContext context) => MainNavigationPage(),
    RouteNames.NEW_ACCOUNT.toString(): (BuildContext context) => const LoginPage(),
    RouteNames.CHOOSE_AVATAR.toString(): (BuildContext context) => const ChooseAvatarPage(),
    RouteNames.USER_QR_CODE.toString(): (BuildContext context) => UserQrCodePage(),
    RouteNames.AVATAR_ICON_PAGE.toString(): (BuildContext context) => AvatarIconsPage(),

  };
}
