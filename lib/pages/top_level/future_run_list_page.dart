import 'package:harrier_central/imports.dart';

final GlobalKey<FutureRunListPageState> futureRunsListPageKey = GlobalKey<FutureRunListPageState>();

class FutureRunsListPage extends StatefulWidget {
  FutureRunsListPage() : super(key: futureRunsListPageKey);

  @override
  State<FutureRunsListPage> createState() => FutureRunListPageState();
}

class FutureRunListPageState extends State<FutureRunsListPage> {
  int pageIndex = 1;
  List<dynamic>? _allRuns;
  List<dynamic>? _filteredRuns;

  bool _showRsvpInstructions = false;

  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  String _searchRunsText = '';
  final ScrollController _scrollController = ScrollController(initialScrollOffset: 100.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _allRuns == null ? const HcCircularProgressIndicator(key: Key('16669020')) : _buildListView(),
    );
  }

  Future<void> forceRefreshFromTableExternal() async {
    await refreshFromTable(true);
  }

  Future<void> _refreshFromBackend({bool clearLocalTables = false}) async {
    if (clearLocalTables) {
      setState(() {
        _allRuns = null;
      });

      String query = 'DELETE FROM ${G0<TableModel>().hasherEventMapTableHelper.getTableName(AppDomainType.user)}';
      try {
        await G0<Database>().rawQuery(query);
      } catch (e) {
        //print(e);
      }

      query = 'DELETE FROM ${G0<TableModel>().paymentsTableHelper.getTableName(AppDomainType.user)}';
      try {
        await G0<Database>().rawQuery(query);
      } catch (e) {
        //print(e);
      }

      query = 'DELETE FROM ${G0<TableModel>().eventsTableHelper.getTableName(AppDomainType.user)}';
      try {
        await G0<Database>().rawQuery(query);
      } catch (e) {
        //print(e);
      }
    }

    await G0<TableModel>().syncUserDataService.updateFromBackend(
          SyncUserDataService.flagHasherEventMapTable | SyncUserDataService.flagNarrowEventsTable | SyncUserDataService.flagKennelsTable,
          false,
          debugText: 'future_run_list_page: HEM, Events, Kennels',
        );

    await refreshFromTable(true);
    //final String resultStr = result ? 'successfully' : 'unsuccessfully';
    //print('Events user data synchronized $resultStr');
  }

  @override
  void initState() {
    // const SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(
    //   statusBarColor: Colors.red,
    //   statusBarIconBrightness: Brightness.dark,
    //   statusBarBrightness: Brightness.dark,
    // );
    // SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);

    IveCoreUtilities.logTiming('initState called', G0<AppModel>().appStartTime);
    _searchController.text = '';
    _searchRunsText = '';

    Permission.location.isGranted.then((bool isGranted) {
      setState(() {
        G0<AppModel>().hasLocationPermissions = isGranted;
      });
    });

    _refreshFromBackend().then((void _) {
      refreshFromTable(true).then((void _) {
        setState(() {});
      });
    });
    super.initState();
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
          //       value: _searchAllRuns,
          //       onChanged: (bool value) {
          //         _searchAllRuns = !_searchAllRuns;
          //         refreshFromTable(true).then((void _) {
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
                        setState(() {
                          _searchRunsText = text;
                          _filterRuns();
                        });
                      },
                      focusNode: _searchFocusNode,
                      controller: _searchController,
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
                      style: TextButton.styleFrom(textStyle: TextStyle(color: Colors.grey.shade700), backgroundColor: Colors.white),
                      child: Text('X', style: ts_headingBlack.copyWith(color: Colors.grey.shade700)),
                      onPressed: () {
                        _searchController.text = '';
                        _searchRunsText = '';
                        setState(() {
                          _filterRuns();
                        });
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

  Future<void> refreshFromTable(bool forceRefresh) async {
    if (forceRefresh || (_allRuns == null) || (_allRuns!.isEmpty)) {
      _allRuns = await QueryRuns.getRunDetailsAggregates(true);
      _filterRuns();

      setState(() {});
    }
    return;
  }

  /// filterRuns() provides a complex filtering (search) option
  /// where the plus sign (+) is used as a logical OR allowing
  /// query results to be added together and commas (,) to be used
  /// to separate query options and act as a logical AND function, thus
  /// limiting the query results. Finally the text 'not ' at the beginning
  /// of a search term will negate the resdults.
  ///
  /// For example: "AH3 + FILTH, not Wednesday + Thursday" will show all
  /// Amsterdam and FILTH hashes that are not on a Wednesday or Thursday
  ///
  void _filterRuns() {
    _showRsvpInstructions = true;
    _filteredRuns = QueryRuns.doRunsFilter(_searchRunsText, _allRuns ?? <dynamic>[]);

    _filteredRuns!.sort((dynamic a, dynamic b) {
      // start by sorting by run classification, closest runs should be listed first, then runs
      // from Kennels the user is following, then the rest
      int result = a.extensions.runClassification.compareTo(b.extensions.runClassification);

      if (result == 0) {
        result = _toDateOnly(a.event.eventStartDatetime).compareTo(_toDateOnly(b.event.eventStartDatetime));
        // if the runs are on the same day then try to sort by distance
        // if there are no distances because location services are off, then sort by Kennel name
        if (result == 0) {
          if ((a.extensions.distToEvent != null) && (b.extensions.distToEvent != null)) {
            final num distA = a.extensions.latitude == null ? 99999999 : a.extensions.distToEvent;
            final num distB = b.extensions.latitude == null ? 99999999 : b.extensions.distToEvent;
            result = distA.compareTo(distB);
          } else {
            result = a.kennel.kennelName.compareTo(b.kennel.kennelName);
          }
        }
      }
      return result;
    });

    int lastInsertedClassification = 4;

    final int listLength = _filteredRuns!.length;

    for (int i = listLength - 1; i >= 0; i--) {
      if (_filteredRuns![i].extensions.runClassification == 1) {
        _showRsvpInstructions = false;
      }

      int currentClassification = 1;
      if (i > 0) {
        currentClassification = _filteredRuns![i - 1].extensions.runClassification ?? 1;
      }

      if (currentClassification != lastInsertedClassification) {
        for (int j = lastInsertedClassification - currentClassification - 1; j >= 0; j--) {
          _filteredRuns!.insert(i, currentClassification + j + 1);
        }

        lastInsertedClassification = currentClassification;
      }
    }

    _filteredRuns!.insert(0, 1);

    // if (_filteredRuns.isNotEmpty) {
    //   // make sure the "All runs within..." bar always shows

    //   _filteredRuns.insert(0, _filteredRuns[0].extensions.runClassification);

    //   if ((_filteredRuns[0] != 1) && (_filteredRuns[0] != 2)) {
    //     _filteredRuns.insert(0, 2);
    //   } else if ((_filteredRuns[0] == 1) && (_filteredRuns[0] != 2)) {

    //     _filteredRuns.insert(1, 2);
    //   }

    //   if (_filteredRuns[0] != 1) {
    //     _filteredRuns.insert(0, 1);
    //   }
    // }

    setState(() {});
  }

  DateTime _toDateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  Widget _buildListView() {
    return Container(
      decoration: Backgrounds.defaultHcBackground(),
      child: (_allRuns ?? <dynamic>[]).isEmpty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 25, right: 25, bottom: 30),
                  child: Center(
                      child: Text(
                    'No Runs available.',
                    style: ts_headingVeryLarge,
                    textAlign: TextAlign.center,
                  )),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 25.0, right: 25.0, bottom: 30),
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
                    child: Text('Reload runs', style: ts_button),
                    onPressed: () async {
                      await _refreshFromBackend(clearLocalTables: false);
                    },
                  ),
                ),
              ],
            )
          : NestedScrollView(
              controller: _scrollController,
              floatHeaderSlivers: true,
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
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
                onRefresh: () => _refreshFromBackend(clearLocalTables: false),
                displacement: 40.0,
                child: _filteredRuns == null
                    ? const SizedBox()
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 50),
                        physics: const AlwaysScrollableScrollPhysics(),
                        //padding: const EdgeInsets.only( bottom: 40.0),
                        itemCount: _filteredRuns?.length ?? 0,
                        itemBuilder: (BuildContext context, int index) {
                          if (_filteredRuns![index] is int) {
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
                                      if ((_filteredRuns![index] == 2) && (G0<AppModel>().connectionStatus == EnumConnectionStatus2.connected)) ...<Widget>[
                                        const SizedBox(width: 36.0),
                                      ],
                                      if ((_filteredRuns![index] == 1) && _showRsvpInstructions) ...<Widget>[
                                        const SizedBox(width: 36.0),
                                      ],
                                      Text(
                                        _filteredRuns![index] == 1
                                            ? _showRsvpInstructions
                                                ? 'Learn about RSVPs →'
                                                : 'My upcoming runs'
                                            : _filteredRuns![index] == 2
                                                ? _getDistancePreferenceString('Runs within ')
                                                : _filteredRuns![index] == 3
                                                    ? 'Runs from Kennels I follow'
                                                    : 'All other upcoming runs',
                                        textAlign: TextAlign.center,
                                        //textScaleFactor: G0<DeviceInfo>().textClamp15,
                                        style: ts_titleLarge,
                                      ),
                                      if ((_filteredRuns![index] == 1) && _showRsvpInstructions) ...<Widget>[
                                        GestureDetector(
                                          onTap: () async {
                                            await Utilities.showAlert(
                                              'Why should I RSVP?',
                                              'Not only does it help the hares to plan for how much beer to buy, but it helps you keep track of which trails you plan to attend. It also lets your friends know if you\'ll be there.\r\n\r\nTo RSVP, click on the three dots next to the run and click on "I\'ll be there!" on the pop-up.',
                                              'OK',
                                            );
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                                            child: Icon(FontAwesome.graduation_cap, size: 28.0),
                                          ),
                                        )
                                      ],
                                      if ((_filteredRuns![index] == 2) && (G0<AppModel>().connectionStatus == EnumConnectionStatus2.connected)) ...<Widget>[
                                        GestureDetector(
                                          onTap: () async {
                                            bool success = false;

                                            if (!await Permission.location.isGranted) {
                                              final bool? allow = await Utilities.showAlert(
                                                  'Location Services Required',
                                                  'To show all runs near your current location you must allow Harrier Central to have access to location information from your phone.\r\n\r\nWould you like to enable location services?',
                                                  'Yes',
                                                  showCancelButton: true,
                                                  cancelButtonText: 'No');

                                              if (allow ?? false) {
                                                final PermissionStatus ps = await Permission.location.request();

                                                if (ps.isPermanentlyDenied) {
                                                  final bool? openSettings = await Utilities.showAlert(
                                                      'Phone Settings',
                                                      'You must change the location permissions in the phone\'s settings panel for Harrier Central.\r\n\r\nOnce you have done this, please close Settings and come back to Harrier Central.',
                                                      'Open Settings',
                                                      showCancelButton: true,
                                                      cancelButtonText: 'Cancel');
                                                  if (openSettings ?? false) {
                                                    await openAppSettings();

                                                    success = await Utilities.showAlert('Success?', 'Were you able to change the settings to enable location services?', 'Yes',
                                                            showCancelButton: true, cancelButtonText: 'No') ??
                                                        false;
                                                  }
                                                }

                                                if ((ps.isGranted) || success) {
                                                  if (await Permission.location.serviceStatus.isEnabled) {
                                                    G0<AppModel>().hasLocationPermissions = true;
                                                    await Utilities.subscribeToGeoLocationStream().then((void _) async {
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
                                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                                            child: Icon(FontAwesome.gear, size: 28.0),
                                          ),
                                        )
                                      ]
                                    ],
                                  ),
                                ),
                                // add some text if no runs are found within the distance filter
                                if ((_filteredRuns![index] == 2) && (_filteredRuns![index + 1] == 3)) ...<Widget>[
                                  Padding(
                                    padding: const EdgeInsets.only(top: 22.0, bottom: 10.0),
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
                              futureRun: _filteredRuns![index],
                              onItemTapped: () {
                                Navigator.push<dynamic>(
                                  this.context,
                                  MaterialPageRoute<dynamic>(
                                    builder: (BuildContext context) => RunDetailsPage(
                                      futureRun: _filteredRuns![index],
                                      refreshPage: () async {
                                        // WARNING!!!!  We need to return the filtered run based
                                        // on it's ID and not the index

                                        //await _refreshFromBackend(clearLocalTables: false);
                                        await refreshFromTable(true);
                                        //filterRuns();
                                        return _filteredRuns![index];
                                      },
                                    ),
                                  ),
                                ).then((void _) {
                                  _refreshFromBackend(clearLocalTables: false).then((void _) {
                                    setState(() {});
                                  });
                                });
                              },
                            );
                          }
                        },
                      ),
              ),
            ),
    );
  }

  void _showConfigureDistancePopup() {
    final String units = (getIntPref(IntPrefsEnum.hasherPreferences) ?? 2) & hasherPref_distanceMeasuredIn == 2 ? ' km' : ' miles';

    final String switchUnits = (getIntPref(IntPrefsEnum.hasherPreferences) ?? 2) & hasherPref_distanceMeasuredIn == 2 ? ' miles' : ' kilometers';

    final List<Map<String, dynamic>> buttons = <Map<String, dynamic>>[
      <String, dynamic>{
        'title': '10$units',
        'icon': <Widget>[
          Container(
            height: 30,
            width: 45,
            decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.rectangle),
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
            decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.rectangle),
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
            decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.rectangle),
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
            decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.rectangle),
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
            decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.rectangle),
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
            decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.rectangle),
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
            decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.rectangle),
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
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.rectangle),
          ),
          Text('Off', style: ts_footnoteBlack.copyWith(color: Colors.white))
        ],
        'returnValue': hasherPref_0
      },
      <String, dynamic>{
        'title': 'Switch to $switchUnits',
        'icon': <Widget>[
          Container(height: 30, width: 45, decoration: BoxDecoration(color: Colors.green.shade800, shape: BoxShape.rectangle)),
          const Icon(MaterialCommunityIcons.map_marker_distance, color: Colors.white)
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

    showDialog<dynamic>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return popup;
        }).then((dynamic retVal) async {
      if (retVal == 9999) {
        if (G0<AppModel>().connectionStatus == EnumConnectionStatus2.connected) {
          final HashersService srv = HashersService();

          final int hasherPreferences = getIntPref(IntPrefsEnum.hasherPreferences) ?? 3;
          final int distanceMeasuredIn = ((hasherPreferences & hasherPref_distanceMeasuredIn) == 3) ? 2 : 3;

          final int distance = hasherPreferences & hasherPref_distanceForAutoDisplay;

          await srv.addEditUser(
            targetUserId: getStringPref(StringPrefsEnum.userId)!,
            preferences: distanceMeasuredIn + distance,
          );

          await setIntPref(IntPrefsEnum.hasherPreferences, distanceMeasuredIn + distance);
          await refreshFromTable(true);
        }
      } else if ((retVal is! EnumFollowType) && (retVal >= hasherPref_0) && (retVal <= hasherPref_500)) {
        if (G0<AppModel>().connectionStatus == EnumConnectionStatus2.connected) {
          final HashersService srv = HashersService();

          final int hasherPreferences = getIntPref(IntPrefsEnum.hasherPreferences) ?? 3;
          final int distanceMeasuredIn = hasherPreferences & hasherPref_distanceMeasuredIn;
          //int _autoRunPreference = hasherPreferences & hasherPref_distanceForAutoDisplay;

          await srv.addEditUser(
            targetUserId: getStringPref(StringPrefsEnum.userId)!,
            preferences: distanceMeasuredIn + (retVal as int),
          );

          await setIntPref(IntPrefsEnum.hasherPreferences, distanceMeasuredIn + retVal);

          await refreshFromTable(true);
        }
      }
    });
  }

  String _getDistancePreferenceString(String precursorText) {
    int distancePref = (getIntPref(IntPrefsEnum.hasherPreferences) ?? 3) & hasherPref_distanceForAutoDisplay;

    final String units = (getIntPref(IntPrefsEnum.hasherPreferences) ?? 3) & hasherPref_distanceMeasuredIn == 2 ? ' km' : ' miles';

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
