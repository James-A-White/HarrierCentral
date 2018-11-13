import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';

import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/remote_api_data/process_qr_scan_service.dart';
import 'package:harrier_central/data_models/process_qr_scan_model.dart';

import 'package:qr_flutter/qr_flutter.dart';

class UserQrCodePage extends StatefulWidget {
  UserQrCodePage({Key key}) : super(key: key);

  @override
  _UserQrCodePageState createState() => _UserQrCodePageState();
}

class _UserQrCodePageState extends State<UserQrCodePage> {
  // final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  PageController _pageController;

  Color left = Colors.white;
  Color right = Colors.white;

  String barcode = '';

  @override
  void initState() {
    super.initState();

    // SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    //   DeviceOrientation.portraitUp,
    //   DeviceOrientation.portraitDown,
    // ]);

    _pageController = PageController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //key: _scaffoldKey,

      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          'My QR Code',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),

      body:

          // NotificationListener<OverscrollIndicatorNotification>(
          //   onNotification: (OverscrollIndicatorNotification overscroll) {
          //     overscroll.disallowGlow();
          //   },
          //   child:

          SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height - 100,
          // height: MediaQuery.of(context).size.height >= 300.0
          //     ? MediaQuery.of(context).size.height
          //     : 300.0,
          // decoration: BoxDecoration(
          //   gradient: LinearGradient(
          //       colors: <Color>[
          //         LoginColors.loginGradientStart,
          //         LoginColors.loginGradientEnd
          //       ],
          //       begin: const FractionalOffset(0.0, 0.0),
          //       end: const FractionalOffset(1.0, 1.0),
          //       stops: const <double>[0.0, 1.0],
          //       tileMode: TileMode.clamp),
          // ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: _buildMenuBar(context),
              ),
              Expanded(
                flex: 2,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (int i) {
                    if (i == 0) {
                      setState(() {
                        right = Colors.white;
                        left = Colors.white;
                      });
                    } else if (i == 1) {
                      setState(() {
                        right = Colors.white;
                        left = Colors.white;
                      });
                    }
                  },
                  children: <Widget>[
                    ConstrainedBox(
                      constraints: const BoxConstraints.expand(),
                      child: _buildMyQrCode(context),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints.expand(),
                      child: _buildSignIn(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      //),
    );
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

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
                onPressed: _onSignInTabPress,
                child: Text(
                  'My QR Code',
                  style: TextStyle(
                      color: left,
                      fontSize: 16.0,
                      fontFamily: 'WorkSansSemiBold'),
                ),
              ),
            ),
            //Container(height: 33.0, width: 1.0, color: Colors.white),
            Expanded(
              child: FlatButton(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onPressed: _onSignUpTabPress,
                child: Text(
                  'My Scanner',
                  style: TextStyle(
                      color: right,
                      fontSize: 16.0,
                      fontFamily: 'WorkSansSemiBold'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyQrCode(BuildContext context) {
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

  Widget _buildSignIn(BuildContext context) {
    String userName = Preferences.getStringPref(StringPrefsEnum.displayName);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(left: 24.0, right: 24.0),
            child: Text(
              'Scan to add friends and scan to check yourself in at the start and end of runs.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'AvenirNextDemiBold',
                  fontStyle: FontStyle.normal,
                  fontSize: 24.0,
                  height: 1.0),
            ),
          ),
          new Center(
            child: new Column(
              children: <Widget>[
                Container(
                  width: 150.0,
                  child: RaisedButton(
                      child: const Text(
                        'Start Scanning',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: scanUserBarcode),
                ),
                Padding( 
                  padding: EdgeInsets.only(left:24.0, right: 24.0, top:35.0),
                  child:Text(
                  barcode,
                  textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'AvenirNextDemiBold',
                  fontStyle: FontStyle.normal,
                  fontSize: 24.0,
                  height: 1.0),
            
                  ),),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 32.0, right: 32.0, bottom: 16.0),
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

  Future<void> scanUserBarcode() async {
    Future<String> scanAction = BarcodeScanner.scan();
    scanAction.then((String s) {
      ProcessQrScanService srv = ProcessQrScanService();
      Future<ProcessQrScanModel> apiCall =
          srv.processQrScan('', s, 'UserScan', '', '', '');
      apiCall.then((ProcessQrScanModel result) {
        setState(() => barcode = result.resultStr1);
      });
      setState(() => barcode = "Processing QR Scan");
    });
    // try {
    //   Future<String> scanAction = BarcodeScanner.scan();
    //   scanAction.then((String s) {
    //     setState(() => barcode = s);
    //   });
    // } on PlatformException catch (e) {
    //   if (e.code == BarcodeScanner.CameraAccessDenied) {
    //     setState(() {
    //       this.barcode = 'The user did not grant the camera permission!';
    //     });
    //   } else {
    //     setState(() => this.barcode = 'Unknown error: $e');
    //   }
    // } on FormatException {
    //   setState(() => this.barcode =
    //       'null (User returned using the "back"-button before scanning anything. Result)');
    // } catch (e) {
    //   setState(() => this.barcode = 'Unknown error: $e');
    // }
  }

  void _onSignInTabPress() {
    _pageController.animateToPage(0,
        duration: Duration(milliseconds: 500), curve: Curves.decelerate);
  }

  void _onSignUpTabPress() {
    _pageController?.animateToPage(1,
        duration: Duration(milliseconds: 500), curve: Curves.decelerate);
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
