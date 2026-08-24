// ignore_for_file: constant_identifier_names

import 'package:harrier_central/imports.dart';

enum RouteNames {
  MAIN_LANDING_PAGE,
  AVATAR_ICON_PAGE,
  NEW_ACCOUNT,
  ACCOUNT_QUESTION,
  PERMISSION_PHOTO_SLIDER,
  PERMISSION_NOTIFICATION_SLIDER,
  GET_STARTED_SLIDER,
  USER_QR_CODE,
  GUEST_DISCOVERY,
}

final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
  RouteNames.MAIN_LANDING_PAGE.toString(): (BuildContext context) =>
      const MainNavigationPage(),
  RouteNames.NEW_ACCOUNT.toString(): (BuildContext context) =>
      const NewAccountPage(),
  RouteNames.ACCOUNT_QUESTION.toString(): (BuildContext context) =>
      const AccountQuestionPage(),
  RouteNames.USER_QR_CODE.toString(): (BuildContext context) =>
      const UserQrCodePage(),
  RouteNames.AVATAR_ICON_PAGE.toString(): (BuildContext context) =>
      const AvatarIconsPage(),
};
