import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:harrier_central/util/constants.dart';

import 'package:intl/intl.dart';
//import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:harrier_central/pages/detail_pages/run_details_page.dart';
import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/widgets/kennel_logo.dart';
import 'package:harrier_central/pages/top_level/future_run_list_page.dart';
import 'package:harrier_central/widgets/multiple_choice_popup.dart';
import 'package:harrier_central/data/hc3_services/hasher_event_map_service.dart';
import 'package:harrier_central/notifications/notification_support.dart';

//import 'package:flip_panel/flip_panel.dart';

class RunListItem extends StatefulWidget {
  const RunListItem({Key key, @required this.futureRun}) : super(key: key);

  final RunDetailsAggregate futureRun;

  @override
  _RunListItemState createState() => _RunListItemState();
}

class _RunListItemState extends State<RunListItem> with WidgetsBindingObserver {
  _RunListItemState();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('App lifecycle state => ' + state.toString());
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    // return IntrinsicWidth(
    //     child:
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.only(top: 10.0, left: 0.0, right: 0.0),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.only(top: 5.0, left: 20.0),
                  child: Text(
                    widget.futureRun.event.eventName,
                    style: const TextStyle(fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 17.0, color: Colors.black, height: 1.0),
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () {
                    showEmailAlertPopup(context);
                  },
                  child: widget.futureRun.extensions.emailAlertPreference == -1
                      ? Icon(delayIcon, color: Colors.blue[800], size: 24.0)
                      : Image(
                          width: 24.0,
                          height: 24.0,
                          fit: BoxFit.fill,
                          image: widget.futureRun.extensions.emailAlertPreference == 1
                              ? const AssetImage('images/icons/envelope_gold_50px.png')
                              : widget.futureRun.extensions.emailAlertPreference == 2 ? const AssetImage('images/icons/envelope_silver_strike_out_50px.png') : const AssetImage('images/icons/envelope_silver_strike_out_50px.png'),
                        ),
                ),
              ),
              widget.futureRun.event.eventStartDatetime.isAfter(DateTime.now().add(const Duration(days: NOTIFICATION_DAYS_IN_FUTURE)))
                  ? Container()
                  : Container(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () {
                          showNotificationPopup(context);
                        },
                        child: widget.futureRun.extensions.notificationPreference == -1
                            ? Icon(delayIcon, color: Colors.blue[800], size: 24.0)
                            : Image(
                                width: 24.0,
                                height: 24.0,
                                fit: BoxFit.fill,
                                image: widget.futureRun.extensions.notificationPreference == 1
                                    ? const AssetImage('images/icons/bell_gold_50px.png')
                                    : widget.futureRun.extensions.notificationPreference == 2 ? const AssetImage('images/icons/bell_silver_strike_out_50px.png') : const AssetImage('images/icons/bell_silver_strike_out_50px.png'),
                              ),
                      ),
                    ),
            ],
          ),
          // Stack(children: <Widget>[
          //   Positioned(top:10.0,
          //   child:FlipClock.reverseCountdown(
          //     //startTime: DateTime.now(),
          //     duration: widget.futureRun.eventStartDatetime
          //         .difference(DateTime.now()),
          //     digitColor: Colors.black,
          //     backgroundColor: Colors.white,
          //     digitSize: 30.0,
          //     width: 20.0,
          //     flipDirection: FlipDirection.down,
          //     borderRadius: const BorderRadius.all(Radius.circular(2.0)),
          //     //onDone: () => print('ih'),
          //   ),),
          // ]),
          Container(
            //padding: const EdgeInsets.only(top: 15.0, bottom: 10.0),
            margin: const EdgeInsets.only(top: 7.0, bottom: 0.0),
            padding: const EdgeInsets.only(top: 7.0, bottom: 0.0),
            height: 1.0,
            color: Colors.grey[300],
          ),
          Stack(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 100,
                    child: FlatButton(
                      splashColor: Theme.of(context).accentColor,
                      highlightColor: Theme.of(context).accentColor,
                      onPressed: () {
                        Navigator.push<dynamic>(
                          this.context,
                          MaterialPageRoute<dynamic>(
                            builder: (BuildContext context) => RunDetailsPage(futureRun: widget.futureRun),
                          ),
                        );
                        //   },
                        // );
                      },
                      padding: const EdgeInsets.only(top: 10.0, left: 4.0, right: 0.0, bottom: 10.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          KennelLogo(
                            kennelLogoUrl: widget.futureRun.kennel.kennelLogo,
                            kennelShortName: widget.futureRun.kennel.kennelShortName,
                            logoHeight: 70.0,
                            leftPadding: 7.0,
                            rightPadding: 7.0,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 3.0, left: 10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    (widget.futureRun.event.isCountedRun == 1 ? 'Run #${widget.futureRun.event.eventNumber}, ' : 'Run / Event ') +
                                        (widget.futureRun.extensions.daysUntilEvent <= 14
                                            ? widget.futureRun.extensions.daysUntilEvent.toInt() == 0 ? 'TODAY' : widget.futureRun.extensions.daysUntilEvent.toInt() == 1 ? 'Tomorrow' : 'in ${widget.futureRun.extensions.daysUntilEvent.toInt().toString()} days'
                                            : (widget.futureRun.extensions.daysUntilEvent <= 30)
                                                ? 'in ' + (widget.futureRun.extensions.daysUntilEvent ~/ 7.0).toString() + ((widget.futureRun.extensions.daysUntilEvent ~/ 7.0) == 1 ? ' week' : ' weeks')
                                                : widget.futureRun.extensions.daysUntilEvent <= 365
                                                    ? 'in ' + (widget.futureRun.extensions.daysUntilEvent ~/ 30.0).toString() + ((widget.futureRun.extensions.daysUntilEvent ~/ 30.0) == 1 ? ' month' : ' months')
                                                    : 'in ' + (widget.futureRun.extensions.daysUntilEvent ~/ 365.0).toString() + ((widget.futureRun.extensions.daysUntilEvent ~/ 365.0) == 1 ? ' year' : ' years')),
                                    style: const TextStyle(color: Colors.black87, fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, fontSize: 15.0, height: 1),
                                    textAlign: TextAlign.left,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    DateFormat("E, MMM d 'at' h:mm a").format(widget.futureRun.event.eventStartDatetime),
                                    style: const TextStyle(color: Colors.black87, fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 15.0, height: 1),
                                    textAlign: TextAlign.left,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    (widget.futureRun.event.hares ?? '') == '' ? 'RSVP to sign up to Hare!' : 'Hares: ' + widget.futureRun.event.hares,
                                    style: const TextStyle(color: Colors.black87, fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 15.0, height: 1),
                                    textAlign: TextAlign.left,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  widget.futureRun.extensions.distToEvent >= 0
                                      ? Text(
                                          Utilities.getDistance(widget.futureRun.extensions.distToEvent, context,isMetric: widget.futureRun.extensions.distancePreference == 0 ) + ' from here',
                                          style: const TextStyle(color: Colors.black87, fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 15.0, height: 1),
                                          textAlign: TextAlign.left,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      : const Text(''),
                                ],
                              ),
                            ),
                          ),
                          (widget.futureRun.event.hares ?? '') == '' ? Container(
                            padding: const EdgeInsets.only(top:15),
                            child:Image(width: 40.0 * deviceWidthScaleFactor, height: 40.0 * deviceWidthScaleFactor, fit: BoxFit.fill, image: AssetImage('images/other/hare_needed_stamp.png'))) : Container(),
                        ],
                      ),
                    ),
                  ),
                  // Expanded(
                  //   flex: 10,
                  //   child: IconButton(
                  //     icon: const Icon(MaterialCommunityIcons.dots_vertical),
                  //     iconSize: Theme.of(context).iconTheme.size,
                  //     color: Colors.black54,
                  //     splashColor: Theme.of(context).highlightColor,
                  //     onPressed: () {
                  //       showNotificationPopup(context);
                  //     },
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void showNotificationPopup(BuildContext context) {
    final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
      <String, dynamic>{
        'title': 'Turn notifications\r\non',
        'icon': <Widget>[
          Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          const Positioned(
            left: 3,
            top: 1.5,
            child: Image(
              width: 25.0,
              height: 25.0,
              fit: BoxFit.fill,
              image: AssetImage('images/icons/bell_gold_50px.png'),
            ),
          )
        ],
        'returnValue': notificationsOn,
      },
      <String, dynamic>{
        'title': 'Turn notifications\r\noff',
        'icon': <Widget>[
          Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          const Positioned(
            left: 3,
            top: 1.5,
            child: Image(
              width: 25.0,
              height: 25.0,
              fit: BoxFit.fill,
              image: AssetImage('images/icons/bell_silver_strike_out_50px.png'),
            ),
          )
        ],
        'returnValue': notificationsOff,
      },
      <String, dynamic>{
        'title': 'Use Kennel setting',
        'icon': <Widget>[
          Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          const Positioned(
            left: 3,
            top: 1.5,
            child: Image(
              width: 25.0,
              height: 25.0,
              fit: BoxFit.fill,
              image: AssetImage('images/icons/bell_silver_50px.png'),
            ),
          )
        ],
        'returnValue': notificationsAuto,
      },
      // <String, dynamic>{
      //   'title': 'Set notifications to auto',
      //   'icon':  <Widget>[Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), Positioned(left:3,top:1.5,child:Icon(MaterialCommunityIcons.bell_off, size:25, color: Colors.red[800]))],
      //   'returnValue': EnumNotificationPopupActions.notificationsAuto,
      // },
    ];

    final MultipleChoicePopup popup = MultipleChoicePopup(
        title: 'Notification options for this run',
        buttons: buttons,
        cancelButtonTitle: 'Cancel',
        buttonPress: (dynamic retVal) {
          if ((retVal == notificationsOn) || (retVal == notificationsOff) || (retVal == notificationsAuto)) {
            final String userId = getStringPref(StringPrefsEnum.userId);
            final HasherEventMapService hemSrv = HasherEventMapService();
            final EnumNotificationState<int> nState = retVal;
            setState(() {
              widget.futureRun.extensions.notificationPreference = -1;
            });

            hemSrv.joinEvent(widget.futureRun.event.eventId, HasherEventMapTableType.user, userId, null, notificationState: nState.value).then((List<dynamic> results) {
              setState(() {
                final NotificationSupport notifications = NotificationSupport();
                notifications.setNotificationState(eventId: widget.futureRun.event.eventId);
                // TODO(James): Fix this to reflect true value of what is in the DB not just the value
                // provided to the function
                widget.futureRun.extensions.notificationPreference = results[0]['notificationPreference'] ?? 0;
              });
            });
          }

          // modifyMembershipCallback(retVal);
        });

    showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return popup;
        });
  }

  void showEmailAlertPopup(BuildContext context) {
    final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
      <String, dynamic>{
        'title': 'Turn email\r\nmessages on',
        'icon': <Widget>[
          Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          const Positioned(
            left: 3,
            top: 1.5,
            child: Image(
              width: 25.0,
              height: 25.0,
              fit: BoxFit.fill,
              image: AssetImage('images/icons/envelope_gold_50px.png'),
            ),
          )
        ],
        'returnValue': emailAlertsOn,
      },
      <String, dynamic>{
        'title': 'Turn email\r\nmessages off',
        'icon': <Widget>[
          Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          const Positioned(
            left: 3,
            top: 1.5,
            child: Image(
              width: 25.0,
              height: 25.0,
              fit: BoxFit.fill,
              image: AssetImage('images/icons/envelope_silver_strike_out_50px.png'),
            ),
          )
        ],
        'returnValue': emailAlertsOff,
      },
      <String, dynamic>{
        'title': 'Use Kennel setting',
        'icon': <Widget>[
          Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          const Positioned(
            left: 3,
            top: 1.5,
            child: Image(
              width: 25.0,
              height: 25.0,
              fit: BoxFit.fill,
              image: AssetImage('images/icons/envelope_silver_50px.png'),
            ),
          )
        ],
        'returnValue': emailAlertsAuto,
      },
      // <String, dynamic>{
      //   'title': 'Set notifications to auto',
      //   'icon':  <Widget>[Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), Positioned(left:3,top:1.5,child:Icon(MaterialCommunityIcons.bell_off, size:25, color: Colors.red[800]))],
      //   'returnValue': EnumNotificationPopupActions.notificationsAuto,
      // },
    ];

    final MultipleChoicePopup popup = MultipleChoicePopup(
        title: 'Email options for this run',
        buttons: buttons,
        cancelButtonTitle: 'Cancel',
        buttonPress: (dynamic retVal) {
          if ((retVal == emailAlertsOn) || (retVal == emailAlertsOff) || (retVal == emailAlertsAuto)) {
            final String userId = getStringPref(StringPrefsEnum.userId);
            final HasherEventMapService hemSrv = HasherEventMapService();
            final EnumEmailAlertState<int> nState = retVal;
            setState(() {
              widget.futureRun.extensions.emailAlertPreference = -1;
            });

            hemSrv.joinEvent(widget.futureRun.event.eventId, HasherEventMapTableType.user, userId, null, emailAlertState: nState.value).then((List<dynamic> results) {
              setState(() {
                widget.futureRun.extensions.emailAlertPreference = results[0]['emailAlertPreference'] ?? 0;
              });
            });
          }

          // modifyMembershipCallback(retVal);
        });

    showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return popup;
        });
  }
}
