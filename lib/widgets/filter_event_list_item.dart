import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:intl/intl.dart';

import 'package:harrier_central/data_models/lite_event_model.dart';
import 'package:harrier_central/pages/kennel_admin/edit_event_page.dart';

class FilterEventListItem extends StatelessWidget {
  const FilterEventListItem(
      {@required this.eventModel, @required this.kennelShortName, @required this.updateEvent});

  final Event eventModel;
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

  Widget listItem(BuildContext context) {
    return GestureDetector(
      onTap: () {
         Navigator.push<num>(
              context,
              MaterialPageRoute<num>(
                builder: (BuildContext context) =>
                    EditEventPage(eventModel: eventModel),
              ),
            ).then((num value) {
              updateEvent(value);
            });
      },
    
    child: Container(
      margin: const EdgeInsets.only(left: 5, top: 5, bottom: 5),
      width: MediaQuery.of(context).size.width,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          eventModel.isLoading
              ? Icon(FontAwesome.hourglass_2,
                  color: Colors.blue[800], size: 35.0)
              : (eventModel.eventFacebookId?.length ?? 0) > 2
                  ?  Icon(FontAwesome.facebook_square,
                      color: eventModel.isVisible == 1 ? const Color.fromARGB(255, 59, 89, 152) : Colors.grey, size: 35.0)
                      
                      
                  :  Container(height:1.0,width:35.0), 

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top:4.0,left: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${eventModel.eventName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: eventModel.isVisible == 1 ? Colors.black87 : Colors.grey,
                        fontFamily: 'AvenirNextCondensedDemiBold',
                        fontStyle: FontStyle.normal,
                        fontSize: 18.0,
                        height: 0.85),
                    textAlign: TextAlign.left,
                  ),
                  Text(
                    eventModel.eventStartDatetime.year !=
                            DateTime.now().year
                        ? 'Run #${eventModel.eventNumber.toString()} on ${DateFormat("E, MMM d, yyyy \'at\' h:mm a").format(eventModel.eventStartDatetime)}'
                        : 'Run #${eventModel.eventNumber.toString()} on ${DateFormat("E, MMM d \'at\' h:mm a").format(eventModel.eventStartDatetime)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: eventModel.isVisible == 1 ? Colors.black87 : Colors.grey,
                        fontFamily: 'AvenirNextCondensedDemiBold',
                        fontStyle: FontStyle.normal,
                        fontSize: 18.0,
                        height: 0.85),
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
    ),);
  }
}
