import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class DoNotUse extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  DoNotUse({Key key}) : super(key: key);

  DoNotUseState createState() => DoNotUseState();
}

class DoNotUseState extends State<DoNotUse> {
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
