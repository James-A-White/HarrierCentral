import 'package:harrier_central/imports.dart';

import 'package:intl/intl.dart';

class UserQrCodePage extends StatefulWidget {
  const UserQrCodePage({Key key}) : super(key: key);

  @override
  _UserQrCodePageState createState() => _UserQrCodePageState();
}

class _UserQrCodePageState extends State<UserQrCodePage> with SingleTickerProviderStateMixin {
  List<Tab> tabs = <Tab>[];

  String barcode = '';
  bool isAdmin = true;

  PageController _pageController;
  TabController _tabController;

  final String userId = getStringPref(StringPrefsEnum.userId);

  GlobalKey tabKey;
  GlobalKey<ScaffoldState> scaffoldKey;

  AppBar appBar;

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
            appBar: appBar,
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
                            indicatorColor: Theme.of(context).buttonColor,
                            tabBarIndicatorSize: TabBarIndicatorSize.tab,
                            indicatorRadius: 20.0,
                          ),
                          tabs: tabs,
                          controller: _tabController,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                      top: 80,
                      bottom: 0,
                      child: Container(
                        key: tabKey,
                        //color: Colors.teal,
                        width: MediaQuery.of(context).size.width,
                        child: TabBarView(
                          controller: _tabController,
                          children: const <Widget>[QrCodeTab(), QrScannerTab()],
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
    _pageController?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initTabs();

    appBar = AppBar(
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
        'QR Page',
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );

    _pageController = PageController(initialPage: 0, keepPage: true);
    _tabController = TabController(vsync: this, length: tabs.length);
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

  Color left = Colors.white;
  Color right = Colors.white;

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
    if (tabs.isEmpty) {
      tabs.add(const Tab(text: 'Be Scanned'));
      tabs.add(const Tab(text: 'Scan'));
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

  Key tabKey;

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
                          data: userQrCode,
                          //data: 'testing123',
                          version: 2,
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

class _QrScannerTabState extends State<QrScannerTab> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  String onScreenMessage = 'Waiting for Scan';

  QRViewController controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

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
    controller?.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      if (Platform.isAndroid) {
        controller.pauseCamera();
      } else if (Platform.isIOS) {
        controller.resumeCamera();
      }
    }
  }

  Future<void> scanUserBarcode() async {
    if (controller != null) {
      controller.resumeCamera();
    }
  }

  //   // return Future<void>(() {});(() {});
  // }

  Future<void> onCodeRead(dynamic scanResult) async {
    final AudioCache audioPlayer = AudioCache(prefix: 'sounds/');
    audioPlayer.play('camera.mp3');

    setState(() => onScreenMessage = 'Processing QR Scan');
    //await stopScanning();

    //final Map<String,String> result = Utilities.validateScan(scanResult, Utilities.qrScanTypeFlag_user | Utilities.qrScanTypeFlag_kennelRunEnd| Utilities.qrScanTypeFlag_kennelRunStart| Utilities.qrScanTypeFlag_runStart| Utilities.qrScanTypeFlag_runEnd);
    final Map<String, String> result = Utilities.validateScan(
        scanResult,
        Utilities.qrScanTypeFlag_user |
            Utilities.qrScanTypeFlag_runStart |
            Utilities.qrScanTypeFlag_runEnd |
            Utilities.qrScanTypeFlag_kennelRunEnd |
            Utilities.qrScanTypeFlag_kennelRunStart);

    if (result['validScan'] == 'false') {
      setState(() {
        onScreenMessage = result['validHcQr'] == 'true' ? 'This QR code is not valid here' : 'QR code not recignized';
      });
    } else {
      final String prefix = result['prefix'];
      final String content = result['content'];

      if ((prefix == QR_PREFIX_SPECIFIC_RUN_START) || (prefix == QR_PREFIX_SPECIFIC_RUN_END)) {
        final int attendenceState = prefix == QR_PREFIX_SPECIFIC_RUN_START ? attendenceAtHash.value : attendenceOnIn.value;

        final String userId = getStringPref(StringPrefsEnum.userId);

        G0<TableModel>()
            .hasherEventMapService
            .joinEvent(
              content,
              userId,
              null,
              AppDomainType.user,
              rsvpState: rsvpYes.value,
              attendenceState: attendenceState,
              isHare: isHareNo.value,
              virginVisitorType: enumHasher.value,
            )
            .then((
          List<dynamic> adHocData,
        ) {
          setState(() {
            if ((adHocData != null) && (adHocData.isNotEmpty)) {
              onScreenMessage = adHocData[0]['userMessage'];
            } else {
              onScreenMessage = 'Processing Complete';
            }
          });
        });
      }

      if ((prefix == QR_PREFIX_KENNEL_GENERIC_RUN_END) || (prefix == QR_PREFIX_KENNEL_GENERIC_RUN_START)) {
        final int attendenceState = prefix == QR_PREFIX_KENNEL_GENERIC_RUN_START ? attendenceAtHash.value : attendenceOnIn.value;

        final String eventId = await CommonQueries.getClosestEventInTime(content);
        if (num.tryParse(eventId) != null) {
          final num hoursUntilNextEvent = num.tryParse(eventId);
          setState(() {
            if (hoursUntilNextEvent > 24) {
              onScreenMessage = 'The next event does not open for check-in for another ${NumberFormat('###').format(hoursUntilNextEvent / 24)} days';
            } else {
              if (hoursUntilNextEvent >= 2) {
                onScreenMessage = 'The next event does not open for check-in for another ${NumberFormat('##').format(hoursUntilNextEvent)} hours';
              } else {
                onScreenMessage = 'The next event does not open for check-in for another ${NumberFormat('###').format(hoursUntilNextEvent * 60)} minute' +
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
              onScreenMessage = 'There is no event for this Kennel at this time';
            });
          } else {
            final String userId = getStringPref(StringPrefsEnum.userId);

            G0<TableModel>()
                .hasherEventMapService
                .joinEvent(eventId, userId, null, AppDomainType.user, rsvpState: rsvpYes.value, attendenceState: attendenceState, isHare: isHareNo.value)
                .then((
              List<dynamic> adHocData,
            ) {
              setState(() {
                if ((adHocData != null) && (adHocData.isNotEmpty)) {
                  onScreenMessage = adHocData[0]['userMessage'];
                } else {
                  onScreenMessage = 'Processing Complete';
                }
              });
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

  void showInSnackBar(String message) {
    // _scaffoldKey.currentState
    //     .showSnackBar(SnackBar(content: Text(message)));
  }

  String result;

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((Barcode scanData) {
      setState(() {
        result = scanData.code;
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
                    child: QRView(key: qrKey, onQRViewCreated: _onQRViewCreated),
                  ),
                ),
              ],
            ),
          ),
        ),
        // // child:Container(
        // //   child: _cameraPreviewWidget(), width: 200.0, height: 200.0),

        Container(
          margin: const EdgeInsets.all(10.0),
          //width: 280.0,
          height: 40.0,
          child: Connection.styleForConnected(
            G0<AppModel>().connectionStatus,
            ElevatedButton(
                child: Text(
                  //'Start scanning',
                  controller == null ? 'Start Scanning' : 'Stop Scanning',
                  style: const TextStyle(fontFamily: 'AvenirNextDemiBold', color: Colors.white, fontStyle: FontStyle.normal, fontSize: 22.0),
                ),
                onPressed: () {
                  if (Connection.checkForConnection(context, G0<AppModel>().connectionStatus)) {
                    scanUserBarcode();
                  }
                }),
          ),
        ),

        Container(
          //color:Colors.yellow,
          //height: 80,
          padding: const EdgeInsets.only(top: 20, bottom: 0),
          child: Center(
            child: AutoSizeText(
              onScreenMessage,
              //'This is a test of how ',
              //'This is a test of how this works with 2 lines ',
              //'this is a test of how 3 lines will fit Ill need a lot more text than that to make it work',
              textAlign: TextAlign.center,
              maxLines: 3,
              style: const TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.yellow, fontSize: 26.0, height: 0.9),
            ),
          ),
        ),
      ],
    );
  }
}
