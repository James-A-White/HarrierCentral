import 'package:badges/badges.dart' as badges;
import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

enum LiveRunButtonStatus { hidden, eligible, active }

class RunListItemController extends GetxController {
  RunListItemController(this.futureRun)
    : rsvpState = (futureRun.extensions.rsvpState).obs,
      attendanceState = (futureRun.extensions.attendenceState).obs,
      isHareState = (futureRun.extensions.isHare).obs,
      emailAlertPreference = (futureRun.extensions.emailAlertPreference).obs,
      notificationPreference =
          (NotificationState.fromInt(
                    futureRun.extensions.notificationPreference,
                  ) ??
                  NotificationState.auto)
              .obs,
      isPaid = (futureRun.extensions.isPaid).obs,
      hares = (futureRun.event.hares ?? '').obs,
      locationOneLineDesc = (futureRun.event.locationOneLineDesc ?? '').obs,
      liveRunState = LiveRunService.ensure() {
    if (AppAccess(
      futureRun.extensions.appAccessFlags,
      mismanagementRoles: futureRun.extensions.mismanagementRoles,
    ).isPhotoAdmin) {
      unawaited(KennelPhotoService()
          .loadPendingPhotoSummary(futureRun.kennel.kennelId));
    }
  }

  final RunDetailsAggregate futureRun;

  final Rx<int> rsvpState;
  final Rx<int> attendanceState;

  final Rx<int> isHareState;
  final Rx<int> emailAlertPreference;
  final Rx<NotificationState> notificationPreference;
  final Rx<int> isPaid;
  final Rx<String> hares;
  final Rx<String> locationOneLineDesc;
  final Rx<bool> automaticallySetNotifiationPrefs =
      getBoolPref(BoolPrefsEnum.automaticallySetNotifiationPrefs)?.obs ??
      true.obs;

  final LiveRunService liveRunState;
  final Rx<LiveRunButtonStatus> liveRunButtonStatus =
      LiveRunButtonStatus.hidden.obs;
  final RxBool liveRunButtonLoading = false.obs;
  final RxBool liveRunAtStart = false.obs;

  void initLiveRunTracking() {
    unawaited(Future.microtask(refreshLiveRunButton));
  }

  void setRsvpState(int state) {
    rsvpState.value = state;
    unawaited(refreshLiveRunButton());
  }

  void setEmailState(int state) => emailAlertPreference.value = state;

  void setNotificationState(NotificationState state) {
    if (notificationPreference.value != state) {
      notificationPreference.value = state;
    }
  }

  void setIsPaid(int state) => isPaid.value = state;

  Future<void> refreshLiveRunButton() async {
    try {
      liveRunButtonLoading.value = true;

      final now = DateTime.now();
      final eventStart = futureRun.event.eventStartDatetime;
      final windowStart = eventStart.subtract(const Duration(minutes: 30));
      final windowEnd = eventStart.add(const Duration(hours: 6));

      final String eventId = futureRun.event.eventId;
      final String? activeId = liveRunState.activeRunEventId.value;

      if (activeId != null) {
        liveRunButtonStatus.value = activeId == eventId
            ? LiveRunButtonStatus.active
            : LiveRunButtonStatus.hidden;
        return;
      }

      if (now.isBefore(windowStart) || now.isAfter(windowEnd)) {
        liveRunButtonStatus.value = LiveRunButtonStatus.hidden;
        return;
      }

      final bool isCheckedIn = attendanceState.value >= attendenceAtHash.value;
      final bool hasRsvpYes = rsvpState.value == rsvpYes.value;

      if (isCheckedIn) {
        liveRunButtonStatus.value = LiveRunButtonStatus.eligible;
        liveRunAtStart.value = true;
        return;
      }

      if (!hasRsvpYes) {
        liveRunButtonStatus.value = LiveRunButtonStatus.hidden;
        return;
      }

      final results = await CommonQueries.isAtRunStart(eventId: eventId);
      final bool atStart = results.any((item) => item.eventId == eventId);
      liveRunAtStart.value = atStart;
      liveRunButtonStatus.value = atStart
          ? LiveRunButtonStatus.eligible
          : LiveRunButtonStatus.hidden;
    } catch (e, s) {
      debugPrint('Live run button check failed: $e');
      BootLogger.logError('[RunListItem._checkLiveRunEligibility] eventId=${futureRun.event.eventId}', e, s);
      liveRunButtonStatus.value = LiveRunButtonStatus.hidden;
    } finally {
      liveRunButtonLoading.value = false;
    }
  }

