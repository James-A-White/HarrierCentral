// @dart=2.11
import 'package:harrier_central/imports.dart';

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
  //RouteNames.FACEBOOK_LOGIN.toString(): (BuildContext context) => ThirdPartyLogin(true),
  RouteNames.MAIN_LANDING_PAGE.toString(): (BuildContext context) => const MainNavigationPage(
        promos: <PromoModel>[],
        firstPromoImage: null,
      ),
  RouteNames.NEW_ACCOUNT.toString(): (BuildContext context) => const NewAccountPage(),
  RouteNames.INTRO_SLIDER.toString(): (BuildContext context) => const IntroSliderPage(),
  RouteNames.PERMISSIONS_SLIDER.toString(): (BuildContext context) => const PermissionSliderPage(),
  RouteNames.USER_QR_CODE.toString(): (BuildContext context) => const UserQrCodePage(),
  RouteNames.AVATAR_ICON_PAGE.toString(): (BuildContext context) => const AvatarIconsPage(),
};
