import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

class RunListItemController extends GetxController {
  RunListItemController();

  Rx<int> rsvpState = 0.obs;
  Rx<int> isHareState = 0.obs;

  void setRsvpState(int rState) => rsvpState.value = rState;
  void setHareState(int rState) => isHareState.value = rState;
}

class RunListItem extends StatelessWidget {
  RunListItem({
    Key? key,
    required this.futureRun,
    required this.onItemTapped,
  }) : super(key: key);

  final RunDetailsAggregate futureRun;
  final Function onItemTapped;
  final RunListItemController rliController = RunListItemController();

  @override
  Widget build(BuildContext context) {
    if (futureRun.extensions.rsvpState != rliController.rsvpState.value) {
      rliController.setRsvpState(futureRun.extensions.rsvpState);
    }

    if (futureRun.extensions.isHare != rliController.isHareState.value) {
      rliController.setHareState(futureRun.extensions.isHare);
    }

    return GestureDetector(
      onTap: () {
        onItemTapped();
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
                    _showRsvpOptionsPopup(
                      rliController,
                      context,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 5.0, right: 5.0, top: 5.0, bottom: 5.0),
                    child: Obx(() => _getRsvpWidget(rliController)),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.only(top: 5.0, left: 5.0),
                    child: AutoSizeText(
                      futureRun.event.eventName,
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
                      //showEmailAlertPopup(context);
                    },
                    child: futureRun.extensions.emailAlertPreference == -1
                        ? Icon(delayIcon, color: Colors.blue[800], size: 24.0)
                        : Image(
                            width: 24.0,
                            height: 24.0,
                            fit: BoxFit.fill,
                            image: futureRun.extensions.emailAlertPreference == 1
                                ? const AssetImage('images/icons/envelope_gold_50px.png')
                                : futureRun.extensions.emailAlertPreference == 2
                                    ? const AssetImage('images/icons/envelope_silver_strike_out_50px.png')
                                    : const AssetImage('images/icons/envelope_silver_strike_out_50px.png'),
                          ),
                  ),
                ),
                ((futureRun.event.eventStartDatetime.isAfter(DateTime.now().add(const Duration(days: NOTIFICATION_DAYS_IN_FUTURE)))))
                    ? Container()
                    : Container(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () {
                            //_showNotificationPopup(context);
                          },
                          child: futureRun.extensions.notificationPreference == -1
                              ? Icon(delayIcon, color: Colors.blue[800], size: 24.0)
                              : Image(
                                  width: 24.0,
                                  height: 24.0,
                                  fit: BoxFit.fill,
                                  image: futureRun.extensions.notificationPreference == 1
                                      ? const AssetImage('images/icons/bell_gold_50px.png')
                                      : futureRun.extensions.notificationPreference == 2
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
            if ((futureRun.event.eventImage != null) && (futureRun.event.eventImage!.isNotEmpty)) ...<Widget>[
              GestureDetector(
                onLongPress: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => ZoomableImagePage2(
                          key: const Key('51120331'),
                          pageTitle: futureRun.event.eventName,
                          imageUrl: futureRun.event.eventImage,
                          appBarBackgroundColor: themeAppBarBackground,
                          background: Backgrounds.defaultHcBackground(),
                          margin: 20.0),
                    ),
                  );
                },
                child: CachedNetworkImage(
                  imageUrl: futureRun.event.eventImage!,
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
                              kennelId: futureRun.kennel.kennelId,
                              kennelLogoUrl: futureRun.kennel.kennelLogo,
                              kennelShortName: futureRun.kennel.kennelShortName,
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
                                      futureRun.kennel.kennelName,
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
                                      (futureRun.event.isCountedRun == 1 ? 'Run #${futureRun.event.eventNumber}, ' : 'Run / Event ') +
                                          (futureRun.extensions.daysUntilEvent <= 14
                                              ? futureRun.extensions.daysUntilEvent.toInt() == -1
                                                  ? 'Yesterday'
                                                  : futureRun.extensions.daysUntilEvent.toInt() == 0
                                                      ? 'TODAY'
                                                      : futureRun.extensions.daysUntilEvent.toInt() == 1
                                                          ? 'Tomorrow'
                                                          : 'in ${futureRun.extensions.daysUntilEvent.toInt().toString()} days'
                                              : (futureRun.extensions.daysUntilEvent <= 30)
                                                  ? 'in ${futureRun.extensions.daysUntilEvent ~/ 7.0}${(futureRun.extensions.daysUntilEvent ~/ 7.0) == 1 ? ' week' : ' weeks'}'
                                                  : futureRun.extensions.daysUntilEvent <= 365
                                                      ? 'in ${futureRun.extensions.daysUntilEvent ~/ 30.0}${(futureRun.extensions.daysUntilEvent ~/ 30.0) == 1 ? ' month' : ' months'}'
                                                      : 'in ${futureRun.extensions.daysUntilEvent ~/ 365.0}${(futureRun.extensions.daysUntilEvent ~/ 365.0) == 1 ? ' year' : ' years'}'),
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
                                      DateFormat("E, MMM d 'at' h:mm a").format(futureRun.event.eventStartDatetime),
                                      style: const TextStyle(color: Colors.black87, fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 15.0, height: 1),
                                      textAlign: TextAlign.left,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    (futureRun.event.hares ?? '') == ''
                                        ? const SizedBox()
                                        // Text(
                                        //     'RSVP to Hare this run!',
                                        //     style: TextStyle(color: Colors.red.shade700, fontFamily: 'AvenirNextBold', fontStyle: FontStyle.normal, fontSize: 15.0, height: 1),
                                        //     textAlign: TextAlign.left,
                                        //     overflow: TextOverflow.ellipsis,
                                        //   )
                                        : Text(
                                            'Hares: ${futureRun.event.hares}',
                                            style: const TextStyle(color: Colors.black87, fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 15.0, height: 1),
                                            textAlign: TextAlign.left,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                    if ((futureRun.extensions.latitude != null && futureRun.extensions.isMapAndDistanceValid == 1) &&
                                        ((futureRun.extensions.distToEvent ?? -1.0) >= 0) &&
                                        (G0<AppModel>().hasLocationPermissions)) ...<Widget>[
                                      Text(
                                        '${Utilities.getDistance(futureRun.extensions.distToEvent!, context, isMetric: ((futureRun.extensions.distanceUnitsPref) & 0x01) == 0)} from here',
                                        style: const TextStyle(color: Colors.black87, fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 15.0, height: 1),
                                        textAlign: TextAlign.left,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ] else
                                      const Text('No location provided',
                                          style: TextStyle(color: Colors.black87, fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 15.0, height: 1)),
                                    if (futureRun.event.eventGeographicScope > 1) ...<Widget>[
                                      Text(
                                        Utilities.getEventScopeText(futureRun.event.eventGeographicScope),
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
                                  // _showAllOptionsPopup(context);
                                },
                              ),
                            ],

                            // (futureRun.event.hares ?? '') == '' ? Container(
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
              futureRun.event,
              futureRun.kennel,
              futureRun.extensions.digitsAfterDecimal,
              futureRun.extensions.currencySymbol,
              futureRun.extensions.distanceUnitsPref,
              futureRun.extensions.distToEvent,
              futureRun.paymentUrl,
              futureRun.extensions.rsvpState,
              futureRun.extensions.isMember,
              futureRun.extensions.isPaid,
              true,
              (int r, int p) {
                // NULLSAFETODO1
                // futureRun.extensions.rsvpState = r;
                // if (p != -1) {
                //   futureRun.extensions.isPaid = p;
                // }
                // setState(() {});
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _getRsvpWidget(RunListItemController controller) {
    String iconFile = '';

    switch (controller.rsvpState.value) {
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
        if (rliController.isHareState.value == isHareNo.value) {
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

    if (iconFile.isEmpty) {
      return const SizedBox();
    }

    return Image.asset(iconFile, height: 24.0, width: 24.0);
  }

  void _showRsvpOptionsPopup(
    RunListItemController rliController,
    BuildContext context,
  ) async {
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

      dynamic retVal = await Get.dialog<dynamic>(popup);

      if (retVal is EnumRsvpState<int>) {
        await _setRsvpState(
          rliController,
          retVal,
          false,
        );
      } else if (retVal is EnumIsHare) {
        final bool willHare = await Utilities.promptForHare(futureRun.event.hares) ?? false;
        await _setRsvpState(rliController, rsvpYes, willHare);
      }

      // showDialog<dynamic>(
      //     context: context,
      //     barrierDismissible: false, // user must tap button!
      //     builder: (BuildContext context) {
      //       return popup;
      //     }).then((dynamic retVal) async {
      //   if (retVal is EnumRsvpState<int>) {
      //     // await _setRsvpState(retVal, false);
      //   } else if (retVal is EnumIsHare) {
      //     final bool willHare = await Utilities.promptForHare(context, _rda.event.hares) ?? false;
      //     // await _setRsvpState(rsvpYes, willHare);
      //   }
      // });
    }
  }

  Future<void> _setRsvpState(
    RunListItemController rliController,
    EnumRsvpState<int> rsvpState,
    bool willHare,
  ) async {
    rliController.rsvpState.value = -1;
    // NULLSAFETODO1
    // setState(() {
    //   _rda.extensions.rsvpState = -1;
    // });

    final String userId = getStringPref(StringPrefsEnum.userId)!;
    final List<dynamic> adHocData = await G0<TableModel>().hasherEventMapService.setEventRsvp(
          futureRun.event.eventId,
          userId,
          AppDomainType.user,
          rsvpState.value,
          willHare ? isHareYes.value : isHareNo.value,
        );

    final int rsvpResult = adHocData[0]['rsvpState'];
    final int willHareResult = adHocData[0]['willHareState'];
    final String hares = adHocData[0]['hares'] ?? '';
    final String serverMessage = adHocData[0]['serverMessage'] ?? '';

    rliController.rsvpState.value = rsvpResult;
    rliController.isHareState.value = willHareResult;

    // setState(() {
    //   _rda = RunDetailsAggregate(
    //     kennel: _rda.kennel,
    //     extensions: _rda.extensions,
    //     paymentUrl: _rda.paymentUrl,
    //     event: _rda.event.copyWith(
    //       hares: hares,
    //     ),
    //   );

    //   // NULLSAFETODO1
    //   // _rda.extensions.rsvpState = rsvpResult;
    //   // _rda.extensions.isHare = willHareResult;

    //   // _rda.event = _rda.event.hares = hares;
    // });

    if (serverMessage.isNotEmpty) {
      await IveCoreUtilities.showAlert(navigatorKey.currentContext!, 'RSVP Result', serverMessage, 'OK');
    }
  }
}
