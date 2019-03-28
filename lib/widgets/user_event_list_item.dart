import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:intl/intl.dart';

import 'package:harrier_central/data_models/lite_event_model.dart';
import 'package:harrier_central/util/enums.dart';

class UserEventListItem extends StatelessWidget {
  const UserEventListItem(
      {@required this.userEventHistoryModel, @required this.kennelShortName});

  final LiteEvent userEventHistoryModel;
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
          userEventHistoryModel.isLoading
              ? const Icon(MaterialCommunityIcons.cloud_upload,
                  color: Colors.blue, size: 35.0)
              : userEventHistoryModel.attendenceState < attendenceAtHash.value
                  ? const Icon(FontAwesome.times_circle,
                      color: Colors.red, size: 35.0)
                  : userEventHistoryModel.isHare == isHareNo.value
                      ? const Icon(FontAwesome.check_circle,
                          color: Colors.green, size: 35.0)
                      : const Padding(
                          padding: EdgeInsets.only(left: 2.5, right: 2.5),
                          child: ImageIcon(
                              AssetImage('images/icons/hare_icon.png'),
                              color: Colors.purple,
                              size: 30.0),
                        ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${userEventHistoryModel.eventName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.black87,
                        fontFamily: 'AvenirNextCondensedDemiBold',
                        fontStyle: FontStyle.normal,
                        fontSize: 18.0,
                        height: 0.85),
                    textAlign: TextAlign.left,
                  ),
                  Text(
                    userEventHistoryModel.eventStartDatetime.year !=
                            DateTime.now().year
                        ? 'Run #${userEventHistoryModel.eventNumber.toString()} on ${DateFormat("E, MMM d, yyyy \'at\' h:mm a").format(userEventHistoryModel.eventStartDatetime)}'
                        : 'Run #${userEventHistoryModel.eventNumber.toString()} on ${DateFormat("E, MMM d \'at\' h:mm a").format(userEventHistoryModel.eventStartDatetime)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.black87,
                        fontFamily: 'AvenirNextCondensedDemiBold',
                        fontStyle: FontStyle.normal,
                        fontSize: 18.0,
                        height: 0.85),
                    textAlign: TextAlign.left,
                  ),
                  userEventHistoryModel.attendenceState < attendenceAtHash.value
                      ? Container()
                      : Row(
                          children: <Widget>[
                            Text(
                              'My $kennelShortName run #${userEventHistoryModel.totalRunsThisKennel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.green[800],
                                  fontFamily: 'AvenirNextCondensedDemiBold',
                                  fontStyle: FontStyle.normal,
                                  fontSize: 18.0,
                                  height: 0.85),
                              textAlign: TextAlign.left,
                            ),
                            userEventHistoryModel.isHare ==isHareNo.value ? Container() :
                              Text(
                              ' and #${userEventHistoryModel.totalHaringThisKennel} time haring',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.purple[800],
                                  fontFamily: 'AvenirNextCondensedDemiBold',
                                  fontStyle: FontStyle.normal,
                                  fontSize: 18.0,
                                  height: 0.85),
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
