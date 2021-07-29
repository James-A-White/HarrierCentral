import 'package:harrier_central/imports.dart';
import 'package:latlong/latlong.dart';
import 'package:date_time_picker/date_time_picker.dart';

class EditRunDetailsPage extends StatefulWidget {
  const EditRunDetailsPage(this.eventAggregate, this.getUpdatedEventAggregate, {Key key}) : super(key: key);

  final RunDetailAggregate eventAggregate;
  final Function getUpdatedEventAggregate;

  @override
  _EditRunDetailsPageState createState() => _EditRunDetailsPageState();
}

class _EditRunDetailsPageState extends State<EditRunDetailsPage> with SingleTickerProviderStateMixin {
  List<Tab> tabs = <Tab>[];

  TabController _tabController;

  final String userId = getStringPref(StringPrefsEnum.userId);

  GlobalKey tabKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        title: const Text(
          'Edit run details',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: <Widget>[
            // Positioned(
            //     top: 30,
            //     left: 0,
            //     right: 0,
            //     child: Text(
            //       'QR Code Scanner',
            //       textAlign: TextAlign.center,
            //       style: const TextStyle(
            //           fontFamily: 'AvenirNextRegular',
            //           fontStyle: FontStyle.normal,
            //           color: Colors.white,
            //           fontSize: 24.0,
            //           height: 1.0),
            //     )),
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                width: 340.0,
                height: 45.0,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColorLight,
                  borderRadius: const BorderRadius.all(Radius.circular(35.0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 1.0, right: 1.0),
                  child: TabBar(
                    physics: const NeverScrollableScrollPhysics(),
                    labelStyle: const TextStyle(fontFamily: 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
                    unselectedLabelStyle: const TextStyle(fontFamily: 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
                    isScrollable: false,
                    unselectedLabelColor: Colors.black,
                    labelColor: Colors.white,
                    labelPadding: const EdgeInsets.only(top: 5, left: 20, right: 20),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BubbleTabIndicator(
                      indicatorHeight: 35.0,
                      indicatorColor: Theme.of(context).buttonColor,
                      tabBarIndicatorSize: TabBarIndicatorSize.tab,
                      indicatorRadius: 20.0,
                    ),
                    tabs: tabs,
                    controller: _tabController,
                  ),
                ),
              ),
            ),
            Positioned(
                top: 80,
                bottom: 0,
                child: Container(
                  key: tabKey,
                  //color: Colors.teal,
                  width: MediaQuery.of(context).size.width,
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: _tabController,
                    children: <Widget>[DetailsTab(widget.eventAggregate, widget.getUpdatedEventAggregate), LocationTab(widget.eventAggregate, widget.getUpdatedEventAggregate)],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initTabs();

    _tabController = TabController(vsync: this, length: tabs.length);
  }

  // Color left = Colors.white;
  // Color right = Colors.white;

  void _initTabs() {
    if (tabs.isEmpty) {
      tabs.add(const Tab(text: 'Details'));
      tabs.add(const Tab(text: 'Map'));
      //tabs.add(const Tab(text: 'Date/Time'));
    }
  }

  // void _onSwitchToQrCode() {
  //   _pageController.animateToPage(0,
  //       duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
  // }

  // void _onSwitchToQrScanner() {
  //   _pageController?.animateToPage(1,
  //       duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
  // }
}

class DetailsTab extends StatefulWidget {
  const DetailsTab(this.eventAggregate, this.getUpdatedEventAggregate, {Key key}) : super(key: key);

  final RunDetailAggregate eventAggregate;
  final Function getUpdatedEventAggregate;

  @override
  _DetailsTabState createState() => _DetailsTabState();
}

class _DetailsTabState extends State<DetailsTab> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  Key tabKey;
  RunDetailAggregate _updatedEventAggregate;
  bool _isUpdating = false;

  final GlobalKey<FormState> _detailsFormKey = GlobalKey<FormState>();

  final FocusNode focusNodeAbsoluteEventNumber = FocusNode();
  final FocusNode focusNodeDatetime = FocusNode();
  final FocusNode focusNodeEventName = FocusNode();
  final FocusNode focusNodeEventDescription = FocusNode();
  final FocusNode focusNodeEventPriceForMembers = FocusNode();
  final FocusNode focusNodeEventPriceForNonMembers = FocusNode();
  final FocusNode focusNodeLocationOneLineDesc = FocusNode();

  TextEditingController eventDatetimeController = TextEditingController();
  TextEditingController eventNameController = TextEditingController();
  TextEditingController eventDescriptionController = TextEditingController();
  TextEditingController absoluteEventNumberController = TextEditingController();
  TextEditingController eventPriceForMembersController = TextEditingController();
  TextEditingController eventPriceForNonMembersController = TextEditingController();
  TextEditingController locationOneLineDescController = TextEditingController();

  @override
  void dispose() {
    eventDatetimeController.dispose();
    eventNameController.dispose();
    eventDescriptionController.dispose();
    absoluteEventNumberController.dispose();
    eventPriceForMembersController.dispose();
    eventPriceForNonMembersController.dispose();
    locationOneLineDescController.dispose();

    focusNodeAbsoluteEventNumber.dispose();
    focusNodeDatetime.dispose();
    focusNodeEventName.dispose();
    focusNodeEventDescription.dispose();
    focusNodeEventPriceForMembers.dispose();
    focusNodeEventPriceForNonMembers.dispose();
    focusNodeLocationOneLineDesc.dispose();

    super.dispose();
  }

  void setTextFields() {
    eventNameController.text = _updatedEventAggregate.event.eventName;
    eventDescriptionController.text = _updatedEventAggregate.event.eventDescription;
    absoluteEventNumberController.text = _updatedEventAggregate.event.absoluteEventNumber?.toString() ?? '<auto>';
    eventDatetimeController.text = _updatedEventAggregate.event.eventStartDatetime.toString();
    eventPriceForMembersController.text = _updatedEventAggregate.event.eventPriceForMembers?.toString() ?? '<auto>';
    eventPriceForNonMembersController.text = _updatedEventAggregate.event.eventPriceForNonMembers?.toString() ?? '<auto>';
    locationOneLineDescController.text = _updatedEventAggregate.event.locationOneLineDesc;
  }

  @override
  void initState() {
    _updatedEventAggregate = widget.eventAggregate;
    setTextFields();

    focusNodeEventName.addListener(() {
      setState(() {});
    });

    focusNodeEventDescription.addListener(() {
      setState(() {});
    });

    focusNodeAbsoluteEventNumber.addListener(() {
      setState(() {});
    });

    focusNodeDatetime.addListener(() {
      setState(() {});
    });

    focusNodeEventPriceForMembers.addListener(() {
      setState(() {});
    });

    focusNodeEventPriceForNonMembers.addListener(() {
      setState(() {});
    });

    focusNodeLocationOneLineDesc.addListener(() {
      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      //elevation: 2.0,
      decoration: Backgrounds.defaultHcBackgroundLight(),
      // shape: RoundedRectangleBorder(
      //   borderRadius: BorderRadius.circular(8.0),
      // ),
      child: SingleChildScrollView(
        child: Form(
          key: _detailsFormKey,
          child: Wrap(
            children: <Widget>[
              Column(
                //mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    color: focusNodeEventName.hasFocus ? Colors.yellow.shade50 : Colors.white,
                    margin: const EdgeInsets.only(top: 20.0, bottom: 10.0, left: 25.0, right: 25.0),
                    child: TextFormField(
                      focusNode: focusNodeEventName,
                      controller: eventNameController,
                      minLines: 1,
                      maxLines: 2,
                      onChanged: (String text) {
                        //widget.EventName = text;
                      },
                      keyboardType: TextInputType.multiline,
                      validator: (String val) {
                        if (val.isEmpty) {
                          return 'Please provide an event name';
                        } else {
                          return null;
                        }
                      },
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Event name',
                        fillColor: Colors.red,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(),
                        ),
                        hintText: 'Event Name',
                        hintStyle: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                      ),
                    ),
                  ),
                  Container(
                    color: focusNodeEventDescription.hasFocus ? Colors.yellow.shade50 : Colors.white,
                    margin: const EdgeInsets.only(top: 10.0, bottom: 10.0, left: 25.0, right: 25.0),
                    child: TextFormField(
                      onChanged: (String text) {
                        //widget.EventDescription = text;
                      },
                      maxLines: null,
                      focusNode: focusNodeEventDescription,
                      controller: eventDescriptionController,
                      validator: (String val) {
                        if (val.isEmpty) {
                          return 'Please provide an event description';
                        } else {
                          return null;
                        }
                      },
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Event Description',
                        fillColor: Colors.red,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(),
                        ),
                        hintText: 'Event Description',
                        hintStyle: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                      ),
                    ),
                  ),
                  Container(
                    color: focusNodeAbsoluteEventNumber.hasFocus ? Colors.yellow.shade50 : Colors.white,
                    margin: const EdgeInsets.only(top: 10.0, bottom: 10.0, left: 25.0, right: 25.0),
                    child: TextFormField(
                      onChanged: (String text) {
                        if ((text == null) || (text.isEmpty)) {
                          absoluteEventNumberController.text = '<auto>';
                        } else if ((text.length > 6) && (text.contains('<auto>'))) {
                          absoluteEventNumberController.text = absoluteEventNumberController.text.replaceAll('<auto>', '');
                          absoluteEventNumberController.selection = TextSelection.fromPosition(TextPosition(offset: absoluteEventNumberController.text.length));
                        }
                      },
                      maxLines: 1,
                      focusNode: focusNodeAbsoluteEventNumber,
                      controller: absoluteEventNumberController,
                      validator: (String val) {
                        if (val.isEmpty) {
                          return 'Please provide an event number or enter \'<auto>\'';
                        } else {
                          return null;
                        }
                      },
                      keyboardType: const TextInputType.numberWithOptions(),
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Event Number (or \'<auto>\')',
                        fillColor: Colors.red,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(),
                        ),
                        hintText: 'Event Number (or \'<auto>\')',
                        hintStyle: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                      ),
                    ),
                  ),
                  Container(
                    color: focusNodeLocationOneLineDesc.hasFocus ? Colors.yellow.shade50 : Colors.white,
                    margin: const EdgeInsets.only(top: 20.0, bottom: 10.0, left: 25.0, right: 25.0),
                    child: TextFormField(
                      focusNode: focusNodeLocationOneLineDesc,
                      controller: locationOneLineDescController,
                      minLines: 1,
                      maxLines: 2,
                      onChanged: (String text) {
                        //widget.EventName = text;
                      },
                      keyboardType: TextInputType.multiline,
                      validator: (String val) {
                        if (val.isEmpty) {
                          return 'Please provide a location description';
                        } else {
                          return null;
                        }
                      },
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Location one-line description',
                        fillColor: Colors.red,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(),
                        ),
                        hintText: 'Location description',
                        hintStyle: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                      ),
                    ),
                  ),
                  Container(
                    color: focusNodeDatetime.hasFocus ? Colors.yellow.shade50 : Colors.white,
                    margin: const EdgeInsets.only(top: 10.0, bottom: 10.0, left: 25.0, right: 25.0),
                    child: DateTimePicker(
                      decoration: InputDecoration(
                        labelText: 'Date / Time',
                        fillColor: Colors.red,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(),
                        ),
                        //hintText: 'Event Number (or \'<auto>\')',
                        hintStyle: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                      ),
                      focusNode: focusNodeDatetime,
                      controller: eventDatetimeController,
                      type: DateTimePickerType.dateTime,
                      use24HourFormat: false,
                      locale: const Locale('en', 'US'),
                      dateMask: 'E, d MMM, yyyy, h:mm a',
                      //initialValue: DateTime.now().toString(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      //icon: const Icon(Icons.event),
                      dateLabelText: 'Date',
                      timeLabelText: 'Hour',
                      // selectableDayPredicate: (DateTime date) {
                      //   // Disable weekend days to select from the calendar
                      //   if (date.weekday == 6 || date.weekday == 7) {
                      //     return false;
                      //   }

                      //   return true;
                      // },
                      // onChanged: (val) => print(val),
                      validator: (String val) {
                        //print(val);
                        return null;
                      },
                      //onSaved: (val) => print(val),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 20.0, bottom: 10.0, left: 25.0, right: 25.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: Container(
                            color: focusNodeEventPriceForMembers.hasFocus ? Colors.yellow.shade50 : Colors.white,
                            margin: const EdgeInsets.only(right: 12.5),
                            child: TextFormField(
                              onChanged: (String text) {
                                if ((text == null) || (text.isEmpty)) {
                                  eventPriceForMembersController.text = '<auto>';
                                }
                              },
                              maxLines: 1,
                              focusNode: focusNodeEventPriceForMembers,
                              controller: eventPriceForMembersController,
                              keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: true),
                              textCapitalization: TextCapitalization.sentences,
                              style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
                              decoration: InputDecoration(
                                labelText: 'H-cash (members)',
                                fillColor: Colors.red,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: const BorderSide(),
                                ),
                                hintText: 'H-cash (members)',
                                hintStyle: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            color: focusNodeEventPriceForNonMembers.hasFocus ? Colors.yellow.shade50 : Colors.white,
                            margin: const EdgeInsets.only(left: 12.5),
                            child: TextFormField(
                              onChanged: (String text) {
                                if ((text == null) || (text.isEmpty)) {
                                  eventPriceForNonMembersController.text = '<auto>';
                                }
                              },
                              maxLines: 1,
                              focusNode: focusNodeEventPriceForNonMembers,
                              controller: eventPriceForNonMembersController,
                              keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: true),
                              textCapitalization: TextCapitalization.sentences,
                              style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
                              decoration: InputDecoration(
                                labelText: 'H-cash (non-members)',
                                fillColor: Colors.red,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: const BorderSide(),
                                ),
                                hintText: 'H-cash (non-members)',
                                hintStyle: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 10.0, bottom: 60.0, left: 25.0, right: 25.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      //crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        _isUpdating
                            ? Container(
                                height: 70.0,
                                width: 70.0,
                                child: HcCircularProgressIndicator(key: UniqueKey()),
                              )
                            : Container(
                                width: 162.0,
                                child: ElevatedButton(
                                  child: Text('Save Details', style: buttonLabelStyleMedium),
                                  onPressed: () {
                                    setState(() {
                                      _updateDetails();
                                    });
                                  },
                                ),
                              ),
                        if ((widget.eventAggregate.event.eventFacebookId != null) && (!_isUpdating)) ...<Widget>[
                          const SizedBox(width: 10.0),
                          Container(
                            width: 162.0,
                            child: ElevatedButton(
                              child: Text('Use Facebook', style: buttonLabelStyleMedium),
                              onPressed: () {
                                setState(() {
                                  _isUpdating = true;
                                  _useFacebookDetails();
                                });
                              },
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _useFacebookDetails() {
    setState(() {
      _isUpdating = true;
      final EventsService nSvc = EventsService();
      nSvc
          .addEditEvent(
        eventId: widget.eventAggregate.event.eventId,
        useFbRunDetails: 1,
      )
          .then((void dummy) async {
        _updatedEventAggregate = await widget.getUpdatedEventAggregate();
        setState(() {
          _isUpdating = false;
          setTextFields();
        });
      });
    });
  }

  void _updateDetails() {
    if (_detailsFormKey.currentState.validate()) {
      //    If all data are correct then save data to out variables
      _detailsFormKey.currentState.save();

      setState(() {
        _isUpdating = true;
        final EventsService nSvc = EventsService();
        nSvc
            .addEditEvent(
          eventId: widget.eventAggregate.event.eventId,
          eventName: eventNameController.text,
          eventStartDatetime: DateTime.tryParse(eventDatetimeController.text),
          eventDescription: eventDescriptionController.text,
          eventPriceForMembers: eventPriceForMembersController.text == '<auto>' ? null : num.tryParse(eventPriceForMembersController.text),
          eventPriceForNonMembers: eventPriceForNonMembersController.text == '<auto>' ? null : num.tryParse(eventPriceForNonMembersController.text),
          absoluteEventNumber: absoluteEventNumberController.text == '<auto>' ? 0 : num.tryParse(absoluteEventNumberController.text),
          locationOneLineDesc: locationOneLineDescController.text,
          useFbRunDetails: 0,
        )
            .then((void dummy) async {
          _updatedEventAggregate = await widget.getUpdatedEventAggregate();
          setState(() {
            _isUpdating = false;
          });
        });
      });
    } else {
//    If all data are not valid then start auto validation.
      // setState(() {
      //   _autoValidate = true;
      // });
    }
  }
}

class LocationTab extends StatefulWidget {
  const LocationTab(this.eventAggregate, this.getUpdatedEventAggregate, {Key key}) : super(key: key);

  final RunDetailAggregate eventAggregate;
  final Function getUpdatedEventAggregate;

  @override
  _LocationTabState createState() => _LocationTabState();
}

class _LocationTabState extends State<LocationTab> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  Key tabKey;
  RunDetailAggregate _updatedEventAggregate;
  bool _isUpdating = false;

  final MapController mapController = MapController();

  @override
  void initState() {
    _updatedEventAggregate = widget.eventAggregate;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return runLocationsBody();
    // return Stack(children: <Widget>[
    //   Container(height: MediaQuery.of(context).size.height, width: MediaQuery.of(context).size.width),
    //   Positioned(top: 0, left: 0, width: MediaQuery.of(context).size.width, height: MediaQuery.of(context).size.height, child: runLocationsBody()),
    //   OfflineModeRibbon(
    //     showRibbon: G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected,
    //     lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSyncAsDate),
    //     ribbonImage: 'images/icons/offline_mode.png',
    //   ),
    // ]);
  }

  Widget runLocationsBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: <Widget>[
              // Container(
              //   //decoration: Backgrounds.defaultHcBackground(),
              //   height: MediaQuery.of(context).size.height - 300,
              //   child:

              FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  center: LatLng(_updatedEventAggregate.event.narrowEventLatitude, _updatedEventAggregate.event.narrowEventLongitude),
                  zoom: 14.0,
                  minZoom: 1.0,
                  maxZoom: 18.0,
                  // plugins: <MarkerClusterPlugin>[
                  //   MarkerClusterPlugin(),
                  // ],
                ),
                layers: <LayerOptions>[
                  TileLayerOptions(
                      urlTemplate:
                          //'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          'http://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                      //subdomains: ['a', 'b', 'c']),
                      subdomains: <String>['mt0', 'mt1', 'mt2', 'mt3']),
                  MarkerLayerOptions(
                    markers: <Marker>[
                      Marker(
                        height: 50.0,
                        width: 50.0,
                        point: LatLng(G0<DeviceInfo>().deviceLat + .0, G0<DeviceInfo>().deviceLon + .0),
                        builder: (BuildContext ctx) => Container(
                          padding: const EdgeInsets.all(1.0),
                          height: 50.0,
                          width: 50.0,
                          child: IgnorePointer(
                            ignoring: true,
                            child: Image.asset(
                              'images/other/map_current_location.png',
                              height: 50.0,
                              width: 50.0,
                            ),
                          ),
                        ),
                      ),
                      Marker(
                        width: 120.0,
                        height: 120.0,
                        point: LatLng(_updatedEventAggregate.event.narrowEventLatitude + .0, _updatedEventAggregate.event.narrowEventLongitude + .0),
                        builder: (BuildContext ctx) => GestureDetector(
                          //onTap: () => _launchMaps(widget.futureRun.event),
                          child: Container(
                            padding: const EdgeInsets.only(bottom: 58.0),
                            child: Image.asset('images/icons/map_pin_foot.png'),
                            //child: FlutterLogo(colors: Colors.purple),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),

              IgnorePointer(
                ignoring: true,
                child: Image.asset('images/other/map_center_target.png', height: 300.0, width: 300.0),
              ),
              Positioned(
                left: 10.0,
                right: 10.0,
                bottom: 40.0,
                child: Container(
                  padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                  child: Text(_updatedEventAggregate.event.useFbLatLon == 1 ? 'Facebook Location' : 'Harrier Central Location',
                      textAlign: TextAlign.center, style: headingStyle20Black),
                  decoration: BoxDecoration(
                    color: Colors.yellow[100],
                    border: Border.all(width: 2.0),
                    borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                  ),
                ),
              ),
              Positioned(
                right: 10.0,
                top: 10.0,
                child: GestureDetector(
                  onTap: () {
                    mapController.move(
                      LatLng(G0<DeviceInfo>().deviceLat + .0, G0<DeviceInfo>().deviceLon + .0),
                      mapController.zoom,
                    );
                  },
                  child: Container(
                    height: 50.0,
                    width: 50.0,
                    child: Image.asset('images/other/set_map_to_current_location.png'),
                  ),
                ),
              ),
              Positioned(
                right: 70.0,
                top: 10.0,
                child: GestureDetector(
                  onTap: () {
                    mapController.move(
                      LatLng(_updatedEventAggregate.event.narrowEventLatitude + .0, _updatedEventAggregate.event.narrowEventLongitude + .0),
                      mapController.zoom,
                    );
                  },
                  child: Container(
                    height: 50.0,
                    width: 50.0,
                    child: Image.asset('images/other/set_map_to_event_location.png'),
                  ),
                ),
              ),
              Positioned(
                left: 10.0,
                right: 10.0,
                bottom: 80.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    _isUpdating
                        ? Container(
                            height: 70.0,
                            width: 70.0,
                            child: HcCircularProgressIndicator(key: UniqueKey()),
                          )
                        : ElevatedButton(
                            child: Text('Set Location', style: buttonLabelStyleMedium),
                            onPressed: () {
                              setState(() {
                                _isUpdating = true;
                                final EventsService nSvc = EventsService();
                                nSvc
                                    .addEditEvent(
                                  eventId: widget.eventAggregate.event.eventId,
                                  lat: mapController.center.latitude,
                                  lon: mapController.center.longitude,
                                  useFbLatLon: 0,
                                )
                                    .then((void dummy) async {
                                  _updatedEventAggregate = await widget.getUpdatedEventAggregate();
                                  setState(() {
                                    _isUpdating = false;
                                  });
                                });

                                //_showEventPopup(_calendarController.selectedDay);
                              });
                            },
                          ),
                    if ((widget.eventAggregate.event.eventFacebookId != null) && (!_isUpdating)) ...<Widget>[
                      ElevatedButton(
                        child: Text('Use Facebook', style: buttonLabelStyleMedium),
                        onPressed: () {
                          setState(() {
                            _isUpdating = true;
                            final EventsService nSvc = EventsService();
                            nSvc
                                .addEditEvent(
                              eventId: widget.eventAggregate.event.eventId,
                              useFbLatLon: 1,
                            )
                                .then((void dummy) async {
                              _updatedEventAggregate = await widget.getUpdatedEventAggregate();
                              setState(() {
                                _isUpdating = false;
                              });
                            });
                          });
                        },
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class OtherInfoTab extends StatefulWidget {
  const OtherInfoTab({Key key}) : super(key: key);

  @override
  _OtherInfoTabState createState() => _OtherInfoTabState();
}

class _OtherInfoTabState extends State<OtherInfoTab> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  Key tabKey;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(color: Colors.teal);
  }
}
