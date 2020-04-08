import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:fast_qr_reader_view/fast_qr_reader_view.dart';
import 'package:audioplayers/audio_cache.dart';

import 'package:harrier_central/database/common_queries.dart';
import 'package:ive_flutter_core/database/base_service.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/widgets/bubble_tab_indicator.dart';

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

  // Future<bool> _displayInstructions(BuildContext context) async {
  //   return showDialog<bool>(
  //     context: context,
  //     barrierDismissible: false, // user must tap button!
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('About your QR Scanner'),
  //         content: SingleChildScrollView(
  //           child: ListBody(
  //             children: const <Widget>[
  //               Text(
  //                 'You can use your QR scanner to add friends to your Harrier Central friend list simply by scanning their personal QR code. You can also use your scanner to check in when you arrive at runs and to check in when you are done with trail so the hares know who is still out.',
  //                 textAlign: TextAlign.justify,
  //                 style: TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 16.0, height: 1.0),
  //               )
  //             ],
  //           ),
  //         ),
  //         actions: <Widget>[
  //           FlatButton(
  //             child: const Text('OK, Got it!'),
  //             onPressed: () {
  //               Navigator.of(context).pop(true);
  //             },
  //           ),
  //         ],
  //       );
  //     },
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

class TabIndicationPainter extends CustomPainter {
  TabIndicationPainter({this.context, this.dxTarget = 125.0, this.dxEntry = 25.0, this.radius = 21.0, this.dy = 25.0, this.pageController}) : super(repaint: pageController) {
    painter = Paint()
      ..color = Theme.of(context).accentColor
      ..style = PaintingStyle.fill;
  }

  Paint painter;
  final num dxTarget;
  final num dxEntry;
  final num radius;
  final num dy;
  BuildContext context;

  final PageController pageController;

