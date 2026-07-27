import 'package:harrier_central/imports.dart';

class PaymentSnackBar extends SnackBar {
  const PaymentSnackBar({
    super.key,
    required this.context,
    required this.packMember,
    required this.eventAggregate,
    required this.onRsvpCallback,
    required this.onPaidCallback,
    required this.amountOwed,
    required this.multiSelectEnabled,
  }) : super(content: const Text('test'));

  final BuildContext context;
  final CheckInPackModel packMember;
  final RunAdminAggregate eventAggregate;
  final Function onRsvpCallback;
  final Function onPaidCallback;
  final double amountOwed;
  final bool multiSelectEnabled;

  @override
  Duration get duration => const Duration(seconds: 30);

  @override
  Color get backgroundColor => hc_red;

  String formatMoney(num money) {
    return IveCoreUtilities.getFormattedMoney(
      money,
      eventAggregate.extensions.digAfterDec,
      eventAggregate.extensions.curSym,
    );
  }

  @override
  Widget get content {
    // Mirror the server gate (role OR flag), not flag-only. See /hc-authorizations.
    final bool canAttend = canAccessFeature(
      KennelFeature.manageAttendance,
      appAccessFlags: eventAggregate.extensions.appAccessFlags,
      mismanagementRoles: eventAggregate.extensions.mismanagementRoles,
      kennelOverrideJson: eventAggregate.kennel.permissionOverrideJson,
    );
    final bool canTakePayment = canAccessFeature(
      KennelFeature.takePayment,
      appAccessFlags: eventAggregate.extensions.appAccessFlags,
      mismanagementRoles: eventAggregate.extensions.mismanagementRoles,
      kennelOverrideJson: eventAggregate.kennel.permissionOverrideJson,
    );
    return TextScaleFactorClamper(
      textScaleFactor: 1.50,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AutoSizeText(
            multiSelectEnabled ? 'Multiple Hashers' : packMember.nameForDisplay,
            maxLines: 1,
            minFontSize: 12.0,
            style: ts_titleCondensedVeryLarge,
          ),
          (!canAttend ||
                  multiSelectEnabled)
              ? Container()
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          IconButton(
                            icon: Image.asset(
                              'images/icons/x_icon.png',
                              height: 30.0,
                              width: 30.0,
                              color: ((packMember.rsvpState == rsvpNo.value))
                                  ? Colors.yellow
                                  : Colors.white,
                            ),

                            //tooltip: 'Select to follow a Kennel',
                            iconSize: 30.0,
                            alignment: Alignment.topCenter,
                            splashColor: Colors.greenAccent,
                            onPressed: () {
                              onRsvpCallback(
                                packMember,
                                rsvpState: rsvpNo.value,
                                attendenceState: attendenceNoChange.value,
                                isHare: isHareNo.value,
                              );
                              ScaffoldMessenger.of(context).hideCurrentSnackBar(
                                reason: SnackBarClosedReason.hide,
                              );
                            },
                          ),
                          Text(
                            'Not coming',
                            textAlign: TextAlign.center,
                            style: ts_titleSmallCondensedBold.copyWith(
                              height: 0.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          IconButton(
                            icon: Image.asset(
                              'images/icons/question_icon.png',
                              height: 30.0,
                              width: 30.0,
                              color: ((packMember.rsvpState == rsvpMaybe.value))
                                  ? Colors.yellow
                                  : Colors.white,
                            ),

                            //tooltip: 'Select to follow a Kennel',
                            iconSize: 30.0,
                            alignment: Alignment.topCenter,
                            splashColor: Colors.greenAccent,
                            onPressed: () {
                              onRsvpCallback(
                                packMember,
                                rsvpState: rsvpMaybe.value,
                                attendenceState: attendenceNoChange.value,
                                isHare: isHareNo.value,
                              );
                              // packScopedModel.setRsvpState(
                              //     rsvpMaybe.value,
                              //     isHareNo.value,
                              //     attendenceNo.value,
                              //     packMember['']);
                              ScaffoldMessenger.of(context).hideCurrentSnackBar(
                                reason: SnackBarClosedReason.hide,
                              );
                            },
                          ),
                          Text(
                            'Maybe',
                            textAlign: TextAlign.center,
                            style: ts_titleSmallCondensedBold,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          IconButton(
                            icon: Image.asset(
                              'images/icons/check_icon.png',
                              height: 30.0,
                              width: 30.0,
                              color:
                                  (((packMember.rsvpState == rsvpYes.value)) &&
                                      ((packMember.isHare == isHareNo.value)))
                                  ? Colors.yellow
                                  : Colors.white,
                            ),

                            //tooltip: 'Select to follow a Kennel',
                            iconSize: 30.0,
                            alignment: Alignment.topCenter,
                            splashColor: Colors.greenAccent,
                            onPressed: () {
                              onRsvpCallback(
                                packMember,
                                rsvpState: rsvpYes.value,
                                isHare: isHareNo.value,
                                attendenceState: attendenceNoChange.value,
                              );
                            },
                          ),
                          Text(
                            'Coming',
                            textAlign: TextAlign.center,
                            style: ts_titleSmallCondensedBold,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          IconButton(
                            icon: Image.asset(
                              'images/icons/hare_icon.png',
                              height: 30.0,
                              width: 30.0,
                              color:
                                  (((packMember.rsvpState == rsvpYes.value)) &&
                                      ((packMember.isHare == isHareYes.value)))
                                  ? Colors.yellow
                                  : Colors.white,
                            ),

                            //tooltip: 'Select to follow a Kennel',
                            iconSize: 30.0,
                            alignment: Alignment.topCenter,
                            splashColor: Colors.greenAccent,
                            onPressed: () {
                              onRsvpCallback(
                                packMember,
                                rsvpState: rsvpYes.value,
                                isHare: isHareYes.value,
                              );
                              // packScopedModel.setRsvpState(rsvpYes.value,
                              //     isHareYes.value, -1, packMember['']);
                              // ScaffoldMessenger.of(context).hideCurrentSnackBar(
                              //     reason: SnackBarClosedReason.hide);
                            },
                          ),
                          Text(
                            'Will hare',
                            textAlign: TextAlign.center,
                            style: ts_titleSmallCondensedBold,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          (!canAttend ||
                  multiSelectEnabled)
              ? Container()
              : Padding(
                  padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
                  child: Container(color: Colors.white, height: 3.0),
                ),
          !canAttend
              ? Container()
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    if (!multiSelectEnabled)
                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            IconButton(
                              icon: Image.asset(
                                'images/icons/not_at_hash_icon.png',
                                height: 30.0,
                                width: 30.0,
                                color:
                                    ((packMember.attendenceState ==
                                            attendenceNo.value) &&
                                        ((packMember.rsvpState ==
                                            rsvpYes.value)))
                                    ? Colors.yellow
                                    : Colors.white,
                              ),

                              //tooltip: 'Select to follow a Kennel',
                              iconSize: 30.0,
                              alignment: Alignment.topCenter,
                              splashColor: Colors.greenAccent,
                              onPressed: () {
                                onRsvpCallback(
                                  packMember,
                                  attendenceState: attendenceNo.value,
                                );
                                // packScopedModel.setRsvpState(
                                //     -1, -1, attendenceNo.value, packMember['']);
                                // ScaffoldMessenger.of(context).hideCurrentSnackBar(
                                //     reason: SnackBarClosedReason.hide);
                              },
                            ),
                            Text(
                              'Not at Hash',
                              textAlign: TextAlign.center,
                              style: ts_titleSmallCondensedBold,
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          IconButton(
                            icon: Image.asset(
                              'images/icons/runner_icon.png',
                              height: 30.0,
                              width: 30.0,
                              color:
                                  ((packMember.attendenceState ==
                                          attendenceAtHash.value) &&
                                      ((packMember.rsvpState == rsvpYes.value)))
                                  ? Colors.yellow
                                  : Colors.white,
                            ),

                            //tooltip: 'Select to follow a Kennel',
                            iconSize: 30.0,
                            alignment: Alignment.topCenter,
                            splashColor: Colors.greenAccent,
                            onPressed: () {
                              onRsvpCallback(
                                packMember,
                                rsvpState: packMember.rsvpState < rsvpYes.value
                                    ? rsvpYes.value
                                    : -1,
                                attendenceState: attendenceAtHash.value,
                              );
                              // packScopedModel.setRsvpState(rsvpYes.value, -1,
                              //     attendenceAtHash.value, packMember['']);
                              // ScaffoldMessenger.of(context).hideCurrentSnackBar(
                              //     reason: SnackBarClosedReason.hide);
                            },
                          ),
                          Text(
                            'At Hash',
                            textAlign: TextAlign.center,
                            style: ts_titleSmallCondensedBold,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          IconButton(
                            icon: Image.asset(
                              'images/icons/beer_icon.png',
                              height: 30.0,
                              width: 30.0,
                              color:
                                  ((packMember.attendenceState ==
                                          attendenceOnIn.value) &&
                                      ((packMember.rsvpState == rsvpYes.value)))
                                  ? Colors.yellow
                                  : Colors.white,
                            ),

                            //tooltip: 'Select to follow a Kennel',
                            iconSize: 30.0,
                            alignment: Alignment.topCenter,
                            splashColor: Colors.greenAccent,
                            onPressed: () {
                              onRsvpCallback(
                                packMember,
                                rsvpState: packMember.rsvpState < rsvpYes.value
                                    ? rsvpYes.value
                                    : -1,
                                attendenceState: attendenceOnIn.value,
                              );
                              // packScopedModel.setRsvpState(rsvpYes.value, -1,
                              //     attendenceOnIn.value, packMember['']);
                              // ScaffoldMessenger.of(context).hideCurrentSnackBar(
                              //     reason: SnackBarClosedReason.hide);
                            },
                          ),
                          Text(
                            'On In',
                            textAlign: TextAlign.center,
                            style: ts_titleSmallCondensedBold,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          !canAttend
              ? Container()
              : Padding(
                  padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
                  child: Container(color: Colors.white, height: 3.0),
                ),
          !canTakePayment
              ? Container()
              : Column(
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              IconButton(
                                icon: Image.asset(
                                  'images/icons/payment_type_3.png',
                                  height: 30.0,
                                  width: 30.0,
                                  color:
                                      packMember.paymentType ==
                                          paymentCash.value
                                      ? Colors.yellow
                                      : Colors.white,
                                ),
                                //tooltip: 'Select to follow a Kennel',
                                iconSize: 30.0,
                                alignment: Alignment.topCenter,
                                splashColor: Colors.greenAccent,
                                onPressed: () async {
                                  await onPaidCallback(
                                    packMember,
                                    paymentCash.value,
                                  );
                                },
                              ),
                              Text(
                                (eventAggregate.event.eventPriceForExtras ??
                                            0) !=
                                        0
                                    ? 'Paid cash'
                                    : 'Paid\r\n${formatMoney(amountOwed)} cash',
                                textAlign: TextAlign.center,
                                style: ts_titleSmallCondensedBold.copyWith(
                                  height: 0.9,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              IconButton(
                                icon: Image.asset(
                                  'images/icons/payment_type_2.png',
                                  height: 30.0,
                                  width: 30.0,
                                  color:
                                      packMember.paymentType ==
                                          paymentFreeRun.value
                                      ? Colors.yellow
                                      : Colors.white,
                                ),
                                //tooltip: 'Select to follow a Kennel',
                                iconSize: 30.0,
                                alignment: Alignment.topCenter,
                                splashColor: Colors.greenAccent,
                                onPressed: () async {
                                  await onPaidCallback(
                                    packMember,
                                    paymentFreeRun.value,
                                  );
                                },
                              ),
                              Text(
                                'Free run',
                                textAlign: TextAlign.center,
                                style: ts_titleSmallCondensedBold.copyWith(
                                  height: 0.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!multiSelectEnabled)
                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                IconButton(
                                  icon: Image.asset(
                                    'images/icons/payment_type_5.png',
                                    height: 30.0,
                                    width: 30.0,
                                    color:
                                        ((packMember.paymentType ==
                                                paymentCashOtherAmount.value) ||
                                            (packMember.paymentType ==
                                                paymentBankTransferOtherAmount
                                                    .value))
                                        ? Colors.yellow
                                        : Colors.white,
                                  ),
                                  //tooltip: 'Select to follow a Kennel',
                                  iconSize: 30.0,
                                  alignment: Alignment.topCenter,
                                  splashColor: Colors.greenAccent,
                                  onPressed: () async {
                                    await _payOther(packMember, context);
                                  },
                                ),
                                Text(
                                  'Paid other${((packMember.paymentType == paymentCashOtherAmount.value) || (packMember.paymentType == paymentBankTransferOtherAmount.value)) ? '\r\n(${formatMoney(packMember.creditAmount)}${packMember.paymentType == paymentCashOtherAmount.value ? ' cash)' : ' transfer)'}' : ''}',
                                  textAlign: TextAlign.center,
                                  style: ts_titleSmallCondensedBold.copyWith(
                                    height: 0.9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 100, height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              IconButton(
                                icon: Image.asset(
                                  'images/icons/payment_type_4.png',
                                  height: 30.0,
                                  width: 30.0,
                                  color:
                                      packMember.paymentType ==
                                          paymentBankTransfer.value
                                      ? Colors.yellow
                                      : Colors.white,
                                ),
                                //tooltip: 'Select to follow a Kennel',
                                iconSize: 30.0,
                                alignment: Alignment.topCenter,
                                splashColor: Colors.greenAccent,
                                onPressed: () async {
                                  await onPaidCallback(
                                    packMember,
                                    paymentBankTransfer.value,
                                  );
                                },
                              ),
                              Text(
                                (eventAggregate.event.eventPriceForExtras ??
                                            0) !=
                                        0
                                    ? 'Paid\r\nbank transfer'
                                    : 'Paid ${formatMoney(amountOwed)}\r\nbank transfer',
                                textAlign: TextAlign.center,
                                style: ts_titleSmallCondensedBold.copyWith(
                                  height: 0.9,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!multiSelectEnabled)
                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                IconButton(
                                  icon: Image.asset(
                                    'images/icons/payment_type_1.png',
                                    height: 30.0,
                                    width: 30.0,
                                    color:
                                        ((packMember.isPaid == 0) ||
                                            (packMember.paymentType ==
                                                paymentNotPaid.value))
                                        ? Colors.yellow
                                        : Colors.white,
                                  ),

                                  //tooltip: 'Select to follow a Kennel',
                                  iconSize: 30.0,
                                  alignment: Alignment.topCenter,
                                  splashColor: Colors.greenAccent,
                                  onPressed: () async {
                                    await onPaidCallback(
                                      packMember,
                                      paymentNotPaid.value,
                                    );
                                  },
                                ),
                                Text(
                                  'Not paid',
                                  textAlign: TextAlign.center,
                                  style: ts_titleSmallCondensedBold.copyWith(
                                    height: 0.9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        (packMember.isMember == 0)
                            ? Container()
                            : Expanded(
                                flex: 1,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: <Widget>[
                                    IconButton(
                                      icon: Image.asset(
                                        'images/icons/payment_type_6.png',
                                        height: 30.0,
                                        width: 30.0,
                                        color:
                                            packMember.paymentType ==
                                                paymentHashCredit.value
                                            ? Colors.yellow
                                            : Colors.white,
                                      ),
                                      //tooltip: 'Select to follow a Kennel',
                                      iconSize: 30.0,
                                      alignment: Alignment.topCenter,
                                      splashColor: Colors.greenAccent,
                                      onPressed: () async {
                                        await onPaidCallback(
                                          packMember,
                                          paymentHashCredit.value,
                                        );
                                      },
                                    ),
                                    if (multiSelectEnabled)
                                      Text(
                                        'Paid credit',
                                        textAlign: TextAlign.center,
                                        style: ts_titleSmallCondensedBold
                                            .copyWith(height: 0.9),
                                      ),
                                    if (!multiSelectEnabled)
                                      Text(
                                        (eventAggregate
                                                        .event
                                                        .eventPriceForExtras ??
                                                    0) !=
                                                0
                                            ? 'Paid credit\r\n(${packMember.credit < 0 ? 'Owes' : 'Available'} ${IveCoreUtilities.getFormattedMoney(packMember.credit.abs(), eventAggregate.extensions.digAfterDec, eventAggregate.extensions.curSym)})'
                                            : 'Credit ${formatMoney(amountOwed)}\r\n(${packMember.credit < 0 ? 'Owes' : 'Available'} ${IveCoreUtilities.getFormattedMoney(packMember.credit.abs(), eventAggregate.extensions.digAfterDec, eventAggregate.extensions.curSym)})',
                                        textAlign: TextAlign.center,
                                        style: ts_titleSmallCondensedBold
                                            .copyWith(height: 0.9),
                                      ),
                                  ],
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  // void populatePriceStrings() {
  //   memberPrice = IveCoreUtilities.getFormattedMoney(futureRun.eventPriceForMembers,
  //       futureRun.digitsAfterDecimal, futureRun.currencySymbol);
  //   nonMemberPrice = IveCoreUtilities.getFormattedMoney(
  //       futureRun.eventPriceForNonMembers,
  //       futureRun.digitsAfterDecimal,
  //       futureRun.currencySymbol);
  // }

  Future<void> _payOther(
    CheckInPackModel packMember,
    BuildContext context,
  ) async {
    final OtherPaymentPopup otherPaymentPopup = OtherPaymentPopup(
      amountOwed,
      eventAggregate.extensions.digAfterDec,
      eventAggregate.extensions.curSym,
      packMember.isMember != 0,
      (packMember.isMember != 0) || (packMember.isFollowing != 0),
    );

    final OtherPaymentPopupResult? userInput =
        await showDialog<OtherPaymentPopupResult>(
          context: context,
          barrierDismissible: false, // user must tap button!
          builder: (BuildContext context) {
            return otherPaymentPopup;
          },
        );

    if ((userInput != null) && (userInput.action == 'process')) {
      await onPaidCallback(
        packMember,
        userInput.transType,
        userInput: userInput,
      );
    }
  }
}
