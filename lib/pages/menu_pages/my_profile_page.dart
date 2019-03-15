import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/styles.dart';

class MyProfilePage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  MyProfilePage({Key key}) : super(key: key);

  MyProfilePageState createState() => MyProfilePageState();
}

class MyProfilePageState extends State<MyProfilePage> {
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
                top: 10,
                bottom: 20,
                width: MediaQuery.of(context).size.width,
                child: QrCodeTab()),
          ],
        ),
      ),
    );
  }
}

class QrCodeTab extends StatefulWidget {
  const QrCodeTab({Key key}) : super(key: key);

  @override
  _QrCodeTabState createState() => _QrCodeTabState();
}

class _QrCodeTabState extends State<QrCodeTab>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  Future<bool> _displayInstructions(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Your Secret QR Code'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'This QR code allows other Hashers to quickly scan you using their Harrier Central apps.\r\n\r\nAny Hasher can scan this code to easily add you as their friend.\r\n\r\nHares and mis-management can use this code to scan you in at the beginning and end of runs in order to keep your run counts accurate and ensure that no one is left behind on trail at the end of a run.',
                  textAlign: TextAlign.justify,
                  style: const TextStyle(
                      fontFamily: 'AvenirNextRegular',
                      fontStyle: FontStyle.normal,
                      fontSize: 16.0,
                      height: 1.0),
                )
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text("OK, Got it!"),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    String userName = Preferences.getStringPref(StringPrefsEnum.displayName);
    String userQrCode = Preferences.getStringPref(StringPrefsEnum.qrSecretCode);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: <Widget>[
                // Positioned(
                //   top: 0,
                //   width: MediaQuery.of(context).size.width * 0.8,
                //   child: Text(
                //     'Use this code to check in at the beginning and end of runs. Your friends can also scan this code to add you to their friend list. ',
                //     textAlign: TextAlign.justify,
                //     style: const TextStyle(
                //       color: Colors.white,
                //       fontFamily: 'AvenirNextDemiBold',
                //       fontStyle: FontStyle.normal,
                //       fontSize: 16.0,
                //       height: 0.8,
                //     ),
                //   ),
                // ),
                Positioned(
                  top: 30,
                  child: AutoSizeText(
                    'Secret QR code for:\r\n$userName',
                    //'QR Code for xxx',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(
                        fontFamily: 'AvenirNextDemiBold',
                        fontStyle: FontStyle.normal,
                        color: Colors.white,
                        fontSize: 24.0,
                        height: 1.0),
                  ),
                ),
                Positioned(
                  top: 160,
                  //bottom: 50,
                  child: Container(
                    height: (MediaQuery.of(context).size.width * 0.8 <
                            MediaQuery.of(context).size.height * 0.4)
                        ? MediaQuery.of(context).size.width * 0.8
                        : MediaQuery.of(context).size.height * 0.4,
                    width: (MediaQuery.of(context).size.width * 0.8 <
                            MediaQuery.of(context).size.height * 0.4)
                        ? MediaQuery.of(context).size.width * 0.8
                        : MediaQuery.of(context).size.height * 0.4,
                    child: QrImage(
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.all(10.0),
                        data: 'USC:${userQrCode.toUpperCase()}',
                        //data: 'testing123',
                        version: 4,
                        //size: 200.0,
                        errorCorrectionLevel: 3),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Padding(
                    padding: EdgeInsets.only(left: 32.0, right: 32.0),
                    child: FlatButton(
                      textColor: Colors.white,
                      child: Text("Learn more about this feature"),
                      onPressed: () {
                        this._displayInstructions(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
