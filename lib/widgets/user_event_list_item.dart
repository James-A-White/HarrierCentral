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
    // const num textWidth = 55.0;

    // const TextStyle numberStyle = TextStyle(
    //   fontFamily: 'AvenirNextCondensedDemiBold',
    //   fontStyle: FontStyle.normal,
    //   fontSize: 22.0,
    // );

    return listItem(context);
  }

  Container listItem(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 5, top: 5, bottom: 5),
      width: MediaQuery.of(context).size.width,
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
                              'My ${kennelInfo.kennelShortName} run #${item.totalRunsThisKennel + kennelInfo.historicalTotalRunCount}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.green[800], fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
                              textAlign: TextAlign.left,
                            ),
                            item.isHare == isHareNo.value
                                ? Container()
                                : Text(
                                    ' and #${item.totalHaringThisKennel + kennelInfo.historicalHaringCount} time haring',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.purple[800], fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
                                    textAlign: TextAlign.left,
                                  ),
                          ],
                        ),
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
          // Container(
          //   //padding: const EdgeInsets.only(top: 15.0, bottom: 10.0),
          //   margin: const EdgeInsets.only(top: 7.0, bottom: 7.0),
          //   padding: const EdgeInsets.only(top: 7.0, bottom: 7.0),
          //   height: 1.0,
          //   color: Colors.grey[800],
          // ),
        ],
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