  @override
  void paint(Canvas canvas, Size size) {
    final ScrollPosition pos = pageController.position;
    final num fullExtent = pos.maxScrollExtent - pos.minScrollExtent + pos.viewportDimension;

    final num pageOffset = pos.extentBefore / fullExtent;

    final bool left2right = dxEntry < dxTarget;
    final Offset entry = Offset(left2right ? dxEntry : dxTarget, dy);
    final Offset target = Offset(left2right ? dxTarget : dxEntry, dy);

    final Path path = Path();
    path.addArc(Rect.fromCircle(center: entry, radius: radius), 0.5 * math.pi, 1 * math.pi);
    path.addRect(Rect.fromLTRB(entry.dx, dy - radius, target.dx, dy + radius));
    path.addArc(Rect.fromCircle(center: target, radius: radius), 1.5 * math.pi, 1 * math.pi);

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

class _QrCodeTabState extends State<QrCodeTab> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
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
                  style: TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 16.0, height: 1.0),
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
              height: (deviceWidthScaleFactor - 1) * 90,
            ),
            Container(
              padding: const EdgeInsets.only(top: 0, bottom: 30, right: 25, left: 25),
              child: Text(
                'Use this code to check in at the beginning and end of runs. Your friends can also scan this code to add you to their friend list. ',
                textAlign: TextAlign.justify,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'AvenirNextDemiBold',
                  fontStyle: FontStyle.normal,
                  fontSize: 16.0 * deviceWidthScaleFactor,
                  height: 1.0,
                ),
              ),
            ),

            AutoSizeText(
              'QR for: $userName',
              //'QR Code for xxx',
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 24.0 * deviceWidthScaleFactor, height: 1.0),
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
                    //height: math.min(constraints.maxHeight, constraints.maxWidth) * 0.65,
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

            Padding(
              padding: const EdgeInsets.only(left: 0.0, right: 0.0),
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
      setState(() => onScreenMessage = 'Scanning');
      cameras = await availableCameras();

      onNewCameraSelected(cameras[0]);
    } else {
      await stopScanning();
      setState(() => onScreenMessage = 'Waiting for scan');
    }

    // return Future<void>(() {});(() {});
  }

  Future<void> onCodeRead(dynamic scanResult) async {
    final AudioCache audioPlayer = AudioCache(prefix: 'sounds/');
    audioPlayer.play('camera.mp3');

    setState(() => onScreenMessage = 'Processing QR Scan');
    await stopScanning();

    //final Map<String,String> result = Utilities.validateScan(scanResult, Utilities.qrScanTypeFlag_user | Utilities.qrScanTypeFlag_kennelRunEnd| Utilities.qrScanTypeFlag_kennelRunStart| Utilities.qrScanTypeFlag_runStart| Utilities.qrScanTypeFlag_runEnd);
    final Map<String, String> result = Utilities.validateScan(scanResult, Utilities.qrScanTypeFlag_user | Utilities.qrScanTypeFlag_runStart | Utilities.qrScanTypeFlag_runEnd | Utilities.qrScanTypeFlag_kennelRunEnd | Utilities.qrScanTypeFlag_kennelRunStart);

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

        hasherEventMapService.joinEvent(content, TableType.hemUser, userId, null,AppDomainType.user , rsvpState: rsvpYes.value, attendenceState: attendenceState, isHare: isHareNo.value, virginVisitorType: enumHasher.value).then((List<dynamic> adHocData) {
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
                onScreenMessage = 'The next event does not open for check-in for another ${NumberFormat('###').format(hoursUntilNextEvent * 60)} minute' + NumberFormat('###').format(hoursUntilNextEvent * 60) != '1' ? 's' : '';
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

            hasherEventMapService.joinEvent(eventId, TableType.hemUser, userId, null,AppDomainType.user , rsvpState: rsvpYes.value, attendenceState: attendenceState, isHare: isHareNo.value).then((List<dynamic> adHocData) {
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

  Future<dynamic> stopScanning() async {
    controller.stopScanning();
    await controller.dispose();
    controller = null;
  }

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

  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = QRReaderController(cameraDescription, ResolutionPreset.high, <CodeFormat>[CodeFormat.qr, CodeFormat.pdf417], onCodeRead);

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
                  style: TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 16.0, height: 1.0),
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
        SizedBox(
          width: 10,
          height: (deviceWidthScaleFactor - 1) * 90,
        ),
        Container(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: AutoSizeText(
            'Use this scanner to either scan in at the beginning or end of runs or to scan the QR codes of other Hashers who you want to add to your friend list.',
            textAlign: TextAlign.justify,
            maxLines: 4,
            style: TextStyle(color: Colors.white, fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, fontSize: 16.0 * deviceMaxScaleFactor, height: 1.0),
          ),
        ),

        //_cameraPreviewWidget(),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(10 * (deviceMaxScaleFactor * 1.5)),
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: <Widget>[
                Image.asset(
                  'images/other/qr_scanner.png',
                ),
                (controller == null)
                    ? Container()
                    : Container(
                        padding: const EdgeInsets.all(11.0),
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: QRReaderPreview(controller),
                        ),
                      ),
              ],
            ),
          ),
        ),
        // // child:Container(
        // //   child: _cameraPreviewWidget(), width: 200.0, height: 200.0),

        Container(
          //margin: const EdgeInsets.all(20.0),
          width: 280.0,
          child: Utilities.styleForConnected(
            RaisedButton(
                child: Text(
                  controller == null ? 'Start Scanning' : 'Stop Scanning',
                  style: const TextStyle(fontFamily: 'AvenirNextDemiBold', color: Colors.white, fontStyle: FontStyle.normal, fontSize: 22.0, height: 1.0),
                ),
                onPressed: () {
                  if (Utilities.checkForConnection(context)) {
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

        FlatButton(
          textColor: Colors.white,
          child: const Text('Learn more about this feature'),
          onPressed: () {
            _displayInstructions(context);
          },
        ),
      ],
    );
  }
}
