import 'package:harrier_central/imports.dart';
import 'package:harrier_central/pages/menu_pages/add_kennel_page.dart';
//import 'package:harrier_central/pages/menu_pages/app_download_page.dart';
// import 'package:harrier_central/pages/menu_pages/payment_terminal_config_page.dart';

class DrawerMenu extends StatefulWidget {
  const DrawerMenu({
    super.key,
    required this.scaffoldKey,
    required this.futureRunsListKey,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final GlobalKey<FutureRunListPageState> futureRunsListKey;

  @override
  DrawerMenuState createState() => DrawerMenuState();
}

class DrawerMenuState extends State<DrawerMenu> {
  void onTabTapped(EnumAppPages page) {
    Navigator.pop(context);
  }

  static const int opacity = 160;
  static const Color textColor = Color.fromARGB(opacity, 255, 255, 255);

  final TextStyle _style = ts_large;

  final String _userId = getStringPref(StringPrefsEnum.userId)!;

  @override
  Widget build(BuildContext context) {
    return TextScaleFactorClamper(
      textScaleFactor: G0<DeviceInfo>().textClamp15,
      child: Drawer(
        //elevation: 120,
        child: Stack(clipBehavior: Clip.hardEdge, children: <Widget>[
          Positioned(
            top: 0,
            left: 0,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Image.asset('images/other/drawer_image.jpg',
                      fit: BoxFit.fill,
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width),
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
                  leading: const Icon(FontAwesome.trophy, color: textColor),
                  title: Text('Global Leaders', style: _style),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            const GenericWidgetPage(
                          key: Key('52233311'),
                          widget: Column(
                            children: <Widget>[
                              // Padding(
                              //   padding: const EdgeInsets.only(top: 18.0, bottom: 10.0),
                              //   child: Image.asset('images/icons/leaderboard_icon.png', height: 130),
                              // ),
                              //SizedBox(height: 13.0),
                              Expanded(
                                child: Leaderboard(
                                  kennelId: null,
                                ),
                              ),
                            ],
                          ),
                          appBarTitle: 'Get a Life (Leaderboards)',
                        ),
                      ),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(MaterialIcons.house, color: textColor),
                  title: Text('Add a Kennel', style: _style),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push<dynamic>(
                      context,
                      MaterialPageRoute<dynamic>(
                        settings: const RouteSettings(),
                        builder: (BuildContext context) {
                          return const AddKennelPage();
                        },
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person, color: textColor),
                  title: Text('My Profile', style: _style),
                  onTap: () async {
                    //onTabTapped(EnumAppPages.settings);
                    //final String userId = getStringPref(StringPrefsEnum.userId);
                    Navigator.pop(context);
                    await Navigator.push<dynamic>(
                      context,
                      MaterialPageRoute<dynamic>(
                        settings: const RouteSettings(),
                        builder: (BuildContext context) {
                          return HasherProfilePage(
                              dataContext: EnumDataContext.user,
                              pageType: EnumMyProfilePageType.myProfile,
                              hasherId: _userId,
                              uiElementsToDisplay: HasherProfilePage
                                      .flagUiElement_distancePref |
                                  HasherProfilePage
                                      .flagUiElement_autoDisplayRunsDistance |
                                  HasherProfilePage
                                      .flagUiElement_logOutAndRefreshButton |
                                  HasherProfilePage
                                      .flagUiElement_refresh3rdPartyLogin |
                                  HasherProfilePage
                                      .flagUiElement_gdprDeleteAccount);
                        },
                      ),
                    );
                    if (futureRunsListPageKey.currentState != null) {
                      await futureRunsListPageKey.currentState!
                          .forceRefreshFromTableExternal();
                    }
                  },
                ),
                // ListTile(
                //   leading: const Icon(Icons.shopping_cart, color: textColor),
                //   title: Text('In App Purchases', style: _style),
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
                  title: Text('FAQs', style: _style),
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
                  title: Text('Imprint', style: _style),
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
                    ).then(
                      (dynamic value) {
                        if (widget.scaffoldKey.currentState != null) {
                          widget.scaffoldKey.currentState!.setState(() {});
                        }
                      },
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(FontAwesome.legal, color: textColor),
                  title: Text('Legal', style: _style),
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
                  title: Text('Privacy Policy', style: _style),
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

                // ListTile(
                //   leading: const Icon(MaterialCommunityIcons.cloud_download, color: textColor),
                //   title: Text('App Download Links', style: _style),
                //   onTap: () {
                //     Navigator.pop(context);
                //     Navigator.push<dynamic>(
                //       context,
                //       MaterialPageRoute<dynamic>(
                //         settings: const RouteSettings(),
                //         builder: (BuildContext context) {
                //           return const AppDownloadPage();
                //         },
                //       ),
                //     );
                //   },
                // ),
                // if (Utilities.isOpeeOrTuna()) ...<Widget>[
                //   ListTile(
                //     leading: const Icon(FontAwesome.question_circle, color: textColor),
                //     title: Text('Payment Terminal', style: _style),
                //     onTap: () {
                //       Navigator.pop(context);
                //       Navigator.push<dynamic>(
                //         context,
                //         MaterialPageRoute<dynamic>(
                //           settings: const RouteSettings(),
                //           builder: (BuildContext context) {
                //             return const PaymentTerminalConfigPage();
                //           },
                //         ),
                //       );
                //     },
                //   ),
                // ],

                ListTile(
                  leading: const Icon(FontAwesome.support, color: textColor),
                  title: Text('Support', style: _style),
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
                // ListTile(
                //   leading: const Icon(Icons.integration_instructions, color: textColor),
                //   title: Text('Data integrations', style: style),
                //   onTap: () {
                //     Navigator.pop(context);
                //     Navigator.push<dynamic>(
                //       context,
                //       MaterialPageRoute<dynamic>(
                //         settings: const RouteSettings(),
                //         builder: (BuildContext context) {
                //           return const IntegrationPage();
                //         },
                //       ),
                //     );
                //   },
                // ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
