import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:sqflite/sqflite.dart';

import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/data/hc3_services/sync_master_data_service.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/widgets/fancy_divider.dart';
import 'package:harrier_central/data/services/authorize_device_service.dart';
import 'package:harrier_central/database/database.dart';

// import 'package:harrier_central/widgets/user_details_ui.dart';
// import 'package:harrier_central/widgets/fancy_divider.dart';

class SupportPage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const SupportPage({Key key}) : super(key: key);

  @override
  SupportPageState createState() => SupportPageState();
}

class SupportPageState extends State<SupportPage> {
  String firstName = getStringPref(StringPrefsEnum.firstName);
  String lastName = getStringPref(StringPrefsEnum.lastName);
  String email = getStringPref(StringPrefsEnum.email);
  String hashName = getStringPref(StringPrefsEnum.hashName);

  final FocusNode resetCodeFocusNode = FocusNode();
  TextEditingController resetCodeTextController;
  InputDecoration resetCodeDecoration;

  @override
  void initState() {
    super.initState();
    resetCodeTextController = TextEditingController();
    resetCodeDecoration = InputDecoration(
      labelText: 'Reset Code',
      fillColor: Colors.red,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25.0),
        borderSide: const BorderSide(),
      ),
    );
  }

  String userName = getStringPref(StringPrefsEnum.displayName);
  String userQrCode = getStringPref(StringPrefsEnum.qrSecretCode);
  String supportCode = getStringPref(StringPrefsEnum.supportCode);

  bool isLoading = false;

  Widget _buildCircularProgressIndicator() {
    return Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Applying Reset Code',
              style: headingStyle,
              textAlign: TextAlign.center,
            ),
            Container(height: 30),
            SpinKitCircle(
              size: 75.0,
              itemBuilder: (_, int index) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: index.isEven
                        ? Colors.grey[50]
                        : Theme.of(context).accentColor,
                  ),
                );
              },
            ),
          ]),
    );
  }

  TextStyle headingStyle = const TextStyle(
      fontFamily: 'AvenirNextRegular',
      fontStyle: FontStyle.normal,
      color: Colors.yellow,
      fontSize: 22.0,
      height: 1.0);

  TextStyle largeText = const TextStyle(
      fontFamily: 'AvenirNextRegular',
      fontStyle: FontStyle.normal,
      color: Colors.white,
      fontSize: 32.0,
      height: 1.0);

  @override
  Widget build(BuildContext context) {
    final AppBar appBar = AppBar(
      centerTitle: true,
      backgroundColor: themeAppBarBackground,
      title: const Text(
        'Support',
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );
    return Scaffold(
      appBar: appBar,
      body: isLoading
          ? Container(
              height: MediaQuery.of(context).size.height -
                  appBar.preferredSize.height,
              decoration: Backgrounds.defaultHcBackground(),
              child: _buildCircularProgressIndicator())
          : Container(
              decoration: Backgrounds.defaultHcBackground(),
              height: MediaQuery.of(context).size.height -
                  appBar.preferredSize.height,
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                      //minHeight: viewportConstraints.maxHeight,
                      ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding:
                          const EdgeInsets.only(top: 30, left: 20, right: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          // TODO(James): Bring this back eventually
                          // UserDetailsUi(firstName: firstName, lastName: lastName, email: email, hashName: hashName,),
                          // const FancyDivider(innerColor: Colors.white),
                          Container(
                            //height:500,
                            width: MediaQuery.of(context).size.width,

                            child: IntrinsicHeight(
                              child: Stack(
                                fit: StackFit.expand,
                                alignment: AlignmentDirectional.center,
                                children: <Widget>[
                                  Container(height: 900),
                                  Positioned(
                                    top: 10,
                                    bottom: 20,
                                    width: MediaQuery.of(context).size.width,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: <Widget>[
                                          Expanded(
                                            child: Stack(
                                              alignment:
                                                  AlignmentDirectional.center,
                                              children: <Widget>[
                                                Positioned(
                                                  top: 50,
                                                  child: AutoSizeText(
                                                      'Secret QR code for:',
                                                      //'QR Code for xxx',
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines: 1,
                                                      style: headingStyle),
                                                ),
                                                Positioned(
                                                  top: 75,
                                                  child: AutoSizeText(
                                                      '$userName',
                                                      //'QR Code for xxx',
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines: 1,
                                                      style: largeText),
                                                ),
                                                Positioned(
                                                  top: 145,
                                                  //bottom: 50,
                                                  child: Container(
                                                    height: (MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.8 <
                                                            MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .height *
                                                                0.4)
                                                        ? MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.8
                                                        : MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.4,
                                                    width: (MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.8 <
                                                            MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .height *
                                                                0.4)
                                                        ? MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.8
                                                        : MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.4,
                                                    child: QrImage(
                                                        backgroundColor:
                                                            Colors.white,
                                                        padding:
                                                            const EdgeInsets
                                                                .all(10.0),
                                                        data:
                                                            'USC:${userQrCode.toUpperCase()}',
                                                        //data: 'testing123',
                                                        version: 4,
                                                        //size: 200.0,
                                                        errorCorrectionLevel:
                                                            3),
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 420,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 32.0,
                                                            right: 32.0),
                                                    child: FlatButton(
                                                      textColor: Colors.white,
                                                      child: const Text(
                                                          'Learn more about this feature'),
                                                      onPressed: () {
                                                        _displayInstructions(
                                                            context);
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Positioned(
                                      top: 513,
                                      left: 0,
                                      right: 0,
                                      child: FancyDivider(
                                          innerColor: Colors.white)),
                                  Positioned(
                                    top: 535,
                                    left: 0,
                                    right: 0,
                                    child: Text(
                                      'Support Code:',
                                      style: headingStyle,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Positioned(
                                    top: 565,
                                    left: 0,
                                    right: 0,
                                    child: Text(
                                      supportCode ?? '<no code>',
                                      style: largeText,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const Positioned(
                                      top: 650,
                                      left: 0,
                                      right: 0,
                                      child: FancyDivider(
                                          innerColor: Colors.white)),
                                  Positioned(
                                    top: 670,
                                    left: 0,
                                    right: 0,
                                    child: Text(
                                      'Reset Code:',
                                      style: headingStyle,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Positioned(
                                      top: 690,
                                      //bottom: 20,
                                      width: MediaQuery.of(context).size.width,
                                      child: Container(
                                        padding: const EdgeInsets.all(30.0),

                                        //color: const Color.fromARGB(255, 255, 255, 255),
                                        child: Container(
                                          child: Center(
                                            child: Column(
                                              children: <Widget>[
                                                Container(
                                                  //color: Colors.white,
                                                  padding: const EdgeInsets.all(
                                                      10.0),
                                                  decoration: BoxDecoration(
                                                    color: Colors.yellow[100],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5.0),
                                                  ),
                                                  // padding: const EdgeInsets.only(
                                                  //     top: 0.0, bottom: 8.0),
                                                  child: TextFormField(
                                                    autocorrect: false,
                                                    controller:
                                                        resetCodeTextController,
                                                    focusNode:
                                                        resetCodeFocusNode,
                                                    decoration:
                                                        resetCodeDecoration,
                                                    // validator: (val) {
                                                    //   if (val.length == 0) {
                                                    //     return "Email cannot be empty";
                                                    //   } else {
                                                    //     return null;
                                                    //   }
                                                    // },
                                                    keyboardType:
                                                        TextInputType.text,
                                                    style: const TextStyle(
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 25),
                                                  child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceAround,
                                                      children: <Widget>[
                                                        RaisedButton(
                                                          padding:
                                                              const EdgeInsets
                                                                      .only(
                                                                  top: 15,
                                                                  bottom: 15,
                                                                  left: 50,
                                                                  right: 50),
                                                          onPressed: () async {











                                                            Database db =
                                                                await DBProvider
                                                                    .db
                                                                    .database;

                                                            final SyncMasterDataService
                                                                cSrv =
                                                                SyncMasterDataService();
                                                            final bool result =
                                                                await cSrv
                                                                    .updateFromBackend(
                                                                        db,
                                                                        false);
                                                            final String
                                                                resultStr =
                                                                result
                                                                    ? 'successfully'
                                                                    : 'unsuccessfully';
                                                            print(
                                                                'Master data synchronized $resultStr');





                                                                

                                                            if (resetCodeTextController
                                                                    .text
                                                                    .length ==
                                                                6) {
                                                              setState(() {
                                                                isLoading =
                                                                    true;

                                                                final AuthorizeDeviceService
                                                                    srv =
                                                                    AuthorizeDeviceService();
                                                                final Future<
                                                                        Map<String,
                                                                            String>>
                                                                    apiCall =
                                                                    srv.authorizeDevice(
                                                                        context,
                                                                        'RC:' +
                                                                            resetCodeTextController.text.toUpperCase());
                                                                apiCall.then((Map<
                                                                        String,
                                                                        String>
                                                                    result) {
                                                                  setState(() {
                                                                    isLoading =
                                                                        false;
                                                                  });

                                                                  if (result[
                                                                          'result'] !=
                                                                      'failed') {
                                                                    userName = getStringPref(
                                                                        StringPrefsEnum
                                                                            .displayName);
                                                                    userQrCode =
                                                                        getStringPref(
                                                                            StringPrefsEnum.qrSecretCode);

                                                                    Utilities.showAlert(
                                                                        context,
                                                                        'App Reset Successful',
                                                                        'Your app has been successfully reset. Please close and restart the app to ensure all data is properly reloaded.',
                                                                        'OK');
                                                                  }
                                                                });
                                                              });
                                                            }
                                                          },
                                                          child: const Text(
                                                            'Reset App',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                        ),
                                                      ]),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )),
                                ],
                              ),
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
    );
  }

  Future<bool> _displayInstructions(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('About your QR Secret Code'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text(
                  'Harrier Central does not use either usernames or passwords. Instead we identify you using a \'secret QR code\'. This QR code can be used to allow Harrier Central running on another device to access your account. If you want to install Harrier Central on another device, when you first install the app, select \'existing user\' and use the scanner to scan this code. The app on the new device will then be configured to access your account',
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
}
