import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:harrier_central/util/styles.dart';

class InAppPurchasePage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  InAppPurchasePage({Key key}) : super(key: key);

  InAppPurchasePageState createState() => InAppPurchasePageState();
}

class InAppPurchasePageState extends State<InAppPurchasePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: ThemeColors.appBarBackground,
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
                //top: 10,
                //left: 20,
                //width: MediaQuery.of(context).size.width,
                child: InAppPurchasePageContent()),
          ],
        ),
      ),
    );
  }

}

class InAppPurchasePageContent extends StatefulWidget {
  const InAppPurchasePageContent({Key key}) : super(key: key);

  @override
  _InAppPurchasePageContentState createState() => _InAppPurchasePageContentState();
}

class _InAppPurchasePageContentState extends State<InAppPurchasePageContent>
 {

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
      child: Center(child:Text(' In App Purchase\r\nPage Placeholder', textAlign: TextAlign.center, style: headingStyle)),
    );
  }

 }
