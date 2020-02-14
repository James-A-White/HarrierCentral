import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fast_qr_reader_view/fast_qr_reader_view.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:harrier_central/database/common_queries.dart';
import 'package:harrier_central/pages/run_admin/run_admin_main.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/data/hc3_services/base_service.dart';
import 'package:harrier_central/pages/run_admin/payment_popup.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/data/hc3_services/payments_service.dart';

class CheckInScannerPage extends StatefulWidget {
  const CheckInScannerPage({@required this.eventAggregate});

  final RunDetailAggregate eventAggregate;

  @override
  _CheckInScannerPageState createState() => _CheckInScannerPageState();
}

bool isScanningAtRunStart = true;
final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class _CheckInScannerPageState extends State<CheckInScannerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        title: const Text(
          'Scan at start & end of Hash',
          style: TextStyle(
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
                      child: const AutoSizeText(
                        'Use this scanner to scan Hasher barcodes at the start of the run so you know who is at the Hash and at the end of the run so you can ensure that no one is lost on trail.',
                        textAlign: TextAlign.justify,
                        maxLines: 4,
                        style: TextStyle(color: Colors.white, fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, fontSize: 16.0, height: 0.8),
                      ),
                    ),
                    Positioned(
                      top: 120.0,
                      child: Container(
                        //margin: const EdgeInsets.all(20.0),
                        width: 280.0,
                        child: RaisedButton(
                            child: Text(
                              ((controller != null) && isScanningAtRunStart) ? 'Stop Scanning' : 'Scan at start of run',
                              style: const TextStyle(
                                  fontFamily: 'AvenirNextDemiBold',
                                  //color: Colors.white,
                                  fontStyle: FontStyle.normal,
                                  fontSize: 22.0,
                                  height: 1.0),
                            ),
                            disabledColor: Colors.grey[700],
                            disabledTextColor: Colors.grey[200],
                            textColor: Colors.white,
                            onPressed: ((controller != null) && !isScanningAtRunStart)
                                ? null
                                : () {
                                    isScanningAtRunStart = true;
                                    scanUserBarcode();
                                  }),
                      ),
                    ),
                    Positioned(
                        top: 190,
                        bottom: 215,
                        //width:150,
                        //height:150,
                        child: 

Container(
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
                    Positioned(
                      bottom: 140.0,
                      child: Container(
                        //margin: const EdgeInsets.all(20.0),
                        width: 280.0,
                        child: RaisedButton(
                            child: Text(
                              ((controller != null) && !isScanningAtRunStart) ? 'Stop Scanning' : 'Scan at end of run',
                              style: const TextStyle(
                                  fontFamily: 'AvenirNextDemiBold',
                                  //color: Colors.white,
                                  fontStyle: FontStyle.normal,
                                  fontSize: 22.0,
                                  height: 1.0),
                            ),
                            disabledColor: Colors.grey[700],
                            disabledTextColor: Colors.grey[200],
                            textColor: Colors.white,
                            onPressed: ((controller != null) && isScanningAtRunStart)
                                ? null
                                : () {
                                    isScanningAtRunStart = false;
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

  String onScreenMessage = 'Waiting to start scanning';

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
      setState(() => onScreenMessage = 'Scanning');
      cameras = await availableCameras();

      onNewCameraSelected(cameras[0]);
    } else {
      await stopScanning();
      setState(() => onScreenMessage = 'Waiting for scan');
    }
  }

  Future<void> onCodeRead(dynamic scanResult) async {
    _scaffoldKey.currentState?.hideCurrentSnackBar();
    final AudioCache audioPlayer = AudioCache(prefix: 'sounds/');
    audioPlayer.play('camera.mp3');

    await stopScanning();

    final Map<String, String> result = Utilities.validateScan(scanResult, Utilities.qrScanTypeFlag_user);

    if (result['validScan'] == 'false') {
      setState(() {
        onScreenMessage = result['validHcQr'] == 'true' ? 'This QR code is not valid here' : 'QR code not recignized';
      });
    } else {
      final String prefix = result['prefix'];
      final String content = result['content'];

      if (prefix != QR_PREFIX_USER_CODE) {
        // NOTE: We should never get to this point in, but set
        print('ERROR! The app should never reach this point.');
      } else {
        setState(() {
          onScreenMessage = 'Processing QR Scan';
        });
        final int attendenceState = isScanningAtRunStart ? attendenceAtHash.value : attendenceOnIn.value;

        CommonQueries.getUserIdFromUqr(prefix + content).then((String hasherId) {
          hasherEventMapService.joinEvent(widget.eventAggregate.event.eventId, TableType.hemEventAdmin, hasherId, null, rsvpState: rsvpYes.value, attendenceState: attendenceState, isHare: isHareNo.value, virginVisitorType: enumHasher.value).then((List<dynamic> adHocData) {
            setState(() {
              
              if ((adHocData != null) && (adHocData.isNotEmpty)) {
                final num amount = adHocData[0]['isMember'] == 1 ? widget.eventAggregate.extensions.memberPrice : widget.eventAggregate.extensions.nonMemberPrice;
                Utilities.showInSnackBar(context, _scaffoldKey, adHocData[0]['userMessage'], durationInSeconds: 10);
                //
                if ((adHocData[0]['isPaid'] != 0) || (amount <= 0)) {
                  scanUserBarcode();
                  // Future<void>.delayed(const Duration(seconds: 4)).then((void dummy) {
                  //   scanUserBarcode();
                  // });
                } else {
                  final PaymentPopup pp = PaymentPopup(
                    amount: amount,
                    creditAllowed: 1, // TODO(James): fix this in the DB so that Kennnels can disable credit
                    creditRemaining: 0,
                    currencySymbol: widget.eventAggregate.extensions.curSym,
                    hemId: adHocData[0]['hasherEventMapId'],
                    decimalDigits: widget.eventAggregate.extensions.digAfterDec,
                    // valueChanged: (num value) {
                    //   finalValue = value;
                    // },
                  );

                  final Future<PaymentPopupResult> dlg = showDialog<PaymentPopupResult>(
                      context: context,
                      barrierDismissible: false, // user must tap button!
                      builder: (BuildContext context) {
                        return pp;
                      });

                  dlg.then(
                    (PaymentPopupResult popupResult) {
                      if (popupResult.transactionType != -1) {
                        setState(() {
                          onScreenMessage = 'Please wait, processing payment';
                        });

                        payForEvent(adHocData[0]['hasherEventMapId'], popupResult.transactionType, popupResult.transactionValue);
                      }
                    },
                  );
                }
              } else {
                onScreenMessage = 'Processing Complete';
              }
            });
          });
        });
      }
    }

    // final ProcessQrScanService srv = ProcessQrScanService();
    // final Future<ProcessQrScanModel> apiCall = srv.processQrScan(widget.eventId, scanResult, 'CheckInOut', context2, 'admin', '');
    // apiCall.then((ProcessQrScanModel result) {
    //   setState(() => barcode = result.resultStr2);
    //   if (result.resultInt2 != 0) {
    //     Future<dynamic>.delayed(const Duration(seconds: 2)).then<dynamic>((dynamic unused) {
    //       scanUserBarcode();
    //     });
    //   } else {
    //     final PaymentPopup pp = PaymentPopup(
    //       amount: result.resultDecimal1,
    //       creditAllowed: result.resultInt3,
    //       creditRemaining: result.resultDecimal2,
    //       currencySymbol: result.resultStr1,
    //       hemId: result.resultGuid2,
    //       decimalDigits: result.resultInt4,
    //       // valueChanged: (num value) {
    //       //   ppSelectedValue = value;
    //       // },
    //     );

    //     final Future<int> dlg = showDialog<int>(
    //         context: context,
    //         barrierDismissible: false, // user must tap button!
    //         builder: (BuildContext context) {
    //           return pp;
    //         });

    //     dlg.then((int selectedTransactionType) {
    //       if (selectedTransactionType != -1) {
    //         final PayForEventService paySrv = PayForEventService();
    //         //final Future<List<PayForEventModel>> retVal = paySrv.payForEvent(result.resultGuid1, widget.eventId, result.resultGuid2, selectedTransactionType, pp.amount, widget.isRunStart == 1 ? attendenceAtHash.value : attendenceOnIn.value);
    //         final Future<List<PayForEventModel>> retVal = paySrv.payForEvent(result.resultGuid1, widget.eventId, result.resultGuid2, selectedTransactionType, pp.amount, attendenceAtHash.value);
    //         retVal.then((List<PayForEventModel> paymentResult) {
    //           if (paymentResult.isNotEmpty) {
    //             setState(() => barcode = paymentResult[0].result);
    //           } else {
    //             setState(() => barcode = 'Error processing payment');
    //           }
    //           Future<dynamic>.delayed(const Duration(seconds: 2)).then<dynamic>((dynamic unused) {
    //             scanUserBarcode();
    //           });
    //         });
    //       }
    //     });
    //   }
    // });
  }

  void payForEvent(String hemId, int paymentType, num amount) {
    final PaymentsService paySrv = PaymentsService();
    final Future<List<dynamic>> retVal = paySrv.payForEvent(
      widget.eventAggregate.event.eventId,
      GUID_EMPTY,
      hemId,
      paymentType,
      amount,
      attendenceAtHash.value,
      payForRunOnly
    );
    retVal.then(
      (List<dynamic> paymentResult) {
        if ((paymentResult != null) && (paymentResult.isNotEmpty)) {
          final int paymentType = paymentResult[0]['paymentType'];
          final String amountPaid = Utilities.getFormattedMoney(paymentResult[0]['creditAmount'], widget.eventAggregate.extensions.digAfterDec, widget.eventAggregate.extensions.curSym);

          onScreenMessage = paymentResult[0]['hasherWhoPaid'];

          if (paymentResult[0]['attendenceState'] == attendenceAtHash.value) {
            onScreenMessage += ' is checked in and';
          } else if (paymentResult[0]['attendenceState'] == attendenceOnIn.value) {
            onScreenMessage += ' is On Inn and';
          }

          switch (paymentType) {
            case 1:
              onScreenMessage += ' has not paid and needs to pay for the Hash';
              break;
            case 2:
              onScreenMessage += ' enjoyed a FREE Hash today';
              break;
            case 3:
              onScreenMessage += ' has paid $amountPaid in cash';
              break;
            case 4:
              onScreenMessage += ' has paid $amountPaid by bank transfer';
              break;
            case 5:
              onScreenMessage += ' has paid $amountPaid in cash';
              break;
            case 6:
              onScreenMessage += ' has paid $amountPaid using Hash credit';
              break;
            case 7:
              onScreenMessage += ' has paid $amountPaid by bank transfer';
              break;
            default:
              break;
          }
          setState(() {});

          Future<void>.delayed(const Duration(seconds: 4)).then((void dummy) {
            scanUserBarcode();
          });
        }
      },
    );
  }

  Future<dynamic> stopScanning() async {
    controller.stopScanning();
    await controller.dispose();
    controller = null;
  }

  // Widget _cameraPreviewWidget() {
  //   return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraint) {
  //     return Stack(children: <Widget>[
  //       Image.asset(
  //         'images/other/qr_scanner.png',
  //       ),
  //       Container(
  //         padding: const EdgeInsets.all(9.0),
  //         height: constraint.biggest.height,
  //         width: constraint.biggest.height,
  //         child: (controller == null) ? Container() : QRReaderPreview(controller),
  //       )
  //     ]);
  //   });

  //   // ;
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
          title: const Text('Hasher Scanner'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text(
                  'Harrier Central admins can use this page to scan in Hashers both at the beginning of runs (to record who is at the run) and the end of runs (to make sure everone is back safely).\r\n\r\nThis screen also makes it possible to record who has paid and who has not.',
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
}
