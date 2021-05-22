import 'package:harrier_central/imports.dart';

//

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
  String userSecretCode = getStringPref(StringPrefsEnum.qrSecretCode);
  String supportCode = getStringPref(StringPrefsEnum.supportCode);

  bool isLoading = false;

  Widget _buildCircularProgressIndicator() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
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
                color: index.isEven ? Colors.grey[50] : Theme.of(context).accentColor,
              ),
            );
          },
        ),
      ]),
    );
  }

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
    return Stack(
      children: <Widget>[
        Container(height: MediaQuery.of(context).size.height, width: MediaQuery.of(context).size.width),
        Positioned(
          top: 0,
          left: 0,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Scaffold(
            appBar: appBar,
            body: isLoading
                ? Container(
                    height: MediaQuery.of(context).size.height - appBar.preferredSize.height,
                    decoration: Backgrounds.defaultHcBackground(),
                    child: _buildCircularProgressIndicator())
                : Container(
                    decoration: Backgrounds.defaultHcBackground(),
                    height: MediaQuery.of(context).size.height - appBar.preferredSize.height,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20, left: 0, right: 0),
                        child: Column(
                          children: <Widget>[
                            AutoSizeText('Secret QR code for:',
                                //'QR Code for xxx',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: headingStyle),
                            const SizedBox(height: 15.0),
                            AutoSizeText('$userName',
                                //'QR Code for xxx',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: largeText),
                            const SizedBox(height: 15.0),
                            Container(
                              height: (MediaQuery.of(context).size.width * 0.8 < MediaQuery.of(context).size.height * 0.4)
                                  ? MediaQuery.of(context).size.width * 0.8
                                  : MediaQuery.of(context).size.height * 0.4,
                              width: (MediaQuery.of(context).size.width * 0.8 < MediaQuery.of(context).size.height * 0.4)
                                  ? MediaQuery.of(context).size.width * 0.8
                                  : MediaQuery.of(context).size.height * 0.4,
                              child: Stack(
                                alignment: AlignmentDirectional.center,
                                children: <Widget>[
                                  QrImage(
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.all(10.0),
                                      data: '$QR_PREFIX_USER_SECRET_CODE${userSecretCode.toUpperCase()}',
                                      //data: 'testing123',
                                      version: 4,
                                      //size: 200.0,
                                      errorCorrectionLevel: 3),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10.0),
                            FlatButton(
                              textColor: Colors.white,
                              child: const Text('Learn more about this feature'),
                              onPressed: () {
                                _displayInstructions(context);
                              },
                            ),
                            FancyDivider(
                              key: UniqueKey(),
                              innerColor: Colors.white,
                              topMargin: 20.0,
                              bottomMargin: 20.0,
                            ),
                            Text(
                              'Support Code:',
                              style: headingStyle,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 15.0),
                            Text(
                              supportCode ?? '<no code>',
                              style: largeText,
                              textAlign: TextAlign.center,
                            ),
                            FancyDivider(
                              key: UniqueKey(),
                              innerColor: Colors.white,
                              topMargin: 40.0,
                              bottomMargin: 30.0,
                            ),
                            Text(
                              'Reset Code:',
                              style: headingStyle,
                              textAlign: TextAlign.center,
                            ),
                            Container(
                              padding: const EdgeInsets.all(30.0),

                              //color: const Color.fromARGB(255, 255, 255, 255),
                              child: Container(
                                child: Center(
                                  child: Column(
                                    children: <Widget>[
                                      Container(
                                        //color: Colors.white,
                                        padding: const EdgeInsets.all(10.0),
                                        decoration: BoxDecoration(
                                          color: Colors.yellow[100],
                                          borderRadius: BorderRadius.circular(5.0),
                                        ),
                                        // padding: const EdgeInsets.only(
                                        //     top: 0.0, bottom: 8.0),
                                        child: TextFormField(
                                          autocorrect: false,
                                          controller: resetCodeTextController,
                                          focusNode: resetCodeFocusNode,
                                          decoration: resetCodeDecoration,
                                          // validator: (val) {
                                          //   if (val.length == 0) {
                                          //     return "Email cannot be empty";
                                          //   } else {
                                          //     return null;
                                          //   }
                                          // },
                                          keyboardType: TextInputType.text,
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 25),
                                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <Widget>[
                                          Connection.styleForConnected(
                                            G0<AppModel>().connectionStatus,
                                            RaisedButton(
                                              padding: const EdgeInsets.only(top: 8, bottom: 8, left: 20, right: 20),
                                              onPressed: () async {
                                                if (Connection.checkForConnection(context, G0<AppModel>().connectionStatus)) {
                                                  final bool result = await G0<TableModel>().syncUserDataService.updateFromBackend(SyncUserDataService.flagAllMasterData, false);
                                                  final String resultStr = result ? 'successfully' : 'unsuccessfully';
                                                  print('Master data synchronized $resultStr');

                                                  if (resetCodeTextController.text.length == 6) {
                                                    setState(() {
                                                      isLoading = true;

                                                      final AuthorizeDeviceService srv = AuthorizeDeviceService();
                                                      final Future<Map<String, String>> apiCall =
                                                          srv.authorizeDevice(context, QR_PREFIX_USER_RESET_CODE + resetCodeTextController.text.toUpperCase());
                                                      apiCall.then((Map<String, String> result) {
                                                        setState(() {
                                                          isLoading = false;
                                                        });

                                                        if (result['result'] != 'failed') {
                                                          userName = getStringPref(StringPrefsEnum.displayName);
                                                          userSecretCode = getStringPref(StringPrefsEnum.qrSecretCode);

                                                          IveCoreUtilities.showAlert(
                                                              context,
                                                              'App Reset Successful',
                                                              'Your app has been successfully reset. Please close and restart the app to ensure all data is properly reloaded.',
                                                              'OK');
                                                        }
                                                      });
                                                    });
                                                  }
                                                }
                                              },
                                              child: Text(
                                                'Reset App',
                                                style: textStyleButton,
                                              ),
                                            ),
                                          ),
                                        ]),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 25),
                                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <Widget>[
                                          Connection.styleForConnected(
                                            G0<AppModel>().connectionStatus,
                                            RaisedButton(
                                              padding: const EdgeInsets.only(top: 8, bottom: 8, left: 20, right: 20),
                                              onPressed: () async {
                                                if (Connection.checkForConnection(context, G0<AppModel>().connectionStatus)) {
                                                  final bool result = await G0<TableModel>().syncUserDataService.updateFromBackend(SyncUserDataService.flagAllMasterData, false);
                                                  final String resultStr = result ? 'successfully' : 'unsuccessfully';
                                                  print('Master data synchronized $resultStr');

                                                  if (resetCodeTextController.text.length == 6) {
                                                    setState(() {
                                                      isLoading = true;

                                                      final AuthorizeDeviceService srv = AuthorizeDeviceService();
                                                      final Future<Map<String, String>> apiCall =
                                                          srv.authorizeDevice(context, QR_PREFIX_USER_RESET_CODE + resetCodeTextController.text.toUpperCase());
                                                      apiCall.then((Map<String, String> result) {
                                                        setState(() {
                                                          isLoading = false;
                                                        });

                                                        if (result['result'] != 'failed') {
                                                          userName = getStringPref(StringPrefsEnum.displayName);
                                                          userSecretCode = getStringPref(StringPrefsEnum.qrSecretCode);

                                                          IveCoreUtilities.showAlert(
                                                              context,
                                                              'App Reset Successful',
                                                              'Your app has been successfully reset. Please close and restart the app to ensure all data is properly reloaded.',
                                                              'OK');
                                                        }
                                                      });
                                                    });
                                                  }
                                                }
                                              },
                                              child: Text(
                                                'Reload Database',
                                                style: textStyleButton,
                                              ),
                                            ),
                                          ),
                                        ]),
                                      ),
                                    ],
                                  ),
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
        OfflineModeRibbon(
          showRibbon: G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected,
          lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSyncAsDate),
          ribbonImage: 'images/icons/offline_mode.png',
        ),
      ],
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
                  style: TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 16.0, height: 1.0),
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
