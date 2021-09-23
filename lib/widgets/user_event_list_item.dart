// @dart=2.11
import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

class UserEventListItem extends StatelessWidget {
  const UserEventListItem({@required this.item, @required this.kennelShortName});

  final UserRunHistoryResults item;
  final String kennelShortName;

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
          item.isLoading
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
                    '${item.eventName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black87, fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
                    textAlign: TextAlign.left,
                  ),
                  Text(
                    item.eventStartDatetime.year != DateTime.now().year
                        ? 'Run #${item.eventNumber.toString()} on ${DateFormat("E, MMM d, yyyy \'at\' h:mm a").format(item.eventStartDatetime)}'
                        : 'Run #${item.eventNumber.toString()} on ${DateFormat("E, MMM d \'at\' h:mm a").format(item.eventStartDatetime)}',
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
                              'My $kennelShortName run #${item.totalRunsThisKennel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.green[800], fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
                              textAlign: TextAlign.left,
                            ),
                            item.isHare == isHareNo.value
                                ? Container()
                                : Text(
                                    ' and #${item.totalHaringThisKennel} time haring',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        TextStyle(color: Colors.purple[800], fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
                                    textAlign: TextAlign.left,
                                  ),
                          ],
                        ),
                ],
              ),
            ),
          ),
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
}
