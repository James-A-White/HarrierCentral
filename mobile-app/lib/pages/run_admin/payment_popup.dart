import 'package:harrier_central/imports.dart';

class PaymentPopupResult {
  PaymentPopupResult({
    required this.transactionType,
    required this.transactionValue,
    this.otherPayment,
  });

  final int transactionType;
  final double transactionValue;
  final OtherPaymentPopupResult? otherPayment;
}

class PaymentPopup extends StatefulWidget {
  const PaymentPopup({
    super.key,
    required this.hemId,
    required this.currencySymbol,
    required this.amount,
    required this.creditRemaining,
    required this.creditAllowed,
    required this.decimalDigits,
    required this.allowDefaultPricing,
  });

  final String hemId;
  final String currencySymbol;
  final double amount;
  final double creditRemaining;
  final int creditAllowed;
  final int decimalDigits;
  final bool allowDefaultPricing;

  static const int otherAmountRowId = 10;

  //final Function valueChanged;

  @override
  PaymentPopupState createState() => PaymentPopupState();
}

class PaymentPopupState extends State<PaymentPopup> {
  int _selectedValue = 1;
  OtherPaymentPopupResult? _otherPaymentResult;

  // @override
  // void initState() {

  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select payment', style: ts_alertDialogTitle),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            RadioGroup(
              groupValue: _selectedValue,
              onChanged: _handleRadioValueChange1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Radio<int>(value: 1),
                      Text('Not paid', style: ts_alertDialogBodyMedium),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Radio<int>(value: 2),
                      Text('Free run', style: ts_alertDialogBodyMedium),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Radio<int>(value: 3),
                      Text(
                        'Cash (${IveCoreUtilities.getFormattedMoney(widget.amount, widget.decimalDigits, widget.currencySymbol)})',
                        style: ts_alertDialogBodyMedium,
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Radio<int>(value: 4),
                      Text(
                        'Bank transfer (${IveCoreUtilities.getFormattedMoney(widget.amount, widget.decimalDigits, widget.currencySymbol)})',
                        style: ts_alertDialogBodyMedium,
                      ),
                    ],
                  ),
                  if (widget.creditAllowed == 0) ...<Widget>[_otherAmountRow()],
                  if (widget.creditAllowed != 0) ...<Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Radio<int>(value: 6),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Credit (${IveCoreUtilities.getFormattedMoney(widget.amount, widget.decimalDigits, widget.currencySymbol)})',
                              style: ts_alertDialogBodyMedium,
                            ),
                            Text(
                              '${IveCoreUtilities.getFormattedMoney((widget.creditRemaining).abs(), widget.decimalDigits, widget.currencySymbol)} ${(widget.creditRemaining >= 0) ? 'remaining' : 'owed'}',
                              style: ts_alertDialogBodyMedium.copyWith(
                                color: (widget.creditRemaining >= 0)
                                    ? Colors.green[800]
                                    : hc_red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                  _otherAmountRow(),
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
                  //             'Pay ${IveCoreUtilities.getFormattedMoney(widget.amount, widget.decimalDigits, widget.currencySymbol)} & top up',
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
                ],
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 1.0),
          child: SizedBox(
            //width: 100.0,
            height: 41.0,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: hc_red),
              child: Text('Cancel', style: ts_button.copyWith(fontSize: 18)),
              onPressed: () {
                final PaymentPopupResult popupResult = PaymentPopupResult(
                  transactionType: -1,
                  transactionValue: 0,
                );
                Navigator.of(context).pop(popupResult);
              },
            ),
          ),
        ),
        SizedBox(
          //width: 100.0,
          height: 41.0,
          child: ElevatedButton(
            style: TextButton.styleFrom(
              shape: button_shape,
              backgroundColor: hc_blue,
            ),
            child: Text('Process', style: ts_button.copyWith(fontSize: 18)),
            onPressed: () {
              if (_selectedValue != PaymentPopup.otherAmountRowId) {
                _otherPaymentResult = null;
              }

              final double resultAmount =
                  _otherPaymentResult?.totalAmount ?? widget.amount;
              final int resultTransType = _selectedValue;

              final PaymentPopupResult result = PaymentPopupResult(
                transactionType:
                    _otherPaymentResult?.transType ?? resultTransType,
                transactionValue: resultAmount,
                otherPayment: _otherPaymentResult,
              );
              Navigator.of(context).pop(result);
            },
          ),
        ),
      ],
    );
  }

  Widget _otherAmountRow() {
    return GestureDetector(
      onTap: () async {
        if (_selectedValue == PaymentPopup.otherAmountRowId) {
          await _handleRadioValueChange1(PaymentPopup.otherAmountRowId);
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Radio<int>(value: PaymentPopup.otherAmountRowId),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Other Amount', style: ts_alertDialogBodyMedium),
              _otherPaymentResult == null
                  ? const SizedBox(height: 1, width: 1)
                  : Text(
                      '${IveCoreUtilities.getFormattedMoney(_otherPaymentResult!.totalAmount.abs(), widget.decimalDigits, widget.currencySymbol)} ${(_otherPaymentResult!.transType == 5) ? ' cash' : ' bank transfer'}',
                      style: ts_alertDialogBodyMedium.copyWith(
                        color: (widget.creditRemaining >= 0)
                            ? Colors.green[800]
                            : hc_red,
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleRadioValueChange1(int? value) async {
    if (value != null) {
      if (value != PaymentPopup.otherAmountRowId) {
        setState(() {
          _selectedValue = value;
        });
      } else {
        final OtherPaymentPopup otherPaymentPopup = OtherPaymentPopup(
          widget.amount,
          widget.decimalDigits,
          widget.currencySymbol,
          widget.creditAllowed != 0,
          widget.allowDefaultPricing,
        );

        final OtherPaymentPopupResult? result =
            await showDialog<OtherPaymentPopupResult>(
              context: context,
              barrierDismissible: false, // user must tap button!
              builder: (BuildContext context) {
                return otherPaymentPopup;
              },
            );

        if ((result != null) && (result.action != 'cancel')) {
          setState(() {
            _otherPaymentResult = result;
            _selectedValue = value;

            if (_selectedValue != PaymentPopup.otherAmountRowId) {
              _otherPaymentResult = null;
            }

            final double resultAmount =
                _otherPaymentResult?.totalAmount ?? widget.amount;
            final int resultTransType = _selectedValue;

            final PaymentPopupResult ppResult = PaymentPopupResult(
              transactionType:
                  _otherPaymentResult?.transType ?? resultTransType,
              transactionValue: resultAmount,
              otherPayment: _otherPaymentResult,
            );
            Navigator.of(context).pop(ppResult);
          });
        } else {
          _otherPaymentResult = null;
        }
      }
    }
  }
}
