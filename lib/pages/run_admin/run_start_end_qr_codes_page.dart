import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:qr_flutter/qr_flutter.dart';

class RunStartEndQrCodes extends StatelessWidget {
  RunStartEndQrCodes(
      {
      @required this.kennelShortName,
      @required this.eventId,
      @required this.eventName,
      @required this.eventNumber,
      @required this.eventStartDatetime,
      @required this.isStart});

  String kennelShortName;
  String eventId;
  String eventName;
  int eventNumber;
  DateTime eventStartDatetime;
  bool isStart;

  @override
  Widget build(BuildContext context) {
    
    String qrData = (isStart ? 'EVTSTART:' : 'EVTEND:') + eventId.toUpperCase();

    String startEndString = isStart ? 'Start' : 'End';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          'Run $startEndString QR Code',
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
              '$kennelShortName #$eventNumber - $startEndString',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'AvenirNextDemiBold',
                  fontStyle: FontStyle.normal,
                  fontSize: 24.0,
                  height: 1.0),
            ),
            Text(
              eventName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'AvenirNextRegular',
                  fontStyle: FontStyle.normal,
                  fontSize: 28.0,
                  height: 1.0),
            ),
            Text(
              DateFormat("E, MMM d 'at' h:mm a").format(eventStartDatetime),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'AvenirNextRegular',
                  fontStyle: FontStyle.normal,
                  fontSize: 20.0,
                  height: 1.0),
            ),
            QrImage(
                padding: EdgeInsets.all(10.0),
                data: qrData,
                version: 4,
                size: 200.0,
                errorCorrectionLevel: 3),
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

  Future<bool> _displayInstructions(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Instructions on using run QR codes'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  isStart ?
                  'Use this code to allow Hashers to scan themselves in at the START of this run. This QR code only works for THIS RUN. You can print it or take a screenshot and send it to someone who does not have admin privileges. Harrier Central users can then scan the code to check themselves in at the run.' :
                  'Use this code to allow Hashers to scan themselves in at the END of this run. This way, you can keep track of who is still out on trail and make sure everyone makes it back safe and sound.',
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
