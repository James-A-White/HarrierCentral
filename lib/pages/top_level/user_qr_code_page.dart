// @dart=2.11
import 'package:harrier_central/imports.dart';

import 'package:intl/intl.dart';

class UserQrCodePage extends StatefulWidget {
  const UserQrCodePage({Key key}) : super(key: key);

  @override
  _UserQrCodePageState createState() => _UserQrCodePageState();
}

class _UserQrCodePageState extends State<UserQrCodePage> with SingleTickerProviderStateMixin {
  final List<Tab> _tabs = <Tab>[];

  //PageController _pageController;
  TabController _tabController;

  GlobalKey _tabKey;

  AppBar _appBar;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(height: MediaQuery.of(context).size.height, width: MediaQuery.of(context).size.width),
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
                        borderRadius: const BorderRadius.all(Radius.circular(35.0)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 1.0, right: 1.0),
                        child: TabBar(
                          labelStyle: const TextStyle(fontFamily: 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
                          unselectedLabelStyle: const TextStyle(fontFamily: 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
                          isScrollable: false,
                          unselectedLabelColor: Colors.black,
                          labelColor: Colors.white,
                          labelPadding: const EdgeInsets.only(top: 5, left: 20, right: 20),
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BubbleTabIndicator(
                            indicatorHeight: 35.0,
                            indicatorColor: Colors.red.shade900,
                            tabBarIndicatorSize: TabBarIndicatorSize.tab,
                            indicatorRadius: 20.0,
                          ),
                          tabs: _tabs,
                          controller: _tabController,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                      top: 80,
                      bottom: 0,
                      child: Container(
                        key: _tabKey,
                        //color: Colors.teal,
                        width: MediaQuery.of(context).size.width,
                        child: TabBarView(
                          controller: _tabController,
                          children: const <Widget>[QrScannerTab(), QrCodeTab()],
                        ),
                      )),
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

  @override
  void initState() {
    super.initState();
    _initTabs();

    _appBar = AppBar(
      centerTitle: true,
      backgroundColor: themeAppBarBackground,
      actions: <IconButton>[
        IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _displayInstructions(context);
            }),
      ],
      title: const Text(
        'Run check in page',
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );

    //_pageController = PageController(initialPage: 0, keepPage: true);
    _tabController = TabController(vsync: this, length: _tabs.length);
  }

  Future<bool> _displayInstructions(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Your QR Code'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  _tabController.index == 0
                      ?
                      //'This QR code allows other Hashers to quickly scan you using their Harrier Central apps.\r\n\r\nAny Hasher can scan this code to easily add you as their friend.\r\n\r\nHares and mis-management can use this code to scan you in at the beginning and end of runs in order to keep your run counts accurate and ensure that no one is left behind on trail at the end of a run.',
                      'Mis-management can scan this code to keep your run counts accurate and ensure that no one is left behind on trail at the end of a run.\r\n\r\nThis is your unique code. If you don\'t normally carry a phone, you can print this code as a way to be quickly checked in at Hash runs.'
                      : 'You can use your QR scanner to check in when you arrive at runs and to check in when you are done with trail so the hares know who is still out on trail.',
                  //'You can use your QR scanner to add friends to your Harrier Central friend list simply by scanning their personal QR code.\r\n\r\nYou can also use your scanner to check in when you arrive at runs and to check in when you are done with trail so the hares know who is still out.',
                  textAlign: TextAlign.justify,
                  style: const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 16.0, height: 1.0),
                )
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
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
  //             child: TextButton(
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
  //             child: TextButton(
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
  const QrCodeTab({Key key}) : super(key: key);

  @override
  _QrCodeTabState createState() => _QrCodeTabState();
}

class _QrCodeTabState extends State<QrCodeTab> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final String userName = getStringPref(StringPrefsEnum.displayName);
    final String userQrCode = getStringPref(StringPrefsEnum.qrCode);

    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      print('Height = ${constraints.maxHeight}');
      print('Width = ${constraints.maxWidth}');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              width: 10,
              height: (G0<DeviceInfo>().deviceWidthScaleFactor - 1) * 90,
            ),
            Container(
              padding: const EdgeInsets.only(top: 0, bottom: 30, right: 25, left: 25),
              child: Text(
                'This code can be scanned by mismanagement to check you in at the beginning and end of runs.',
                textAlign: TextAlign.justify,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'AvenirNextDemiBold',
                  fontStyle: FontStyle.normal,
                  fontSize: 16.0 * G0<DeviceInfo>().deviceWidthScaleFactor,
                  height: 1.0,
                ),
              ),
            ),

            AutoSizeText(
              'QR for: $userName',
              //'QR Code for xxx',
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                  fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 24.0 * G0<DeviceInfo>().deviceWidthScaleFactor, height: 1.0),
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
                padding: const EdgeInsets.only(top: 20, bottom: 10, left: 30, right: 30),
                child: Stack(alignment: AlignmentDirectional.center,
                    //height: min(constraints.maxHeight, constraints.maxWidth) * 0.65,
                    children: <Widget>[
                      QrImage(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(10.0),
                          data: BASE_HCWEB_MOBILE_URL + userQrCode,
                          //data: 'testing123',
                          version: 4,
                          //size: 200.0,
                          errorCorrectionLevel: 3),
                    ]),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class QrScannerTab extends StatefulWidget {
  const QrScannerTab({Key key}) : super(key: key);

  @override
  _QrScannerTabState createState() => _QrScannerTabState();
}

