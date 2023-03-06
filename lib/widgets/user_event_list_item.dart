// @dart=2.11
import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

class UserEventListItem extends StatelessWidget {
  const UserEventListItem({
    Key key,
    @required this.item,
    @required this.kennelInfo,
    @required this.setAttendenceStateCallback,
  }) : super(key: key);

  final UserRunHistoryResults item;
  final HistoryListResults kennelInfo;
  final Function setAttendenceStateCallback;

  @override
  Widget build(BuildContext context) {
    return _listItem(context);
  }

  Container _listItem(BuildContext context) {
    num netPayment = (item.creditAmount ?? 0) - (item.debitAmount ?? 0);
    Color paymentColor = Colors.green.shade800;
    Color creditAvailableColor = (item.creditAvailable ?? 0) > 0
        ? Colors.green.shade800
        : (item.creditAvailable ?? 0) < 0
            ? Colors.red.shade900
            : Colors.black38;

    bool creditWasUsed = false;

    if (((item.debitAmount ?? 0) > 0) && ((item.creditAmount ?? 0) == 0)) {
      creditWasUsed = true;
    }

    final String amountDue = IveCoreUtilities.getFormattedMoney(item.debitAmount ?? 0, kennelInfo.digitsAfterDecimal, kennelInfo.currencySymbol);

    final String creditAmount = IveCoreUtilities.getFormattedMoney(item.creditAmount ?? 0, kennelInfo.digitsAfterDecimal, kennelInfo.currencySymbol);

    final String creditAvailable = IveCoreUtilities.getFormattedMoney(item.creditAvailable ?? 0, kennelInfo.digitsAfterDecimal, kennelInfo.currencySymbol);

    final String extrasPrice = IveCoreUtilities.getFormattedMoney(item.extrasPrice ?? 0, kennelInfo.digitsAfterDecimal, kennelInfo.currencySymbol);

    return Container(
      margin: const EdgeInsets.only(left: 5, top: 5, bottom: 5),
      width: MediaQuery.of(context).size.width,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            item.isUpdating
                ? Icon(delayIcon, color: Colors.blue[800], size: 35.0)
                : item.attendenceState < attendenceAtHash.value
                    ? const Icon(FontAwesome.times_circle, color: Colors.red, size: 35.0)
                    : item.isHare == isHareNo.value
                        ? const Icon(FontAwesome.check_circle, color: Colors.green, size: 35.0)
                        : const Padding(
                            padding: EdgeInsets.only(left: 2.5, right: 2.5),
                            child: ImageIcon(AssetImage('images/icons/hare_icon.png'), color: Colors.purple, size: 30.0),
                          ),
            const Padding(
              padding: EdgeInsets.only(left: 7.0, right: 3.0),
              child: VerticalDivider(
                thickness: 2.0,
                width: 2.0,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.eventName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black87, fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
                      textAlign: TextAlign.left,
                    ),
                    Text(
                      item.eventStartDatetime.year != DateTime.now().year
                          ? 'Run #${item.eventNumber.toString()} on ${DateFormat("E, MMM d, yyyy 'at' h:mm a").format(item.eventStartDatetime)}'
                          : 'Run #${item.eventNumber.toString()} on ${DateFormat("E, MMM d 'at' h:mm a").format(item.eventStartDatetime)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black87, fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
                      textAlign: TextAlign.left,
                    ),
                    item.attendenceState < attendenceAtHash.value
                        ? Container()
                        : Row(
                            children: <Widget>[
                              Text(
                                'My ${kennelInfo.kennelShortName} run #${(item.totalRunsThisKennel ?? 0) + (kennelInfo?.historicalTotalRunCount ?? 0)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.green[800], fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
                                textAlign: TextAlign.left,
                              ),
                              item.isHare == isHareNo.value
                                  ? Container()
                                  : Text(
                                      ' and #${(item.totalHaringThisKennel ?? 0) + (kennelInfo?.historicalHaringCount ?? 0)} time haring',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.purple[800], fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
                                      textAlign: TextAlign.left,
                                    ),
                            ],
                          ),
                    // Container(
                    //   //padding: const EdgeInsets.only(top: 15.0, bottom: 10.0),
                    //   margin: const EdgeInsets.only(top: 7.0, bottom: 7.0),
                    //   padding: const EdgeInsets.only(top: 7.0, bottom: 7.0),
                    //   height: 1.0,
                    //   color: Colors.grey[800],
                    // ),

                    if ((item.doPayForExtras ?? 0) != 0) ...<Widget>[
                      const SizedBox(height: 5.0),
                      Center(
                        child: Text((item.extrasDescription ?? 'Extra charge: ') + extrasPrice,
                            style: netPayment == 0 ? mediumTextBlack.copyWith(color: paymentColor) : mediumTextBlackBold.copyWith(color: paymentColor)),
                      ),
                    ],

                    if ((item.debitAmount ?? 0) != 0) ...<Widget>[
                      const SizedBox(height: 5.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            flex: 33,
                            child: Column(
                              children: [
                                Text('Run fee', style: netPayment == 0 ? smallTextBlack.copyWith(color: paymentColor) : smallTextBlackBold.copyWith(color: paymentColor)),
                                Text(amountDue, style: netPayment == 0 ? smallTextBlack.copyWith(color: paymentColor) : smallTextBlackBold.copyWith(color: paymentColor)),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 34,
                            child: Column(
                              children: <Widget>[
                                Text(
                                  creditWasUsed ? 'From credit' : 'Paid',
                                  style: netPayment == 0 ? smallTextBlack.copyWith(color: paymentColor) : smallTextBlackBold.copyWith(color: paymentColor),
                                  textScaleFactor: 1.0,
                                ),
                                Text(
                                  creditWasUsed ? amountDue : creditAmount,
                                  style: netPayment == 0 ? smallTextBlack.copyWith(color: paymentColor) : smallTextBlackBold.copyWith(color: paymentColor),
                                  textScaleFactor: 1.0,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 33,
                            child: Column(
                              children: [
                                Text(
                                  'Credit left',
                                  style: netPayment == 0 ? smallTextBlack.copyWith(color: creditAvailableColor) : smallTextBlackBold.copyWith(color: creditAvailableColor),
                                  textScaleFactor: 1.0,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (netPayment != 0) ...<Widget>[
                                      Padding(
                                        padding: const EdgeInsets.only(left: 0.0, bottom: 2.0, right: 3.0),
                                        child: SizedBox(
                                            child: netPayment > 0
                                                ? Icon(
                                                    Fontisto.caret_up,
                                                    color: Colors.green.shade800,
                                                    size: 12.0,
                                                  )
                                                : Icon(
                                                    Fontisto.caret_down,
                                                    color: Colors.red.shade900,
                                                    size: 12.0,
                                                  )),
                                      ),
                                    ],
                                    Text(
                                      creditAvailable,
                                      style: netPayment == 0 ? smallTextBlack.copyWith(color: creditAvailableColor) : smallTextBlackBold.copyWith(color: creditAvailableColor),
                                      textScaleFactor: 1.0,
                                    ),
                                    if (netPayment != 0) ...<Widget>[const SizedBox(width: 3.0)],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 40.0,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if ((G0<AppModel>().connectionStatus == EnumConnectionStatus.connected) && (item.canEditRunAttendence != 0)) ...<Widget>[
              IconButton(
                icon: const Icon(MaterialCommunityIcons.dots_vertical),
                iconSize: Theme.of(context).iconTheme.size,
                color: Colors.black54,
                splashColor: Theme.of(context).highlightColor,
                onPressed: () async {
                  await _showRunAttendencePopup(context);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showRunAttendencePopup(BuildContext context) async {
    if (Connection.checkForConnection(context, G0<AppModel>().connectionStatus, message: 'Setting run options is not available in offline mode. Please connect to the Internet.')) {
      final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
        <String, dynamic>{
          'title': 'I was at this Hash',
          'icon': <Widget>[
            Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            const Icon(FontAwesome.check_circle, color: Colors.green, size: 28.0),
          ],
          'returnValue': 1
        },
        <String, dynamic>{
          'title': 'I was not at this Hash',
          'icon': <Widget>[
            Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            const Icon(FontAwesome.times_circle, color: Colors.red, size: 28.0),
          ],
          'returnValue': 0
        },
        <String, dynamic>{
          'title': 'I hared this Hash',
          'icon': <Widget>[
            Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            const ImageIcon(AssetImage('images/icons/hare_icon.png'), color: Colors.purple, size: 24.0),
          ],
          'returnValue': 2
        },
      ];

      final MultipleChoicePopup popup = MultipleChoicePopup(
        key: const Key('01019395'),
        title: 'Run Options',
        buttons: buttons,
        cancelButtonTitle: 'Cancel',
        cancelButtonReturnValue: followTypeCancel,
      );

      final int retVal = await showDialog<dynamic>(
          context: context,
          barrierDismissible: false, // user must tap button!
          builder: (BuildContext context) {
            return popup;
          });

      switch (retVal) {
        case 0:
          await setAttendenceStateCallback(attendenceNo, isHareNo);
          break;
        case 1:
          await setAttendenceStateCallback(attendenceAtHash, isHareNo);
          break;
        case 2:
          await setAttendenceStateCallback(attendenceAtHash, isHareYes);
          break;
      }
    }
  }
}
