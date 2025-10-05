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

class OtherPaymentPopupController extends GetxController {
  OtherPaymentPopupController(this.normalPrice, this.decimalDigits);

  final double normalPrice;
  final int decimalDigits;

  final specialPriceTextController = TextEditingController();
  final specialPriceReasonTextController = TextEditingController();
  final topUpTextController = TextEditingController();

  final specialPriceFocusNode = FocusNode();
  final specialPriceReasonFocusNode = FocusNode();
  final topUpFocusNode = FocusNode();

  final topUpCreditEnabled = false.obs;
  final specialPriceEnabled = false.obs;
  final paySpecialPriceWithCredit = false.obs;
  final specialPriceIsDefaultForUser = false.obs;
  final totalDue = 0.0.obs;

  @override
  void onInit() {
    specialPriceTextController.text = normalPrice.toStringAsFixed(
      decimalDigits,
    );
    specialPriceTextController.addListener(_recalculateTotal);
    topUpTextController.addListener(_recalculateTotal);
    topUpCreditEnabled.listen((_) => _recalculateTotal());
    specialPriceEnabled.listen((_) => _recalculateTotal());
    paySpecialPriceWithCredit.listen((_) => _recalculateTotal());
    specialPriceIsDefaultForUser.listen((_) => _recalculateTotal());

    _recalculateTotal();
    super.onInit();
  }

  void _recalculateTotal() {
    double total = specialPriceEnabled.value
        ? double.tryParse(
                specialPriceTextController.text.replaceAll(',', '.'),
              ) ??
              0
        : normalPrice;

    if (topUpCreditEnabled.value) {
      total +=
          double.tryParse(topUpTextController.text.replaceAll(',', '.')) ?? 0;
    }

    totalDue.value = total;
  }
}