enum EQrScannerState { waitingForScan, scanning, isProcessing, qrNotRecognized, dataRecorded }

class _QrScannerTabState extends State<QrScannerTab> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  String _onScreenMessage = 'Scanning paused';

  QRViewController _controller;
  EQrScannerState _state = EQrScannerState.waitingForScan;
  bool _isScanning = false;
  // bool _isProcessing = false;
  // bool _dataRecorded = false;

  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');

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

  @override
  void dispose() {
    _isScanning = false;
    if (_controller != null) {
      _controller.stopCamera();
      _controller.dispose();
    }

    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (_controller != null) {
      if (Platform.isAndroid) {
        _controller.pauseCamera();
        _isScanning = false;
        _onScreenMessage = 'Scanning paused';
        _state = EQrScannerState.waitingForScan;
      } else if (Platform.isIOS) {
        _controller.resumeCamera();
        _isScanning = true;
        _onScreenMessage = 'Looking for QR Code';
        _state = EQrScannerState.scanning;
      }
    }
  }

  Future<void> _toggleScanning() async {
    if (_controller != null) {
      setState(() {
        if (_isScanning) {
          _controller.pauseCamera();
          _isScanning = false;
          _onScreenMessage = 'Scanning paused';
          _state = EQrScannerState.waitingForScan;
        } else {
          _controller.resumeCamera();
          _isScanning = true;
          _onScreenMessage = 'Looking for QR Code';
          _state = EQrScannerState.scanning;
        }
      });
    }
  }

  //   // return Future<void>(() {});(() {});
  // }

  Future<void> _onCodeRead(dynamic scanResult) async {
    final AudioCache audioPlayer = AudioCache(prefix: 'assets/sounds/');
    // ignore: unawaited_futures
    audioPlayer.play('camera.mp3');

    setState(() {
      _onScreenMessage = 'Processing QR Scan';
      _state = EQrScannerState.isProcessing;
    });
    //await stopScanning();

    //final Map<String,String> result = Utilities.validateScan(scanResult, Utilities.qrScanTypeFlag_user | Utilities.qrScanTypeFlag_kennelRunEnd| Utilities.qrScanTypeFlag_kennelRunStart| Utilities.qrScanTypeFlag_runStart| Utilities.qrScanTypeFlag_runEnd);
    final Map<String, String> result = Utilities.validateScan(
        scanResult,
        //Utilities.qrScanTypeFlag_user |
        Utilities.qrScanTypeFlag_runStart | Utilities.qrScanTypeFlag_runEnd | Utilities.qrScanTypeFlag_kennelRunEnd | Utilities.qrScanTypeFlag_kennelRunStart);

    if (result['validScan'] == 'false') {
      setState(() {
        _state = EQrScannerState.qrNotRecognized;
        _onScreenMessage = result['validHcQr'] == 'true' ? 'This QR code is not valid here' : 'QR code not recignized';
      });
    } else {
      final String prefix = result['prefix'];
      final String content = result['content'];

      if ((prefix == QR_PREFIX_SPECIFIC_RUN_START) || (prefix == QR_PREFIX_SPECIFIC_RUN_END)) {
        final int attendenceState = prefix == QR_PREFIX_SPECIFIC_RUN_START ? attendenceAtHash.value : attendenceOnIn.value;

        final String userId = getStringPref(StringPrefsEnum.userId);

        final List<dynamic> adHocData = await G0<TableModel>().hasherEventMapService.joinEvent(
              content,
              userId,
              null,
              AppDomainType.user,
              rsvpState: rsvpYes.value,
              attendenceState: attendenceState,
              isHare: isHareNo.value,
              virginVisitorType: enumHasher.value,
            );

        setState(() {
          _state = EQrScannerState.dataRecorded;
          if ((adHocData != null) && (adHocData.isNotEmpty)) {
            _onScreenMessage = adHocData[0]['userMessage'];
          } else {
            _onScreenMessage = 'Processing Complete';
          }
        });
      }

      if ((prefix == QR_PREFIX_KENNEL_GENERIC_RUN_END) || (prefix == QR_PREFIX_KENNEL_GENERIC_RUN_START)) {
        final int attendenceState = prefix == QR_PREFIX_KENNEL_GENERIC_RUN_START ? attendenceAtHash.value : attendenceOnIn.value;

        final String eventId = await CommonQueries.getClosestEventInTime(content);
        if (num.tryParse(eventId) != null) {
          final num hoursUntilNextEvent = num.tryParse(eventId);
          setState(() {
            if (hoursUntilNextEvent > 24) {
              _onScreenMessage = 'The next event does not open for check-in for another ${NumberFormat('###').format(hoursUntilNextEvent / 24)} days';
            } else {
              if (hoursUntilNextEvent >= 2) {
                _onScreenMessage = 'The next event does not open for check-in for another ${NumberFormat('##').format(hoursUntilNextEvent)} hours';
              } else {
                _onScreenMessage = 'The next event does not open for check-in for another ${NumberFormat('###').format(hoursUntilNextEvent * 60)} minute' +
                            NumberFormat('###').format(hoursUntilNextEvent * 60) !=
                        '1'
                    ? 's'
                    : '';
              }
            }
          });
        } else {
          if (eventId == EMPTY_RESULT) {
            setState(() {
              _onScreenMessage = 'There is no event for this Kennel at this time';
            });
          } else {
            final String userId = getStringPref(StringPrefsEnum.userId);

            final List<dynamic> adHocData = await G0<TableModel>()
                .hasherEventMapService
                .joinEvent(eventId, userId, null, AppDomainType.user, rsvpState: rsvpYes.value, attendenceState: attendenceState, isHare: isHareNo.value);

            setState(() {
              if ((adHocData != null) && (adHocData.isNotEmpty)) {
                _onScreenMessage = adHocData[0]['userMessage'];
              } else {
                _onScreenMessage = 'Processing Complete';
              }
            });
          }
        }
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

  String _result;

  void _onQRViewCreated(QRViewController controller) {
    _controller = controller;
    setState(() {
      _isScanning = true;
      _onScreenMessage = 'Looking for QR Code';
      _state = EQrScannerState.scanning;
    });

    _controller.scannedDataStream.listen((Barcode scanData) {
      setState(() {
        _result = scanData.code;
        _onCodeRead(_result);
        _controller.pauseCamera();
        _isScanning = false;
      });
    });
  }

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
          height: (G0<DeviceInfo>().deviceWidthScaleFactor - 1) * 90,
        ),
        Container(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: AutoSizeText(
            'Use this scanner to scan QR codes at the beginning and end of runs to check in.',
            //'Use this scanner to scan the QR codes at theor end of runs or to scan the QR codes of other Hashers who you want to add to your friend list.',
            textAlign: TextAlign.justify,
            maxLines: 4,
            style:
                TextStyle(color: Colors.white, fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, fontSize: 16.0 * G0<DeviceInfo>().deviceMaxScaleFactor, height: 1.0),
          ),
        ),

        //_cameraPreviewWidget(),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(10 * (G0<DeviceInfo>().deviceMaxScaleFactor * 1.5)),
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: <Widget>[
                Image.asset(
                  'images/other/qr_scanner.png',
                ),
                Container(
                  padding: const EdgeInsets.all(11.0),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: QRView(key: _qrKey, onQRViewCreated: _onQRViewCreated),
                  ),
                ),
                if ((!_isScanning) && (_state == EQrScannerState.waitingForScan)) ...<Widget>[
                  Image.asset(
                    'images/other/qr_scanner.png',
                  ),
                ],
                if ((!_isScanning) && (_state == EQrScannerState.isProcessing)) ...<Widget>[
                  Image.asset(
                    'images/other/uploading_to_cloud.png',
                  ),
                ],
                if ((!_isScanning) && (_state == EQrScannerState.dataRecorded)) ...<Widget>[
                  Image.asset(
                    'images/other/run_info_recorded.png',
                  ),
                ],
                if ((!_isScanning) && (_state == EQrScannerState.qrNotRecognized)) ...<Widget>[
                  Image.asset(
                    'images/other/qr_not_recognized.png',
                  ),
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
            child: Connection.styleForConnected(
              G0<AppModel>().connectionStatus,
              ElevatedButton(
                  child: Text(
                    _isScanning ? 'Stop Scanning' : 'Start Scanning',
                    style: const TextStyle(fontFamily: 'AvenirNextDemiBold', color: Colors.white, fontStyle: FontStyle.normal, fontSize: 22.0),
                  ),
                  onPressed: () async {
                    if (Connection.checkForConnection(context, G0<AppModel>().connectionStatus)) {
                      await _toggleScanning();
                    }
                  }),
            ),
          )
        ],

        Container(
          //color:Colors.yellow,
          //height: 80,
          padding: const EdgeInsets.only(top: 20, bottom: 30, left: 20, right: 20),
          child: Center(
            child: AutoSizeText(
              _onScreenMessage,
              //'This is a test of how ',
              //'This is a test of how this works with 2 lines ',
              //'this is a test of how 3 lines will fit Ill need a lot more text than that to make it work',
              textAlign: TextAlign.center,
              maxLines: 3,
              style: const TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.yellow, fontSize: 26.0, height: 1.15),
            ),
          ),
        ),
      ],
    );
  }
}
