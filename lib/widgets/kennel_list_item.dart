import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

class KennelListItem extends StatefulWidget {
  const KennelListItem({
    super.key,
    required this.kennelItem,
    required this.kennelSelected,
    required this.kennelFollowingUpdated,
    required this.kennelEmailAndNotificationPrefsUpdated,
  });

  final KennelListAggregate kennelItem;
  final Function kennelSelected;
  final Function kennelFollowingUpdated;
  final Function kennelEmailAndNotificationPrefsUpdated;

  @override
  KennelListItemState createState() => KennelListItemState();
}

class KennelListItemState extends State<KennelListItem> {
  int _distancePreference = 0;

  @override
  void initState() {
    _distancePreference = (getIntPref(IntPrefsEnum.hasherPreferences) ?? 0) & hasherPref_distanceMeasuredIn;
    // kilometers = 2, miles = 3, auto = 0
    if (_distancePreference == 0) {
      _distancePreference = (widget.kennelItem.extensions.distanceUnitsPref ?? 0) + 2;
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
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () {
                        _showFollowingPopup();
                      },
                      child: Column(
                        children: <Widget>[
                          if (widget.kennelItem.extensions.followingRequested != -1)
                            Image.asset(delayIconAsset, width: 24, height: 24)
                          else if (widget.kennelItem.hkm?.following == 1)
                            Image.asset('images/icons/checkbox_yes.png', width: 24, height: 24)
                          else if (widget.kennelItem.hkm?.following == 2)
                            Image.asset('images/icons/checkbox_no.png', width: 24, height: 24)
                          else
                            Image.asset('images/icons/checkbox_empty.png', width: 24, height: 24),
                        ],
                      ),
                    ),
                  )),
              !widget.kennelItem.isHomeKennel
                  ? Container()
                  : Container(
                      alignment: Alignment.topLeft,
                      padding: const EdgeInsets.only(right: 5.0, bottom: 2.0),
                      child: widget.kennelItem.extensions.followingRequested != -1 ? Icon(delayIcon, size: 35, color: Colors.blue) : Icon(FontAwesome.home, size: 35, color: Colors.red[900]),
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
                    padding: const EdgeInsets.only(top: 7.0, left: 5.0, bottom: 2.0, right: 5.0),
                    child: AutoSizeText(
                      widget.kennelItem.kennel.kennelName,
                      //'An extremely long kennel name for testing purposes',
                      style: ts_titleCondensedBlack,
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
                    _showEmailPopup(context);
                  },
                  child: widget.kennelItem.extensions.emailAlertRequested != -1
                      ? Icon(delayIcon, color: Colors.blue[800], size: 24.0)
                      : Image(
                          width: 24.0,
                          height: 24.0,
                          fit: BoxFit.fill,
                          image: widget.kennelItem.hkm?.kennelEmailAlertPreference == 1
                              ? const AssetImage('images/icons/envelope_gold_50px.png')
                              : const AssetImage('images/icons/envelope_silver_strike_out_50px.png'),
                        ),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () {
                    _showNotificationPopup(context);
                  },
                  child: widget.kennelItem.extensions.notificationsRequested != -1
                      ? Icon(delayIcon, color: Colors.blue[800], size: 24.0)
                      : Image(
                          width: 24.0,
                          height: 24.0,
                          fit: BoxFit.fill,
                          image: widget.kennelItem.hkm?.kennelNotificationPreference == 1
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
                          if (widget.kennelItem.extensions.location != null) ...<Widget>[
                            Text(
                              widget.kennelItem.extensions.location!,
                              style: ts_regularMediumBlack,
                            ),
                          ],
                          if ((G0<AppModel>().hasLocationPermissions) && (widget.kennelItem.extensions.distToKennel != null)) ...<Widget>[
                            Text(
                              '${Utilities.getDistance(widget.kennelItem.extensions.distToKennel!, isMetric: _distancePreference == 2)} from here',
                              style: ts_regularMediumBlack,
                            )
                          ],
                          if ((widget.kennelItem.hkm != null) && (widget.kennelItem.hkm!.hcTotalRunCount != 0)) ...<Widget>[
                            Text(
                              'Runs: ${widget.kennelItem.hkm!.historicalCountIsEstimate == 0 ? '' : '~'}${widget.kennelItem.hkm!.hcTotalRunCount + widget.kennelItem.hkm!.historicalTotalRunCount}, Times hared: ${widget.kennelItem.hkm!.hcHaringCount + widget.kennelItem.hkm!.historicalHaringCount}',
                              style: ts_titleMedium.copyWith(color: Colors.blue.shade800),
                            ),
                          ],
                          if (widget.kennelItem.hkm?.dateOfLastRun != null) ...<Widget>[
                            Text(
                              'Last run: ${widget.kennelItem.hkm!.dateOfLastRun!.year != DateTime.now().year ? DateFormat('E, MMM d, yyyy').format(widget.kennelItem.hkm!.dateOfLastRun!) : DateFormat('E, MMM d').format(widget.kennelItem.hkm!.dateOfLastRun!)}',
                              style: ts_titleMedium.copyWith(color: Colors.blue.shade800),
                            ),
                          ],
                          if ((widget.kennelItem.hkm != null) && (widget.kennelItem.hkm!.kennelCredit != 0)) ...<Widget>[
                            Text(
                              (widget.kennelItem.hkm!.kennelCredit >= 0 ? 'Credit available: ' : 'Funds owed: ') +
                                  IveCoreUtilities.getFormattedMoney(
                                      widget.kennelItem.hkm!.kennelCredit.abs(), widget.kennelItem.kennel.digitsAfterDecimal ?? 2, widget.kennelItem.kennel.currencySymbol ?? r'$^'),
                              style: TextStyle(
                                  fontFamily: 'AvenirNextDemiBold',
                                  fontStyle: FontStyle.normal,
                                  fontSize: 16.0,
                                  height: 1.0,
                                  color: widget.kennelItem.hkm!.kennelCredit >= 0 ? Colors.green.shade900 : Colors.red.shade900),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (G0<AppModel>().connectionStatus == EnumConnectionStatus2.connected) ...<Widget>[
                    IconButton(
                      icon: const Icon(MaterialCommunityIcons.dots_vertical),
                      iconSize: Theme.of(context).iconTheme.size,
                      color: Colors.black54,
                      splashColor: Theme.of(context).highlightColor,
                      onPressed: () async {
                        await _showFollowingPopup();
                      },
                    ),
                  ],
                ],
              )),
        ],
      ),
    );
  }

  Future<void> _showFollowingPopup() async {
    if (Connection2.checkForConnection(G0<AppModel>().connectionStatus,
        message: 'Follwing kennels is not available in offline mode. Please connect to the Internet to change the following status for a kennel.')) {
      final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
        <String, dynamic>{
          'title': 'Always show runs',
          'icon': <Widget>[
            Image.asset('images/icons/checkbox_yes.png', width: 30, height: 30),
            Container(height: 30, width: 30, decoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.rectangle, border: Border.all(color: Colors.white, width: 3.0))),
          ],
          'returnValue': followTypeFollow
        },
        <String, dynamic>{
          'title': 'Never show runs',
          'icon': <Widget>[
            Image.asset('images/icons/checkbox_no.png', width: 30, height: 30),
            Container(height: 30, width: 30, decoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.rectangle, border: Border.all(color: Colors.white, width: 3.0))),
          ],
          'returnValue': followTypeIgnore
        },
        <String, dynamic>{
          'title': 'Show runs within ${getDistanceString()}',
          'icon': <Widget>[
            Image.asset('images/icons/checkbox_empty.png', width: 30, height: 30),
            //Container(height: 30, width: 30, decoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.rectangle, border: Border.all(color: Colors.white, width: 3.0))),
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

      final MultipleChoicePopupHc popup = MultipleChoicePopupHc(
        key: const Key('661135667'),
        title: 'Follow ${widget.kennelItem.kennel.kennelName}',
        buttons: buttons,
        cancelButtonTitle: 'Cancel',
        cancelButtonReturnValue: followTypeCancel,
      );

      final dynamic retVal = await showDialog<dynamic>(
          context: context,
          barrierDismissible: false, // user must tap button!
          builder: (BuildContext context) {
            return popup;
          });

      if (retVal.value != -1) {
        final HasherKennelMapService srv = HasherKennelMapService();
        widget.kennelItem.extensions.followingRequested = retVal.value;
        setState(() {});
        int isHomeKennel = -1;
        if (retVal == followTypeToggleHomeKennel) {
          isHomeKennel = widget.kennelItem.isHomeKennel ? 0 : 1;
        }

        final List<dynamic> queryResults = await srv.updateHasherKennelStatus(widget.kennelItem.kennel.kennelId, AppDomainType.user, followingState: retVal.value, isHomeKennel: isHomeKennel);

        await setStringPref(StringPrefsEnum.homeKennelId, queryResults[0]['isHomeKennel'] == 1 ? widget.kennelItem.kennel.kennelId : '');

        widget.kennelFollowingUpdated(queryResults[0]['following'], queryResults[0]['kennelNotificationPreference'], queryResults[0]['kennelEmailAlertPreference'], queryResults[0]['isHomeKennel']);

        setState(() {});
      }
    }
  }

  Future<void> _showNotificationPopup(BuildContext context) async {
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

    final MultipleChoicePopupHc popup = MultipleChoicePopupHc(
      key: const Key('001939741'),
      title: 'Notification options for this Kennel',
      buttons: buttons,
      cancelButtonTitle: 'Cancel',
      cancelButtonReturnValue: followTypeCancel,
    );

    final dynamic retVal = await showDialog<dynamic>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return popup;
        });

    if ((retVal == notificationsOn) || (retVal == notificationsOff)) {
      {
        if (!mounted) return;
        if (Connection2.checkForConnection(
          G0<AppModel>().connectionStatus,
          message: 'Setting Kennel notifications is not available in offline mode. Please connect to the Internet to change the notification preferences for a kennel.',
        )) {
          widget.kennelItem.extensions.notificationsRequested = retVal.value;
          setState(() {});

          final String userId = getStringPref(StringPrefsEnum.userId)!;
          await G0<TableModel>()
              .hasherKennelMapService
              .setEmailAndNotificationPreferences(
                widget.kennelItem.kennel.kennelId,
                userId,
                AppDomainType.user,
                retVal,
                emailAlertsUnchanged,
              )
              .then((List<dynamic> results) {
            setState(() {
              widget.kennelEmailAndNotificationPrefsUpdated(results[0]['notificationPreference'], null);
            });
          });

          // final NotificationSupport notifications = NotificationSupport();
          // notifications.setNotificationState(kennelId: widget.kennelItem.kennel.kennelId);

          setState(() {});
        }
      }
    }
  }

  String getDistanceString() {
    final int preferences = getIntPref(IntPrefsEnum.hasherPreferences) ?? 0;
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

    return '$distance $unitsOfMeasure';
  }

  void _showEmailPopup(BuildContext context) {
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

    final MultipleChoicePopupHc popup = MultipleChoicePopupHc(
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
        }).then((dynamic retVal) async {
      if ((retVal == emailAlertsOn) || (retVal == emailAlertsOff)) {
        if (Connection2.checkForConnection(
          G0<AppModel>().connectionStatus,
          message: 'Setting Kennel email alerts is not available in offline mode. Please connect to the Internet to change the notification preferences for a kennel.',
        )) {
          widget.kennelItem.extensions.emailAlertRequested = retVal.value;
          setState(() {});

          final String userId = getStringPref(StringPrefsEnum.userId)!;
          await G0<TableModel>()
              .hasherKennelMapService
              .setEmailAndNotificationPreferences(
                widget.kennelItem.kennel.kennelId,
                userId,
                AppDomainType.user,
                notificationsUnchanged,
                retVal,
              )
              .then((List<dynamic> results) {
            setState(() {
              widget.kennelEmailAndNotificationPrefsUpdated(null, results[0]['emailAlertPreference']);
            });
          });
        }
      }
    });
  }
}
