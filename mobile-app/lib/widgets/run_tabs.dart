// import 'package:flutter/material.dart';

// ignore_for_file: constant_identifier_names

import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:harrier_central/pages/run_admin/add_down_down_page.dart';
import 'package:harrier_central/pages/live_run_pages/live_run_charges_page.dart';
import 'package:harrier_central/widgets/run_photo_gallery.dart';
import 'package:harrier_central/widgets/hc_badges.dart' as badges;
import 'package:eventide/eventide.dart';
import 'package:harrier_central/imports.dart';
import 'package:harrier_central/services/export/gpx_export_service.dart';
import 'package:harrier_central/widgets/beta_ribbon.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:map_launcher/map_launcher.dart' as maps;

// import 'package:manage_calendar_events/manage_calendar_events.dart' as calendar;

/// Chat tabs with their corresponding integer IDs.
enum RunTab {
  details(0),
  rsvp(1),
  map(2),
  stats(3),
  chat(4),
  photos(5);

  /// The integer ID associated with this tab.
  final int id;

  const RunTab(this.id);

  /// Lookup a ChatTab by its [id]. Throws if not found.
  factory RunTab.fromId(int id) {
    return RunTab.values.firstWhere(
      (tab) => tab.id == id,
      orElse: () => throw ArgumentError('No ChatTab with id $id'),
    );
  }
}

/// The run detail's six tabs. Stateless over [RunTabsController]; the map,
/// share sheet, zoomable photo and GPX export keep their BuildContext here.
class RunTabs extends StatelessWidget {
  const RunTabs({
    super.key,
    required this.futureRun,
    required this.relayActiveTab,
    this.openToTab = RunTab.details,
  });

  final RunDetailsAggregate futureRun;
  final RunTab openToTab;
  final Function relayActiveTab;

