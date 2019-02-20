import 'dart:async';

//import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';

import 'package:harrier_central/remote_api_data/process_qr_scan_service.dart';
import 'package:harrier_central/data_models/process_qr_scan_model.dart';
import 'package:harrier_central/pages/run_admin/payment_popup.dart';
import 'package:harrier_central/remote_api_data/pay_for_event_service.dart';
import 'package:harrier_central/data_models/pay_for_event_model.dart';
import 'package:harrier_central/util/enums.dart';

class CheckInScannerPage extends StatefulWidget {
  CheckInScannerPage(
      {@required this.kennelShortName,
      @required this.eventId,
      @required this.eventName,
      @required this.eventNumber});

  String kennelShortName;
  String eventId;
  String eventName;
  int eventNumber;

  _CheckInScannerPageState createState() => _CheckInScannerPageState();
}

class _CheckInScannerPageState extends State<CheckInScannerPage> {
  
  
  String barcode = '';

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          'Check in Scanner',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Text(
              '${widget.kennelShortName} #${widget.eventNumber}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'AvenirNextDemiBold',
                  fontStyle: FontStyle.normal,
                  fontSize: 24.0,
                  height: 1.0),
            ),
            Text(
              widget.eventName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'AvenirNextRegular',
                  fontStyle: FontStyle.normal,
                  fontSize: 28.0,
                  height: 1.0),
            ),
            new Center(
              child: new Column(
                children: <Widget>[
                  Container(
                    width: 320.0,
                    child: RaisedButton(
                        child: const Text(
                          'Start Scanning: RUN START',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          scanUserBarcode(true, widget.eventId);
                        }),
                  ),

                  Container(
                    padding: EdgeInsets.only(top: 30.0),
                    width: 320.0,
                    child: RaisedButton(
                        child: const Text(
                          'Start Scanning: RUN END',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          scanUserBarcode(false, widget.eventId);
                        }),
                  ),

                  // new Container(
                  //   child: new MaterialButton(
                  //       onPressed: scan, child: new Text("Scan")),
                  //   padding: const EdgeInsets.all(8.0),
                  // ),
                  Padding(
                    padding:
                        EdgeInsets.only(left: 24.0, right: 24.0, top: 35.0),
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
      ),
    );
  }

  Future<void> scanUserBarcode(bool isRunStart, String eventId) async {
    String context2 = isRunStart ? '0' : '1';
    // Future<String> scanAction = BarcodeScanner.scan();
    // scanAction.then((String s) {
    //   ProcessQrScanService srv = ProcessQrScanService();
    //   Future<ProcessQrScanModel> apiCall =
    //       srv.processQrScan(eventId, s, 'CheckInOut', context2, 'user', '');
    //   apiCall.then((ProcessQrScanModel result) {
    //     setState(() => barcode = result.resultStr2);
    //     if (result.resultInt2 == 0) {
    //       PaymentPopup pp = new PaymentPopup(
    //         amount: result.resultDecimal1,
    //         creditAllowed: result.resultInt3,
    //         creditRemaining: result.resultDecimal2,
    //         currencySymbol: result.resultStr1,
    //         hemId: result.resultGuid2,
    //         decimalDigits: result.resultInt4,
    //       );

    //       Future<bool> dlg = showDialog<bool>(
    //           context: context,
    //           barrierDismissible: false, // user must tap button!
    //           builder: (BuildContext context) {
    //             return pp;
    //           });

    //       dlg.then((bool x) {
    //         PayForEventService paySrv = PayForEventService();
    //         Future<List<PayForEventModel>> retVal = paySrv.payForEvent(
    //             result.resultGuid1,
    //             eventId,
    //             result.resultGuid2,
    //             pp.selectedValue,
    //             pp.amount,
    //             isRunStart == 1 ? attendenceAtHash.value : attendenceOnIn.value);
    //         retVal.then((List<PayForEventModel> paymentResult) {
    //           if (paymentResult.isNotEmpty) {
    //             setState(() => barcode = paymentResult[0].result);
    //           } else {
    //             setState(() => barcode = 'Error processing payment');
    //           }
    //         });
    //       });
    //     }
    //   });
    //   setState(() => barcode = "Processing QR Scan");
    // });
 
 
  }

  Future<bool> _displayInstructions(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hasher Scanner'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Harrier Central admins can use this page to scan in Hashers both at the beginning of runs (to record who is at the run) and the end of runs (to make sure everone is back safely).\r\n\r\nThis screen also makes it possible to record who has paid and who has not.',
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
