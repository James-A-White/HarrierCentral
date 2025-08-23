import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

class UserEventListItem extends StatelessWidget {
  const UserEventListItem({
    super.key,
    required this.item,
    //required this.kennelInfo,
    required this.setAttendenceStateCallback,
    required this.showCountry,
    required this.showKennel,
    required this.historicalHaringCount,
    required this.historicalTotalRunCount,
  });

  final UserRunHistoryModel item;
  //final RunHistoryModel kennelInfo;
  final Function setAttendenceStateCallback;
  final bool showCountry;
  final bool showKennel;
  final int historicalHaringCount;
  final int historicalTotalRunCount;

  @override
  Widget build(BuildContext context) {
    return _listItem(context);
  }

  Container _listItem(BuildContext context) {
    double netPayment = (item.creditAmount ?? 0) - (item.debitAmount ?? 0);
    Color paymentColor = Colors.green.shade800;
    Color creditAvailableColor =
        (item.creditAvailable ?? 0) > 0
            ? Colors.green.shade800
            : (item.creditAvailable ?? 0) < 0
            ? hc_red
            : Colors.black38;

    bool creditWasUsed = false;

    if (((item.debitAmount ?? 0) > 0) && ((item.creditAmount ?? 0) == 0)) {
      creditWasUsed = true;
    }

    final String amountDue = IveCoreUtilities.getFormattedMoney(
      item.debitAmount ?? 0,
      item.digitsAfterDecimal,
      item.currencySymbol,
    );

    final String creditAmount = IveCoreUtilities.getFormattedMoney(
      item.creditAmount ?? 0,
      item.digitsAfterDecimal,
      item.currencySymbol,
    );

    final String creditAvailable = IveCoreUtilities.getFormattedMoney(
      item.creditAvailable ?? 0,
      item.digitsAfterDecimal,
      item.currencySymbol,
    );

    final String extrasPrice = IveCoreUtilities.getFormattedMoney(
      item.extrasPrice ?? 0,
      item.digitsAfterDecimal,
      item.currencySymbol,
    );

    return Container(
      margin: const EdgeInsets.only(left: 5, top: 5, bottom: 5),
      width: MediaQuery.of(context).size.width,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            item.isUpdating
                ? Icon(delayIcon, color: hc_blue, size: 35.0)
                : item.attendenceState < attendenceAtHash.value
                ? Icon(FontAwesome.times_circle, color: hc_red, size: 35.0)
                : item.isHare == isHareNo.value
                ? const Icon(
                  FontAwesome.check_circle,
                  color: Colors.green,
                  size: 35.0,
                )
                : const Padding(
                  padding: EdgeInsets.only(left: 2.5, right: 2.5),
                  child: ImageIcon(
                    AssetImage('images/icons/hare_icon.png'),
                    color: Colors.purple,
                    size: 30.0,
                  ),
                ),
            if (showCountry) ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 5.0),
                child: Image.asset(
                  'images/flags/${item.flagFile}',
                  height: 28,
                  width: 28,
                ),
              ),
            ],
            if (showKennel) ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 5.0),
                child: KennelLogo(
                  kennelLogoUrl: item.kennelLogo,
                  kennelShortName: item.kennelShortName,
                  logoHeight: 60,
                ),
              ),
            ],
            const Padding(
              padding: EdgeInsets.only(left: 7.0, right: 3.0),
              child: VerticalDivider(thickness: 2.0, width: 2.0),
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
                      style: ts_titleMediumCondensedBlack.copyWith(
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    Text(
                      item.eventStartDatetime.year != DateTime.now().year
                          ? 'Run #${item.eventNumber.toString()} on ${DateFormat("E, MMM d, yyyy 'at' h:mm a").format(item.eventStartDatetime)}'
                          : 'Run #${item.eventNumber.toString()} on ${DateFormat("E, MMM d 'at' h:mm a").format(item.eventStartDatetime)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ts_titleMediumCondensedBlack.copyWith(
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    item.attendenceState < attendenceAtHash.value
                        ? Container()
                        : Row(
                          children: <Widget>[
                            Text(
                              'My ${item.kennelShortName} run #${(item.totalRunsThisKennel ?? 0) + (historicalTotalRunCount)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ts_titleMediumCondensedBlack.copyWith(
                                color: Colors.green.shade800,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            item.isHare == isHareNo.value
                                ? Container()
                                : Text(
                                  ' and #${(item.totalHaringThisKennel ?? 0) + (historicalHaringCount)} time haring',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ts_titleMediumCondensedBlack.copyWith(
                                    color: Colors.purple.shade800,
                                  ),
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
                        child: Text(
                          (item.extrasDescription ?? 'Extra charge: ') +
                              extrasPrice,
                          style:
                              netPayment == 0
                                  ? ts_mediumBlack.copyWith(color: paymentColor)
                                  : ts_mediumBlackBold.copyWith(
                                    color: paymentColor,
                                  ),
                        ),
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
                                Text(
                                  'Run fee',
                                  style:
                                      netPayment == 0
                                          ? ts_smallTextBlackDemiBold.copyWith(
                                            color: paymentColor,
                                          )
                                          : ts_smallTextBlackBold.copyWith(
                                            color: paymentColor,
                                          ),
                                ),
                                Text(
                                  amountDue,
                                  style:
                                      netPayment == 0
                                          ? ts_smallTextBlackDemiBold.copyWith(
                                            color: paymentColor,
                                          )
                                          : ts_smallTextBlackBold.copyWith(
                                            color: paymentColor,
                                          ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 34,
                            child: Column(
                              children: <Widget>[
                                Text(
                                  creditWasUsed ? 'From credit' : 'Paid',
                                  style:
                                      netPayment == 0
                                          ? ts_smallTextBlackDemiBold.copyWith(
                                            color: paymentColor,
                                          )
                                          : ts_smallTextBlackBold.copyWith(
                                            color: paymentColor,
                                          ),
                                ),
                                Text(
                                  creditWasUsed ? amountDue : creditAmount,
                                  style:
                                      netPayment == 0
                                          ? ts_smallTextBlackDemiBold.copyWith(
                                            color: paymentColor,
                                          )
                                          : ts_smallTextBlackBold.copyWith(
                                            color: paymentColor,
                                          ),
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
                                  style:
                                      netPayment == 0
                                          ? ts_smallTextBlackDemiBold.copyWith(
                                            color: creditAvailableColor,
                                          )
                                          : ts_smallTextBlackBold.copyWith(
                                            color: creditAvailableColor,
                                          ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (netPayment != 0) ...<Widget>[
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 0.0,
                                          bottom: 2.0,
                                          right: 3.0,
                                        ),
                                        child: SizedBox(
                                          child:
                                              netPayment > 0
                                                  ? Icon(
                                                    Fontisto.caret_up,
                                                    color:
                                                        Colors.green.shade800,
                                                    size: 12.0,
                                                  )
                                                  : Icon(
                                                    Fontisto.caret_down,
                                                    color: hc_red,
                                                    size: 12.0,
                                                  ),
                                        ),
                                      ),
                                    ],
                                    Text(
                                      creditAvailable,
                                      style:
                                          netPayment == 0
                                              ? ts_smallTextBlackDemiBold
                                                  .copyWith(
                                                    color: creditAvailableColor,
                                                  )
                                              : ts_smallTextBlackBold.copyWith(
                                                color: creditAvailableColor,
                                              ),
                                    ),
                                    if (netPayment != 0) ...<Widget>[
                                      const SizedBox(width: 3.0),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 40.0),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if ((appModel.connectionStatus ==
                    EnumConnectionStatus2.connected) &&
                (item.canEditRunAttendence != 0)) ...<Widget>[
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
    if (Connection2.checkForConnection(
      appModel.connectionStatus,
      message:
          'Setting run options is not available in offline mode. Please connect to the Internet.',
    )) {
      final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
        <String, dynamic>{
          'title': 'I was at this Hash',
          'icon': <Widget>[
            Container(
              height: 30,
              width: 30,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const Icon(
              FontAwesome.check_circle,
              color: Colors.green,
              size: 28.0,
            ),
          ],
          'returnValue': 1,
        },
        <String, dynamic>{
          'title': 'I was not at this Hash',
          'icon': <Widget>[
            Container(
              height: 30,
              width: 30,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            Icon(FontAwesome.times_circle, color: hc_red, size: 28.0),
          ],
          'returnValue': 0,
        },
        <String, dynamic>{
          'title': 'I hared this Hash',
          'icon': <Widget>[
            Container(
              height: 30,
              width: 30,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const ImageIcon(
              AssetImage('images/icons/hare_icon.png'),
              color: Colors.purple,
              size: 24.0,
            ),
          ],
          'returnValue': 2,
        },
      ];

      final MultipleChoicePopupHc popup = MultipleChoicePopupHc(
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
        },
      );

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
