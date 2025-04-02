import 'package:harrier_central/imports.dart';

//

class SupportPage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const SupportPage({
    super.key,
  });

  @override
  SupportPageState createState() => SupportPageState();
}

class SupportPageState extends State<SupportPage> {
  // final String _firstName = getStringPref(StringPrefsEnum.firstName) ?? '';
  // final String _lastName = getStringPref(StringPrefsEnum.lastName) ?? '';
  // final String _email = getStringPref(StringPrefsEnum.email) ?? '';
  // final String _hashName = getStringPref(StringPrefsEnum.hashName) ?? '';

  // final FocusNode _resetCodeFocusNode = FocusNode();
  // final TextEditingController _resetCodeTextController =
  //     TextEditingController();
  // final InputDecoration _resetCodeDecoration = InputDecoration(
  //   labelText: 'Invite Code',
  //   fillColor: hc_red,
  //   border: OutlineInputBorder(
  //     borderRadius: BorderRadius.circular(25.0),
  //     borderSide: const BorderSide(),
  //   ),
  // );

  @override
  void initState() {
    super.initState();
  }

  final _userName = getStringPref(StringPrefsEnum.displayName) ?? '';
  final _userSecretCode = getStringPref(StringPrefsEnum.qrSecretCode) ?? '';
  final String _supportCode = getStringPref(StringPrefsEnum.supportCode) ?? '';

  bool isLoading = false;

