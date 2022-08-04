// @dart=2.11
import 'package:harrier_central/imports.dart';

class OtherPaymentPopupResult {
  OtherPaymentPopupResult(
    this.action,
    this.transType,
    this.specialPriceAmount,
    this.specialPriceReason,
    this.topUpAmount,
    this.totalAmount,
    this.useSpecialPriceAsDefault,
  );

  final String action;
  final int transType;
  final double specialPriceAmount;
  final String specialPriceReason;
  final double topUpAmount;
  final double totalAmount;
  final bool useSpecialPriceAsDefault;
}

class OtherPaymentPopup extends StatefulWidget {
  const OtherPaymentPopup(this.normalPrice, this.decimalDigits, this.currencySymbol, this.showCreditTopup, this.allowDefaultPricing, {Key key}) : super(key: key);

  final num normalPrice;
  final int decimalDigits;
  final String currencySymbol;
  final bool showCreditTopup;
  final bool allowDefaultPricing;

  @override
  _OtherPaymentPopupState createState() => _OtherPaymentPopupState();
}

class _OtherPaymentPopupState extends State<OtherPaymentPopup> {
  final FocusNode _specialPriceFocusNode = FocusNode();
  final TextEditingController _specialPriceTextController = TextEditingController();

  final FocusNode _specialPriceReasonFocusNode = FocusNode();
  final TextEditingController _specialPriceReasonTextController = TextEditingController();

  final FocusNode _topUpFocusNode = FocusNode();
  final TextEditingController _topUpTextController = TextEditingController();

  bool _topUpCreditEnabled = false;
  bool _specialPriceEnabled = false;
  bool _paySpecialPriceWithCredit = false;
  bool _specialPriceIsDefaultForUser = false;

  @override
  void initState() {
    _specialPriceTextController.value = TextEditingValue(text: widget.normalPrice.toStringAsFixed(widget.decimalDigits));
    _specialPriceTextController.addListener(() {
      _recalculateTotal();
    });
    _topUpTextController.addListener(() {
      _recalculateTotal();
    });
    _recalculateTotal();
    super.initState();
  }

  double _totalDue = 0;

