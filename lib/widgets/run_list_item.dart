import 'package:harrier_central/imports_null_safe.dart';
import 'package:intl/intl.dart';

class RunListItem extends StatefulWidget {
  const RunListItem({
    Key? key,
    required this.futureRun,
    required this.onItemTapped,
  }) : super(key: key);

  final RunDetailsAggregate futureRun;
  final Function onItemTapped;

  @override
  RunListItemState createState() => RunListItemState();
}

class RunListItemState extends State<RunListItem> with WidgetsBindingObserver {
  RunListItemState();

  late RunDetailsAggregate _rda;

  @override
  void initState() {
    _rda = widget.futureRun;
    super.initState();
    //_rsvpIcon = Future<Widget>.value(getRsvpWidget(_rda.extensions.rsvpState, _rda.extensions.isHare));
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

  Widget _getRsvpWidget(int? rsvpState, int? willHareState) {
    String iconFile = '';

    if (rsvpState != null) {
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
          if ((willHareState ?? 0) == 0) {
            iconFile = 'images/icons/checkbox_yes.png';
          } else {
            iconFile = 'images/icons/checkbox_hare.png';
          }
          break;
        case -1:
          iconFile = 'wait';
          break;
      }
    }

    if (iconFile == 'wait') {
      return Icon(delayIcon, color: Colors.blue[800], size: 24.0);
    }

    if (iconFile.isEmpty) {
      return const SizedBox();
    }

    return Image.asset(iconFile, height: 24.0, width: 24.0);
  }

  Future<void> _setRsvpState(EnumRsvpState<int> rsvpState, bool willHare) async {
    setState(() {
      _rda.extensions.rsvpState = -1;
    });

    final String userId = getStringPref(StringPrefsEnum.userId)!;
    final List<dynamic> adHocData = await G0<TableModel>().hasherEventMapService.setEventRsvp(
          _rda.event.eventId,
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
      _rda = RunDetailsAggregate(
        kennel: _rda.kennel,
        extensions: _rda.extensions,
        paymentUrl: _rda.paymentUrl,
        event: _rda.event.copyWith(
          hares: hares,
        ),
      );

      _rda.extensions.rsvpState = rsvpResult;
      _rda.extensions.isHare = willHareResult;

      // _rda.event = _rda.event.hares = hares;
    });

