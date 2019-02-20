import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:harrier_central/data_models/main_navigation_model.dart';
import 'package:harrier_central/remote_api_data/main_navigation_scoped_model.dart';

import 'package:harrier_central/data_models/main_navigation_model.dart';
import 'package:harrier_central/pages/facebook_login.dart';
import 'package:harrier_central/pages/top_level/future_run_list_page.dart';
import 'package:harrier_central/pages/top_level/drawer_menu.dart';
import 'package:harrier_central/pages/top_level/kennel_list_page.dart';
import 'package:harrier_central/pages/top_level/user_qr_code_page.dart';
import 'package:harrier_central/remote_api_data/kennel_scoped_model.dart';
import 'package:harrier_central/widgets/placeholder_widget.dart';

import 'package:scoped_model/scoped_model.dart';

class MainNavigationPage extends StatefulWidget {
  MainNavigationPage({Key key}) : super(key: key);

  @override
  _MainNavigationPageState createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  //MainNavigationScopedModel homePageModel = MainNavigationScopedModel();

  void initState() {
    // homePageModel.init();
    // homePageModel.mainAppScaffoldKey = GlobalKey<ScaffoldState>();
  }

  void onTabTapped(EnumAppPages index) {
    //homePageModel.currentMainView = index;
    //Preferences.setIntPref(IntPrefsEnum.mainViewCurrentTab, index);
  }

  final KennelScopedModel kennelModel = KennelScopedModel();

  @override
  Widget build(BuildContext context) {
    return

        // ScopedModel<MainNavigationScopedModel>(
        //   model: homePageModel,
        //   child:

        //   ScopedModelDescendant<MainNavigationScopedModel>(
        //     builder: (BuildContext context, Widget child, MainNavigationScopedModel model) =>

        CupertinoTabScaffold(
            //key: homePageModel.mainAppScaffoldKey,
            // appBar: AppBar(
            //   centerTitle: true,
            //   backgroundColor: Theme.of(context).primaryColor,
            //   title: Text(
            //     homePageModel.appBarTitle ?? '',
            //     style: TextStyle(
            //       color: Colors.white,
            //     ),
            //   ),
            // ),
            // body: homePageModel.homePage
            //     .children[homePageModel.homePage.currentMainAppView.index],
            // floatingActionButtonLocation:
            //     FloatingActionButtonLocation.endDocked,
            // floatingActionButton: FloatingActionButton(
            //   child:
            //       const ImageIcon(AssetImage('images/icons/hash_foot.png')),
            //   onPressed: () {
            //     onTabTapped(EnumAppPages.fab);
            //   },
            // ),

            tabBar: CupertinoTabBar(
              activeColor: Theme.of(context).accentColor,
              items: <BottomNavigationBarItem>[
                const BottomNavigationBarItem(
                    icon: Icon(Icons.menu), title: Text('Menu')),
                const BottomNavigationBarItem(
                    icon: Icon(Icons.directions_run), title: Text('Runs')),
                const BottomNavigationBarItem(
                    icon:
                        ImageIcon(AssetImage('images/icons/dog_face_icon.png')),
                    title: Text('Kennels')),
                const BottomNavigationBarItem(
                    icon: Icon(Icons.show_chart), title: Text('Stats')),
                const BottomNavigationBarItem(
                    icon:
                        ImageIcon(AssetImage('images/icons/qr_code_icon.png')),
                    title: Text('Scanner')),
                const BottomNavigationBarItem(
                    icon: ImageIcon(AssetImage('images/icons/friends.png')),
                    title: Text('Friends')),
              ],
            ),
            tabBuilder: (BuildContext context, int index) {
              assert(index >= 0 && index <= 5);
              switch (index) {
                case 0:
                  return CupertinoTabView(
                    builder: (BuildContext context) {
                      return DrawerMenu();
                    },
                    defaultTitle: 'Menu',
                  );
                  break;
                case 1:
                  return CupertinoTabView(
                    builder: (BuildContext context) {
                      return FutureRunsListPage();
                    },
                    defaultTitle: 'Runs',
                  );
                  break;
                case 2:
                  return CupertinoTabView(
                    builder: (BuildContext context) {
                      //kennelModel.getKennelsFromBackend(1, true);
                      return KennelsListPage(kennelModel: kennelModel);
                    },
                    defaultTitle: 'Kennels',
                  );
                  break;
                                  case 3:
                  return CupertinoTabView(
                    builder: (BuildContext context) {
                      //kennelModel.getKennelsFromBackend(1, true);
                      return KennelsListPage(kennelModel: kennelModel);
                    },
                    defaultTitle: 'Stats',
                  );
                  break;
                                  case 4:
                  return CupertinoTabView(
                    builder: (BuildContext context) {
                      //kennelModel.getKennelsFromBackend(1, true);
                      return UserQrCodePage();
                    },
                    defaultTitle: 'Scanner',
                  );
                  break;
                                  case 5:
                  return CupertinoTabView(
                    builder: (BuildContext context) {
                      //kennelModel.getKennelsFromBackend(1, true);
                      return KennelsListPage(kennelModel: kennelModel);
                    },
                    defaultTitle: 'Friends',
                  );
                  break;
              }
              return null;
            }

            // bottomNavigationBar: BottomAppBar(
            //   shape: const CircularNotchedRectangle(),
            //   notchMargin: 5.0,
            //   //color: Theme.of(context).primaryColor,
            //   child: Padding(
            //     padding: const EdgeInsets.only(right: 80.0),
            //     child: Row(
            //       mainAxisSize: MainAxisSize.max,
            //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //       children: <Widget>[
            //         IconButton(
            //             icon: const Icon(Icons.menu),
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
            //                               leading: const Icon(Icons.settings),
            //                               title: const Text('Settings'),
            //                               onTap: () {
            //                                 Navigator.pop(context);
            //                                 onTabTapped(
            //                                     EnumAppPages.settings);
            //                               },
            //                             ),
            //                             ListTile(
            //                               leading: const Icon(Icons.person),
            //                               title: const Text('My Profile'),
            //                               onTap: () {
            //                                 Navigator.pop(context);
            //                                 onTabTapped(
            //                                     EnumAppPages.settings);
            //                               },
            //                             ),
            //                             ListTile(
            //                               leading:
            //                                   const Icon(Icons.shopping_cart),
            //                               title:
            //                                   const Text('In App Purchases'),
            //                               onTap: () {
            //                                 Navigator.pop(context);
            //                                 onTabTapped(
            //                                     EnumAppPages.settings);
            //                               },
            //                             ),
            //                             // ListTile(
            //                             //   leading: Icon(Icons.speaker_notes),
            //                             //   title: Text('Acknowledgements'),
            //                             //   onTap: () {
            //                             //     Navigator.pop(context);
            //                             //     onTabTapped(3);
            //                             //   },
            //                             // ),
            //                             ListTile(
            //                               leading: const Icon(Icons.info),
            //                               title: const Text('FAQ'),
            //                               onTap: () {
            //                                 Navigator.pop(context);
            //                                 onTabTapped(
            //                                     EnumAppPages.settings);
            //                               },
            //                             ),
            //                             ListTile(
            //                               leading: const Icon(Icons.feedback),
            //                               title: const Text('Your feedback'),
            //                               onTap: () {
            //                                 Navigator.pop(context);
            //                                 onTabTapped(
            //                                     EnumAppPages.settings);
            //                               },
            //                             ),
            //                             ListTile(
            //                               leading:
            //                                   const Icon(Icons.speaker_notes),
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
            //           icon: const Icon(Icons.directions_run),
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
            //           icon: const Icon(Icons.show_chart),
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
            );
  }
}
