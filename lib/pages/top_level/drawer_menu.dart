import 'dart:async';

import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';

import 'package:harrier_central/remote_api_data/future_run_scoped_model.dart';
import 'package:harrier_central/data_models/main_navigation_model.dart';
import 'package:harrier_central/widgets/run_list_item.dart';

import 'package:scoped_model/scoped_model.dart';
//

class DrawerMenu extends StatelessWidget {
  //final FutureRunScopedModel futureRunsModel;

  const DrawerMenu({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DrawerMenuBody();
  }
}

class DrawerMenuBody extends StatelessWidget {
  void onTabTapped(EnumAppPages page) {}

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              // Navigator.pop(context);
              onTabTapped(EnumAppPages.settings);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('My Profile'),
            onTap: () {
              //Navigator.pop(context);
              onTabTapped(EnumAppPages.settings);
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('In App Purchases'),
            onTap: () {
              // Navigator.pop(context);
              onTabTapped(EnumAppPages.settings);
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
              // Navigator.pop(context);
              onTabTapped(EnumAppPages.settings);
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Your feedback'),
            onTap: () {
              //Navigator.pop(context);
              onTabTapped(EnumAppPages.settings);
            },
          ),
          ListTile(
            leading: const Icon(Icons.speaker_notes),
            title: const Text('Imprint'),
            onTap: () {
              //Navigator.pop(context);
              onTabTapped(EnumAppPages.settings);
            },
          ),
        ],
      ),
    );
  }
}
