// @dart=2.11
import 'package:harrier_central/imports.dart';

class ConfirmAutoCheckinPopup extends StatefulWidget {
  const ConfirmAutoCheckinPopup({
    Key key,
    @required this.title,
    @required this.kennelLogo,
    @required this.eventName,
    @required this.eventImage,
    @required this.cancelButtonTitle,
    @required this.okButtonTitle,
    @required this.kennelShortName,
    @required this.eventNumber,
    @required this.kennelCredit,
    @required this.eventPrice,
    @required this.extrasCost,
    @required this.extrasDescription,
    @required this.currencySymbol,
    @required this.digitsAfterDecimal,
  }) : super(key: key);

  final String title;
  final String kennelLogo;
  final String eventName;
  final String eventImage;
  final String cancelButtonTitle;
  final String okButtonTitle;
  final String kennelShortName;
  final num eventNumber;
  final num kennelCredit;
  final num eventPrice;
  final num extrasCost;
  final String extrasDescription;
  final int digitsAfterDecimal;
  final String currencySymbol;

  @override
  _ConfirmAutoCheckinPopupState createState() => _ConfirmAutoCheckinPopupState();
}

class _ConfirmAutoCheckinPopupState extends State<ConfirmAutoCheckinPopup> {
  final FocusNode myFocusNodeFirstName = FocusNode();
  TextEditingController followKennelAmountTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      //title: Text(widget.title),
      contentPadding: const EdgeInsets.fromLTRB(14, 20, 14, 10),
      content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        CachedNetworkImage(
          height: 120.0,
          imageUrl: widget.eventImage ?? widget.kennelLogo,
          // errorWidget:
          //     (BuildContext context, String url, Exception error) =>
          //         const  Icon(Icons.error),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 15.0, bottom: 5.0),
          child: ((widget.eventNumber != null) && (widget.eventNumber != 0))
              ? Text(
                  'Would you like to check in to ${widget.kennelShortName}\'s ${widget.eventName} (Run #${widget.eventNumber})',
                )
              : Text(
                  'Would you like to check in to ${widget.kennelShortName}\'s ${widget.eventName}',
                ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              TextButton(
                style: TextButton.styleFrom(backgroundColor: Colors.red),
                child: Text(widget.cancelButtonTitle),
                onPressed: () {
                  Navigator.of(context).pop(enumCheckInOption_Cancel);
                },
              ),
              TextButton(
                style: TextButton.styleFrom(backgroundColor: Colors.green.shade700),
                child: Text(widget.eventPrice <= widget.kennelCredit ? 'Check in only' : widget.okButtonTitle),
                onPressed: () {
                  Navigator.of(context).pop(enumCheckInOption_Yes);
                },
              ),
            ],
          ),
        ),
        if (widget.eventPrice <= widget.kennelCredit) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              children: <Widget>[
                Text(
                    'You have ${IveCoreUtilities.getFormattedMoney(widget.kennelCredit ?? 0, widget.digitsAfterDecimal, widget.currencySymbol)} of Hash Credit remaining. Would you like to pay ${IveCoreUtilities.getFormattedMoney(widget.eventPrice ?? 0, widget.digitsAfterDecimal, widget.currencySymbol)} from credit for this run?'),
                TextButton(
                  style: TextButton.styleFrom(backgroundColor: Colors.green.shade700),
                  child: const Text('Pay for run with credit'),
                  onPressed: () {
                    Navigator.of(context).pop(enumCheckInOption_YesAndPay);
                  },
                ),
              ],
            ),
          ),
        ],
        if ((widget.extrasCost > 0) && ((widget.eventPrice + widget.extrasCost) <= widget.kennelCredit)) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              children: <Widget>[
                Text(
                    'You have ${IveCoreUtilities.getFormattedMoney(widget.kennelCredit ?? 0, widget.digitsAfterDecimal, widget.currencySymbol)} of Hash Credit remaining. Would you like to pay ${IveCoreUtilities.getFormattedMoney(widget.eventPrice ?? 0, widget.digitsAfterDecimal, widget.currencySymbol)} for the run and ${IveCoreUtilities.getFormattedMoney(widget.extrasCost ?? 0, widget.digitsAfterDecimal, widget.currencySymbol)} for the ${widget.extrasDescription} from credit?'),
                TextButton(
                  style: TextButton.styleFrom(backgroundColor: Colors.green.shade700),
                  child: Text('Pay for run and ${widget.extrasDescription} with credit'),
                  onPressed: () {
                    Navigator.of(context).pop(enumCheckInOption_YesAndPayPlusExtras);
                  },
                ),
              ],
            ),
          ),
        ],
      ]

          //  <Widget>[

          // ],
          ),
      // actions: <Widget>[
      //   // Padding(
      //   //   padding: const EdgeInsets.only(right: 0.0),
      //   //   child: Container(
      //   //     width: 60.0,
      //   //     child:

      //   TextButton(
      //     color: Colors.red,
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

  //   for (Map<String, dynamic> btnDef in widget.buttons) {
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
  //             //padding: EdgeInsets.only(top: 6.0 * G0<DeviceInfo>().deviceHeightScaleFactor, left: 8.0, bottom: 6.0 * G0<DeviceInfo>().deviceHeightScaleFactor),
  //             color: Colors.blue[900],
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
  //     TextButton(
  //       color: Colors.red,
  //       child: Text(widget.cancelButtonTitle),
  //       textColor: Colors.white,
  //       onPressed: () {
  //         Navigator.of(context).pop(followTypeCancel);
  //       },
  //     ),
  //   );
  //   return buttons;
  // }
}
