import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:harrier_central/data/hc3_services/base_service.dart';
import 'package:harrier_central/data/hc3_services/kennels_service.dart';
import 'package:harrier_central/data/hc3_services/payments_service.dart';
import 'package:harrier_central/pages/top_level/future_run_list_page.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/widgets/multiple_choice_popup.dart';

class PaymentIcons extends StatelessWidget {
  const PaymentIcons(this.futureRun, this.stateSetter);

  final RunDetailsAggregate futureRun;
  final Function stateSetter;

  @override
  Widget build(BuildContext context) {
    return paymentIcons(context);
  }

  Widget paymentIcons(BuildContext context) {
    return !showPaymentIcons(futureRun)
        ? Container()
        : Column(
            children: <Widget>[
              Container(
                //padding: const EdgeInsets.only(top: 15.0, bottom: 10.0),
                margin: const EdgeInsets.only(top: 2.0, bottom: 0.0),
                padding: const EdgeInsets.only(top: 7.0, bottom: 0.0),
                height: 1.0,
                color: Colors.grey[300],
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4.0, bottom: 0.0),
                child: Text('Pay for your run with...'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: getPaymentIcons(context),
              ),
            ],
          );
  }

  List<Widget> getPaymentIcons(BuildContext context) {
    final List<Widget> icons = <Widget>[];

    final KennelsModel k = futureRun.kennel;

    Widget w = getPaymentIcon(context, k.kennelPaymentUrl, k.kennelPaymentUrlExpires, k.kennelPaymentScheme, k.kennelPaymentMemberSurcharge, k.kennelPaymentNonMemberSurcharge);
    if (w != null) {
      icons.add(w);
    }

    w = getPaymentIcon(context, k.kennelPaymentUrl2, k.kennelPaymentUrlExpires2, k.kennelPaymentScheme2, k.kennelPaymentMemberSurcharge2, k.kennelPaymentNonMemberSurcharge2);
    if (w != null) {
      icons.add(w);
    }

    w = getPaymentIcon(context, k.kennelPaymentUrl3, k.kennelPaymentUrlExpires3, k.kennelPaymentScheme3, k.kennelPaymentMemberSurcharge3, k.kennelPaymentNonMemberSurcharge3);
    if (w != null) {
      icons.add(w);
    }
    return icons;
  }

  Future<dynamic> showExtrasDialog(BuildContext context, num runOnlyPrice, num extrasPrice) {
    final String runOnlyPriceStr = Utilities.getFormattedMoney(runOnlyPrice, futureRun.extensions.digitsAfterDecimal, futureRun.extensions.currencySymbol);
    final String runPlusExtrasPriceStr = Utilities.getFormattedMoney(runOnlyPrice + extrasPrice, futureRun.extensions.digitsAfterDecimal, futureRun.extensions.currencySymbol);

    final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
      <String, dynamic>{
        'title': 'Run only ($runOnlyPriceStr)',
        'icon': <Widget>[
          Container(),
        ],
        'returnValue': payForRunOnly,
      },
      <String, dynamic>{
        'title': 'Run + ' + futureRun.event.extrasDescription + ' ($runPlusExtrasPriceStr)',
        'icon': <Widget>[
          Container(),
        ],
        'returnValue': payForRunAndExtras
      },
    ];

    final MultipleChoicePopup popup = MultipleChoicePopup(
      title: 'Payment options',
      buttons: buttons,
      cancelButtonTitle: 'Cancel',
    );

