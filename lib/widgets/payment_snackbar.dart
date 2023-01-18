// @dart=2.11
import 'package:harrier_central/imports.dart';

class PaymentSnackBar extends SnackBar {
  const PaymentSnackBar({
    Key key,
    @required this.context,
    @required this.packMember,
    @required this.eventAggregate,
    @required this.onRsvpCallback,
    @required this.onPaidCallback,
    @required this.amountOwed,
  }) : super(key: key, content: const Text('test'));

  final BuildContext context;
  final CheckInPackModel packMember;
  final RunAdminAggregate eventAggregate;
  final Function onRsvpCallback;
  final Function onPaidCallback;
  final num amountOwed;

  @override
  Duration get duration => const Duration(seconds: 30);

  @override
  Color get backgroundColor => Colors.red.shade900;

  String formatMoney(num money) {
    return IveCoreUtilities.getFormattedMoney(money, eventAggregate.extensions.digAfterDec ?? 2, eventAggregate.extensions.curSym);
  }

  @override
  Widget get content {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AutoSizeText(
          packMember.nameForDisplay,
          maxLines: 1,
          minFontSize: 12.0,
          style: const TextStyle(fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 35.0, height: 1.0),
        ),
        !eventAggregate.extensions.appAccess.canManageRuns
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
                            color: ((packMember.rsvpState != null) && (packMember.rsvpState == rsvpNo.value)) ? Colors.yellow : Colors.white,
                          ),

