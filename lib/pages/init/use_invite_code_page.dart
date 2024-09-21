import 'package:harrier_central/imports.dart';

class UseInviteCodePage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const UseInviteCodePage({
    super.key,
  });

  @override
  UseInviteCodePageState createState() => UseInviteCodePageState();
}

class UseInviteCodePageState extends State<UseInviteCodePage> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        SizedBox(height: MediaQuery.of(context).size.height, width: MediaQuery.of(context).size.width),
        Positioned(
          top: 0,
          left: 0,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Scaffold(
              appBar: AppBar(
                centerTitle: true,
                backgroundColor: themeAppBarBackground,
                iconTheme: const IconThemeData(
                  color: Colors.white,
                  size: 28.0,
                ),
                title: Text('Use Invite Code', style: ts_appBarTitle),
              ),
              body: SingleChildScrollView(
                child: Container(
                  decoration: Backgrounds.defaultHcBackground(),
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: const UseInviteCodePageContent(),
                ),
              ),
              resizeToAvoidBottomInset: false),
        ),
        OfflineModeRibbon(
          showRibbon: G0<AppModel>().connectionStatus == EnumConnectionStatus2.notConnected,
          lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSyncAsDate),
          ribbonImage: 'images/icons/offline_mode.png',
          refreshFunction: () {
            setState(() {});
          },
        ),
      ],
    );
  }
}

class UseInviteCodePageContent extends StatefulWidget {
  const UseInviteCodePageContent({
    super.key,
  });

  @override
  UseInviteCodePageContentState createState() => UseInviteCodePageContentState();
}

class UseInviteCodePageContentState extends State<UseInviteCodePageContent> {
  late TextEditingController _inviteCodeTextController;
  late InputDecoration _inviteCodeDecoration;
  final FocusNode _inviteCodeFocusNode = FocusNode();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  bool _showQrScanner = false;

  // bool _includeInGlobalHashDirectory = true;

  String _emailAddress = '';

  String _lastQrCode = '';

  String? _result;

  bool _isScanning = false;

  DateTime? _lastScan;

  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR123');

  // EQrScannerState _state = EQrScannerState.waitingForScan;

  QRViewController? _controller;
  // EQrScannerState _state = EQrScannerState.waitingForScan;
  // bool _isScanning = true;

