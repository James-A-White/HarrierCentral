import 'dart:core';

import 'package:flutter/material.dart';

import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/pages/run_admin/other_payment_popup.dart';


class PaymentPopupResult{

  PaymentPopupResult({this.transactionType,this.transactionValue});

  final int transactionType;
  final num transactionValue;
}

class PaymentPopup extends StatefulWidget {
  const PaymentPopup({@required this.hemId, @required this.currencySymbol, @required this.amount, @required this.creditRemaining, @required this.creditAllowed, @required this.decimalDigits
      // @required this.valueChanged
      });

  final String hemId;
  final String currencySymbol;
  final num amount;
  final num creditRemaining;
  final int creditAllowed;
  final int decimalDigits;

  static const int otherAmountRowId = 10;

  //final Function valueChanged;

  @override
  _PaymentPopupState createState() => _PaymentPopupState();
}

class _PaymentPopupState extends State<PaymentPopup> {
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
                  ? List<Widget>.from(<Widget>[otherAmountRow()])
                  : List<Widget>.from(<Widget>[
                      Row(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
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
                              '${Utilities.getFormattedMoney((widget.creditRemaining).abs(), widget.decimalDigits, widget.currencySymbol)} ' + ((widget.creditRemaining >= 0) ? 'remaining' : 'owed'),
                              style: TextStyle(fontSize: 16.0, color: (widget.creditRemaining >= 0) ? Colors.green[800] : Colors.red[800]),
                            ),
                          ],
                        ),
                      ]),
                      otherAmountRow()
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
                final PaymentPopupResult popupResult = PaymentPopupResult(transactionType: -1, transactionValue: 0);
                Navigator.of(context).pop(popupResult);
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
              num resultAmount = widget.amount;
              int resultTransType = selectedValue;
              if (selectedValue == PaymentPopup.otherAmountRowId)
              {
                resultAmount = otherAmount;
                resultTransType = otherTransType;
              }

              final PaymentPopupResult result = PaymentPopupResult(transactionType: resultTransType, transactionValue: resultAmount);
              Navigator.of(context).pop(result);
            },
          ),
        ),
      ],
    );
  }

  Widget otherAmountRow() {
    return GestureDetector(
      onTap: () {
        if (selectedValue == PaymentPopup.otherAmountRowId) {
          _handleRadioValueChange1(PaymentPopup.otherAmountRowId);
        }
      },
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
        Radio<int>(
          value: PaymentPopup.otherAmountRowId,
          groupValue: selectedValue,
          onChanged: _handleRadioValueChange1,
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Other Amount',
              style: TextStyle(fontSize: 16.0),
            ),
            otherTransType == null
                ? Container(height:1, width:1)
                : Text(
                    '${Utilities.getFormattedMoney(otherAmount.abs(), widget.decimalDigits, widget.currencySymbol)} ' + ((otherTransType == 5) ? ' cash' : ' bank transfer'),
                    style: TextStyle(fontSize: 16.0, color: (widget.creditRemaining >= 0) ? Colors.green[800] : Colors.red[800]),
                  ),
          ],
        ),
      ]),
    );
  }

  void _handleRadioValueChange1(int value) {
    if (value != PaymentPopup.otherAmountRowId) {
      setState(() {
        selectedValue = value;
      });
    } else {
      const OtherPaymentPopup otherPaymentPopup = OtherPaymentPopup();

      final Future<Map<String, String>> dlg = showDialog<Map<String, String>>(
          context: context,
          barrierDismissible: false, // user must tap button!
          builder: (BuildContext context) {
            return otherPaymentPopup;
          });

      dlg.then((Map<String, String> x) {
        final String amount = x['amount'];
        final String type = x['type'];

        if (type != 'cancel') {
          final num amountNumeric = num.tryParse(amount);
          final int typeNumeric = int.tryParse(type);

          if ((amountNumeric != null) && (typeNumeric != null)) {
            otherTransType = typeNumeric;
            otherAmount = amountNumeric;

            setState(() {
              selectedValue = value;
            });
          }
        }
      });
    }
  }
}
