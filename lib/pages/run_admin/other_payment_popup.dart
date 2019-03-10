import 'dart:core';

import 'package:flutter/material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:harrier_central/util/enums.dart';

class OtherPaymentPopup extends StatefulWidget {
  final String currencySymbol;

  OtherPaymentPopup({@required this.currencySymbol});

  _OtherPaymentPopupState createState() => _OtherPaymentPopupState();
}

class _OtherPaymentPopupState extends State<OtherPaymentPopup> {
  final FocusNode myFocusNodeFirstName = FocusNode();
  TextEditingController otherPaymentAmountTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select payment amount'),
      content: TextField(
        autofocus: true,
        focusNode: myFocusNodeFirstName,
        controller: otherPaymentAmountTextController,
        keyboardType: TextInputType.number,
        style: const TextStyle(
            fontFamily: 'WorkSansSemiBold',
            fontSize: 16.0,
            color: Colors.white),
        decoration: const InputDecoration(
          border: InputBorder.none,
          icon: Icon(
            FontAwesomeIcons.moneyBillWave,
            color: Colors.white,
          ),
          hintText: 'Other amount',
          hintStyle: TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
        ),
      ),
      actions: <Widget>[
        // Padding(
        //   padding: EdgeInsets.only(right: 0.0),
        //   child: Container(
        //     width: 60.0,
        //     child:

        FlatButton(
          color: Colors.red,
          child: Text("Cancel"),
          textColor: Colors.white,
          onPressed: () {
            Navigator.of(context)
                .pop(<String, String>{'type': 'cancel', 'amount': ''});
          },
        ),
        //   ),
        // ),
        // Container(
        //   width: 60.0,
        //child:

        FlatButton(
            color: Colors.blue,
            child: Text("Cash"),
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).pop(<String, String>{
                'type': paymentCashOtherAmount.value.toString(),
                'amount': otherPaymentAmountTextController.text
              });
            }),
        // ),
        // Container(
        //   width: 60.0,
        //child:

        FlatButton(
          color: Colors.blue,
          child: Text("Bank transfer"),
          textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).pop(<String, String>{
                'type': paymentBankTransferOtherAmount.value.toString(),
                'amount': otherPaymentAmountTextController.text
              });
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
