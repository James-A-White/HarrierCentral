import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:fast_qr_reader_view/fast_qr_reader_view.dart';
import 'package:audioplayers/audio_cache.dart';

import 'package:harrier_central/data_models/process_qr_scan_model.dart';
import 'package:harrier_central/services/process_qr_scan_service.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/widgets/bubble_tab_indicator.dart';

class UserQrCodePage extends StatefulWidget {
  const UserQrCodePage({Key key}) : super(key: key);

  @override
  _UserQrCodePageState createState() => _UserQrCodePageState();
}

class _UserQrCodePageState extends State<UserQrCodePage>
    with SingleTickerProviderStateMixin {
  List<Tab> tabs = <Tab>[];

  String barcode = '';
  bool isAdmin = true;

  PageController _pageController;
  TabController _tabController;

  final String userId = getStringPref(StringPrefsEnum.userId);

  GlobalKey tabKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: <Widget>[
            // Positioned(
            //     top: 30,
            //     left: 0,
            //     right: 0,
            //     child: Text(
            //       'QR Code Scanner',
            //       textAlign: TextAlign.center,
            //       style: const TextStyle(
            //           fontFamily: 'AvenirNextRegular',
            //           fontStyle: FontStyle.normal,
            //           color: Colors.white,
            //           fontSize: 24.0,
            //           height: 1.0),
            //     )),
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
                    labelStyle: const TextStyle(
                        fontFamily: 'AvenirNextCondensedMedium',
                        fontStyle: FontStyle.normal,
                        fontSize: 18.0,
                        height: 1.0),
                    unselectedLabelStyle: const TextStyle(
                        fontFamily: 'AvenirNextCondensedMedium',
                        fontStyle: FontStyle.normal,
                        fontSize: 18.0,
                        height: 1.0),
                    isScrollable: false,
                    unselectedLabelColor: Colors.black,
                    labelColor: Colors.white,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BubbleTabIndicator(
                      indicatorHeight: 35.0,
                      indicatorColor: Theme.of(context).buttonColor,
                      tabBarIndicatorSize: TabBarIndicatorSize.tab,
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

    _pageController = PageController(initialPage: 0, keepPage: true);
    _tabController = TabController(vsync: this, length: tabs.length);
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
  //             child: FlatButton(
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
  //             child: FlatButton(
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

  Future<bool> _displayInstructions(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('About your QR Scanner'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text(
                  'You can use your QR scanner to add friends to your Harrier Central friend list simply by scanning their personal QR code. You can also use your scanner to check in when you arrive at runs and to check in when you are done with trail so the hares know who is still out.',
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

class TabIndicationPainter extends CustomPainter {
  TabIndicationPainter(
      {this.context,
      this.dxTarget = 125.0,
      this.dxEntry = 25.0,
      this.radius = 21.0,
      this.dy = 25.0,
      this.pageController})
      : super(repaint: pageController) {
    painter = Paint()
      ..color = Theme.of(context).accentColor
      ..style = PaintingStyle.fill;
  }

  Paint painter;
  final double dxTarget;
  final double dxEntry;
  final double radius;
  final double dy;
  BuildContext context;

  final PageController pageController;

  @override
  void paint(Canvas canvas, Size size) {
    final ScrollPosition pos = pageController.position;
    final double fullExtent =
        pos.maxScrollExtent - pos.minScrollExtent + pos.viewportDimension;

    final double pageOffset = pos.extentBefore / fullExtent;

    final bool left2right = dxEntry < dxTarget;
    final Offset entry = Offset(left2right ? dxEntry : dxTarget, dy);
    final Offset target = Offset(left2right ? dxTarget : dxEntry, dy);

    final Path path = Path();
    path.addArc(Rect.fromCircle(center: entry, radius: radius), 0.5 * math.pi,
        1 * math.pi);
    path.addRect(Rect.fromLTRB(entry.dx, dy - radius, target.dx, dy + radius));
    path.addArc(Rect.fromCircle(center: target, radius: radius), 1.5 * math.pi,
        1 * math.pi);

    canvas.translate(size.width * pageOffset, 0.0);
    canvas.drawShadow(path, const Color(0xFFfbab66), 3.0, true);
    canvas.drawPath(path, painter);
  }

  @override
  bool shouldRepaint(TabIndicationPainter oldDelegate) => true;
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
          title: const Text('Your QR Code'),
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

  Key tabKey;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final String userName =
        getStringPref(StringPrefsEnum.displayName);
    final String userQrCode = getStringPref(StringPrefsEnum.qrCode);

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      print('Height = ${constraints.maxHeight}');
      print('Width = ${constraints.maxWidth}');
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
                    top: 0,
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: const Text(
                      'Use this code to check in at the beginning and end of runs. Your friends can also scan this code to add you to their friend list. ',
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'AvenirNextDemiBold',
                        fontStyle: FontStyle.normal,
                        fontSize: 16.0,
                        height: 0.8,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 80,
                    child: AutoSizeText(
                      'QR for: $userName',
                      //'QR Code for xxx',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: const TextStyle(
                          fontFamily: 'AvenirNextDemiBold',
                          fontStyle: FontStyle.normal,
                          color: Colors.white,
                          fontSize: 24.0,
                          height: 1.0),
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
                  Positioned(
                    top: 127,
                    //bottom: 50,
                    child: Container(
                      height: math.min(
                              constraints.maxHeight, constraints.maxWidth) *
                          0.65,
                      child: QrImage(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(10.0),
                          data: userQrCode,
                          //data: 'testing123',
                          version: 2,
                          //size: 200.0,
                          errorCorrectionLevel: 3),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 0.0, right: 0.0),
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
    });
  }
}

class QrScannerTab extends StatefulWidget {
  const QrScannerTab({Key key}) : super(key: key);

  @override
  _QrScannerTabState createState() => _QrScannerTabState();
}

class _QrScannerTabState extends State<QrScannerTab>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  String barcode = 'Waiting for Scan';

  QRReaderController controller;

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

  List<CameraDescription> cameras;

  Future<void> scanUserBarcode() async {
    if (controller == null) {
      setState(() => barcode = 'Scanning');
      cameras = await availableCameras();

      onNewCameraSelected(cameras[0]);
    } else {
      await stopScanning();
      setState(() => barcode = 'Waiting for scan');
    }

    // return Future<void>(() {});(() {});
  }

  Future<void> onCodeRead(dynamic scanResult) async {
    final AudioCache audioPlayer = AudioCache(prefix: 'sounds/');
    audioPlayer.play('camera.mp3');

    setState(() => barcode = 'Processing QR Scan');
    await stopScanning();

    final ProcessQrScanService srv = ProcessQrScanService();
    final Future<ProcessQrScanModel> apiCall =
        srv.processQrScan('', scanResult, 'UserScan', '', '', '');
    apiCall.then((ProcessQrScanModel result) {
      setState(() => barcode = result.resultStr1);
    });

    // return Future<void>(() {});(() {});
  }

  Future<dynamic> stopScanning() async {
    controller.stopScanning();
    await controller.dispose();
    controller = null;
  }

  Widget _cameraPreviewWidget() {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraint) {
      return Stack(children: <Widget>[
        Image.asset(
          'images/other/qr_scanner.png',
        ),
        Container(
          padding: const EdgeInsets.all(9.0),
          height: constraint.biggest.height,
          width: constraint.biggest.height,
          child:
              (controller == null) ? Container() : QRReaderPreview(controller),
        )
      ]);
    });

    // ;
  }

  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = QRReaderController(cameraDescription, ResolutionPreset.high,
        <CodeFormat>[CodeFormat.qr, CodeFormat.pdf417], onCodeRead);

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (controller.value.hasError) {
        showInSnackBar('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on QRReaderException catch (e) {
      //logError(e.code, e.description);
      showInSnackBar('Error: ${e.code}\n${e.description}');
    }

    if (mounted) {
      setState(() {});
      controller.startScanning();
    }

    // return Future<void>(() {});(() {});
  }

  void showInSnackBar(String message) {
    // _scaffoldKey.currentState
    //     .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _displayInstructions(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('QR Code Scanner'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text(
                  'You can use your QR scanner to add friends to your Harrier Central friend list simply by scanning their personal QR code.\r\n\r\nYou can also use your scanner to check in when you arrive at runs and to check in when you are done with trail so the hares know who is still out.',
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
    return Column(
      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
      // mainAxisSize: MainAxisSize.min,
      // crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Padding(
        //   padding: const EdgeInsets.only(top: 70.0, left: 24.0, right: 24.0),
        //   child: Text(
        //     'Use to scan the QR code from a fixed muster point location or the QR code from the phone of someone who has already mustered.',
        //     textAlign: TextAlign.center,
        //     style: const TextStyle(
        //         color: Colors.white,
        //         fontFamily: 'AvenirNextDemiBold',
        //         fontStyle: FontStyle.normal,
        //         fontSize: 22.0,
        //         height: 1.0),
        //   ),
        // ),
        // Expanded(
        //   child: const Padding(
        //     padding: const EdgeInsets.all(100),
        //     child: Container(
        //       color: Colors.yellow,
        //       // height: 200,
        //       // width: 200,
        //     ),
        //   ),
        // ),

        Expanded(
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: <Widget>[
              Positioned(
                top: 0,
                width: MediaQuery.of(context).size.width * 0.86,
                child: AutoSizeText(
                  'Use this scanner to either scan in at the beginning or end of runs or to scan the QR codes of other Hashers who you want to add to your friend list.',
                  textAlign: TextAlign.justify,
                  maxLines: 4,
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'AvenirNextDemiBold',
                      fontStyle: FontStyle.normal,
                      fontSize: 16.0,
                      height: 0.8),
                ),
              ),
              Positioned(
                  top: 80,
                  bottom: 180,
                  //width:150,
                  //height:150,
                  child: _cameraPreviewWidget()
                  // child:Container(
                  //   child: _cameraPreviewWidget(), width: 200.0, height: 200.0),
                  ),
              Positioned(
                bottom: 120.0,
                child: Container(
                  //margin: const EdgeInsets.all(20.0),
                  width: 280.0,
                  child: RaisedButton(
                      child: Text(
                        controller == null ? 'Start Scanning' : 'Stop Scanning',
                        style: const TextStyle(
                            fontFamily: 'AvenirNextDemiBold',
                            color: Colors.white,
                            fontStyle: FontStyle.normal,
                            fontSize: 22.0,
                            height: 1.0),
                      ),
                      onPressed: () {
                        scanUserBarcode();
                      }),
                ),
              ),
              Positioned(
                bottom: 40.0,
                width: MediaQuery.of(context).size.width - 40,
                child: Container(
                  //color:Colors.yellow,
                  height: 80,
                  child: Center(
                    child: AutoSizeText(
                      barcode,
                      //'This is a test of how ',
                      //'This is a test of how this works with 2 lines ',
                      //'this is a test of how 3 lines will fit Ill need a lot more text than that to make it work',
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      style: const TextStyle(
                          fontFamily: 'AvenirNextDemiBold',
                          fontStyle: FontStyle.normal,
                          color: Colors.yellow,
                          fontSize: 26.0,
                          height: 0.9),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0.0,
                // left: 30,
                // right: 30,
                child: FlatButton(
                  textColor: Colors.white,
                  child: const Text('Learn more about this feature'),
                  onPressed: () {
                    _displayInstructions(context);
                  },
                ),
              ),
            ],
          ),
        ),

        // ),
      ],
    );
  }
}