                          //tooltip: 'Select to follow a Kennel',
                          iconSize: 30.0,
                          alignment: Alignment.topCenter,
                          splashColor: Colors.greenAccent,
                          onPressed: () {
                            onRsvpCallback(packMember, rsvpState: rsvpNo.value, attendenceState: attendenceNoChange.value, isHare: isHareNo.value);
                            // packScopedModel.setRsvpState(
                            //     rsvpNo.value,
                            //     isHareNo.value,
                            //     attendenceNo.value,
                            //     packMember['']);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar(reason: SnackBarClosedReason.hide);
                          },
                        ),
                        const Text(
                          'Not coming',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'AvenirNextCondensedDemiBold',
                            fontStyle: FontStyle.normal,
                            fontSize: 15.0,
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
                            color: ((packMember.rsvpState != null) && (packMember.rsvpState == rsvpMaybe.value)) ? Colors.yellow : Colors.white,
                          ),

                          //tooltip: 'Select to follow a Kennel',
                          iconSize: 30.0,
                          alignment: Alignment.topCenter,
                          splashColor: Colors.greenAccent,
                          onPressed: () {
                            onRsvpCallback(packMember, rsvpState: rsvpMaybe.value, attendenceState: attendenceNoChange.value, isHare: isHareNo.value);
                            // packScopedModel.setRsvpState(
                            //     rsvpMaybe.value,
                            //     isHareNo.value,
                            //     attendenceNo.value,
                            //     packMember['']);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar(reason: SnackBarClosedReason.hide);
                          },
                        ),
                        const Text(
                          'Maybe',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'AvenirNextCondensedDemiBold',
                            fontStyle: FontStyle.normal,
                            fontSize: 15.0,
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
                            'images/icons/check_icon.png',
                            height: 30.0,
                            width: 30.0,
                            color: (((packMember.rsvpState != null) && (packMember.rsvpState == rsvpYes.value)) && ((packMember.isHare == null) || (packMember.isHare == isHareNo.value)))
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
                        const Text(
                          'Coming',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'AvenirNextCondensedDemiBold',
                            fontStyle: FontStyle.normal,
                            fontSize: 15.0,
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
                            'images/icons/hare_icon.png',
                            height: 30.0,
                            width: 30.0,
                            color: (((packMember.rsvpState != null) && (packMember.rsvpState == rsvpYes.value)) && ((packMember.isHare != null) && (packMember.isHare == isHareYes.value)))
                                ? Colors.yellow
                                : Colors.white,
                          ),

                          //tooltip: 'Select to follow a Kennel',
                          iconSize: 30.0,
                          alignment: Alignment.topCenter,
                          splashColor: Colors.greenAccent,
                          onPressed: () {
                            onRsvpCallback(packMember, rsvpState: rsvpYes.value, isHare: isHareYes.value);
                            // packScopedModel.setRsvpState(rsvpYes.value,
                            //     isHareYes.value, -1, packMember['']);
                            // ScaffoldMessenger.of(context).hideCurrentSnackBar(
                            //     reason: SnackBarClosedReason.hide);
                          },
                        ),
                        const Text(
                          'Will hare',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'AvenirNextCondensedDemiBold',
                            fontStyle: FontStyle.normal,
                            fontSize: 15.0,
                            height: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        !eventAggregate.extensions.appAccess.canManageRuns
            ? Container()
            : Padding(
                padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
                child: Container(color: Colors.white, height: 3.0),
              ),
        !eventAggregate.extensions.appAccess.canManageRuns
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
                            'images/icons/not_at_hash_icon.png',
                            height: 30.0,
                            width: 30.0,
                            color: ((packMember.attendenceState == attendenceNo.value) && ((packMember.rsvpState != null) && (packMember.rsvpState == rsvpYes.value))) ? Colors.yellow : Colors.white,
                          ),

                          //tooltip: 'Select to follow a Kennel',
                          iconSize: 30.0,
                          alignment: Alignment.topCenter,
                          splashColor: Colors.greenAccent,
                          onPressed: () {
                            onRsvpCallback(packMember, attendenceState: attendenceNo.value);
                            // packScopedModel.setRsvpState(
                            //     -1, -1, attendenceNo.value, packMember['']);
                            // ScaffoldMessenger.of(context).hideCurrentSnackBar(
                            //     reason: SnackBarClosedReason.hide);
                          },
                        ),
                        const Text(
                          'Not at Hash',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'AvenirNextCondensedDemiBold',
                            fontStyle: FontStyle.normal,
                            fontSize: 15.0,
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
                            'images/icons/runner_icon.png',
                            height: 30.0,
                            width: 30.0,
                            color:
                                ((packMember.attendenceState == attendenceAtHash.value) && ((packMember.rsvpState != null) && (packMember.rsvpState == rsvpYes.value))) ? Colors.yellow : Colors.white,
                          ),

                          //tooltip: 'Select to follow a Kennel',
                          iconSize: 30.0,
                          alignment: Alignment.topCenter,
                          splashColor: Colors.greenAccent,
                          onPressed: () {
                            onRsvpCallback(packMember, rsvpState: packMember.rsvpState < rsvpYes.value ? rsvpYes.value : -1, attendenceState: attendenceAtHash.value);
                            // packScopedModel.setRsvpState(rsvpYes.value, -1,
                            //     attendenceAtHash.value, packMember['']);
                            // ScaffoldMessenger.of(context).hideCurrentSnackBar(
                            //     reason: SnackBarClosedReason.hide);
                          },
                        ),
                        const Text(
                          'At Hash',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'AvenirNextCondensedDemiBold',
                            fontStyle: FontStyle.normal,
                            fontSize: 15.0,
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
                            'images/icons/beer_icon.png',
                            height: 30.0,
                            width: 30.0,
                            color: ((packMember.attendenceState == attendenceOnIn.value) && ((packMember.rsvpState != null) && (packMember.rsvpState == rsvpYes.value))) ? Colors.yellow : Colors.white,
                          ),

                          //tooltip: 'Select to follow a Kennel',
                          iconSize: 30.0,
                          alignment: Alignment.topCenter,
                          splashColor: Colors.greenAccent,
                          onPressed: () {
                            onRsvpCallback(packMember, rsvpState: packMember.rsvpState < rsvpYes.value ? rsvpYes.value : -1, attendenceState: attendenceOnIn.value);
                            // packScopedModel.setRsvpState(rsvpYes.value, -1,
                            //     attendenceOnIn.value, packMember['']);
                            // ScaffoldMessenger.of(context).hideCurrentSnackBar(
                            //     reason: SnackBarClosedReason.hide);
                          },
                        ),
                        const Text(
                          'On In',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'AvenirNextCondensedDemiBold',
                            fontStyle: FontStyle.normal,
                            fontSize: 15.0,
                            height: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        !eventAggregate.extensions.appAccess.canManageRuns
            ? Container()
            : Padding(
                padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
                child: Container(color: Colors.white, height: 3.0),
              ),
        !eventAggregate.extensions.appAccess.canManageHashCash
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
                              icon: Image.asset('images/icons/payment_type_3.png', height: 30.0, width: 30.0, color: packMember.paymentType == paymentCash.value ? Colors.yellow : Colors.white),
                              //tooltip: 'Select to follow a Kennel',
                              iconSize: 30.0,
                              alignment: Alignment.topCenter,
                              splashColor: Colors.greenAccent,
                              onPressed: () async {
                                await onPaidCallback(packMember, paymentCash.value);
                              },
                            ),
                            Text(
                              (eventAggregate.event.eventPriceForExtras ?? 0) != 0 ? 'Paid cash' : 'Paid\r\n${formatMoney(amountOwed)} cash',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'AvenirNextCondensedDemiBold',
                                fontStyle: FontStyle.normal,
                                fontSize: 15.0,
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
                              icon: Image.asset('images/icons/payment_type_2.png', height: 30.0, width: 30.0, color: packMember.paymentType == paymentFreeRun.value ? Colors.yellow : Colors.white),
                              //tooltip: 'Select to follow a Kennel',
                              iconSize: 30.0,
                              alignment: Alignment.topCenter,
                              splashColor: Colors.greenAccent,
                              onPressed: () async {
                                await onPaidCallback(packMember, paymentFreeRun.value);
                              },
                            ),
                            const Text(
                              'Free run',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'AvenirNextCondensedDemiBold',
                                fontStyle: FontStyle.normal,
                                fontSize: 15.0,
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
                              icon: Image.asset('images/icons/payment_type_5.png',
                                  height: 30.0,
                                  width: 30.0,
                                  color: ((packMember.paymentType == paymentCashOtherAmount.value) || (packMember.paymentType == paymentBankTransferOtherAmount.value)) ? Colors.yellow : Colors.white),
                              //tooltip: 'Select to follow a Kennel',
                              iconSize: 30.0,
                              alignment: Alignment.topCenter,
                              splashColor: Colors.greenAccent,
                              onPressed: () async {
                                await _payOther(packMember, context);
                              },
                            ),
                            Text(
                              'Paid other${((packMember.paymentType == paymentCashOtherAmount.value) || (packMember.paymentType == paymentBankTransferOtherAmount.value))
                                      ? '\r\n(${formatMoney(packMember.creditAmount)}${packMember.paymentType == paymentCashOtherAmount.value ? ' cash)' : ' transfer)'}'
                                      : ''}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'AvenirNextCondensedDemiBold',
                                fontStyle: FontStyle.normal,
                                fontSize: 15.0,
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
                              icon:
                                  Image.asset('images/icons/payment_type_4.png', height: 30.0, width: 30.0, color: packMember.paymentType == paymentBankTransfer.value ? Colors.yellow : Colors.white),
                              //tooltip: 'Select to follow a Kennel',
                              iconSize: 30.0,
                              alignment: Alignment.topCenter,
                              splashColor: Colors.greenAccent,
                              onPressed: () async {
                                await onPaidCallback(packMember, paymentBankTransfer.value);
                              },
                            ),
                            Text(
                              (eventAggregate.event.eventPriceForExtras ?? 0) != 0 ? 'Paid\r\nbank transfer' : 'Paid ${formatMoney(amountOwed)}\r\nbank transfer',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'AvenirNextCondensedDemiBold',
                                fontStyle: FontStyle.normal,
                                fontSize: 15.0,
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
                              icon: Image.asset('images/icons/payment_type_1.png',
                                  height: 30.0, width: 30.0, color: ((packMember.isPaid == 0) || (packMember.paymentType == paymentNotPaid.value)) ? Colors.yellow : Colors.white),

                              //tooltip: 'Select to follow a Kennel',
                              iconSize: 30.0,
                              alignment: Alignment.topCenter,
                              splashColor: Colors.greenAccent,
                              onPressed: () async {
                                await onPaidCallback(packMember, paymentNotPaid.value);
                              },
                            ),
                            const Text(
                              'Not paid',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'AvenirNextCondensedDemiBold',
                                fontStyle: FontStyle.normal,
                                fontSize: 15.0,
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
                                    icon: Image.asset('images/icons/payment_type_6.png',
                                        height: 30.0, width: 30.0, color: packMember.paymentType == paymentHashCredit.value ? Colors.yellow : Colors.white),
                                    //tooltip: 'Select to follow a Kennel',
                                    iconSize: 30.0,
                                    alignment: Alignment.topCenter,
                                    splashColor: Colors.greenAccent,
                                    onPressed: () async {
                                      await onPaidCallback(packMember, paymentHashCredit.value);
                                    },
                                  ),
                                  Text(
                                    (eventAggregate.event.eventPriceForExtras ?? 0) != 0
                                        ? 'Paid credit\r\n(${packMember.credit < 0 ? 'Owes' : 'Available'} ${IveCoreUtilities.getFormattedMoney(packMember.credit.abs(), eventAggregate.extensions.digAfterDec ?? 2, eventAggregate.extensions.curSym)})'
                                        : 'Credit ${formatMoney(amountOwed)}\r\n(${packMember.credit < 0 ? 'Owes' : 'Available'} ${IveCoreUtilities.getFormattedMoney(packMember.credit.abs(), eventAggregate.extensions.digAfterDec ?? 2, eventAggregate.extensions.curSym)})',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'AvenirNextCondensedDemiBold',
                                      fontStyle: FontStyle.normal,
                                      fontSize: 15.0,
                                      height: 0.9,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ],
                  ),
                ],
              ),
      ],
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

  Future<void> _payOther(CheckInPackModel packMember, BuildContext context) async {
    final OtherPaymentPopup otherPaymentPopup = OtherPaymentPopup(
      amountOwed,
      eventAggregate.extensions.digAfterDec,
      eventAggregate.extensions.curSym,
      packMember.isMember != 0,
      (packMember.isMember != 0) || (packMember.isFollowing != 0),
    );

    final OtherPaymentPopupResult userInput = await showDialog<OtherPaymentPopupResult>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return otherPaymentPopup;
        });

    if (userInput.action == 'process') {
      await onPaidCallback(packMember, userInput.transType, userInput: userInput);
    }
  }
}
