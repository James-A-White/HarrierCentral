// import 'dart:math';

// import 'package:flutter/material.dart';

// import 'package:qr_flutter/qr_flutter.dart';

//
// import 'package:harrier_central/widgets/bubble_tab_indicator.dart';
// import 'package:harrier_central/data/models/kennel_member_model.dart';
// import 'package:harrier_central/util/styles.dart';

// class UserSecretQrPage extends StatefulWidget {
//   const UserSecretQrPage({Key key, this.kennelMemberModel}) : super(key: key);

//   final KennelMemberModel kennelMemberModel;

//   @override
//   _UserSecretQrCodePageState createState() => _UserSecretQrCodePageState();
// }

// class _UserSecretQrCodePageState extends State<UserSecretQrPage>
//     with SingleTickerProviderStateMixin {
//   List<Tab> tabs = <Tab>[];

//   String barcode = '';
//   bool isAdmin = true;

//   PageController _pageController;
//   TabController _tabController;

//   final String userId = getStringPref(StringPrefsEnum.userId);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: themeAppBarBackground,
//         title: Text('Admin for: ${widget.kennelMemberModel.displayName}'),
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(120.0),
//           child: Padding(
//             padding: const EdgeInsets.all(30.0),
//             child: Container(
//               width: 320.0,
//               height: 90.0,
//               decoration: BoxDecoration(
//                 color: Theme.of(context).primaryColorLight,
//                 borderRadius: const BorderRadius.all(Radius.circular(45.0)),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.only(left: 5.0, right: 5.0),
//                 child:

