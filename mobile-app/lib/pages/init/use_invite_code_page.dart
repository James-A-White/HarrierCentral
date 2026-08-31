import 'package:harrier_central/imports.dart';

class UseInviteCodePage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const UseInviteCodePage({super.key});

  @override
  UseInviteCodePageState createState() => UseInviteCodePageState();
}

class UseInviteCodePageState extends State<UseInviteCodePage> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        SizedBox(
          height: MediaQuery.sizeOf(context).height,
          width: MediaQuery.sizeOf(context).width,
        ),
        Positioned(
          top: 0,
          left: 0,
          width: MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).height,
          child: AppScaffold(
            appBar: AppBar(
              centerTitle: true,
              backgroundColor: themeAppBarBackground,
              iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
              title: Text('Use Invite Code', style: ts_appBarTitle),
            ),
            body: SingleChildScrollView(
              child: Container(
                decoration: Backgrounds.defaultHcBackground(),
                height: MediaQuery.sizeOf(context).height,
                width: MediaQuery.sizeOf(context).width,
                child: const UseInviteCodePageContent(),
              ),
            ),
            resizeToAvoidBottomInset: false,
          ),
        ),
        OfflineModeRibbon(
          lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSync),
          ribbonImage: 'images/icons/offline_mode.png',
          refreshFunction: () {
            setStateIfMounted(() {});
          },
        ),
      ],
    );
  }
}

class UseInviteCodePageContent extends StatefulWidget {
  const UseInviteCodePageContent({super.key});

  @override
  UseInviteCodePageContentState createState() =>
      UseInviteCodePageContentState();
}

class UseInviteCodePageContentState extends State<UseInviteCodePageContent> {
  late TextEditingController _inviteCodeTextController;
  late InputDecoration _inviteCodeDecoration;
  final FocusNode _inviteCodeFocusNode = FocusNode();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  /// Failed "code not found" attempts. Mistyping a six-letter code is easy, so
  /// there is no attempt limit — this only decides when to also *offer* a way
  /// onward, for someone who has checked the code and knows it is right.
  int _notFoundAttempts = 0;

  bool _showQrScanner = false;

  // bool _includeInGlobalHashDirectory = true;

  String _emailAddress = '';

  String _lastQrCode = '';

  String? _result;

  bool _isScanning = false;

  DateTime? _lastScan;

  //final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR123');

  // EQrScannerState _state = EQrScannerState.waitingForScan;

  MobileScannerController? _scannerController;
  // EQrScannerState _state = EQrScannerState.waitingForScan;
  // bool _isScanning = true;

  @override
  void initState() {
    super.initState();

    _scannerController = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: [BarcodeFormat.qrCode],
    );

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
    if (_scannerController != null) {
      unawaited(
        Future.microtask(() async {
          await _scannerController!.stop();
          unawaited(_scannerController!.dispose());
        }),
      );
    }
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    final c = _scannerController;
    if (c == null) return;

