import 'package:harrier_central/imports.dart';

class ConfirmAutoCheckinPopup extends StatefulWidget {
  const ConfirmAutoCheckinPopup({
    super.key,
    required this.title,
    required this.areWeAtRunData,
    required this.cancelButtonTitle,
    required this.okButtonTitle,
  });

  final String title;
  final AreWeAtRunModel areWeAtRunData;
  final String cancelButtonTitle;
  final String okButtonTitle;

  @override
  ConfirmAutoCheckinPopupState createState() => ConfirmAutoCheckinPopupState();
}

// eventPrice: result.membershipExpirationDate.isAfter(DateTime.now()) ? result.memberPrice : result.nonMemberPrice,

class ConfirmAutoCheckinPopupState extends State<ConfirmAutoCheckinPopup> {
  final FocusNode myFocusNodeFirstName = FocusNode();
  TextEditingController followKennelAmountTextController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    double eventPrice =
        0.0 +
        (widget.areWeAtRunData.membershipExpirationDate.isAfter(DateTime.now())
            ? widget.areWeAtRunData.memberPrice
            : widget.areWeAtRunData.nonMemberPrice) -
        widget.areWeAtRunData.discountAmount;

    eventPrice =
        eventPrice * (1.0 - (widget.areWeAtRunData.discountPercent / 100.0));

