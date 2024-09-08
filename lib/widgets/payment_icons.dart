import 'package:harrier_central/imports.dart';

class PaymentIcons extends StatelessWidget {
  const PaymentIcons(
    this.event,
    this.kennel,
    this.digitsAfterDecimal,
    this.currencySymbol,
    this.distancePreference,
    this.distToEvent,
    this.paymentLinkUrl,
    this.rsvpState,
    this.isMember,
    this.isPaid,
    this.showHairlineDivider,
    this.stateSetter, {
    super.key,
  });

  final EventModel event;
  final KennelsModel kennel;
  final int digitsAfterDecimal;
  final String currencySymbol;
  final int distancePreference;
  final num? distToEvent;
  final String? paymentLinkUrl;
  final int rsvpState;
  final int isMember;
  final int isPaid;
  final bool showHairlineDivider;
  final Function stateSetter;

  static int daysToDisplayPaymentIcons = 1;
  static int distanceToDisplayPaymentIcons = 50; // in kilometers

  @override
  Widget build(BuildContext context) {
    return paymentIcons(context);
  }

  Widget paymentIcons(BuildContext context) {
    return !showPaymentIcons()
        ? Container()
        : showHairlineDivider
            ? Column(
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
              )
            : Column(
                children: <Widget>[
                  const FancyDivider(
                    key: Key('9818283'),
                    innerColor: Colors.white,
                    topMargin: 40.0,
                    bottomMargin: 10.0,
                  ),
                  Text('Payment', style: ts_headingLarge),
                  const SizedBox(
                    height: 20,
                  ),
                  Stack(
                    alignment: AlignmentDirectional.center,
                    children: <Widget>[
                      Container(
                        height: 120,
                        padding: const EdgeInsets.all(10.0),
                        margin: const EdgeInsets.only(left: 30, right: 30),
                        decoration: BoxDecoration(
                          color: Colors.yellow[100],
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 80.0),
                        child: Text('Pay for your run with...'),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 28.0, left: 30, right: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: getPaymentIcons(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                ],
              );
  }

  List<Widget> getPaymentIcons(BuildContext context) {
    final List<Widget> icons = <Widget>[];

    final KennelsModel k = kennel;

    Widget? w = _getPaymentIcon(
      context,
      k.kennelPaymentUrl,
      k.kennelPaymentUrlExpires,
      k.kennelPaymentScheme,
      k.kennelPaymentMemberSurcharge,
      k.kennelPaymentNonMemberSurcharge,
    );
    if (w != null) {
      icons.add(w);
    }

    w = _getPaymentIcon(
      context,
      k.kennelPaymentUrl2,
      k.kennelPaymentUrlExpires2,
      k.kennelPaymentScheme2,
      k.kennelPaymentMemberSurcharge2,
      k.kennelPaymentNonMemberSurcharge2,
    );
    if (w != null) {
      icons.add(w);
    }

    w = _getPaymentIcon(
      context,
      k.kennelPaymentUrl3,
      k.kennelPaymentUrlExpires3,
      k.kennelPaymentScheme3,
      k.kennelPaymentMemberSurcharge3,
      k.kennelPaymentNonMemberSurcharge3,
    );
    if (w != null) {
      icons.add(w);
    }
    return icons;
  }

  Future<dynamic> showExtrasDialog(BuildContext context, num runOnlyPrice, num extrasPrice) {
    final String runOnlyPriceStr = IveCoreUtilities.getFormattedMoney(runOnlyPrice, digitsAfterDecimal, currencySymbol);
    final String runPlusExtrasPriceStr = IveCoreUtilities.getFormattedMoney(runOnlyPrice + extrasPrice, digitsAfterDecimal, currencySymbol);

    final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
      <String, dynamic>{
        'title': 'Run only ($runOnlyPriceStr)',
        'icon': <Widget>[
          Container(),
        ],
        'returnValue': payForRunOnly,
      },
      <String, dynamic>{
        'title': 'Run + ${event.extrasDescription} ($runPlusExtrasPriceStr)',
        'icon': <Widget>[
          Container(),
        ],
        'returnValue': payForRunAndExtras
      },
    ];

    final MultipleChoicePopup popup = MultipleChoicePopup(
      key: const Key('6610393912'),
      title: 'Payment options',
      buttons: buttons,
      cancelButtonTitle: 'Cancel',
      cancelButtonReturnValue: followTypeCancel,
    );

    return showDialog<dynamic>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return popup;
        });
  }

  Widget? _getPaymentIcon(
    BuildContext context,
    String? url,
    DateTime? urlExpires,
    String? paymentProvider,
    double? memberSurcharge,
    double? nonMemberSurcharge,
  ) {
    if ((url == null) || (paymentProvider == null) || (urlExpires == null)) {
      return null;
    }

    if (!url.toLowerCase().startsWith('http')) {
      return null;
    }

    if (((!urlExpires.isBefore(DateTime(2010))) && (urlExpires.isBefore(DateTime.now())))) {
      return null;
    }

    const double imgSize = 70.0;

    Widget? w;

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

    return (w == null)
        ? const SizedBox()
        : GestureDetector(
            onTap: () async {
              // temporarily replace the payment value token (if one exists) with a number
              // just so we can get a valid URL for testing. This will not be the actual value
              // sent to the bank, that is done lower down in this method once we've calculated
              // the total amount to be paid.
              // final String modifiedUrl = url.replaceAll('/<payment amount>', '');

              // FUCK ANDRIOD - canLaunch doesn't work properly on Android, so I'm commenting it out for now
              // canLaunch(modifiedUrl).then((bool canLaunch) async {
              //   if (canLaunch) {
              // OK, we have a good URL, so let's figure out how much the hasher needs to pay

              // start with the extras
              EnumPayForExtras<int> didPayForExtras = payForRunOnly;

              String extrasStr = '';
              num extrasPrice = event.eventPriceForExtras ?? 0;
              final double surcharge = (isMember == 0 ? nonMemberSurcharge : memberSurcharge) ?? 0.0;
              final double eventPrice = (isMember == 0.0 ? event.eventPriceForNonMembers ?? kennel.defaultPriceForNonMembers : event.eventPriceForMembers ?? kennel.defaultPriceForMembers);

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
                extrasStr = ' ,and a\r\n${IveCoreUtilities.getFormattedMoney(extrasPrice, digitsAfterDecimal, currencySymbol)} charge for ${event.extrasDescription}';
              }

              final num total = surcharge + eventPrice + extrasPrice;

              // build the other strings for the total price and event prices
              final String totalStr = IveCoreUtilities.getFormattedMoney(total, digitsAfterDecimal, currencySymbol);
              final String eventPriceStr = IveCoreUtilities.getFormattedMoney(eventPrice, digitsAfterDecimal, currencySymbol);

              String surchargeStr = '';
              if (surcharge > 0) {
                // if there is a surcharge, build the surcharge string
                surchargeStr = ' ,and a\r\n${IveCoreUtilities.getFormattedMoney(surcharge, digitsAfterDecimal, currencySymbol)} surcharge for $paymentProvider';
              }

              // show the alert so the user knows how much to pay
              final bool? result = await Utilities.showAlert(
                'Please pay $totalStr',
                'Please pay $totalStr, which includes:\r\n\r\n$eventPriceStr for the run$extrasStr$surchargeStr',
                'OK',
                showCancelButton: true,
                cancelButtonText: 'Cancel',
              );

              if (result ?? false) {
                // now launch into the payment provider
                await launchUrl(Uri.parse(url.replaceAll('<payment amount>', total.toString().replaceAll(',', '.'))), mode: LaunchMode.externalApplication);
                if ((kennel.allowSelfPayment & selfPaymentAutoPayAfterBankTransfer) == selfPaymentAutoPayAfterBankTransfer) {
                  // show the alert so the user knows how much to pay
                  final bool? result2 = await Utilities.showAlert(
                    'Were you able to pay?',
                    'Were you able to complete a payment of $totalStr using $paymentProvider',
                    'Yes',
                    showCancelButton: true,
                    cancelButtonText: 'No',
                  );
                  if (result2 ?? false) {
                    //rsvpState = -1;
                    stateSetter(-1, -1); // call setState on the parent
                    final List<dynamic> adHocItems = await payForEvent(eventPrice + extrasPrice, didPayForExtras, surcharge, paymentProvider);
                    // rsvpState = adHocItems[0]['rsvpState'];
                    // isPaid = 1;
                    stateSetter(adHocItems[0]['rsvpState'], 1);
                  } else {
                    await Utilities.showAlert('Please pay for the Hash', 'Please pay the Wanker Banker for your Hash run.', 'OK');
                  }
                } else {
                  await Utilities.showAlert('Thank you', 'Please let the Wanker Banker know that you\'ve paid', 'OK');
                }
              }
              // } else {
              //   await Utilities.showAlert(navigatorKey.currentContext, 'Bad payment URL',
              //       'The payment URL provided by the Kennel is not valid. Please check with the Kennel\'s mismanagement to have them fix the problem.', 'OK');
              // }
              //});
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: w,
            ),
          );
  }