//                 TabBar(
//                   labelStyle: const TextStyle(
//                       fontFamily: 'AvenirNextCondensedMedium',
//                       fontStyle: FontStyle.normal,
//                       fontSize: 18.0,
//                       height: 1.0),
//                   unselectedLabelStyle: const TextStyle(
//                       fontFamily: 'AvenirNextCondensedMedium',
//                       fontStyle: FontStyle.normal,
//                       fontSize: 18.0,
//                       height: 1.0),
//                   isScrollable: false,
//                   unselectedLabelColor: Colors.black,
//                   labelColor: Colors.white,
//                   indicatorSize: TabBarIndicatorSize.tab,
//                   indicator: BubbleTabIndicator(
//                     indicatorHeight: 45.0,
//                     indicatorColor: Theme.of(context).buttonColor,
//                     tabBarIndicatorSize: TabBarIndicatorSize.tab,
//                   ),
//                   tabs: tabs,
//                   controller: _tabController,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//       body: Stack(
//         children: <Widget>[
//           TabBarView(
//             controller: _tabController,
//             children: <Widget>[
//               QrCodeTab(kennelMemberModel: widget.kennelMemberModel),
//               const QrScannerTab()
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _pageController?.dispose();
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   void initState() {
//     super.initState();
//     _initTabs();

//     _pageController = PageController(initialPage: 0, keepPage: true);
//     _tabController = TabController(vsync: this, length: tabs.length);
//   }

//   Color left = Colors.white;
//   Color right = Colors.white;

//   // Widget _buildMenuBar(BuildContext context) {
//   //   return Container(
//   //     width: 300.0,
//   //     height: 50.0,
//   //     decoration: const BoxDecoration(
//   //       color: Color(0x552B2B2B),
//   //       borderRadius: BorderRadius.all(Radius.circular(25.0)),
//   //     ),
//   //     child: CustomPaint(
//   //       painter: TabIndicationPainter(
//   //           context: context, pageController: _pageController),
//   //       child: Row(
//   //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//   //         children: <Widget>[
//   //           Expanded(
//   //             child: TextButton(
//   //               splashColor: Colors.transparent,
//   //               highlightColor: Colors.transparent,
//   //               onPressed: _onSwitchToQrCode,
//   //               child: Text(
//   //                 'My QR Code',
//   //                 style: TextStyle(
//   //                     color: left,
//   //                     fontSize: 14.0,
//   //                     fontFamily: 'WorkSansSemiBold'),
//   //               ),
//   //             ),
//   //           ),
//   //           Expanded(
//   //             child: TextButton(
//   //               splashColor: Colors.transparent,
//   //               highlightColor: Colors.transparent,
//   //               onPressed: _onSwitchToQrScanner,
//   //               child: Text(
//   //                 'My Scanner',
//   //                 style: TextStyle(
//   //                     color: right,
//   //                     fontSize: 14.0,
//   //                     fontFamily: 'WorkSansSemiBold'),
//   //               ),
//   //             ),
//   //           ),
//   //         ],
//   //       ),
//   //     ),
//   //   );
//   // }

//   // Future<bool> _displayInstructions(BuildContext context) async {
//   //   return showDialog<bool>(
//   //     context: context,
//   //     barrierDismissible: false, // user must tap button!
//   //     builder: (BuildContext context) {
//   //       return AlertDialog(
//   //         title: const Text('About your QR Scanner',
          //   style: ts_alertDialogTitle,
          // ),
//   //         content: SingleChildScrollView(
//   //           child: ListBody(
//   //             children: const <Widget>[
//   //               Text(
//   //                 'You can use your QR scanner to add friends to your Harrier Central friend list simply by scanning their personal QR code. You can also use your scanner to check in when you arrive at runs and to check in when you are done with trail so the hares know who is still out.',
//   //                 textAlign: TextAlign.justify,
//   //                 style: TextStyle(
//   //                     fontFamily: 'AvenirNextRegular',
//   //                     fontStyle: FontStyle.normal,
//   //                     fontSize: 16.0,
//   //                     height: 1.0),
//   //               )
//   //             ],
//   //           ),
//   //         ),
//   //         actions: <Widget>[
//   //           TextButton(
//   //             child: const Text('OK, Got it!'),
//   //             onPressed: () {
//   //               Navigator.of(context).pop(true);
//   //             },
//   //           ),
//   //         ],
//   //       );
//   //     },
//   //   );
//   // }

//   void _initTabs() {
//     if (tabs.isEmpty) {
//       tabs.add(const Tab(text: 'My QR Code'));
//       tabs.add(const Tab(text: 'QR Scanner'));
//     }
//   }

//   // void _onSwitchToQrCode() {
//   //   _pageController.animateToPage(0,
//   //       duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
//   // }

//   // void _onSwitchToQrScanner() {
//   //   _pageController?.animateToPage(1,
//   //       duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
//   // }
// }

// class TabIndicationPainter extends CustomPainter {
//   TabIndicationPainter(
//       {this.context,
//       this.dxTarget = 125.0,
//       this.dxEntry = 25.0,
//       this.radius = 21.0,
//       this.dy = 25.0,
//       this.pageController})
//       : super(repaint: pageController) {
//     painter = Paint()
//       ..color = Theme.of(context).accentColor
//       ..style = PaintingStyle.fill;
//   }

//   Paint painter;
//   final num dxTarget;
//   final num dxEntry;
//   final num radius;
//   final num dy;
//   BuildContext context;

//   final PageController pageController;

//   @override
//   void paint(Canvas canvas, Size size) {
//     final ScrollPosition pos = pageController.position;
//     final num fullExtent =
//         pos.maxScrollExtent - pos.minScrollExtent + pos.viewportDimension;

//     final num pageOffset = pos.extentBefore / fullExtent;

//     final bool left2right = dxEntry < dxTarget;
//     final Offset entry = Offset(left2right ? dxEntry : dxTarget, dy);
//     final Offset target = Offset(left2right ? dxTarget : dxEntry, dy);

//     final Path path = Path();
//     path.addArc(
//         Rect.fromCircle(center: entry, radius: radius), 0.5 * pi, 1 * pi);
//     path.addRect(Rect.fromLTRB(entry.dx, dy - radius, target.dx, dy + radius));
//     path.addArc(
//         Rect.fromCircle(center: target, radius: radius), 1.5 * pi, 1 * pi);

//     canvas.translate(size.width * pageOffset, 0.0);
//     canvas.drawShadow(path, const Color(0xFFfbab66), 3.0, true);
//     canvas.drawPath(path, painter);
//   }

//   @override
//   bool shouldRepaint(TabIndicationPainter oldDelegate) => true;
// }

// class QrCodeTab extends StatefulWidget {
//   const QrCodeTab({Key key, this.kennelMemberModel}) : super(key: key);

//   final KennelMemberModel kennelMemberModel;

//   @override
//   _QrCodeTabState createState() => _QrCodeTabState();
// }

// class _QrCodeTabState extends State<QrCodeTab>
//     with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
//   @override
//   bool get wantKeepAlive => true;

//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//     // final String userName = getStringPref(StringPrefsEnum.displayName);
//     // final String userQrCode = getStringPref(StringPrefsEnum.qrCode);

//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: <Widget>[
//           Text(
//             'QR Authentication Code for:\r\n${widget.kennelMemberModel.displayName}',
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//                 fontFamily: 'AvenirNextDemiBold',
//                 fontStyle: FontStyle.normal,
//                 fontSize: 24.0,
//                 height: 1.0),
//           ),
//           QrImage(
//               padding: const EdgeInsets.all(10.0),
//               data: widget.kennelMemberModel.qrSecretCode,
//               version: 4,
//               size: 200.0,
//               errorCorrectionLevel: 3),
//           Padding(
//             padding: const EdgeInsets.only(left: 32.0, right: 32.0),
//             child: TextButton(
//               textColor: Theme.of(context).buttonColor,
//               child: const Text('Learn more about this feature'),
//               onPressed: () {
//                 //this._displayInstructions(context);
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class QrScannerTab extends StatefulWidget {
//   const QrScannerTab({Key key}) : super(key: key);

//   @override
//   _QrScannerTabState createState() => _QrScannerTabState();
// }

// class _QrScannerTabState extends State<QrScannerTab>
//     with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
//   String barcode = 'Waiting';

//   @override
//   bool get wantKeepAlive => true;

//   void scanUserBarcode() {
//     // final Future<String> scanAction = BarcodeScanner.scan();
//     // scanAction.then((String s) {
//     //   ProcessQrScanService srv = ProcessQrScanService();
//     //   final Future<ProcessQrScanModel> apiCall =
//     //       srv.processQrScan('', s, 'UserScan', '', '', '');
//     //   apiCall.then((ProcessQrScanModel result) {
//     //     setState(() => barcode = result.resultStr1);
//     //   });
//     //   setState(() => barcode = 'Processing QR Scan');
//     // });
//   }

//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: <Widget>[
//           const Padding(
//             padding: EdgeInsets.only(left: 24.0, right: 24.0),
//             child: Text(
//               'Scan to add friends and scan to check yourself in at the start and end of runs.',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                   fontFamily: 'AvenirNextDemiBold',
//                   fontStyle: FontStyle.normal,
//                   fontSize: 24.0,
//                   height: 1.0),
//             ),
//           ),
//           Center(
//             child: Column(
//               children: <Widget>[
//                 Container(
//                   width: 150.0,
//                   child: ElevatedButton(
//                       child: const Text(
//                         'Start Scanning',
//                         style: TextStyle(color: Colors.white),
//                       ),
//                       onPressed: () {
//                         scanUserBarcode();
//                       }),
//                 ),
//                 Padding(
//                   padding:
//                       const EdgeInsets.only(left: 24.0, right: 24.0, top: 35.0),
//                   child: Text(
//                     barcode,
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(
//                         fontFamily: 'AvenirNextDemiBold',
//                         fontStyle: FontStyle.normal,
//                         fontSize: 24.0,
//                         height: 1.0),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
