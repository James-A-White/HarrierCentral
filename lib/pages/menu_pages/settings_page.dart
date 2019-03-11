import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:harrier_central/util/styles.dart';

class SettingsPage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  SettingsPage({Key key}) : super(key: key);

  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: <Widget>[
            Positioned(
                // width: MediaQuery.of(context).size.width,
                // height: MediaQuery.of(context).size.height,
                child: SettingsPageContent()),
          ],
        ),
      ),
    );
  }
}

class SettingsPageContent extends StatefulWidget {
  const SettingsPageContent({Key key}) : super(key: key);

  @override
  _SettingsPageContentState createState() => _SettingsPageContentState();
}

class _SettingsPageContentState extends State<SettingsPageContent> {
  TextStyle headingStyle = TextStyle(
      fontFamily: 'AvenirNextRegular',
      fontStyle: FontStyle.normal,
      color: Colors.yellow,
      fontSize: 24.0,
      height: 1.0);

  TextStyle bodyStyle = TextStyle(
      fontFamily: 'AvenirNextRegular',
      fontStyle: FontStyle.normal,
      color: Colors.white,
      fontSize: 20.0,
      height: 1.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Center(child:Text('Settings\r\nPage Placeholder', textAlign: TextAlign.center, style: headingStyle)),
    );
  }
}
