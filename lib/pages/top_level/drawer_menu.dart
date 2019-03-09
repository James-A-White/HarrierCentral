import 'dart:async';

import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';

import 'package:harrier_central/remote_api_data/future_run_scoped_model.dart';
import 'package:harrier_central/data_models/main_navigation_model.dart';
import 'package:harrier_central/widgets/run_list_item.dart';

import 'package:scoped_model/scoped_model.dart';

import 'package:flutter_inner_drawer/inner_drawer.dart';
//

class DrawerMenu extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;
  GlobalKey<InnerDrawerState> innerDrawerGlobalKey;

  DrawerMenu({Key key, this.innerDrawerGlobalKey}) : super(key: key);

  DrawerMenuState createState() => DrawerMenuState();
}

class DrawerMenuState extends State<DrawerMenu> {
  void onTabTapped(EnumAppPages page) {
    widget.innerDrawerGlobalKey.currentState.close();
  }

  TextStyle style =TextStyle(color:Colors.white);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      //elevation: 120,
      child: Stack(children: <Widget>[
        Image.asset('images/other/drawer_image.jpg'),
        Positioned(
          //top:50,
          //top:10,
          top:40,
          width:MediaQuery.of(context).size.width,
        child:Column(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.settings, color:Colors.white),
              title: Text('Settings',style: style),
              onTap: () {
                // Navigator.pop(context);
                onTabTapped(EnumAppPages.settings);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color:Colors.white),
              title: Text('My Profile',style: style),
              onTap: () {
                //Navigator.pop(context);
                onTabTapped(EnumAppPages.settings);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart, color:Colors.white),
              title: Text('In App Purchases',style: style),
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
              leading: const Icon(Icons.info, color:Colors.white),
              title: Text('FAQ',style: style),
              onTap: () {
                // Navigator.pop(context);
                onTabTapped(EnumAppPages.settings);
              },
            ),
            ListTile(
              leading: const Icon(Icons.feedback, color:Colors.white),
              title: Text('Your feedback',style: style),
              onTap: () {
                //Navigator.pop(context);
                onTabTapped(EnumAppPages.settings);
              },
            ),
            ListTile(
              leading: const Icon(Icons.speaker_notes, color:Colors.white),
              title: Text('Imprint',style: style),
              onTap: () {
                //Navigator.pop(context);
                onTabTapped(EnumAppPages.settings);
              },
            ),
          ],
        ),),
      ]),
    );
  }
}