  @override
  void initState() {
    super.initState();

    _inviteCodeTextController = TextEditingController();
    _inviteCodeDecoration = InputDecoration(
      labelText: 'Invite Code',
      fillColor: hc_red,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(),
      ),
    );
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller!.pauseCamera();
      _controller!.dispose();
    }

    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (_controller != null) {
      if (Platform.isAndroid) {
        _controller!.pauseCamera().then((void _) {
          // _isScanning = false;
          // _onScreenMessage = 'Scanning paused';
          // _state = EQrScannerState.waitingForScan;
        });
      } else if (Platform.isIOS) {
        _controller!.resumeCamera().then((void _) {
          // _isScanning = true;
          // _onScreenMessage = 'Looking for QR Code';
          // _state = EQrScannerState.scanning;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints viewportConstraints) {
      final double newFontSize = (ts_headingLarge.fontSize ?? 24.0) * G0<DeviceInfo>().deviceWidthScaleFactor;

      final TextStyle localHeadingStyle = ts_headingLarge.copyWith(fontSize: newFontSize, height: 1.2);

      return SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(width: 46.0),
                Expanded(
                  child: Text(
                    'Please enter your invite code',
                    maxLines: 3,
                    style: localHeadingStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    await Utilities.showAlert(
                        'What is an "Invite Code"?',
                        'An Invite Code is a six character code that allows you to connect to an existing account in Harrier Central.\r\n\r\nYou can ask any Harrier Central admin from your Home Kennel to provide you with your invite code using their Harrier Central app.\r\n\r\nIf you do not have an Invite Code, please go back to the previous screen and select the option to Create a New Account.',
                        'OK');
                  },
                  child: Container(
                    padding: const EdgeInsets.only(left: 20),
                    height: 26,
                    child: Image.asset('images/icons/more_info_button.png'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 35, width: 10),
            Form(
              key: _formKey,
              child: Container(
                margin: const EdgeInsets.only(left: 15, right: 15),
                padding: const EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 5),
                color: Colors.yellow[100],
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            autocorrect: false,
                            textCapitalization: TextCapitalization.characters,
                            controller: _inviteCodeTextController,
                            focusNode: _inviteCodeFocusNode,
                            decoration: _inviteCodeDecoration,
                            validator: (String? val) {
                              if (val == null) {
                                return 'Application error 1802. Please contact us at connect@harriercentral.com';
                              } else if (val.length != 6) {
                                return 'Invite codes are six characters';
                              } else {
                                return null;
                              }
                            },
                            keyboardType: TextInputType.text,
                            textAlign: TextAlign.center,
                            style: ts_titleDarkRedLarge,
                          ),
                        ),
                        const SizedBox(width: 15.0),
                        TextButton(
                            style: text_button_style.copyWith(
                                padding: const WidgetStatePropertyAll(EdgeInsets.all(8.0)), minimumSize: const WidgetStatePropertyAll(Size.zero), alignment: Alignment.center),
                            onPressed: () async {
                              setState(() {
                                _showQrScanner = !_showQrScanner;
                                if (_controller != null) {
                                  if (_showQrScanner) {
                                    _lastQrCode = '';
                                    _controller!.resumeCamera();
                                  } else {
                                    _controller!.pauseCamera();
                                  }
                                }
                              });
                            },
                            child: const Icon(MaterialCommunityIcons.qrcode_scan, color: Colors.white)),
                      ],
                    ),
                    Visibility(
                      visible: _showQrScanner,
                      maintainState: true,
                      child: Container(
                        padding: const EdgeInsets.all(11.0),
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: QRView(
                            key: _qrKey,
                            onQRViewCreated: _onQRViewCreated,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20, width: 10),
                    // Row(
                    //   children: <Widget>[
                    //     Container(
                    //       margin: const EdgeInsets.only(right: 10),
                    //       height: 25,
                    //       width: 25,
                    //       color: Colors.yellow[100],
                    //       child: Checkbox(
                    //         value: _includeInGlobalHashDirectory,
                    //         onChanged: (bool value) {
                    //           setState(() {
                    //             _includeInGlobalHashDirectory = value;
                    //             // checkDirty();
                    //           });
                    //         },
                    //       ),
                    //     ),
                    //     const Expanded(
                    //       child: Text(
                    //         'Include me in Global Hash Directory',
                    //         //style: headingStyle,
                    //         textAlign: TextAlign.center,
                    //       ),
                    //     ),
                    //     GestureDetector(
                    //       onTap: () async {
                    //         await Utilities.showAlert(
                    //             context,
                    //             'What is the Global Hash Directory?',
                    //             'The Global Hash Directory is a list of all Hashers who use Harrier Central and "opt-in" to be included in the list.\r\n\r\nWhen you select to be included in the Directory your name, home Kennel and any mismanagement roles you have will be publicly available.\r\n\r\nYou may also use Harrier Central to send short email messages to anyone else in the Directory without sharing your e-mail address.',
                    //             'OK');
                    //       },
                    //       child: Container(
                    //         padding: const EdgeInsets.only(left: 20),
                    //         height: 26,
                    //         child: Image.asset('images/icons/more_info_button.png'),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    const SizedBox(height: 8, width: 10),
                    TextButton(
                        style: text_button_style.copyWith(
                          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
                          foregroundColor: WidgetStatePropertyAll(hc_red),
                        ),
                        onPressed: () async {
                          final EmailPopup emailPopup = EmailPopup(
                            initialEmailAddress: _emailAddress,
                          );

                          final Future<Map<String, String?>?> dlg = showDialog<Map<String, String>>(
                              context: context,
                              barrierDismissible: false, // user must tap button!
                              builder: (BuildContext context) {
                                return emailPopup;
                              });

                          final Map<String, String?>? x = await dlg;
                          if (x != null) {
                            final String email = x['email'] ?? '';
                            final String type = x['type'] ?? '';

                            if (type != 'cancel') {
                              _emailAddress = email;
                              final String userMessage = await HashersService.sendInviteCodeByEmail(email);
                              await Utilities.showAlert('Instructions', userMessage, 'OK');
                            }
                          }
                        },
                        child: Text(
                          'Email me a new invite code',
                          style: ts_title.copyWith(color: hc_red),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 35, width: 10),
            _isLoading
                ? Text(
                    'Please wait...',
                    style: localHeadingStyle,
                    textAlign: TextAlign.center,
                  )
                : TextButton(
                    style: text_button_style,
                    child: Text('Get Started!', style: ts_button),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        // If the form is valid, display a snackbar. In the real world,
                        // you'd often call a server or save the information in a database.
                        setState(() {
                          _isLoading = true;
                        });

                        final AuthorizeDeviceService srv = AuthorizeDeviceService();
                        final Map<String, String> result = await srv.authorizeDevice(context, QR_PREFIX_USER_RESET_CODE + _inviteCodeTextController.text.toUpperCase(),
                            //includeInGlobalHashDirectory: _includeInGlobalHashDirectory ? 1 : 0);
                            includeInGlobalHashDirectory: 0);

                        setState(() {
                          _isLoading = false;
                        });

                        if (result['result'] != 'failed') {
                          final String userName = getStringPref(StringPrefsEnum.displayName) ?? '<no name>';

                          String? profilePhotoUrl = getStringPref(StringPrefsEnum.profilePhotoUrl);
                          profilePhotoUrl ??= 'bundle://avatar-${Random.secure().nextInt(49) + 1}';

                          await Utilities.showAlert('Success!', 'The app has been successfully set up for $userName.', 'OK');

                          Navigator.pop(navigatorKey.currentContext!);
                          if (!mounted) return;
                          await Navigator.pushReplacement<dynamic, dynamic>(
                              navigatorKey.currentContext!,
                              MaterialPageRoute<dynamic>(
                                builder: (BuildContext context) => ChooseProfileImage(
                                  isForThisDevice: true,
                                  fileNamePrefix: getStringPref(StringPrefsEnum.supportCode) ?? '<no code>',
                                  currentProfileImage: profilePhotoUrl,
                                  popToCaller: false,
                                ),
                              ));
                        } else {
                          // TODO(James): Do something here if the auth device fails
                        }
                      }
                    },
                  ),
            const SizedBox(height: 50, width: 10),
          ],
        ),
      );
    });
  }

  Future<void> _onCodeRead(String? scanResult) async {
    if (((scanResult ?? '').isNotEmpty) && _showQrScanner && (_lastQrCode != scanResult)) {
      _lastQrCode = scanResult!;
      final Map<String, String> result = Utilities.validateScan(scanResult, Utilities.qrScanTypeFlag_resetCode);
      await _controller!.pauseCamera();
      setState(() {
        _showQrScanner = false;
      });

      if (result['validScan'] == 'false') {
        await Utilities.showAlert(
            'Wrong QR Code', 'The QR Code you scanned is not a valid Harrier Central invite code. Please use a proper invite code or manually type in your invite code on this screen.', 'OK');
      } else {
        setState(() {
          _inviteCodeTextController.text = scanResult.replaceAll(QR_PREFIX_USER_RESET_CODE, '');
        });
      }
    }
  }

  Future<void> _toggleScanning({bool? doScanning}) async {
    if (_controller != null) {
      if (_isScanning && ((doScanning == null) || !doScanning)) {
        await _controller!.pauseCamera();
        _isScanning = false;
        //_state = EQrScannerState.waitingForScan;
      } else {
        if ((doScanning == null) || doScanning) {
          await _controller!.resumeCamera();
          _isScanning = true;
          // _state = EQrScannerState.scanning;
        }
      }
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    _controller = controller;
    setState(() {
      // _isScanning = true;
      // _onScreenMessage = 'Looking for QR Code';
      // _state = EQrScannerState.scanning;
      //_toggleScanning();
    });

    if (_controller != null) {
      _controller!.scannedDataStream.listen((Barcode scanData) async {
        _result = scanData.code;
        // "debounce" the listener to discard multiple scans
        // that happen within a 5 second window.
        if ((_lastScan == null) || (_lastScan!.difference(DateTime.now()).inSeconds.abs() > 5)) {
          _lastScan = DateTime.now();
          await _toggleScanning();
          await _onCodeRead(_result);
        }
      });
    }
  }
}
