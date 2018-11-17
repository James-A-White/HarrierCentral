// import 'dart:async';
// import 'dart:core';
// import 'dart:ui';

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';

// import 'package:barcode_scan/barcode_scan.dart';

// import 'package:harrier_central/data_models/process_qr_scan_model.dart';
// import 'package:harrier_central/pages/run_admin/check_in_scanner_page.dart';
// import 'package:harrier_central/remote_api_data/process_qr_scan_service.dart';


// class UserQrCodePage extends StatelessWidget {
//   UserQrCodePage({Key key}) : super(key: key);

//   String barcode = 'Result';

//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   @override
//   Widget build(BuildContext context) {
//     return 
//     Scaffold(
//       key: _scaffoldKey,
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).selectedRowColor,
//         //title: Text('Bubble Tab Indicator'),
//         automaticallyImplyLeading: false,
//         flexibleSpace: Text('testing'

//         ),
//       ),
//     body: Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: <Widget>[
//           Padding(
//             padding: EdgeInsets.only(left: 24.0, right: 24.0),
//             child: Text(
//               'Scan to add friends and scan to check yourself in at the start and end of runs.',
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                   fontFamily: 'AvenirNextDemiBold',
//                   fontStyle: FontStyle.normal,
//                   fontSize: 24.0,
//                   height: 1.0),
//             ),
//           ),
//           new Center(
//             child: new Column(
//               children: <Widget>[
//                 Container(
//                   width: 150.0,
//                   child: RaisedButton(
//                       child: const Text(
//                         'Start Scanning',
//                         style: TextStyle(color: Colors.white),
//                       ),
//                       onPressed: () {
//                         //scanUserBarcode();

//                          Navigator.push<dynamic>(
//                                         context,
//                                         MaterialPageRoute<dynamic>(
//                                             builder: (context) =>
//                                                 CheckInScannerPage(
//                                                   kennelShortName: 'test',
//                                                   eventId:
//                                                       '00000000-0000-0000-0000-000000000000',
//                                                   eventName: 'dummy',
//                                                   eventNumber: 128,
//                                                 )));
//                                   }
//                   ),
//                 ),
//                 Padding(
//                   padding: EdgeInsets.only(left: 24.0, right: 24.0, top: 35.0),
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
//     ),
//     );

//   }

//   // @override
//   // void dispose() {
//   //   super.dispose();
//   // }

//   //   @override
//   // void initState() {
//   //   super.initState();

//     // SystemChrome.setPreferredOrientations(<DeviceOrientation>[
//     //   DeviceOrientation.portraitUp,
//     //   DeviceOrientation.portraitDown,
//     // ]);
//   //}


//   Future<void> scanUserBarcode() async {
    
//     Future<String> scanAction = BarcodeScanner.scan();
//     scanAction.then((String s) {
//       barcode = s;
//       // ProcessQrScanService srv = ProcessQrScanService();
//       // Future<ProcessQrScanModel> apiCall =
//       //     srv.processQrScan('', s, 'UserScan', '', '', '');
//       // apiCall.then((ProcessQrScanModel result) {
//       //   setState(() => barcode = result.resultStr1);
//       // });
//       // setState(() => barcode = "Processing QR Scan");
//     });

//     // } on PlatformException catch (e) {
//     //   if (e.code == BarcodeScanner.CameraAccessDenied) {
//     //     setState(() {
//     //       this.barcode = 'The user did not grant the camera permission!';
//     //     });
//     //   } else {
//     //     setState(() => this.barcode = 'Unknown error: $e');
//     //   }
//     // } on FormatException {
//     //   setState(() => this.barcode =
//     //       'null (User returned using the "back"-button before scanning anything. Result)');
//     // } catch (e) {
//     //   setState(() => this.barcode = 'Unknown error: $e');
//     // }

//     // try {
//     //   Future<String> scanAction = BarcodeScanner.scan();
//     //   scanAction.then((String s) {
//     //     setState(() => barcode = s);
//     //   });
//     // } on PlatformException catch (e) {
//     //   if (e.code == BarcodeScanner.CameraAccessDenied) {
//     //     setState(() {
//     //       this.barcode = 'The user did not grant the camera permission!';
//     //     });
//     //   } else {
//     //     setState(() => this.barcode = 'Unknown error: $e');
//     //   }
//     // } on FormatException {
//     //   setState(() => this.barcode =
//     //       'null (User returned using the "back"-button before scanning anything. Result)');
//     // } catch (e) {
//     //   setState(() => this.barcode = 'Unknown error: $e');
//     // }
//   }
// }

