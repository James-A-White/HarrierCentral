import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/data_models/future_run_model.dart';
import 'package:harrier_central/data_models/user_model.dart';
import 'package:harrier_central/services/pack_scoped_model.dart';
import 'package:harrier_central/services/pay_scoped_model.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/pages/run_admin/other_payment_popup.dart';
import 'package:harrier_central/data_models/pay_for_event_model.dart';

import 'package:scoped_model/scoped_model.dart';

class PaymentSnackBar extends SnackBar {
   const PaymentSnackBar({
    @required this.index,
    @required this.packScopedModel,
    @required this.payScopedModel,
    @required this.context,
    @required this.packList,
    @required this.futureRun,
  }): super(content: const Text('test'));

  final int index;
  final PackScopedModel packScopedModel;
  final PayScopedModel payScopedModel;
  final BuildContext context;
  final List<UserModel> packList;
  final FutureRun futureRun;

   final String memberPrice = '€5.00';
   final String nonMemberPrice = '€5.00';

   @override // TODO: implement content
  Widget get content => 
Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            packList[index].displayName,
            style: const TextStyle(
                fontFamily: 'AvenirNextCondensedDemiBold',
                fontStyle: FontStyle.normal,
                fontSize: 35.0,
                height: 1.0),
          ),
          Row(
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
                        color: packList[index].requestedRsvpState != -1
                            ? Colors.blue
                            : packList[index].rsvpState == rsvpNo.value
                                ? Colors.yellow
                                : Colors.white,
                      ),

                      //tooltip: 'Select to follow a Kennel',
                      iconSize: 30.0,
                      alignment: Alignment.topCenter,
                      splashColor: Colors.greenAccent,
                      onPressed: () {
                        packScopedModel.setRsvpState(
                            rsvpNo.value,
                            isHareNo.value,
                            attendenceNo.value,
                            packList[index]);
                        Scaffold.of(context).hideCurrentSnackBar(
                            reason: SnackBarClosedReason.hide);
                      },
                    ),
                    Text(
                      "Not coming",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
                        color: packList[index].requestedRsvpState != -1
                            ? Colors.blue
                            : packList[index].rsvpState == rsvpMaybe.value
                                ? Colors.yellow
                                : Colors.white,
                      ),

                      //tooltip: 'Select to follow a Kennel',
                      iconSize: 30.0,
                      alignment: Alignment.topCenter,
                      splashColor: Colors.greenAccent,
                      onPressed: () {
                        packScopedModel.setRsvpState(
                            rsvpMaybe.value,
                            isHareNo.value,
                            attendenceNo.value,
                            packList[index]);
                        Scaffold.of(context).hideCurrentSnackBar(
                            reason: SnackBarClosedReason.hide);
                      },
                    ),
                    Text(
                      "Maybe",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
                        color: packList[index].requestedRsvpState != -1
                            ? Colors.blue
                            : ((packList[index].rsvpState == rsvpYes.value) &&
                                    (packList[index].isHare == isHareNo.value))
                                ? Colors.yellow
                                : Colors.white,
                      ),

                      //tooltip: 'Select to follow a Kennel',
                      iconSize: 30.0,
                      alignment: Alignment.topCenter,
                      splashColor: Colors.greenAccent,
                      onPressed: () {
                        packScopedModel.setRsvpState(
                            rsvpYes.value, isHareNo.value, -1, packList[index]);
                        Scaffold.of(context).hideCurrentSnackBar(
                            reason: SnackBarClosedReason.hide);
                      },
                    ),
                    Text(
                      "Coming",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
                        color: packList[index].requestedRsvpState != -1
                            ? Colors.blue
                            : ((packList[index].rsvpState == rsvpYes.value) &&
                                    (packList[index].isHare == isHareYes.value))
                                ? Colors.yellow
                                : Colors.white,
                      ),

                      //tooltip: 'Select to follow a Kennel',
                      iconSize: 30.0,
                      alignment: Alignment.topCenter,
                      splashColor: Colors.greenAccent,
                      onPressed: () {
                        packScopedModel.setRsvpState(rsvpYes.value,
                            isHareYes.value, -1, packList[index]);
                        Scaffold.of(context).hideCurrentSnackBar(
                            reason: SnackBarClosedReason.hide);
                      },
                    ),
                    Text(
                      "Will hare",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
          Padding(
            padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
            child: Container(color: Colors.white, height: 3.0),
          ),
          Row(
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
                        color: packList[index].requestedAttendenceState != -1
                            ? Colors.blue
                            : ((packList[index].attendenceState ==
                                        attendenceNo.value) &&
                                    (packList[index].rsvpState ==
                                        rsvpYes.value))
                                ? Colors.yellow
                                : Colors.white,
                      ),

                      //tooltip: 'Select to follow a Kennel',
                      iconSize: 30.0,
                      alignment: Alignment.topCenter,
                      splashColor: Colors.greenAccent,
                      onPressed: () {
                        packScopedModel.setRsvpState(
                            -1, -1, attendenceNo.value, packList[index]);
                        Scaffold.of(context).hideCurrentSnackBar(
                            reason: SnackBarClosedReason.hide);
                      },
                    ),
                    Text(
                      "Not at Hash",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
                        color: packList[index].requestedAttendenceState != -1
                            ? Colors.blue
                            : ((packList[index].attendenceState ==
                                        attendenceAtHash.value) &&
                                    (packList[index].rsvpState ==
                                        rsvpYes.value))
                                ? Colors.yellow
                                : Colors.white,
                      ),

                      //tooltip: 'Select to follow a Kennel',
                      iconSize: 30.0,
                      alignment: Alignment.topCenter,
                      splashColor: Colors.greenAccent,
                      onPressed: () {
                        packScopedModel.setRsvpState(rsvpYes.value, -1,
                            attendenceAtHash.value, packList[index]);
                        Scaffold.of(context).hideCurrentSnackBar(
                            reason: SnackBarClosedReason.hide);
                      },
                    ),
                    Text(
                      "At Hash",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
                        color: packList[index].requestedAttendenceState != -1
                            ? Colors.blue
                            : ((packList[index].attendenceState ==
                                        attendenceOnIn.value) &&
                                    (packList[index].rsvpState ==
                                        rsvpYes.value))
                                ? Colors.yellow
                                : Colors.white,
                      ),

                      //tooltip: 'Select to follow a Kennel',
                      iconSize: 30.0,
                      alignment: Alignment.topCenter,
                      splashColor: Colors.greenAccent,
                      onPressed: () {
                        packScopedModel.setRsvpState(rsvpYes.value, -1,
                            attendenceOnIn.value, packList[index]);
                        Scaffold.of(context).hideCurrentSnackBar(
                            reason: SnackBarClosedReason.hide);
                      },
                    ),
                    Text(
                      "On In",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
          Padding(
            padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
            child: Container(color: Colors.white, height: 3.0),
          ),
          ScopedModelDescendant<PayScopedModel>(
            builder:
                (BuildContext context, Widget child, PayScopedModel model) {
              return Column(children: <Widget>[
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
                            icon: Image.asset('images/icons/payment_type_1.png',
                                height: 30.0,
                                width: 30.0,
                                color: ((packList[index].isPaid == 0) ||
                                        (packList[index].paymentType ==
                                            paymentNotPaid.value))
                                    ? Colors.yellow
                                    : Colors.white),

                            //tooltip: 'Select to follow a Kennel',
                            iconSize: 30.0,
                            alignment: Alignment.topCenter,
                            splashColor: Colors.greenAccent,
                            onPressed: () {
                              processPayment(
                                  index,
                                  packScopedModel,
                                  payScopedModel,
                                  context,
                                  paymentNotPaid.value,
                                  0.0);
                            },
                          ),
                          Text(
                            "Not paid",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
                            icon: Image.asset('images/icons/payment_type_2.png',
                                height: 30.0,
                                width: 30.0,
                                color: packList[index].paymentType ==
                                        paymentFreeRun.value
                                    ? Colors.yellow
                                    : Colors.white),
                            //tooltip: 'Select to follow a Kennel',
                            iconSize: 30.0,
                            alignment: Alignment.topCenter,
                            splashColor: Colors.greenAccent,
                            onPressed: () {
                              processPayment(
                                  index,
                                  packScopedModel,
                                  payScopedModel,
                                  context,
                                  paymentFreeRun.value,
                                  0.0);
                            },
                          ),
                          Text(
                            "Free run",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
                                color: ((packList[index].paymentType ==
                                            paymentCashOtherAmount.value) ||
                                        (packList[index].paymentType ==
                                            paymentBankTransferOtherAmount
                                                .value))
                                    ? Colors.yellow
                                    : Colors.white),
                            //tooltip: 'Select to follow a Kennel',
                            iconSize: 30.0,
                            alignment: Alignment.topCenter,
                            splashColor: Colors.greenAccent,
                            onPressed: () {
                              payOther(index, packScopedModel, context);
                            },
                          ),
                          Text(
                            "Paid other",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
                Container(width: 100, height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          IconButton(
                            icon: Image.asset('images/icons/payment_type_3.png',
                                height: 30.0,
                                width: 30.0,
                                color: packList[index].paymentType ==
                                        paymentCash.value
                                    ? Colors.yellow
                                    : Colors.white),
                            //tooltip: 'Select to follow a Kennel',
                            iconSize: 30.0,
                            alignment: Alignment.topCenter,
                            splashColor: Colors.greenAccent,
                            onPressed: () {
                              processPayment(
                                  index,
                                  packScopedModel,
                                  payScopedModel,
                                  context,
                                  paymentCash.value,
                                  packList[index].isMember != 1
                                      ? futureRun.eventPriceForNonMembers
                                      : futureRun.eventPriceForNonMembers);
                            },
                          ),
                          Text(
                            'Paid ${packList[index].isMember != 1 ? nonMemberPrice : memberPrice}\r\ncash',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
                            icon: Image.asset('images/icons/payment_type_4.png',
                                height: 30.0,
                                width: 30.0,
                                color: packList[index].paymentType ==
                                        paymentBankTransfer.value
                                    ? Colors.yellow
                                    : Colors.white),
                            //tooltip: 'Select to follow a Kennel',
                            iconSize: 30.0,
                            alignment: Alignment.topCenter,
                            splashColor: Colors.greenAccent,
                            onPressed: () {
                              processPayment(
                                  index,
                                  packScopedModel,
                                  payScopedModel,
                                  context,
                                  paymentBankTransfer.value,
                                  packList[index].isMember != 1
                                      ? futureRun.eventPriceForNonMembers
                                      : futureRun.eventPriceForNonMembers);
                            },
                          ),
                          Text(
                            'Paid ${packList[index].isMember != 1 ? nonMemberPrice : memberPrice}\r\nbank transfer',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
                            icon: Image.asset('images/icons/payment_type_6.png',
                                height: 30.0,
                                width: 30.0,
                                color: packList[index].paymentType ==
                                        paymentHashCredit.value
                                    ? Colors.yellow
                                    : Colors.white),
                            //tooltip: 'Select to follow a Kennel',
                            iconSize: 30.0,
                            alignment: Alignment.topCenter,
                            splashColor: Colors.greenAccent,
                            onPressed: () {
                              processPayment(
                                  index,
                                  packScopedModel,
                                  payScopedModel,
                                  context,
                                  paymentHashCredit.value,
                                  packList[index].isMember != 1
                                      ? futureRun.eventPriceForNonMembers
                                      : futureRun.eventPriceForNonMembers);
                            },
                          ),
                          Text(
                            'Credit ${packList[index].isMember != 1 ? nonMemberPrice : memberPrice}\r\n(${packList[index].credit < 0 ? 'Owes' : 'Credit'} ${Utilities.getFormattedMoney(packList[index].credit.abs(), futureRun?.digitsAfterDecimal ?? 2, futureRun.currencySymbol)})',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
              ]);
            },
          ),
        ],
      )
      
      ;

   
  

  // void populatePriceStrings() {
  //   memberPrice = Utilities.getFormattedMoney(futureRun.eventPriceForMembers,
  //       futureRun.digitsAfterDecimal, futureRun.currencySymbol);
  //   nonMemberPrice = Utilities.getFormattedMoney(
  //       futureRun.eventPriceForNonMembers,
  //       futureRun.digitsAfterDecimal,
  //       futureRun.currencySymbol);
  // }

  void payOther(
      int index, PackScopedModel _packScopedModel, BuildContext context) {
    OtherPaymentPopup otherPaymentPopup =
        OtherPaymentPopup(currencySymbol: futureRun.currencySymbol);

    Future<Map<String, String>> dlg = showDialog<Map<String, String>>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return otherPaymentPopup;
        });

    dlg.then((Map<String, String> x) {
      String amount = x['amount'];
      String type = x['type'];

      if (type != 'cancel') {
        num v = num.tryParse(amount);
        int t = int.tryParse(type);

        if ((v != null) && (t != null)) {
          processPayment(
              index, _packScopedModel, payScopedModel, context, t, v);
        }
      }
    });
  }

  void processPayment(
      int index,
      PackScopedModel _packScopedModel,
      PayScopedModel _payScopedModel,
      BuildContext context,
      int paymentType,
      num paymentAmount) {
    UserModel hasher = packList[index];

    if (hasher.rsvpState < rsvpYes.value) {
      hasher.rsvpState = -1;
      hasher.requestedRsvpState = rsvpYes.value;
    }

    // if (hasher.attendenceState < attendenceAtHash.value)
    // {
    //   hasher.attendenceState = -1;
    //   hasher.requestedAttendenceState = attendenceAtHash.value;
    // }

    _packScopedModel.forceRefresh();

    _payScopedModel
        .payForEvent(
            packList, index, paymentType, paymentAmount, attendenceAtHash.value)
        .then((List<PayForEventModel> result) {
      if (paymentType == paymentNotPaid.value) {
        hasher.isPaid = 0;
      } else {
        hasher.isPaid = 1;
      }

      if (hasher.hasherEventMapId != result[0].hasherEventMapId) {
        hasher.hasherEventMapId = result[0].hasherEventMapId;
      }

      if (hasher.userRunCount != result[0].totalRunsThisKennel) {
        hasher.userRunCount = result[0].totalRunsThisKennel;
      }

      hasher.rsvpState = rsvpYes.value;
      hasher.requestedRsvpState = -1;

      if (hasher.attendenceState < attendenceAtHash.value) {
        hasher.attendenceState = attendenceAtHash.value;
      }



      _packScopedModel.forceRefresh();

      packList[index].paymentType = paymentType;
      if ((paymentType == paymentCashOtherAmount.value) ||
          (paymentType == paymentBankTransferOtherAmount.value)) {
        final num fundsDifference = paymentAmount -
            (hasher.isMember == 1
                ? futureRun.eventPriceForMembers
                : futureRun.eventPriceForNonMembers);

        String credit = Utilities.getFormattedMoney(fundsDifference,
            futureRun?.digitsAfterDecimal ?? 2, futureRun.currencySymbol);

        double hashCashAmount = (hasher.isMember == 1
            ? futureRun.eventPriceForMembers
            : futureRun.eventPriceForNonMembers);

        String hashCash = Utilities.getFormattedMoney(hashCashAmount,
            futureRun?.digitsAfterDecimal ?? 2, futureRun.currencySymbol);

        String amountPaid = Utilities.getFormattedMoney(paymentAmount,
            futureRun?.digitsAfterDecimal ?? 2, futureRun.currencySymbol);

        String paymentMethod = paymentType == paymentCashOtherAmount.value
            ? 'in cash'
            : 'by bank transfer';

        if (fundsDifference > 0.0) {
          showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                // return object of type Dialog
                return AlertDialog(
                  title: const Text("Credit applied to account"),
                  content: Text(
                      '$amountPaid was paid $paymentMethod. $hashCash was used to pay for the run and $credit has been credited to your Hash account for ${futureRun.kennelShortName}'),
                  actions: <Widget>[
                    // usually buttons at the bottom of the dialog
                    FlatButton(
                      color: Colors.blue,
                      textColor: Colors.white,
                      child: const Text("Close"),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              });
        }
      }
    });

    packList[index].isPaid = -1;

    // int attendenceState = -1;
    // if (packList[index].attendenceState < attendenceAtHash.value) {
    //   attendenceState = attendenceAtHash.value;
    // }
    // _packScopedModel.setRsvpState(
    //     rsvpYes.value, -1, attendenceState, packList[index]);

    Scaffold.of(context).hideCurrentSnackBar(reason: SnackBarClosedReason.hide);
  }




  // @override
  // Widget build(BuildContext context) {
  //   //populatePriceStrings();

  //   return SnackBar(
  //     duration: const Duration(seconds: 5),
  //     content: 
      
      
  //     Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: <Widget>[
  //         Text(
  //           packList[index].displayName,
  //           style: const TextStyle(
  //               fontFamily: 'AvenirNextCondensedDemiBold',
  //               fontStyle: FontStyle.normal,
  //               fontSize: 35.0,
  //               height: 1.0),
  //         ),
  //         Row(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           mainAxisAlignment: MainAxisAlignment.spaceAround,
  //           children: <Widget>[
  //             Expanded(
  //               flex: 1,
  //               child: Column(
  //                 mainAxisAlignment: MainAxisAlignment.start,
  //                 children: <Widget>[
  //                   IconButton(
  //                     icon: Image.asset(
  //                       'images/icons/x_icon.png',
  //                       height: 30.0,
  //                       width: 30.0,
  //                       color: packList[index].requestedRsvpState != -1
  //                           ? Colors.blue
  //                           : packList[index].rsvpState == rsvpNo.value
  //                               ? Colors.yellow
  //                               : Colors.white,
  //                     ),

  //                     //tooltip: 'Select to follow a Kennel',
  //                     iconSize: 30.0,
  //                     alignment: Alignment.topCenter,
  //                     splashColor: Colors.greenAccent,
  //                     onPressed: () {
  //                       packScopedModel.setRsvpState(
  //                           rsvpNo.value,
  //                           isHareNo.value,
  //                           attendenceNo.value,
  //                           packList[index]);
  //                       Scaffold.of(context).hideCurrentSnackBar(
  //                           reason: SnackBarClosedReason.hide);
  //                     },
  //                   ),
  //                   Text(
  //                     "Not coming",
  //                     textAlign: TextAlign.center,
  //                     style: const TextStyle(
  //                       fontFamily: 'AvenirNextCondensedDemiBold',
  //                       fontStyle: FontStyle.normal,
  //                       fontSize: 15.0,
  //                       height: 0.7,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             Expanded(
  //               flex: 1,
  //               child: Column(
  //                 mainAxisAlignment: MainAxisAlignment.start,
  //                 children: <Widget>[
  //                   IconButton(
  //                     icon: Image.asset(
  //                       'images/icons/question_icon.png',
  //                       height: 30.0,
  //                       width: 30.0,
  //                       color: packList[index].requestedRsvpState != -1
  //                           ? Colors.blue
  //                           : packList[index].rsvpState == rsvpMaybe.value
  //                               ? Colors.yellow
  //                               : Colors.white,
  //                     ),

  //                     //tooltip: 'Select to follow a Kennel',
  //                     iconSize: 30.0,
  //                     alignment: Alignment.topCenter,
  //                     splashColor: Colors.greenAccent,
  //                     onPressed: () {
  //                       packScopedModel.setRsvpState(
  //                           rsvpMaybe.value,
  //                           isHareNo.value,
  //                           attendenceNo.value,
  //                           packList[index]);
  //                       Scaffold.of(context).hideCurrentSnackBar(
  //                           reason: SnackBarClosedReason.hide);
  //                     },
  //                   ),
  //                   Text(
  //                     "Maybe",
  //                     textAlign: TextAlign.center,
  //                     style: const TextStyle(
  //                       fontFamily: 'AvenirNextCondensedDemiBold',
  //                       fontStyle: FontStyle.normal,
  //                       fontSize: 15.0,
  //                       height: 0.7,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             Expanded(
  //               flex: 1,
  //               child: Column(
  //                 mainAxisAlignment: MainAxisAlignment.start,
  //                 children: <Widget>[
  //                   IconButton(
  //                     icon: Image.asset(
  //                       'images/icons/check_icon.png',
  //                       height: 30.0,
  //                       width: 30.0,
  //                       color: packList[index].requestedRsvpState != -1
  //                           ? Colors.blue
  //                           : ((packList[index].rsvpState == rsvpYes.value) &&
  //                                   (packList[index].isHare == isHareNo.value))
  //                               ? Colors.yellow
  //                               : Colors.white,
  //                     ),

  //                     //tooltip: 'Select to follow a Kennel',
  //                     iconSize: 30.0,
  //                     alignment: Alignment.topCenter,
  //                     splashColor: Colors.greenAccent,
  //                     onPressed: () {
  //                       packScopedModel.setRsvpState(
  //                           rsvpYes.value, isHareNo.value, -1, packList[index]);
  //                       Scaffold.of(context).hideCurrentSnackBar(
  //                           reason: SnackBarClosedReason.hide);
  //                     },
  //                   ),
  //                   Text(
  //                     "Coming",
  //                     textAlign: TextAlign.center,
  //                     style: const TextStyle(
  //                       fontFamily: 'AvenirNextCondensedDemiBold',
  //                       fontStyle: FontStyle.normal,
  //                       fontSize: 15.0,
  //                       height: 0.7,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             Expanded(
  //               flex: 1,
  //               child: Column(
  //                 mainAxisAlignment: MainAxisAlignment.start,
  //                 children: <Widget>[
  //                   IconButton(
  //                     icon: Image.asset(
  //                       'images/icons/hare_icon.png',
  //                       height: 30.0,
  //                       width: 30.0,
  //                       color: packList[index].requestedRsvpState != -1
  //                           ? Colors.blue
  //                           : ((packList[index].rsvpState == rsvpYes.value) &&
  //                                   (packList[index].isHare == isHareYes.value))
  //                               ? Colors.yellow
  //                               : Colors.white,
  //                     ),

  //                     //tooltip: 'Select to follow a Kennel',
  //                     iconSize: 30.0,
  //                     alignment: Alignment.topCenter,
  //                     splashColor: Colors.greenAccent,
  //                     onPressed: () {
  //                       packScopedModel.setRsvpState(rsvpYes.value,
  //                           isHareYes.value, -1, packList[index]);
  //                       Scaffold.of(context).hideCurrentSnackBar(
  //                           reason: SnackBarClosedReason.hide);
  //                     },
  //                   ),
  //                   Text(
  //                     "Will hare",
  //                     textAlign: TextAlign.center,
  //                     style: const TextStyle(
  //                       fontFamily: 'AvenirNextCondensedDemiBold',
  //                       fontStyle: FontStyle.normal,
  //                       fontSize: 15.0,
  //                       height: 0.7,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //         Padding(
  //           padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
  //           child: Container(color: Colors.white, height: 3.0),
  //         ),
  //         Row(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           mainAxisAlignment: MainAxisAlignment.spaceAround,
  //           children: <Widget>[
  //             Expanded(
  //               flex: 1,
  //               child: Column(
  //                 mainAxisAlignment: MainAxisAlignment.start,
  //                 children: <Widget>[
  //                   IconButton(
  //                     icon: Image.asset(
  //                       'images/icons/not_at_hash_icon.png',
  //                       height: 30.0,
  //                       width: 30.0,
  //                       color: packList[index].requestedAttendenceState != -1
  //                           ? Colors.blue
  //                           : ((packList[index].attendenceState ==
  //                                       attendenceNo.value) &&
  //                                   (packList[index].rsvpState ==
  //                                       rsvpYes.value))
  //                               ? Colors.yellow
  //                               : Colors.white,
  //                     ),

  //                     //tooltip: 'Select to follow a Kennel',
  //                     iconSize: 30.0,
  //                     alignment: Alignment.topCenter,
  //                     splashColor: Colors.greenAccent,
  //                     onPressed: () {
  //                       packScopedModel.setRsvpState(
  //                           -1, -1, attendenceNo.value, packList[index]);
  //                       Scaffold.of(context).hideCurrentSnackBar(
  //                           reason: SnackBarClosedReason.hide);
  //                     },
  //                   ),
  //                   Text(
  //                     "Not at Hash",
  //                     textAlign: TextAlign.center,
  //                     style: const TextStyle(
  //                       fontFamily: 'AvenirNextCondensedDemiBold',
  //                       fontStyle: FontStyle.normal,
  //                       fontSize: 15.0,
  //                       height: 0.7,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             Expanded(
  //               flex: 1,
  //               child: Column(
  //                 mainAxisAlignment: MainAxisAlignment.start,
  //                 children: <Widget>[
  //                   IconButton(
  //                     icon: Image.asset(
  //                       'images/icons/runner_icon.png',
  //                       height: 30.0,
  //                       width: 30.0,
  //                       color: packList[index].requestedAttendenceState != -1
  //                           ? Colors.blue
  //                           : ((packList[index].attendenceState ==
  //                                       attendenceAtHash.value) &&
  //                                   (packList[index].rsvpState ==
  //                                       rsvpYes.value))
  //                               ? Colors.yellow
  //                               : Colors.white,
  //                     ),

  //                     //tooltip: 'Select to follow a Kennel',
  //                     iconSize: 30.0,
  //                     alignment: Alignment.topCenter,
  //                     splashColor: Colors.greenAccent,
  //                     onPressed: () {
  //                       packScopedModel.setRsvpState(rsvpYes.value, -1,
  //                           attendenceAtHash.value, packList[index]);
  //                       Scaffold.of(context).hideCurrentSnackBar(
  //                           reason: SnackBarClosedReason.hide);
  //                     },
  //                   ),
  //                   Text(
  //                     "At Hash",
  //                     textAlign: TextAlign.center,
  //                     style: const TextStyle(
  //                       fontFamily: 'AvenirNextCondensedDemiBold',
  //                       fontStyle: FontStyle.normal,
  //                       fontSize: 15.0,
  //                       height: 0.7,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             Expanded(
  //               flex: 1,
  //               child: Column(
  //                 mainAxisAlignment: MainAxisAlignment.start,
  //                 children: <Widget>[
  //                   IconButton(
  //                     icon: Image.asset(
  //                       'images/icons/beer_icon.png',
  //                       height: 30.0,
  //                       width: 30.0,
  //                       color: packList[index].requestedAttendenceState != -1
  //                           ? Colors.blue
  //                           : ((packList[index].attendenceState ==
  //                                       attendenceOnIn.value) &&
  //                                   (packList[index].rsvpState ==
  //                                       rsvpYes.value))
  //                               ? Colors.yellow
  //                               : Colors.white,
  //                     ),

  //                     //tooltip: 'Select to follow a Kennel',
  //                     iconSize: 30.0,
  //                     alignment: Alignment.topCenter,
  //                     splashColor: Colors.greenAccent,
  //                     onPressed: () {
  //                       packScopedModel.setRsvpState(rsvpYes.value, -1,
  //                           attendenceOnIn.value, packList[index]);
  //                       Scaffold.of(context).hideCurrentSnackBar(
  //                           reason: SnackBarClosedReason.hide);
  //                     },
  //                   ),
  //                   Text(
  //                     "On In",
  //                     textAlign: TextAlign.center,
  //                     style: const TextStyle(
  //                       fontFamily: 'AvenirNextCondensedDemiBold',
  //                       fontStyle: FontStyle.normal,
  //                       fontSize: 15.0,
  //                       height: 0.7,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //         Padding(
  //           padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
  //           child: Container(color: Colors.white, height: 3.0),
  //         ),
  //         ScopedModelDescendant<PayScopedModel>(
  //           builder:
  //               (BuildContext context, Widget child, PayScopedModel model) {
  //             return Column(children: <Widget>[
  //               Row(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: <Widget>[
  //                   Expanded(
  //                     flex: 1,
  //                     child: Column(
  //                       mainAxisAlignment: MainAxisAlignment.start,
  //                       children: <Widget>[
  //                         IconButton(
  //                           icon: Image.asset('images/icons/payment_type_1.png',
  //                               height: 30.0,
  //                               width: 30.0,
  //                               color: ((packList[index].isPaid == 0) ||
  //                                       (packList[index].paymentType ==
  //                                           paymentNotPaid.value))
  //                                   ? Colors.yellow
  //                                   : Colors.white),

  //                           //tooltip: 'Select to follow a Kennel',
  //                           iconSize: 30.0,
  //                           alignment: Alignment.topCenter,
  //                           splashColor: Colors.greenAccent,
  //                           onPressed: () {
  //                             processPayment(
  //                                 index,
  //                                 packScopedModel,
  //                                 payScopedModel,
  //                                 context,
  //                                 paymentNotPaid.value,
  //                                 0.0);
  //                           },
  //                         ),
  //                         Text(
  //                           "Not paid",
  //                           textAlign: TextAlign.center,
  //                           style: const TextStyle(
  //                             fontFamily: 'AvenirNextCondensedDemiBold',
  //                             fontStyle: FontStyle.normal,
  //                             fontSize: 15.0,
  //                             height: 0.7,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                   Expanded(
  //                     flex: 1,
  //                     child: Column(
  //                       mainAxisAlignment: MainAxisAlignment.start,
  //                       children: <Widget>[
  //                         IconButton(
  //                           icon: Image.asset('images/icons/payment_type_2.png',
  //                               height: 30.0,
  //                               width: 30.0,
  //                               color: packList[index].paymentType ==
  //                                       paymentFreeRun.value
  //                                   ? Colors.yellow
  //                                   : Colors.white),
  //                           //tooltip: 'Select to follow a Kennel',
  //                           iconSize: 30.0,
  //                           alignment: Alignment.topCenter,
  //                           splashColor: Colors.greenAccent,
  //                           onPressed: () {
  //                             processPayment(
  //                                 index,
  //                                 packScopedModel,
  //                                 payScopedModel,
  //                                 context,
  //                                 paymentFreeRun.value,
  //                                 0.0);
  //                           },
  //                         ),
  //                         Text(
  //                           "Free run",
  //                           textAlign: TextAlign.center,
  //                           style: const TextStyle(
  //                             fontFamily: 'AvenirNextCondensedDemiBold',
  //                             fontStyle: FontStyle.normal,
  //                             fontSize: 15.0,
  //                             height: 0.7,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                   Expanded(
  //                     flex: 1,
  //                     child: Column(
  //                       mainAxisAlignment: MainAxisAlignment.start,
  //                       children: <Widget>[
  //                         IconButton(
  //                           icon: Image.asset('images/icons/payment_type_5.png',
  //                               height: 30.0,
  //                               width: 30.0,
  //                               color: ((packList[index].paymentType ==
  //                                           paymentCashOtherAmount.value) ||
  //                                       (packList[index].paymentType ==
  //                                           paymentBankTransferOtherAmount
  //                                               .value))
  //                                   ? Colors.yellow
  //                                   : Colors.white),
  //                           //tooltip: 'Select to follow a Kennel',
  //                           iconSize: 30.0,
  //                           alignment: Alignment.topCenter,
  //                           splashColor: Colors.greenAccent,
  //                           onPressed: () {
  //                             payOther(index, packScopedModel, context);
  //                           },
  //                         ),
  //                         Text(
  //                           "Paid other",
  //                           textAlign: TextAlign.center,
  //                           style: const TextStyle(
  //                             fontFamily: 'AvenirNextCondensedDemiBold',
  //                             fontStyle: FontStyle.normal,
  //                             fontSize: 15.0,
  //                             height: 0.7,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               Container(width: 100, height: 10),
  //               Row(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: <Widget>[
  //                   Expanded(
  //                     flex: 1,
  //                     child: Column(
  //                       mainAxisAlignment: MainAxisAlignment.start,
  //                       children: <Widget>[
  //                         IconButton(
  //                           icon: Image.asset('images/icons/payment_type_3.png',
  //                               height: 30.0,
  //                               width: 30.0,
  //                               color: packList[index].paymentType ==
  //                                       paymentCash.value
  //                                   ? Colors.yellow
  //                                   : Colors.white),
  //                           //tooltip: 'Select to follow a Kennel',
  //                           iconSize: 30.0,
  //                           alignment: Alignment.topCenter,
  //                           splashColor: Colors.greenAccent,
  //                           onPressed: () {
  //                             processPayment(
  //                                 index,
  //                                 packScopedModel,
  //                                 payScopedModel,
  //                                 context,
  //                                 paymentCash.value,
  //                                 packList[index].isMember != 1
  //                                     ? futureRun.eventPriceForNonMembers
  //                                     : futureRun.eventPriceForNonMembers);
  //                           },
  //                         ),
  //                         Text(
  //                           'Paid ${packList[index].isMember != 1 ? nonMemberPrice : memberPrice}\r\ncash',
  //                           textAlign: TextAlign.center,
  //                           style: const TextStyle(
  //                             fontFamily: 'AvenirNextCondensedDemiBold',
  //                             fontStyle: FontStyle.normal,
  //                             fontSize: 15.0,
  //                             height: 0.7,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                   Expanded(
  //                     flex: 1,
  //                     child: Column(
  //                       mainAxisAlignment: MainAxisAlignment.start,
  //                       children: <Widget>[
  //                         IconButton(
  //                           icon: Image.asset('images/icons/payment_type_4.png',
  //                               height: 30.0,
  //                               width: 30.0,
  //                               color: packList[index].paymentType ==
  //                                       paymentBankTransfer.value
  //                                   ? Colors.yellow
  //                                   : Colors.white),
  //                           //tooltip: 'Select to follow a Kennel',
  //                           iconSize: 30.0,
  //                           alignment: Alignment.topCenter,
  //                           splashColor: Colors.greenAccent,
  //                           onPressed: () {
  //                             processPayment(
  //                                 index,
  //                                 packScopedModel,
  //                                 payScopedModel,
  //                                 context,
  //                                 paymentBankTransfer.value,
  //                                 packList[index].isMember != 1
  //                                     ? futureRun.eventPriceForNonMembers
  //                                     : futureRun.eventPriceForNonMembers);
  //                           },
  //                         ),
  //                         Text(
  //                           'Paid ${packList[index].isMember != 1 ? nonMemberPrice : memberPrice}\r\nbank transfer',
  //                           textAlign: TextAlign.center,
  //                           style: const TextStyle(
  //                             fontFamily: 'AvenirNextCondensedDemiBold',
  //                             fontStyle: FontStyle.normal,
  //                             fontSize: 15.0,
  //                             height: 0.7,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                   Expanded(
  //                     flex: 1,
  //                     child: Column(
  //                       mainAxisAlignment: MainAxisAlignment.start,
  //                       children: <Widget>[
  //                         IconButton(
  //                           icon: Image.asset('images/icons/payment_type_6.png',
  //                               height: 30.0,
  //                               width: 30.0,
  //                               color: packList[index].paymentType ==
  //                                       paymentHashCredit.value
  //                                   ? Colors.yellow
  //                                   : Colors.white),
  //                           //tooltip: 'Select to follow a Kennel',
  //                           iconSize: 30.0,
  //                           alignment: Alignment.topCenter,
  //                           splashColor: Colors.greenAccent,
  //                           onPressed: () {
  //                             processPayment(
  //                                 index,
  //                                 packScopedModel,
  //                                 payScopedModel,
  //                                 context,
  //                                 paymentHashCredit.value,
  //                                 packList[index].isMember != 1
  //                                     ? futureRun.eventPriceForNonMembers
  //                                     : futureRun.eventPriceForNonMembers);
  //                           },
  //                         ),
  //                         Text(
  //                           'Credit ${packList[index].isMember != 1 ? nonMemberPrice : memberPrice}\r\n(${packList[index].credit < 0 ? 'Owes' : 'Credit'} ${Utilities.getFormattedMoney(packList[index].credit.abs(), futureRun.digitsAfterDecimal, futureRun.currencySymbol)})',
  //                           textAlign: TextAlign.center,
  //                           style: const TextStyle(
  //                             fontFamily: 'AvenirNextCondensedDemiBold',
  //                             fontStyle: FontStyle.normal,
  //                             fontSize: 15.0,
  //                             height: 0.7,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ]);
  //           },
  //         ),
  //       ],
  //     ),
      
      
      
  //     backgroundColor: Theme.of(context).accentColor,
  //   );
  // }






}

