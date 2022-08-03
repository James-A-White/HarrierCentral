// @dart=2.11
import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

class RunListItem extends StatefulWidget {
  const RunListItem({Key key, @required this.futureRun, @required this.onItemTapped}) : super(key: key);

  final RunDetailsAggregate futureRun;
  final Function onItemTapped;

  @override
  _RunListItemState createState() => _RunListItemState();
}

class _RunListItemState extends State<RunListItem> with WidgetsBindingObserver {
  _RunListItemState();

  @override
  void initState() {
    super.initState();
    //_rsvpIcon = Future<Widget>.value(getRsvpWidget(widget.futureRun.extensions.rsvpState, widget.futureRun.extensions.isHare));
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    //print('App lifecycle state => ' + state.toString());
    super.didChangeAppLifecycleState(state);
  }

  //Future<Widget> _rsvpIcon;

  Widget _getRsvpWidget(int rsvpState, int willHareState) {
    String iconFile;
    switch (rsvpState) {
      case 0:
        iconFile = 'images/icons/checkbox_empty.png';
        break;
      case 1:
        iconFile = 'images/icons/checkbox_no.png';
        break;
      case 2:
        iconFile = 'images/icons/checkbox_maybe.png';
        break;
      case 3:
        if (willHareState == 0) {
          iconFile = 'images/icons/checkbox_yes.png';
        } else {
          iconFile = 'images/icons/checkbox_hare.png';
        }
        break;
      case -1:
        iconFile = 'wait';
        break;
    }

    if (iconFile == 'wait') {
      return Icon(delayIcon, color: Colors.blue[800], size: 24.0);
    }

    return Image.asset(iconFile, height: 24.0, width: 24.0);
  }