  @override
  Widget build(BuildContext context) {
    // Route-scoped: this PAGE's controllers, not the run's. Two pages for one
    // run (a notification tap pops the open one and pushes a fresh one in the
    // same frame) must not share them — the popped page deletes what it
    // created when its animation ends, under the page on screen.
    final String tag = routeScopedTag(
      context,
      RunTabsController.tagFor(futureRun.event.eventId),
    );
    return GetBuilder<RunTabsController>(
      init: RunTabsController(
        futureRun: futureRun,
        relayActiveTab: relayActiveTab,
        openToTab: openToTab,
        mapTag: routeScopedTag(context, futureRun.event.eventId),
      ),
      tag: tag,
      // `init` is ignored when this page's controller already exists (a
      // rebuild of the same page), so the requested tab is applied to
      // whichever controller the page has. A no-op on a fresh one.
      initState: (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<RunTabsController>(tag: tag)) {
          Get.find<RunTabsController>(tag: tag).showTab(openToTab);
        }
      }),
      builder: (RunTabsController c) => Obx(() => _body(context, c)),
    );
  }

  Widget _buildRunDetailsView(BuildContext context, RunTabsController c) {
    final bool hasAttended = futureRun.extensions.attendenceState >= 20;
    final bool isLoggedIn =
        (getStringPref(StringPrefsEnum.userId) ?? '').isNotEmpty;

    return RunDetails(
      futureRun.event,
      futureRun.kennel,
      futureRun.extensions.digitsAfterDecimal,
      futureRun.extensions.currencySymbol,
      futureRun.extensions.distanceUnitsPref,
      futureRun.extensions.distToEvent,
      futureRun.paymentUrl,
      true,
      futureRun.extensions.isMapAndDistanceValid == 1,
      eventUrlWithKennelBackup:
          futureRun.event.eventUrl ?? futureRun.kennel.kennelEventsUrl,
      isMember: futureRun.extensions.isMember,
      isPaid: futureRun.extensions.isPaid,
      rsvpState: futureRun.extensions.rsvpState,
      ianaTimeZone: futureRun.extensions.ianaTimeZone,
      processPayment: c.onPaymentProcessed,
      bottomExtension: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HashTrashView(
            kennelId: futureRun.kennel.kennelId,
            eventId: futureRun.event.eventId,
          ),
          if (isLoggedIn && hasAttended)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.sports_bar),
                label: const Text('Add Down Down'),
                onPressed: () {
                  if (Utilities.isConnected(showDialog: true)) {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => AddDownDownPage(
                          kennelId: futureRun.kennel.kennelId,
                          eventId: futureRun.event.eventId,
                          eventName: futureRun.event.eventName,
                          kennelSlug: futureRun.kennel.kennelUniqueShortName,
                          eventNumber: futureRun.event.eventNumber,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          if (isLoggedIn)
            _DownDownsHistoryView(
              kennelId: futureRun.kennel.kennelId,
              eventId: futureRun.event.eventId,
              eventName: futureRun.event.eventName,
              kennelSlug: futureRun.kennel.kennelUniqueShortName,
              eventNumber: futureRun.event.eventNumber,
              isPast: isRunPast(futureRun),
            ),
        ],
      ),
    );
  }

  Widget _buildRsvpView(BuildContext context, RunTabsController c) {
    final TextStyle rsvpTitlesView = ts_tileText.copyWith(
      fontSize: 20.0 * deviceInfo.deviceWidthScaleFactor,
      color: Colors.white,
    );
    return Obx(() {
      if (!c.packListLoaded.value) {
        return const HcAppCircularProgressIndicator(key: Key('42223995'));
      } else {
        final List<PackListAggregate> packList = c.packList;
        final int thisUserIndex = c.thisUserIndex.value;
        final PackListAggregate? currentUser =
            (thisUserIndex >= 0 && thisUserIndex < packList.length)
            ? packList[thisUserIndex]
            : null;

        return Center(
          child: Column(
            //mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedSize(
                duration: Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: !c.slideTopWidget.value
                    ? AnimatedOpacity(
                        opacity: c.showTopWidget.value ? 1.0 : 0.0,
                        duration: Duration(milliseconds: 400),
                        onEnd: c.onTopWidgetFaded,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: 15,
                            left: 20,
                            bottom: 0,
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  KennelLogo(
                                    kennelLogoUrl: futureRun.kennel.kennelLogo,
                                    kennelShortName:
                                        futureRun.kennel.kennelShortName,
                                    logoHeight: 70,
                                  ),
                                  SizedBox(width: 30),
                                  Expanded(child: _getRunDetails(Colors.white)),
                                  SizedBox(width: 20),
                                ],
                              ),
                              SizedBox(height: 25),
                              FancyDivider(
                                key: ValueKey('divider2342'),
                                innerColor: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      )
                    : SizedBox(),
              ), // Collapses cleanly

              StyleForConnected(
                child: Padding(
                  padding: const EdgeInsets.only(top: 15.0, bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width / 5.5,
                        child: Column(
                          children: <Widget>[
                            Text('Going', style: rsvpTitlesView),
                            Stack(
                              alignment: AlignmentDirectional.center,
                              children: <Widget>[
                                Positioned(
                                  // top: 6.5,
                                  // left: 6.5,
                                  child: Container(
                                    height: 36,
                                    width: 36,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(FontAwesome.check_circle),
                                  color: currentUser == null
                                      ? Colors.grey
                                      : currentUser.hem.rsvpState ==
                                            rsvpYes.value
                                      ? Colors.green
                                      : (currentUser.hem.rsvpState == -1 &&
                                            c.rsvpRequested.value == rsvpYes)
                                      ? hc_blue
                                      : Colors.grey,
                                  //tooltip: 'Select to follow a Kennel',
                                  iconSize: 35.0,
                                  alignment: Alignment.topCenter,
                                  splashColor: Colors.greenAccent,
                                  onPressed: () async {
                                    await c.setRsvpState(rsvpYes);
                                  },
                                  //   futureRun.attendingEvent +
                                  //               futureRun.haresCount >=
                                  //           0
                                  //       ? (futureRun.attendingEvent +
                                  //       : '',
                                  //   style: const TextStyle(
                                  //       fontFamily: 'AvenirNext',
                                  //       fontStyle: FontStyle.normal,
                                  //       fontSize: 20.0,
                                  //       height: 0.85),
                                ),
                              ],
                            ),
                            Text(
                              (c.packCount['rsvpYesCount'] ?? 0) >= 0
                                  ? (c.packCount['rsvpYesCount'] ?? 0)
                                        .toString()
                                  : '',
                              style: rsvpTitlesView,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width / 5.5,
                        child: Column(
                          children: <Widget>[
                            Text(
                              //'Maybe: ' + (futureRun.rsvpMaybeCount >= 0 ? futureRun.rsvpMaybeCount.toString() : ''),
                              'Maybe',
                              style: rsvpTitlesView,
                            ),
                            Stack(
                              alignment: AlignmentDirectional.center,
                              children: <Widget>[
                                Positioned(
                                  // top: 6.5,
                                  // left: 6.5,
                                  child: Container(
                                    height: 36,
                                    width: 36,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(FontAwesome.question_circle),
                                  color: currentUser == null
                                      ? Colors.grey
                                      : currentUser.hem.rsvpState ==
                                            rsvpMaybe.value
                                      ? Colors.orange
                                      : (currentUser.hem.rsvpState == -1 &&
                                            c.rsvpRequested.value == rsvpMaybe)
                                      ? hc_blue
                                      : Colors.grey,
                                  //tooltip: 'Select to follow a Kennel',
                                  iconSize: 35.0,
                                  alignment: Alignment.topCenter,
                                  splashColor: Colors.greenAccent,
                                  onPressed: () async {
                                    await c.setRsvpState(rsvpMaybe);
                                  },
                                ),
                              ],
                            ),
                            Text(
                              (c.packCount['rsvpMaybeCount'] ?? 0) >= 0
                                  ? (c.packCount['rsvpMaybeCount'] ?? 0)
                                        .toString()
                                  : '',
                              style: rsvpTitlesView,
                            ),
                            // Text(
                            //   futureRun.maybeAttendingEvent >= 0
                            //       ? futureRun.maybeAttendingEvent
                            //           .toString()
                            //       : '',
                            //   style: const TextStyle(
                            //       fontFamily: 'AvenirNext',
                            //       fontStyle: FontStyle.normal,
                            //       fontSize: 20.0,
                          ],
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width / 5.5,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              //'Not go: ' + (futureRun.rsvpNoCount >= 0 ? futureRun.rsvpNoCount.toString() : ''),
                              'Not go',
                              style: rsvpTitlesView,
                            ),
                            Stack(
                              alignment: AlignmentDirectional.center,
                              children: <Widget>[
                                Positioned(
                                  // top: 6.5,
                                  // left: 6.5,
                                  child: Container(
                                    height: 36,
                                    width: 36,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(FontAwesome.times_circle),
                                  color: currentUser == null
                                      ? Colors.grey
                                      : currentUser.hem.rsvpState ==
                                            rsvpNo.value
                                      ? hc_red
                                      : (currentUser.hem.rsvpState == -1 &&
                                            c.rsvpRequested.value == rsvpNo)
                                      ? hc_blue
                                      : Colors.grey,
                                  //tooltip: 'Select to follow a Kennel',
                                  iconSize: 35.0,
                                  alignment: Alignment.topCenter,
                                  splashColor: Colors.greenAccent,
                                  onPressed: () async {
                                    await c.setRsvpState(rsvpNo);
                                  },
                                ),
                              ],
                            ),
                            Text(
                              (c.packCount['rsvpNoCount'] ?? 0) >= 0
                                  ? (c.packCount['rsvpNoCount'] ?? 0).toString()
                                  : '',
                              style: rsvpTitlesView,
                            ),

                            // Text(
                            //   futureRun.notAttendingEvent >= 0
                            //       ? futureRun.notAttendingEvent
                            //           .toString()
                            //       : '',
                            //   style: const TextStyle(
                            //       fontFamily: 'AvenirNext',
                            //       fontStyle: FontStyle.normal,
                            //       fontSize: 20.0,
                          ],
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width / 5.5,
                        child: Column(
                          children: <Widget>[
                            Text(
                              // 'Hares: ' + (futureRun.haresCount >= 0 ? futureRun.haresCount.toString() : ''),
                              'Hares',
                              style: rsvpTitlesView,
                            ),
                            Stack(
                              alignment: AlignmentDirectional.center,
                              children: <Widget>[
                                Positioned(
                                  child: Container(
                                    height: 36,
                                    width: 36,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const ImageIcon(
                                    AssetImage('images/icons/hare_icon.png'),
                                  ),
                                  color: currentUser == null
                                      ? Colors.grey
                                      : currentUser.hem.isHare ==
                                            isHareYes.value
                                      ? Colors.deepPurple
                                      : currentUser.hem.isHare == -1
                                      ? hc_blue
                                      : Colors.grey,
                                  //tooltip: 'Select to follow a Kennel',
                                  iconSize: 30.0,
                                  alignment: Alignment.center,
                                  splashColor: Colors.greenAccent,
                                  onPressed: () async {
                                    //await _setRsvpHare();
                                  },
                                ),
                              ],
                            ),
                            Text(
                              (c.packCount['isHareCount'] ?? 0) >= 0
                                  ? (c.packCount['isHareCount'] ?? 0).toString()
                                  : '',
                              style: rsvpTitlesView,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: !c.packListLoaded.value
                    ? const SizedBox(
                        //color: Colors.grey[300],
                        width: 70.0,
                        height: 70.0,
                        child: Padding(
                          padding: EdgeInsets.all(5.0),
                          child: Center(
                            child: HcAppCircularProgressIndicator(
                              key: Key('22030392'),
                            ),
                          ),
                        ),
                      )
                    : ((packList.isEmpty) &&
                          (futureRun.event.eventStartDatetime.isAfter(
                            DateTime.now().subtract(const Duration(hours: 6)),
                          )))
                    ? Column(
                        children: <Widget>[
                          const Expanded(flex: 40, child: SizedBox()),
                          Text(
                            'Be the first to RSVP\r\nfor this run!',
                            style: ts_headingVeryLarge,
                            textAlign: TextAlign.center,
                          ),
                          if (currentUser == null) ..._getRsvpButtons(c),
                          if (currentUser == null) ...<Widget>[
                            const Expanded(flex: 40, child: SizedBox()),
                          ],
                        ],
                      )
                    : Column(
                        children: <Widget>[
                          if ((currentUser == null) &&
                              (futureRun.event.eventStartDatetime.isAfter(
                                DateTime.now().subtract(
                                  const Duration(hours: 6),
                                ),
                              )))
                            ..._getRsvpButtons(c),
                          if (currentUser == null) ...<Widget>[
                            const SizedBox(height: 10),
                          ],
                          if ((currentUser != null) &&
                              (currentUser.hem.rsvpState >=
                                  rsvpMaybe.value)) ...<Widget>[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: ElevatedButton(
                                child: SizedBox(
                                  width: 230.0,
                                  height: 40.0,
                                  child: Row(
                                    children: <Widget>[
                                      Stack(
                                        alignment: AlignmentDirectional.center,
                                        children: <Widget>[
                                          Container(
                                            height: 24,
                                            width: 24,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 22.0,
                                            width: 22.0,
                                            child: Icon(
                                              Icons.calendar_month,
                                              size: 22.0,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 15.0),
                                      Text('Add to calendar', style: ts_button),
                                    ],
                                  ),
                                ),
                                onPressed: () async {
                                  // THIS IS A H@CK: strip the "Z" timezone character off of the time so it imports as local time and not GMT
                                  String url =
                                      '$BASE_HASHRUNS_DOT_ORG_URL${futureRun.kennel.kennelUniqueShortName}/${futureRun.event.eventNumber}';

                                  String startTime = futureRun
                                      .event
                                      .eventStartDatetime
                                      .toString();
                                  startTime = startTime.substring(
                                    0,
                                    startTime.length - 1,
                                  );
                                  DateTime localTime =
                                      DateTime.tryParse(startTime) ??
                                      DateTime.now();

                                  String? oneLineLocForDesc =
                                      futureRun.event.locationOneLineDesc;

                                  String? oneLineLocForTitle;

                                  if ((oneLineLocForDesc != null) &&
                                      (oneLineLocForDesc.isNotEmpty)) {
                                    oneLineLocForTitle =
                                        ' @ $oneLineLocForDesc';
                                    oneLineLocForDesc =
                                        'Location: $oneLineLocForDesc\r\n\r\n';
                                  } else {
                                    oneLineLocForDesc = '';
                                    oneLineLocForTitle = '';
                                  }

                                  var eventide = Eventide();

                                  // Create an event in the default calendar (iOS write-only access)
                                  await eventide.createEventInDefaultCalendar(
                                    title:
                                        futureRun.event.eventName +
                                        oneLineLocForTitle,
                                    description:
                                        oneLineLocForDesc +
                                        (futureRun.event.eventDescription ??
                                            ''),
                                    location: Utilities.buildMapLocation(
                                      futureRun.event,
                                    ),
                                    startDate: localTime,
                                    endDate: localTime.add(Duration(hours: 4)),
                                    url: url,
                                  );

                                  closeAllSnackbarsSafely();

                                  if (!context.mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Colors.blue,
                                      content: Text(
                                        '${futureRun.event.eventName}$oneLineLocForTitle has been added to your calendar',
                                      ),
                                    ),
                                  );

                                  // if (success) {

                                  // calendar.CalendarEvent
                                  // newEvent = calendar.CalendarEvent(
                                  //   title:
                                  //       futureRun.event.eventName +
                                  //       oneLineLocForTitle,
                                  //   description:
                                  //       oneLineLocForDesc +
                                  //       (widget
                                  //               .futureRun
                                  //               .event
                                  //               .eventDescription ??
                                  //           ''),
                                  //   startDate: localTime,
                                  //   location:
                                  //       widget
                                  //           .futureRun
                                  //           .extensions
                                  //           .userFriendlyLocation,
                                  //   url:
                                  //       'https://www.hashruns.org/#/RID?publicEventId=${futureRun.event.publicEventId}&textTheme=light',
                                  // );

                                  // final calendar.CalendarPlugin
                                  // calendarPlugIn =

                                  //   calendarPlugIn
                                  //       .createEvent(
                                  //         calendarId: calendars[0].id!,
                                  //         event: newEvent,
                                  //             'Event Id is: $evenId',

                                  // Event event = Event(
                                  //   title:
                                  //       futureRun.event.eventName +
                                  //       oneLineLocForTitle,
                                  //   description:
                                  //       oneLineLocForDesc +
                                  //       (widget
                                  //               .futureRun
                                  //               .event
                                  //               .eventDescription ??
                                  //           ''),
                                  //   location:
                                  //       widget
                                  //           .futureRun
                                  //           .extensions
                                  //           .userFriendlyLocation,
                                  //   startDate: localTime,
                                  //       hours: 4,
                                  //     ), // on iOS, you can set alarm notification after your event.
                                  //     url:
                                  //         'https://www.hashruns.org/#/RID?publicEventId=${futureRun.event.publicEventId}&textTheme=light', // on iOS, you can set url to your event.
                                  //   //   emailInvites: [], // on Android, you can add invite emails to your event.

                                  // PermissionStatus ps;

                                  // await Add2Calendar.addEvent2Cal(event);

                                  // bool success = await Add2Calendar.addEvent2Cal(event);
                                },
                              ),
                            ),
                          ],
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            width: 140.0,
                            // Reviewed for 2.0+
                            child: TabBar(
                              isScrollable:
                                  true, // <-- required for labelPadding
                              tabAlignment: TabAlignment
                                  .center, // Flutter 3.13+ to keep centered

                              unselectedLabelColor: Colors.white,
                              labelColor: Colors.white,
                              indicatorSize: TabBarIndicatorSize.label,
                              // labelPadding: EdgeInsets.symmetric(
                              //   horizontal: 20.0,
                              // ),
                              indicatorPadding: EdgeInsets.symmetric(
                                horizontal: -5.0,
                                vertical: 3.0,
                              ),
                              indicator: BoxDecoration(
                                color: hc_red,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              tabs: const <Tab>[
                                Tab(
                                  icon: Icon(
                                    MaterialCommunityIcons
                                        .format_list_bulleted_square,
                                  ),
                                ),
                                Tab(
                                  icon: Icon(
                                    MaterialCommunityIcons.view_grid_outline,
                                  ),
                                ),
                              ],
                              controller: c.gridListTabController,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              //key: packListBox,
                              color: const Color.fromARGB(60, 255, 255, 255),
                              margin: const EdgeInsets.only(
                                left: 16.0,
                                right: 16.0,
                                bottom: 15.0,
                              ),
                              padding: const EdgeInsets.all(8.0),
                              width: MediaQuery.sizeOf(context).width,
                              child: Scrollbar(
                                controller: c.scrollController,
                                child: RefreshIndicator(
                                  onRefresh: () =>
                                      c.refreshHemTableFromBackend(true),
                                  child: c.gridListIndex.value == 0
                                      ? ListView.separated(
                                          separatorBuilder:
                                              (
                                                BuildContext context,
                                                int index,
                                              ) => const Divider(
                                                height: 3.0,
                                                color: Colors.black45,
                                                thickness: 1.5,
                                              ),
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          controller: c.scrollController,
                                          itemCount: packList.length,
                                          itemBuilder: (BuildContext context, int index) {
                                            final PackListAggregate e =
                                                packList[index];

                                            return GestureDetector(
                                              onTap: () async {
                                                if (e.hasher.photo != null) {
                                                  await _getHasherZoomablePhoto(
                                                    context,
                                                    e.hasher.photo!,
                                                    e.displayName,
                                                  );
                                                }
                                              },
                                              child: Row(
                                                children: <Widget>[
                                                  _rsvpIcon(e),
                                                  const SizedBox(width: 6.0),
                                                  Container(
                                                    height: 60,
                                                    width: 60,
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    child: _hasherPhoto(
                                                      e,
                                                      false,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8.0),
                                                  Expanded(
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 1.0,
                                                          ),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            e.hem.hemKennelHashName ??
                                                                e.displayName,
                                                            style:
                                                                ts_condensedLarge,
                                                          ),
                                                          if (e.homeKennelName !=
                                                              null)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    top: 4.0,
                                                                  ),
                                                              child: Text(
                                                                e.homeKennelName!,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style:
                                                                    ts_bodySmall,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        )
                                      : Builder(
                                          builder: (BuildContext context) {
                                            // Hares (few) render eagerly as
                                            // 2x2 tiles up top; the large
                                            // member list is a LAZY SliverGrid
                                            // below so a big pack no longer
                                            // builds every tile at once.
                                            final List<PackListAggregate>
                                            hares = packList
                                                .where(
                                                  (PackListAggregate e) =>
                                                      e.hem.isHare != 0,
                                                )
                                                .toList();
                                            final List<PackListAggregate>
                                            members = packList
                                                .where(
                                                  (PackListAggregate e) =>
                                                      e.hem.isHare == 0,
                                                )
                                                .toList();
                                            return CustomScrollView(
                                              controller: c.scrollController,
                                              slivers: <Widget>[
                                                if (hares.isNotEmpty)
                                                  SliverToBoxAdapter(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 8.0,
                                                          ),
                                                      child: GridView.count(
                                                        // Was StaggeredGrid.count with uniform 2x2 tiles
                                                        // in a 4-cell row — identical layout as a plain
                                                        // 2-column grid (package removed).
                                                        crossAxisCount: 2,
                                                        mainAxisSpacing: 8.0,
                                                        crossAxisSpacing: 8.0,
                                                        shrinkWrap: true,
                                                        physics:
                                                            const NeverScrollableScrollPhysics(),
                                                        children: hares
                                                            .map(
                                                              (
                                                                PackListAggregate
                                                                e,
                                                              ) => _packTile(
                                                                context,
                                                                e,
                                                              ),
                                                            )
                                                            .toList(),
                                                      ),
                                                    ),
                                                  ),
                                                SliverGrid(
                                                  gridDelegate:
                                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                                        crossAxisCount: 4,
                                                        mainAxisSpacing: 8.0,
                                                        crossAxisSpacing: 8.0,
                                                      ),
                                                  delegate:
                                                      SliverChildBuilderDelegate(
                                                        (
                                                          BuildContext context,
                                                          int index,
                                                        ) => _packTile(
                                                          context,
                                                          members[index],
                                                        ),
                                                        childCount:
                                                            members.length,
                                                      ),
                                                ),
                                                const SliverToBoxAdapter(
                                                  child: SizedBox(
                                                    height: 100.0,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      }
    });
  }

  /// A single pack-grid tile (photo + tap-to-zoom). Shared by the eager hare
  /// header and the lazy member grid.
  Widget _packTile(BuildContext context, PackListAggregate e) {
    return GestureDetector(
      onTap: () async {
        if (e.hasher.photo != null) {
          await _getHasherZoomablePhoto(
            context,
            e.hasher.photo!,
            e.displayName,
          );
        }
      },
      child: _hasherPhoto(e, true),
    );
  }

  Future<void> _getHasherZoomablePhoto(
    BuildContext context,
    String photo,
    String dispName,
  ) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ZoomableImagePage2(
          key: const Key('39392001'),
          pageTitle: dispName,
          imageUrl: blobUrlForPhoto(photo),
          appBarBackgroundColor: themeAppBarBackground,
          background: Backgrounds.defaultHcBackground(),
          margin: 20.0,
        ),
      ),
    );
  }

  Stack _hasherPhoto(PackListAggregate e, bool isGrid) {
    return Stack(
      children: <Widget>[
        Image(
          width: 300.0,
          height: 300.0,
          fit: BoxFit.fill,
          image: avatarImageProvider(
            e.hem.hemKennelUserPhoto ?? e.hasher.photo,
          ),
        ),
        if (isGrid) ...<Widget>[
          Positioned(right: 1.0, bottom: 1.0, child: _rsvpIcon(e)),
        ],
      ],
    );
  }

  Widget _getRunDetails(Color textColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AutoSizeText(
          futureRun.event.eventName,
          maxLines: 3,
          style: ts_tileTextLarge.copyWith(color: textColor),
        ),
        Text(
          DateFormat(
            'E, MMM d, yyyy, h:mm a',
          ).format(futureRun.event.eventStartDatetime),
          style: ts_listValueStyle.copyWith(color: textColor),
          textAlign: TextAlign.left,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if ((futureRun.event.locationOneLineDesc ?? '') != '')
          Text(
            futureRun.event.locationOneLineDesc!,
            style: ts_listValueStyle.copyWith(color: textColor),
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if ((futureRun.event.hares ?? '') != '')
          Text(
            'Hares: ${futureRun.event.hares!}',
            style: ts_listValueStyle.copyWith(color: textColor),
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Stack _rsvpIcon(PackListAggregate e) {
    return Stack(
      alignment: AlignmentDirectional.center,
      children: <Widget>[
        const CircleAvatar(backgroundColor: Colors.white, radius: 11.0),
        (e.hem.rsvpState <= 0)
            ? CircleAvatar(backgroundColor: hc_blue, radius: 10.0)
            : (e.hem.rsvpState == 1)
            ? Icon(FontAwesome.times_circle, color: hc_red, size: 21.0)
            : (e.hem.rsvpState == 2)
            ? const Icon(
                FontAwesome.question_circle,
                color: Colors.orange,
                size: 21.0,
              )
            : (e.hem.isHare == 0)
            ? const Icon(
                FontAwesome.check_circle,
                color: Colors.green,
                size: 21.0,
              )
            : Image.asset(
                'images/icons/hare_icon.png',
                color: Colors.deepPurple,
                height: 18.0,
                width: 18.0,
              ),
      ],
    );
  }

  Widget _buildPhotosView(RunTabsController c) {
    return RunPhotoGallery(
      eventName: futureRun.event.eventName,
      loader: () => KennelPhotoService().getRunPhotosForGallery(
        eventId: futureRun.event.eventId,
      ),
      kennelId: c.isAdmin ? futureRun.kennel.kennelId : null,
      kennelSlug: c.isAdmin ? futureRun.kennel.kennelUniqueShortName : null,
      eventNumber: c.isAdmin ? futureRun.event.absoluteEventNumber : null,
      run: futureRun,
    );
  }

  Widget _buildChatView(RunTabsController c) {
    return ColoredBox(
      color: Colors.yellow.shade100,
      child: Column(
        children: [
          AnimatedSize(
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: !c.slideTopWidget.value
                ? AnimatedOpacity(
                    opacity: c.showTopWidget.value ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 400),
                    onEnd: c.onTopWidgetFaded,
                    child: Padding(
                      padding: EdgeInsets.only(top: 15, left: 20, bottom: 15),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              KennelLogo(
                                kennelLogoUrl: futureRun.kennel.kennelLogo,
                                kennelShortName:
                                    futureRun.kennel.kennelShortName,
                                logoHeight: 70,
                              ),
                              SizedBox(width: 30),
                              Expanded(
                                child: _getRunDetails(themeAppBarBackground),
                              ),
                              SizedBox(width: 20),
                            ],
                          ),
                          //   innerColor: Colors.black,
                          // ),
                        ],
                      ),
                    ),
                  )
                : SizedBox(),
            //: SizedBox.expand(child: ColoredBox(color: Colors.white)),
          ), // Collapses cleanly

          Expanded(
            child: Stack(
              children: [
                ChatPage(
                  eventId: futureRun.event.eventId,
                  publicEventId: futureRun.event.publicEventId,
                ),
                BetaRibbon(
                  title: 'Trail Chat',
                  text:
                      'Trail Chat is a brand-new feature currently in beta. Over the next few releases, we’ll be continuing to improve and expand it — fixing any bugs and adding new functionality based on your feedback.\r\n\r\nYou may encounter occasional glitches as we refine the experience, but rest assured we’re actively working on updates in each release.\r\n\r\nOnce Trail Chat reaches full stability and feature completeness, this beta label will be removed.\r\n\r\nWe appreciate your patience and support as we make Trail Chat the best way to stay connected on the trail!',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView(BuildContext context, RunTabsController c) {
    final List<double?> coords = Utilities.getLatLongFromString(<String>[
      futureRun.event.locationOneLineDesc ?? '',
      futureRun.event.eventDescription ?? '',
      futureRun.event.eventName,
    ]);

    // The tracking button that used this is gone (see the note below the
    // map), but the CALL stays: ensure() REGISTERS the service when it is
    // absent, and several screens Get.find it without a guard. Dropping it
    // would leave them to throw on a path that had not opened a tracking
    // view first.
    LocationService.ensure();

    return ConnectedWidget(
      refreshFunction: c.update,
      showConnectButton: true,
      disconnectedChild: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Text(
            'Maps require a connection to the Internet',
            style: ts_headingLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                // Map
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: Stack(
                    alignment: AlignmentDirectional.center,
                    children: <Widget>[
                      RunTrackerMap(
                        futureRun.event,

                        (futureRun.extensions.evtLat ?? coords[0]) == null
                            ? null
                            : latlng.LatLng(
                                (futureRun.extensions.evtLat ?? coords[0]!),
                                (futureRun.extensions.evtLon ?? coords[1])!,
                              ),
                        c.mapCenter,
                        latlng.LatLng(
                          futureRun.kennel.kennelLatitude!,
                          futureRun.kennel.kennelLongitude!,
                        ),
                        1.0,
                        22.0,
                        14.0,
                        c.trueNorthLock.value,
                        // This page's own map controller (route-scoped).
                        controllerTag: c.mapTag,
                        // The map draws no controls of its own: they all
                        // live in the one left-hand column below, which the
                        // map positions over whichever canvas is showing.
                        showLocateButton: false,
                        overlayControls:
                            (BuildContext ctx, PackTrackCanvas canvas) =>
                                _mapControls(ctx, c, canvas),
                        mapMoved: (latlng.LatLng newPosition) {
                          c.mapCenter = newPosition;
                        },
                        markerClicked: () async {
                          await _launchMaps(context, c, futureRun);
                        },
                      ),
                      // Admin trim bar, as on the full-screen route: hidden
                      // until the scissors button starts editing, then sits
                      // just above the playback panel, whose laid-out height
                      // the map controller publishes.
                      Positioned.fill(
                        child: Builder(
                          builder: (BuildContext context) {
                            final String tag = c.mapTag;
                            Widget overlay(double panel) {
                              final double clearance = panel > 0
                                  ? panel + 12
                                  : 250;
                              return Padding(
                                padding: EdgeInsets.only(
                                  left: 12,
                                  right: 12,
                                  bottom: clearance,
                                ),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: TrimEditorOverlay(
                                    trimController: c.trimController(),
                                    showCollapsedPill: false,
                                  ),
                                ),
                              );
                            }

                            // No map controller yet means nothing reactive to
                            // read, and an Obx that reads no Rx throws
                            // "improper use" — so no Obx in that case.
                            if (!Get.isRegistered<RunTrackerMapController>(
                              tag: tag,
                            )) {
                              return overlay(0.0);
                            }
                            return Obx(
                              () => overlay(
                                Get.find<RunTrackerMapController>(
                                  tag: tag,
                                ).playbackPanelHeight.value,
                              ),
                            );
                          },
                        ),
                      ),
                      if (futureRun.extensions.isMapAndDistanceValid ==
                          0) ...<Widget>[
                        Positioned(
                          right: 10.0,
                          top: 10.0,
                          child: GestureDetector(
                            onTap: c.recenterMapOnEvent,
                            child: SizedBox(
                              height: 50.0,
                              width: 50.0,
                              child: Image.asset(
                                'images/other/set_map_to_event_location.png',
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 70.0,
                          top: 10.0,
                          child: GestureDetector(
                            onTap: c.recenterMapOnDevice,
                            child: SizedBox(
                              height: 50.0,
                              width: 50.0,
                              child: Image.asset(
                                'images/other/set_map_to_current_location.png',
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (futureRun.extensions.isMapAndDistanceValid !=
                          1) ...<Widget>[
                        Container(color: Colors.black54),
                        Container(
                          margin: const EdgeInsets.only(bottom: 60.0),
                          child: Text(
                            'No location provided',
                            textAlign: TextAlign.center,
                            style: ts_headingVeryLarge,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // The "Track my run" button used to sit here, under
          // the map. Removed 2026-09-20 (James): starting a track
          // belongs on the Run Tools screen, which is where it
          // now lives, and this copy offered it to anyone opening
          // the map — including people nowhere near the start,
          // reading the run from home.
        ],
      ),
    );
  }

  /// Every control that floats over the run map, in one left-hand column of
  /// identical circles — the same set, in the same slot, as the full-screen
  /// route. They used to be spread across both top corners in three different
  /// shapes and sizes, plus a red bar button below the map.
  ///
  /// Built PER CANVAS: the radar and the list are not maps, and a control that
  /// does nothing there is worse than no control. North-lock survives into the
  /// radar (it decides north-up vs heading-up) but means nothing on the list;
  /// locate moves a camera neither of them has. Share and GPX are about the
  /// RUN, not the rendering, so they stay on all three.
  Widget _mapControls(
    BuildContext context,
    RunTabsController c,
    PackTrackCanvas canvas,
  ) {
    final bool isMap = canvas == PackTrackCanvas.map;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (canvas != PackTrackCanvas.list) ...<Widget>[
          // Same circle as every other control, here and on the full-screen
          // route: the compass used to be a bare image in its own artwork,
          // the one button in the column that did not match the rest.
          MapOverlayButton(
            icon: c.trueNorthLock.value ? Icons.explore : Icons.navigation,
            tooltip: c.trueNorthLock.value ? 'North up' : 'Rotate with heading',
            onTap: c.toggleTrueNorthLock,
          ),
          const SizedBox(height: 10.0),
        ],
        // Opens on the canvas you were looking at, so this enlarges the
        // radar or the list rather than quietly switching you to the map.
        MapOverlayButton(
          icon: Icons.fullscreen,
          tooltip: 'Full screen',
          onTap: () => Get.to<void>(
            () => PackTrackFullScreenMap(run: futureRun, initialCanvas: canvas),
          ),
        ),
        const SizedBox(height: 10.0),
        MapOverlayButton(
          icon: Icons.ios_share,
          tooltip: 'Share this run',
          onTap: () =>
              unawaited(RunShareLinks(futureRun).showShareSheet(context)),
        ),
        // Map only — it moves the map camera. Same gate the map itself used:
        // no point offering to centre on a location we do not have.
        if (isMap &&
            appModel.hasLocationPermissions &&
            deviceInfo.deviceLat != null &&
            deviceInfo.deviceLon != null) ...<Widget>[
          const SizedBox(height: 10.0),
          MapOverlayButton(
            icon: Icons.near_me,
            tooltip: 'My location',
            onTap: c.recenterMapOnUser,
          ),
        ],
        // Only when a track actually exists. It used to be gated on the run
        // having OPENED, which is a clock test — a run can open, and finish,
        // with nobody pressing start, and the button was then offered for a
        // run with nothing to export. Same gate on the full-screen map.
        _trackOnlyControls(context, c),
      ],
    );
  }

  /// Controls that act ON a recorded track, so they appear only once there is
  /// one. Reactive: the column is built inside RunTrackerMap's GetBuilder, so
  /// the map controller exists here, and the Obx rebuilds when positions land.
  Widget _trackOnlyControls(BuildContext context, RunTabsController c) {
    final String tag = c.mapTag;
    if (!Get.isRegistered<RunTrackerMapController>(tag: tag)) {
      return const SizedBox.shrink();
    }
    final RunTrackerMapController controller =
        Get.find<RunTrackerMapController>(tag: tag);

    final PackTrackTrimController trimController = c.trimController();

    return Obx(() {
      if (!controller.hasRecordedTrack) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 10.0),
          MapOverlayButton(
            label: 'GPX',
            tooltip: 'Export GPX',
            onTap: () => unawaited(_exportOwnTrack(context, c)),
          ),
          // Same control, same slot, same gate as the full-screen route.
          if (trimController.isAdmin) ...<Widget>[
            const SizedBox(height: 10.0),
            MapOverlayButton(
              tooltip: 'Trim run',
              icon: Icons.content_cut,
              onTap: trimController.toggleEditing,
            ),
          ],
        ],
      );
    });
  }

  Future<void> _exportOwnTrack(
    BuildContext context,
    RunTabsController c,
  ) async {
    if (c.isExportingTrack.value) return;
    final String tag = c.mapTag;
    if (!Get.isRegistered<RunTrackerMapController>(tag: tag)) {
      _showExportMessage(context, 'No track data available yet.');
      return;
    }
    await _exportCurrentUserTrack(
      context,
      c,
      Get.find<RunTrackerMapController>(tag: tag),
    );
  }

  Future<void> _exportCurrentUserTrack(
    BuildContext context,
    RunTabsController c,
    RunTrackerMapController controller,
  ) async {
    final UserTrack? track = c.currentUserTrack(controller);
    if (track == null) {
      _showExportMessage(context, 'No track data available yet.');
      return;
    }

    c.isExportingTrack.value = true;

    try {
      final exporter = GpxExportService();
      final trackName = futureRun.event.eventName;
      await exporter.exportTrack(
        context: context,
        track: track,
        trackName: trackName,
      );
    } catch (error, s) {
      BootLogger.logError(
        '[RunTabs._exportTrack] trackName=${futureRun.event.eventName} eventId=${futureRun.event.eventId}',
        error,
        s,
      );
      if (context.mounted) _showExportMessage(context, 'Export failed: $error');
    } finally {
      if (!c.isClosed) c.isExportingTrack.value = false;
    }
  }

  void _showExportMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _getRsvpButton(
    RunTabsController c,
    IconData iconData,
    Color iconColor,
    String text,
    EnumRsvpState rsvpState,
  ) {
    return StyleForConnected(
      child: ElevatedButton(
        child: SizedBox(
          width: 200.0,
          child: Row(
            children: <Widget>[
              Stack(
                alignment: AlignmentDirectional.center,
                children: <Widget>[
                  Container(
                    height: 24,
                    width: 24,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(
                    height: 22.0,
                    width: 22.0,
                    child: Icon(iconData, size: 22.0, color: iconColor),
                  ),
                ],
              ),
              const SizedBox(width: 15.0),
              Text(text, style: ts_button),
            ],
          ),
        ),
        onPressed: () async {
          await c.setRsvpState(rsvpState);
        },
      ),
    );
  }

  List<Widget> _getRsvpButtons(RunTabsController c) {
    // A past run cannot be RSVP'd to. The three buttons were still offered on
    // finished runs, where they say nothing useful and take most of the screen
    // above the attendee list. The counts and the roster stay — those are the
    // interesting part of a run that has happened.
    if (isRunPast(futureRun)) {
      return const <Widget>[SizedBox(height: 12.0)];
    }

    if (c.rsvpRequested.value != rsvpUnknown) {
      return <Widget>[
        const HcAppCircularProgressIndicator(key: Key('3920394')),
      ];
    } else {
      return <Widget>[
        const SizedBox(height: 30.0),
        _getRsvpButton(
          c,
          FontAwesome.check_circle,
          Colors.green,
          'I\'ll be there!',
          rsvpYes,
        ),
        _getRsvpButton(
          c,
          FontAwesome.check_circle,
          Colors.orange,
          'I might come',
          rsvpMaybe,
        ),
        _getRsvpButton(
          c,
          FontAwesome.check_circle,
          hc_red,
          'I will not come',
          rsvpNo,
        ),
      ];
    }
  }

  Widget _body(BuildContext context, RunTabsController c) {
    final bool fabIsVisible = c.fabIsVisible.value;
    return Stack(
      children: <Widget>[
        AppScaffold(
          floatingActionButton: (!fabIsVisible)
              ? null
              : StyleForConnected(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: fabIsVisible ? 1.0 : 0.0,
                    child: SpeedDial(
                      // both default to 16
                      // marginEnd: 18,
                      // marginBottom: 20,
                      animatedIcon: AnimatedIcons.menu_close,
                      animatedIconTheme: const IconThemeData(size: 22.0),
                      visible: true,
                      curve: Curves.bounceIn,
                      overlayColor: Colors.black,
                      overlayOpacity: 0.5,
                      onOpen: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      },
                      //onClose: () => //print('DIAL CLOSED'),
                      tooltip: 'Speed Dial',
                      heroTag: 'speed-dial-hero-tag-722526',
                      backgroundColor: hc_red,
                      foregroundColor: Colors.white,
                      elevation: 8.0,
                      shape: const CircleBorder(),
                      children: <SpeedDialChild>[
                        SpeedDialChild(
                          child: const Icon(Feather.x),
                          backgroundColor: hc_red,
                          label: 'I\'m not coming',
                          labelStyle: const TextStyle(fontSize: 18.0),
                          onTap: () async {
                            await c.setRsvpState(rsvpNo);
                          },
                        ),
                        SpeedDialChild(
                          child: const Icon(AntDesign.question),
                          backgroundColor: Colors.orange,
                          label: 'I might come',
                          labelStyle: const TextStyle(fontSize: 18.0),
                          onTap: () async {
                            await c.setRsvpState(rsvpMaybe);
                          },
                        ),
                        SpeedDialChild(
                          child: const Icon(Feather.check),
                          backgroundColor: Colors.green,
                          label: 'I\'m coming',
                          labelStyle: const TextStyle(fontSize: 18.0),
                          onTap: () async {
                            await c.setRsvpState(rsvpYes);
                          },
                        ),
                        //   backgroundColor: Colors.white,
                        //   label: 'I will hare',
                        //   },
                        // ),
                      ],
                    ),
                  ),
                ),
          body: Container(
            decoration: Backgrounds.defaultHcBackground(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                PreferredSize(
                  preferredSize: const Size.fromHeight(120.0),
                  child: Container(
                    width: MediaQuery.sizeOf(context).width,
                    height: 48.0,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColorLight,
                    ),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.grey[300]),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5.0,
                        vertical: 2.0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: TabBar(
                                labelStyle: ts_tabSelected,
                                unselectedLabelStyle: ts_tabUnselected,
                                isScrollable: false,
                                labelPadding: const EdgeInsets.only(
                                  top: 3.0,
                                  left: 6.0,
                                  right: 6.0,
                                ),
                                dividerHeight: 0,
                                unselectedLabelColor: Colors.black,
                                labelColor: Colors.white,
                                indicatorSize: TabBarIndicatorSize.tab,
                                indicatorPadding: const EdgeInsets.symmetric(
                                  vertical: 6.0,
                                  horizontal: 4.0,
                                ),
                                indicator: BoxDecoration(
                                  color: hc_red,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                tabs: RunTabsController.tabs,
                                controller: c.tabController,
                              ),
                            ),
                          ),

                          Builder(
                            builder: (_) {
                              // The null check lives OUTSIDE the Obx, on
                              // purpose. An Obx whose builder returns
                              // without reading an observable does not
                              // render nothing — GetX THROWS ("improper use
                              // of a GetX"), and in release that paints an
                              // error box. This Builder re-runs on the same
                              // rebuilds the Obx would, so a service that
                              // has gone is still caught, just one frame
                              // up, where returning early is safe.
                              final ns = notificationServiceOrNull;
                              if (ns == null) return const SizedBox();
                              return Obx(() {
                                final count =
                                    ns
                                        .unreadEventCounts[futureRun
                                            .event
                                            .publicEventId]
                                        ?.value ??
                                    0;
                                if (count == 0) return const SizedBox();
                                return badges.Badge(
                                  position: badges.BadgePosition.topEnd(
                                    top: -5,
                                    end: 0,
                                  ),
                                  badgeContent: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
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
                                    badgeColor: Colors.red.shade800,
                                    padding: const EdgeInsets.all(6),
                                  ),
                                );
                              });
                            },
                          ),

                          // if ((chatCount > 0) &&
                          //     (_tabController.index != 4)) ...<Widget>[
                          //   badges.Badge(
                          //     position: badges.BadgePosition.topEnd(
                          //       top: 0,
                          //       end: 0,
                          //       //color: Colors.pink,
                          //       padding: EdgeInsets.symmetric(
                          //         horizontal: 2,
                          //       ),
                          //       width: 30,
                          //       height: 13,
                          //         textAlign: TextAlign.center,
                          //         maxLines: 1,
                          //         minFontSize: 10,
                          //         maxFontSize: 13,
                          //         style: ts_badge,
                          //       badgeColor: Colors.red.shade800,
                          // ],
                        ],
                      ),
                    ),
                  ),
                ),
                _buildLiveRunButton(context, c),
                Expanded(
                  child: TabBarView(
                    controller: c.tabController,
                    children: <Widget>[
                      _buildRunDetailsView(context, c),
                      _buildRsvpView(context, c),
                      _buildMapView(context, c),
                      ConnectedWidget(
                        refreshFunction: c.update,
                        showConnectButton: true,
                        disconnectedChild: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Center(
                            child: Text(
                              '"Get a life" leaderboards require a connection to the Internet',
                              style: ts_headingLarge,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        child: Leaderboard(kennelId: futureRun.kennel.kennelId),
                      ),
                      _buildChatView(c),
                      _buildPhotosView(c),
                    ],
                    //     tab.text,
                  ),
                ),
              ],
            ),
          ),
        ),
        OfflineModeRibbon(
          lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSync),
          ribbonImage: 'images/icons/offline_mode.png',
          refreshFunction: () {},
          //refreshFunction: () => controller.initialize(),
        ),
      ],
    );
  }

  Future<void> _launchMaps(
    BuildContext context,
    RunTabsController c,
    RunDetailsAggregate rda,
  ) async {
    double? lat;
    double? lon;
    String address = '';

    if (rda.extensions.evtLat != null) {
      lat = rda.extensions.evtLat;
    }

    if (rda.extensions.evtLon != null) {
      lon = rda.extensions.evtLon;
    }

    if ((lat == null) || (lon == null)) {
      // try to get lat/lons from other sources
      final List<double?> coords = Utilities.getLatLongFromString(<String>[
        rda.event.locationOneLineDesc ?? '',
        rda.event.eventDescription ?? '',
        rda.event.eventName,
      ]);

      if ((coords[0] != null) && (coords[1] != null)) {
        lat = coords[0]!;
        lon = coords[1]!;
      }
    }

    if (rda.event.locationStreet != null) {
      address = '$address${rda.event.locationStreet} ';
    }

    if (rda.event.locationCity != null) {
      address = '$address${rda.event.locationCity} ';
    }

    if (rda.event.locationPostCode != null) {
      address = '$address${rda.event.locationPostCode} ';
    }

    if (rda.event.locationCountry != null) {
      address = '$address${rda.event.locationCountry} ';
    }

    address = address.trim();

    if ((address.isEmpty) && (lat == null || lon == null)) {
      address = rda.event.locationOneLineDesc ?? '';
    }

    // use the native map provider for the selected platform
    if ((lat != null) && (lon != null)) {
      final String? mapName = getStringPref(StringPrefsEnum.mapPreference);
      if (mapName == null) {
        await Utilities.openMapsSheet(
          context,
          address,
          maps.Coords(lat, lon),
          rda.event.eventName,
          c.saveUserMapPreference,
        );
      } else {
        final List<maps.AvailableMap> availableMaps =
            await maps.MapLauncher.installedMaps;
        final maps.AvailableMap? activeMap = availableMaps
            .where((maps.AvailableMap map) => map.mapName == mapName)
            .firstOrNull;
        if (activeMap == null) return;

        // BUG in plugin - doesn't work when sending a title with Google maps
        await activeMap.showMarker(
          coords: maps.Coords(lat, lon),
          title: activeMap.mapName.contains('Google') ? '' : address,
          description: address,
        );
      }
    } else {
      await Utilities.showAlert(
        'No location information available',
        'There is no location information available for this run and so we cannot display a map',
        'OK',
      );
    }
  }

  Widget _buildLiveRunButton(BuildContext context, RunTabsController c) {
    final state = c.liveRunStatus.value;
    final loading = c.liveRunLoading.value;
    final bool isActiveRun = state == LiveRunButtonStatus.active;

    if (state == LiveRunButtonStatus.hidden) return const SizedBox.shrink();

    final String label = isActiveRun
        ? 'Return to Live Run Tools'
        : 'Show Live Run Tools';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
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
                    c.startLiveRun();
                  }
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LiveRunShell(run: futureRun),
                    ),
                  );
                  await c.refreshLiveRunButton();
                },
        ),
      ),
    );
  }
}

/// Loads and displays published HashTrash for a run.
/// Renders nothing if the event has no published HashTrash.
class _HashTrashView extends StatelessWidget {
  const _HashTrashView({required this.kennelId, required this.eventId});

  final String kennelId;
  final String eventId;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HashTrashViewController>(
      init: HashTrashViewController(kennelId: kennelId, eventId: eventId),
      tag: routeScopedTag(context, HashTrashViewController.tagFor(eventId)),
      builder: (HashTrashViewController c) => Obx(() {
        final HashTrashModel? model = c.model.value;
        if (!c.loaded.value ||
            model == null ||
            (model.headline.isEmpty &&
                (model.content == null || model.content!.isEmpty))) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FancyDivider(
              key: Key('hash_trash_divider'),
              innerColor: Colors.white,
              topMargin: 20,
              bottomMargin: 10,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Hash Trash',
                    style: ts_headingLarge.copyWith(color: Colors.white),
                  ),
                  if (model.isDraft) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'DRAFT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Markdown(
                data: model.headline.isNotEmpty
                    ? '# ${model.headline}\n\n${model.content ?? ''}'
                    : (model.content ?? ''),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ── Charges history (visible to kennel members) ───────────────────────────────
//
// Completed charges while the run is upcoming or under way; every charge
// that was not cancelled once the run is past — the server draws that line
// (hcapp_getCompletedDownDowns, six hours after the start), the pending ones
// are marked here. Those who can manage down-downs get a button into the
// charges page, so a past run's circle can still be recorded and marked done.

class _DownDownsHistoryView extends StatelessWidget {
  const _DownDownsHistoryView({
    required this.kennelId,
    required this.eventId,
    required this.eventName,
    required this.kennelSlug,
    required this.eventNumber,
    required this.isPast,
  });

  final String kennelId;
  final String eventId;
  final String eventName;
  final String kennelSlug;
  final int eventNumber;
  final bool isPast;

  Future<void> _openChargesPage(
    BuildContext context,
    DownDownsHistoryController c,
  ) async {
    if (!Utilities.isConnected(showDialog: true)) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LiveRunChargesPage(
          kennelId: kennelId,
          eventId: eventId,
          eventName: eventName,
          kennelSlug: kennelSlug,
          eventNumber: eventNumber,
        ),
      ),
    );
    // Charges may have been added, marked done or cancelled: the run card's
    // count lives on the synced event row and follows with the next sync.
    await c.load();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DownDownsHistoryController>(
      init: DownDownsHistoryController(kennelId: kennelId, eventId: eventId),
      tag: routeScopedTag(context, DownDownsHistoryController.tagFor(eventId)),
      builder: (DownDownsHistoryController c) => Obx(() {
        if (!c.loaded.value) return const SizedBox.shrink();
        final List<DownDownModel> charges = c.charges;
        // A manager sees the section on a past run even when it is empty —
        // that is the way in to record a circle nobody wrote down on the
        // night.
        final bool showManage = c.canManage.value && isPast;
        if (charges.isEmpty && !showManage) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FancyDivider(
              key: Key('down_downs_divider'),
              innerColor: Colors.white,
              topMargin: 20,
              bottomMargin: 10,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  const Icon(
                    MaterialCommunityIcons.gavel,
                    color: Colors.yellow,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Down Downs',
                      style: ts_headingLarge.copyWith(color: Colors.yellow),
                    ),
                  ),
                  if (showManage)
                    TextButton.icon(
                      onPressed: () => unawaited(_openChargesPage(context, c)),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Manage',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            if (charges.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'No down downs recorded for this run.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            for (final dd in charges) _DownDownHistoryTile(dd: dd),
            const SizedBox(height: 16),
          ],
        );
      }),
    );
  }
}

class _DownDownHistoryTile extends StatelessWidget {
  const _DownDownHistoryTile({required this.dd});

  final DownDownModel dd;

  @override
  Widget build(BuildContext context) {
    final names = dd.allChargedNames.join(', ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (names.isNotEmpty)
            Text(
              names,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.yellow,
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'by ${dd.createdByDisplayName}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.yellow,
                  ),
                ),
              ),
              if (!dd.isDone)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white54),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Not marked done',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dd.chargeText,
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
          if (dd.songChoice != null && dd.songChoice!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.music_note, size: 13, color: Colors.white54),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      dd.songChoice!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (dd.chargePhotoUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  dd.chargePhotoUrl!,
                  height: 120,
                  width: double.infinity,
                  // Decode to the strip height, not the photo's full res.
                  cacheHeight: 360,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          const Divider(height: 16, color: Colors.white24),
        ],
      ),
    );
  }
}
