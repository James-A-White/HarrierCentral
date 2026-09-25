import 'package:harrier_central/imports.dart';
import 'package:harrier_central/pages/menu_pages/add_kennel_page.dart';

class DrawerMenu extends StatefulWidget {
  const DrawerMenu({
    super.key,
    //required this.ScaffoldKey,
    //required this.futureRunsListKey,
  });

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

  final String _userId = currentUserId;

  // Whether to show the "Admin Portal" item (admins of any kennel only).
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadAdminStatus());
  }

  Future<void> _loadAdminStatus() async {
    final isAdmin = await QueryKennels.isUserAdminOfAnyKennel();
    if (mounted) setState(() => _isAdmin = isAdmin);
  }

  /// Same-device portal login: register a one-time auth code, then open the
  /// portal at `…/#authCode=<code>` so it logs in without scanning a QR.
  /// The code is passed in the URL *fragment* (not the query string) so it is
  /// never transmitted to — or logged by — any server.
  Future<void> _openAdminPortal() async {
    Navigator.pop(context);
    final authCode = const Uuid().v4();
    final result = await AuthenticateWebPortalService().authenticateWebPortal(
      authCode,
    );
    if (result?.result == 'Success') {
      await launchUrl(
        Uri.parse('$PORTAL_URL/#authCode=$authCode'),
        mode: LaunchMode.externalApplication,
      );
    } else {
      Get.snackbar(
        'Admin Portal',
        'Could not start a portal session. Please check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextScaleFactorClamper(
      textScaleFactor: deviceInfo.textClamp15,
      child: Drawer(
        //elevation: 120,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: <Widget>[
            Positioned(
              top: 0,
              left: 0,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Image.asset(
                      'images/other/drawer_image.jpg',
                      fit: BoxFit.fill,
                      height: MediaQuery.sizeOf(context).height,
                      width: MediaQuery.sizeOf(context).width,
                    ),
                  ],
                ),
              ),
            ),
            // IntrinsicHeight(child:Image.asset('images/other/drawer_image.jpg',height: 1000, width:800,),),
            // Bounded top and bottom, and scrollable: on a small phone the
            // admins' menu (11 items) is taller than the screen, and Admin
            // Portal sat half under the gesture bar where it could not be
            // reached (360 x 640 dp, 2026-09-25). Where it fits, which is
            // every larger phone, nothing scrolls and nothing moves.
            Positioned(
              top: 40,
              bottom: 0,
              width: MediaQuery.sizeOf(context).width,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewPaddingOf(context).bottom + 8,
                ),
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(FontAwesome.trophy, color: textColor),
                      title: Text('Global Leaders', style: _style),
                      onTap: () async {
                        Navigator.pop(context);
                        await Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) =>
                                const GenericWidgetPage(
                                  key: Key('52233311'),
                                  widget: Column(
                                    children: <Widget>[
                                      Expanded(
                                        child: Leaderboard(kennelId: null),
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
                      leading: const Icon(
                        MaterialIcons.house,
                        color: textColor,
                      ),
                      title: Text('Add a Kennel', style: _style),
                      onTap: () async {
                        Navigator.pop(context);
                        await Navigator.push<dynamic>(
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
                      title: Text('My Account', style: _style),
                      onTap: () async {
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
                                uiElementsToDisplay:
                                    HasherProfilePage
                                        .flagUiElement_autoDisplayRunsDistance |
                                    HasherProfilePage
                                        .flagUiElement_refresh3rdPartyLogin |
                                    HasherProfilePage
                                        .flagUiElement_logOutButton |
                                    HasherProfilePage
                                        .flagUiElement_gdprDeleteAccount,
                              );
                            },
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings, color: textColor),
                      title: Text('Settings', style: _style),
                      onTap: () async {
                        Navigator.pop(context);
                        await Navigator.push<dynamic>(
                          context,
                          MaterialPageRoute<dynamic>(
                            settings: const RouteSettings(),
                            builder: (BuildContext context) {
                              return const SettingsPage();
                            },
                          ),
                        );
                      },
                    ),
                    //     Navigator.push<dynamic>(
                    //       context,
                    //       MaterialPageRoute<dynamic>(
                    //         },
                    //   },
                    //   },
                    // ),
                    ListTile(
                      leading: const Icon(
                        FontAwesome.question_circle,
                        color: textColor,
                      ),
                      title: Text('FAQs', style: _style),
                      onTap: () async {
                        Navigator.pop(context);
                        await Navigator.push<dynamic>(
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
                    //     Navigator.push<dynamic>(
                    //       context,
                    //       MaterialPageRoute<dynamic>(
                    //         },
                    //   },
                    // ),
                    ListTile(
                      leading: const Icon(
                        Icons.speaker_notes,
                        color: textColor,
                      ),
                      title: Text('Imprint', style: _style),
                      onTap: () async {
                        Navigator.pop(context);
                        await Navigator.push<dynamic>(
                          context,
                          MaterialPageRoute<dynamic>(
                            settings: const RouteSettings(),
                            builder: (BuildContext context) {
                              return const ImprintPage();
                            },
                          ),
                          //   },
                        );
                      },
                    ),

                    ListTile(
                      leading: const Icon(FontAwesome.legal, color: textColor),
                      title: Text('Legal', style: _style),
                      onTap: () async {
                        Navigator.pop(context);
                        await Navigator.push<dynamic>(
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
                      leading: const Icon(
                        MaterialCommunityIcons.shield_lock,
                        color: textColor,
                      ),
                      title: Text('Privacy Policy', style: _style),
                      onTap: () async {
                        Navigator.pop(context);
                        await Navigator.push<dynamic>(
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

                    //     Navigator.push<dynamic>(
                    //       context,
                    //       MaterialPageRoute<dynamic>(
                    //         },
                    //   },
                    //       Navigator.push<dynamic>(
                    //         context,
                    //         MaterialPageRoute<dynamic>(
                    //           },
                    //     },
                    //   ),
                    // ],
                    ListTile(
                      leading: const Icon(Icons.upload_file, color: textColor),
                      title: Text('Import Tracks', style: _style),
                      onTap: () async {
                        Navigator.pop(context);
                        await Navigator.push<dynamic>(
                          context,
                          MaterialPageRoute<dynamic>(
                            settings: const RouteSettings(),
                            builder: (BuildContext context) {
                              return const ImportGpxPage();
                            },
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        FontAwesome.support,
                        color: textColor,
                      ),
                      title: Text('Support', style: _style),
                      onTap: () async {
                        //onTabTapped(EnumAppPages.settings);
                        Navigator.pop(context);
                        await Navigator.push<dynamic>(
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
                    // Admin Portal sits at the bottom of the menu (admins only).
                    if (_isAdmin)
                      ListTile(
                        leading: const Icon(
                          Icons.admin_panel_settings,
                          color: textColor,
                        ),
                        title: Text('Admin Portal', style: _style),
                        onTap: _openAdminPortal,
                      ),
                    //     Navigator.push<dynamic>(
                    //       context,
                    //       MaterialPageRoute<dynamic>(
                    //         },
                    //   },
                    // ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
