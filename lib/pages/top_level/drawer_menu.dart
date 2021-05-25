import 'package:harrier_central/imports.dart';
import 'package:harrier_central/pages/menu_pages/app_download_page.dart';

class DrawerMenu extends StatefulWidget {
  const DrawerMenu({Key key, this.scaffoldKey}) : super(key: key);

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  DrawerMenuState createState() => DrawerMenuState();
}

class DrawerMenuState extends State<DrawerMenu> {
  void onTabTapped(EnumAppPages page) {
    Navigator.pop(context);
  }

  static const int opacity = 160;
  static const Color textColor = Color.fromARGB(opacity, 255, 255, 255);

  TextStyle style = const TextStyle(
      fontFamily: 'AvenirNext',
      fontStyle: FontStyle.normal,
      color: textColor,
      fontSize: 24.0,
      height: 1.0);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      //elevation: 120,
      child: Stack(overflow: Overflow.clip, children: <Widget>[
        Positioned(
          top: 0,
          left: 0,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  // decoration: const BoxDecoration(
                  //   image: const DecorationImage(
                  //     fit: BoxFit.fill,
                  //     image: const AssetImage("images/other/drawer_image.jpg"),
                  //   ),
                  // ),
                  child: Image.asset('images/other/drawer_image.jpg',
                      fit: BoxFit.fill,
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width),
                ),
              ],
            ),
          ),
        ),
        // IntrinsicHeight(child:Image.asset('images/other/drawer_image.jpg',height: 1000, width:800,),),
        Positioned(
          //top:50,
          //top:10,
          top: 40,
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: <Widget>[
              // ListTile(
              //   leading: const Icon(Icons.settings, color: textColor),
              //   title: Text('Settings', style: style),
              //   onTap: () async {
              //     Navigator.pop(context);
              //     Navigator.push<dynamic>(
              //       context,
              //       MaterialPageRoute<dynamic>(
              //         settings: const RouteSettings(),
              //         builder: (BuildContext context) {
              //           return const SettingsPage();
              //         },
              //       ),
              //     );
              //   },
              // ),
              ListTile(
                leading: const Icon(Icons.person, color: textColor),
                title: Text('My Profile', style: style),
                onTap: () async {
                  //onTabTapped(EnumAppPages.settings);
                  final String userId = getStringPref(StringPrefsEnum.userId);
                  Navigator.pop(context);
                  Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                      settings: const RouteSettings(),
                      builder: (BuildContext context) {
                        return HasherProfilePage(
                          dataContext: EnumDataContext.user,
                          pageType: EnumMyProfilePageType.myProfile,
                          hasherId: userId,
                          uiElementsToDisplay:
                              HasherProfilePage.flagUiElement_distancePref |
                                  HasherProfilePage
                                      .flagUiElement_autoDisplayRunsDistance,
                        );
                      },
                    ),
                  );
                },
              ),
              // ListTile(
              //   leading: const Icon(Icons.shopping_cart, color: textColor),
              //   title: Text('In App Purchases', style: style),
              //   onTap: () async {
              //     Navigator.pop(context);
              //     Navigator.push<dynamic>(
              //       context,
              //       MaterialPageRoute<dynamic>(
              //         settings: const RouteSettings(),
              //         builder: (BuildContext context) {
              //           return const InAppPurchasePage();
              //         },
              //       ),
              //     );
              //   },
              // ),
              // ListTile(
              //   leading:const  Icon(Icons.speaker_notes),
              //   title: const Text('Acknowledgements'),
              //   onTap: () {
              //     Navigator.pop(context);
              //     onTabTapped(3);
              //   },
              // ),
              ListTile(
                leading:
                    const Icon(FontAwesome.question_circle, color: textColor),
                title: Text('FAQs', style: style),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                      settings: const RouteSettings(),
                      builder: (BuildContext context) {
                        return const FaqPage();
                      },
                    ),
                  );
                },
              ),
              // ListTile(
              //   leading: const Icon(Icons.feedback, color: textColor),
              //   title: Text('Your feedback', style: style),
              //   onTap: () {
              //     Navigator.pop(context);
              //     Navigator.push<dynamic>(
              //       context,
              //       MaterialPageRoute<dynamic>(
              //         settings: const RouteSettings(),
              //         builder: (BuildContext context) {
              //           return const UserFeedbackPage();
              //         },
              //       ),
              //     );
              //   },
              // ),
              ListTile(
                leading: const Icon(Icons.speaker_notes, color: textColor),
                title: Text('Imprint', style: style),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                      settings: const RouteSettings(),
                      builder: (BuildContext context) {
                        return const ImprintPage();
                      },
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(FontAwesome.legal, color: textColor),
                title: Text('Legal', style: style),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                      settings: const RouteSettings(),
                      builder: (BuildContext context) {
                        return const LegalPage();
                      },
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(MaterialCommunityIcons.shield_lock,
                    color: textColor),
                title: Text('Privacy Policy', style: style),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                      settings: const RouteSettings(),
                      builder: (BuildContext context) {
                        return const PrivacyPolicyPage();
                      },
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(MaterialCommunityIcons.cloud_download,
                    color: textColor),
                title: Text('App Download Links', style: style),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                      settings: const RouteSettings(),
                      builder: (BuildContext context) {
                        return const AppDownloadPage();
                      },
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(FontAwesome.support, color: textColor),
                title: Text('Support', style: style),
                onTap: () async {
                  //onTabTapped(EnumAppPages.settings);
                  Navigator.pop(context);
                  Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                      settings: const RouteSettings(),
                      builder: (BuildContext context) {
                        return const SupportPage();
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
