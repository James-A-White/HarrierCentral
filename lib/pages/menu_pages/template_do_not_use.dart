import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:harrier_central/util/styles.dart';

class DoNotUse extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  DoNotUse({Key key}) : super(key: key);

  @override
  DoNotUseState createState() => DoNotUseState();
}

class DoNotUseState extends State<DoNotUse> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          'My Profile',
          style: const TextStyle(
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
                top: 10,
                left: 20,
                //width: MediaQuery.of(context).size.width,
                child: XPageContent()),
          ],
        ),
      ),
    );
  }
}

class XPageContent extends StatefulWidget {
  const XPageContent({Key key}) : super(key: key);

  @override
  _XPageContentState createState() => _XPageContentState();
}

class _XPageContentState extends State<XPageContent> {
  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.red, width: 100, height: 100);
  }
}
