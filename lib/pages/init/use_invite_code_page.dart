// @dart=2.11
import 'package:harrier_central/imports.dart';

class UseInviteCodePage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const UseInviteCodePage({Key key}) : super(key: key);

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
                title: const Text(
                  'Use Invite Code',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
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
          showRibbon: G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected,
          lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSyncAsDate),
          ribbonImage: 'images/icons/offline_mode.png',
        ),
      ],
    );
  }
}

class UseInviteCodePageContent extends StatefulWidget {
  const UseInviteCodePageContent({Key key}) : super(key: key);

  @override
  _UseInviteCodePageContentState createState() => _UseInviteCodePageContentState();
}

class _UseInviteCodePageContentState extends State<UseInviteCodePageContent> {
  TextEditingController _inviteCodeTextController;
  InputDecoration _inviteCodeDecoration;
  final FocusNode _inviteCodeFocusNode = FocusNode();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  bool _showQrScanner = false;

  bool _includeInGlobalHashDirectory = true;

  String _emailAddress = '';

  String _lastQrCode = '';

  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR123');

  final MobileScannerController _controller = MobileScannerController();
  // EQrScannerState _state = EQrScannerState.waitingForScan;
  // bool _isScanning = true;

  @override
  void initState() {
    super.initState();

    _inviteCodeTextController = TextEditingController();
    _inviteCodeDecoration = InputDecoration(
      labelText: 'Invite Code',
      fillColor: Colors.red,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(),
      ),
    );
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller.stop();
      _controller.dispose();
    }

    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (_controller != null) {
      if (Platform.isAndroid) {
        _controller.stop().then((_) {
          // _isScanning = false;
          // _onScreenMessage = 'Scanning paused';
          // _state = EQrScannerState.waitingForScan;
        });
      } else if (Platform.isIOS) {
        _controller.start().then((_) {
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
      final num newFontSize = headingStyle.fontSize * G0<DeviceInfo>().deviceWidthScaleFactor;

      final TextStyle localHeadingStyle = headingStyle.copyWith(fontSize: newFontSize, height: 1.2);

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
                    await IveCoreUtilities.showAlert(
                        context,
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
                            validator: (String val) {
                              if (val.length != 6) {
                                return 'Invite codes are six characters';
                              } else {
                                return null;
                              }
                            },
                            keyboardType: TextInputType.text,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 24.0, color: Colors.red.shade900),
                          ),
                        ),
                        const SizedBox(width: 15.0),
                        TextButton(
                            child: const Icon(MaterialCommunityIcons.qrcode_scan, color: Colors.white),
                            style: TextButton.styleFrom(padding: const EdgeInsets.all(8.0), minimumSize: Size.zero, alignment: Alignment.center),
                            onPressed: () async {
                              setState(() {
                                _showQrScanner = !_showQrScanner;
                                if (_showQrScanner) {
                                  _lastQrCode = '';
                                  _controller.start();
                                } else {
                                  _controller.stop();
                                }
                              });
                            }),
                      ],
                    ),
                    Visibility(
                      visible: _showQrScanner,
                      maintainState: true,
                      child: Container(
                        padding: const EdgeInsets.all(11.0),
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: MobileScanner(
                            allowDuplicates: true,
                            key: _qrKey,
                            controller: _controller,
                            onDetect: (Barcode barcode, MobileScannerArguments args) async {
                              await _onCodeRead(barcode.rawValue);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20, width: 10),
                    Row(
                      children: <Widget>[
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          height: 25,
                          width: 25,
                          color: Colors.yellow[100],
                          child: Checkbox(
                            value: _includeInGlobalHashDirectory,
                            onChanged: (bool value) {
                              setState(() {
                                _includeInGlobalHashDirectory = value;
                                // checkDirty();
                              });
                            },
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Include me in Global Hash Directory',
                            //style: headingStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            await IveCoreUtilities.showAlert(
                                context,
                                'What is the Global Hash Directory?',
                                'The Global Hash Directory is a list of all Hashers who use Harrier Central and "opt-in" to be included in the list.\r\n\r\nWhen you select to be included in the Directory your name, home Kennel and any mismanagement roles you have will be publicly available.\r\n\r\nYou may also use Harrier Central to send short email messages to anyone else in the Directory without sharing your e-mail address.',
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
                    const SizedBox(height: 8, width: 10),
                    TextButton(
                        child: const Text('Email me a new invite code'),
                        style: TextButton.styleFrom(backgroundColor: Colors.transparent, primary: Colors.red.shade800),
                        onPressed: () async {
                          final EmailPopup emailPopup = EmailPopup(
                            initialEmailAddress: _emailAddress,
                          );

                          final Future<Map<String, String>> dlg = showDialog<Map<String, String>>(
                              context: context,
                              barrierDismissible: false, // user must tap button!
                              builder: (BuildContext context) {
                                return emailPopup;
                              });

                          final Map<String, String> x = await dlg;
                          final String email = x['email'];
                          final String type = x['type'];

                          if (type != 'cancel') {
                            _emailAddress = email;
                            final String userMessage = await HashersService.sendInviteCodeByEmail(email);
                            await IveCoreUtilities.showAlert(navigatorKey.currentContext, 'Instructions', userMessage, 'OK');
                          }
                        }),
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
                    child: Text('Get Started!', style: textStyleButton),
                    onPressed: () async {
                      if (_formKey.currentState.validate()) {
                        // If the form is valid, display a snackbar. In the real world,
                        // you'd often call a server or save the information in a database.
                        setState(() {
                          _isLoading = true;
                        });

                        final AuthorizeDeviceService srv = AuthorizeDeviceService();
                        final Map<String, String> result = await srv.authorizeDevice(context, QR_PREFIX_USER_RESET_CODE + _inviteCodeTextController.text.toUpperCase(),
                            includeInGlobalHashDirectory: _includeInGlobalHashDirectory ? 1 : 0);

                        setState(() {
                          _isLoading = false;
                        });

                        if (result['result'] != 'failed') {
                          final String userName = getStringPref(StringPrefsEnum.displayName);

                          String profilePhotoUrl = getStringPref(StringPrefsEnum.profilePhotoUrl);
                          profilePhotoUrl ??= 'bundle://avatar-' + (Random.secure().nextInt(49) + 1).toString();

                          await IveCoreUtilities.showAlert(context, 'Success!', 'The app has been successfully set up for $userName.', 'OK');
                          await Navigator.pushReplacement<dynamic, dynamic>(
                              context,
                              MaterialPageRoute<dynamic>(
                                builder: (BuildContext context) => ChooseProfileImage(
                                  isForThisDevice: true,
                                  fileNamePrefix: getStringPref(StringPrefsEnum.supportCode),
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

  Future<void> _onCodeRead(String scanResult) async {
    if (_showQrScanner && (_lastQrCode != scanResult)) {
      _lastQrCode = scanResult;
      final Map<String, String> result = Utilities.validateScan(scanResult, Utilities.qrScanTypeFlag_resetCode);
      await _controller.stop();
      setState(() {
        _showQrScanner = false;
      });

      if (result['validScan'] == 'false') {
        await IveCoreUtilities.showAlert(
            context, 'Wrong QR Code', 'The QR Code you scanned is not a valid Harrier Central invite code. Please use a proper invite code or manually type in your invite code on this screen.', 'OK');
      } else {
        _inviteCodeTextController.text = scanResult.replaceAll(QR_PREFIX_USER_RESET_CODE, '');
      }
    }
  }
}
