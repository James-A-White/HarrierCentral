import 'dart:math';

//import 'package:barcode_scan/barcode_scan.dart';

import 'package:flutter/material.dart';

import 'package:harrier_central/data_models/process_qr_scan_model.dart';
import 'package:harrier_central/remote_api_data/process_qr_scan_service.dart';

// import 'package:managed_response/pages/sub_pages/scan_others_page.dart';
// import 'package:managed_response/data_models/check_in_result_model.dart';
// import 'package:managed_response/services/check_in_service.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';
//import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/widgets/bubble_tab_indicator.dart';

import 'package:auto_size_text/auto_size_text.dart';

import 'package:qr_flutter/qr_flutter.dart';

import 'package:fast_qr_reader_view/fast_qr_reader_view.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers/audio_cache.dart';

class UserQrCodePage extends StatefulWidget {
  UserQrCodePage({Key key}) : super(key: key);

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

  final String userId = Preferences.getStringPref(StringPrefsEnum.userId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          centerTitle: true,
          backgroundColor: Theme.of(context).primaryColor,
          title: Text(
            'QR Code and Scanner',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      body: Container(
        decoration: BoxDecoration(
          // Box decoration takes a gradient
          gradient: LinearGradient(
            // Where the linear gradient begins and ends
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            // Add one stop for each color. Stops should increase from 0 to 1
            stops: [0.1, 0.9],
            colors: [
              // Colors are easy thanks to Flutter's Colors class.
              Colors.grey[500],
              Colors.grey[850],
            ],
          ),
        ),
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
                  borderRadius: BorderRadius.all(Radius.circular(35.0)),
                ),
                child: Padding(
                  padding: EdgeInsets.only(left: 1.0, right: 1.0),
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
                bottom: 52,
                child: Container(
                  //color: Colors.teal,
                  width: MediaQuery.of(context).size.width,
                  child: TabBarView(
                    controller: _tabController,
                    children: <Widget>[QrCodeTab(), QrScannerTab()],
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

  Widget _buildMenuBar(BuildContext context) {
    return Container(
      width: 300.0,
      height: 50.0,
      decoration: const BoxDecoration(
        color: Color(0x552B2B2B),
        borderRadius: BorderRadius.all(Radius.circular(25.0)),
      ),
      child: CustomPaint(
        painter: TabIndicationPainter(
            context: context, pageController: _pageController),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Expanded(
              child: FlatButton(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onPressed: _onSwitchToQrScanner,
                child: Text(
                  'Scan',
                  style: TextStyle(
                      color: left,
                      fontSize: 14.0,
                      fontFamily: 'WorkSansSemiBold'),
                ),
              ),
            ),
            Expanded(
              child: FlatButton(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onPressed: _onSwitchToQrCode,
                child: Text(
                  'My Scanner',
                  style: TextStyle(
                      color: right,
                      fontSize: 14.0,
                      fontFamily: 'WorkSansSemiBold'),
                ),
              ),
            ),
          ],
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
          title: Text('About your QR Scanner'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'You can use your QR scanner to add friends to your Harrier Central friend list simply by scanning their personal QR code. You can also use your scanner to check in when you arrive at runs and to check in when you are done with trail so the hares know who is still out.',
                  textAlign: TextAlign.justify,
                  style: const TextStyle(
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
              child: Text("OK, Got it!"),
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
      tabs.add(Tab(text: 'Be Scanned'));
      tabs.add(Tab(text: 'Scan'));
    }
  }

  void _onSwitchToQrCode() {
    _pageController.animateToPage(0,
        duration: Duration(milliseconds: 500), curve: Curves.decelerate);
  }

  void _onSwitchToQrScanner() {
    _pageController?.animateToPage(1,
        duration: Duration(milliseconds: 500), curve: Curves.decelerate);
  }
}

class TabIndicationPainter extends CustomPainter {
  Paint painter;
  final double dxTarget;
  final double dxEntry;
  final double radius;
  final double dy;
  BuildContext context;

  final PageController pageController;

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
    path.addArc(
        Rect.fromCircle(center: entry, radius: radius), 0.5 * pi, 1 * pi);
    path.addRect(Rect.fromLTRB(entry.dx, dy - radius, target.dx, dy + radius));
    path.addArc(
        Rect.fromCircle(center: target, radius: radius), 1.5 * pi, 1 * pi);

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
          title: Text('Your QR Code'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'This QR code allows other Hashers to quickly scan you using their Harrier Central apps.\r\n\r\nAny Hasher can scan this code to easily add you as their friend.\r\n\r\nHares and mis-management can use this code to scan you in at the beginning and end of runs in order to keep your run counts accurate and ensure that no one is left behind on trail at the end of a run.',
                  textAlign: TextAlign.justify,
                  style: const TextStyle(
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
              child: Text("OK, Got it!"),
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
    String userName = Preferences.getStringPref(StringPrefsEnum.displayName);
    String userQrCode = Preferences.getStringPref(StringPrefsEnum.qrCode);

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
                  child: Text(
                    'Use this code to check in at the beginning and end of runs. Your friends can also scan this code to add you to their friend list. ',
                    textAlign: TextAlign.justify,
                    style: const TextStyle(
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
                    height: (MediaQuery.of(context).size.width * 0.8 <
                            MediaQuery.of(context).size.height * 0.4)
                        ? MediaQuery.of(context).size.width * 0.8
                        : MediaQuery.of(context).size.height * 0.4,
                    width: (MediaQuery.of(context).size.width * 0.8 <
                            MediaQuery.of(context).size.height * 0.4)
                        ? MediaQuery.of(context).size.width * 0.8
                        : MediaQuery.of(context).size.height * 0.4,
                    child: QrImage(
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.all(10.0),
                        data: userQrCode,
                        //data: 'testing123',
                        version: 2,
                        //size: 200.0,
                        errorCorrectionLevel: 3),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Padding(
                    padding: EdgeInsets.only(left: 32.0, right: 32.0),
                    child: FlatButton(
                      textColor: Colors.white,
                      child: Text("Learn more about this feature"),
                      onPressed: () {
                        this._displayInstructions(context);
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

  // void scanUserBarcode() async {
  //   setState(() => barcode = 'Waiting for Scan');

  //   // BarcodeScanner.scan().then((scanResult) {
  //   //   if (scanResult.toUpperCase().startsWith(SELF_MUSTER_HEADER) ||
  //   //       scanResult.toUpperCase().startsWith(MOBILE_MUSTER_HEADER)) {
  //   //     setState(() => barcode = 'Processing scan data');
  //   //     CheckInResultService srv = CheckInResultService();
  //   //     final Future<CheckInResultModel> apiCall = srv.checkIn(scanResult);
  //   //     apiCall.then((CheckInResultModel result) {
  //   //       if (result?.confirmationCode == null) {
  //   //         setState(() => barcode = 'Error processing QR code');
  //   //         Utilities.say(
  //   //             'Error processing QR code. Please ensure you are scanning a valid QR code at a muster point.');
  //   //       } else {
  //   //         Utilities.say(result.result == 1
  //   //                 ? 'You are mustered with muster code ${result.confirmationCode}'
  //   //                 : result.result == 2
  //   //                     ? 'You are already mustered with muster code ${result.confirmationCode})'
  //   //                     : 'Unknown muster code result')
  //   //             .then<dynamic>((void dummy) {
  //   //           Utilities.say('Please use this app to help others muster');
  //   //           Navigator.of(context).pushReplacement<dynamic, dynamic>(
  //   //                   MaterialPageRoute<dynamic>(
  //   //                     builder: (context) => ScanOthersPage(),
  //   //                   ),
  //   //                 );
  //   //         });
  //   //         setState(() => barcode = result.confirmationCode);
  //   //       }
  //   //     });
  //   //   } else {
  //   //     setState(() => barcode = 'QR code not recognized');
  //   //     Utilities.say(
  //   //         'The QR code was not recognized. Please ensure you are scanning a valid QR code at a muster point.');
  //   //   }
  //   // });

  // }

// ########### DON'T DELETE - This is for use wtih FastBarcode Scan, which is preferred over Barcode Scanner

  void scanUserBarcode() async {
    if (controller == null) {
      setState(() => barcode = 'Scanning');
      cameras = await availableCameras();

      onNewCameraSelected(cameras[0]);
    } else {
      await stopScanning();
      setState(() => barcode = 'Waiting for scan');
    }
  }

  List<CameraDescription> cameras;

  void onCodeRead(dynamic scanResult) async {

    final AudioCache audioPlayer = AudioCache(prefix: 'sounds/');
    audioPlayer.play('camera.mp3');

    setState(() => barcode = 'Processing QR Scan');
    await stopScanning();

    ProcessQrScanService srv = ProcessQrScanService();
    final Future<ProcessQrScanModel> apiCall =
        srv.processQrScan('', scanResult, 'UserScan', '', '', '');
    apiCall.then((ProcessQrScanModel result) {
      setState(() => barcode = result.resultStr1);
    });
  }

  // void onCodeRead(dynamic scanResult) async {
  //   setState(() => barcode = scanResult);

  //   // String passNumber = Preferences.getStringPref(StringPrefsEnum.passNumber);
  //   // String lastNameFragment =
  //   //     Preferences.getStringPref(StringPrefsEnum.lastNameFragment)
  //   //         .toLowerCase();

  //   // String passNumberFragment = passNumber.substring(passNumber.length - 4);
  //   // String md5HashPassNumberFragment =
  //   //     Utilities.md5HashText(passNumberFragment);

  //   // String encryptedPassNumber = Utilities.encryptText(
  //   //     EnumEncryptionKeyName.passNumber, md5HashPassNumberFragment);
  //   // String encryptedLastNameFragment = Utilities.encryptText(
  //   //     EnumEncryptionKeyName.lastNameFragment, lastNameFragment);

  //   // setState(() => barcode = 'Processing QR Scan');
  //   // await stopScanning();

  //   // int musterType = -1;
  //   // if (scanResult.toUpperCase().startsWith(SELF_MUSTER_HEADER)) {
  //   //   musterType = 0;
  //   // }

  //   // if (scanResult.toUpperCase().startsWith(MOBILE_MUSTER_HEADER)) {
  //   //   musterType = 1;
  //   // }

  //   // if ((musterType == 0) || (musterType == 1)) {
  //   //   setState(() => barcode = 'Processing scan data');
  //   //   CheckInResultService srv = CheckInResultService();
  //   //   final Future<CheckInResultModel> apiCall = srv.checkIn(
  //   //       scanResult, encryptedPassNumber, encryptedLastNameFragment, musterType);
  //   //   apiCall.then((CheckInResultModel result) {
  //   //     if (result?.confirmationCode == null) {
  //   //       setState(() => barcode = 'Error processing QR code');
  //   //       Utilities.say(
  //   //           'Error processing QR code. Please ensure you are scanning a valid QR code at a muster point.');
  //   //     } else {
  //   //       Utilities.say(result.result == 1
  //   //               ? 'You are mustered with muster code ${result.confirmationCode} at muster point ${result.musterPointName}. Please use your Managed Response app to help others muster.'
  //   //               : result.result == 2
  //   //                   ? 'You are already mustered with muster code ${result.confirmationCode} at muster point ${result.musterPointName}. Please use your Managed Response app to help others muster.'
  //   //                   : 'Unknown muster code result')
  //   //           .then<dynamic>((void dummy) {
  //   //         Navigator.of(context).pushReplacement<dynamic, dynamic>(
  //   //           MaterialPageRoute<dynamic>(
  //   //             builder: (context) => ScanOthersPage(
  //   //                 mobileMusterPointId: result.mobileMusterPointId,
  //   //                 confirmationCode: result.confirmationCode,
  //   //                 musterPointName: result.musterPointName),
  //   //           ),
  //   //         );
  //   //       });
  //   //       setState(() => barcode =
  //   //           '${result.confirmationCode.trim().replaceAll(' ', '')} at ${result.musterPointName.trim()}');
  //   //     }
  //   //   });
  //   // } else {
  //   //   setState(() => barcode = 'QR code not recognized');
  //   //   Utilities.say(
  //   //       'The QR code was not recognized. Please ensure you are scanning a valid QR code at a muster point.');
  //   // }
  // }

  Future stopScanning() async {
    controller.stopScanning();
    await controller.dispose();
    controller = null;
  }

  Widget _cameraPreviewWidget() {
    return LayoutBuilder(builder: (context, constraint) {
      return new Stack(children: <Widget>[
        Image.asset(
          'images/other/qr_scanner.png',
        ),
        Container(
          padding: EdgeInsets.all(9.0),
          height: constraint.biggest.height,
          width: constraint.biggest.height,
          child: (controller == null)
              ? Container()
              : new QRReaderPreview(controller),
        )
      ]);
    });

    // ;
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = new QRReaderController(cameraDescription,
        ResolutionPreset.high, [CodeFormat.qr, CodeFormat.pdf417], onCodeRead);

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) setState(() {});
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
  }

  void showInSnackBar(String message) {
    // _scaffoldKey.currentState
    //     .showSnackBar(new SnackBar(content: new Text(message)));
  }

  Future<bool> _displayInstructions(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('QR Code Scanner'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'You can use your QR scanner to add friends to your Harrier Central friend list simply by scanning their personal QR code.\r\n\r\nYou can also use your scanner to check in when you arrive at runs and to check in when you are done with trail so the hares know who is still out.',
                  textAlign: TextAlign.justify,
                  style: const TextStyle(
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
              child: Text("OK, Got it!"),
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
        //   padding: EdgeInsets.only(top: 70.0, left: 24.0, right: 24.0),
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
        //   child: Padding(
        //     padding: EdgeInsets.all(100),
        //     child: Container(
        //       color: Colors.yellow,
        //       // height: 200,
        //       // width: 200,
        //     ),
        //   ),
        // ),

        new Expanded(
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
                  //margin: EdgeInsets.all(20.0),
                  width: 280.0,
                  child: RaisedButton(
                      child: Text(
                        controller == null
                            ? 'Start scanning'
                            : 'Stop Scanning',
                        style: TextStyle(
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
                  child: Text("Learn more about this feature"),
                  onPressed: () {
                    this._displayInstructions(context);
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
