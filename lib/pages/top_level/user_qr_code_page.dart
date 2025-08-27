import 'package:harrier_central/imports.dart';

import 'package:intl/intl.dart';

class UserQrCodePage extends StatefulWidget {
  const UserQrCodePage({super.key});

  @override
  UserQrCodePageState createState() => UserQrCodePageState();
}

class UserQrCodePageState extends State<UserQrCodePage>
    with SingleTickerProviderStateMixin {
  final List<Tab> _tabs = <Tab>[];

  //PageController _pageController;
  late TabController _tabController;

  late AppBar _appBar;

  @override
  void initState() {
    _initTabs();
    _tabController = TabController(vsync: this, length: _tabs.length);

    _appBar = AppBar(
      centerTitle: true,
      backgroundColor: themeAppBarBackground,
      iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
      actions: <IconButton>[
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            _displayInstructions(context);
          },
        ),
      ],
      title: Text('Run check in page', style: ts_appBarTitle),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
        ),
        Positioned(
          top: 0,
          left: 0,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Scaffold(
            appBar: _appBar,
            body: Container(
              decoration: Backgrounds.defaultHcBackground(),
              child: Stack(
                alignment: AlignmentDirectional.center,
                children: <Widget>[
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      width: 340.0,
                      height: 45.0,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColorLight,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(35.0),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 1.0, right: 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(999),
                          ),
                          padding: const EdgeInsets.all(5.0),
                          // Reviewed for 2.0+
                          child: TabBar(
                            labelStyle: ts_tabSelected,
                            unselectedLabelStyle: ts_tabUnselected,
                            isScrollable: false,
                            unselectedLabelColor: Colors.black,
                            labelColor: Colors.white,
                            labelPadding: const EdgeInsets.only(
                              top: 5,
                              left: 20,
                              right: 20,
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BoxDecoration(
                              color: hc_red,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            indicatorColor:
                                Colors
                                    .transparent, // make sure underline isn’t drawn
                            // BubbleTabIndicator(
                            //   indicatorHeight: 35.0,
                            //   indicatorColor: hc_red,
                            //   tabBarIndicatorSize: TabBarIndicatorSize.tab,
                            //   indicatorRadius: 20.0,
                            // ),
                            tabs: _tabs,
                            controller: _tabController,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 80,
                    bottom: 0,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: TabBarView(
                        controller: _tabController,
                        children: const <Widget>[QrScannerTab(), QrCodeTab()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    //_pageController?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<bool?> _displayInstructions(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Your QR Code', style: ts_alertDialogTitle),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  _tabController.index == 0
                      ?
                      //'This QR code allows other Hashers to quickly scan you using their Harrier Central apps.\r\n\r\nAny Hasher can scan this code to easily add you as their friend.\r\n\r\nHares and mis-management can use this code to scan you in at the beginning and end of runs in order to keep your run counts accurate and ensure that no one is left behind on trail at the end of a run.',
                      'Mis-management can scan this code to keep your run counts accurate and ensure that no one is left behind on trail at the end of a run.\r\n\r\nThis is your unique code. If you don\'t normally carry a phone, you can //print this code as a way to be quickly checked in at Hash runs.'
                      : 'You can use your QR scanner to check in when you arrive at runs and to check in when you are done with trail so the hares know who is still out on trail.',
                  //'You can use your QR scanner to add friends to your Harrier Central friend list simply by scanning their personal QR code.\r\n\r\nYou can also use your scanner to check in when you arrive at runs and to check in when you are done with trail so the hares know who is still out.',
                  textAlign: TextAlign.justify,
                  style: ts_alertDialogBody,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: text_button_style,
              child: Text('OK, Got it!', style: ts_button),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  // Widget _buildMenuBar(BuildContext context) {
  //   return Container(
  //     width: 300.0,
  //     height: 50.0,
  //     decoration: const BoxDecoration(
  //       color: Color(0x552B2B2B),
  //       borderRadius: BorderRadius.all(Radius.circular(25.0)),
  //     ),
  //     child: CustomPaint(
  //       painter: TabIndicationPainter(
  //           context: context, pageController: _pageController),
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //         children: <Widget>[
  //           Expanded(
  //             child:             TextButton(
  //               splashColor: Colors.transparent,
  //               highlightColor: Colors.transparent,
  //               onPressed: _onSwitchToQrScanner,
  //               child: Text(
  //                 'Scan',
  //                 style: const TextStyle(
  //                     color: left,
  //                     fontSize: 14.0,
  //                     fontFamily: 'WorkSansSemiBold'),
  //               ),
  //             ),
  //           ),
  //           Expanded(
  //             child:             TextButton(
  //               splashColor: Colors.transparent,
  //               highlightColor: Colors.transparent,
  //               onPressed: _onSwitchToQrCode,
  //               child: Text(
  //                 'My Scanner',
  //                 style: const TextStyle(
  //                     color: right,
  //                     fontSize: 14.0,
  //                     fontFamily: 'WorkSansSemiBold'),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  void _initTabs() {
    if (_tabs.isEmpty) {
      _tabs.add(const Tab(text: 'Scan'));
      _tabs.add(const Tab(text: 'Be Scanned'));
    }
  }

  // void _onSwitchToQrCode() {
  //   _pageController.animateToPage(0,
  //       duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
  // }

  // void _onSwitchToQrScanner() {
  //   _pageController?.animateToPage(1,
  //       duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
  // }
}

class QrCodeTab extends StatefulWidget {
  const QrCodeTab({super.key});

  @override
  QrCodeTabState createState() => QrCodeTabState();
}

class QrCodeTabState extends State<QrCodeTab>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final String userName = getStringPref(StringPrefsEnum.displayName) ?? '';
    final String userQrCode = getStringPref(StringPrefsEnum.qrCode) ?? '';

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        //print('Height = ${constraints.maxHeight}');
        //print('Width = ${constraints.maxWidth}');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                width: 10,
                height: (deviceInfo.deviceWidthScaleFactor - 1) * 90,
              ),
              Container(
                padding: const EdgeInsets.only(
                  top: 0,
                  bottom: 30,
                  right: 25,
                  left: 25,
                ),
                child: Text(
                  'This code can be scanned by mismanagement to check you in at the beginning and end of runs.',
                  textAlign: TextAlign.justify,
                  style: ts_titleMedium.copyWith(
                    fontSize: 16.0 * deviceInfo.deviceWidthScaleFactor,
                  ),
                ),
              ),

              AutoSizeText(
                'QR for: $userName',
                //'QR Code for xxx',
                textAlign: TextAlign.center,
                maxLines: 1,
                style: ts_titleMedium.copyWith(
                  fontSize: 24.0 * deviceInfo.deviceWidthScaleFactor,
                ),
              ),

              // Positioned(
              //   top: 127,

              //   child: Container(
              //                       color: Colors.white,
              //     height: MediaQuery.of(context).size.width * 0.8,
              //     width: MediaQuery.of(context).size.width * 0.8,
              //   ),
              // ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 20,
                    bottom: 10,
                    left: 30,
                    right: 30,
                  ),
                  child: Stack(
                    alignment: AlignmentDirectional.center,
                    //height: min(constraints.maxHeight, constraints.maxWidth) * 0.65,
                    children: <Widget>[
                      QrImageView(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(10.0),
                        data: BASE_HCWEB_MOBILE_URL + userQrCode,
                        //data: 'testing123',
                        version: 5,
                        //size: 200.0,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class QrScannerTab extends StatefulWidget {
  const QrScannerTab({super.key});

  @override
  QrScannerTabState createState() => QrScannerTabState();
}

enum EQrScannerState {
  waitingForScan,
  scanning,
  isProcessing,
  qrNotRecognized,
  dataRecorded,
}

class QrScannerTabState extends State<QrScannerTab>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  String _onScreenMessage = 'Scanning paused';

  MobileScannerController? _scannerController;
  EQrScannerState _state = EQrScannerState.waitingForScan;
  bool _isScanning = false;
  // bool _isProcessing = false;
  // bool _dataRecorded = false;

  //final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void initState() {
    _scannerController = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: [BarcodeFormat.qrCode],
    );

    super.initState();
  }

  @override
  void dispose() {
    if (_scannerController != null) {
      Future.microtask(() async {
        await _scannerController!.stop();
        _scannerController!.dispose();
      });
    }
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  //
  //
  //
  //
  //
  //
  //
  // QR Code Scanner support
  //
  //
  //
  //
  //
  //

  DateTime? _lastScan;

  @override
  void reassemble() {
    super.reassemble();
    final c = _scannerController;
    if (c == null) return;

    // Only meaningful during hot-reload (debug)
    assert(() {
      if (Platform.isAndroid) {
        // Use pause()/resume() if available; otherwise swap to stop()/start()
        c
            .pause()
            .then((_) {
              if (!mounted) return;
              setState(() {
                _isScanning = false;
                _onScreenMessage = 'Scanning paused';
                _state = EQrScannerState.waitingForScan;
              });
            })
            .catchError((e, st) {
              // Optional: log pause error
            });
      } else if (Platform.isIOS) {
        c
            .start()
            .then((_) {
              if (!mounted) return;
              setState(() {
                _isScanning = true;
                _onScreenMessage = 'Looking for QR Code';
                _state = EQrScannerState.scanning;
              });
            })
            .catchError((e, st) {
              // Optional: log start error
            });
      }
      return true;
    }());
  }

  Future<void> _toggleScanning({bool? doScanning}) async {
    if (_scannerController != null) {
      if (_isScanning && ((doScanning == null) || !doScanning)) {
        await _scannerController!.pause();
        _isScanning = false;
        setState(() {
          _onScreenMessage = 'Scanning paused';
        });
        _state = EQrScannerState.waitingForScan;
      } else {
        if ((doScanning == null) || doScanning) {
          await _scannerController!.start();
          _isScanning = true;
          setState(() {
            _onScreenMessage = 'Looking for QR Code';
          });
          _state = EQrScannerState.scanning;
        }
      }
    }
  }

  //   // return Future<void>(() {});(() {});
  // }

  Future<void> _onCodeRead(String scanResult) async {
    // final AudioPlayer audioPlayer = AudioPlayer();
    // // ignore: unawaited_futures
    // audioPlayer.play(AssetSource('assets/sounds/camera.mp3'));

    final player = AudioPlayer();
    await player.setAsset('assets/sounds/camera.mp3'); // or setFilePath/setUrl
    //NOTE: Unawaited future is OK
    await player.play();
    await player.dispose();

    setState(() {
      _onScreenMessage = 'Processing QR Scan';
      _state = EQrScannerState.isProcessing;
    });
    //await stopScanning();

    //final Map<String,String> result = Utilities.validateScan(scanResult, Utilities.qrScanTypeFlag_user | Utilities.qrScanTypeFlag_kennelRunEnd| Utilities.qrScanTypeFlag_kennelRunStart| Utilities.qrScanTypeFlag_runStart| Utilities.qrScanTypeFlag_runEnd);
    final Map<String, String> result = Utilities.validateScan(
      scanResult,
      //Utilities.qrScanTypeFlag_user |
      Utilities.qrScanTypeFlag_runStart |
          Utilities.qrScanTypeFlag_runEnd |
          Utilities.qrScanTypeFlag_kennelRunEnd |
          Utilities.qrScanTypeFlag_kennelRunStart |
          Utilities.qrScanTypeFlag_authenticateWebPortal,
    );

    if (result['validScan'] == 'false') {
      setState(() {
        _state = EQrScannerState.qrNotRecognized;
        _onScreenMessage =
            result['validHcQr'] == 'true'
                ? 'This QR code is not valid here'
                : 'QR code not recignized';
      });
    } else {
      final String prefix = result['prefix'] ?? '';
      final String scanData = result['content'] ?? '';

      if ((prefix == QR_PREFIX_SPECIFIC_RUN_START) ||
          (prefix == QR_PREFIX_SPECIFIC_RUN_END)) {
        final int attendenceState =
            (prefix == QR_PREFIX_SPECIFIC_RUN_START)
                ? attendenceAtHash.value
                : attendenceOnIn.value;

        final String userId = getStringPref(StringPrefsEnum.userId)!;

        final List<dynamic> adHocData = await tableModel.hasherEventMapService
            .setEventAttendence(
              scanData,
              userId,
              AppDomainType.user,
              attendenceState,
              isHare: isHareNo.value,
            );

        setState(() {
          _state = EQrScannerState.dataRecorded;
          if (adHocData.isNotEmpty) {
            _onScreenMessage = adHocData[0]['userMessage'];
          } else {
            _onScreenMessage = 'Processing Complete';
          }
        });
      } else if ((prefix == QR_PREFIX_KENNEL_GENERIC_RUN_END) ||
          (prefix == QR_PREFIX_KENNEL_GENERIC_RUN_START)) {
        final int attendenceState =
            prefix == QR_PREFIX_KENNEL_GENERIC_RUN_START
                ? attendenceAtHash.value
                : attendenceOnIn.value;

        // the eventId variable can either have the number of hours
        // to the closest event or an actual eventId for one event
        final String queryResult = await CommonQueries.getClosestEventInTime(
          scanData,
        );
        if (double.tryParse(queryResult) != null) {
          final double? hoursUntilNextEvent = double.tryParse(
            queryResult.replaceAll(',', '.'),
          );
          if (hoursUntilNextEvent != null) {
            setState(() {
              if (hoursUntilNextEvent > 24) {
                _onScreenMessage =
                    'The next event does not open for check-in for another ${NumberFormat('###').format(hoursUntilNextEvent / 24)} days';
              } else {
                if (hoursUntilNextEvent >= 2) {
                  _onScreenMessage =
                      'The next event does not open for check-in for another ${NumberFormat('##').format(hoursUntilNextEvent)} hours';
                } else {
                  _onScreenMessage =
                      'The next event does not open for check-in for another ${NumberFormat('###').format(hoursUntilNextEvent * 60)} minute${NumberFormat('###').format(hoursUntilNextEvent * 60)}' !=
                              '1'
                          ? 's'
                          : '';
                }
              }
            });
          }
        } else {
          if (queryResult == EMPTY_RESULT) {
            setState(() {
              _onScreenMessage =
                  'There is no event for this Kennel at this time';
            });
          } else {
            final String userId = getStringPref(StringPrefsEnum.userId)!;

            final List<dynamic> adHocData = await tableModel
                .hasherEventMapService
                .setEventAttendence(
                  scanData,
                  userId,
                  AppDomainType.user,
                  attendenceState,
                  isHare: isHareNo.value,
                );

            setState(() {
              if (adHocData.isNotEmpty) {
                _onScreenMessage = adHocData[0]['userMessage'];
              } else {
                _onScreenMessage = 'Processing Complete';
              }
            });
          }
        }
      } else if (prefix == QR_PREFIX_AUTHENTICATE_WEB_PORTAL_LOGIN) {
        final AuthenticateWebPortalService svc = AuthenticateWebPortalService();
        final SingleResultModel? returnValue = await svc.authenticateWebPortal(
          scanData,
        );

        setState(() {
          if ((returnValue != null) &&
              (returnValue.result != null) &&
              (returnValue.result!.isNotEmpty)) {
            _onScreenMessage = returnValue.result!;
          } else {
            _onScreenMessage = 'Processing Complete';
          }
        });
      }
    }

    // final ProcessQrScanService srv = ProcessQrScanService();
    // final Future<ProcessQrScanModel> apiCall =
    //     srv.processQrScan('', scanResult, 'UserScan', '', '', '');
    // apiCall.then((ProcessQrScanModel result) {
    //   setState(() => barcode = result.resultStr1);
    // });

    // return Future<void>(() {});(() {});
  }

  // Future<dynamic> stopScanning() async {
  //   controller.stopScanning();
  //   await controller.dispose();
  //   controller = null;
  // }

  // Widget _cameraPreviewWidget() {
  //   return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraint) {
  //     return Container(
  //       padding: const EdgeInsets.all(9.0),
  //       height: constraint.biggest.height,
  //       width: constraint.biggest.height,
  //       child: (controller == null) ? Container() : QRReaderPreview(controller),
  //     );
  //   });
  // }

  // Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
  //   if (controller != null) {
  //     await controller.dispose();
  //   }
  //   controller = QRReaderController(cameraDescription, ResolutionPreset.high, <CodeFormat>[CodeFormat.qr, CodeFormat.pdf417], onCodeRead);

  //   // If the controller is updated then update the UI.
  //   controller.addListener(() {
  //     if (mounted) {
  //       setState(() {});
  //     }
  //     if (controller.value.hasError) {
  //       showInSnackBar('Camera error ${controller.value.errorDescription}');
  //     }
  //   });

  //   try {
  //     await controller.initialize();
  //   } on QRReaderException catch (e) {
  //     //logError(e.code, e.description);
  //     showInSnackBar('Error: ${e.code}\n${e.description}');
  //   }

  //   if (mounted) {
  //     setState(() {});
  //     controller.startScanning();
  //   }

  //   // return Future<void>(() {});(() {});
  // }

  // void showInSnackBar(String message) {
  //   // _scaffoldKey.currentState
  //   //     .showSnackBar(SnackBar(content: Text(message)));
  // }

  String? _result;

  // void _onQRViewCreated(QRViewController controller) {
  //   _scannerController = controller;
  //   if (_scannerController != null) {
  //     setState(() {
  //       _isScanning = true;
  //       _onScreenMessage = 'Looking for QR Code';
  //       _state = EQrScannerState.scanning;
  //     });

  //     _scannerController!.scannedDataStream.listen((Barcode scanData) async {
  //       await _scannerController!.pauseCamera();
  //       setState(() {
  //         _isScanning = false;
  //         _result = scanData.code;
  //       });
  //       if (_result != null) {
  //         await _onCodeRead(_result!);
  //         setState(() {});
  //       }
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
      // mainAxisSize: MainAxisSize.min,
      // crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          width: 10,
          height: (deviceInfo.deviceWidthScaleFactor - 1) * 90,
        ),
        Container(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: AutoSizeText(
            'Use this scanner to scan QR codes at the beginning and end of runs to check in.',
            //'Use this scanner to scan the QR codes at theor end of runs or to scan the QR codes of other Hashers who you want to add to your friend list.',
            textAlign: TextAlign.justify,
            maxLines: 4,
            style: ts_titleMedium.copyWith(
              fontSize: 16.0 * deviceInfo.deviceWidthScaleFactor,
            ),
          ),
        ),

        //_cameraPreviewWidget(),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(
              10 * (deviceInfo.deviceMaxScaleFactor * 1.5),
            ),
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: <Widget>[
                Image.asset('images/other/qr_scanner.png'),
                Container(
                  padding: const EdgeInsets.all(11.0),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: MobileScanner(
                      controller: _scannerController,
                      onDetect: (result) async {
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
                if ((!_isScanning) &&
                    (_state == EQrScannerState.waitingForScan)) ...<Widget>[
                  Image.asset('images/other/qr_scanner.png'),
                ],
                if ((!_isScanning) &&
                    (_state == EQrScannerState.isProcessing)) ...<Widget>[
                  Image.asset('images/other/uploading_to_cloud.png'),
                ],
                if ((!_isScanning) &&
                    (_state == EQrScannerState.dataRecorded)) ...<Widget>[
                  Image.asset('images/other/run_info_recorded.png'),
                ],
                if ((!_isScanning) &&
                    (_state == EQrScannerState.qrNotRecognized)) ...<Widget>[
                  Image.asset('images/other/qr_not_recognized.png'),
                ],
              ],
            ),
          ),
        ),
        // // child:Container(
        // //   child: _cameraPreviewWidget(), width: 200.0, height: 200.0),
        if (_state != EQrScannerState.dataRecorded) ...<Widget>[
          Container(
            margin: const EdgeInsets.all(10.0),
            //width: 280.0,
            height: 40.0,
            child: Connection2.styleForConnected(
              appModel.connectionStatus,
              ElevatedButton(
                child: Text(
                  _isScanning ? 'Stop Scanning' : 'Start Scanning',
                  style: ts_title,
                ),
                onPressed: () async {
                  if (Connection2.checkForConnection(
                    appModel.connectionStatus,
                  )) {
                    await _toggleScanning();
                  }
                },
              ),
            ),
          ),
        ],

        Container(
          //color:Colors.yellow,
          //height: 80,
          padding: const EdgeInsets.only(
            top: 20,
            bottom: 30,
            left: 20,
            right: 20,
          ),
          child: Center(
            child: AutoSizeText(
              _onScreenMessage,
              //'This is a test of how ',
              //'This is a test of how this works with 2 lines ',
              //'this is a test of how 3 lines will fit Ill need a lot more text than that to make it work',
              textAlign: TextAlign.center,
              maxLines: 3,
              style: ts_headingLarge,
            ),
          ),
        ),
      ],
    );
  }
}
