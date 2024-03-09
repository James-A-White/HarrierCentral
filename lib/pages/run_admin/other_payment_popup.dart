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
  final double? specialPriceAmount;
  final String? specialPriceReason;
  final double topUpAmount;
  final double totalAmount;
  final bool useSpecialPriceAsDefault;
}

class OtherPaymentPopup extends StatefulWidget {
  const OtherPaymentPopup(
    this.normalPrice,
    this.decimalDigits,
    this.currencySymbol,
    this.showCreditTopup,
    this.allowDefaultPricing, {
    super.key,
  });

  final double normalPrice;
  final int decimalDigits;
  final String currencySymbol;
  final bool showCreditTopup;
  final bool allowDefaultPricing;

  @override
  OtherPaymentPopupState createState() => OtherPaymentPopupState();
}

class OtherPaymentPopupState extends State<OtherPaymentPopup> {
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
                                    ? (bool? val) {
                                        if (val != null) {
                                          setState(() {
                                            _paySpecialPriceWithCredit = !_paySpecialPriceWithCredit;
                                            if (_topUpCreditEnabled && _paySpecialPriceWithCredit) {
                                              _topUpCreditEnabled = false;
                                            }
                                          });
                                        }
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
                                    ? (bool? val) {
                                        if (val != null) {
                                          setState(() {
                                            _specialPriceIsDefaultForUser = !_specialPriceIsDefaultForUser;
                                          });
                                        }
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
                        onChanged: (bool? val) {
                          if (val != null) {
                            setState(() {
                              _recalculateTotal();
                              _specialPriceEnabled = !_specialPriceEnabled;
                              if (!_specialPriceEnabled) {
                                _specialPriceTextController.value = TextEditingValue(text: widget.normalPrice.toStringAsFixed(widget.decimalDigits));
                              }
                            });
                          }
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
                          onChanged: (bool? val) {
                            if (val != null) {
                              _recalculateTotal();
                              setState(() {
                                _topUpCreditEnabled = !_topUpCreditEnabled;
                                if (_paySpecialPriceWithCredit && _topUpCreditEnabled) {
                                  _paySpecialPriceWithCredit = false;
                                }
                              });
                            }
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

        SizedBox(
          height: 55.0,
          child: TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(OtherPaymentPopupResult(
                'cancel',
                -1,
                0.0,
                '',
                0.0,
                0.0,
                _specialPriceIsDefaultForUser,
              ));
            },
          ),
        ),
        //   ),
        // ),
        // Container(
        //   width: 60.0,
        //child:

        if (!_paySpecialPriceWithCredit) ...<Widget>[
          SizedBox(
            height: 55.0,
            child: TextButton(
                style: TextButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Cash'),
                onPressed: () {
                  final OtherPaymentPopupResult result = OtherPaymentPopupResult(
                    'process',
                    paymentCashOtherAmount.value,
                    _specialPriceEnabled ? double.tryParse(_specialPriceTextController.text.replaceAll(',', '.')) ?? 0.0 : 0.0,
                    _specialPriceEnabled ? _specialPriceReasonTextController.text : '',
                    _topUpCreditEnabled ? double.tryParse(_topUpTextController.text.replaceAll(',', '.')) ?? 0.0 : 0.0,
                    _totalDue,
                    _specialPriceIsDefaultForUser,
                  );

                  Navigator.of(context).pop(result);
                }),
          ),
          SizedBox(
            height: 55.0,
            child: TextButton(
                style: TextButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text(
                  'Bank\r\ntransfer',
                  textAlign: TextAlign.center,
                ),
                onPressed: () {
                  final OtherPaymentPopupResult result = OtherPaymentPopupResult(
                    'process',
                    paymentBankTransferOtherAmount.value,
                    _specialPriceEnabled ? double.tryParse(_specialPriceTextController.text.replaceAll(',', '.')) ?? 0.0 : 0.0,
                    _specialPriceEnabled ? _specialPriceReasonTextController.text : '',
                    _topUpCreditEnabled ? double.tryParse(_topUpTextController.text.replaceAll(',', '.')) ?? 0.0 : 0.0,
                    _totalDue,
                    _specialPriceIsDefaultForUser,
                  );
                  Navigator.of(context).pop(
                    result,
                  );
                }),
          ),
        ],
        if (_paySpecialPriceWithCredit) ...<Widget>[
          SizedBox(
            height: 55.0,
            child: TextButton(
                style: TextButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Hash Credit'),
                onPressed: () {
                  final OtherPaymentPopupResult result = OtherPaymentPopupResult(
                    'process',
                    paymentHashCreditOtherAmount.value,
                    _specialPriceEnabled ? double.tryParse(_specialPriceTextController.text.replaceAll(',', '.')) ?? 0.0 : 0.0,
                    _specialPriceEnabled ? _specialPriceReasonTextController.text : '',
                    _topUpCreditEnabled ? double.tryParse(_topUpTextController.text.replaceAll(',', '.')) ?? 0.0 : 0.0,
                    _totalDue,
                    _specialPriceIsDefaultForUser,
                  );

                  Navigator.of(context).pop(result);
                }),
          ),
        ],
        // ),
      ],
    );
  }
}
