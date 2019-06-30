import 'dart:core';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrPopup extends StatefulWidget {
  const QrPopup({
    @required this.dialogTitle,
    @required this.qrText,
    // @required this.valueChanged
  });

  final String dialogTitle;
  final String qrText;

  @override
  _QrPopupState createState() => _QrPopupState();
}

class _QrPopupState extends State<QrPopup> {
  int selectedValue = 1;
  num otherAmount;
  int otherTransType;

  // @override
  // void initState() {

  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.dialogTitle),
      content:  Container(
          height: 250,
          width: 250,
          child: QrImage(backgroundColor: Colors.white, padding: const EdgeInsets.all(10.0), data: widget.qrText, version: 7, errorCorrectionLevel: 3),
        ),
      
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 0.0),
          child: Container(
            width: 100.0,
            child: RaisedButton(
              color: Colors.red,
              child: const Text('Done'),
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ],
    );
  }
}
