import 'package:harrier_central/imports.dart';
import 'package:get/get.dart';

class FutureRunsListPage extends StatelessWidget {
  FutureRunsListPage() : super(key: UniqueKey());

  // Initialize the controller with the provided arguments
  final FutureRunListPageController controller = Get.put(
    FutureRunListPageController(),
    // permanent: true,
  );

  final ScrollController _scrollController =
      ScrollController(initialScrollOffset: 100.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<FutureRunListPageController>(
          id: 'runList',
          builder: (listController) {
            return listController.allRuns == null
                ? HcCircularProgressIndicator(key: UniqueKey())
                : _buildListView(listController);
          }),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //       body: controller.allRuns == null
  //           ? HcCircularProgressIndicator(key: UniqueKey())
  //           : _buildListView(controller));
  // }

  Future<void> refreshFromTableExternal() async {
    await controller.refreshFromTable(true);
  }

  Widget _searchBar() {
    return Container(
      height: 50,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Row(
          //   children: <Widget>[
          //     Checkbox(
          //       value: _searchcontroller.allRuns,
          //       onChanged: (bool value) {
          //         _searchcontroller.allRuns = !_searchcontroller.allRuns;
          //         controller.refreshFromTable(true).then((void _) {
          //           setState(() {});
          //         });
          //       },
          //     ),
          //     Padding(
          //       padding: const EdgeInsets.only(top: 4.0),
          //       child: Text('Search all runs', style: headingStyleBlack.copyWith(fontSize: 18.0)),
          //     ),
          //   ],
          // ),
          const Divider(
            height: 2.0,
            thickness: 2.0,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 14.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      autocorrect: false,
                      onChanged: (String text) {
                        //setState(() {
                        controller.searchRunsText = text;
                        controller.filterRuns();
                        //});
                      },
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
                      child: Text('X',
                          style: ts_headingBlack.copyWith(
                              color: Colors.grey.shade700)),
                      onPressed: () {
                        controller.searchController.text = '';
                        controller.searchRunsText = '';
                        //setState(() {
                        controller.filterRuns();
                        //});
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(FutureRunListPageController listController) {
    return Container(
      decoration: Backgrounds.defaultHcBackground(),
      child: (controller.allRuns ?? <dynamic>[]).isEmpty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding:
                      const EdgeInsets.only(left: 25, right: 25, bottom: 30),
                  child: Center(
                      child: Text(
                    'No Runs available.',
                    style: ts_headingVeryLarge,
                    textAlign: TextAlign.center,
                  )),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 25.0, right: 25.0, bottom: 30),
                  child: Center(
                      child: Text(
                    'You might not be following any Kennels with upcoming runs. Check the Kennels page, select several Kennels and then return to this page and hit the "Reload runs" button below.',
                    style: ts_title,
                    textAlign: TextAlign.center,
                  )),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 0.0),
                  child: TextButton(
                    style: text_button_style,
                    child: Text('Reload runs', style: ts_button),
                    onPressed: () async {
                      await controller.refreshFromBackend(
                          clearLocalTables: false);
                    },
                  ),
                ),
              ],
            )
          : NestedScrollView(
              controller: _scrollController,
              floatHeaderSlivers: true,
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  // SliverList(
                  //   delegate: SliverChildListDelegate(<Widget>[_searchBar()]),
                  // ),
                  SliverAppBar(
                    floating: true,
                    titleSpacing: 0.0,
                    title: SizedBox(
                      height: 54.0,
                      child: _searchBar(),
                    ),
                  )
                ];
              },
              body: RefreshIndicator(
                onRefresh: () => controller.refreshFromBackend(
                  clearLocalTables: false,
                ),
                displacement: 40.0,
                child:

                    // GetBuilder<FutureRunListPageController>(
                    //     id: 'runList',
                    //     builder: (listController) {
                    //       return

                    ListView.builder(
                        padding: const EdgeInsets.only(
                            left: 10, right: 10, top: 0, bottom: 50),
                        physics: const AlwaysScrollableScrollPhysics(),
                        //padding: const EdgeInsets.only( bottom: 40.0),
                        itemCount: listController.filteredRuns.length,
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      if ((listController.filteredRuns[index] ==
                                              2) &&
                                          (G0<AppModel>().connectionStatus ==
                                              EnumConnectionStatus2
                                                  .connected)) ...<Widget>[
                                        const SizedBox(width: 36.0),
                                      ],
                                      if ((listController.filteredRuns[index] ==
                                              1) &&
                                          listController
                                              .showRsvpInstructions) ...<Widget>[
                                        const SizedBox(width: 36.0),
                                      ],
                                      Text(
                                        listController.filteredRuns[index] == 1
                                            ? listController
                                                    .showRsvpInstructions
                                                ? 'Learn about RSVPs →'
                                                : 'My upcoming runs'
                                            : listController
                                                        .filteredRuns[index] ==
                                                    2
                                                ? _getDistancePreferenceString(
                                                    'Runs within ')
                                                : listController.filteredRuns[
                                                            index] ==
                                                        3
                                                    ? 'Runs from Kennels I follow'
                                                    : 'All other upcoming runs',
                                        textAlign: TextAlign.center,
                                        //textScaleFactor: G0<DeviceInfo>().textClamp15,
                                        style: ts_titleLarge,
                                      ),
                                      if ((listController.filteredRuns[index] ==
                                              1) &&
                                          listController
                                              .showRsvpInstructions) ...<Widget>[
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
                                                horizontal: 8.0),
                                            child: Icon(
                                                FontAwesome.graduation_cap,
                                                size: 28.0),
                                          ),
                                        )
                                      ],
                                      if ((listController.filteredRuns[index] ==
                                              2) &&
                                          (G0<AppModel>().connectionStatus ==
                                              EnumConnectionStatus2
                                                  .connected)) ...<Widget>[
                                        GestureDetector(
                                          onTap: () async {
                                            bool success = false;

                                            if (!await Permission
                                                .location.isGranted) {
                                              final bool? allow =
                                                  await Utilities.showAlert(
                                                      'Location Services Required',
                                                      'To show all runs near your current location you must allow Harrier Central to have access to location information from your phone.\r\n\r\nWould you like to enable location services?',
                                                      'Yes',
                                                      showCancelButton: true,
                                                      cancelButtonText: 'No');

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
                                                              'Cancel');
                                                  if (openSettings ?? false) {
                                                    await openAppSettings();

                                                    success = await Utilities
                                                            .showAlert(
                                                                'Success?',
                                                                'Were you able to change the settings to enable location services?',
                                                                'Yes',
                                                                showCancelButton:
                                                                    true,
                                                                cancelButtonText:
                                                                    'No') ??
                                                        false;
                                                  }
                                                }

                                                if ((ps.isGranted) || success) {
                                                  if (await Permission
                                                      .location
                                                      .serviceStatus
                                                      .isEnabled) {
                                                    G0<AppModel>()
                                                            .hasLocationPermissions =
                                                        true;
                                                    await Utilities
                                                            .subscribeToGeoLocationStream()
                                                        .then((void _) async {
                                                      await Utilities.showAlert(
                                                        'Location Services Enabled',
                                                        'Location Services have been enabled.',
                                                        'OK',
                                                      );

                                                      _showConfigureDistancePopup();
                                                    });
                                                  }
                                                }
                                              }
                                            } else {
                                              _showConfigureDistancePopup();
                                            }
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                            child: Icon(FontAwesome.gear,
                                                size: 28.0),
                                          ),
                                        )
                                      ]
                                    ],
                                  ),
                                ),
                                // add some text if no runs are found within the distance filter
                                if ((listController.filteredRuns[index] == 2) &&
                                    (listController.filteredRuns[index + 1] ==
                                        3)) ...<Widget>[
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 22.0, bottom: 10.0),
                                    child: Text(
                                      '${_getDistancePreferenceString('[No runs found within ')}]',
                                      style: ts_headingLarge,
                                    ),
                                  ),
                                ],
                              ],
                            );
                          } else {
                            String publicEventId = (listController
                                    .filteredRuns[index] as RunDetailsAggregate)
                                .event
                                .publicEventId;
                            // print(
                            //     'chatSummaryMap = ${(chatSummaryMap[publicEventId]?.eventChatMessageCount ?? 0)} / thisEventChatCount = ${(thisEventChatCount[publicEventId] ?? 0)} ');

                            return RunListItem(
                              futureRun: listController.filteredRuns[index],
                              currentChatCount: (listController
                                      .thisEventUnseenChats[publicEventId]
                                      ?.value ??
                                  listController.chatSummaryMap[publicEventId]
                                      ?.eventChatMessageCount ??
                                  0),
                              onItemTapped: () {
                                listController.openRun(
                                  listController.filteredRuns[index],
                                  openToChatTab: false,
                                );
                              },
                            );
                          }
                        }),
              ),
            ),
    );
  }

  void _showConfigureDistancePopup() {
    final String units = (getIntPref(IntPrefsEnum.hasherPreferences) ?? 2) &
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
                color: Colors.yellow, shape: BoxShape.rectangle),
          ),
          Text('10', style: ts_footnoteBlack)
        ],
        'returnValue': hasherPref_10
      },
      <String, dynamic>{
        'title': '25$units',
        'icon': <Widget>[
          Container(
            height: 30,
            width: 45,
            decoration: const BoxDecoration(
                color: Colors.yellow, shape: BoxShape.rectangle),
          ),
          Text('25', style: ts_footnoteBlack)
        ],
        'returnValue': hasherPref_25
      },
      <String, dynamic>{
        'title': '50$units',
        'icon': <Widget>[
          Container(
            height: 30,
            width: 45,
            decoration: const BoxDecoration(
                color: Colors.yellow, shape: BoxShape.rectangle),
          ),
          Text('50', style: ts_footnoteBlack)
        ],
        'returnValue': hasherPref_50
      },
      <String, dynamic>{
        'title': '75$units',
        'icon': <Widget>[
          Container(
            height: 30,
            width: 45,
            decoration: const BoxDecoration(
                color: Colors.yellow, shape: BoxShape.rectangle),
          ),
          Text('75', style: ts_footnoteBlack)
        ],
        'returnValue': hasherPref_75
      },
      <String, dynamic>{
        'title': '100$units',
        'icon': <Widget>[
          Container(
            height: 30,
            width: 45,
            decoration: const BoxDecoration(
                color: Colors.yellow, shape: BoxShape.rectangle),
          ),
          Text('100', style: ts_footnoteBlack)
        ],
        'returnValue': hasherPref_100
      },
      <String, dynamic>{
        'title': '150$units',
        'icon': <Widget>[
          Container(
            height: 30,
            width: 45,
            decoration: const BoxDecoration(
                color: Colors.yellow, shape: BoxShape.rectangle),
          ),
          Text('150', style: ts_footnoteBlack)
        ],
        'returnValue': hasherPref_150
      },
      <String, dynamic>{
        'title': '250$units',
        'icon': <Widget>[
          Container(
            height: 30,
            width: 45,
            decoration: const BoxDecoration(
                color: Colors.yellow, shape: BoxShape.rectangle),
          ),
          Text('250', style: ts_footnoteBlack)
        ],
        'returnValue': hasherPref_250
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
            decoration: BoxDecoration(color: hc_red, shape: BoxShape.rectangle),
          ),
          Text('Off', style: ts_footnoteBlack.copyWith(color: Colors.white))
        ],
        'returnValue': hasherPref_0
      },
      <String, dynamic>{
        'title': 'Switch to $switchUnits',
        'icon': <Widget>[
          Container(
              height: 30,
              width: 45,
              decoration: BoxDecoration(
                  color: Colors.green.shade800, shape: BoxShape.rectangle)),
          const Icon(MaterialCommunityIcons.map_marker_distance,
              color: Colors.white)
        ],
        'returnValue': 9999
      },
    ];

    final MultipleChoicePopupHc popup = MultipleChoicePopupHc(
      key: const Key('5030202'),
      title: 'Display all runs within...',
      buttons: buttons,
      cancelButtonTitle: 'Cancel',
      cancelButtonReturnValue: followTypeCancel,
    );

    // showDialog<dynamic>(
    //     context: context,
    //     barrierDismissible: false, // user must tap button!
    //     builder: (BuildContext context) {
    //       return popup;
    //     }).then((dynamic retVal) async {
    //   if (retVal == 9999) {
    //     if (G0<AppModel>().connectionStatus ==
    //         EnumConnectionStatus2.connected) {
    //       final HashersService srv = HashersService();

    //       final int hasherPreferences =
    //           getIntPref(IntPrefsEnum.hasherPreferences) ?? 3;
    //       final int distanceMeasuredIn =
    //           ((hasherPreferences & hasherPref_distanceMeasuredIn) == 3)
    //               ? 2
    //               : 3;

    //       final int distance =
    //           hasherPreferences & hasherPref_distanceForAutoDisplay;

    //       await srv.addEditUser(
    //         targetUserId: getStringPref(StringPrefsEnum.userId)!,
    //         preferences: distanceMeasuredIn + distance,
    //       );

    //       await setIntPref(
    //           IntPrefsEnum.hasherPreferences, distanceMeasuredIn + distance);
    //       await controller.refreshFromTable(true);
    //     }
    //   } else if ((retVal is! EnumFollowType) &&
    //       (retVal >= hasherPref_0) &&
    //       (retVal <= hasherPref_500)) {
    //     if (G0<AppModel>().connectionStatus ==
    //         EnumConnectionStatus2.connected) {
    //       final HashersService srv = HashersService();

    //       final int hasherPreferences =
    //           getIntPref(IntPrefsEnum.hasherPreferences) ?? 3;
    //       final int distanceMeasuredIn =
    //           hasherPreferences & hasherPref_distanceMeasuredIn;
    //       //int _autoRunPreference = hasherPreferences & hasherPref_distanceForAutoDisplay;

    //       await srv.addEditUser(
    //         targetUserId: getStringPref(StringPrefsEnum.userId)!,
    //         preferences: distanceMeasuredIn + (retVal as int),
    //       );

    //       await setIntPref(
    //           IntPrefsEnum.hasherPreferences, distanceMeasuredIn + retVal);

    //       await controller.refreshFromTable(true);
    //     }
    //   }
    // });
  }

  String _getDistancePreferenceString(String precursorText) {
    int distancePref = (getIntPref(IntPrefsEnum.hasherPreferences) ?? 3) &
        hasherPref_distanceForAutoDisplay;

    final String units = (getIntPref(IntPrefsEnum.hasherPreferences) ?? 3) &
                hasherPref_distanceMeasuredIn ==
            2
        ? ' km'
        : ' miles';

    if (!G0<AppModel>().hasLocationPermissions) {
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
}

class EventChatSummary {
  final String id;
  final String publicEventId;
  final int eventChatMessageCount;

  EventChatSummary({
    required this.id,
    required this.publicEventId,
    required this.eventChatMessageCount,
  });

  factory EventChatSummary.fromJson(Map<String, dynamic> json) {
    return EventChatSummary(
      id: json['id'] as String,
      publicEventId: json['PublicEventId'] as String,
      eventChatMessageCount: json['EventChatMessageCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'PublicEventId': publicEventId,
      'EventChatMessageCount': eventChatMessageCount,
    };
  }
}
