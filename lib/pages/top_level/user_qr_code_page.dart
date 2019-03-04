import 'dart:math';

//import 'package:barcode_scan/barcode_scan.dart';

import 'package:flutter/material.dart';

import 'package:harrier_central/data_models/process_qr_scan_model.dart';
import 'package:harrier_central/remote_api_data/process_qr_scan_service.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/widgets/bubble_tab_indicator.dart';

import 'package:qr_flutter/qr_flutter.dart';
//import 'package:fast_qr_reader_view/fast_qr_reader_view.dart';

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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(120.0),
        child: Padding(
          padding: EdgeInsets.all(30.0),
          child: Container(
            width: 320.0,
            height: 65.0,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColorLight,
              borderRadius: BorderRadius.all(Radius.circular(45.0)),
            ),
            child: Padding(
              padding: EdgeInsets.only(left: 5.0, right: 5.0),
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
                  indicatorHeight: 45.0,
                  indicatorColor: Theme.of(context).buttonColor,
                  tabBarIndicatorSize: TabBarIndicatorSize.tab,
                ),
                tabs: tabs,
                controller: _tabController,
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          TabBarView(
            controller: _tabController,
            children: <Widget>[QrCodeTab(), QrScannerTab()],
          ),
        ],
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
                onPressed: _onSwitchToQrCode,
                child: Text(
                  'My QR Code',
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
                onPressed: _onSwitchToQrScanner,
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
      tabs.add(Tab(text: 'My QR Code'));
      tabs.add(Tab(text: 'QR Scanner'));
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
          title: Text('Your Hash QR Code'),
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
        children: <Widget>[
          Text(
            'QR Code for: $userName',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontFamily: 'AvenirNextDemiBold',
                fontStyle: FontStyle.normal,
                fontSize: 24.0,
                height: 1.0),
          ),
          QrImage(
              padding: EdgeInsets.all(10.0),
              data: userQrCode,
              version: 4,
              size: 200.0,
              errorCorrectionLevel: 3),
          Padding(
            padding: EdgeInsets.only(left: 32.0, right: 32.0),
            child: FlatButton(
              textColor: Theme.of(context).buttonColor,
              child: Text("Learn more about this feature"),
              onPressed: () {
                this._displayInstructions(context);
              },
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
  String barcode = 'Waiting';

  //QRReaderController controller;

  @override
  bool get wantKeepAlive => true;

  void scanUserBarcode() async {
    // if (controller == null) {
    //   cameras = await availableCameras();
    //   onNewCameraSelected(cameras[0]);
    // } else {
    //   await stopScanning();
    //   setState(() => barcode = 'Waiting');
    // }
  }

  //List<CameraDescription> cameras;

  void onCodeRead(dynamic scanResult) async {
    setState(() => barcode = 'Processing QR Scan');
    await stopScanning();

    ProcessQrScanService srv = ProcessQrScanService();
    final Future<ProcessQrScanModel> apiCall =
        srv.processQrScan('', scanResult, 'UserScan', '', '', '');
    apiCall.then((ProcessQrScanModel result) {
      setState(() => barcode = result.resultStr1);
    });
  }

  Future stopScanning() async {
    // controller.stopScanning();
    // await controller.dispose();
    // controller = null;
  }

  // Widget _cameraPreviewWidget() {
  //   return Stack(children: <Widget>[
  //     Image.asset(
  //       'images/other/qr_scanner.png',
  //     ),
  //     Padding(
  //       padding: EdgeInsets.all(7.0),
  //       child: (controller == null)
  //           ? Container()
  //           : new QRReaderPreview(controller),
  //     )
  //   ]);
  // }

  // void onNewCameraSelected(CameraDescription cameraDescription) async {
  //   if (controller != null) {
  //     await controller.dispose();
  //   }
  //   controller = new QRReaderController(cameraDescription, ResolutionPreset.low,
  //       [CodeFormat.qr, CodeFormat.pdf417], onCodeRead);

  //   // If the controller is updated then update the UI.
  //   controller.addListener(() {
  //     if (mounted) setState(() {});
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
  // }

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
          title: Text('Hash Scanner'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Use this scanner to add other Hashers to your friend list.\r\n\r\nIf the hares for a run have posted QR codes for the run, you can also use the scanner to check yourself in at the start and end of the run.',
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(left: 24.0, right: 24.0),
            child: Text(
              'Scan to add friends and scan to check yourself in at runs.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'AvenirNextDemiBold',
                  fontStyle: FontStyle.normal,
                  fontSize: 22.0,
                  height: 1.0),
            ),
          ),
          new Center(
            child: new Column(
              children: <Widget>[
                Container(
                  margin: EdgeInsets.all(20.0),
                  width: 220.0,
                  child: RaisedButton(
                      child: Text(
                        //((controller == null)
                        ((1==1)
                            ? 'Start Scanning'
                            : 'Stop Scanning'),
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
                // Container(
                //     child: _cameraPreviewWidget(), width: 200.0, height: 200.0),
                Padding(
                  padding: EdgeInsets.only(left: 24.0, right: 24.0, top: 35.0),
                  child: Text(
                    barcode,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: 'AvenirNextDemiBold',
                        fontStyle: FontStyle.normal,
                        fontSize: 24.0,
                        height: 1.0),
                  ),
                ),
                 Padding(
            padding: EdgeInsets.only(left: 32.0, right: 32.0),
            child: FlatButton(
              textColor: Theme.of(context).buttonColor,
              child: Text("Learn more about this feature"),
              onPressed: () {
                this._displayInstructions(context);
              },
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
