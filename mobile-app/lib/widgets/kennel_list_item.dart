import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

class KennelListItem extends StatefulWidget {
  const KennelListItem({
    super.key,
    required this.kennelItem,
    required this.kennelSelected,
    required this.onFollowSelected,
    required this.onNotificationSelected,
    required this.onEmailSelected,
  });

  final KennelListAggregate kennelItem;
  final Function kennelSelected;
  final Future<void> Function(int followValue, int isHomeKennel)
  onFollowSelected;
  final Future<void> Function(NotificationState state) onNotificationSelected;
  final Future<void> Function(dynamic retVal) onEmailSelected;

  @override
  KennelListItemState createState() => KennelListItemState();
}

class KennelListItemState extends State<KennelListItem> {
  int _distancePreference = 0;

  @override
  void initState() {
    super.initState();
    _distancePreference =
        (getIntPref(IntPrefsEnum.hasherPreferences) ?? 0) &
        hasherPref_distanceMeasuredIn;
    if (_distancePreference == 0) {
      _distancePreference =
          (widget.kennelItem.extensions.distanceUnitsPref ?? 0) + 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    String path = 'images/icons/bell_silver_strike_out_50px.png';
    switch (NotificationState.fromInt(
      widget.kennelItem.hkm?.kennelNotificationPreference ?? 0,
    )) {
      case NotificationState.auto:
        path = 'images/icons/bell_silver_50px.png';
        break;
      case NotificationState.on:
        path = 'images/icons/bell_gold_50px.png';
        break;
      case NotificationState.ignore:
        path = 'images/icons/bell_silver_strike_out_50px.png';
        break;
      case NotificationState.mute:
        path = 'images/icons/bell_silver_50px.png';
        break;
      case NotificationState.onBeforeRun:
        path = 'images/icons/bell_time_50px.png';
        break;
      default:
        path = 'images/icons/bell_silver_50px.png';
        break;
    }

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.only(top: 10.0, left: 0.0, right: 0.0),
      color: Colors.white,
      // Clip content to the rounded corners so edge-to-edge child content
      // doesn't square them off — consistent slight rounding with the run cards.
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  InkWell(
                    onTap: () {
                      widget.kennelSelected();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () async {
                          await _showFollowingPopup();
                        },
                        child: Column(
                          children: <Widget>[
                            if (widget
                                    .kennelItem
                                    .extensions
                                    .followingRequested !=
                                -1)
                              Image.asset(delayIconAsset, width: 24, height: 24)
                            else if (widget.kennelItem.hkm?.following == 1)
                              Image.asset(
                                'images/icons/checkbox_yes.png',
                                width: 24,
                                height: 24,
                              )
                            else if (widget.kennelItem.hkm?.following == 2)
                              Image.asset(
                                'images/icons/checkbox_no.png',
                                width: 24,
                                height: 24,
                              )
                            else
                              Image.asset(
                                'images/icons/checkbox_empty.png',
                                width: 24,
                                height: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  !widget.kennelItem.isHomeKennel
                      ? Container()
                      : Container(
                          alignment: Alignment.topLeft,
                          padding: const EdgeInsets.only(
                            right: 5.0,
                            bottom: 2.0,
                          ),
                          child:
                              widget.kennelItem.extensions.followingRequested !=
                                  -1
                              ? Icon(delayIcon, size: 35, color: hc_blue)
                              : Icon(FontAwesome.home, size: 35, color: hc_red),
                        ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        widget.kennelSelected();
                      },
                      child: Container(
                        width: MediaQuery.sizeOf(context).width - 70,
                        padding: const EdgeInsets.only(
                          top: 7.0,
                          left: 5.0,
                          bottom: 2.0,
                          right: 5.0,
                        ),
                        child: AutoSizeText(
                          widget.kennelItem.kennel.kennelName,
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
                      onTap: () async {
                        await _showEmailPopup(context);
                      },
                      child:
                          widget.kennelItem.extensions.emailAlertRequested != -1
                          ? Icon(delayIcon, color: hc_blue, size: 24.0)
                          : Image(
                              width: 24.0,
                              height: 24.0,
                              fit: BoxFit.fill,
                              image:
                                  widget
                                          .kennelItem
                                          .hkm
                                          ?.kennelEmailAlertPreference ==
                                      1
                                  ? const AssetImage(
                                      'images/icons/envelope_gold_50px.png',
                                    )
                                  : const AssetImage(
                                      'images/icons/envelope_silver_strike_out_50px.png',
                                    ),
                            ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () async {
                        await _showNotificationPopup(context);
                      },
                      child:
                          widget.kennelItem.extensions.notificationsRequested !=
                              -1
                          ? Icon(delayIcon, color: hc_blue, size: 24.0)
                          : Image(
                              width: 24.0,
                              height: 24.0,
                              fit: BoxFit.fill,
                              image: AssetImage(path),
                            ),
                    ),
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 0.0),
                height: 1.0,
                color: Colors.grey[300],
              ),
              InkWell(
                onTap: () {
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
                      rightPadding: 10.0,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const SizedBox(width: 10.0, height: 10.0),
                            if (widget.kennelItem.extensions.location !=
                                null) ...<Widget>[
                              Text(
                                widget.kennelItem.extensions.location!,
                                style: ts_regularMediumBlack,
                              ),
                            ],
                            if ((appModel.hasLocationPermissions) &&
                                (widget.kennelItem.extensions.distToKennel !=
                                    null)) ...<Widget>[
                              Text(
                                '${Utilities.getDistance(widget.kennelItem.extensions.distToKennel!, isMetric: _distancePreference == 2)} from here',
                                style: ts_regularMediumBlack,
                              ),
                            ],
                            if ((widget.kennelItem.hkm != null) &&
                                (widget.kennelItem.hkm!.hcTotalRunCount !=
                                    0)) ...<Widget>[
                              Text(
                                'Runs: ${widget.kennelItem.hkm!.historicalCountIsEstimate == 0 ? '' : '~'}${widget.kennelItem.hkm!.hcTotalRunCount + widget.kennelItem.hkm!.historicalTotalRunCount}, Times hared: ${widget.kennelItem.hkm!.hcHaringCount + widget.kennelItem.hkm!.historicalHaringCount}',
                                style: ts_titleMedium.copyWith(color: hc_blue),
                              ),
                            ],
                            if (widget.kennelItem.hkm?.dateOfLastRun !=
                                null) ...<Widget>[
                              Text(
                                'Last run: ${widget.kennelItem.hkm!.dateOfLastRun!.year != DateTime.now().year ? DateFormat('E, MMM d, yyyy').format(widget.kennelItem.hkm!.dateOfLastRun!) : DateFormat('E, MMM d').format(widget.kennelItem.hkm!.dateOfLastRun!)}',
                                style: ts_titleMedium.copyWith(color: hc_blue),
                              ),
                            ],
                            if ((widget.kennelItem.hkm != null) &&
                                (widget.kennelItem.hkm!.kennelCredit !=
                                    0)) ...<Widget>[
                              Text(
                                (widget.kennelItem.hkm!.kennelCredit >= 0
                                        ? 'Credit available: '
                                        : 'Funds owed: ') +
                                    IveCoreUtilities.getFormattedMoney(
                                      widget.kennelItem.hkm!.kennelCredit.abs(),
                                      widget
                                              .kennelItem
                                              .kennel
                                              .digitsAfterDecimal ??
                                          2,
                                      widget.kennelItem.kennel.currencySymbol ??
                                          r'$^',
                                    ),
                                style: TextStyle(
                                  fontFamily: 'AvenirNextDemiBold',
                                  fontStyle: FontStyle.normal,
                                  fontSize: 16.0,
                                  height: 1.0,
                                  color:
                                      widget.kennelItem.hkm!.kennelCredit >= 0
                                      ? Colors.green.shade900
                                      : hc_red,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (Utilities.isConnected())
                      // Chat bubble stacked ABOVE the three dots so the pair
                      // occupies a single icon-width column on the right edge
                      // instead of eating into the kennel info text. Compact
                      // constraints keep two buttons inside the 85px logo row.
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          // Kennel-level chat (not bound to a run). Available to
                          // followers — the SP enforces the HKM requirement.
                          if (widget.kennelItem.hkm != null)
                            IconButton(
                              icon: HcChatBubble(
                                threadId:
                                    widget.kennelItem.kennel.publicKennelId,
                                isKennelThread: true,
                              ),
                              iconSize: Theme.of(context).iconTheme.size,
                              splashColor: Theme.of(context).highlightColor,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              onPressed: () async {
                                final k = widget.kennelItem.kennel;
                                await openChatThread(
                                  title: '${k.kennelShortName} Kennel Chat',
                                  threadId: k.kennelId,
                                  publicThreadId: k.publicKennelId,
                                  isKennelThread: true,
                                );
                              },
                            ),
                          IconButton(
                            icon: const Icon(
                              MaterialCommunityIcons.dots_vertical,
                            ),
                            iconSize: Theme.of(context).iconTheme.size,
                            color: Colors.black54,
                            splashColor: Theme.of(context).highlightColor,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                            onPressed: () async {
                              await _showFollowingPopup();
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          // The follow checkbox is a 24px image inside an InkWell that opens
          // the kennel, so taps that miss the image by a few px navigate away
          // instead. Overlay an invisible 56×56 target on the card's top-left
          // corner (topmost in the Stack) without changing the icon or layout.
          Positioned(
            left: 0,
            top: 0,
            width: 56,
            height: 56,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _showFollowingPopup,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFollowingPopup() async {
    if (!Utilities.isConnected(
      showDialog: true,
      message:
          'Following kennels is not available in offline mode. Please connect to the Internet to change the following status for a kennel.',
    )) {
      return;
    }

    final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
      <String, dynamic>{
        'title': 'Always show runs',
        'icon': <Widget>[
          Image.asset('images/icons/checkbox_yes.png', width: 30, height: 30),
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.rectangle,
              border: Border.all(color: Colors.white, width: 3.0),
            ),
          ),
        ],
        'returnValue': followTypeFollow,
      },
      <String, dynamic>{
        'title': 'Never show runs',
        'icon': <Widget>[
          Image.asset('images/icons/checkbox_no.png', width: 30, height: 30),
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.rectangle,
              border: Border.all(color: Colors.white, width: 3.0),
            ),
          ),
        ],
        'returnValue': followTypeIgnore,
      },
      <String, dynamic>{
        'title': 'Show runs within ${getDistanceString()}',
        'icon': <Widget>[
          Image.asset('images/icons/checkbox_empty.png', width: 30, height: 30),
        ],
        'returnValue': followTypeAuto,
      },
      !widget.kennelItem.isHomeKennel
          ? <String, dynamic>{
              'title': 'Set home kennel',
              'icon': <Widget>[
                Container(
                  height: 30,
                  width: 30,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const Icon(FontAwesome.home, color: Colors.white, size: 23),
              ],
              'returnValue': followTypeToggleHomeKennel,
            }
          : <String, dynamic>{
              'title': 'Clear home kennel',
              'icon': <Widget>[
                Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    color: hc_red,
                    shape: BoxShape.circle,
                  ),
                ),
                const Icon(FontAwesome.home, color: Colors.white, size: 23),
              ],
              'returnValue': followTypeToggleHomeKennel,
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
      barrierDismissible: false,
      builder: (BuildContext context) => popup,
    );

    if (retVal == null || retVal.value == -1) return;

    int isHomeKennel = -1;
    if (retVal == followTypeToggleHomeKennel) {
      isHomeKennel = widget.kennelItem.isHomeKennel ? 0 : 1;
    }

    // Delegate entirely to the parent controller — no setState here.
    // The loading spinner (followingRequested) is managed by the controller.
    await widget.onFollowSelected(retVal.value as int, isHomeKennel);
  }

  Future<void> _showNotificationPopup(BuildContext context) async {
    final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
      <String, dynamic>{
        'title': 'Always on',
        'icon': <Widget>[
          Container(
            height: 30,
            width: 30,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const Positioned(
            left: 3,
            top: 1.5,
            child: Image(
              width: 25.0,
              height: 25.0,
              fit: BoxFit.fill,
              image: AssetImage('images/icons/bell_gold_50px.png'),
            ),
          ),
        ],
        'returnValue': NotificationState.on,
      },
      <String, dynamic>{
        'title': 'On 6 hours before run',
        'icon': <Widget>[
          Container(
            height: 30,
            width: 30,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const Positioned(
            left: 3,
            top: 1.5,
            child: Image(
              width: 25.0,
              height: 25.0,
              fit: BoxFit.fill,
              image: AssetImage('images/icons/bell_time_50px.png'),
            ),
          ),
        ],
        'returnValue': NotificationState.onBeforeRun,
      },
      <String, dynamic>{
        'title': 'On but muted',
        'icon': <Widget>[
          Container(
            height: 30,
            width: 30,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const Positioned(
            left: 3,
            top: 1.5,
            child: Image(
              width: 25.0,
              height: 25.0,
              fit: BoxFit.fill,
              image: AssetImage('images/icons/bell_silver_50px.png'),
            ),
          ),
        ],
        'returnValue': NotificationState.mute,
      },
      <String, dynamic>{
        'title': 'Off',
        'icon': <Widget>[
          Container(
            height: 30,
            width: 30,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const Positioned(
            left: 3,
            top: 1.5,
            child: Image(
              width: 25.0,
              height: 25.0,
              fit: BoxFit.fill,
              image: AssetImage('images/icons/bell_silver_strike_out_50px.png'),
            ),
          ),
        ],
        'returnValue': NotificationState.ignore,
      },
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
      barrierDismissible: false,
      builder: (BuildContext context) => popup,
    );

    if (!mounted) return;
    if (!Utilities.isConnected(
      showDialog: true,
      message:
          'Setting Kennel notifications is not available in offline mode. Please connect to the Internet to change the notification preferences for a kennel.',
    )) {
      return;
    }

    // Delegate to parent controller — no setState, no direct API call here.
    await widget.onNotificationSelected(retVal as NotificationState);
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

  Future<void> _showEmailPopup(BuildContext context) async {
    final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
      <String, dynamic>{
        'title': 'Turn email alerts on',
        'icon': <Widget>[
          Container(
            height: 30,
            width: 30,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const Positioned(
            left: 3,
            top: 1.5,
            child: Image(
              width: 25.0,
              height: 25.0,
              fit: BoxFit.fill,
              image: AssetImage('images/icons/envelope_gold_50px.png'),
            ),
          ),
        ],
        'returnValue': emailAlertsOn,
      },
      <String, dynamic>{
        'title': 'Turn email alerts off',
        'icon': <Widget>[
          Container(
            height: 30,
            width: 30,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const Positioned(
            left: 3,
            top: 1.5,
            child: Image(
              width: 25.0,
              height: 25.0,
              fit: BoxFit.fill,
              image: AssetImage(
                'images/icons/envelope_silver_strike_out_50px.png',
              ),
            ),
          ),
        ],
        'returnValue': emailAlertsOff,
      },
    ];

    final MultipleChoicePopupHc popup = MultipleChoicePopupHc(
      key: const Key('66010398690'),
      title: 'Email options for this Kennel',
      buttons: buttons,
      cancelButtonTitle: 'Cancel',
      cancelButtonReturnValue: followTypeCancel,
    );

    final dynamic retVal = await showDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => popup,
    );

    if ((retVal != emailAlertsOn) && (retVal != emailAlertsOff)) return;
    if (!Utilities.isConnected(
      showDialog: true,
      message:
          'Setting Kennel email alerts is not available in offline mode. Please connect to the Internet to change the notification preferences for a kennel.',
    )) {
      return;
    }

    // Delegate to parent controller — no setState, no direct API call here.
    await widget.onEmailSelected(retVal);
  }
}