    // Only meaningful during hot-reload (debug)
    assert(() {
      if (Platform.isAndroid) {
        // Use pause()/resume() if available; otherwise swap to stop()/start()
        unawaited(
          c
              .pause()
              .then((_) {
                if (!mounted) return;
                setStateIfMounted(() {
                  _isScanning = false;
                  // _onScreenMessage = 'Scanning paused';
                  // _state = EQrScannerState.waitingForScan;
                });
              })
              .catchError((e, st) {
                // Optional: log pause error
              }),
        );
      } else if (Platform.isIOS) {
        unawaited(
          c
              .start()
              .then((_) {
                if (!mounted) return;
                setStateIfMounted(() {
                  _isScanning = true;
                  // _onScreenMessage = 'Looking for QR Code';
                  // _state = EQrScannerState.scanning;
                });
              })
              .catchError((e, st) {
                // Optional: log start error
              }),
        );
      }
      return true;
    }());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints viewportConstraints) {
        final double newFontSize =
            (ts_headingLarge.fontSize ?? 24.0) *
            deviceInfo.deviceWidthScaleFactor;

        final TextStyle localHeadingStyle = ts_headingLarge.copyWith(
          fontSize: newFontSize,
          height: 1.2,
        );

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
                        'OK',
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.only(left: 20),
                      height: 26,
                      child: Image.asset('images/icons/info_button.png'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 35, width: 10),
              Form(
                key: _formKey,
                child: Container(
                  margin: const EdgeInsets.only(left: 15, right: 15),
                  padding: const EdgeInsets.only(
                    left: 15,
                    right: 15,
                    top: 15,
                    bottom: 5,
                  ),
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
                                  return 'Application error 1802. Please contact us at harriercentral@gmail.com';
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
                              padding: const WidgetStatePropertyAll(
                                EdgeInsets.all(8.0),
                              ),
                              minimumSize: const WidgetStatePropertyAll(
                                Size.zero,
                              ),
                              alignment: Alignment.center,
                            ),
                            onPressed: () async {
                              setStateIfMounted(() {
                                _showQrScanner = !_showQrScanner;
                                if (_scannerController != null) {
                                  if (_showQrScanner) {
                                    _lastQrCode = '';
                                    unawaited(_scannerController!.start());
                                  } else {
                                    unawaited(_scannerController!.pause());
                                  }
                                }
                              });
                            },
                            child: const Icon(
                              MaterialCommunityIcons.qrcode_scan,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Visibility(
                        visible: _showQrScanner,
                        maintainState: true,
                        child: Container(
                          padding: const EdgeInsets.all(11.0),
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child:
                                // QRView(
                                //   key: _qrKey,
                                //   onQRViewCreated: _onQRViewCreated,
                                // ),
                                MobileScanner(
                                  controller: _scannerController,
                                  onDetect: (result) async {
                                    if (result.barcodes.isEmpty) return;
                                    _result = result.barcodes.first.rawValue;

                                    if ((_lastScan == null) ||
                                        (_lastScan!
                                                .difference(DateTime.now())
                                                .inSeconds
                                                .abs() >
                                            5)) {
                                      _lastScan = DateTime.now();
                                      await _toggleScanning();
                                      if (_result != null) {
                                        await _onCodeRead(_result!);
                                      }
                                    }
                                  },
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
                      //           setStateIfMounted(() {
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
                      //         child: Image.asset('images/icons/info_button.png'),
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      const SizedBox(height: 16, width: 10),
                      _isLoading
                          ? Text(
                              'Please wait...',
                              // Dark on the pale-yellow card — the page's
                              // yellow heading style is invisible here.
                              style: localHeadingStyle.copyWith(
                                color: themeAppBarBackground,
                              ),
                              textAlign: TextAlign.center,
                            )
                          : SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                style: text_button_style,
                                child: Text('Get Started!', style: ts_button),
                                onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          // If the form is valid, display a snackbar. In the real world,
                          // you'd often call a server or save the information in a database.
                          setStateIfMounted(() {
                            _isLoading = true;
                          });

                          final AuthorizeDeviceService srv =
                              AuthorizeDeviceService();
                          final Map<String, String> result = await srv
                              .authorizeDevice(
                                scanText: normalizeInviteCode(
                                  _inviteCodeTextController.text,
                                ),
                              );

                          setStateIfMounted(() {
                            _isLoading = false;
                          });

                          if (result['result'] != 'failed') {
                            final String userName =
                                getStringPref(StringPrefsEnum.displayName) ??
                                '<no name>';

                            String? profilePhotoUrl = getStringPref(
                              StringPrefsEnum.profilePhotoUrl,
                            );
                            profilePhotoUrl ??=
                                bundledAvatarUrl(Random.secure().nextInt(49) + 1);

                            await Utilities.showAlert(
                              'Success!',
                              'The app has been successfully set up for $userName.',
                              'OK',
                            );

                            Navigator.pop(navigatorKey.currentContext!);
                            if (!mounted) return;
                            await Navigator.pushReplacement<dynamic, dynamic>(
                              navigatorKey.currentContext!,
                              MaterialPageRoute<dynamic>(
                                builder: (BuildContext context) =>
                                    ChooseProfileImage(
                                      isForThisDevice: true,
                                      fileNamePrefix:
                                          getStringPref(
                                            StringPrefsEnum.supportCode,
                                          ) ??
                                          '<no code>',
                                      currentProfileImage: profilePhotoUrl,
                                      popToCaller: false,
                                    ),
                              ),
                            );
                          } else {
                            final int? errorCode = int.tryParse(
                              result['errorCode'] ?? '',
                            );

                            if (errorCode == DB_ERROR_ACCOUNT_REMOVED) {
                              // The code was entered CORRECTLY — it resolved to
                              // a real account that has since been removed. Never
                              // ask them to retype it; that is an endless loop.
                              // They may still have a second, live account (a
                              // kennel admin may have created one for them), so
                              // send them to look themselves up.
                              await Utilities.showAlert(
                                'Let\'s find your account',
                                'That invite code is no longer active.'
                                '\r\n\r\nEnter your hash name or email address '
                                'and we\'ll find your account.',
                                'Continue',
                              );
                              if (!mounted) return;
                              await OnboardingFlowController.start(
                                OnboardingDestination.findMyAccount,
                              );
                              return;
                            }

                            if (errorCode == DB_ERROR_INVITE_CODE_NOT_FOUND) {
                              _notFoundAttempts++;

                              // After a couple of misses, also offer a way on —
                              // by then it is more likely the code is stale than
                              // mistyped. Retrying stays the default action.
                              if (_notFoundAttempts >= 2) {
                                final bool findAccount =
                                    await Utilities.showAlert(
                                      'Code not found',
                                      'We couldn\'t find that invite code.'
                                      '\r\n\r\nIf you\'re sure it\'s right it may '
                                      'have expired — we can look up your '
                                      'account instead.',
                                      'Find my account',
                                      showCancelButton: true,
                                    ) ??
                                    false;
                                if (findAccount) {
                                  if (!mounted) return;
                                  await OnboardingFlowController.start(
                                    OnboardingDestination.findMyAccount,
                                  );
                                  return;
                                }
                              } else {
                                await Utilities.showAlert(
                                  'Code not found',
                                  'We couldn\'t find that invite code. Please '
                                  'check it and try again.',
                                  'OK',
                                );
                              }
                              return;
                            }

                            await Utilities.showAlert(
                              'Setup failed',
                              result['message'] ??
                                  'We could not set up your device. Please check your invite code and try again.',
                              'OK',
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
              const SizedBox(height: 20, width: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: text_button_style,
                  onPressed: () async {
                    final EmailPopup emailPopup = EmailPopup(
                      initialEmailAddress: _emailAddress,
                    );
                    final Future<Map<String, String?>?> dlg =
                        showDialog<Map<String, String>>(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return emailPopup;
                          },
                        );
                    final Map<String, String?>? x = await dlg;
                    if (x != null) {
                      final String email = x['email'] ?? '';
                      final String type = x['type'] ?? '';
                      if (type != 'cancel') {
                        _emailAddress = email;
                        final String userMessage =
                            await HashersService.sendInviteCodeByEmail(email);
                        await Utilities.showAlert(
                          'Instructions',
                          userMessage,
                          'OK',
                        );
                      }
                    }
                  },
                  child: Text('Email me a new invite code', style: ts_button),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: text_button_style.copyWith(
                    backgroundColor: const WidgetStatePropertyAll(Colors.grey),
                  ),
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const EmailNotReceivedPage(),
                    ),
                  ),
                  child: Text("I didn't receive an email", style: ts_button),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onCodeRead(String scanResult) async {
    if ((scanResult.isNotEmpty) &&
        _showQrScanner &&
        (_lastQrCode != scanResult)) {
      _lastQrCode = scanResult;
      final Map<String, String> result = Utilities.validateScan(
        scanResult,
        Utilities.qrScanTypeFlag_resetCode +
            Utilities.qrScanTypeFlag_userSecretCode,
      );
      await _scannerController!.pause();
      setStateIfMounted(() {
        _showQrScanner = false;
      });

      if (result['validScan'] == 'false') {
        await Utilities.showAlert(
          'Wrong QR Code',
          'The QR Code you scanned is not a valid Harrier Central invite code. Please use a proper invite code or manually type in your invite code on this screen.',
          'OK',
        );
      } else {
        setStateIfMounted(() {
          _inviteCodeTextController.text = scanResult.replaceAll(
            QR_PREFIX_USER_RESET_CODE,
            '',
          );
        });
      }
    }
  }

  Future<void> _toggleScanning({bool? doScanning}) async {
    if (_scannerController != null) {
      if (_isScanning && ((doScanning == null) || !doScanning)) {
        await _scannerController!.pause();
        _isScanning = false;
        //_state = EQrScannerState.waitingForScan;
      } else {
        if ((doScanning == null) || doScanning) {
          await _scannerController!.start();
          _isScanning = true;
          // _state = EQrScannerState.scanning;
        }
      }
    }
  }

  // void _onQRViewCreated(QRViewController controller) {
  //   _scannerController = controller;
  //   setStateIfMounted(() {
  //     // _isScanning = true;
  //     // _onScreenMessage = 'Looking for QR Code';
  //     // _state = EQrScannerState.scanning;
  //     //_toggleScanning();
  //   });

  //   if (_scannerController != null) {
  //     _scannerController!.scannedDataStream.listen((Barcode scanData) async {
  //       _result = scanData.code;
  //       // "debounce" the listener to discard multiple scans
  //       // that happen within a 5 second window.
  //       if ((_lastScan == null) ||
  //           (_lastScan!.difference(DateTime.now()).inSeconds.abs() > 5)) {
  //         _lastScan = DateTime.now();
  //         await _toggleScanning();
  //         await _onCodeRead(_result);
  //       }
  //     });
  //   }
  // }
}
