import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fast_qr_reader_view/fast_qr_reader_view.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/services/process_qr_scan_service.dart';
import 'package:harrier_central/data_models/process_qr_scan_model.dart';
import 'package:harrier_central/pages/run_admin/payment_popup.dart';
import 'package:harrier_central/services/pay_for_event_service.dart';
import 'package:harrier_central/data_models/pay_for_event_model.dart';
import 'package:harrier_central/util/enums.dart';

class CheckInScannerPage extends StatefulWidget {
  const CheckInScannerPage(
      {@required this.kennelShortName,
      @required this.eventId,
      @required this.eventName,
      @required this.eventNumber,
      @required this.isRunStart});

  final String kennelShortName;
  final String eventId;
  final String eventName;
  final int eventNumber;
  final int isRunStart;

  @override
  _CheckInScannerPageState createState() => _CheckInScannerPageState();
}

class _CheckInScannerPageState extends State<CheckInScannerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        title: Text(
          widget.isRunStart == 1
              ? 'Scan at start of Hash'
              : 'Scan at end of Hash',
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(
                child: Stack(
                  alignment: AlignmentDirectional.center,
                  children: <Widget>[
                    Positioned(
                      top: 30,
                      width: MediaQuery.of(context).size.width * 0.86,
                      child: AutoSizeText(
                        widget.isRunStart == 1
                            ? 'Use this scanner to scan Hasher barcodes at the beginning of the run so that their run will count and they can be marked as paid.'
                            : 'Use this scanner to scan Hasher barcodes at the end of the run so you can ensure that no one is lost on trail and to identify people who still need to pay.',
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
                        top: 125,
                        bottom: 215,
                        //width:150,
                        //height:150,
                        child: _cameraPreviewWidget()
                        // child:Container(
                        //   child: _cameraPreviewWidget(), width: 200.0, height: 200.0),
                        ),
                    Positioned(
                      bottom: 140.0,
                      child: Container(
                        //margin: const EdgeInsets.all(20.0),
                        width: 280.0,
                        child: RaisedButton(
                            child: Text(
                              controller == null
                                  ? 'Start Scanning'
                                  : 'Stop Scanning',
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
                        height: 100,
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

              // Text(
              //   '${widget.kennelShortName} #${widget.eventNumber}',
              //   textAlign: TextAlign.center,
              //   style: const TextStyle(
              //     color: Colors.white,
              //       fontFamily: 'AvenirNextDemiBold',
              //       fontStyle: FontStyle.normal,
              //       fontSize: 24.0,
              //       height: 1.0),
              // ),
              // Text(
              //   widget.eventName,
              //   textAlign: TextAlign.center,
              //   style: const TextStyle(
              //     color: Colors.white,
              //       fontFamily: 'AvenirNextRegular',
              //       fontStyle: FontStyle.normal,
              //       fontSize: 28.0,
              //       height: 1.0),
              // ),
              // Center(
              //   child: Column(
              //     children: <Widget>[
              //       Container(
              //         width: 320.0,
              //         child: RaisedButton(
              //             child: const Text(
              //               'Start Scanning: RUN START',
              //               style: TextStyle(color: Colors.white),
              //             ),
              //             onPressed: () {
              //               //scanUserBarcode(true, widget.eventId);
              //             }),
              //       ),

              //       Container(
              //         padding: const EdgeInsets.only(top: 30.0),
              //         width: 320.0,
              //         child: RaisedButton(
              //             child: const Text(
              //               'Start Scanning: RUN END',
              //               style: TextStyle(color: Colors.white),
              //             ),
              //             onPressed: () {
              //               //scanUserBarcode(false, widget.eventId);
              //             }),
              //       ),

              //       // Container(
              //       //   child: MaterialButton(
              //       //       onPressed: scan, child: const Text('Scan')),
              //       //   padding: const EdgeInsets.all(8.0),
              //       // ),
              //       Padding(
              //         padding:
              //             const EdgeInsets.only(left: 24.0, right: 24.0, top: 35.0),
              //         child: Text(
              //           barcode,
              //           textAlign: TextAlign.center,
              //           style: const TextStyle(
              //               fontFamily: 'AvenirNextDemiBold',
              //               fontStyle: FontStyle.normal,
              //               fontSize: 24.0,
              //               height: 1.0),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              // Padding(
              //   padding:
              //       const EdgeInsets.only(left: 32.0, right: 32.0, bottom: 16.0),
              //   child: FlatButton(
              //     textColor: themeLearnMoreLink,
              //     child: const Text('Learn more about this feature'),
              //     onPressed: () {
              //       _displayInstructions(context);
              //     },
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  // Future<void> scanUserBarcode(bool isRunStart, String eventId) async {
  //   final String context2 = isRunStart ? '0' : '1';
  //   Future<String> scanAction = BarcodeScanner.scan();
  //   scanAction.then((String s) {
  //     ProcessQrScanService srv = ProcessQrScanService();
  //     Future<ProcessQrScanModel> apiCall =
  //         srv.processQrScan(eventId, s, 'CheckInOut', context2, 'user', '');
  //     apiCall.then((ProcessQrScanModel result) {
  //       setState(() => barcode = result.resultStr2);
  //       if (result.resultInt2 == 0) {
  //         PaymentPopup pp = PaymentPopup(
  //           amount: result.resultDecimal1,
  //           creditAllowed: result.resultInt3,
  //           creditRemaining: result.resultDecimal2,
  //           currencySymbol: result.resultStr1,
  //           hemId: result.resultGuid2,
  //           decimalDigits: result.resultInt4,
  //         );

  //         Future<bool> dlg = showDialog<bool>(
  //             context: context,
  //             barrierDismissible: false, // user must tap button!
  //             builder: (BuildContext context) {
  //               return pp;
  //             });

  //         dlg.then((bool x) {
  //           PayForEventService paySrv = PayForEventService();
  //           Future<List<PayForEventModel>> retVal = paySrv.payForEvent(
  //               result.resultGuid1,
  //               eventId,
  //               result.resultGuid2,
  //               pp.selectedValue,
  //               pp.amount,
  //               isRunStart == 1 ? attendenceAtHash.value : attendenceOnIn.value);
  //           retVal.then((List<PayForEventModel> paymentResult) {
  //             if (paymentResult.isNotEmpty) {
  //               setState(() => barcode = paymentResult[0].result);
  //             } else {
  //               setState(() => barcode = 'Error processing payment');
  //             }
  //           });
  //         });
  //       }
  //     });
  //     setState(() => barcode = 'Processing QR Scan');
  //   });
  // }

  String barcode = 'Waiting for Scan';

  QRReaderController controller;

  // @override
  // bool get wantKeepAlive => true;

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

    stopScanning();

    // setState(() {
    //   barcode = 'Processing QR Scan';
    //   //await stopScanning();
    // });

    final String context2 = widget.isRunStart == 1 ? '0' : '1';

    int ppSelectedValue = -1;

    final ProcessQrScanService srv = ProcessQrScanService();
    final Future<ProcessQrScanModel> apiCall = srv.processQrScan(
        widget.eventId, scanResult, 'CheckInOut', context2, 'admin', '');
    apiCall.then((ProcessQrScanModel result) {
      setState(() => barcode = result.resultStr2);
      if (result.resultInt2 != 0) {
        Future<dynamic>.delayed(const Duration(seconds: 2))
            .then<dynamic>((dynamic unused) {
          scanUserBarcode();
        });
      } else {
        final PaymentPopup pp = PaymentPopup(
          amount: result.resultDecimal1,
          creditAllowed: result.resultInt3,
          creditRemaining: result.resultDecimal2,
          currencySymbol: result.resultStr1,
          hemId: result.resultGuid2,
          decimalDigits: result.resultInt4,
          valueChanged: (num value) {
            ppSelectedValue = value;
          },
        );

        final Future<bool> dlg = showDialog<bool>(
            context: context,
            barrierDismissible: false, // user must tap button!
            builder: (BuildContext context) {
              return pp;
            });

        dlg.then((bool x) {
          if (ppSelectedValue != -1) {
            final PayForEventService paySrv = PayForEventService();
            final Future<List<PayForEventModel>> retVal = paySrv.payForEvent(
                result.resultGuid1,
                widget.eventId,
                result.resultGuid2,
                ppSelectedValue,
                pp.amount,
                widget.isRunStart == 1
                    ? attendenceAtHash.value
                    : attendenceOnIn.value);
            retVal.then((List<PayForEventModel> paymentResult) {
              if (paymentResult.isNotEmpty) {
                setState(() => barcode = paymentResult[0].result);
              } else {
                setState(() => barcode = 'Error processing payment');
              }
              Future<dynamic>.delayed(const Duration(seconds: 2))
                  .then<dynamic>((dynamic unused) {
                scanUserBarcode();
              });
            });
          }
        });
      }
    });
    setState(() => barcode = 'Processing QR Scan');
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
          title: const Text('Hasher Scanner'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text(
                  'Harrier Central admins can use this page to scan in Hashers both at the beginning of runs (to record who is at the run) and the end of runs (to make sure everone is back safely).\r\n\r\nThis screen also makes it possible to record who has paid and who has not.',
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
}
