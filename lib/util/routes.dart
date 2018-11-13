import 'package:flutter/material.dart';

import 'package:harrier_central/pages/facebook_login.dart';
import 'package:harrier_central/pages/init/login_page.dart';
import 'package:harrier_central/pages/top_level/main_navigation_page.dart';
import 'package:harrier_central/pages/top_level/user_qr_code_page.dart';


enum RouteNames {
  FACEBOOK_LOGIN,
  MAIN_NAVIGATION,
  NEW_ACCOUNT,
  USER_QR_CODE
}

class Routes {
  static final Map<String, WidgetBuilder>routes = <String, WidgetBuilder>{
    RouteNames.FACEBOOK_LOGIN.toString(): (BuildContext context) => FbLoginPage(),
    RouteNames.MAIN_NAVIGATION.toString(): (BuildContext context) => MainNavigationPage(),
    RouteNames.NEW_ACCOUNT.toString(): (BuildContext context) => const LoginPage(),
    RouteNames.USER_QR_CODE.toString(): (BuildContext context) => UserQrCodePage(),
  };
}
