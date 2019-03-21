import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/widgets/user_details_ui.dart';
import 'package:harrier_central/widgets/fancy_divider.dart';

class MyProfilePage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const MyProfilePage({Key key}) : super(key: key);

  @override
  MyProfilePageState createState() => MyProfilePageState();
}

class MyProfilePageState extends State<MyProfilePage> {
  
  String firstName = getStringPref(StringPrefsEnum.firstName);
  String lastName = getStringPref(StringPrefsEnum.lastName);
  String email = getStringPref(StringPrefsEnum.email);
  String hashName = getStringPref(StringPrefsEnum.hashName);
  
  @override
  Widget build(BuildContext context) {

    final AppBar appBar = AppBar(
          centerTitle: true,
          backgroundColor: themeAppBarBackground,
          title: const Text(
            'My Profile',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        );
    return Scaffold(
        appBar: appBar,
        body: 
        Container(
          decoration: Backgrounds.defaultHcBackground(),
          height: MediaQuery.of(context).size.height - appBar.preferredSize.height,
        child:SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
                //minHeight: viewportConstraints.maxHeight,
                ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    UserDetailsUi(firstName: firstName, lastName: lastName, email: email, hashName: hashName,),
                    const FancyDivider(innerColor: Colors.white),
                    Container(
                      height:500,
                      width:MediaQuery.of(context).size.width,
                      
                      child: Stack(
                        alignment: AlignmentDirectional.center,
                        children: <Widget>[
                          Positioned(
                              top: 10,
                              bottom: 20,
                              width: MediaQuery.of(context).size.width,
                              child: const QrCodeTab()),
                        ],
                      ),
                    ),
                    Container(width: 40, height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
        ),

        // Container(
        //   decoration: Backgrounds.defaultHcBackground(),
        //   child: Stack(
        //     alignment: AlignmentDirectional.center,
        //     children: <Widget>[
        //       Positioned(
        //           top: 10,
        //           bottom: 20,
        //           width: MediaQuery.of(context).size.width,
        //           child: QrCodeTab()),
        //     ],
        //   ),
        // ),

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
          title: const Text('Your Secret QR Code'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text(
                  'This QR code allows other Hashers to quickly scan you using their Harrier Central apps.\r\n\r\nAny Hasher can scan this code to easily add you as their friend.\r\n\r\nHares and mis-management can use this code to scan you in at the beginning and end of runs in order to keep your run counts accurate and ensure that no one is left behind on trail at the end of a run.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(
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
              child: const Text('OK, Got it!'),
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
    final String userName = getStringPref(StringPrefsEnum.displayName);
    final String userQrCode = getStringPref(StringPrefsEnum.qrSecretCode);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: <Widget>[
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
                        padding: const EdgeInsets.all(10.0),
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
                    padding: const EdgeInsets.only(left: 32.0, right: 32.0),
                    child: FlatButton(
                      textColor: Colors.white,
                      child: const Text('Learn more about this feature'),
                      onPressed: () {
                        _displayInstructions(context);
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