  Future<void> _setRsvpState(EnumRsvpState<int> rsvpState, bool willHare) async {
    setState(() {
      widget.futureRun.extensions.rsvpState = -1;
    });

    final String userId = getStringPref(StringPrefsEnum.userId);
    final List<dynamic> adHocData = await G0<TableModel>().hasherEventMapService.setEventRsvp(
          widget.futureRun.event.eventId,
          userId,
          AppDomainType.user,
          rsvpState.value,
          willHare ? isHareYes.value : isHareNo.value,
        );

    final int rsvpResult = adHocData[0]['rsvpState'];
    final int willHareResult = adHocData[0]['willHareState'];
    final String hares = adHocData[0]['hares'] ?? '';
    final String serverMessage = adHocData[0]['serverMessage'] ?? '';

    setState(() {
      widget.futureRun.extensions.rsvpState = rsvpResult;
      widget.futureRun.extensions.isHare = willHareResult;
      widget.futureRun.event.hares = hares;
    });

    if (serverMessage.isNotEmpty) {
      await IveCoreUtilities.showAlert(context, 'RSVP Result', serverMessage, 'OK');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.only(top: 10.0, left: 0.0, right: 0.0),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Row(
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  _showRsvpOptionsPopup(context);
                },
                child: Padding(
                    padding: const EdgeInsets.only(left: 5.0, right: 5.0, top: 5.0, bottom: 5.0), child: _getRsvpWidget(widget.futureRun.extensions.rsvpState, widget.futureRun.extensions.isHare)),
              ),
              Expanded(
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.only(top: 5.0, left: 5.0),
                  child: AutoSizeText(
                    widget.futureRun.event.eventName,
                    style: const TextStyle(fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 22.0, color: Colors.black, height: 1.0),
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    minFontSize: 18,
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
                              : widget.futureRun.extensions.emailAlertPreference == 2
                                  ? const AssetImage('images/icons/envelope_silver_strike_out_50px.png')
                                  : const AssetImage('images/icons/envelope_silver_strike_out_50px.png'),
                        ),
                ),
              ),
              widget.futureRun.event.eventStartDatetime.isAfter(DateTime.now().add(const Duration(days: NOTIFICATION_DAYS_IN_FUTURE)))
                  ? Container()
                  : Container(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () {
                          _showNotificationPopup(context);
                        },
                        child: widget.futureRun.extensions.notificationPreference == -1
                            ? Icon(delayIcon, color: Colors.blue[800], size: 24.0)
                            : Image(
                                width: 24.0,
                                height: 24.0,
                                fit: BoxFit.fill,
                                image: widget.futureRun.extensions.notificationPreference == 1
                                    ? const AssetImage('images/icons/bell_gold_50px.png')
                                    : widget.futureRun.extensions.notificationPreference == 2
                                        ? const AssetImage('images/icons/bell_silver_strike_out_50px.png')
                                        : const AssetImage('images/icons/bell_silver_strike_out_50px.png'),
                              ),
                      ),
                    ),
            ],
          ),
          Container(
            //padding: const EdgeInsets.only(top: 15.0, bottom: 10.0),
            margin: const EdgeInsets.only(top: 2.0, bottom: 0.0),
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
                    child: TextButton(
                      style: TextButton.styleFrom(padding: const EdgeInsets.only(top: 10.0, left: 4.0, right: 0.0, bottom: 10.0), backgroundColor: Colors.white),
                      // splashColor: Theme.of(context).accentColor,
                      // highlightColor: Theme.of(context).accentColor,
                      onPressed: () {
                        widget.onItemTapped();
                      },
                      //padding: const EdgeInsets.only(top: 10.0, left: 4.0, right: 0.0, bottom: 10.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          KennelLogo(
                            kennelId: widget.futureRun.kennel.kennelId,
                            kennelLogoUrl: widget.futureRun.kennel.kennelLogo,
                            kennelShortName: widget.futureRun.kennel.kennelShortName,
                            logoHeight: 70.0,
                            leftPadding: 7.0,
                            rightPadding: 7.0,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                //mainAxisAlignment: MainAxisAlignment.center,
                                //mainAxisSize: MainAxisSize.max,
                                children: <Widget>[
                                  Text(
                                    widget.futureRun.kennel.kennelName,
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 7, 12, 165),
                                      fontFamily: 'AvenirNextDemiBold',
                                      fontStyle: FontStyle.normal,
                                      fontSize: 15.0,
                                      height: 1,
                                    ),
                                    textAlign: TextAlign.left,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    (widget.futureRun.event.isCountedRun == 1 ? 'Run #${widget.futureRun.event.eventNumber}, ' : 'Run / Event ') +
                                        (widget.futureRun.extensions.daysUntilEvent <= 14
                                            ? widget.futureRun.extensions.daysUntilEvent.toInt() == -1
                                                ? 'Yesterday'
                                                : widget.futureRun.extensions.daysUntilEvent.toInt() == 0
                                                    ? 'TODAY'
                                                    : widget.futureRun.extensions.daysUntilEvent.toInt() == 1
                                                        ? 'Tomorrow'
                                                        : 'in ${widget.futureRun.extensions.daysUntilEvent.toInt().toString()} days'
                                            : (widget.futureRun.extensions.daysUntilEvent <= 30)
                                                ? 'in ' +
                                                    (widget.futureRun.extensions.daysUntilEvent ~/ 7.0).toString() +
                                                    ((widget.futureRun.extensions.daysUntilEvent ~/ 7.0) == 1 ? ' week' : ' weeks')
                                                : widget.futureRun.extensions.daysUntilEvent <= 365
                                                    ? 'in ' +
                                                        (widget.futureRun.extensions.daysUntilEvent ~/ 30.0).toString() +
                                                        ((widget.futureRun.extensions.daysUntilEvent ~/ 30.0) == 1 ? ' month' : ' months')
                                                    : 'in ' +
                                                        (widget.futureRun.extensions.daysUntilEvent ~/ 365.0).toString() +
                                                        ((widget.futureRun.extensions.daysUntilEvent ~/ 365.0) == 1 ? ' year' : ' years')),
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontFamily: 'AvenirNextDemiBold',
                                      fontStyle: FontStyle.normal,
                                      fontSize: 15.0,
                                      height: 1,
                                    ),
                                    textAlign: TextAlign.left,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    DateFormat("E, MMM d 'at' h:mm a").format(widget.futureRun.event.eventStartDatetime),
                                    style: const TextStyle(color: Colors.black87, fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 15.0, height: 1),
                                    textAlign: TextAlign.left,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  (widget.futureRun.event.hares ?? '') == ''
                                      ? const SizedBox()
                                      // Text(
                                      //     'RSVP to Hare this run!',
                                      //     style: TextStyle(color: Colors.red.shade700, fontFamily: 'AvenirNextBold', fontStyle: FontStyle.normal, fontSize: 15.0, height: 1),
                                      //     textAlign: TextAlign.left,
                                      //     overflow: TextOverflow.ellipsis,
                                      //   )
                                      : Text(
                                          'Hares: ' + widget.futureRun.event.hares,
                                          style: const TextStyle(color: Colors.black87, fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 15.0, height: 1),
                                          textAlign: TextAlign.left,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                  if ((widget.futureRun.extensions.latitude != null && widget.futureRun.extensions.isMapAndDistanceValid) &&
                                      ((widget.futureRun.extensions.distToEvent ?? -1.0) >= 0) &&
                                      (G0<AppModel>().hasLocationPermissions)) ...<Widget>[
                                    Text(
                                      Utilities.getDistance(widget.futureRun.extensions.distToEvent, context, isMetric: (widget.futureRun.extensions.distanceUnitsPref & 0x01) == 0) + ' from here',
                                      style: const TextStyle(color: Colors.black87, fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 15.0, height: 1),
                                      textAlign: TextAlign.left,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ] else
                                    const Text('No location provided',
                                        style: TextStyle(color: Colors.black87, fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 15.0, height: 1)),
                                  if (widget.futureRun.event.eventGeographicScope > 1) ...<Widget>[
                                    Text(
                                      Utilities.getEventScopeText(widget.futureRun.event.eventGeographicScope),
                                      style: TextStyle(color: Colors.blue.shade700, fontFamily: 'AvenirNextBold', fontStyle: FontStyle.normal, fontSize: 15.0, height: 1),
                                      textAlign: TextAlign.left,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],

                                  //Expanded(child:Container()),
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
                                _showAllOptionsPopup(context);
                              },
                            ),
                          ],

                          // (widget.futureRun.event.hares ?? '') == '' ? Container(
                          //   padding: const EdgeInsets.only(top:15),
                          //   child:Image(width: 40.0 * G0<DeviceInfo>().deviceWidthScaleFactor, height: 40.0 * G0<DeviceInfo>().deviceWidthScaleFactor, fit: BoxFit.fill, image: const AssetImage('images/other/hare_needed_stamp.png'))) : Container(),
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
          PaymentIcons(
            widget.futureRun.event,
            widget.futureRun.kennel,
            widget.futureRun.extensions.digitsAfterDecimal,
            widget.futureRun.extensions.currencySymbol,
            widget.futureRun.extensions.distanceUnitsPref,
            widget.futureRun.extensions.distToEvent,
            widget.futureRun.paymentUrl,
            widget.futureRun.extensions.rsvpState,
            widget.futureRun.extensions.isMember,
            widget.futureRun.extensions.isPaid,
            true,
            (int r, int p) {
              widget.futureRun.extensions.rsvpState = r;
              if (p != -1) {
                widget.futureRun.extensions.isPaid = p;
              }
              setState(() {});
            },
          )
        ],
      ),
    );
  }

  void _showRsvpOptionsPopup(BuildContext context) {
    if (Connection.checkForConnection(context, G0<AppModel>().connectionStatus, message: 'Setting run options is not available in offline mode. Please connect to the Internet.')) {
      final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
        <String, dynamic>{
          'title': 'I\'ll be there!',
          'icon': <Widget>[
            Image.asset('images/icons/checkbox_yes.png', width: 30, height: 30),
            Container(height: 30, width: 30, decoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.rectangle, border: Border.all(color: Colors.white, width: 3.0))),
          ],
          'returnValue': rsvpYes
        },
        <String, dynamic>{
          'title': 'I might be there',
          'icon': <Widget>[
            Image.asset('images/icons/checkbox_maybe.png', width: 30, height: 30),
            Container(height: 30, width: 30, decoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.rectangle, border: Border.all(color: Colors.white, width: 3.0))),
          ],
          'returnValue': rsvpMaybe
        },
        <String, dynamic>{
          'title': 'I won\'t make it',
          'icon': <Widget>[
            Image.asset('images/icons/checkbox_no.png', width: 30, height: 30),
            Container(height: 30, width: 30, decoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.rectangle, border: Border.all(color: Colors.white, width: 3.0))),
          ],
          'returnValue': rsvpNo
        },
        <String, dynamic>{
          'title': 'I\'ll hare!',
          'icon': <Widget>[
            Image.asset('images/icons/checkbox_hare.png', width: 30, height: 30),
            Container(height: 30, width: 30, decoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.rectangle, border: Border.all(color: Colors.white, width: 3.0))),
          ],
          'returnValue': isHareYes
        },
      ];

      final MultipleChoicePopup popup = MultipleChoicePopup(
        key: const Key('01019395'),
        title: 'Run Options',
        buttons: buttons,
        cancelButtonTitle: 'Cancel',
        cancelButtonReturnValue: followTypeCancel,
      );

      showDialog<dynamic>(
          context: context,
          barrierDismissible: false, // user must tap button!
          builder: (BuildContext context) {
            return popup;
          }).then((dynamic retVal) async {
        if (retVal is EnumRsvpState) {
          await _setRsvpState(retVal, false);
        } else if (retVal is EnumIsHare) {
          final bool willHare = await Utilities.promptForHare(context, widget.futureRun.event.hares);
          await _setRsvpState(rsvpYes, willHare);
        }
      });
    }
  }

  void _showAllOptionsPopup(BuildContext context) {
    if (Connection.checkForConnection(context, G0<AppModel>().connectionStatus, message: 'Setting run options is not available in offline mode. Please connect to the Internet.')) {
      final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
        <String, dynamic>{
          'title': 'I\'ll be there!',
          'icon': <Widget>[
            Image.asset('images/icons/checkbox_yes.png', width: 30, height: 30),
            Container(height: 30, width: 30, decoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.rectangle, border: Border.all(color: Colors.white, width: 3.0))),
          ],
          'returnValue': rsvpYes
        },
        <String, dynamic>{
          'title': 'I might be there',
          'icon': <Widget>[
            Image.asset('images/icons/checkbox_maybe.png', width: 30, height: 30),
            Container(height: 30, width: 30, decoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.rectangle, border: Border.all(color: Colors.white, width: 3.0))),
          ],
          'returnValue': rsvpMaybe
        },
        <String, dynamic>{
          'title': 'I won\'t make it',
          'icon': <Widget>[
            Image.asset('images/icons/checkbox_no.png', width: 30, height: 30),
            Container(height: 30, width: 30, decoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.rectangle, border: Border.all(color: Colors.white, width: 3.0))),
          ],
          'returnValue': rsvpNo
        },
        <String, dynamic>{
          'title': 'I\'ll hare!',
          'icon': <Widget>[
            Image.asset('images/icons/checkbox_hare.png', width: 30, height: 30),
            Container(height: 30, width: 30, decoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.rectangle, border: Border.all(color: Colors.white, width: 3.0))),
          ],
          'returnValue': isHareYes
        },
        widget.futureRun.extensions.notificationPreference == 2
            ? <String, dynamic>{
                'title': 'Notifications on',
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
              }
            : <String, dynamic>{
                'title': 'Notifications off',
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
        widget.futureRun.extensions.emailAlertPreference == 2
            ? <String, dynamic>{
                'title': 'Send e-mail',
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
              }
            : <String, dynamic>{
                'title': 'Don\'t send email',
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
      ];

      final MultipleChoicePopup popup = MultipleChoicePopup(
        key: const Key('233030391'),
        title: 'Run Options',
        buttons: buttons,
        cancelButtonTitle: 'Cancel',
        cancelButtonReturnValue: followTypeCancel,
      );

      showDialog<dynamic>(
          context: context,
          barrierDismissible: false, // user must tap button!
          builder: (BuildContext context) {
            return popup;
          }).then((dynamic retVal) async {
        if (retVal is EnumEmailAlertState) {
          _setEmailAlertState(retVal);
        } else if (retVal is EnumNotificationState) {
          _setNotificationState(retVal);
        } else if (retVal is EnumRsvpState) {
          await _setRsvpState(retVal, false);
        } else if (retVal is EnumIsHare) {
          final bool willHare = await Utilities.promptForHare(context, widget.futureRun.event.hares);
          await _setRsvpState(rsvpYes, willHare);
        }
      });
    }
  }

  void _showNotificationPopup(BuildContext context) {
    final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
      <String, dynamic>{
        'title': 'Notifications on',
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
        'title': 'Notifications off',
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
      key: const Key('661039301'),
      title: 'Notification options for this run',
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
      _setNotificationState(retVal);
    });
  }

  void _setEmailAlertState(EnumEmailAlertState<int> retVal) {
    if ((retVal == emailAlertsOn) || (retVal == emailAlertsOff) || (retVal == emailAlertsAuto)) {
      final String userId = getStringPref(StringPrefsEnum.userId);
      final EnumEmailAlertState<int> nState = retVal;
      setState(() {
        widget.futureRun.extensions.emailAlertPreference = -1;
      });

      G0<TableModel>()
          .hasherEventMapService
          .setEmailAndNotificationPreferences(
            widget.futureRun.event.eventId,
            userId,
            AppDomainType.user,
            notificationsUnchanged,
            nState,
          )
          .then((List<dynamic> results) {
        setState(() {
          widget.futureRun.extensions.emailAlertPreference = results[0]['emailAlertPreference'] ?? 0;
        });
      });
    }
  }

  void _setNotificationState(EnumNotificationState<int> retVal) {
    if ((retVal == notificationsOn) || (retVal == notificationsOff) || (retVal == notificationsAuto)) {
      final String userId = getStringPref(StringPrefsEnum.userId);
      final EnumNotificationState<int> nState = retVal;
      setState(() {
        widget.futureRun.extensions.notificationPreference = -1;
      });

      G0<TableModel>()
          .hasherEventMapService
          .setEmailAndNotificationPreferences(
            widget.futureRun.event.eventId,
            userId,
            AppDomainType.user,
            nState,
            emailAlertsUnchanged,
          )
          .then((List<dynamic> results) {
        setState(() {
          // final NotificationSupport notifications = NotificationSupport();
          // notifications.setNotificationState(eventId: widget.futureRun.event.eventId);
          // // T0D0(James): Fix this to reflect true value of what is in the DB not just the value
          // // provided to the function
          widget.futureRun.extensions.notificationPreference = results[0]['notificationPreference'] ?? 0;
        });
      });
    }
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
    ];

    final MultipleChoicePopup popup = MultipleChoicePopup(
      key: const Key('321039395'),
      title: 'Email options for this run',
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
      _setEmailAlertState(retVal);
    });
  }
}