  Widget _buildCircularProgressIndicator() {
    return Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Applying Invite Code',
              style: ts_headingLarge,
              textAlign: TextAlign.center,
            ),
            Container(height: 30),
            const HcCircularProgressIndicator(
              key: Key('68462'),
            ),
          ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppBar appBar = AppBar(
      centerTitle: true,
      backgroundColor: themeAppBarBackground,
      iconTheme: const IconThemeData(
        color: Colors.white,
        size: 28.0,
      ),
      title: Text('Support', style: ts_appBarTitle),
    );
    return Stack(
      children: <Widget>[
        SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width),
        Positioned(
          top: 0,
          left: 0,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Scaffold(
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
                      child: Padding(
                        padding:
                            const EdgeInsets.only(top: 20, left: 0, right: 0),
                        child: Column(
                          children: <Widget>[
                            AutoSizeText('Secret QR code for:',
                                //'QR Code for xxx',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: ts_headingLarge),
                            const SizedBox(height: 15.0),
                            AutoSizeText(_userName,
                                //'QR Code for xxx',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: ts_titleVeryLarge),
                            const SizedBox(height: 15.0),
                            SizedBox(
                              height: (MediaQuery.of(context).size.width * 0.8 <
                                      MediaQuery.of(context).size.height * 0.4)
                                  ? MediaQuery.of(context).size.width * 0.8
                                  : MediaQuery.of(context).size.height * 0.4,
                              width: (MediaQuery.of(context).size.width * 0.8 <
                                      MediaQuery.of(context).size.height * 0.4)
                                  ? MediaQuery.of(context).size.width * 0.8
                                  : MediaQuery.of(context).size.height * 0.4,
                              child: Stack(
                                alignment: AlignmentDirectional.center,
                                children: <Widget>[
                                  QrImageView(
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.all(10.0),
                                      data:
                                          '$QR_PREFIX_USER_SECRET_CODE${_userSecretCode.toUpperCase()}',
                                      //data: 'testing123',
                                      version: 5,
                                      //size: 200.0,
                                      errorCorrectionLevel:
                                          QrErrorCorrectLevel.M),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10.0),
                            TextButton(
                              style: text_button_style,
                              child: Text(
                                'Learn more about this feature',
                                style: ts_button,
                              ),
                              onPressed: () {
                                _displayInstructions(context);
                              },
                            ),
                            const FancyDivider(
                              key: Key('7911393501'),
                              innerColor: Colors.white,
                              topMargin: 20.0,
                              bottomMargin: 20.0,
                            ),
                            Text(
                              'Support Code:',
                              style: ts_headingLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 15.0),
                            Text(
                              _supportCode,
                              style: ts_titleVeryLarge,
                              textAlign: TextAlign.center,
                            ),
                            // const FancyDivider(
                            //   key: Key('6624334671'),
                            //   innerColor: Colors.white,
                            //   topMargin: 40.0,
                            //   bottomMargin: 30.0,
                            // ),
                            // Text(
                            //   'Invite Code:',
                            //   style: ts_headingLarge,
                            //   textAlign: TextAlign.center,
                            // ),
                            // Container(
                            //   padding: const EdgeInsets.all(30.0),

                            //   //color: const Color.fromARGB(255, 255, 255, 255),
                            //   child: Center(
                            //     child: Column(
                            //       children: <Widget>[
                            //         Container(
                            //           //color: Colors.white,
                            //           padding: const EdgeInsets.all(10.0),
                            //           decoration: BoxDecoration(
                            //             color: Colors.yellow[100],
                            //             borderRadius: BorderRadius.circular(5.0),
                            //           ),
                            //           // padding: const EdgeInsets.only(
                            //           //     top: 0.0, bottom: 8.0),
                            //           child: TextFormField(
                            //             autocorrect: false,
                            //             controller: _resetCodeTextController,
                            //             focusNode: _resetCodeFocusNode,
                            //             decoration: _resetCodeDecoration,
                            //             // validator: (val) {
                            //             //   if (val.length == 0) {
                            //             //     return "Email cannot be empty";
                            //             //   } else {
                            //             //     return null;
                            //             //   }
                            //             // },
                            //             keyboardType: TextInputType.text,
                            //             style: const TextStyle(
                            //               color: Colors.yellow,
                            //               fontFamily: 'Poppins',
                            //             ),
                            //           ),
                            //         ),
                            //         Padding(
                            //           padding: const EdgeInsets.only(top: 25),
                            //           child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <Widget>[
                            //             Connection2.styleForConnected(
                            //               G0<AppModel>().connectionStatus,
                            //               ElevatedButton(
                            //                 style: ElevatedButton.styleFrom(
                            //                   padding: const EdgeInsets.only(top: 8, bottom: 8, left: 20, right: 20),
                            //                 ),
                            //                 onPressed: () async {
                            //                   if (Connection2.checkForConnection(G0<AppModel>().connectionStatus)) {
                            //                     await G0<TableModel>().syncUserDataService.updateFromBackend(
                            //                           SyncUserDataService.flagAllMasterData,
                            //                           false,
                            //                           debugText: 'support_page: All master data',
                            //                         );
                            //                     //final String resultStr = result ? 'successfully' : 'unsuccessfully';
                            //                     //print('Master data synchronized $resultStr');

                            //                     if (_resetCodeTextController.text.length == 6) {
                            //                       setState(() {
                            //                         isLoading = true;
                            //                       });

                            //                       final AuthorizeDeviceService srv = AuthorizeDeviceService();

                            //                       if (!mounted) return;
                            //                       final Map<String, String> result = await srv.authorizeDevice(navigatorKey.currentContext!, QR_PREFIX_USER_RESET_CODE + _resetCodeTextController.text.toUpperCase());

                            //                       setState(() {
                            //                         isLoading = false;
                            //                       });

                            //                       if (result['result'] != 'failed') {
                            //                         _userName = getStringPref(StringPrefsEnum.displayName) ?? _userName;
                            //                         _userSecretCode = getStringPref(StringPrefsEnum.qrSecretCode) ?? _userSecretCode;

                            //                         await Utilities.showAlert('App Reset Successful', 'Your app has been successfully reset. Please close and restart the app to ensure all data is properly reloaded.', 'OK');
                            //                       }
                            //                     }
                            //                   }
                            //                 },
                            //                 child: Text(
                            //                   'Reset App',
                            //                   style: ts_button,
                            //                 ),
                            //               ),
                            //             ),
                            //           ]),
                            //         ),
                            //         Padding(
                            //           padding: const EdgeInsets.only(top: 25),
                            //           child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <Widget>[
                            //             Connection2.styleForConnected(
                            //               G0<AppModel>().connectionStatus,
                            //               ElevatedButton(
                            //                 style: ElevatedButton.styleFrom(
                            //                   padding: const EdgeInsets.only(top: 8, bottom: 8, left: 20, right: 20),
                            //                 ),
                            //                 onPressed: () async {
                            //                   if (Connection2.checkForConnection(G0<AppModel>().connectionStatus)) {
                            //                     await G0<TableModel>().syncUserDataService.updateFromBackend(
                            //                           SyncUserDataService.flagAllMasterData,
                            //                           false,
                            //                           debugText: 'support_page: All master data 2',
                            //                         );
                            //                     // final String resultStr = result ? 'successfully' : 'unsuccessfully';
                            //                     // print('Master data synchronized $resultStr');

                            //                     if (_resetCodeTextController.text.length == 6) {
                            //                       setState(() {
                            //                         isLoading = true;
                            //                       });

                            //                       final AuthorizeDeviceService srv = AuthorizeDeviceService();

                            //                       if (!mounted) return;
                            //                       final Map<String, String> result = await srv.authorizeDevice(navigatorKey.currentContext!, QR_PREFIX_USER_RESET_CODE + _resetCodeTextController.text.toUpperCase());

                            //                       setState(() {
                            //                         isLoading = false;
                            //                       });

                            //                       if (result['result'] != 'failed') {
                            //                         _userName = getStringPref(StringPrefsEnum.displayName) ?? _userName;
                            //                         _userSecretCode = getStringPref(StringPrefsEnum.qrSecretCode) ?? _userSecretCode;

                            //                         await Utilities.showAlert('App Reset Successful', 'Your app has been successfully reset. Please close and restart the app to ensure all data is properly reloaded.', 'OK');
                            //                       }
                            //                     }
                            //                   }
                            //                 },
                            //                 child: Text(
                            //                   'Reload Database',
                            //                   style: ts_button,
                            //                 ),
                            //               ),
                            //             ),
                            //           ]),
                            //         ),
                            //       ],
                            //     ),
                            //   ),
                            // ),
                            const SizedBox(width: 40, height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        OfflineModeRibbon(
          showRibbon: G0<AppModel>().connectionStatus ==
              EnumConnectionStatus2.notConnected,
          lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSyncAsDate),
          ribbonImage: 'images/icons/offline_mode.png',
          refreshFunction: () {
            setState(() {});
          },
        ),
      ],
    );
  }

  Future<bool?> _displayInstructions(BuildContext context) async {
    return showDialog<bool?>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'About your QR Secret Code',
            style: ts_alertDialogTitle,
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Harrier Central does not use either usernames or passwords. Instead we identify you using a \'secret QR code\'. This QR code can be used to allow Harrier Central running on another device to access your account. If you want to install Harrier Central on another device, when you first install the app, select \'existing user\' and use the scanner to scan this code. The app on the new device will then be configured to access your account',
                  textAlign: TextAlign.justify,
                  style: ts_alertDialogBody,
                )
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: text_button_style,
              child: Text(
                'OK, Got it!',
                style: ts_button,
              ),
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
