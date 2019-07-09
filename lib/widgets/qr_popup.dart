import 'dart:convert';
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

String qrMediumJson = '''
[{"quality":"M","version":1,"numeric":34,"character":20,"binary":14},
{"quality":"M","version":2,"numeric":63,"character":38,"binary":26},
{"quality":"M","version":3,"numeric":101,"character":61,"binary":42},
{"quality":"M","version":4,"numeric":149,"character":90,"binary":62},
{"quality":"M","version":5,"numeric":202,"character":122,"binary":84},
{"quality":"M","version":6,"numeric":255,"character":154,"binary":106},
{"quality":"M","version":7,"numeric":293,"character":178,"binary":122},
{"quality":"M","version":8,"numeric":365,"character":221,"binary":152},
{"quality":"M","version":9,"numeric":432,"character":262,"binary":180},
{"quality":"M","version":10,"numeric":513,"character":311,"binary":213},
{"quality":"M","version":11,"numeric":604,"character":366,"binary":251},
{"quality":"M","version":12,"numeric":691,"character":419,"binary":287},
{"quality":"M","version":13,"numeric":796,"character":483,"binary":331},
{"quality":"M","version":14,"numeric":871,"character":528,"binary":362},
{"quality":"M","version":15,"numeric":991,"character":600,"binary":412},
{"quality":"M","version":16,"numeric":1082,"character":656,"binary":450},
{"quality":"M","version":17,"numeric":1212,"character":734,"binary":504},
{"quality":"M","version":18,"numeric":1346,"character":816,"binary":560},
{"quality":"M","version":19,"numeric":1500,"character":909,"binary":624},
{"quality":"M","version":20,"numeric":1600,"character":970,"binary":666},
{"quality":"M","version":21,"numeric":1708,"character":1035,"binary":711},
{"quality":"M","version":22,"numeric":1872,"character":1134,"binary":779},
{"quality":"M","version":23,"numeric":2059,"character":1248,"binary":857},
{"quality":"M","version":24,"numeric":2188,"character":1326,"binary":911},
{"quality":"M","version":25,"numeric":2395,"character":1451,"binary":997},
{"quality":"M","version":26,"numeric":2544,"character":1542,"binary":1059},
{"quality":"M","version":27,"numeric":2701,"character":1637,"binary":1125},
{"quality":"M","version":28,"numeric":2857,"character":1732,"binary":1190},
{"quality":"M","version":29,"numeric":3035,"character":1839,"binary":1264},
{"quality":"M","version":30,"numeric":3289,"character":1994,"binary":1370},
{"quality":"M","version":31,"numeric":3486,"character":2113,"binary":1452},
{"quality":"M","version":32,"numeric":3693,"character":2238,"binary":1538},
{"quality":"M","version":33,"numeric":3909,"character":2369,"binary":1628},
{"quality":"M","version":34,"numeric":4134,"character":2506,"binary":1722},
{"quality":"M","version":35,"numeric":4343,"character":2632,"binary":1809},
{"quality":"M","version":36,"numeric":4588,"character":2780,"binary":1911},
{"quality":"M","version":37,"numeric":4775,"character":2894,"binary":1989},
{"quality":"M","version":38,"numeric":5039,"character":3054,"binary":2099},
{"quality":"M","version":39,"numeric":5313,"character":3220,"binary":2213},
{"quality":"M","version":40,"numeric":5596,"character":3391,"binary":2331}]
''';

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
    final List<dynamic> items = json.decode(qrMediumJson);
    int qrVersion = 15;

    for (int i = 0; i < items.length; i++)
    {
      final int charLength = items[i]['character'];
      if (charLength > widget.qrText.length)
      {
        qrVersion = items[i]['version'];
        break;
      }
    }

    return AlertDialog(
      title: Text(widget.dialogTitle, textAlign: TextAlign.center,),
      content:  Container(
          height: 250,
          width: 250,
          child: QrImage(backgroundColor: Colors.white, padding: const EdgeInsets.all(10.0), data: widget.qrText, version: qrVersion+2, errorCorrectionLevel: QrErrorCorrectLevel.M),
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
