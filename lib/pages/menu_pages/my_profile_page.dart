import 'dart:async';

import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';

import 'package:harrier_central/remote_api_data/future_run_scoped_model.dart';
import 'package:harrier_central/data_models/main_navigation_model.dart';
import 'package:harrier_central/widgets/run_list_item.dart';

import 'package:scoped_model/scoped_model.dart';

import 'package:flutter/cupertino.dart';

//

// class MyProfilePageRoute extends CupertinoPageRoute<MyProfilePage> {
//   MyProfilePageRoute()
//       : super(builder: (BuildContext context) => new MyProfilePage());

//   // OPTIONAL IF YOU WISH TO HAVE SOME EXTRA ANIMATION WHILE ROUTING
//   @override
//   Widget buildPage(BuildContext context, Animation<double> animation,
//       Animation<double> secondaryAnimation) {
//     return new FadeTransition(opacity: animation, child: MyProfilePage());
//   }
// }

class MyProfilePage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  MyProfilePage({Key key}) : super(key: key);

  MyProfilePageState createState() => MyProfilePageState();
}

class MyProfilePageState extends State<MyProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //key: _scaffoldKey,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Container(color: Colors.blue, height: MediaQuery.of(context).size.height, width: MediaQuery.of(context).size.width),
      ),
    );
  }
}
