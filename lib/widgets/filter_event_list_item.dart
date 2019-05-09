import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:intl/intl.dart';

import 'package:harrier_central/pages/run_admin/run_admin_main.dart';
import 'package:harrier_central/util/styles.dart';

class FilterEventListItem extends StatelessWidget {
  const FilterEventListItem({@required this.event, @required this.kennelShortName, @required this.updateEvent});

  final Map<String, dynamic> event;
  final String kennelShortName;
  final Function updateEvent;

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

  //   MaterialPageRoute<dynamic>(
  //   builder: (BuildContext context) => RunAdminMainPage(
  //         eventId: futureRun.eventId
  //       ),
  // ),

  Widget listItem(BuildContext context) {
    return GestureDetector(
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            (event['eventFacebookId']?.length ?? 0) > 2
                ? event['canEditRunAttendence'] == -2 || event['canEditRunAttendence'] == -3 ? Icon(delayIcon, size: 35.0, color: Colors.blue) : Icon(FontAwesome.facebook_square, color: event['isVisible'] == 1 ? const Color.fromARGB(255, 59, 89, 152) : Colors.grey, size: 35.0)
                : event['canEditRunAttendence'] == -2 || event['canEditRunAttendence'] == -3
                    ? Icon(delayIcon, size: 35.0, color: Colors.blue)
                    : Container(
                        foregroundDecoration: event['isVisible'] == 1
                            ? const BoxDecoration()
                            : const BoxDecoration(
                                color: Colors.grey,
                                backgroundBlendMode: BlendMode.saturation,
                              ),
                        child: Opacity(opacity: event['isVisible'] == 1 ? 1.0 : 0.5, child: Image.asset('images/other/hc_app_icon.png', height: 35, width: 35)),
                      ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
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
                      DateTime.parse(event['eventStartDatetime']).year != DateTime.now().year
                          ? 'Run #${event['eventNumber'].toString()} on ${DateFormat("E, MMM d, yyyy \'at\' h:mm a").format(DateTime.parse(event['eventStartDatetime']))}'
                          : 'Run #${event['eventNumber'].toString()} on ${DateFormat("E, MMM d \'at\' h:mm a").format(DateTime.parse(event['eventStartDatetime']))}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: event['isVisible'] == 1 ? Colors.black87 : Colors.grey, fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 18.0, height: 0.85),
                      textAlign: TextAlign.left,
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
      ),
    );
  }
}
