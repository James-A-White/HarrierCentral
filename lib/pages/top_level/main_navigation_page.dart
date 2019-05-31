

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:sqflite/sqflite.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:fancy_bottom_navigation/fancy_bottom_navigation.dart';

import 'package:harrier_central/data/models/main_navigation_model.dart';
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

  void onTabTapped(EnumAppPages index) {
    //homePageModel.currentMainView = index;
    //setIntPref(IntPrefsEnum.mainViewCurrentTab, index);
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

    // return Scaffold(
    //     appBar: AppBar(
    //       title: const Text(appBarText),
    //     ),
    //     key: _scaffoldKey,
    //     drawer: DrawerMenu(scaffoldKey: _scaffoldKey),
    //     body: CupertinoTabScaffold(
    //         tabBar: CupertinoTabBar(
    //           currentIndex: 0,
    //           onTap: (int index) {
    //             setState(() {
    //               appBarText = tabTitles[index];
    //             });
    //           },
    //           activeColor: Theme.of(context).accentColor,
    //           items: <BottomNavigationBarItem>[
    //             const BottomNavigationBarItem(
    //                 icon:const  Icon(Icons.directions_run), title: const Text('Runs')),
    //             const BottomNavigationBarItem(
    //                 icon:
    //                     ImageIcon(AssetImage('images/icons/dog_face_icon.png')),
    //                 title: const Text('Kennels')),
    //             const BottomNavigationBarItem(
    //                 icon:const  Icon(MaterialCommunityIcons.star),
    //                 title: const Text('Stats')),
    //             const BottomNavigationBarItem(
    //                 icon:
    //                     ImageIcon(AssetImage('images/icons/qr_code_icon.png')),
    //                 title: const Text('Scanner')),
    //             const BottomNavigationBarItem(
    //                 icon: ImageIcon(AssetImage('images/icons/friends.png')),
    //                 title: const Text('Friends')),
    //           ],
    //         ),
    //         tabBuilder: (BuildContext context, int index) {
    //           return CupertinoTabView(
    //             builder: (BuildContext context) {
    //               return (tabs[index]);
    //             },
    //             //defaultTitle: 'Friends',
    //           );
    //         }));
  }
}

// bottomNavigationBar: BottomAppBar(
//   shape: const CircularNotchedRectangle(),
//   notchMargin: 5.0,
//   //color: Theme.of(context).primaryColor,
//   child: const Padding(
//     padding: const EdgeInsets.only(right: 80.0),
//     child: Row(
//       mainAxisSize: MainAxisSize.max,
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: <Widget>[
//         IconButton(
//             icon: const  Icon(Icons.menu),
//             iconSize: Theme.of(context).iconTheme.size,
//             color: model.currentMainView == EnumAppPages.settings
//                 ? Theme.of(context).highlightColor
//                 : Theme.of(context).iconTheme.color,
//             onPressed: () {
//               onTabTapped(EnumAppPages.settings);
//               showModalBottomSheet<dynamic>(
//                   context: context,
//                   builder: (BuildContext context) => Drawer(
//                         child: Column(
//                           children: <Widget>[
//                             ListTile(
//                               leading: const  Icon(Icons.settings),
//                               title: const Text('Settings'),
//                               onTap: () {
//                                 Navigator.pop(context);
//                                 onTabTapped(
//                                     EnumAppPages.settings);
//                               },
//                             ),
//                             ListTile(
//                               leading: const  Icon(Icons.person),
//                               title: const Text('My Profile'),
//                               onTap: () {
//                                 Navigator.pop(context);
//                                 onTabTapped(
//                                     EnumAppPages.settings);
//                               },
//                             ),
//                             ListTile(
//                               leading:
//                                   const  Icon(Icons.shopping_cart),
//                               title:
//                                   const Text('In App Purchases'),
//                               onTap: () {
//                                 Navigator.pop(context);
//                                 onTabTapped(
//                                     EnumAppPages.settings);
//                               },
//                             ),
//                             // ListTile(
//                             //   leading:const  Icon(Icons.speaker_notes),
//                             //   title: const Text('Acknowledgements'),
//                             //   onTap: () {
//                             //     Navigator.pop(context);
//                             //     onTabTapped(3);
//                             //   },
//                             // ),
//                             ListTile(
//                               leading: const  Icon(Icons.info),
//                               title: const Text('FAQ'),
//                               onTap: () {
//                                 Navigator.pop(context);
//                                 onTabTapped(
//                                     EnumAppPages.settings);
//                               },
//                             ),
//                             ListTile(
//                               leading: const  Icon(Icons.feedback),
//                               title: const Text('Your feedback'),
//                               onTap: () {
//                                 Navigator.pop(context);
//                                 onTabTapped(
//                                     EnumAppPages.settings);
//                               },
//                             ),
//                             ListTile(
//                               leading:
//                                   const  Icon(Icons.speaker_notes),
//                               title: const Text('Imprint'),
//                               onTap: () {
//                                 Navigator.pop(context);
//                                 onTabTapped(
//                                     EnumAppPages.settings);
//                               },
//                             ),
//                           ],
//                         ),
//                       ));
//             }),
//         IconButton(
//           icon: const  Icon(Icons.directions_run),
//           iconSize: Theme.of(context).iconTheme.size,
//           color: model.currentMainView == EnumAppPages.futureRuns
//               ? Theme.of(context).highlightColor
//               : Theme.of(context).iconTheme.color,
//           onPressed: () {
//             onTabTapped(EnumAppPages.futureRuns);
//           },
//         ),
//         IconButton(
//           icon: const ImageIcon(
//               AssetImage('images/icons/dog_face_icon.png')),
//           color: model.currentMainView == EnumAppPages.kennelList
//               ? Theme.of(context).highlightColor
//               : Theme.of(context).iconTheme.color,
//           iconSize: Theme.of(context).iconTheme.size,
//           onPressed: () {
//             onTabTapped(EnumAppPages.kennelList);
//           },
//         ),
//         IconButton(
//           icon: const  Icon(Icons.show_chart),
//           iconSize: Theme.of(context).iconTheme.size,
//           color: model.currentMainView == EnumAppPages.runCounts
//               ? Theme.of(context).highlightColor
//               : Theme.of(context).iconTheme.color,
//           onPressed: () {
//             onTabTapped(EnumAppPages.runCounts);
//           },
//         ),
//         IconButton(
//           icon: const ImageIcon(
//               AssetImage('images/icons/qr_code_icon.png')),
//           iconSize: Theme.of(context).iconTheme.size,
//           color: model.currentMainView == EnumAppPages.qrCodePage
//               ? Theme.of(context).highlightColor
//               : Theme.of(context).iconTheme.color,
//           onPressed: () {
//             onTabTapped(EnumAppPages.qrCodePage);
//           },
//         ),
//         IconButton(
//           icon: const ImageIcon(
//               AssetImage('images/icons/friends.png')),
//           iconSize: Theme.of(context).iconTheme.size,
//           color: model.currentMainView == EnumAppPages.friends
//               ? Theme.of(context).highlightColor
//               : Theme.of(context).iconTheme.color,
//           onPressed: () {
//             onTabTapped(EnumAppPages.friends);
//           },
//         ),
//       ],
//     ),
//   ),
// ),

// ),
// ),