    return AlertDialog(
      //title: Text(widget.title),
      contentPadding: const EdgeInsets.fromLTRB(14, 20, 14, 10),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CachedNetworkImage(
            height: 120.0,
            imageUrl:
                widget.areWeAtRunData.eventImage ??
                widget.areWeAtRunData.kennelLogo,
            // errorWidget:
            //     (BuildContext context, String url, Exception error) =>
            //         const  Icon(Icons.error),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15.0, bottom: 5.0),
            child: (widget.areWeAtRunData.eventNumber != 0)
                ? Text(
                    (eventPrice <= widget.areWeAtRunData.kennelCredit)
                        ? 'Check in to ${widget.areWeAtRunData.kennelShortName}\'s ${widget.areWeAtRunData.eventName} (Run #${widget.areWeAtRunData.eventNumber})'
                        : 'Would you like to check in to ${widget.areWeAtRunData.kennelShortName}\'s ${widget.areWeAtRunData.eventName} (Run #${widget.areWeAtRunData.eventNumber})',
                  )
                : Text(
                    (eventPrice <= widget.areWeAtRunData.kennelCredit)
                        ? 'Check in to ${widget.areWeAtRunData.kennelShortName}\'s ${widget.areWeAtRunData.eventName}'
                        : 'Would you like to check in to ${widget.areWeAtRunData.kennelShortName}\'s ${widget.areWeAtRunData.eventName}',
                  ),
          ),

          // pay for run only buttons
          if ((eventPrice <= widget.areWeAtRunData.kennelCredit) ||
              ((widget.areWeAtRunData.allowSelfPayment &
                      selfPaymentShowBankButtonOnAutoCheckinDialog) !=
                  0)) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                children: <Widget>[
                  if (eventPrice <=
                      widget.areWeAtRunData.kennelCredit) ...<Widget>[
                    Text(
                      'You have ${IveCoreUtilities.getFormattedMoney(widget.areWeAtRunData.kennelCredit, widget.areWeAtRunData.digitsAfterDecimal, widget.areWeAtRunData.currencySymbol)} of Hash Credit remaining.',
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        shape: button_shape,
                        backgroundColor: Colors.green.shade700,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: Text(
                          'Pay ${IveCoreUtilities.getFormattedMoney(eventPrice, widget.areWeAtRunData.digitsAfterDecimal, widget.areWeAtRunData.currencySymbol)} from Hash Credit',
                          style: ts_button,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop(enumCheckInOption_YesAndPayByCredit);
                      },
                    ),
                  ],
                  if ((widget.areWeAtRunData.allowSelfPayment &
                          selfPaymentShowBankButtonOnAutoCheckinDialog) !=
                      0) ...<Widget>[
                    TextButton(
                      style: TextButton.styleFrom(
                        shape: button_shape,
                        backgroundColor: Colors.green.shade700,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: Text(
                          'Paid ${IveCoreUtilities.getFormattedMoney(eventPrice, widget.areWeAtRunData.digitsAfterDecimal, widget.areWeAtRunData.currencySymbol)} by Bank Transfer',
                          style: ts_button,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop(enumCheckInOption_YesAndPayByBankXfer);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],

          // pay for extras buttons
          if (((widget.areWeAtRunData.extrasCost > 0) &&
                  ((eventPrice + widget.areWeAtRunData.extrasCost) <=
                      widget.areWeAtRunData.kennelCredit)) ||
              ((widget.areWeAtRunData.allowSelfPayment &
                      selfPaymentShowBankButtonOnAutoCheckinDialog) !=
                  0)) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                children: <Widget>[
                  Text(
                    'You can also pay an additional ${IveCoreUtilities.getFormattedMoney(widget.areWeAtRunData.extrasCost, widget.areWeAtRunData.digitsAfterDecimal, widget.areWeAtRunData.currencySymbol)} for ${widget.areWeAtRunData.extrasDescription}',
                  ),
                  if ((widget.areWeAtRunData.extrasCost > 0) &&
                      ((eventPrice + widget.areWeAtRunData.extrasCost) <=
                          widget.areWeAtRunData.kennelCredit)) ...<Widget>[
                    TextButton(
                      style: TextButton.styleFrom(
                        shape: button_shape,
                        backgroundColor: Colors.green.shade700,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: Text(
                          'Pay ${IveCoreUtilities.getFormattedMoney((eventPrice + widget.areWeAtRunData.extrasCost), widget.areWeAtRunData.digitsAfterDecimal, widget.areWeAtRunData.currencySymbol)} from Hash Credit',
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop(enumCheckInOption_YesAndPayPlusExtrasByCredit);
                      },
                    ),
                  ],
                  if ((widget.areWeAtRunData.allowSelfPayment &
                          selfPaymentShowBankButtonOnAutoCheckinDialog) !=
                      0) ...<Widget>[
                    TextButton(
                      style: TextButton.styleFrom(
                        shape: button_shape,
                        backgroundColor: Colors.green.shade700,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: Text(
                          'Paid ${IveCoreUtilities.getFormattedMoney((eventPrice + widget.areWeAtRunData.extrasCost), widget.areWeAtRunData.digitsAfterDecimal, widget.areWeAtRunData.currencySymbol)} by Bank Transfer',
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop(enumCheckInOption_YesAndPayPlusExtrasByBankXfer);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (eventPrice <= widget.areWeAtRunData.kennelCredit) ...<Widget>[
            const Padding(
              padding: EdgeInsets.only(top: 10.0),
              child: Text('Would you like to check in without paying?'),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(
                    shape: button_shape,
                    backgroundColor: hc_red,
                  ),
                  child: Text(widget.cancelButtonTitle),
                  onPressed: () {
                    Navigator.of(context).pop(enumCheckInOption_Cancel);
                  },
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    shape: button_shape,
                    backgroundColor: Colors.green.shade700,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: Text(widget.okButtonTitle),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(enumCheckInOption_Yes);
                  },
                ),
              ],
            ),
          ),
        ],

        //  <Widget>[

        // ],
      ),
      // actions: <Widget>[
      //   // Padding(
      //   //   padding: const EdgeInsets.only(right: 0.0),
      //   //   child: Container(
      //   //     width: 60.0,
      //   //     child:

      //               TextButton(
      //     color:hc_red,
      //     child: const Text('Cancel'),
      //     textColor: Colors.white,
      //     onPressed: () {
      //       Navigator.of(context)
      //           .pop(<String, String>{'type': 'cancel', 'amount': ''});
      //     },
      //   ),

      // ],
    );

    //     Image.network(kennel.kennelLogo,
    //         fit: BoxFit.fitHeight, height: logoHeight),
    // alignment: Alignment.centerRight);
  }

  // List<Widget> getButtons() {
  //   final List<Widget> buttons = <Widget>[];

  //   for (Map<String, dynamic> btnDef in widget.areWeAtRunData.buttons) {
  //     if (btnDef['title'].toString().isEmpty) {
  //       continue;
  //     }
  //     final Widget w = Row(children: <Widget>[
  //       Expanded(
  //         child: GestureDetector(
  //           onTap: () {
  //             Navigator.of(context).pop<dynamic>(btnDef['returnValue']);
  //           },
  //           child: Container(
  //             //padding: EdgeInsets.only(top: 6.0 * deviceInfo.deviceHeightScaleFactor, left: 8.0, bottom: 6.0 * deviceInfo.deviceHeightScaleFactor),
  //             color: hc_blue,
  //             child: Row(children: <Widget>[
  //               const SizedBox(width: 8.0,),
  //               Stack(alignment: AlignmentDirectional.center, children: btnDef['icon']),
  //               Flexible(
  //                 child: Padding(
  //                   padding: const EdgeInsets.only(left: 8.0, top: 16.0, bottom: 10.0),
  //                   child: Text(
  //                     btnDef['title'].toString(),
  //                     maxLines: 5,
  //                     overflow: TextOverflow.ellipsis,
  //                     style: buttonLabelStyleSmall,
  //                   ),
  //                 ),
  //               ),
  //             ]),
  //             //textColor: Colors.white,
  //           ),
  //         ),
  //       )
  //     ]);

  //     buttons.add(w);
  //     buttons.add(const SizedBox(height: 10.0));
  //   }
  //   buttons.add(
  //                 TextButton(
  //       color:hc_red,
  //       child: Text(widget.areWeAtRunData.cancelButtonTitle),
  //       textColor: Colors.white,
  //       onPressed: () {
  //         Navigator.of(context).pop(followTypeCancel);
  //       },
  //     ),
  //   );
  //   return buttons;
  // }
}
