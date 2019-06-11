

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:sqflite/sqflite.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:fancy_bottom_navigation/fancy_bottom_navigation.dart';

import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/widgets/offline_mode_ribbon.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/pages/top_level/history_list_page.dart';
import 'package:harrier_central/pages/top_level/future_run_list_page.dart';
import 'package:harrier_central/pages/top_level/drawer_menu.dart';
import 'package:harrier_central/pages/top_level/kennel_list_page.dart';
import 'package:harrier_central/pages/top_level/user_qr_code_page.dart';
import 'package:harrier_central/database/database.dart';


class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({Key key}) : super(key: key);

  @override
  _MainNavigationPageState createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  //MainNavigationScopedModel homePageModel = MainNavigationScopedModel();

  List<Widget> tabs = <Widget>[];
  List<String> tabTitles = <String>[];

  String appBarText;
  String initializationMessage = '';

  @override
  void initState() {
    tabs.add(const FutureRunsListPage());
    tabs.add(const KennelsListPage());
    tabs.add(const UserQrCodePage());
    tabs.add(const UserQrCodePage());
    tabs.add(const UserQrCodePage());

    tabTitles.add('Upcoming Runs');
    tabTitles.add('Kennels');
    tabTitles.add('Your Total Run Counts');
    tabTitles.add('Scanner');
    tabTitles.add('Friends');

    appBarText = tabTitles[0];

    super.initState();

    // this is here to force the database to be instnatiated upon startup.
    // the first time this is run, the database will be created. On subsequent
    // runs, the database will simply be opened.

    DBProvider.db.initDB(informUser).then((Database db) {
      setState(() {
        setIntPref(IntPrefsEnum.dbCreated, 1);
      });
    });
  }

  void informUser(String message) {
    setState(() {
      initializationMessage = message;
    });
  }


  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  int currentPage = 0;

  GlobalKey bottomNavigationKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final int dbCreated = getIntPref(IntPrefsEnum.dbCreated) ?? 0;
    Widget _getPage(int pageIndex) {
      Widget w;
      appBarText = tabTitles[pageIndex];

      switch (pageIndex) {
        case 0:
          w = const FutureRunsListPage();
          break;
        case 1:
          w = const KennelsListPage();
          break;
        case 2:
          w = const HistoryListPage();
          break;
        case 3:
          w = const UserQrCodePage();
          break;
      }
      return w;
    }

    return Stack(
      children: <Widget>[
        Container(height: MediaQuery.of(context).size.height, width: MediaQuery.of(context).size.width),
        Positioned(
          top: 0,
          left: 0,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: themeAppBarBackground,
              title: Text(appBarText),
            ),
            body: Container(
              decoration: const BoxDecoration(color: Colors.white),
              child: dbCreated == 0
                  ? Container(
                      decoration: Backgrounds.defaultHcBackground(),
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      child: Center(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Image.asset(
                            'images/other/creating_database.png',
                            height: 250,
                            width: 250,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              initializationMessage,
                              style: headingStyle,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      )),
                    )
                  : Center(
                      child: _getPage(currentPage),
                    ),
            ),
            bottomNavigationBar: FancyBottomNavigation(
              circleColor: themeButtonColors,
              inactiveIconColor: themeBackgroundColor,
              barBackgroundColor: themeNavBarBackground,
              tabs: <TabData>[
                TabData(
                  iconData: MaterialCommunityIcons.run_fast,
                  title: 'Runs',
                  // onclick: () {
                  //   final FancyBottomNavigationState fState =
                  //       bottomNavigationKey.currentState;
                  //   fState.setPage(2);
                  // },
                ),
                TabData(
                  iconData: FontAwesome.home,
                  title: 'Kennels',
                  // onclick: () => Navigator.of(context).push<dynamic>(
                  //       MaterialPageRoute<dynamic>(
                  //         builder: (BuildContext context) => UserQrCodePage(),
                  //       ),
                  //     ),
                ),
                TabData(
                  iconData: FontAwesome.list_ul,
                  title: 'History',
                  // onclick: () => Navigator.of(context).push<dynamic>(
                  //       MaterialPageRoute<dynamic>(
                  //         builder: (BuildContext context) => UserQrCodePage(),
                  //       ),
                  //     ),
                ),
                TabData(
                  iconData: MaterialCommunityIcons.qrcode_scan,
                  title: 'Scanner',
                )
              ],
              initialSelection: 0,
              key: bottomNavigationKey,
              onTabChangedListener: (int position) {
                setState(() {
                  appBarText = tabTitles[position];
                  currentPage = position;
                });
              },
            ),
            drawer: DrawerMenu(scaffoldKey: _scaffoldKey),
          ),
        ),
        const OfflineModeRibbon(),
      ],
    );
  }
}

