import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:intl/intl.dart';

import 'package:harrier_central/pages/run_admin/run_admin_main.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/widgets/multiple_choice_popup.dart';

class FilterEventListItem extends StatelessWidget {
  const FilterEventListItem({@required this.event, @required this.kennelShortName, @required this.updateEvent});

  final Map<String, dynamic> event;
  final String kennelShortName;
  final Function updateEvent;

  

  @override
  Widget build(BuildContext context) {
    const double iconSize = 45;
    return  GestureDetector(
      onTap: () {
        Navigator.push<void>(
          context,
          MaterialPageRoute<num>(

            

            builder: (BuildContext context) => RunAdminMainPage(eventId: event['eventId']),
          ),
        ).then((void dummy) {
          //updateEvent(value);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(left: 5, top: 5, bottom: 5),
        width: MediaQuery.of(context).size.width,
        height: 70,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            (event['eventFacebookId']?.length ?? 0) > 2
                ? event['canEditRunAttendence'] == -2 || event['canEditRunAttendence'] == -3 ? Icon(delayIcon, size: iconSize, color: Colors.blue) : Icon(FontAwesome.facebook_square, color: event['isVisible'] == 1 ? const Color.fromARGB(255, 59, 89, 152) : Colors.grey, size: iconSize)
                : event['canEditRunAttendence'] == -2 || event['canEditRunAttendence'] == -3
                    ? Icon(delayIcon, size: iconSize, color: Colors.blue)
                    : Container(
                        foregroundDecoration: event['isVisible'] == 1
                            ? const BoxDecoration()
                            : const BoxDecoration(
                                color: Colors.grey,
                                backgroundBlendMode: BlendMode.saturation,
                              ),
                        child: Opacity(opacity: event['isVisible'] == 1 ? 1.0 : 0.5, child: Image.asset('images/other/hc_app_icon.png', height: iconSize, width: iconSize)),
                      ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${event['eventName']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: event['isVisible'] == 1 ? Colors.black87 : Colors.grey, fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 18.0, height: 0.85),
                      textAlign: TextAlign.left,
                    ),
                    Text(
                      '${DateTime.parse(event['eventStartDatetime']).year != DateTime.now().year ? DateFormat("E, MMM d, yyyy \'at\' h:mm a").format(DateTime.parse(event['eventStartDatetime'])) : DateFormat("E, MMM d \'at\' h:mm a").format(DateTime.parse(event['eventStartDatetime']))}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: event['isVisible'] == 1 ? Colors.black87 : Colors.grey, fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 18.0, height: 0.85),
                      textAlign: TextAlign.left,
                    ),
                    ((event['isVisible'] == 1) && (event['isCountedRun'] == 1))
                        ? Text.rich(
                            TextSpan(
                              text: 'Run ',
                              children: <TextSpan>[
                                TextSpan(
                                  text: '#${event['eventNumber'].toString()}', 
                                  style:TextStyle(fontFamily: 'AvenirNextCondensedBold',
                                    decoration: ((event['absoluteEventNumber'] ?? 0) >= 1) ? TextDecoration.underline :TextDecoration.none)
                                ),
                              ],
                            ),
                            style: TextStyle(color: event['isVisible'] == 1 ? Colors.black87 : Colors.grey, fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 18.0, height: 0.85),
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

                  final List<Map<String, dynamic>> buttons = <Map<String,dynamic>>[
                    <String, dynamic>{
                      'title': event['isVisible'] == 0 ? 'Show Event' : 'Hide Event',
                      'icon': <Widget>[
                        Container(
                          height: 30,
                          width: 30,
                          child: Icon(event['isVisible'] == 0 ? Ionicons.md_eye : Ionicons.md_eye_off, color: Colors.yellow),
                        ),
                      ],
                      'returnValue': event['isVisible'] == 0 ? eventFilterType_showEvent : eventFilterType_hideEvent,
                    },
                    <String, dynamic>{
                      'title': event['isCountedRun'] == 0 ? 'Count Run' : 'Don\'t Count Run',
                      'icon': <Widget>[
                        Container(
                          height: 30,
                          width: 30,
                          child: Icon(event['isCountedRun'] == 0 ? MaterialCommunityIcons.pencil : MaterialCommunityIcons.pencil_off, color: Colors.blue[200]),
                        ),
                      ],
                      'returnValue': event['isCountedRun'] == 0 ? eventFilterType_countEvent : eventFilterType_doNotCountEvent,
                    },
                    <String, dynamic>{
                      'title': 'Set run number',
                      'icon': <Widget>[
                        Container(
                          height: 30,
                          width: 30,
                          child: Icon(FontAwesome.hashtag, color: Colors.red[200]),
                        ),
                      ],
                      'returnValue': eventFilterType_setRunNumber,
                    },
                  ];

                  final MultipleChoicePopup popup = MultipleChoicePopup(
                      title: 'Set event details',
                      buttons: buttons,
                      cancelButtonTitle: 'Cancel',
                      buttonPress: (dynamic retVal) {
                        updateEvent(retVal);
                      });

                  showDialog<void>(
                      context: context,
                      barrierDismissible: false, // user must tap button!
                      builder: (BuildContext context) {
                        return popup;
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
