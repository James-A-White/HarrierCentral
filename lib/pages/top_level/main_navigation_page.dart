import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:harrier_central/remote_api_data/main_navigation_scoped_model.dart';
import 'package:harrier_central/util/preferences.dart';

import 'package:harrier_central/pages/top_level/user_qr_code_page.dart';

class MainNavigationPage extends StatefulWidget {
  MainNavigationPage({Key key}) : super(key: key);

  @override
  _MainNavigationPageState createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  MainNavigationScopedModel homePageModel = MainNavigationScopedModel();

  void initState() {
    homePageModel.init();
    homePageModel.mainAppScaffoldKey = GlobalKey<ScaffoldState>();
  }

  void onTabTapped(int index) {
    homePageModel.currentIndex = index;
    //Preferences.setIntPref(IntPrefsEnum.mainViewCurrentTab, index);
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModel<MainNavigationScopedModel>(
      model: homePageModel,
      child: ScopedModelDescendant<MainNavigationScopedModel>(
        builder: (BuildContext context, Widget child,
                MainNavigationScopedModel model) =>
            Scaffold(
              key: homePageModel.mainAppScaffoldKey,
              appBar: AppBar(
                centerTitle: true,
                backgroundColor: Theme.of(context).primaryColor,
                title: Text(
                  homePageModel.appBarTitle ?? '',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
              body: homePageModel
                  .homePage.children[homePageModel.homePage.currentIndex],
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.endDocked,
              floatingActionButton: FloatingActionButton(
                child:
                    const ImageIcon(AssetImage('images/icons/hash_foot.png')),
                onPressed: () {
                  onTabTapped(6);
                },
              ),
              bottomNavigationBar: BottomAppBar(
                shape: const CircularNotchedRectangle(),
                notchMargin: 5.0,
                //color: Theme.of(context).primaryColor,
                child: Padding(
                  padding: const EdgeInsets.only(right: 80.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      IconButton(
                          icon: const Icon(Icons.menu),
                          iconSize: Theme.of(context).iconTheme.size,
                          color: model.currentIndex == 0
                              ? Theme.of(context).highlightColor
                              : Theme.of(context).iconTheme.color,
                          onPressed: () {
                            onTabTapped(0);
                            showModalBottomSheet<dynamic>(
                                context: context,
                                builder: (BuildContext context) => Drawer(
                                      child: Column(
                                        children: <Widget>[
                                          ListTile(
                                            leading: const Icon(Icons.settings),
                                            title: const Text('Settings'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              onTabTapped(0);
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.person),
                                            title: const Text('My Profile'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              onTabTapped(1);
                                            },
                                          ),
                                          ListTile(
                                            leading:
                                                const Icon(Icons.shopping_cart),
                                            title:
                                                const Text('In App Purchases'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              onTabTapped(2);
                                            },
                                          ),
                                          // ListTile(
                                          //   leading: Icon(Icons.speaker_notes),
                                          //   title: Text('Acknowledgements'),
                                          //   onTap: () {
                                          //     Navigator.pop(context);
                                          //     onTabTapped(3);
                                          //   },
                                          // ),
                                          ListTile(
                                            leading: const Icon(Icons.info),
                                            title: const Text('FAQ'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              onTabTapped(3);
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.feedback),
                                            title: const Text('Your feedback'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              onTabTapped(3);
                                            },
                                          ),
                                          ListTile(
                                            leading:
                                                const Icon(Icons.speaker_notes),
                                            title: const Text('Imprint'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              onTabTapped(3);
                                            },
                                          ),
                                        ],
                                      ),
                                    ));
                          }),
                      IconButton(
                        icon: const Icon(Icons.directions_run),
                        iconSize: Theme.of(context).iconTheme.size,
                        color: model.currentIndex == 1
                            ? Theme.of(context).highlightColor
                            : Theme.of(context).iconTheme.color,
                        onPressed: () {
                          onTabTapped(1);
                        },
                      ),
                      IconButton(
                        icon: const ImageIcon(
                            AssetImage('images/icons/dog_face_icon.png')),
                        color: model.currentIndex == 2
                            ? Theme.of(context).highlightColor
                            : Theme.of(context).iconTheme.color,
                        iconSize: Theme.of(context).iconTheme.size,
                        onPressed: () {
                          onTabTapped(2);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.show_chart),
                        iconSize: Theme.of(context).iconTheme.size,
                        color: model.currentIndex == 3
                            ? Theme.of(context).highlightColor
                            : Theme.of(context).iconTheme.color,
                        onPressed: () {
                          onTabTapped(3);
                        },
                      ),
                      IconButton(
                        icon: const ImageIcon(
                            AssetImage('images/icons/qr_code_icon.png')),
                        iconSize: Theme.of(context).iconTheme.size,
                        color: model.currentIndex == 4
                            ? Theme.of(context).highlightColor
                            : Theme.of(context).iconTheme.color,
                        onPressed: () {
                          onTabTapped(4);
                        },
                      ),
                      IconButton(
                        icon: const ImageIcon(
                            AssetImage('images/icons/friends.png')),
                        iconSize: Theme.of(context).iconTheme.size,
                        color: model.currentIndex == 5
                            ? Theme.of(context).highlightColor
                            : Theme.of(context).iconTheme.color,
                        onPressed: () {
                          onTabTapped(5);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }
}
