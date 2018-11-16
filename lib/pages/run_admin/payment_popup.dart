import 'dart:math';
import 'dart:core';
import 'package:flutter/material.dart';

import 'package:harrier_central/util/utilities.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class PaymentPopup extends StatefulWidget {
  final String hemId;
  final String currencySymbol;
  final double amount;
  final double creditRemaining;
  final int creditAllowed;
  final int decimalDigits;

  PaymentPopup(
      {@required this.hemId,
      @required this.currencySymbol,
      @required this.amount,
      @required this.creditRemaining,
      @required this.creditAllowed,
      @required this.decimalDigits});

  int selectedValue = -1;

  _PaymentPopupState createState() => _PaymentPopupState();
}

class _PaymentPopupState extends State<PaymentPopup> {

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select payment method'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            new Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Row(children: <Widget>[
                  new Radio<int>(
                    value: 1,
                    groupValue: widget.selectedValue,
                    onChanged: _handleRadioValueChange1,
                  ),
                  new Text(
                    'Not paid',
                    style: new TextStyle(fontSize: 16.0),
                  ),
                ]),
                Row(children: <Widget>[
                  new Radio<int>(
                    value: 2,
                    groupValue: widget.selectedValue,
                    onChanged: _handleRadioValueChange1,
                  ),
                  new Text(
                    'Free run',
                    style: new TextStyle(fontSize: 16.0),
                  ),
                ]),
                Row(children: <Widget>[
                  new Radio<int>(
                    value: 3,
                    groupValue: widget.selectedValue,
                    onChanged: _handleRadioValueChange1,
                  ),
                  new Text(
                    'Cash (${Utilities.getFormattedMoney(widget.amount, widget.decimalDigits, widget.currencySymbol)})',
                    style: new TextStyle(fontSize: 16.0),
                  ),
                ]),
                Row(children: <Widget>[
                  new Radio<int>(
                    value: 4,
                    groupValue: widget.selectedValue,
                    onChanged: _handleRadioValueChange1,
                  ),
                  new Text(
                    'Bank transfer (${Utilities.getFormattedMoney(widget.amount, widget.decimalDigits, widget.currencySymbol)})',
                    style: new TextStyle(fontSize: 16.0),
                  ),
                ]),
              ]..addAll((widget.creditAllowed == 0)
                  ? List<Widget>.from(<Widget>[])
                  : List<Widget>.from(<Widget>[
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            new Radio<int>(
                              value: 6,
                              groupValue: widget.selectedValue,
                              onChanged: _handleRadioValueChange1,
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                new Text(
                                  'Credit (${Utilities.getFormattedMoney(widget.amount, widget.decimalDigits, widget.currencySymbol)})',
                                  style: new TextStyle(fontSize: 16.0),
                                ),
                                new Text(
                                  '${Utilities.getFormattedMoney((widget.creditRemaining).abs(), widget.decimalDigits, widget.currencySymbol)} ' +
                                      ((widget.creditRemaining >= 0)
                                          ? 'remaining'
                                          : 'owed'),
                                  style: new TextStyle(
                                      fontSize: 16.0,
                                      color: (widget.creditRemaining >= 0)
                                          ? Colors.green[800]
                                          : Colors.red[800]),
                                ),
                              ],
                            ),
                          ]),
                      // Row(
                      //     //crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: <Widget>[
                      //       new Radio<int>(
                      //         value: 5,
                      //         groupValue: widget.selectedValue,
                      //         onChanged: _handleRadioValueChange1,
                      //       ),
                      //       Column(
                      //         mainAxisAlignment: MainAxisAlignment.start,
                      //         crossAxisAlignment: CrossAxisAlignment.start,
                      //         children: <Widget>[
                      //           new Text(
                      //             'Pay ${Utilities.getFormattedMoney(widget.amount, widget.decimalDigits, widget.currencySymbol)} & top up',
                      //             style: new TextStyle(fontSize: 16.0),
                      //           ),

                      //           //         TextField(

                      //           //   keyboardType: TextInputType.number,
                      //           //   style: const TextStyle(
                      //           //       fontFamily: 'WorkSansSemiBold',
                      //           //       fontSize: 16.0,
                      //           //       color: Colors.black),
                      //           //   decoration: const InputDecoration(
                      //           //     border: InputBorder.none,
                      //           //     icon: Icon(
                      //           //       FontAwesomeIcons.moneyBill,
                      //           //       color: Colors.black,
                      //           //     ),
                      //           //     hintText: 'Amount',
                      //           //     hintStyle: TextStyle(
                      //           //         fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                      //           //   ),
                      //           // ),
                      //         ],
                      //       ),
                      //     ]),
                    ])),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        Padding(
          padding: EdgeInsets.only(right: 60.0),
          child: Container(
            width: 100.0,
            child: RaisedButton(
              color: Colors.red,
              child: Text("Cancel"),
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ),
        ),
        Container(
          width: 100.0,
          child: RaisedButton(
            child: Text("Process"),
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ),
      ],
    );

    //     Image.network(kennel.kennelLogo,
    //         fit: BoxFit.fitHeight, height: logoHeight),
    // alignment: Alignment.centerRight);
  }

  void _handleRadioValueChange1(int value) {
    setState(() {
      widget.selectedValue = value;

      // switch (_radioValue1) {
      //   case 0:
      //     Fluttertoast.showToast(msg: 'Correct !',toastLength: Toast.LENGTH_SHORT);
      //     correctScore++;
      //     break;
      //   case 1:
      //     Fluttertoast.showToast(msg: 'Try again !',toastLength: Toast.LENGTH_SHORT);
      //     break;
      //   case 2:
      //     Fluttertoast.showToast(msg: 'Try again !',toastLength: Toast.LENGTH_SHORT);
      //     break;
      //}
    });
  }
}
