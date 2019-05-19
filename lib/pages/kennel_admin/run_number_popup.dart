import 'dart:core';

import 'package:flutter/material.dart';

import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class RunNumberPopup extends StatefulWidget {
  const RunNumberPopup({@required this.runNumber});

  final int runNumber;

  @override
  _RunNumberPopupState createState() => _RunNumberPopupState();
}

class _RunNumberPopupState extends State<RunNumberPopup> {
  final FocusNode myFocusNodeFirstName = FocusNode();
  TextEditingController runNumberAmountTextController;

  @override
  void initState() {
    runNumberAmountTextController = TextEditingController(text: widget.runNumber == null ? '' : widget.runNumber.toString());

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set run number'),
      content: TextField(
        autofocus: true,
        focusNode: myFocusNodeFirstName,
        controller: runNumberAmountTextController,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
        decoration: const InputDecoration(
          border: InputBorder.none,
          icon: Icon(
            FontAwesome.money,
            color: Colors.white,
          ),
          hintText: 'Enter run number',
          hintStyle: TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
        ),
      ),
      actions: <Widget>[
        // Padding(
        //   padding: const EdgeInsets.only(right: 0.0),
        //   child: Container(
        //     width: 60.0,
        //     child:

        FlatButton(
          color: Colors.red,
          child: const Text('Cancel'),
          textColor: Colors.white,
          onPressed: () {
            Navigator.of(context).pop(<String, String>{'runNumber': 'cancel'});
          },
        ),
        //   ),
        // ),
        // Container(
        //   width: 60.0,
        //child:

        FlatButton(
            color: Colors.blue,
            child: const Text('Auto number'),
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).pop(<String, String>{'runNumber': 'auto'});
            }),
        // ),
        // Container(
        //   width: 60.0,
        //child:

        FlatButton(
            color: Colors.blue,
            child: const Text('OK'),
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).pop(<String, String>{'runNumber': runNumberAmountTextController.text});
            }),
        // ),
      ],
    );

    //     Image.network(kennel.kennelLogo,
    //         fit: BoxFit.fitHeight, height: logoHeight),
    // alignment: Alignment.centerRight);
  }

  // void _handleRadioValueChange1(int value) {
  //   setState(() {
  //     //widget.selectedValue = value;

  //     // switch (_radioValue1) {
  //     //   case 0:
  //     //     Fluttertoast.showToast(msg: 'Correct !',toastLength: Toast.LENGTH_SHORT);
  //     //     correctScore++;
  //     //     break;
  //     //   case 1:
  //     //     Fluttertoast.showToast(msg: 'Try again !',toastLength: Toast.LENGTH_SHORT);
  //     //     break;
  //     //   case 2:
  //     //     Fluttertoast.showToast(msg: 'Try again !',toastLength: Toast.LENGTH_SHORT);
  //     //     break;
  //     //}
  //   });
  // }
}
