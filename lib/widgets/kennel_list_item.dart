// @dart=2.11
import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

class KennelsListItem extends StatefulWidget {
  const KennelsListItem({Key key, @required this.kennelItem, @required this.kennelSelected, @required this.kennelFollowingUpdated}) : super(key: key);

  final KennelListAggregate kennelItem;
  final Function kennelSelected;
  final Function kennelFollowingUpdated;

  @override
  KennelListItemState createState() => KennelListItemState();
}

class KennelListItemState extends State<KennelsListItem> {
  int _distancePreference = 0;

  @override
  void initState() {
    _distancePreference = getIntPref(IntPrefsEnum.hasherPreferences) & hasherPref_distanceMeasuredIn;
    // kilometers = 2, miles = 3, auto = 0
    if (_distancePreference == 0) {
      _distancePreference = widget.kennelItem.extensions.distanceUnitsPref + 2;
    }
    super.initState();
  }

  //final int _autoRunPreference = getIntPref(IntPrefsEnum.hasherPreferences) & hasherPref_distanceForAutoDisplay;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.only(top: 10.0, left: 0.0, right: 0.0),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              InkWell(
                onTap: () {
                  // NOTE: leave this comment in for now. Ideally we would navigate
                  // from here to the next page, but there was an intermittent bug
                  // where the selected Kennel would change unexpectedly. This "hack" of
                  // navigating from the parent is my attempt to fix it
                  //
                  // Navigator.of(context).push<dynamic>(
                  //   MaterialPageRoute<dynamic>(
                  //     builder: (BuildContext context)
                  //       => KennelAdminMainPage(kennel: widget.kennel)
                  //     ,
                  //   ),
                  // );
                  widget.kennelSelected();
                },
                child: Container(
                  child: IconButton(
                    icon: Icon(
                        widget.kennelItem.extensions.followingRequested != -1
                            ? delayIcon
                            : widget.kennelItem.hkm.following == 1
                                ? const Icon(FontAwesome.check_circle).icon
                                : widget.kennelItem.hkm.following == 2
                                    ? const Icon(FontAwesome.times_circle).icon
                                    : const Icon(FontAwesome.star).icon,
                        color: G0<AppModel>().connectionStatus != EnumConnectionStatus.connected
                            ? Colors.grey
                            : widget.kennelItem.extensions.followingRequested != -1
                                ? Colors.blue
                                : widget.kennelItem.hkm.following == KENNEL_IS_FOLLOWING
                                    ? Colors.green
                                    : widget.kennelItem.hkm.following == KENNEL_IS_BLOCKED
                                        ? Colors.red
                                        : Colors.yellow[800]),
                    tooltip: 'Select to follow a Kennel',
                    iconSize: 35.0,
                    alignment: Alignment.topCenter,
                    splashColor: Colors.greenAccent,
                    onPressed: () {
                      if (Connection.checkForConnection(context, G0<AppModel>().connectionStatus,
                          message: 'Follwing kennels is not available in offline mode. Please connect to the Internet to change the following status for a kennel.')) {
                        final HasherKennelMapService srv = HasherKennelMapService();
                        int followingRequested = widget.kennelItem.hkm.following + 1;
                        if (followingRequested > 2) {
                          followingRequested = 0;
                        }
                        widget.kennelItem.extensions.followingRequested = followingRequested;
                        setState(() {});
                        srv.updateHasherKennelStatus(widget.kennelItem.kennel.kennelId, AppDomainType.user, followingState: followingRequested).then((List<dynamic> queryResults) {
                          setState(() {
                            widget.kennelFollowingUpdated(queryResults[0]['following'], queryResults[0]['kennelNotificationPreference'],
                                queryResults[0]['kennelEmailAlertPreference'], queryResults[0]['isHomeKennel']);
                          });
                        });
                      }
                    },
                  ),
                  alignment: Alignment.topCenter,
                ),
              ),
              !widget.kennelItem.isHomeKennel
                  ? Container()
                  : Container(
                      child: widget.kennelItem.extensions.followingRequested != -1
                          ? Icon(delayIcon, size: 35, color: Colors.blue)
                          : Icon(FontAwesome.home, size: 35, color: Colors.red[900]),
                      alignment: Alignment.topLeft,
                      padding: const EdgeInsets.only(right: 5.0, bottom: 2.0),
                    ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    // NOTE: leave this comment in for now. Ideally we would navigate
                    // from here to the next page, but there was an intermittent bug
                    // where the selected Kennel would change unexpectedly. This "hack" of
                    // navigating from the parent is my attempt to fix it
                    //
                    // Navigator.of(context).push<dynamic>(
                    //   MaterialPageRoute<dynamic>(
                    //     builder: (BuildContext context)
                    //       => KennelAdminMainPage(kennel: widget.kennel)
                    //     ,
                    //   ),
                    // );
                    widget.kennelSelected();
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width - 70,
                    padding: const EdgeInsets.only(left: 5.0, bottom: 2.0, right: 5.0),
                    child: AutoSizeText(
                      widget.kennelItem.kennel.kennelName,
                      //'An extremely long kennel name for testing purposes',
                      style: const TextStyle(fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 22.0, height: 1.0),
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      minFontSize: 18,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () {
                    showEmailPopup(context);
                  },
                  child: widget.kennelItem.extensions.emailAlertRequested != -1
                      ? Icon(delayIcon, color: Colors.blue[800], size: 24.0)
                      : Image(
                          width: 24.0,
                          height: 24.0,
                          fit: BoxFit.fill,
                          image: widget.kennelItem.hkm.kennelEmailAlertPreference == 1
                              ? const AssetImage('images/icons/envelope_gold_50px.png')
                              : const AssetImage('images/icons/envelope_silver_strike_out_50px.png'),
                        ),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () {
                    showNotificationPopup(context);
                  },
                  child: widget.kennelItem.extensions.notificationsRequested != -1
                      ? Icon(delayIcon, color: Colors.blue[800], size: 24.0)
                      : Image(
                          width: 24.0,
                          height: 24.0,
                          fit: BoxFit.fill,
                          image: widget.kennelItem.hkm.kennelNotificationPreference == 1
                              ? const AssetImage('images/icons/bell_gold_50px.png')
                              : const AssetImage('images/icons/bell_silver_strike_out_50px.png'),
                        ),
                ),
              ),
            ],
          ),
          Container(
            //padding: const EdgeInsets.only(top: 15.0, bottom: 10.0),
            margin: const EdgeInsets.only(bottom: 0.0),
            //padding: const EdgeInsets.only(top: 7.0, bottom: 0.0),
            height: 1.0,
            color: Colors.grey[300],
          ),
          InkWell(
              onTap: () {
                // NOTE: leave this comment in for now. Ideally we would navigate
                // from here to the next page, but there was an intermittent bug
                // where the selected Kennel would change unexpectedly. This "hack" of
                // navigating from the parent is my attempt to fix it
                //
                // Navigator.of(context).push<dynamic>(
                //   MaterialPageRoute<dynamic>(
                //     builder: (BuildContext context)
                //       => KennelAdminMainPage(kennel: widget.kennel)
                //     ,
                //   ),
                // );
                widget.kennelSelected();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(width: 5.0, height: 85.0),
                  KennelLogo(
                      kennelId: widget.kennelItem.kennel.kennelId,
                      kennelLogoUrl: widget.kennelItem.kennel.kennelLogo,
                      kennelShortName: widget.kennelItem.kennel.kennelShortName,
                      logoHeight: 70.0,
                      leftPadding: 0.0,
                      rightPadding: 10.0),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Column(
                        //mainAxisSize: MainAxisSize.max,
                        //mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(width: 10.0, height: 10.0),
                          Text(
                            widget.kennelItem.extensions.location,
                            style: const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 16.0, height: 1.0),
                          ),
                          if (G0<AppModel>().hasLocationPermissions) ...<Widget>[
                            Text(
                              '${Utilities.getDistance(widget.kennelItem.extensions.distToKennel, context, isMetric: _distancePreference == 2)} from here',
                              style: const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 16.0, height: 1.0),
                            )
                          ],
                          if ((widget.kennelItem.hkm.hcTotalRunCount ?? 0) != 0) ...<Widget>[
                            Text(
                              'Runs: ' +
                                  (widget.kennelItem.hkm.historicalCountIsEstimate == 0 ? '' : '~') +
                                  (widget.kennelItem.hkm.hcTotalRunCount + widget.kennelItem.hkm.historicalTotalRunCount).toString() +
                                  ', Times hared: ' +
                                  (widget.kennelItem.hkm.hcHaringCount + widget.kennelItem.hkm.historicalHaringCount).toString(),
                              style: TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, fontSize: 16.0, height: 1.0, color: Colors.blue.shade800),
                            ),
                          ],
                          if (widget.kennelItem.hkm.dateOfLastRun != null) ...<Widget>[
                            Text(
                              'Last run: ' +
                                  (widget.kennelItem.hkm.dateOfLastRun.year != DateTime.now().year
                                      ? DateFormat('E, MMM d, yyyy h:mm a').format(widget.kennelItem.hkm.dateOfLastRun)
                                      : DateFormat('E, MMM d h:mm a').format(widget.kennelItem.hkm.dateOfLastRun)),
                              style: TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, fontSize: 16.0, height: 1.0, color: Colors.blue.shade800),
                            ),
                          ],
                          if ((widget.kennelItem.hkm.kennelCredit ?? 0) != 0) ...<Widget>[
                            Text(
                              'Credit available: ' +
                                  IveCoreUtilities.getFormattedMoney(
                                      widget.kennelItem.hkm.kennelCredit, widget.kennelItem.kennel.digitsAfterDecimal, widget.kennelItem.kennel.currencySymbol),
                              style: TextStyle(
                                  fontFamily: 'AvenirNextDemiBold',
                                  fontStyle: FontStyle.normal,
                                  fontSize: 16.0,
                                  height: 1.0,
                                  color: widget.kennelItem.hkm.kennelCredit >= 0 ? Colors.green.shade900 : Colors.red.shade900),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (G0<AppModel>().connectionStatus == EnumConnectionStatus.connected) ...<Widget>[
                    IconButton(
                      icon: const Icon(MaterialCommunityIcons.dots_vertical),
                      iconSize: Theme.of(context).iconTheme.size,
                      color: Colors.black54,
                      splashColor: Theme.of(context).highlightColor,
                      onPressed: () {
                        if (Connection.checkForConnection(context, G0<AppModel>().connectionStatus,
                            message: 'Follwing kennels is not available in offline mode. Please connect to the Internet to change the following status for a kennel.')) {
                          final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
                            <String, dynamic>{
                              'title': 'Always show runs',
                              'icon': <Widget>[
                                Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                                const Icon(FontAwesome.check_circle, color: Colors.green)
                              ],
                              'returnValue': followTypeFollow
                            },
                            <String, dynamic>{
                              'title': 'Never show runs',
                              'icon': <Widget>[
                                Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                                const Icon(FontAwesome.times_circle, color: Colors.red)
                              ],
                              'returnValue': followTypeIgnore
                            },
                            <String, dynamic>{
                              'title': 'Show runs within ' + getDistanceString(),
                              'icon': <Widget>[
                                const Icon(
                                  FontAwesome.star,
                                  color: Colors.yellow,
                                ),
                              ],
                              'returnValue': followTypeAuto
                            },
                            !widget.kennelItem.isHomeKennel
                                ? <String, dynamic>{
                                    'title': 'Set home kennel',
                                    'icon': <Widget>[
                                      Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                                      const Icon(FontAwesome.home, color: Colors.white, size: 23)
                                    ],
                                    'returnValue': followTypeToggleHomeKennel
                                  }
                                : <String, dynamic>{
                                    'title': 'Clear home kennel',
                                    'icon': <Widget>[
                                      Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                                      const Icon(FontAwesome.home, color: Colors.white, size: 23)
                                    ],
                                    'returnValue': followTypeToggleHomeKennel
                                  },
                          ];

                          final MultipleChoicePopup popup = MultipleChoicePopup(
                            key: const Key('661135667'),
                            title: 'Follow ${widget.kennelItem.kennel.kennelName}',
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
                            if (retVal.value != -1) {
                              final HasherKennelMapService srv = HasherKennelMapService();
                              widget.kennelItem.extensions.followingRequested = retVal.value;
                              setState(() {});
                              int isHomeKennel = -1;
                              if (retVal == followTypeToggleHomeKennel) {
                                isHomeKennel = widget.kennelItem.isHomeKennel ? 0 : 1;
                              }

                              srv
                                  .updateHasherKennelStatus(widget.kennelItem.kennel.kennelId, AppDomainType.user, followingState: retVal.value, isHomeKennel: isHomeKennel)
                                  .then((List<dynamic> queryResults) {
                                setState(() {
                                  setStringPref(StringPrefsEnum.homeKennelId, queryResults[0]['isHomeKennel'] == 1 ? widget.kennelItem.kennel.kennelId ?? '' : '').then((void _) {
                                    widget.kennelFollowingUpdated(queryResults[0]['following'], queryResults[0]['kennelNotificationPreference'],
                                        queryResults[0]['kennelEmailAlertPreference'], queryResults[0]['isHomeKennel']);
                                  });
                                });
                              });
                            }
                          });
                        }
                      },
                    ),
                  ],
                ],
              )),
        ],
      ),
    );
  }

  void showNotificationPopup(BuildContext context) {
    final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
      <String, dynamic>{
        'title': 'Notifications On',
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
        'title': 'Notifications Off',
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
      // <String, dynamic>{
      //   'title': 'Set notifications to auto',
      //   'icon':  <Widget>[Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), Positioned(left:3,top:1.5,child:Icon(MaterialCommunityIcons.bell_off, size:25, color: Colors.red[800]))],
      //   'returnValue': EnumNotificationPopupActions.notificationsAuto,
      // },
    ];

    final MultipleChoicePopup popup = MultipleChoicePopup(
      key: const Key('001939741'),
      title: 'Notification options for this Kennel',
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
      if ((retVal == notificationsOn) || (retVal == notificationsOff)) {
        {
          if (Connection.checkForConnection(context, G0<AppModel>().connectionStatus,
              message: 'Setting Kennel notifications is not available in offline mode. Please connect to the Internet to change the notification preferences for a kennel.')) {
            final HasherKennelMapService srv = HasherKennelMapService();
            final int notificationStatus = retVal.value;
            widget.kennelItem.extensions.notificationsRequested = notificationStatus;
            setState(() {});
            srv.updateHasherKennelStatus(widget.kennelItem.kennel.kennelId, AppDomainType.user, notificationState: notificationStatus).then((List<dynamic> queryResults) {
              setState(() {
                widget.kennelFollowingUpdated(
                    queryResults[0]['following'], queryResults[0]['kennelNotificationPreference'], queryResults[0]['kennelEmailAlertPreference'], queryResults[0]['isHomeKennel']);
                final NotificationSupport notifications = NotificationSupport();
                notifications.setNotificationState(kennelId: widget.kennelItem.kennel.kennelId);
              });
            });
          }
        }
      }
    });
  }

  String getDistanceString() {
    final int preferences = getIntPref(IntPrefsEnum.hasherPreferences);
    final int distMeasuredIn = preferences & hasherPref_distanceMeasuredIn;
    final int distPref = (preferences & hasherPref_distanceForAutoDisplay) ~/ 4;

    String unitsOfMeasure = 'mi';

    if (distMeasuredIn == 2) {
      unitsOfMeasure = 'km';
    } else if (distPref == 3) {
      unitsOfMeasure = 'mi';
    }

    String distance = '50';

    switch (distPref) {
      case 0:
        distance = '0';
        break;
      case 1:
        distance = '10';
        break;
      case 2:
        distance = '25';
        break;
      case 3:
        distance = '50';
        break;
      case 4:
        distance = '75';
        break;
      case 5:
        distance = '100';
        break;
      case 6:
        distance = '150';
        break;
      case 7:
        distance = '200';
        break;
    }

    return distance + ' ' + unitsOfMeasure;
  }

  void showEmailPopup(BuildContext context) {
    final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
      <String, dynamic>{
        'title': 'Turn email alerts on',
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
        'title': 'Turn email alerts off',
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
      // <String, dynamic>{
      //   'title': 'Set notifications to auto',
      //   'icon':  <Widget>[Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), Positioned(left:3,top:1.5,child:Icon(MaterialCommunityIcons.bell_off, size:25, color: Colors.red[800]))],
      //   'returnValue': EnumNotificationPopupActions.notificationsAuto,
      // },
    ];

    final MultipleChoicePopup popup = MultipleChoicePopup(
      key: const Key('66010398690'),
      title: 'Email options for this Kennel',
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
      if ((retVal == emailAlertsOn) || (retVal == emailAlertsOff)) {
        if (Connection.checkForConnection(context, G0<AppModel>().connectionStatus,
            message: 'Setting Kennel email alerts is not available in offline mode. Please connect to the Internet to change the notification preferences for a kennel.')) {
          final HasherKennelMapService srv = HasherKennelMapService();
          final int emailAlertStatus = retVal.value;
          widget.kennelItem.extensions.emailAlertRequested = emailAlertStatus;
          setState(() {});
          srv.updateHasherKennelStatus(widget.kennelItem.kennel.kennelId, AppDomainType.user, emailAlertState: emailAlertStatus).then((List<dynamic> queryResults) {
            setState(() {
              widget.kennelFollowingUpdated(
                  queryResults[0]['following'], queryResults[0]['kennelNotificationPreference'], queryResults[0]['kennelEmailAlertPreference'], queryResults[0]['isHomeKennel']);
              // final NotificationSupport notifications = NotificationSupport();
              // notifications.setNotificationState(kennelId: widget.kennelItem.kennel.kennelId);
            });
          });
        }
      }
    });
  }
}
