import 'package:calendar_date_picker2/calendar_date_picker2.dart' as calendar;
import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

class FutureRunsListPage extends StatelessWidget {
  FutureRunsListPage() : super(key: UniqueKey());

  // Initialize the controller with the provided arguments
  final FutureRunListPageController controller = Get.put(
    FutureRunListPageController(),
    // permanent: true,
  );

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: GetBuilder<FutureRunListPageController>(
          id: 'runList',
          builder: (listController) {
            return listController.allRuns == null
                ? HcAppCircularProgressIndicator(key: UniqueKey())
                : _buildListView(listController);
          },
        ),
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return AppScaffold(
  //       body: controller.allRuns == null
  //           ? HcAppCircularProgressIndicator(key: UniqueKey())
  //           : _buildListView(controller));
  // }

  Future<void> refreshFromTableExternal() async {
    await controller.refreshFromTable(true);
  }

  Widget _searchBar(BuildContext context) {
    return SizedBox(
      height: 131.0,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Divider(height: 2.0, thickness: 2.0),
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 14.0),
              child: Material(
                color: Colors.transparent,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        autocorrect: false,
                        onChanged: (text) =>
                            controller.searchRunsText.value = text,

                        focusNode: controller.searchFocusNode,
                        controller: controller.searchController,
                        keyboardType: TextInputType.text,
                        style: ts_footnoteBlack,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          icon: const Icon(
                            FontAwesome.search,
                            color: Colors.black,
                          ),
                          hintText: 'Search...',
                          hintStyle: ts_searchLabel,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          shape: button_shape,
                          textStyle: TextStyle(color: Colors.grey.shade700),
                          backgroundColor: Colors.white,
                        ),
                        child: Text(
                          'X',
                          style: ts_headingBlack.copyWith(
                            color: Colors.grey.shade700,
                          ),
                        ),
                        onPressed: () {
                          controller.searchController.text = '';
                          controller.searchRunsText.value = '';
                          //setState(() {
                          controller.filterRuns(true);
                          //});
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1.0, thickness: 1.0, color: Colors.grey),
          Container(
            color: Colors.grey.shade200,
            height: 24.0,
            child: Obx(() {
              return Align(
                alignment: Alignment.center,

                child: Text(
                  'Showing ${controller.resultCount.value} runs',
                  style: ts_titleSmallCondensedBlack,
                ),
              );
            }),
          ),
          const Divider(height: 1.0, thickness: 1.0, color: Colors.grey),

          Container(
            color: Colors.black38,
            height: 55,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 10),
                    _runsToDisplayButton(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 7.0),
                        child: Center(
                          child: Column(
                            children: [
                              AutoSizeText(
                                minFontSize: 5,
                                maxFontSize: 24,
                                maxLines: 1,
                                controller.runsToDisplay.value.label.replaceAll(
                                  '~',
                                  '${controller.runsTimeScope.value.label} ',
                                ),
                                style: ts_titleLarge,
                              ),
                              if (controller.runsTimeScope.value ==
                                  RunsTimeScope.range)
                                AutoSizeText(
                                  ((controller.dateFilterStart.value ==
                                              controller.dateFilterEnd.value) &&
                                          (controller
                                              .multiYearDateFilter
                                              .value))
                                      ? DateFormat('d MMM').format(
                                          controller.dateFilterStart.value,
                                        )
                                      : ((controller.dateFilterStart.value ==
                                                controller
                                                    .dateFilterEnd
                                                    .value) &&
                                            (!controller
                                                .multiYearDateFilter
                                                .value))
                                      ? DateFormat('d MMM yy').format(
                                          controller.dateFilterStart.value,
                                        )
                                      : controller.multiYearDateFilter.value
                                      ? '${DateFormat('d MMM').format(controller.dateFilterStart.value)} \u2794 ${DateFormat('d MMM').format(controller.dateFilterEnd.value)}'
                                      : '${DateFormat('d MMM yy').format(controller.dateFilterStart.value)} \u2794 ${DateFormat('d MMM yy').format(controller.dateFilterEnd.value)}',
                                  minFontSize: 5,
                                  maxFontSize: 16,
                                  maxLines: 1,

                                  style: ts_titleLarge,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (controller.runsToDisplay.value == RunsToDisplay.onMap)
                      SizedBox(width: 42, child: _showMapButton()),

                    if (controller.runsToDisplay.value ==
                        RunsToDisplay.unreadChats)
                      SizedBox(width: 42, child: _showResetChatCountsButton()),

                    ((controller.runsToDisplay.value != RunsToDisplay.onMap) &&
                            (controller.runsToDisplay.value !=
                                RunsToDisplay.unreadChats))
                        ? SizedBox(width: 42, child: _futurePastButton())
                        : SizedBox.shrink(),
                    SizedBox(width: 5),
                    if (controller.runsTimeScope.value != RunsTimeScope.range)
                      GestureDetector(
                        onTap: () async {
                          await Utilities.showAlert(
                            controller.runsToDisplay.value.helpTitle,
                            controller.runsToDisplay.value.helpText,
                            'OK',
                          );
                        },
                        child: SizedBox(
                          height: 33,
                          width: 42,
                          child: Image.asset('images/icons/info_button.png'),
                        ),
                      ),

                    if (controller.runsTimeScope.value == RunsTimeScope.range)
                      SizedBox(width: 42, child: _showCalendarButton(context)),
                    SizedBox(width: 10),
                  ],
                ),
                // SizedBox(height: 5.0),
                // Padding(
                //   padding: const EdgeInsets.symmetric(horizontal: 14.0),
                //   child: Row(
                //     children: [
                //       Expanded(
                //         child: Container(
                //           padding: EdgeInsets.only(right: 10),
                //           child: AutoSizeText(
                //             controller.runsToDisplay.value.description,
                //             style: ts_bodyYellow,
                //             textAlign: TextAlign.center,
                //             maxLines: 2,
                //           ),

                //           //height: 100,
                //           // width: 100,
                //         ),
                //       ),

                //       SizedBox(width: 10),

                //       GestureDetector(
                //         onTap: () async {
                //           await Utilities.showAlert(
                //             controller.runsToDisplay.value.helpTitle,
                //             controller.runsToDisplay.value.helpText,
                //             'OK',
                //           );
                //         },
                //         child: SizedBox(
                //           height: 35,
                //           child: Image.asset('images/icons/info_button.png'),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
              ],
            ),
          ),
          const Divider(height: 2.0, thickness: 2.0, color: Colors.black),
        ],
      ),
    );
  }

  Widget _buildListView(FutureRunListPageController listController) {
    String noRunsTitle = 'No Runs available';
    String noRunsDescription =
        'If you have set a date range or search text, you may want to clear those to see all available runs.';

    switch (controller.runsToDisplay.value) {
      case RunsToDisplay.onMap:
        noRunsTitle = 'No runs on the map';
        noRunsDescription =
            'There are no runs to display based on the area currently being displayed on the map.\r\n\r\nTry zooming out or moving the map to a different area.';
        break;
      case RunsToDisplay.unreadChats:
        noRunsTitle = 'You\'re up to date!';
        noRunsDescription =
            'This view shows you all runs past and future that have chat messages you have not yet seen.\r\n\r\nYou have either seen all chats for your runs (great job staying in the loop!) or you have set a text filter.\r\n\r\nIf you have runs with chats, please clear the text filter to see them.';
        break;
      case RunsToDisplay.myRuns:
        noRunsTitle = 'No runs available';
        noRunsDescription =
            'This view shows you runs you\'ve attended or plan to attend.\r\n\r\nYou can RSVP to upcoming runs from the run details page. Past runs that you have attended will also show up here.\r\n\r\nIf you have set a date range or search text, you may want to clear those to see your runs.';
        break;
      case RunsToDisplay.allRuns:
        noRunsTitle = 'No runs available';
        noRunsDescription =
            'This view shows all upcoming runs in Harrier Central and all runs in the past for Kennels you follow.\r\n\r\nIf you have set a date range or search text, you may want to clear those to see all available runs.';
        break;
      case RunsToDisplay.events:
        noRunsTitle = 'No events available';
        noRunsDescription =
            'This view shows you runs that have been marked as events.\r\n\r\nIf you have set a date range or search text, you may want to clear those to see available events.';
        break;
    }

    bool noRunsAvaiable = false;

    if (controller.filteredRuns.isEmpty) {
      noRunsAvaiable = true;
    }

    // Check if every element in the non-empty list is an integer
    if (controller.filteredRuns.every((element) => element is int)) {
      noRunsAvaiable = true;
    }

    return NestedScrollView(
      controller: controller.scrollController,
      floatHeaderSlivers: true,
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
          // SliverList(
          //   delegate: SliverChildListDelegate(<Widget>[_searchBar()]),
          // ),
          SliverAppBar(
            expandedHeight: 131,
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            floating: true,
            pinned: false,
            toolbarHeight: 131, // 👈 your desired height
            titleSpacing: 0.0,
            flexibleSpace: _searchBar(context),
          ),
        ];
      },
      body: RefreshIndicator(
        onRefresh: () => controller.refreshFromBackend(clearLocalTables: false),
        displacement: 40.0,
        child: Column(
          children: [
            // if (controller.showOnlyEventsWithMessages.value)
            //   Container(
            //     padding: EdgeInsets.only(top: 5, bottom: 5),
            //     child: ElevatedButton(
            //       onPressed: () {
            //         controller.resetNotificationCounters();
            //       },
            //       child: Text(
            //         'Clear all notifications',
            //         style: ts_button,
            //       ),
            //     ),
            //   ),
            Expanded(
              child: Stack(
                children: [
                  noRunsAvaiable
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 25,
                                right: 25,
                                bottom: 30,
                              ),
                              child: Center(
                                child: Text(
                                  noRunsTitle,
                                  style: ts_headingVeryLarge,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 25.0,
                                right: 25.0,
                                bottom: 30,
                              ),
                              child: Center(
                                child: Text(
                                  noRunsDescription,
                                  style: ts_title,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            // Padding(
                            //   padding: const EdgeInsets.only(top: 0.0),
                            //   child: TextButton(
                            //     style: text_button_style,
                            //     child: Text('Reload runs', style: ts_button),
                            //     onPressed: () async {
                            //       await controller.refreshFromBackend(
                            //         clearLocalTables: true,
                            //       );
                            //     },
                            //   ),
                            // ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                            left: 10,
                            right: 10,
                            //top: 50,
                            bottom: 50,
                          ),
                          physics: const AlwaysScrollableScrollPhysics(),
                          //padding: const EdgeInsets.only( bottom: 40.0),
                          itemCount: listController.filteredRuns.length,
                          //itemCount: 5,
                          itemBuilder: (BuildContext context, int index) {
                            if (listController.filteredRuns[index] is int) {
                              return Column(
                                children: <Widget>[
                                  Container(
                                    margin: const EdgeInsets.only(top: 10),
                                    padding: const EdgeInsets.only(top: 2.0),
                                    color: themeButtonColors,
                                    height: 40.0,
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        if ((listController
                                                    .filteredRuns[index] ==
                                                2) &&
                                            (Utilities.isConnected())) ...<
                                          Widget
                                        >[const SizedBox(width: 36.0)],
                                        if ((listController
                                                    .filteredRuns[index] ==
                                                1) &&
                                            listController
                                                .showRsvpInstructions) ...<
                                          Widget
                                        >[const SizedBox(width: 36.0)],
                                        Text(
                                          listController.filteredRuns[index] ==
                                                  1
                                              ? listController
                                                        .showRsvpInstructions
                                                    ? 'Learn about RSVPs →'
                                                    : 'My upcoming runs'
                                              : listController
                                                        .filteredRuns[index] ==
                                                    2
                                              ? _getDistancePreferenceString(
                                                  'Runs within ',
                                                )
                                              : listController
                                                        .filteredRuns[index] ==
                                                    3
                                              ? 'Runs from Kennels I follow'
                                              : 'All other upcoming runs',
                                          textAlign: TextAlign.center,
                                          //textScaleFactor: deviceInfo.textClamp15,
                                          style: ts_titleLarge,
                                        ),
                                        if ((listController
                                                    .filteredRuns[index] ==
                                                1) &&
                                            listController
                                                .showRsvpInstructions) ...<
                                          Widget
                                        >[
                                          GestureDetector(
                                            onTap: () async {
                                              await Utilities.showAlert(
                                                'Why should I RSVP?',
                                                'Not only does it help the hares to plan for how much beer to buy, but it helps you keep track of which trails you plan to attend. It also lets your friends know if you\'ll be there.\r\n\r\nTo RSVP, click on the three dots next to the run and click on "I\'ll be there!" on the pop-up.',
                                                'OK',
                                              );
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8.0,
                                              ),
                                              child: Icon(
                                                FontAwesome.graduation_cap,
                                                size: 28.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                        if ((listController
                                                    .filteredRuns[index] ==
                                                2) &&
                                            (Utilities.isConnected())) ...<
                                          Widget
                                        >[
                                          GestureDetector(
                                            onTap: () async {
                                              bool success = false;

                                              if (!await Permission
                                                  .location
                                                  .isGranted) {
                                                final bool?
                                                allow = await Utilities.showAlert(
                                                  'Location Services Required',
                                                  'To show all runs near your current location you must allow Harrier Central to have access to location information from your phone.\r\n\r\nWould you like to enable location services?',
                                                  'Yes',
                                                  showCancelButton: true,
                                                  cancelButtonText: 'No',
                                                );

                                                if (allow ?? false) {
                                                  final PermissionStatus ps =
                                                      await Permission.location
                                                          .request();

                                                  if (ps.isPermanentlyDenied) {
                                                    final bool? openSettings =
                                                        await Utilities.showAlert(
                                                          'Phone Settings',
                                                          'You must change the location permissions in the phone\'s settings panel for Harrier Central.\r\n\r\nOnce you have done this, please close Settings and come back to Harrier Central.',
                                                          'Open Settings',
                                                          showCancelButton:
                                                              true,
                                                          cancelButtonText:
                                                              'Cancel',
                                                        );
                                                    if (openSettings ?? false) {
                                                      await openAppSettings();

                                                      success =
                                                          await Utilities.showAlert(
                                                            'Success?',
                                                            'Were you able to change the settings to enable location services?',
                                                            'Yes',
                                                            showCancelButton:
                                                                true,
                                                            cancelButtonText:
                                                                'No',
                                                          ) ??
                                                          false;
                                                    }
                                                  }

                                                  if ((ps.isGranted) ||
                                                      success) {
                                                    if (await Permission
                                                        .location
                                                        .serviceStatus
                                                        .isEnabled) {
                                                      appModel.hasLocationPermissions =
                                                          true;

                                                      final locService =
                                                          Get.put(
                                                            LocationService(),
                                                          );
                                                      if (locService
                                                          .initialized) {
                                                        await Utilities.showAlert(
                                                          'Location Services Enabled',
                                                          'Location Services have been enabled.',
                                                          'OK',
                                                        );
                                                        if (context.mounted) {
                                                          _showConfigureDistancePopup(
                                                            context,
                                                          );
                                                        }
                                                      }

                                                      // await Utilities.subscribeToGeoLocationStream().then((
                                                      //   void _,
                                                      // ) async {
                                                      //   await Utilities.showAlert(
                                                      //     'Location Services Enabled',
                                                      //     'Location Services have been enabled.',
                                                      //     'OK',
                                                      //   );
                                                      //   if (context.mounted) {
                                                      //     _showConfigureDistancePopup(
                                                      //       context,
                                                      //     );
                                                      //   }
                                                      // });
                                                    }
                                                  }
                                                }
                                              } else {
                                                if (context.mounted) {
                                                  _showConfigureDistancePopup(
                                                    context,
                                                  );
                                                }
                                              }
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8.0,
                                              ),
                                              child: Icon(
                                                FontAwesome.gear,
                                                size: 28.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // add some text if no runs are found within the distance filter
                                  if ((listController.filteredRuns[index] ==
                                          2) &&
                                      (listController.filteredRuns[index + 1] ==
                                          3)) ...<Widget>[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 22.0,
                                        bottom: 10.0,
                                      ),
                                      child: Text(
                                        '${_getDistancePreferenceString('[No runs found within ')}]',
                                        style: ts_headingLarge,
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            } else {
                              return RunListItem(
                                futureRun: listController.filteredRuns[index],

                                onItemTapped: () {
                                  listController.openRun(
                                    listController.filteredRuns[index],
                                    openToTab: RunTab.details,
                                  );
                                },
                              );
                            }
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _futurePastButton() {
    return Obx(() {
      return !controller.runsToDisplay.value.showFuturePastToggle
          ? SizedBox(height: 48)
          : controller.showRunsTimeScopeSpinner.value
          ? SizedBox(
              height: 49,
              width: 70,
              child: Center(
                child: HcAppCircularProgressIndicator(
                  key: UniqueKey(),
                  color1: Colors.white,
                  color2: Colors.blue.shade300,
                  size: 35,
                ),
              ),
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.only(top: 0.0, bottom: 0.0),
              ),
              onPressed: () async {
                controller.runsTimeScope.value =
                    RunsTimeScope.values[(controller.runsTimeScope.value.next)];
                controller.runsTimeScopeLoading.value = true;
                await controller.refreshFromTable(true);
                controller.runsTimeScopeLoading.value = false;
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 0, right: 0, top: 0),
                child: controller.runsTimeScope.value == RunsTimeScope.range
                    ? Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: Transform.scale(
                          scaleX: -1,
                          child: Icon(
                            Entypo.back_in_time,
                            color: Colors.white,
                            size: 30.0,
                          ),
                        ),
                      )
                    : controller.runsTimeScope.value == RunsTimeScope.future
                    ? Icon(Entypo.back_in_time, color: Colors.white, size: 30.0)
                    : Icon(
                        Ionicons.calendar_outline,
                        color: Colors.white,
                        size: 28.0,
                      ),
              ),
            );
    });
  }

  Widget _showResetChatCountsButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.only(top: 0.0, bottom: 0.0),
      ),
      onPressed: () async {
        if (Get.isRegistered<NotificationService>()) {
          final notificationController = Get.find<NotificationService>();
          notificationController.resetAllEventChatCounts();
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 0),
        child: Icon(
          Ionicons.checkmark_done_sharp,
          color: Colors.white,
          size: 30.0,
        ),
      ),
    );
  }

  Widget _showMapButton() {
    return Obx(() {
      return !controller.runsToDisplay.value.showFuturePastToggle
          ? SizedBox(height: 0)
          : controller.showRunsTimeScopeSpinner.value
          ? SizedBox(
              height: 49,
              width: 70,
              child: Center(
                child: HcAppCircularProgressIndicator(
                  key: UniqueKey(),
                  color1: Colors.white,
                  color2: Colors.blue.shade300,
                  size: 35,
                ),
              ),
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.only(top: 0.0, bottom: 0.0),
                // minimumSize: const Size(0, 0), // remove min size constraints
                // tapTargetSize:
                //     MaterialTapTargetSize.shrinkWrap, // tighter hitbox
              ),
              onPressed: () async {
                controller.openMap();
              },
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                ),
                child: Icon(
                  MaterialCommunityIcons.map_search,
                  color: Colors.white,
                  size: 30.0,
                ),
              ),
            );
    });
  }

  Widget _showCalendarButton(BuildContext context) {
    return Obx(() {
      return !controller.runsToDisplay.value.showFuturePastToggle
          ? SizedBox(height: 0)
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.only(top: 0.0, bottom: 0.0),
                // minimumSize: const Size(0, 0), // remove min size constraints
                // tapTargetSize:
                //     MaterialTapTargetSize.shrinkWrap, // tighter hitbox
              ),
              onPressed: () async {
                // var results = await calendar.showCalendarDatePicker2Dialog(
                //   context: context,
                //   config: calendar.CalendarDatePicker2WithActionButtonsConfig(
                //     firstDayOfWeek: 1,
                //     calendarType: calendar.CalendarDatePicker2Type.range,
                //     selectedDayTextStyle: TextStyle(
                //       color: Colors.white,
                //       fontWeight: FontWeight.w700,
                //     ),
                //     selectedDayHighlightColor: Colors.purple[800],
                //     centerAlignModePicker: true,
                //     customModePickerIcon: SizedBox(),
                //     calendarViewMode: calendar.CalendarDatePicker2Mode.scroll,
                //   ),
                //   dialogSize: Size(Get.width - 30, Get.height - 200),
                //   value: [
                //     controller.dateFilterStart.value,
                //     controller.dateFilterEnd.value,
                //   ],
                //   borderRadius: BorderRadius.circular(15),
                // );

                var results = await _showCalendarDialog(context);

                if (results.length == 1) {
                  controller.dateFilterStart.value = results[0];
                  controller.dateFilterEnd.value = results[0];
                  controller.filterRuns(false);
                } else if (results.length == 2) {
                  controller.dateFilterStart.value = results[0];
                  controller.dateFilterEnd.value = results[1];
                  controller.filterRuns(false);
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                ),
                child: Icon(
                  MaterialCommunityIcons.calendar_search,
                  color: Colors.white,
                  size: 30.0,
                ),
              ),
            );
    });
  }

  Widget _runsToDisplayButton() {
    return Center(
      child: PillArrowButtons(
        onLeftPressed: () async {
          controller.runsToDisplay.value =
              RunsToDisplay.values[(controller.runsToDisplay.value.previous)];
          controller.runsToDisplay.value.defaultViewIsFuture
              ? controller.runsTimeScope.value = RunsTimeScope.future
              : controller.runsTimeScope.value = RunsTimeScope.past;
          controller.runsToDisplayLoading.value = true;
          await controller.refreshFromTable(true);
          controller.runsToDisplayLoading.value = false;
        },
        onRightPressed: () async {
          controller.runsToDisplay.value =
              RunsToDisplay.values[(controller.runsToDisplay.value.next)];
          controller.runsToDisplay.value.defaultViewIsFuture
              ? controller.runsTimeScope.value = RunsTimeScope.future
              : controller.runsTimeScope.value = RunsTimeScope.past;
          controller.runsToDisplayLoading.value = true;
          await controller.refreshFromTable(true);
          controller.runsToDisplayLoading.value = false;
        },
      ),
    );
  }

  // Widget _runsToDisplayButton() {
  //   return Obx(
  //     () => Padding(
  //       padding: const EdgeInsets.symmetric(horizontal: 13.0),
  //       child: controller.showRunToDisplaySpinner.value
  //           ? SizedBox(
  //               height: 49,
  //               width: 100,
  //               child: Center(
  //                 child: HcAppCircularProgressIndicator(
  //                   key: UniqueKey(),
  //                   color1: Colors.white,
  //                   color2: Colors.blue.shade300,
  //                   size: 35,
  //                 ),
  //               ),
  //             )
  //           : ElevatedButton(
  //               style: ElevatedButton.styleFrom(
  //                 padding: const EdgeInsets.only(top: 0.0, bottom: 0.0),
  //               ),
  //               onPressed: () async {
  //                 controller.runsToDisplay.value = RunsToDisplay
  //                     .values[(controller.runsToDisplay.value.next)];
  //                 controller.runsToDisplay.value.defaultViewIsFuture
  //                     ? controller.runsTimeScope.value = RunsTimeScope.future
  //                     : controller.runsTimeScope.value = RunsTimeScope.past;
  //                 controller.runsToDisplayLoading.value = true;
  //                 await controller.refreshFromTable(true);
  //                 controller.runsToDisplayLoading.value = false;
  //               },
  //               child: Padding(
  //                 padding: const EdgeInsets.only(left: 10, right: 10, top: 0),
  //                 child: Text(
  //                   controller.runsToDisplay.value.label,
  //                   textAlign: TextAlign.center,
  //                   style: ts_button,
  //                 ),
  //               ),
  //             ),
  //     ),
  //   );
  // }

  void _showConfigureDistancePopup(BuildContext context) {
    if (Utilities.isConnected(showDialog: true)) {
      final String units =
          (getIntPref(IntPrefsEnum.hasherPreferences) ?? 2) &
                  hasherPref_distanceMeasuredIn ==
              2
          ? ' km'
          : ' miles';

      final String switchUnits =
          (getIntPref(IntPrefsEnum.hasherPreferences) ?? 2) &
                  hasherPref_distanceMeasuredIn ==
              2
          ? ' miles'
          : ' kilometers';

      final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
        <String, dynamic>{
          'title': '10$units',
          'icon': <Widget>[
            Container(
              height: 30,
              width: 45,
              decoration: const BoxDecoration(
                color: Colors.yellow,
                shape: BoxShape.rectangle,
              ),
            ),
            Text('10', style: ts_footnoteBlack),
          ],
          'returnValue': hasherPref_10,
        },
        <String, dynamic>{
          'title': '25$units',
          'icon': <Widget>[
            Container(
              height: 30,
              width: 45,
              decoration: const BoxDecoration(
                color: Colors.yellow,
                shape: BoxShape.rectangle,
              ),
            ),
            Text('25', style: ts_footnoteBlack),
          ],
          'returnValue': hasherPref_25,
        },
        <String, dynamic>{
          'title': '50$units',
          'icon': <Widget>[
            Container(
              height: 30,
              width: 45,
              decoration: const BoxDecoration(
                color: Colors.yellow,
                shape: BoxShape.rectangle,
              ),
            ),
            Text('50', style: ts_footnoteBlack),
          ],
          'returnValue': hasherPref_50,
        },
        <String, dynamic>{
          'title': '75$units',
          'icon': <Widget>[
            Container(
              height: 30,
              width: 45,
              decoration: const BoxDecoration(
                color: Colors.yellow,
                shape: BoxShape.rectangle,
              ),
            ),
            Text('75', style: ts_footnoteBlack),
          ],
          'returnValue': hasherPref_75,
        },
        <String, dynamic>{
          'title': '100$units',
          'icon': <Widget>[
            Container(
              height: 30,
              width: 45,
              decoration: const BoxDecoration(
                color: Colors.yellow,
                shape: BoxShape.rectangle,
              ),
            ),
            Text('100', style: ts_footnoteBlack),
          ],
          'returnValue': hasherPref_100,
        },
        <String, dynamic>{
          'title': '150$units',
          'icon': <Widget>[
            Container(
              height: 30,
              width: 45,
              decoration: const BoxDecoration(
                color: Colors.yellow,
                shape: BoxShape.rectangle,
              ),
            ),
            Text('150', style: ts_footnoteBlack),
          ],
          'returnValue': hasherPref_150,
        },
        <String, dynamic>{
          'title': '250$units',
          'icon': <Widget>[
            Container(
              height: 30,
              width: 45,
              decoration: const BoxDecoration(
                color: Colors.yellow,
                shape: BoxShape.rectangle,
              ),
            ),
            Text('250', style: ts_footnoteBlack),
          ],
          'returnValue': hasherPref_250,
        },
        // <String, dynamic>{
        //   'title': '500' + units,
        //   'icon': <Widget>[
        //     Container(
        //       height: 30,
        //       width: 45,
        //       decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.rectangle),
        //     ),
        //     Text('500', style: ts_footnoteBlack)
        //   ],
        //   'returnValue': hasherPref_500
        // },
        // pop in a divider
        <String, dynamic>{
          'height': 0.0,
          'thickness': 2.0,
          'paddingTop': 2.0,
          //'paddingBottom': 2.0,
          'returnValue': null,
        },
        <String, dynamic>{
          'title': 'Disable auto display',
          'icon': <Widget>[
            Container(
              height: 30,
              width: 45,
              decoration: BoxDecoration(
                color: hc_red,
                shape: BoxShape.rectangle,
              ),
            ),
            Text('Off', style: ts_footnoteBlack.copyWith(color: Colors.white)),
          ],
          'returnValue': hasherPref_0,
        },
        <String, dynamic>{
          'title': 'Switch to $switchUnits',
          'icon': <Widget>[
            Container(
              height: 30,
              width: 45,
              decoration: BoxDecoration(
                color: Colors.green.shade800,
                shape: BoxShape.rectangle,
              ),
            ),
            const Icon(
              MaterialCommunityIcons.map_marker_distance,
              color: Colors.white,
            ),
          ],
          'returnValue': 9999,
        },
      ];

      final MultipleChoicePopupHc popup = MultipleChoicePopupHc(
        key: const Key('5030202'),
        title: 'Display all runs within...',
        buttons: buttons,
        cancelButtonTitle: 'Cancel',
        cancelButtonReturnValue: followTypeCancel,
      );

      showDialog<dynamic>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return popup;
        },
      ).then((dynamic retVal) async {
        if (retVal == 9999) {
          if (Utilities.isConnected()) {
            final HashersService srv = HashersService();

            final int hasherPreferences =
                getIntPref(IntPrefsEnum.hasherPreferences) ?? 3;
            final int distanceMeasuredIn =
                ((hasherPreferences & hasherPref_distanceMeasuredIn) == 3)
                ? 2
                : 3;

            final int distance =
                hasherPreferences & hasherPref_distanceForAutoDisplay;

            await srv.addEditUser(
              targetUserId: getStringPref(StringPrefsEnum.userId)!,
              preferences: distanceMeasuredIn + distance,
            );

            await setIntPref(
              IntPrefsEnum.hasherPreferences,
              distanceMeasuredIn + distance,
            );
            await controller.refreshFromTable(true);
          }
        } else if ((retVal is! EnumFollowType) &&
            (retVal >= hasherPref_0) &&
            (retVal <= hasherPref_500)) {
          if (Utilities.isConnected()) {
            final HashersService srv = HashersService();

            final int hasherPreferences =
                getIntPref(IntPrefsEnum.hasherPreferences) ?? 3;
            final int distanceMeasuredIn =
                hasherPreferences & hasherPref_distanceMeasuredIn;
            //int _autoRunPreference = hasherPreferences & hasherPref_distanceForAutoDisplay;

            await srv.addEditUser(
              targetUserId: getStringPref(StringPrefsEnum.userId)!,
              preferences: distanceMeasuredIn + (retVal as int),
            );

            await setIntPref(
              IntPrefsEnum.hasherPreferences,
              distanceMeasuredIn + retVal,
            );

            await controller.refreshFromTable(true);
          }
        }
      });
    }
  }

  String _getDistancePreferenceString(String precursorText) {
    int distancePref =
        (getIntPref(IntPrefsEnum.hasherPreferences) ?? 3) &
        hasherPref_distanceForAutoDisplay;

    final String units =
        (getIntPref(IntPrefsEnum.hasherPreferences) ?? 3) &
                hasherPref_distanceMeasuredIn ==
            2
        ? ' km'
        : ' miles';

    if (!appModel.hasLocationPermissions) {
      distancePref = hasherPref_0;
    }

    switch (distancePref) {
      case hasherPref_0:
        precursorText = 'Distance filter →';
        break;
      case hasherPref_10:
        precursorText += '10$units';
        break;
      case hasherPref_25:
        precursorText += '25$units';
        break;
      case hasherPref_50:
        precursorText += '50$units';
        break;
      case hasherPref_75:
        precursorText += '75$units';
        break;
      case hasherPref_100:
        precursorText += '100$units';
        break;
      case hasherPref_150:
        precursorText += '150$units';
        break;
      case hasherPref_250:
        precursorText += '250$units';
        break;
      case hasherPref_500:
        precursorText += '500$units';
        break;
      default:
        precursorText = 'Distance not configured';
        break;
    }

    return precursorText;
  }

  Future<List<DateTime>> _showCalendarDialog(BuildContext context) async {
    List<DateTime> result = [
      controller.dateFilterStart.value,
      controller.dateFilterEnd.value,
    ];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: const EdgeInsets.all(16),
          content: SizedBox(
            width: Get.width - 30,
            height: Get.height - 200,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: calendar.CalendarDatePicker2(
                    config: calendar.CalendarDatePicker2WithActionButtonsConfig(
                      firstDayOfWeek: 1,
                      calendarType: calendar.CalendarDatePicker2Type.range,
                      selectedDayTextStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      selectedDayHighlightColor: Colors.purple[800],
                      centerAlignModePicker: true,
                      customModePickerIcon: SizedBox(),
                      calendarViewMode: calendar.CalendarDatePicker2Mode.scroll,
                    ),
                    value: [
                      controller.dateFilterStart.value,
                      controller.dateFilterEnd.value,
                    ],
                    onValueChanged: (dates) => result = dates,
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => CheckboxListTile(
                    dense: true,
                    controlAffinity: ListTileControlAffinity
                        .trailing, // 👈 moves checkbox to right
                    contentPadding: EdgeInsets.zero,
                    title: Align(
                      alignment: AlignmentGeometry.centerRight,
                      child: const Text('Use these dates every year'),
                    ),
                    value: controller.multiYearDateFilter.value,
                    onChanged: (val) {
                      controller.multiYearDateFilter.value = (val ?? false);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: SizedBox.shrink()),
                    TextButton(
                      onPressed: () {
                        result = [];
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                    SizedBox(width: 20),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return result;
  }
}

class EventChatSummary {
  final String publicEventId;
  final int badgeCount;

  EventChatSummary({required this.publicEventId, required this.badgeCount});

  factory EventChatSummary.fromJson(Map<String, dynamic> json) {
    return EventChatSummary(
      publicEventId: json['PublicEventId'] as String,
      badgeCount: json['BadgeCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'PublicEventId': publicEventId, 'BadgeCount': badgeCount};
  }
}