  void _recalculateTotal() {
    setState(() {
      if (_specialPriceEnabled) {
        _totalDue = double.tryParse(_specialPriceTextController.value.text.replaceAll(',', '.')) ?? 0;
      } else {
        _totalDue = widget.normalPrice;
      }

      if (_topUpCreditEnabled) {
        _totalDue += double.tryParse(_topUpTextController.value.text.replaceAll(',', '.')) ?? 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Other payment options'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Stack(
            children: <Widget>[
              //const SizedBox(height: 10.0, width: 10),
              Container(
                margin: const EdgeInsets.only(top: 23.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: Colors.white,
                  border: Border.all(
                    color: _specialPriceEnabled ? Colors.red.shade900 : Colors.grey.shade300,
                    width: 2, //                   <--- border width here
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 20.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: Text('If you want to offer a Hasher a special price for this run, enter that amount here. You can also enter an optional note why you offered this price.',
                          style: TextStyle(color: _specialPriceEnabled ? Colors.black : Colors.grey.shade500)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: TextField(
                        autofocus: true,
                        enabled: _specialPriceEnabled,
                        focusNode: _specialPriceFocusNode,
                        controller: _specialPriceTextController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(fontFamily: 'AvenirNextDemiBold', fontSize: 20.0, color: _specialPriceEnabled ? Colors.grey.shade700 : Colors.grey.shade300),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          // icon: Icon(
                          //   FontAwesome.money,
                          //   color: Colors.white,
                          // ),
                          hintText: 'Enter special price',
                          hintStyle: TextStyle(fontFamily: 'AvenirNextDemiBold', fontSize: 20.0, color: _specialPriceEnabled ? Colors.grey.shade500 : Colors.grey.shade300),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: TextField(
                        autofocus: true,
                        autocorrect: false,
                        enabled: _specialPriceEnabled,
                        focusNode: _specialPriceReasonFocusNode,
                        controller: _specialPriceReasonTextController,
                        keyboardType: TextInputType.text,
                        style: TextStyle(fontFamily: 'AvenirNextDemiBold', fontSize: 20.0, color: _specialPriceEnabled ? Colors.grey.shade700 : Colors.grey.shade300),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          // icon: Icon(
                          //   FontAwesome.money,
                          //   color: Colors.white,
                          // ),
                          hintText: 'Enter reason',
                          hintStyle: TextStyle(fontFamily: 'AvenirNextDemiBold', fontSize: 20.0, color: _specialPriceEnabled ? Colors.grey.shade500 : Colors.grey.shade300),
                        ),
                      ),
                    ),
                    if (widget.showCreditTopup)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Theme(
                              data: ThemeData(
                                //primarySwatch: Colors.blue,
                                unselectedWidgetColor: _specialPriceEnabled ? Colors.red.shade900 : Colors.grey.shade100, // Your color
                              ),
                              child: Checkbox(
                                fillColor: MaterialStateProperty.resolveWith<Color>(
                                  (Set<MaterialState> states) {
                                    if (states.contains(MaterialState.disabled)) {
                                      return Colors.grey.shade300;
                                    }
                                    return Colors.red.shade900;
                                  },
                                ),
                                onChanged: _specialPriceEnabled
                                    ? (bool val) {
                                        setState(() {
                                          _paySpecialPriceWithCredit = !_paySpecialPriceWithCredit;
                                          if (_topUpCreditEnabled && _paySpecialPriceWithCredit) {
                                            _topUpCreditEnabled = false;
                                          }
                                        });
                                      }
                                    : null,
                                value: _paySpecialPriceWithCredit,
                              ),
                            ),
                            Text('Pay with Hash Credit', style: TextStyle(color: _specialPriceEnabled ? Colors.black : Colors.grey.shade300)),
                            const SizedBox(width: 10.0),
                          ],
                        ),
                      ),
                    if (widget.allowDefaultPricing) ...<Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Theme(
                              data: ThemeData(
                                //primarySwatch: Colors.blue,
                                unselectedWidgetColor: _specialPriceEnabled ? Colors.red.shade900 : Colors.grey.shade100, // Your color
                              ),
                              child: Checkbox(
                                fillColor: MaterialStateProperty.resolveWith<Color>(
                                  (Set<MaterialState> states) {
                                    if (states.contains(MaterialState.disabled)) {
                                      return Colors.grey.shade300;
                                    }
                                    return Colors.red.shade900;
                                  },
                                ),
                                onChanged: _specialPriceEnabled
                                    ? (bool val) {
                                        setState(() {
                                          _specialPriceIsDefaultForUser = !_specialPriceIsDefaultForUser;
                                        });
                                      }
                                    : null,
                                value: _specialPriceIsDefaultForUser,
                              ),
                            ),
                            Text('Set for future runs', style: TextStyle(color: _specialPriceEnabled ? Colors.black : Colors.grey.shade300)),
                            const SizedBox(width: 10.0),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 13,
                child: Container(
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Checkbox(
                        fillColor: MaterialStateProperty.all<Color>(Colors.red.shade900),
                        onChanged: (bool val) {
                          setState(() {
                            _recalculateTotal();
                            _specialPriceEnabled = !_specialPriceEnabled;
                            if (!_specialPriceEnabled) {
                              _specialPriceTextController.value = TextEditingValue(text: widget.normalPrice.toStringAsFixed(widget.decimalDigits));
                            }
                          });
                        },
                        value: _specialPriceEnabled,
                      ),
                      const Text('Special run price'),
                      const SizedBox(width: 10.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (widget.showCreditTopup) ...<Widget>[
            const SizedBox(height: 13.0),
            const Divider(
              thickness: 1.0,
            ),
            Stack(
              children: <Widget>[
                const SizedBox(height: 170.0, width: 10),
                Container(
                  margin: const EdgeInsets.only(top: 23.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: Colors.white,
                    border: Border.all(
                      color: _topUpCreditEnabled ? Colors.red.shade900 : Colors.grey.shade300,
                      width: 2, //                   <--- border width here
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 20.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child:
                            Text('Enter an additional amount of money here to add to a Hasher\'s credit balance.', style: TextStyle(color: _topUpCreditEnabled ? Colors.black : Colors.grey.shade500)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: TextField(
                          autofocus: true,
                          enabled: _topUpCreditEnabled,
                          focusNode: _topUpFocusNode,
                          controller: _topUpTextController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(fontFamily: 'AvenirNextDemiBold', fontSize: 20.0, color: _topUpCreditEnabled ? Colors.grey.shade700 : Colors.grey.shade300),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            // icon: Icon(
                            //   FontAwesome.money,
                            //   color: Colors.white,
                            // ),
                            hintText: 'Enter top up amount',
                            hintStyle: TextStyle(fontFamily: 'AvenirNextDemiBold', fontSize: 20.0, color: _topUpCreditEnabled ? Colors.grey.shade500 : Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 13,
                  child: Container(
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Checkbox(
                          fillColor: MaterialStateProperty.all<Color>(Colors.red.shade900),
                          onChanged: (bool val) {
                            _recalculateTotal();
                            setState(() {
                              _topUpCreditEnabled = !_topUpCreditEnabled;
                              if (_paySpecialPriceWithCredit && _topUpCreditEnabled) {
                                _paySpecialPriceWithCredit = false;
                              }
                            });
                          },
                          value: _topUpCreditEnabled,
                        ),
                        const Text('Top up credit'),
                        const SizedBox(width: 10.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Text('Total due: ${IveCoreUtilities.getFormattedMoney(_totalDue, widget.decimalDigits, widget.currencySymbol)}',
                style: TextStyle(fontFamily: 'AvenirNextDemiBold', fontSize: 24.0, color: Colors.grey.shade700)),
          ),
        ]),
      ),
      actions: <Widget>[
        // Padding(
        //   padding: const EdgeInsets.only(right: 0.0),
        //   child: Container(
        //     width: 60.0,
        //     child:

        TextButton(
          style: TextButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop(OtherPaymentPopupResult('cancel', -1, null, null, null, null, _specialPriceIsDefaultForUser));
          },
        ),
        //   ),
        // ),
        // Container(
        //   width: 60.0,
        //child:

        if (!_paySpecialPriceWithCredit) ...<Widget>[
          TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Cash'),
              onPressed: () {
                final OtherPaymentPopupResult result = OtherPaymentPopupResult(
                  'process',
                  paymentCashOtherAmount.value,
                  _specialPriceEnabled ? double.tryParse(_specialPriceTextController.text.replaceAll(',', '.')) : null,
                  _specialPriceEnabled ? _specialPriceReasonTextController.text : null,
                  _topUpCreditEnabled ? double.tryParse(_topUpTextController.text.replaceAll(',', '.')) : null,
                  _totalDue,
                  _specialPriceIsDefaultForUser,
                );

                Navigator.of(context).pop(result);
              }),
          // ),
          // Container(
          //   width: 60.0,
          //child:

          TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Bank transfer'),
              onPressed: () {
                final OtherPaymentPopupResult result = OtherPaymentPopupResult(
                  'process',
                  paymentBankTransferOtherAmount.value,
                  _specialPriceEnabled ? double.tryParse(_specialPriceTextController.text.replaceAll(',', '.')) : null,
                  _specialPriceEnabled ? _specialPriceReasonTextController.text : null,
                  _topUpCreditEnabled ? double.tryParse(_topUpTextController.text.replaceAll(',', '.')) : null,
                  _totalDue,
                  _specialPriceIsDefaultForUser,
                );
                Navigator.of(context).pop(
                  result,
                );
              }),
        ],
        if (_paySpecialPriceWithCredit) ...<Widget>[
          TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Hash Credit'),
              onPressed: () {
                final OtherPaymentPopupResult result = OtherPaymentPopupResult(
                  'process',
                  paymentHashCreditOtherAmount.value,
                  _specialPriceEnabled ? double.tryParse(_specialPriceTextController.text.replaceAll(',', '.')) : null,
                  _specialPriceEnabled ? _specialPriceReasonTextController.text : null,
                  _topUpCreditEnabled ? double.tryParse(_topUpTextController.text.replaceAll(',', '.')) : null,
                  _totalDue,
                  _specialPriceIsDefaultForUser,
                );

                Navigator.of(context).pop(result);
              }),
        ],
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
