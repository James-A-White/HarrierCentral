import 'dart:core';

import 'package:flutter/material.dart';

import 'package:harrier_central/util/utilities.dart';

class PaymentPopup extends StatefulWidget {
   const PaymentPopup(
      {@required this.hemId,
      @required this.currencySymbol,
      @required this.amount,
      @required this.creditRemaining,
      @required this.creditAllowed,
      @required this.decimalDigits,
      @required this.valueChanged});

  final String hemId;
  final String currencySymbol;
  final num amount;
  final num creditRemaining;
  final int creditAllowed;
  final int decimalDigits;

  final Function valueChanged;

  @override
  _PaymentPopupState createState() => _PaymentPopupState();
}

class _PaymentPopupState extends State<PaymentPopup> {

  int selectedValue = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select payment method'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Row(children: <Widget>[
                  Radio<int>(
                    value: 1,
                    groupValue: selectedValue,
                    onChanged: _handleRadioValueChange1,
                  ),
                  const Text(
                    'Not paid',
                    style: TextStyle(fontSize: 16.0),
                  ),
                ]),
                Row(children: <Widget>[
                  Radio<int>(
                    value: 2,
                    groupValue: selectedValue,
                    onChanged: _handleRadioValueChange1,
                  ),
                  const Text(
                    'Free run',
                    style: TextStyle(fontSize: 16.0),
                  ),
                ]),
                Row(children: <Widget>[
                  Radio<int>(
                    value: 3,
                    groupValue: selectedValue,
                    onChanged: _handleRadioValueChange1,
                  ),
                  Text(
                    'Cash (${Utilities.getFormattedMoney(widget.amount, widget.decimalDigits, widget.currencySymbol)})',
                    style: const TextStyle(fontSize: 16.0),
                  ),
                ]),
                Row(children: <Widget>[
                  Radio<int>(
                    value: 4,
                    groupValue: selectedValue,
                    onChanged: _handleRadioValueChange1,
                  ),
                  Text(
                    'Bank transfer (${Utilities.getFormattedMoney(widget.amount, widget.decimalDigits, widget.currencySymbol)})',
                    style: const TextStyle(fontSize: 16.0),
                  ),
                ]),
              ]..addAll((widget.creditAllowed == 0)
                  ? List<Widget>.from(<Widget>[])
                  : List<Widget>.from(<Widget>[
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Radio<int>(
                              value: 6,
                              groupValue: selectedValue,
                              onChanged: _handleRadioValueChange1,
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Credit (${Utilities.getFormattedMoney(widget.amount, widget.decimalDigits, widget.currencySymbol)})',
                                  style: const TextStyle(fontSize: 16.0),
                                ),
                                Text(
                                  '${Utilities.getFormattedMoney((widget.creditRemaining).abs(), widget.decimalDigits, widget.currencySymbol)} ' +
                                      ((widget.creditRemaining >= 0)
                                          ? 'remaining'
                                          : 'owed'),
                                  style: TextStyle(
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
                      //       Radio<int>(
                      //         value: 5,
                      //         groupValue: selectedValue,
                      //         onChanged: _handleRadioValueChange1,
                      //       ),
                      //       Column(
                      //         mainAxisAlignment: MainAxisAlignment.start,
                      //         crossAxisAlignment: CrossAxisAlignment.start,
                      //         children: <Widget>[
                      //           Text(
                      //             'Pay ${Utilities.getFormattedMoney(widget.amount, widget.decimalDigits, widget.currencySymbol)} & top up',
                      //             style: const TextStyle(fontSize: 16.0),
                      //           ),

                      //           //         TextField(

                      //           //   keyboardType: TextInputType.number,
                      //           //   style: const TextStyle(
                      //           //       fontFamily: 'WorkSansSemiBold',
                      //           //       fontSize: 16.0,
                      //           //       color: Colors.black),
                      //           //   decoration: const InputDecoration(
                      //           //     border: InputBorder.none,
                      //           //     icon:const  Icon(
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
          padding: const EdgeInsets.only(right: 60.0),
          child: Container(
            width: 100.0,
            child: RaisedButton(
              color: Colors.red,
              child: const Text('Cancel'),
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
            child: const Text('Process'),
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ),
      ],
    );
  }

  void _handleRadioValueChange1(int value) {
    setState(() {
      widget.valueChanged(selectedValue: value);
      //selectedValue = value;
    });
  }
}