    if (serverMessage.isNotEmpty) {
      await IveCoreUtilities.showAlert(navigatorKey.currentContext!, 'RSVP Result', serverMessage, 'OK');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onItemTapped();
      },
      child: Card(
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
                      padding: const EdgeInsets.only(left: 5.0, right: 5.0, top: 5.0, bottom: 5.0),
                      child: _getRsvpWidget(
                        _rda.extensions.rsvpState,
                        _rda.extensions.isHare,
                      )),
                ),
                Expanded(
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.only(top: 5.0, left: 5.0),
                    child: AutoSizeText(
                      _rda.event.eventName,
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
                    child: _rda.extensions.emailAlertPreference == -1
                        ? Icon(delayIcon, color: Colors.blue[800], size: 24.0)
                        : Image(
                            width: 24.0,
                            height: 24.0,
                            fit: BoxFit.fill,
                            image: _rda.extensions.emailAlertPreference == 1
                                ? const AssetImage('images/icons/envelope_gold_50px.png')
                                : _rda.extensions.emailAlertPreference == 2
                                    ? const AssetImage('images/icons/envelope_silver_strike_out_50px.png')
                                    : const AssetImage('images/icons/envelope_silver_strike_out_50px.png'),
                          ),
                  ),
                ),
                ((_rda.event.eventStartDatetime == null) || (_rda.event.eventStartDatetime!.isAfter(DateTime.now().add(const Duration(days: NOTIFICATION_DAYS_IN_FUTURE)))))
                    ? Container()
                    : Container(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () {
                            _showNotificationPopup(context);
                          },
                          child: _rda.extensions.notificationPreference == -1
                              ? Icon(delayIcon, color: Colors.blue[800], size: 24.0)
                              : Image(
                                  width: 24.0,
                                  height: 24.0,
                                  fit: BoxFit.fill,
                                  image: _rda.extensions.notificationPreference == 1
                                      ? const AssetImage('images/icons/bell_gold_50px.png')
                                      : _rda.extensions.notificationPreference == 2
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
            if ((_rda.event.eventImage != null) && (_rda.event.eventImage!.isNotEmpty)) ...<Widget>[
              GestureDetector(
                onLongPress: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => ZoomableImagePage2(
                          key: const Key('51120331'),
                          pageTitle: _rda.event.eventName,
                          imageUrl: _rda.event.eventImage,
                          appBarBackgroundColor: themeAppBarBackground,
                          background: Backgrounds.defaultHcBackground(),
                          margin: 20.0),
                    ),
                  );
                },
                child: CachedNetworkImage(
                  imageUrl: _rda.event.eventImage!,
                  // errorWidget:
                  //     (BuildContext context, String url, Exception error) =>
                  //         const  Icon(Icons.error),
                ),
              ),
              Container(
                //padding: const EdgeInsets.only(top: 15.0, bottom: 10.0),
                // margin: const EdgeInsets.only(top: 0.0, bottom: 0.0),
                // padding: const EdgeInsets.only(top: 0.0, bottom: 0.0),
                height: 1.0,
                color: Colors.grey[300],
              ),
            ],
            Stack(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 100,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10.0, bottom: 10.0, left: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            KennelLogo(
                              kennelId: _rda.kennel.kennelId,
                              kennelLogoUrl: _rda.kennel.kennelLogo,
                              kennelShortName: _rda.kennel.kennelShortName,
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
                                      _rda.kennel.kennelName,
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
                                    _rda.extensions.daysUntilEvent == null
                                        ? const SizedBox()
                                        : Text(
                                            (_rda.event.isCountedRun == 1 ? 'Run #${_rda.event.eventNumber}, ' : 'Run / Event ') +
                                                (_rda.extensions.daysUntilEvent! <= 14
                                                    ? _rda.extensions.daysUntilEvent!.toInt() == -1
                                                        ? 'Yesterday'
                                                        : _rda.extensions.daysUntilEvent!.toInt() == 0
                                                            ? 'TODAY'
                                                            : _rda.extensions.daysUntilEvent!.toInt() == 1
                                                                ? 'Tomorrow'
                                                                : 'in ${_rda.extensions.daysUntilEvent!.toInt().toString()} days'
                                                    : (_rda.extensions.daysUntilEvent! <= 30)
                                                        ? 'in ${_rda.extensions.daysUntilEvent! ~/ 7.0}${(_rda.extensions.daysUntilEvent! ~/ 7.0) == 1 ? ' week' : ' weeks'}'
                                                        : _rda.extensions.daysUntilEvent! <= 365
                                                            ? 'in ${_rda.extensions.daysUntilEvent! ~/ 30.0}${(_rda.extensions.daysUntilEvent! ~/ 30.0) == 1 ? ' month' : ' months'}'
                                                            : 'in ${_rda.extensions.daysUntilEvent! ~/ 365.0}${(_rda.extensions.daysUntilEvent! ~/ 365.0) == 1 ? ' year' : ' years'}'),
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
                                    _rda.event.eventStartDatetime == null
                                        ? const SizedBox()
                                        : Text(
                                            DateFormat("E, MMM d 'at' h:mm a").format(_rda.event.eventStartDatetime!),
                                            style: const TextStyle(color: Colors.black87, fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 15.0, height: 1),
                                            textAlign: TextAlign.left,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                    (_rda.event.hares ?? '') == ''
                                        ? const SizedBox()
                                        // Text(
                                        //     'RSVP to Hare this run!',
                                        //     style: TextStyle(color: Colors.red.shade700, fontFamily: 'AvenirNextBold', fontStyle: FontStyle.normal, fontSize: 15.0, height: 1),
                                        //     textAlign: TextAlign.left,
                                        //     overflow: TextOverflow.ellipsis,
                                        //   )
                                        : Text(
                                            'Hares: ${_rda.event.hares}',
                                            style: const TextStyle(color: Colors.black87, fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 15.0, height: 1),
                                            textAlign: TextAlign.left,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                    if ((_rda.extensions.latitude != null && (_rda.extensions.isMapAndDistanceValid ?? false)) &&
                                        ((_rda.extensions.distToEvent ?? -1.0) >= 0) &&
                                        (G0<AppModel>().hasLocationPermissions)) ...<Widget>[
                                      Text(
                                        '${Utilities.getDistance(_rda.extensions.distToEvent!, context, isMetric: ((_rda.extensions.distanceUnitsPref ?? 0) & 0x01) == 0)} from here',
                                        style: const TextStyle(color: Colors.black87, fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 15.0, height: 1),
                                        textAlign: TextAlign.left,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ] else
                                      const Text('No location provided',
                                          style: TextStyle(color: Colors.black87, fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 15.0, height: 1)),
                                    if (_rda.event.eventGeographicScope > 1) ...<Widget>[
                                      Text(
                                        Utilities.getEventScopeText(_rda.event.eventGeographicScope),
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

                            // (_rda.event.hares ?? '') == '' ? Container(
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
              _rda.event,
              _rda.kennel,
              _rda.extensions.digitsAfterDecimal ?? 2,
              _rda.extensions.currencySymbol = r'$^',
              _rda.extensions.distanceUnitsPref ?? 0,
              _rda.extensions.distToEvent,
              _rda.paymentUrl,
              _rda.extensions.rsvpState ?? 0,
              _rda.extensions.isMember ?? 0,
              _rda.extensions.isPaid ?? 0,
              true,
              (int r, int p) {
                _rda.extensions.rsvpState = r;
                if (p != -1) {
                  _rda.extensions.isPaid = p;
                }
                setState(() {});
              },
            )
          ],
        ),
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
        if (retVal is EnumRsvpState<int>) {
          await _setRsvpState(retVal, false);
        } else if (retVal is EnumIsHare) {
          final bool willHare = await Utilities.promptForHare(context, _rda.event.hares) ?? false;
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
        _rda.extensions.notificationPreference == 2
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
        _rda.extensions.emailAlertPreference == 2
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
          _setEmailAlertState(retVal as EnumEmailAlertState<int>);
        } else if (retVal is EnumNotificationState) {
          _setNotificationState(retVal as EnumNotificationState<int>);
        } else if (retVal is EnumRsvpState) {
          await _setRsvpState(retVal as EnumRsvpState<int>, false);
        } else if (retVal is EnumIsHare) {
          final bool willHare = await Utilities.promptForHare(context, _rda.event.hares) ?? false;
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
      final String userId = getStringPref(StringPrefsEnum.userId)!;
      final EnumEmailAlertState<int> nState = retVal;
      setState(() {
        _rda.extensions.emailAlertPreference = -1;
      });

      G0<TableModel>()
          .hasherEventMapService
          .setEmailAndNotificationPreferences(
            _rda.event.eventId,
            userId,
            AppDomainType.user,
            notificationsUnchanged,
            nState,
          )
          .then((List<dynamic> results) {
        setState(() {
          _rda.extensions.emailAlertPreference = results[0]['emailAlertPreference'] ?? 0;
        });
      });
    }
  }

  void _setNotificationState(EnumNotificationState<int> retVal) {
    if ((retVal == notificationsOn) || (retVal == notificationsOff) || (retVal == notificationsAuto)) {
      final String userId = getStringPref(StringPrefsEnum.userId)!;
      final EnumNotificationState<int> nState = retVal;
      setState(() {
        _rda.extensions.notificationPreference = -1;
      });

      G0<TableModel>()
          .hasherEventMapService
          .setEmailAndNotificationPreferences(
            _rda.event.eventId,
            userId,
            AppDomainType.user,
            nState,
            emailAlertsUnchanged,
          )
          .then((List<dynamic> results) {
        setState(() {
          // final NotificationSupport notifications = NotificationSupport();
          // notifications.setNotificationState(eventId: _rda.event.eventId);
          // // T0D0(James): Fix this to reflect true value of what is in the DB not just the value
          // // provided to the function
          _rda.extensions.notificationPreference = results[0]['notificationPreference'] ?? 0;
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