    return showDialog<dynamic>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return popup;
        });
  }

  Widget getPaymentIcon(BuildContext context, String url, DateTime urlExpires, String paymentProvider, num memberSurcharge, num nonMemberSurcharge) {
    if ((url == null) || (paymentProvider == null) || (urlExpires == null)) {
      return null;
    }

    if (!url.toLowerCase().startsWith('http')) {
      return null;
    }

    if ((!urlExpires.isBefore(DateTime(2010))) && (urlExpires.isBefore(DateTime.now()))) {
      return null;
    }

    const num imgSize = 70.0;

    Widget w;

    switch (paymentProvider.toLowerCase()) {
      case 'paypal':
        w = Image.asset('images/logos/paypal_logo.png', height: imgSize, width: imgSize);
        break;
      case 'zelle':
        w = Image.asset('images/logos/zelle_logo.png', height: imgSize, width: imgSize);
        break;
      case 'transferwise':
        w = Image.asset('images/logos/transferwise_logo.png', height: imgSize, width: imgSize);
        break;
      case 'venmo':
        w = Image.asset('images/logos/venmo_logo.png', height: imgSize, width: imgSize);
        break;
      case 'tikkie':
        w = Image.asset('images/logos/tikkie_logo.png', height: imgSize, width: imgSize);
        break;
    }

    return GestureDetector(
        onTap: () {
          canLaunch(url).then((bool canLaunch) async {
            if (canLaunch) {
              // OK, we have a good URL, so let's figure out how much the hasher needs to pay

              // start with the extras
              EnumPayForExtras<int> didPayForExtras = payForRunOnly;

              String extrasStr = '';
              num extrasPrice = futureRun.event.eventPriceForExtras ?? 0;
              final num surcharge = (futureRun.extensions.isMember == 0 ? nonMemberSurcharge : memberSurcharge) ?? 0;
              final num eventPrice = (futureRun.extensions.isMember == 0 ? futureRun.event.eventPriceForNonMembers ?? futureRun.kennel.defaultPriceForNonMembers : futureRun.event.eventPriceForMembers ?? futureRun.kennel.defaultPriceForMembers) ?? 0;

              if (extrasPrice > 0) {
                // if there are extras, show the extras dialog
                final dynamic x = await showExtrasDialog(context, eventPrice, extrasPrice);
                if (x == followTypeCancel) {
                  return;
                } else {
                  if (x == payForRunOnly) {
                    // if the user wants to pay only for the run, don't process extras, so set the value to zero
                    extrasPrice = 0;
                  } else {
                    didPayForExtras = payForRunAndExtras;
                  }
                }
              }

              if (extrasPrice > 0) {
                // build the string if we need to
                extrasStr = ' ,and a\r\n' + Utilities.getFormattedMoney(extrasPrice, futureRun.extensions.digitsAfterDecimal, futureRun.extensions.currencySymbol) + ' charge for ${futureRun.event.extrasDescription}';
              }

              final num total = surcharge + eventPrice + extrasPrice;

              // build the other strings for the total price and event prices
              final String totalStr = Utilities.getFormattedMoney(total, futureRun.extensions.digitsAfterDecimal, futureRun.extensions.currencySymbol);
              final String eventPriceStr = Utilities.getFormattedMoney(eventPrice, futureRun.extensions.digitsAfterDecimal, futureRun.extensions.currencySymbol);

              String surchargeStr = '';
              if (surcharge > 0) {
                // if there is a surcharge, build the surcharge string
                surchargeStr = ' ,and a\r\n' + Utilities.getFormattedMoney(surcharge, futureRun.extensions.digitsAfterDecimal, futureRun.extensions.currencySymbol) + ' surcharge for $paymentProvider';
              }

              // show the alert so the user knows how much to pay
              Utilities.showAlert(context, 'Please pay $totalStr', 'Please pay $totalStr, which includes:\r\n\r\n$eventPriceStr for the run$extrasStr$surchargeStr', 'OK', showCancelButton: true, cancelButtonText: 'Cancel').then((bool result) {
                if (result) {
                  // now launch into the payment provider
                  launch(url).then((bool launched) {
                    if (futureRun.kennel.allowSelfPayment == 0) {
                      Utilities.showAlert(context, 'Thank you', 'Please let the Wanker Banker know that you\'ve paid', 'OK').then((bool result2) {});
                    } else {
                      // show the alert so the user knows how much to pay
                      Utilities.showAlert(
                        context,
                        'Were you able to pay?',
                        'Were you able to complete a payment of $totalStr using $paymentProvider',
                        'Yes',
                        showCancelButton: true,
                        cancelButtonText: 'No',
                      ).then((bool result2) {
                        if (result2) {
                          futureRun.extensions.rsvpState = -1;

                          stateSetter(); // call setState on the parent
                          payForEvent(eventPrice + extrasPrice, didPayForExtras, surcharge, paymentProvider).then((List<dynamic> adHocItems) {
                            futureRun.extensions.rsvpState = adHocItems[0]['rsvpState'];
                            futureRun.extensions.isPaid = 1;
                            stateSetter();
                          });
                        } else {
                          Utilities.showAlert(context, 'Please pay for the Hash', 'Please pay the Wanker Banker for your Hash run.', 'OK');
                        }
                      });
                    }
                  });
                }
              });
            } else {
              Utilities.showAlert(context, 'Bad payment URL', 'The payment URL provided by the Kennel is not valid. Please check with the Kennel\'s mismanagement to have them fix the problem.', 'OK');
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: w,
        ));
  }

  bool showPaymentIcons(RunDetailsAggregate futureRun) {
    if ((DateTime.now().isBefore(futureRun.event.eventStartDatetime.subtract(const Duration(days: 7)))) || (DateTime.now().isAfter(futureRun.event.eventStartDatetime.add(const Duration(days: 7))))) {
      return false;
    }

    // if the event is more than 10k away, don't show the payment options
    // TODO(James): Need to test what happens here if user doesn't allow location
    if (futureRun.extensions.distToEvent > 100000) {
      return false;
    }

    if (futureRun.extensions.isPaid != 0) {
      return false;
    }

    // TODO(James): Add filter for distance to event after testing is done so we only pay when we are at an event

    if ((futureRun.kennel.kennelPaymentUrl != null) && (futureRun.kennel.kennelPaymentUrl.toLowerCase().startsWith('http')) && (futureRun.kennel.kennelPaymentUrlExpires.isBefore(DateTime(2010)) || futureRun.kennel.kennelPaymentUrlExpires.isAfter(DateTime.now()))) {
      return true;
    }

    if ((futureRun.kennel.kennelPaymentUrl2 != null) && (futureRun.kennel.kennelPaymentUrl2.toLowerCase().startsWith('http')) && (futureRun.kennel.kennelPaymentUrlExpires2.isBefore(DateTime(2010)) || futureRun.kennel.kennelPaymentUrlExpires2.isAfter(DateTime.now()))) {
      return true;
    }

    if ((futureRun.kennel.kennelPaymentUrl3 != null) && (futureRun.kennel.kennelPaymentUrl3.toLowerCase().startsWith('http')) && (futureRun.kennel.kennelPaymentUrlExpires3.isBefore(DateTime(2010)) || futureRun.kennel.kennelPaymentUrlExpires3.isAfter(DateTime.now()))) {
      return true;
    }

    return false;
  }

  Future<List<dynamic>> payForEvent(num amount, EnumPayForExtras<int> extras, num surcharge, String paymentProvider) async {
    final String hasherId = getStringPref(StringPrefsEnum.userId);
    final PaymentsService paySrv = PaymentsService();
    return paySrv.payForEvent(
      futureRun.event.eventId,
      hasherId,
      GUID_EMPTY,
      paymentBankTransfer.value,
      amount,
      attendenceAtHash.value,
      extras,
      AppDomainType.user,
      surcharge: surcharge,
      paymentProvider: paymentProvider,
    );
  }
}