  // void setHares(String state) => hares.value = state;
  // void setHareState(int state) => isHareState.value = state;
}

class RunListItem extends StatelessWidget {
  RunListItem({super.key, required this.futureRun, required this.onItemTapped})
    : rliController = RunListItemController(futureRun) {
    rliController.initLiveRunTracking();
  }

  final RunDetailsAggregate futureRun;
  final Function onItemTapped;
  final RunListItemController rliController;

  @override
  Widget build(BuildContext context) {
    // if (futureRun.extensions.rsvpState != rliController.rsvpState.value) {
    //   rliController.setRsvpState(futureRun.extensions.rsvpState);
    // }

    // if (futureRun.extensions.isHare != rliController.isHareState.value) {
    //   rliController.setHareState(futureRun.extensions.isHare);
    // }

    // if (futureRun.extensions.emailAlertPreference !=
    //     rliController.emailAlertPreference.value) {
    //   rliController.setEmailState(futureRun.extensions.emailAlertPreference);
    // }

    // if (futureRun.extensions.notificationPreference !=
    //     rliController.notificationPreference.value) {
    //   rliController
    //       .setNotificationState(futureRun.extensions.notificationPreference);
    // }

    // if (futureRun.event.hares != rliController.hares.value) {
    //   rliController.setHares(futureRun.event.hares ?? '');
    // }

    // if (futureRun.extensions.isPaid != rliController.isPaid.value) {
    //   rliController.setIsPaid(futureRun.extensions.isPaid);
    // }

    String eventName = futureRun.event.eventName;
    if (kDebugMode) {
      debugPrint('Event Name: $eventName');
    }

    final event = DateTime.tryParse(
          futureRun.event.eventStartDatetime.toIso8601String().substring(0, 10),
        ) ??
        futureRun.event.eventStartDatetime;
    final device = DateTime.tryParse(
          DateTime.now().toLocal().toIso8601String().substring(0, 10),
        ) ??
        DateTime.now();

    num daysUntilEvent = event.difference(device).inDays;

    // print(
    //   '${futureRun.event.eventStartDatetimeGmt},${futureRun.extensions.eventJulianLocal},Event GMT:${futureRun.event.eventStartDatetimeGmt}, Days until event: $daysUntilEvent, Kennel: ${futureRun.kennel.kennelName}, Event: $eventName',
    // );

    // int xxx = 0;

    return GestureDetector(
      onTap: () {
        onItemTapped();
      },
      child: Card(
        elevation: 4.0,
        margin: const EdgeInsets.only(top: 10.0, left: 0.0, right: 0.0),
        child: Obx(() {
          final isFlashing = Get.isRegistered<FutureRunListPageController>()
              ? Get.find<FutureRunListPageController>()
                  .flashingRunIds
                  .contains(normalizeUuid(futureRun.event.eventId))
              : false;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            color: isFlashing
                ? themeButtonColors.withValues(alpha: 0.35)
                : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    _showRsvpOptionsPopup();
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 5.0,
                      right: 5.0,
                      top: 5.0,
                      bottom: 5.0,
                    ),
                    child: Obx(() => _getRsvpWidget()),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: MediaQuery.sizeOf(context).width,
                    padding: const EdgeInsets.only(top: 5.0, left: 5.0),
                    child: AutoSizeText(
                      futureRun.event.eventName,
                      style: ts_tileText,
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
                    onTap: () async {
                      await _showEmailAlertPopup();
                    },
                    child: Obx(() => _getEmailWidget()),
                  ),
                ),
                ((futureRun.event.eventStartDatetime.isAfter(
                      DateTime.now().add(
                        const Duration(days: NOTIFICATION_DAYS_IN_FUTURE),
                      ),
                    )))
                    ? Container()
                    : Container(
                        padding: const EdgeInsets.only(right: 3),
                        child: GestureDetector(
                          onTap: () async {
                            await _showNotificationPopup();
                          },
                          child: Obx(() => _getNotificationWidget()),
                        ),
                      ),
                if (Get.isRegistered<NotificationService>())
                  Obx(() {
                    if ((!notificationService.unreadEventCounts.containsKey(
                          futureRun.event.publicEventId,
                        )) ||
                        (notificationService
                                .unreadEventCounts[futureRun
                                    .event
                                    .publicEventId]
                                ?.value ==
                            0)) {
                      return const SizedBox();
                    } else {
                      return badges.Badge(
                        position: badges.BadgePosition.topEnd(top: -5, end: 0),
                        badgeContent: Container(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          width: 30,
                          height: 13,
                          child: AutoSizeText(
                            notificationService
                                    .unreadEventCounts[futureRun
                                        .event
                                        .publicEventId]
                                    ?.value
                                    .toString() ??
                                '0',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            minFontSize: 10,
                            maxFontSize: 13,
                            style: ts_badge,
                          ),
                        ),
                        badgeStyle: badges.BadgeStyle(
                          badgeColor: Colors.red.shade800,
                          padding: const EdgeInsets.all(6),
                        ),
                      );
                    }
                  }),
                if (AppAccess(futureRun.extensions.appAccessFlags).isAdmin)
                  Obx(() {
                    final count = KennelPhotoService.pendingPhotosByEvent[
                            futureRun.event.eventId.toLowerCase()] ??
                        0;
                    if (count == 0) return const SizedBox();
                    return badges.Badge(
                      position:
                          badges.BadgePosition.topEnd(top: -5, end: 0),
                      badgeContent: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 2),
                        width: 30,
                        height: 13,
                        child: AutoSizeText(
                          count.toString(),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          minFontSize: 10,
                          maxFontSize: 13,
                          style: ts_badge,
                        ),
                      ),
                      badgeStyle: badges.BadgeStyle(
                        badgeColor: Colors.blue.shade700,
                        padding: const EdgeInsets.all(6),
                      ),
                    );
                  }),
                SizedBox(width: 5),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(top: 2.0, bottom: 0.0),
              padding: const EdgeInsets.only(top: 7.0, bottom: 0.0),
              height: 1.0,
              color: Colors.grey[300],
            ),
            _buildLiveRunModeButton(context),
            if ((futureRun.event.eventImage != null) &&
                (futureRun.event.eventImage!.isNotEmpty)) ...<Widget>[
              GestureDetector(
                onLongPress: () async {
                  await Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => ZoomableImagePage2(
                        key: const Key('51120331'),
                        pageTitle: futureRun.event.eventName,
                        imageUrl: futureRun.event.eventImage,
                        appBarBackgroundColor: themeAppBarBackground,
                        background: Backgrounds.defaultHcBackground(),
                        margin: 20.0,
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: 'EventImage-${futureRun.event.eventId}',
                  child: CachedNetworkImage(
                    imageUrl: futureRun.event.eventImage!,
                    // errorWidget:
                    //     (BuildContext context, String url, Exception error) =>
                    //         const  Icon(Icons.error),
                  ),
                ),
              ),
              Container(height: 1.0, color: Colors.grey[300]),
            ],
            Stack(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 100,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 10.0,
                          bottom: 10.0,
                          left: 4.0,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Hero(
                              tag: 'KennelLogo-${futureRun.event.eventId}',
                              child: KennelLogo(
                                kennelId: futureRun.kennel.kennelId,
                                kennelLogoUrl: futureRun.kennel.kennelLogo,
                                kennelShortName:
                                    futureRun.kennel.kennelShortName,
                                logoHeight: 70.0,
                                leftPadding: 7.0,
                                rightPadding: 7.0,
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      futureRun.kennel.kennelName,
                                      style: ts_titleMediumDarkBlue,
                                      textAlign: TextAlign.left,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      (futureRun.event.isCountedRun == 1
                                              ? 'Run #${futureRun.event.eventNumber}, '
                                              : 'Run / Event ') +
                                          Utilities.describeDayOffset(
                                            daysUntilEvent.toInt(),
                                          ),

                                      // (daysUntilEvent <= 14
                                      //     ? daysUntilEvent.toInt() == -1
                                      //           ? 'Yesterday'
                                      //           : daysUntilEvent.toInt() ==
                                      //                 0
                                      //           ? 'TODAY'
                                      //           : daysUntilEvent.toInt() ==
                                      //                 1
                                      //           ? 'Tomorrow'
                                      //           : daysUntilEvent <= -2
                                      //           ? '${(-daysUntilEvent).toInt().toString()} days ago'
                                      //           : 'in ${daysUntilEvent.toInt().toString()} days'
                                      //     : (daysUntilEvent <= 30)
                                      //     ? 'in ${daysUntilEvent ~/ 7.0}${(daysUntilEvent ~/ 7.0) == 1 ? ' week' : ' weeks'}'
                                      //     : daysUntilEvent <= 365
                                      //     ? 'in ${daysUntilEvent ~/ 30.0}${(daysUntilEvent ~/ 30.0) == 1 ? ' month' : ' months'}'
                                      //     : 'in ${daysUntilEvent ~/ 365.0}${(daysUntilEvent ~/ 365.0) == 1 ? ' year' : ' years'}'),
                                      style: ts_titleMediumBlack,
                                      textAlign: TextAlign.left,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    futureRun.event.eventStartDatetime.year ==
                                            DateTime.now().year
                                        ? Text(
                                            DateFormat(
                                              "E, MMM d 'at' h:mm a",
                                            ).format(
                                              futureRun
                                                  .event
                                                  .eventStartDatetime,
                                            ),
                                            style: ts_regularMediumBlack,
                                            textAlign: TextAlign.left,
                                            overflow: TextOverflow.ellipsis,
                                          )
                                        : Text(
                                            DateFormat(
                                              "E, MMM d yyyy 'at' h:mm a",
                                            ).format(
                                              futureRun
                                                  .event
                                                  .eventStartDatetime,
                                            ),
                                            style: ts_regularMediumBlack,
                                            textAlign: TextAlign.left,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                    Obx(() => _getHaresWidget()),
                                    Obx(() => _getLocationWidget()),
                                    if ((futureRun.extensions.evtLat != null &&
                                            futureRun
                                                    .extensions
                                                    .isMapAndDistanceValid ==
                                                1) &&
                                        ((futureRun.extensions.distToEvent ??
                                                -1.0) >=
                                            0) &&
                                        (appModel.hasLocationPermissions)) ...<
                                      Widget
                                    >[
                                      Text(
                                        '${Utilities.getDistance(futureRun.extensions.distToEvent!, isMetric: ((futureRun.extensions.distanceUnitsPref) & 0x01) == 0)} from here',
                                        style: ts_regularMediumBlack,
                                        textAlign: TextAlign.left,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ] else
                                      Text(
                                        'No location provided',
                                        style: ts_regularMediumBlack,
                                      ),
                                    if (futureRun.event.eventGeographicScope >
                                        1) ...<Widget>[
                                      Text(
                                        Utilities.getEventScopeText(
                                          futureRun.event.eventGeographicScope,
                                        ),
                                        style: ts_titleMediumDarkBlue,
                                        textAlign: TextAlign.left,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],

                                    //Expanded(child:Container()),
                                  ],
                                ),
                              ),
                            ),

                            if (Utilities.isConnected()) ...<Widget>[
                              IconButton(
                                icon: const Icon(
                                  MaterialCommunityIcons.dots_vertical,
                                ),
                                iconSize: Theme.of(context).iconTheme.size,
                                color: Colors.black54,
                                splashColor: Theme.of(context).highlightColor,
                                onPressed: () async {
                                  await _showAllOptionsPopup();
                                },
                              ),
                            ],

                            // (futureRun.event.hares ?? '') == '' ? Container(
                            //   padding: const EdgeInsets.only(top:15),
                            //   child:Image(width: 40.0 * deviceInfo.deviceWidthScaleFactor, height: 40.0 * deviceInfo.deviceWidthScaleFactor, fit: BoxFit.fill, image: const AssetImage('images/other/hare_needed_stamp.png'))) : Container(),
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

            Obx(() => _getPaymentIconnsWidget()),
          ],
        ),
          );
        }),
      ),
    );
  }

  Widget _getPaymentIconnsWidget() {
    return (rliController.isPaid.value == 1)
        ? const SizedBox()
        : PaymentIcons(
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
              futureRun.extensions = futureRun.extensions.copyWith(
                rsvpState: r,
                isPaid: p != -1 ? p : futureRun.extensions.isPaid,
              );

              rliController.setRsvpState(futureRun.extensions.rsvpState);

              if (p != -1) {
                rliController.setIsPaid(p);
              }
            },
          );
  }

  Widget _buildLiveRunModeButton(BuildContext context) {
    return Obx(() {
      final state = rliController.liveRunButtonStatus.value;
      final loading = rliController.liveRunButtonLoading.value;
      final bool isActiveRun = state == LiveRunButtonStatus.active;
      final bool anotherRunActive =
          rliController.liveRunState.hasActiveRun && !isActiveRun;

      final bool isHidden =
          (state == LiveRunButtonStatus.hidden &&
              !rliController.liveRunState.isActive(futureRun.event.eventId)) ||
          anotherRunActive;

      if (isHidden) return const SizedBox.shrink();

      final String label = isActiveRun
          ? 'Return to Live Run Tools'
          : 'Show Live Run Tools';

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.directions_run),
            label: Text(label, style: ts_button),
            style: ElevatedButton.styleFrom(
              backgroundColor: isActiveRun ? hc_blue : hc_red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            onPressed: loading
                ? null
                : () async {
                    if (!isActiveRun) {
                      rliController.liveRunState.startRun(
                        eventId: futureRun.event.eventId,
                        eventName: futureRun.event.eventName,
                      );
                      rliController.liveRunButtonStatus.value =
                          LiveRunButtonStatus.active;
                    }
                    await _openLiveRunFeatures(context);
                  },
          ),
        ),
      );
    });
  }

  Future<void> _openLiveRunFeatures(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LiveRunShell(run: futureRun)),
    );

    // Re-evaluate visibility after returning (in case the user ends tracking later).
    unawaited(rliController.refreshLiveRunButton());
  }

  Future<void> _showAllOptionsPopup() async {
    if (Utilities.isConnected(
      showDialog: true,
      message:
          'Setting run options is not available in offline mode. Please connect to the Internet.',
    )) {
      final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
        <String, dynamic>{
          'title': 'I\'ll be there!',
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
          'returnValue': rsvpYes,
        },
        <String, dynamic>{
          'title': 'I might be there',
          'icon': <Widget>[
            Image.asset(
              'images/icons/checkbox_maybe.png',
              width: 30,
              height: 30,
            ),
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
          'returnValue': rsvpMaybe,
        },
        <String, dynamic>{
          'title': 'I won\'t make it',
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
          'returnValue': rsvpNo,
        },
        // <String, dynamic>{
        //   'title': 'I\'ll hare!',
        //   'icon': <Widget>[
        //     Image.asset('images/icons/checkbox_hare.png',
        //         width: 30, height: 30),
        //     Container(
        //         height: 30,
        //         width: 30,
        //         decoration: BoxDecoration(
        //             color: Colors.transparent,
        //             shape: BoxShape.rectangle,
        //             border: Border.all(color: Colors.white, width: 3.0))),
        //   ],
        //   'returnValue': isHareYes
        // },
        rliController.notificationPreference.value == NotificationState.ignore
            ? <String, dynamic>{
                'title': 'Notifications on',
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
              }
            : <String, dynamic>{
                'title': 'Notifications off',
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
                        'images/icons/bell_silver_strike_out_50px.png',
                      ),
                    ),
                  ),
                ],
                'returnValue': NotificationState.ignore,
              },
        rliController.emailAlertPreference.value == 2
            ? <String, dynamic>{
                'title': 'Send e-mail',
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
              }
            : <String, dynamic>{
                'title': 'Don\'t send email',
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
        key: const Key('233030391'),
        title: 'Run Options',
        buttons: buttons,
        cancelButtonTitle: 'Cancel',
        cancelButtonReturnValue: followTypeCancel,
        otherControls: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Row(
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.only(right: 10),
                  height: 25,
                  width: 25,
                  color: Colors.yellow[100],
                  child: Obx(
                    () => Checkbox(
                      value:
                          rliController.automaticallySetNotifiationPrefs.value,
                      onChanged: (bool? value) async {
                        rliController.automaticallySetNotifiationPrefs.value =
                            value ?? true;
                        await setBoolPref(
                          BoolPrefsEnum.automaticallySetNotifiationPrefs,
                          value ?? true,
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Automatically set email and notification preferences for this run',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: ts_headingBlack,
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

      dynamic retVal = await Get.dialog<dynamic>(
        popup,
        barrierDismissible: false, // user must tap button!
      );

      if (retVal is EnumEmailAlertState) {
        await _setEmailAlertState(retVal);
      } else if (retVal is NotificationState) {
        await _setNotificationState(retVal);
      } else if (retVal is EnumRsvpState) {
        await _setRsvpState(retVal);
      }

      // else if (retVal is EnumIsHare) {
      //   // final bool willHare =
      //   //     await Utilities.promptForHare(rliController.hares.value) ?? false;
      //   await _setRsvpState(rsvpYes);
      // }
    }
  }

  Widget _getHaresWidget() {
    return rliController.hares.isEmpty
        ? const SizedBox.shrink()
        : Text(
            'Hares: ${rliController.hares}',
            style: ts_regularMediumBlack,
            textAlign: TextAlign.left,
            overflow: TextOverflow.ellipsis,
          );
  }

  Widget _getLocationWidget() {
    return rliController.locationOneLineDesc.isEmpty
        ? const SizedBox.shrink()
        : Text(
            rliController.locationOneLineDesc.value,
            style: ts_regularMediumBlack,
            textAlign: TextAlign.left,
            overflow: TextOverflow.ellipsis,
          );
  }

  Widget _getNotificationWidget() {
    String path = 'images/icons/bell_silver_strike_out_50px.png';
    // print(rliController.notificationPreference.value);
    switch (rliController.notificationPreference.value) {
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
      default: // we shuold never reach here
        path = 'images/icons/bell_silver_50px.png';
        break;
    }

    return rliController.notificationPreference.value ==
            NotificationState.unchanged
        ? Icon(delayIcon, color: hc_blue, size: 24.0)
        : Image(
            width: 24.0,
            height: 24.0,
            fit: BoxFit.fill,
            image: AssetImage(path),
          );
  }

  Widget _getEmailWidget() {
    return rliController.emailAlertPreference.value == -1
        ? Icon(delayIcon, color: hc_blue, size: 24.0)
        : Image(
            width: 24.0,
            height: 24.0,
            fit: BoxFit.fill,
            image:
                rliController.emailAlertPreference.value ==
                    NotificationState.on.value
                ? const AssetImage('images/icons/envelope_gold_50px.png')
                : rliController.emailAlertPreference.value ==
                      NotificationState.ignore.value
                ? const AssetImage(
                    'images/icons/envelope_silver_strike_out_50px.png',
                  )
                : const AssetImage(
                    'images/icons/envelope_silver_strike_out_50px.png',
                  ),
          );
  }

  Widget _getRsvpWidget() {
    String iconFile = '';

    if (rliController.rsvpState.value == 3) {
      if (rliController.isHareState.value == isHareYes.value) {
        if (rliController.attendanceState.value >= 20) {
          iconFile = 'images/icons/checkbox_on_in_hare.png';
        } else {
          iconFile = 'images/icons/checkbox_hare.png';
        }
      }
    }

    if (iconFile.isEmpty) {
      if (rliController.attendanceState.value >= 30) {
        iconFile = 'images/icons/checkbox_on_in.png';
      } else if (rliController.attendanceState.value >= 20) {
        iconFile = 'images/icons/checkbox_on_trail.png';
      }
    }

    if (iconFile.isEmpty) {
      switch (rliController.rsvpState.value) {
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
            if (rliController.attendanceState.value >= 20) {
              iconFile = 'images/icons/checkbox_on_in.png';
            } else {
              iconFile = 'images/icons/checkbox_hare.png';
            }
          }
          break;
        case -1:
          iconFile = 'wait';
          break;
      }
    }

    if (iconFile == 'wait') {
      return Icon(delayIcon, color: hc_blue, size: 24.0);
    }

    if (iconFile.isEmpty) {
      return const SizedBox();
    }

    return Image.asset(iconFile, height: 24.0, width: 24.0);
  }

  // Widget _getRsvpWidget() {
  //   String iconFile = '';

  //   switch (rliController.rsvpState.value) {
  //     case 3:
  //       if (rliController.isHareState.value == isHareYes.value) {
  //         iconFile = 'images/icons/checkbox_hare.png';
  //       }
  //       break;
  //   }

  //   if (iconFile.isEmpty) {
  //     switch (rliController.attendanceState.value) {
  //       case 20:
  //         iconFile = 'images/icons/checkbox_on_trail.png';
  //         break;
  //       case 30:
  //         iconFile = 'images/icons/checkbox_on_in.png';
  //         break;
  //     }
  //   }

  //   if (iconFile.isEmpty) {
  //     switch (rliController.rsvpState.value) {
  //       case 0:
  //         iconFile = 'images/icons/checkbox_empty.png';
  //         break;
  //       case 1:
  //         iconFile = 'images/icons/checkbox_no.png';
  //         break;
  //       case 2:
  //         iconFile = 'images/icons/checkbox_maybe.png';
  //         break;
  //       case 3:
  //         if (rliController.isHareState.value == isHareNo.value) {
  //           iconFile = 'images/icons/checkbox_yes.png';
  //         } else {
  //           iconFile = 'images/icons/checkbox_hare.png';
  //         }
  //         break;
  //       case -1:
  //         iconFile = 'wait';
  //         break;
  //     }
  //   }

  //   if (iconFile == 'wait') {
  //     return Icon(delayIcon, color: hc_blue, size: 24.0);
  //   }

  //   if (iconFile.isEmpty) {
  //     return const SizedBox();
  //   }

  //   return Image.asset(iconFile, height: 24.0, width: 24.0);
  // }

  void _showRsvpOptionsPopup() async {
    if (Utilities.isConnected(
      showDialog: true,
      message:
          'Setting run options is not available in offline mode. Please connect to the Internet.',
    )) {
      final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
        <String, dynamic>{
          'title': 'I\'ll be there!',
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
          'returnValue': rsvpYes,
        },
        <String, dynamic>{
          'title': 'I might be there',
          'icon': <Widget>[
            Image.asset(
              'images/icons/checkbox_maybe.png',
              width: 30,
              height: 30,
            ),
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
          'returnValue': rsvpMaybe,
        },
        <String, dynamic>{
          'title': 'I won\'t make it',
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
          'returnValue': rsvpNo,
        },
        // <String, dynamic>{
        //   'title': 'I\'ll hare!',
        //   'icon': <Widget>[
        //     Image.asset('images/icons/checkbox_hare.png',
        //         width: 30, height: 30),
        //     Container(
        //         height: 30,
        //         width: 30,
        //         decoration: BoxDecoration(
        //             color: Colors.transparent,
        //             shape: BoxShape.rectangle,
        //             border: Border.all(color: Colors.white, width: 3.0))),
        //   ],
        //   'returnValue': isHareYes
        // },
      ];

      final MultipleChoicePopupHc popup = MultipleChoicePopupHc(
        key: const Key('01019395'),
        title: 'Run Options',
        buttons: buttons,
        cancelButtonTitle: 'Cancel',
        cancelButtonReturnValue: followTypeCancel,
        otherControls: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Row(
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.only(right: 10),
                  height: 25,
                  width: 25,
                  color: Colors.yellow[100],
                  child: Obx(
                    () => Checkbox(
                      value:
                          rliController.automaticallySetNotifiationPrefs.value,
                      onChanged: (bool? value) async {
                        rliController.automaticallySetNotifiationPrefs.value =
                            value ?? true;
                        await setBoolPref(
                          BoolPrefsEnum.automaticallySetNotifiationPrefs,
                          value ?? true,
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Automatically set email and notification preferences for this run',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: ts_headingBlack,
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

      dynamic retVal = await Get.dialog<dynamic>(popup);

      if (retVal is EnumRsvpState) {
        await _setRsvpState(retVal);
      } else if (retVal is EnumIsHare) {
        // final bool willHare =
        //     await Utilities.promptForHare(futureRun.event.hares) ?? false;
        //await _setRsvpState(rsvpYes, willHare);
        await _setRsvpState(rsvpYes);
      }
    }
  }

  Future<void> _setRsvpState(EnumRsvpState rsvpState) async {
    rliController.rsvpState.value = -1;

    final String userId = currentUserId;
    final List<dynamic> adHocData = await tableModel.hasherEventMapService
        .setEventRsvp(
          futureRun.event.eventId,
          userId,
          AppDomainType.user,
          rsvpState.value,
          autoSetNotifications:
              rliController.automaticallySetNotifiationPrefs.value,
        );

    if (kDebugMode) debugPrint('[_setRsvpState/rli] adHocData length: ${adHocData.length}, contents: $adHocData');
    final int rsvpResult = adHocData[0]['rsvpState'];
    final int willHareResult = adHocData[0]['willHareState'];
    final String hares = adHocData[0]['hares'] ?? '';
    final String serverMessage = adHocData[0]['serverMessage'] ?? '';
    final int? eventNotificationPreference =
        adHocData[0]['eventNotificationPreference'];
    final int? emailAlertPreference = adHocData[0]['emailAlertPreference'];

    rliController.rsvpState.value = rsvpResult;
    rliController.isHareState.value = willHareResult;

    NotificationState? ns;

    if (eventNotificationPreference != null) {
      ns = NotificationState.fromInt(eventNotificationPreference);
      rliController.notificationPreference.value =
          ns ?? rliController.notificationPreference.value;
    }

    if (emailAlertPreference != null) {
      rliController.emailAlertPreference.value = emailAlertPreference;
    }

    if (rliController.hares.value != hares) {
      rliController.hares.value = hares;
    }

    // Keep the source model in sync so the controller re-initialises correctly
    // if this list item is recycled by ListView.builder after scrolling off screen.
    futureRun.extensions = futureRun.extensions.copyWith(
      rsvpState: rsvpResult,
      isHare: willHareResult,
      notificationPreference: eventNotificationPreference ??
          futureRun.extensions.notificationPreference,
      emailAlertPreference:
          emailAlertPreference ?? futureRun.extensions.emailAlertPreference,
    );

    if (serverMessage.isNotEmpty) {
      await Utilities.showAlert('RSVP Result', serverMessage, 'OK');
    }
  }

  Future<void> _showNotificationPopup() async {
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
      <String, dynamic>{
        'title': 'Use Kennel setting',
        'icon': <Widget>[
          Container(
            height: 30,
            width: 30,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          Positioned(
            left: 1,
            top: 1,
            child: Icon(FontAwesome.home, size: 28, color: Colors.red.shade900),
          ),
        ],
        'returnValue': NotificationState.auto,
      },
      // <String, dynamic>{
      //   'title': 'Set notifications to auto',
      //   'icon':  <Widget>[Container(height: 30, width: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), Positioned(left:3,top:1.5,child:Icon(MaterialCommunityIcons.bell_off, size:25, color: hc_red))],
      //   'returnValue': EnumNotificationPopupActions.NotificationState.auto,
      // },
    ];

    final MultipleChoicePopupHc popup = MultipleChoicePopupHc(
      key: const Key('661039301'),
      title: 'Notification options for this run',
      buttons: buttons,
      cancelButtonTitle: 'Cancel',
      cancelButtonReturnValue: NotificationState.unchanged,
    );

    dynamic retVal = await Get.dialog<dynamic>(
      popup,
      barrierDismissible: false, // user must tap button!
    );

    await _setNotificationState(retVal);
  }

  Future<void> _setEmailAlertState(EnumEmailAlertState retVal) async {
    if ((retVal == emailAlertsOn) ||
        (retVal == emailAlertsOff) ||
        (retVal == emailAlertsAuto)) {
      final String userId = currentUserId;
      final EnumEmailAlertState nState = retVal;
      rliController.setEmailState(-1);

      List<dynamic> results = await tableModel.hasherEventMapService
          .setEmailAndNotificationPreferences(
            futureRun.event.eventId,
            userId,
            AppDomainType.user,
            NotificationState.unchanged,
            nState,
          );

      rliController.setEmailState(results[0]?['emailAlertPreference'] ?? 0);
    }
  }

  Future<void> _setNotificationState(NotificationState retVal) async {
    if ((retVal != NotificationState.unchanged)) {
      final String userId = currentUserId;
      final NotificationState nState = retVal;
      rliController.setNotificationState(NotificationState.unchanged);

      List<dynamic> results = await tableModel.hasherEventMapService
          .setEmailAndNotificationPreferences(
            futureRun.event.eventId,
            userId,
            AppDomainType.user,
            nState,
            emailAlertsUnchanged,
          );

      // final NotificationSupport notifications = NotificationSupport();
      // notifications.setNotificationState(eventId: _rda.event.eventId);
      // // T0D0(James): Fix this to reflect true value of what is in the DB not just the value
      // // provided to the function
      rliController.setNotificationState(
        NotificationState.fromInt(results[0]?['notificationPreference'] ?? 0) ??
            NotificationState.auto,
      );
    }
  }

  Future<void> _showEmailAlertPopup() async {
    final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
      <String, dynamic>{
        'title': 'Turn email\r\nmessages on',
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
        'title': 'Turn email\r\nmessages off',
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
      <String, dynamic>{
        'title': 'Use Kennel setting',
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
              image: AssetImage('images/icons/envelope_silver_50px.png'),
            ),
          ),
        ],
        'returnValue': emailAlertsAuto,
      },
    ];

    final MultipleChoicePopupHc popup = MultipleChoicePopupHc(
      key: const Key('321039395'),
      title: 'Email options for this run',
      buttons: buttons,
      cancelButtonTitle: 'Cancel',
      cancelButtonReturnValue: followTypeCancel,
    );

    dynamic retVal = await Get.dialog<dynamic>(
      popup,
      barrierDismissible: false, // user must tap button!
    );

    await _setEmailAlertState(retVal);
  }
}