  bool showPaymentIcons() {
    // if (event.eventStartDatetime == null) {
    //   return false;
    // }
    if ((DateTime.now().isBefore(event.eventStartDatetime.subtract(Duration(days: daysToDisplayPaymentIcons)))) ||
        (DateTime.now().isAfter(event.eventStartDatetime.add(Duration(days: daysToDisplayPaymentIcons))))) {
      return false;
    }

    // if the event is more than 10k away, don't show the payment options
    // TODO(James): Need to test what happens here if user doesn't allow location
    if ((distToEvent == null) || (distToEvent! > distanceToDisplayPaymentIcons * 1000)) {
      return false;
    }

    if (isPaid != 0) {
      return false;
    }

    // TODO(James): Add filter for distance to event after testing is done so we only pay when we are at an event

    if ((kennel.kennelPaymentUrl != null) &&
        (kennel.kennelPaymentUrlExpires != null) &&
        (kennel.kennelPaymentUrl!.toLowerCase().startsWith('http')) &&
        (kennel.kennelPaymentUrlExpires!.isBefore(DateTime(2010)) || kennel.kennelPaymentUrlExpires!.isAfter(DateTime.now()))) {
      return true;
    }

    if ((kennel.kennelPaymentUrl2 != null) &&
        (kennel.kennelPaymentUrlExpires2 != null) &&
        (kennel.kennelPaymentUrl2!.toLowerCase().startsWith('http')) &&
        (kennel.kennelPaymentUrlExpires2!.isBefore(DateTime(2010)) || kennel.kennelPaymentUrlExpires2!.isAfter(DateTime.now()))) {
      return true;
    }

    if ((kennel.kennelPaymentUrl3 != null) &&
        (kennel.kennelPaymentUrlExpires3 != null) &&
        (kennel.kennelPaymentUrl3!.toLowerCase().startsWith('http')) &&
        (kennel.kennelPaymentUrlExpires3!.isBefore(DateTime(2010)) || kennel.kennelPaymentUrlExpires3!.isAfter(DateTime.now()))) {
      return true;
    }

    return false;
  }

  Future<List<dynamic>> payForEvent(double amount, EnumPayForExtras<int> extras, double surcharge, String paymentProvider) async {
    final String hasherId = getStringPref(StringPrefsEnum.userId)!;
    final PaymentsService paySrv = PaymentsService();
    return paySrv.payForEvent(
      event.eventId,
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
