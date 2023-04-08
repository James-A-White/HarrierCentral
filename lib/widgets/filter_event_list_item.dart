import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

class FilterEventListItem extends StatelessWidget {
  const FilterEventListItem({
    Key? key,
    required this.event,
    required this.kennelShortName,
    required this.updateEvent,
  }) : super(key: key);

  final LiteEventModel event;
  final String kennelShortName;
  final Function updateEvent;

  @override
  Widget build(BuildContext context) {
    final double iconSize = 45 * G0<DeviceInfo>().deviceWidthScaleFactor;
    return GestureDetector(
      onTap: () async {
        await Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) => RunAdminPage(eventId: event.eventId),
          ),
        );
        await updateEvent(eventFilterType_refreshOnly);
      },
      child: Container(
        margin: const EdgeInsets.only(left: 5, top: 5, bottom: 5),
        width: MediaQuery.of(context).size.width,
        height: 70,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            event.canEditRunAttendance == -2 || event.canEditRunAttendance == -3
                ? Icon(delayIcon, size: iconSize, color: Colors.blue)
                : Container(
                    foregroundDecoration: event.isVisible == 1
                        ? const BoxDecoration()
                        : const BoxDecoration(
                            color: Colors.grey,
                            backgroundBlendMode: BlendMode.saturation,
                          ),
                    child: Opacity(
                      opacity: event.isVisible == 1 ? 1.0 : 0.5,
                      child: Stack(
                        children: <Widget>[
                          Image.asset(
                            (event.eventInboundIntegrationId ?? 0) <= 2 ? 'images/icons/integration_icon_${event.eventInboundIntegrationId}.png' : 'images/icons/integration_icon_x.png',
                            height: iconSize,
                            width: iconSize,
                          ),
                          if ((event.eventInboundIntegrationId ?? 0) > 2) ...<Widget>[
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 2.5,
                              child: Text(
                                event.eventInboundIntegrationId == 5
                                    ? 'Berlin Website'
                                    : event.eventInboundIntegrationId == 3
                                        ? 'San\r\nDiego'
                                        : 'External Source',
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                style: const TextStyle(
                                  fontFamily: 'AvenirNextBold',
                                  height: 1.0,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10.0,
                                ),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      event.eventName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: event.isVisible == 1 ? Colors.black87 : Colors.grey,
                          fontFamily: 'AvenirNextCondensedDemiBold',
                          fontStyle: FontStyle.normal,
                          fontSize: 14.0 * G0<DeviceInfo>().deviceWidthScaleFactor,
                          height: 1.0),
                      textAlign: TextAlign.left,
                    ),
                    Text(
                      event.eventStartDatetime.year != DateTime.now().year
                          ? DateFormat("E, MMM d, yyyy 'at' h:mm a").format(event.eventStartDatetime)
                          : DateFormat("E, MMM d 'at' h:mm a").format(event.eventStartDatetime),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: event.isVisible == 1 ? Colors.black87 : Colors.grey,
                          fontFamily: 'AvenirNextCondensedDemiBold',
                          fontStyle: FontStyle.normal,
                          fontSize: 14.0 * G0<DeviceInfo>().deviceWidthScaleFactor,
                          height: 1.0),
                      textAlign: TextAlign.left,
                    ),
                    ((event.isVisible == 1) && (event.isCountedRun == 1))
                        ? Text.rich(
                            TextSpan(
                              text: 'Run ',
                              children: <TextSpan>[
                                TextSpan(
                                    text: '#${event.eventNumber.toString()}',
                                    style: TextStyle(fontFamily: 'AvenirNextCondensedBold', decoration: ((event.absoluteEventNumber ?? 0) >= 1) ? TextDecoration.underline : TextDecoration.none)),
                              ],
                            ),
                            style: TextStyle(
                                color: event.isVisible == 1 ? Colors.black87 : Colors.grey,
                                fontFamily: 'AvenirNextCondensedDemiBold',
                                fontStyle: FontStyle.normal,
                                fontSize: 14.0 * G0<DeviceInfo>().deviceWidthScaleFactor,
                                height: 1.0),
                            textAlign: TextAlign.left,
                          )
                        : Container()
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(MaterialCommunityIcons.dots_vertical),
                iconSize: Theme.of(context).iconTheme.size,
                color: Colors.black54,
                splashColor: Theme.of(context).highlightColor,
                onPressed: () {
                  //

                  final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
                    <String, dynamic>{
                      'title': event.isVisible == 0 ? 'Show Event' : 'Hide Event',
                      'icon': <Widget>[
                        SizedBox(
                          height: 30,
                          width: 30,
                          child: Icon(event.isVisible == 0 ? Ionicons.md_eye : Ionicons.md_eye_off, color: Colors.yellow),
                        ),
                      ],
                      'returnValue': event.isVisible == 0 ? eventFilterType_showEvent : eventFilterType_hideEvent,
                    },
                    <String, dynamic>{
                      'title': event.isCountedRun == 0 ? 'Count Run' : 'Don\'t Count Run',
                      'icon': <Widget>[
                        SizedBox(
                          height: 30,
                          width: 30,
                          child: Icon(event.isCountedRun == 0 ? MaterialCommunityIcons.pencil : MaterialCommunityIcons.pencil_off, color: Colors.blue[200]),
                        ),
                      ],
                      'returnValue': event.isCountedRun == 0 ? eventFilterType_countEvent : eventFilterType_doNotCountEvent,
                    },
                    <String, dynamic>{
                      'title': 'Set run number',
                      'icon': <Widget>[
                        SizedBox(
                          height: 30,
                          width: 30,
                          child: Icon(FontAwesome.hashtag, color: Colors.red.shade200),
                        ),
                      ],
                      'returnValue': eventFilterType_setRunNumber,
                    },
                  ];

                  final MultipleChoicePopup popup = MultipleChoicePopup(
                    key: const Key('771334949'),
                    title: 'Set event details',
                    buttons: buttons,
                    cancelButtonTitle: 'Cancel',
                    cancelButtonReturnValue: followTypeCancel,
                  );

                  showDialog<dynamic>(
                      context: context,
                      barrierDismissible: false, // user must tap button!
                      builder: (BuildContext context) {
                        return popup;
                      }).then((dynamic retVal) {
                    updateEvent(retVal);
                  });
                },
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
      ),
    );
  }
}