class OtherPaymentPopup extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final controller = Get.put(
      OtherPaymentPopupController(normalPrice, decimalDigits),
    );
    return AlertDialog(
      actionsOverflowButtonSpacing: 30.0,
      actionsOverflowAlignment: OverflowBarAlignment.start,
      actionsOverflowDirection: VerticalDirection.up,
      actionsPadding: EdgeInsets.all(10.0),
      title: Text('Payment options', style: ts_alertDialogTitle),
      content: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Stack(
                    children: <Widget>[
                      //const SizedBox(height: 10.0, width: 10),
                      Obx(
                        () => Container(
                          margin: const EdgeInsets.only(top: 23.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: Colors.white,
                            border: Border.all(
                              color: controller.specialPriceEnabled.value
                                  ? hc_red
                                  : Colors.grey.shade300,
                              width:
                                  2, //                   <--- border width here
                            ),
                          ),
                          child: Column(
                            children: <Widget>[
                              const SizedBox(height: 20.0),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 15.0,
                                  right: 15.0,
                                  top: 15.0,
                                ),
                                child: Text(
                                  'If you want to offer a Hasher a special price for this run, enter that amount here. You can also enter an optional note why you offered this price.',
                                  style: TextStyle(
                                    color: controller.specialPriceEnabled.value
                                        ? Colors.black
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15.0,
                                ),
                                child: TextField(
                                  autofocus: true,
                                  enabled: controller.specialPriceEnabled.value,
                                  focusNode: controller.specialPriceFocusNode,
                                  controller:
                                      controller.specialPriceTextController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: TextStyle(
                                    fontFamily: 'AvenirNextDemiBold',
                                    fontSize: 20.0,
                                    color: controller.specialPriceEnabled.value
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    // icon: Icon(
                                    //   FontAwesome.money,
                                    //   color: Colors.white,
                                    // ),
                                    hintText: 'Enter special price',
                                    hintStyle: TextStyle(
                                      fontFamily: 'AvenirNextDemiBold',
                                      fontSize: 20.0,
                                      color:
                                          controller.specialPriceEnabled.value
                                          ? Colors.grey.shade500
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15.0,
                                ),
                                child: TextField(
                                  autofocus: true,
                                  autocorrect: false,
                                  enabled: controller.specialPriceEnabled.value,
                                  focusNode:
                                      controller.specialPriceReasonFocusNode,
                                  controller: controller
                                      .specialPriceReasonTextController,
                                  keyboardType: TextInputType.text,
                                  style: TextStyle(
                                    fontFamily: 'AvenirNextDemiBold',
                                    fontSize: 20.0,
                                    color: controller.specialPriceEnabled.value
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    // icon: Icon(
                                    //   FontAwesome.money,
                                    //   color: Colors.white,
                                    // ),
                                    hintText: 'Enter reason',
                                    hintStyle: TextStyle(
                                      fontFamily: 'AvenirNextDemiBold',
                                      fontSize: 20.0,
                                      color:
                                          controller.specialPriceEnabled.value
                                          ? Colors.grey.shade500
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                              ),
                              if (showCreditTopup)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 0.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      Theme(
                                        data: ThemeData(
                                          //primarySwatch: hc_blue,
                                          unselectedWidgetColor:
                                              controller
                                                  .specialPriceEnabled
                                                  .value
                                              ? hc_red
                                              : Colors
                                                    .grey
                                                    .shade100, // Your color
                                        ),
                                        child: Checkbox(
                                          side: const BorderSide(
                                            color: Colors.black,
                                          ), // <- add border always

                                          checkColor: Colors.white,
                                          fillColor:
                                              WidgetStateProperty.resolveWith<
                                                Color
                                              >((Set<WidgetState> states) {
                                                if (states.contains(
                                                  WidgetState.disabled,
                                                )) {
                                                  return Colors.grey.shade300;
                                                }
                                                return controller
                                                        .paySpecialPriceWithCredit
                                                        .value
                                                    ? hc_red
                                                    : Colors.white;
                                              }),
                                          onChanged:
                                              controller
                                                  .specialPriceEnabled
                                                  .value
                                              ? (bool? val) {
                                                  if (val != null) {
                                                    //setState(() {
                                                    controller
                                                        .paySpecialPriceWithCredit
                                                        .value = !controller
                                                        .paySpecialPriceWithCredit
                                                        .value;
                                                    if (controller
                                                            .topUpCreditEnabled
                                                            .value &&
                                                        controller
                                                            .paySpecialPriceWithCredit
                                                            .value) {
                                                      controller
                                                              .topUpCreditEnabled
                                                              .value =
                                                          false;
                                                    }
                                                    //});
                                                  }
                                                }
                                              : null,
                                          value: controller
                                              .paySpecialPriceWithCredit
                                              .value,
                                        ),
                                      ),
                                      Text(
                                        'Pay with Hash Credit',
                                        style: TextStyle(
                                          color:
                                              controller
                                                  .specialPriceEnabled
                                                  .value
                                              ? Colors.black
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                      const SizedBox(width: 10.0),
                                    ],
                                  ),
                                ),
                              if (allowDefaultPricing) ...<Widget>[
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 0.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      Theme(
                                        data: ThemeData(
                                          //primarySwatch: hc_blue,
                                          unselectedWidgetColor:
                                              controller
                                                  .specialPriceEnabled
                                                  .value
                                              ? hc_red
                                              : Colors
                                                    .grey
                                                    .shade100, // Your color
                                        ),
                                        child: Checkbox(
                                          side: const BorderSide(
                                            color: Colors.black,
                                          ), // <- add border always
                                          checkColor: Colors.white,
                                          fillColor:
                                              WidgetStateProperty.resolveWith<
                                                Color
                                              >((Set<WidgetState> states) {
                                                if (states.contains(
                                                  WidgetState.disabled,
                                                )) {
                                                  return Colors.grey.shade300;
                                                }
                                                return controller
                                                        .specialPriceIsDefaultForUser
                                                        .value
                                                    ? hc_red
                                                    : Colors.white;
                                              }),
                                          onChanged:
                                              controller
                                                  .specialPriceEnabled
                                                  .value
                                              ? (bool? val) {
                                                  if (val != null) {
                                                    //setState(() {
                                                    controller
                                                        .specialPriceIsDefaultForUser
                                                        .value = !controller
                                                        .specialPriceIsDefaultForUser
                                                        .value;
                                                    //});
                                                  }
                                                }
                                              : null,
                                          value: controller
                                              .specialPriceIsDefaultForUser
                                              .value,
                                        ),
                                      ),
                                      Text(
                                        'Set for future runs',
                                        style: TextStyle(
                                          color:
                                              controller
                                                  .specialPriceEnabled
                                                  .value
                                              ? Colors.black
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                      const SizedBox(width: 10.0),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Obx(
                        () => Positioned(
                          top: 0,
                          left: 13,
                          child: Container(
                            //color: Colors.white,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: Colors.white,
                              border: Border.all(
                                color: controller.specialPriceEnabled.value
                                    ? hc_red
                                    : Colors.grey.shade300,
                                width:
                                    2, //                   <--- border width here
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                Checkbox(
                                  side: const BorderSide(
                                    color: Colors.black,
                                  ), // <- add border always
                                  checkColor: Colors.white,
                                  fillColor: WidgetStateProperty.all<Color>(
                                    controller.specialPriceEnabled.value
                                        ? hc_red
                                        : Colors.white,
                                  ),

                                  onChanged: (bool? val) {
                                    if (val != null) {
                                      //setState(() {
                                      // _recalculateTotal();
                                      controller.specialPriceEnabled.value =
                                          !controller.specialPriceEnabled.value;
                                      if (!controller
                                          .specialPriceEnabled
                                          .value) {
                                        controller
                                            .specialPriceTextController
                                            .value = TextEditingValue(
                                          text: normalPrice.toStringAsFixed(
                                            decimalDigits,
                                          ),
                                        );
                                      }
                                      // });
                                    }
                                  },
                                  value: controller.specialPriceEnabled.value,
                                ),
                                Text(
                                  'Special run price',
                                  style: ts_condensedBlack,
                                ),
                                const SizedBox(width: 10.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (showCreditTopup) ...<Widget>[
                    const SizedBox(height: 13.0),
                    const Divider(thickness: 1.0),
                    SizedBox(height: 10),
                    Stack(
                      children: <Widget>[
                        const SizedBox(height: 170.0, width: 10),
                        Obx(
                          () => Container(
                            margin: const EdgeInsets.only(top: 23.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: Colors.white,
                              border: Border.all(
                                color: controller.topUpCreditEnabled.value
                                    ? hc_red
                                    : Colors.grey.shade300,
                                width:
                                    2, //                   <--- border width here
                              ),
                            ),
                            child: Column(
                              children: <Widget>[
                                const SizedBox(height: 20.0),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 15.0,
                                    right: 15.0,
                                    top: 15.0,
                                  ),
                                  child: Text(
                                    'Enter an additional amount of money here to add to a Hasher\'s credit balance.',
                                    style: TextStyle(
                                      color: controller.topUpCreditEnabled.value
                                          ? Colors.black
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15.0,
                                  ),
                                  child: TextField(
                                    autofocus: true,
                                    enabled:
                                        controller.topUpCreditEnabled.value,
                                    focusNode: controller.topUpFocusNode,
                                    controller: controller.topUpTextController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    style: TextStyle(
                                      fontFamily: 'AvenirNextDemiBold',
                                      fontSize: 20.0,
                                      color: controller.topUpCreditEnabled.value
                                          ? Colors.grey.shade700
                                          : Colors.grey.shade300,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      // icon: Icon(
                                      //   FontAwesome.money,
                                      //   color: Colors.white,
                                      // ),
                                      hintText: 'Enter top up amount',
                                      hintStyle: TextStyle(
                                        fontFamily: 'AvenirNextDemiBold',
                                        fontSize: 20.0,
                                        color:
                                            controller.topUpCreditEnabled.value
                                            ? Colors.grey.shade500
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Obx(
                          () => Positioned(
                            top: 0,
                            left: 13,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: Colors.white,
                                border: Border.all(
                                  color: controller.topUpCreditEnabled.value
                                      ? hc_red
                                      : Colors.grey.shade300,
                                  width:
                                      2, //                   <--- border width here
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  Checkbox(
                                    side: const BorderSide(
                                      color: Colors.black,
                                    ), // <- add border always
                                    fillColor: WidgetStateProperty.all<Color>(
                                      controller.topUpCreditEnabled.value
                                          ? hc_red
                                          : Colors.white,
                                    ),
                                    checkColor: Colors.white,
                                    onChanged: (bool? val) {
                                      if (val != null) {
                                        // _recalculateTotal();

                                        controller.topUpCreditEnabled.value =
                                            !controller
                                                .topUpCreditEnabled
                                                .value;
                                        if (controller
                                                .paySpecialPriceWithCredit
                                                .value &&
                                            controller
                                                .topUpCreditEnabled
                                                .value) {
                                          controller
                                                  .paySpecialPriceWithCredit
                                                  .value =
                                              false;
                                        }
                                        // setState(() {});
                                      }
                                    },
                                    value: controller.topUpCreditEnabled.value,
                                  ),
                                  Text(
                                    'Top up credit',
                                    style: ts_condensedBlack,
                                  ),
                                  const SizedBox(width: 10.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 20.0),
            child: Obx(
              () => Text(
                'Total due: ${IveCoreUtilities.getFormattedMoney(controller.totalDue.value, decimalDigits, currencySymbol)}',
                style: ts_title.copyWith(color: Colors.grey.shade700),
              ),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        //   ),
        // ),
        // Container(
        //   width: 60.0,
        //child:
        Obx(
          () => OverflowBar(
            spacing: 9.0,
            children: [
              SizedBox(
                height: 41.0,
                child: TextButton(
                  style: TextButton.styleFrom(
                    shape: button_shape,
                    backgroundColor: hc_red,
                  ),
                  child: Text(
                    'Cancel',
                    style: ts_button.copyWith(fontSize: 18),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(
                      OtherPaymentPopupResult(
                        'cancel',
                        -1,
                        0.0,
                        '',
                        0.0,
                        0.0,
                        controller.specialPriceIsDefaultForUser.value,
                      ),
                    );
                  },
                ),
              ),
              if ((controller.specialPriceEnabled.value ||
                      controller.topUpCreditEnabled.value) &&
                  (!controller.paySpecialPriceWithCredit.value)) ...<Widget>[
                SizedBox(
                  //padding: EdgeInsets.all(8.0),
                  height: 41.0,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      shape: button_shape,
                      backgroundColor: hc_blue,
                    ),
                    child: Text(
                      'Cash',
                      style: ts_button.copyWith(fontSize: 18),
                    ),
                    onPressed: () {
                      final OtherPaymentPopupResult
                      result = OtherPaymentPopupResult(
                        'process',
                        paymentCashOtherAmount.value,
                        controller.specialPriceEnabled.value
                            ? double.tryParse(
                                controller.specialPriceTextController.text
                                    .replaceAll(',', '.'),
                              )
                            : null,
                        controller.specialPriceEnabled.value
                            ? controller.specialPriceReasonTextController.text
                            : null,
                        controller.topUpCreditEnabled.value
                            ? double.tryParse(
                                    controller.topUpTextController.text
                                        .replaceAll(',', '.'),
                                  ) ??
                                  0.0
                            : 0.0,
                        controller.totalDue.value,
                        controller.specialPriceIsDefaultForUser.value,
                      );

                      Navigator.of(context).pop(result);
                    },
                  ),
                ),
                SizedBox(
                  //padding: EdgeInsets.all(2.0),
                  height: 41.0,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      shape: button_shape,
                      backgroundColor: hc_blue,
                    ),
                    child: Text(
                      'Bank',
                      style: ts_button.copyWith(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    onPressed: () {
                      final OtherPaymentPopupResult
                      result = OtherPaymentPopupResult(
                        'process',
                        paymentBankTransferOtherAmount.value,
                        controller.specialPriceEnabled.value
                            ? double.tryParse(
                                    controller.specialPriceTextController.text
                                        .replaceAll(',', '.'),
                                  ) ??
                                  0.0
                            : 0.0,
                        controller.specialPriceEnabled.value
                            ? controller.specialPriceReasonTextController.text
                            : '',
                        controller.topUpCreditEnabled.value
                            ? double.tryParse(
                                    controller.topUpTextController.text
                                        .replaceAll(',', '.'),
                                  ) ??
                                  0.0
                            : 0.0,
                        controller.totalDue.value,
                        controller.specialPriceIsDefaultForUser.value,
                      );
                      Navigator.of(context).pop(result);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        Obx(
          () => Column(
            children: [
              if ((controller.specialPriceEnabled.value ||
                      controller.topUpCreditEnabled.value) &&
                  (controller.paySpecialPriceWithCredit.value)) ...<Widget>[
                Container(
                  padding: EdgeInsets.all(8.0),
                  height: 65.0,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      shape: button_shape,
                      backgroundColor: hc_blue,
                    ),
                    child: Text('Hash Credit', style: ts_button),
                    onPressed: () {
                      final OtherPaymentPopupResult
                      result = OtherPaymentPopupResult(
                        'process',
                        paymentHashCreditOtherAmount.value,
                        controller.specialPriceEnabled.value
                            ? double.tryParse(
                                    controller.specialPriceTextController.text
                                        .replaceAll(',', '.'),
                                  ) ??
                                  0.0
                            : 0.0,
                        controller.specialPriceEnabled.value
                            ? controller.specialPriceReasonTextController.text
                            : '',
                        controller.topUpCreditEnabled.value
                            ? double.tryParse(
                                    controller.topUpTextController.text
                                        .replaceAll(',', '.'),
                                  ) ??
                                  0.0
                            : 0.0,
                        controller.totalDue.value,
                        controller.specialPriceIsDefaultForUser.value,
                      );

                      Navigator.of(context).pop(result);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        // ),
      ],
    );
  }
}
