import 'package:date_time_picker/date_time_picker.dart';
import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as latlng;

class EditRunDetailsPage extends StatefulWidget {
  const EditRunDetailsPage(
    this.isNewRun,
    this.eventAggregate,
    this.getUpdatedEventAggregate, {
    super.key,
  });

  final bool isNewRun;
  final RunAdminAggregate eventAggregate;
  final Function getUpdatedEventAggregate;

  @override
  EditRunDetailsPageState createState() => EditRunDetailsPageState();
}

class EditRunDetailsPageState extends State<EditRunDetailsPage> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final List<Tab> _tabs = <Tab>[];

  late TabController _tabController;
  bool _isUpdating = false;

  late RunAdminAggregate _eventAggregate;

  late latlng.LatLng _mapCenter;

  //GlobalKey _tabKey;

  final GlobalKey<FormState> _detailsFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _otherDetailsFormKey = GlobalKey<FormState>();

  final GlobalKey<MyFlutterMapState> _mapKey = GlobalKey<MyFlutterMapState>();

  final FocusNode _focusNodeAbsoluteEventNumber = FocusNode();
  final FocusNode _focusNodeEventPriceForMembers = FocusNode();
  final FocusNode _focusNodeEventPriceForNonMembers = FocusNode();
  final FocusNode _focusNodeEventPriceForExtras = FocusNode();
  final FocusNode _focusNodeExtrasDescription = FocusNode();
  final FocusNode _focusNodeDatetime = FocusNode();
  final FocusNode _focusNodeEventName = FocusNode();
  final FocusNode _focusNodeEventDescription = FocusNode();
  final FocusNode _focusNodeLocationOneLineDesc = FocusNode();
  final FocusNode _focusNodeHares = FocusNode();

  final TextEditingController _eventDatetimeController = TextEditingController();
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _eventDescriptionController = TextEditingController();
  final TextEditingController _locationOneLineDescController = TextEditingController();
  final TextEditingController _absoluteEventNumberController = TextEditingController();
  final TextEditingController _eventPriceForMembersController = TextEditingController();
  final TextEditingController _eventPriceForNonMembersController = TextEditingController();
  final TextEditingController _eventPriceForExtrasController = TextEditingController();
  final TextEditingController _extrasDescriptionController = TextEditingController();
  final TextEditingController _haresController = TextEditingController();

  bool _isVisible = true;
  bool _isCountedRun = true;
  int _usersCanEditRunAttendence = 0;
  bool _isPromotedEvent = false;
  int _eventGeographicScope = 1;
  bool _trueNorthLock = true;

  //Future<File> _imageFromCamera;
  Future<File?> _imageFromGallery = Future.value(null);
  //final SelectedImageTypeEnum _imageTypeSelection = SelectedImageTypeEnum.none;
  //SelectedImageTypeEnum _previousImageTypeSelection = SelectedImageTypeEnum.none;

  @override
  void dispose() {
    _eventDatetimeController.dispose();
    _eventNameController.dispose();
    _eventDescriptionController.dispose();
    _locationOneLineDescController.dispose();

    _focusNodeDatetime.dispose();
    _focusNodeEventName.dispose();
    _focusNodeEventDescription.dispose();
    _focusNodeLocationOneLineDesc.dispose();

    _tabController.dispose();

    _absoluteEventNumberController.dispose();
    _eventPriceForMembersController.dispose();
    _eventPriceForNonMembersController.dispose();
    _eventPriceForExtrasController.dispose();
    _extrasDescriptionController.dispose();
    _haresController.dispose();

    _focusNodeAbsoluteEventNumber.dispose();
    _focusNodeEventPriceForMembers.dispose();
    _focusNodeEventPriceForNonMembers.dispose();
    _focusNodeEventPriceForExtras.dispose();
    _focusNodeExtrasDescription.dispose();
    _focusNodeHares.dispose();
    super.dispose();
  }

  void _setTextFields() {
    _eventNameController.text = _eventAggregate.event.eventName;
    _eventDescriptionController.text = _eventAggregate.event.eventDescription ?? '';
    _eventDatetimeController.text = _eventAggregate.event.eventStartDatetime.toString();
    _locationOneLineDescController.text = _eventAggregate.event.locationOneLineDesc ?? '';
    _haresController.text = _eventAggregate.event.hares ?? '';

    _absoluteEventNumberController.text = _eventAggregate.event.absoluteEventNumber?.toString() ?? '';
    _eventPriceForMembersController.text = _eventAggregate.event.eventPriceForMembers?.toStringAsFixed(_eventAggregate.extensions.digAfterDec) ?? '';
    _eventPriceForNonMembersController.text = _eventAggregate.event.eventPriceForNonMembers?.toStringAsFixed(_eventAggregate.extensions.digAfterDec) ?? '';
    _eventPriceForExtrasController.text = _eventAggregate.event.eventPriceForExtras?.toStringAsFixed(_eventAggregate.extensions.digAfterDec) ?? '';
    _extrasDescriptionController.text = _eventAggregate.event.extrasDescription ?? '';
    _eventGeographicScope = _eventAggregate.event.eventGeographicScope;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 28.0,
        ),
        title: Text('Edit run details', style: ts_appBarTitle),
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackgroundLight(),
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
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  //color: Colors.white,
                  height: 85,
                  decoration: BoxDecoration(
                    // border: new Border.all(width: 1.0, color: Colors.black),
                    //shape: BoxShape.circle,
                    color: Colors.yellow.shade50,
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color.fromARGB(70, 0, 0, 0),
                        offset: Offset(0.0, 6.0),
                        blurRadius: 10.0,
                      ),
                    ],
                  ),
                )),
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
                child: Container(
                  padding: const EdgeInsets.only(left: 1.0, right: 1.0),
                  child: TabBar(
                    physics: const NeverScrollableScrollPhysics(),
                    labelStyle: ts_condensedMediumBlack,
                    unselectedLabelStyle: ts_condensedMediumBlack,
                    isScrollable: false,
                    unselectedLabelColor: Colors.black,
                    labelColor: Colors.white,
                    labelPadding: const EdgeInsets.only(top: 5, left: 20, right: 20),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BubbleTabIndicator(
                      indicatorHeight: 35.0,
                      indicatorColor: Colors.red.shade900,
                      tabBarIndicatorSize: TabBarIndicatorSize.tab,
                      indicatorRadius: 20.0,
                    ),
                    tabs: _tabs,
                    controller: _tabController,
                  ),
                ),
              ),
            ),
            Positioned(
                top: 86,
                bottom: 0,
                child: SizedBox(
                  //key: _tabKey,
                  //color: Colors.teal,
                  width: MediaQuery.of(context).size.width,
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: _tabController,
                    children: <Widget>[
                      _buildDetailsPage(context),
                      _buildMapPage(),
                      _buildImagePage(),
                      _buildOtherDetailsPage(context)
                      //OtherInfoTab(_eventAggregate, widget.getUpdatedEventAggregate),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(vsync: this, length: _tabs.length);
    _tabController.addListener(() {
      FocusScope.of(context).unfocus();
    });

    _eventAggregate = widget.eventAggregate;

    _mapCenter = latlng.LatLng(
      _eventAggregate.extensions.latitude ?? _eventAggregate.extensions.kenlLat,
      _eventAggregate.extensions.longitude ?? _eventAggregate.extensions.kenlLon,
    );
    _initTabs();

    _setTextFields();

    _focusNodeEventName.addListener(() {
      setState(() {});
    });

    _focusNodeEventDescription.addListener(() {
      setState(() {});
    });

    _focusNodeDatetime.addListener(() {
      setState(() {});
    });

    _focusNodeLocationOneLineDesc.addListener(() {
      setState(() {});
    });

    _focusNodeAbsoluteEventNumber.addListener(() {
      setState(() {});
    });

    _focusNodeEventPriceForMembers.addListener(() {
      setState(() {});
    });

    _focusNodeEventPriceForNonMembers.addListener(() {
      setState(() {});
    });

    _eventPriceForExtrasController.addListener(() {
      setState(() {});
    });

    _extrasDescriptionController.addListener(() {
      setState(() {});
    });
  }

  void _initTabs() {
    if (_tabs.isEmpty) {
      _tabs.add(const Tab(text: 'Details'));
      _tabs.add(const Tab(text: 'Map'));
      _tabs.add(const Tab(text: 'Image'));
      _tabs.add(const Tab(text: 'Other'));
      //tabs.add(const Tab(text: 'Date/Time'));
    }
  }

  Future<void> _useExternalSourceDetails() async {
    setState(() {
      _isUpdating = true;
    });
    final EventsService nSvc = EventsService();
    final String eventId = await nSvc.addEditEvent(
      eventId: _eventAggregate.event.eventId,
      useFbRunDetails: 1,
    );

    _eventAggregate = await widget.getUpdatedEventAggregate(eventId);
    setState(() {
      _isUpdating = false;
      _setTextFields();
      final SnackBar snackBar = SnackBar(
        duration: const Duration(seconds: 3),
        content: Text(
          _eventAggregate.event.eventInboundIntegrationId >= integrationPlatformNames.length
              ? 'Run details being synced from external source'
              : 'Run details being synced from ${integrationPlatformNames[_eventAggregate.event.eventInboundIntegrationId]}',
          textAlign: TextAlign.center,
          style: ts_titleCondensedBlack,
        ),
        backgroundColor: Colors.blue.shade700,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  Future<void> _updateRunDetails(bool isMainRunDetailsPage) async {
    if (isMainRunDetailsPage) {
      if (_detailsFormKey.currentState?.validate() ?? false) {
        //    If all data are correct then save data to out variables
        _detailsFormKey.currentState!.save();

        FocusScope.of(context).unfocus();
        setState(() {
          _isUpdating = true;
        });

        final EventsService nSvc = EventsService();
        final String eventId = await nSvc.addEditEvent(
          eventId: _eventAggregate.event.eventId,
          eventName: _eventNameController.text,
          eventStartDatetime: DateTime.tryParse(_eventDatetimeController.text),
          eventDescription: _eventDescriptionController.text,
          locationOneLineDesc: _locationOneLineDescController.text,
          useFbRunDetails: 0,
          isCountedRun: _eventAggregate.event.isCountedRun == 1,
          kennelId: _eventAggregate.event.kennelId,
          eventPriceForMembers: _eventPriceForMembersController.text.isEmpty ? -2 : double.tryParse(_eventPriceForMembersController.text.replaceAll(',', '.')),
          eventPriceForNonMembers: _eventPriceForNonMembersController.text.isEmpty ? -2 : double.tryParse(_eventPriceForNonMembersController.text.replaceAll(',', '.')),
          eventPriceForExtras: _eventPriceForExtrasController.text.isEmpty ? -2 : double.tryParse(_eventPriceForExtrasController.text.replaceAll(',', '.')),
        );

        _eventAggregate = await widget.getUpdatedEventAggregate(eventId);
      }
    } else {
      if ((_eventAggregate.event.eventId.isEmpty) || (_eventAggregate.event.eventId == GUID_EMPTY)) {
        await Utilities.showAlert(
          'Please save Details first',
          'Please fill in the run name and other information on the Details tab and save those details before saving other information on this tab.',
          'OK',
        );
        _tabController.animateTo(0);
      } else {
        if (_otherDetailsFormKey.currentState?.validate() ?? false) {
          //    If all data are correct then save data to out variables
          _otherDetailsFormKey.currentState!.save();

          FocusScope.of(context).unfocus();
          _isUpdating = true;
          final EventsService nSvc = EventsService();
          final String eventId = await nSvc.addEditEvent(
            eventId: _eventAggregate.event.eventId,
            eventPriceForMembers: _eventPriceForMembersController.text.isEmpty ? -2 : double.tryParse(_eventPriceForMembersController.text.replaceAll(',', '.')),
            eventPriceForNonMembers: _eventPriceForNonMembersController.text.isEmpty ? -2 : double.tryParse(_eventPriceForNonMembersController.text.replaceAll(',', '.')),
            // note for "auto" the value we send to the server is '0' because this will
            // remove any previous absoluteEventNumber that is stored there
            absoluteEventNumber: _absoluteEventNumberController.text.isEmpty ? 0 : int.tryParse(_absoluteEventNumberController.text),
            eventPriceForExtras: _eventPriceForExtrasController.text.isEmpty ? -2 : double.tryParse(_eventPriceForExtrasController.text.replaceAll(',', '.')),
            extrasDescription: _extrasDescriptionController.text.isEmpty ? '<none>' : _extrasDescriptionController.text,
            hares: _haresController.text,
            isCountedRun: _isCountedRun,
            isVisible: _isVisible,
            isPromotedEvent: _isPromotedEvent,
            eventGeographicScope: _eventGeographicScope,
            usersCanEditRunAttendence: _usersCanEditRunAttendence,
          );

          _eventAggregate = await widget.getUpdatedEventAggregate(eventId);
          setState(() {
            _isUpdating = false;
            // final SnackBar snackBar = SnackBar(
            //   duration: const Duration(seconds: 3),
            //   content: const Text(
            //     'Other info has been saved',
            //     textAlign: TextAlign.center,
            //     style: TextStyle(fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 20.0, height: 0.85),
            //   ),
            //   backgroundColor: Colors.blue.shade700,
            // );
            // ScaffoldMessenger.of(context).showSnackBar(snackBar);
          });
        }
      }
    }
  }

  KeyboardActionsConfig _buildConfig(BuildContext context) {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      keyboardBarColor: Colors.grey[200],
      nextFocus: true,
      actions: <KeyboardActionsItem>[
        KeyboardActionsItem(
          focusNode: _focusNodeEventName,
        ),
        KeyboardActionsItem(
          focusNode: _focusNodeEventDescription,
        ),

        KeyboardActionsItem(
          focusNode: _focusNodeAbsoluteEventNumber,
        ),
        KeyboardActionsItem(
          focusNode: _focusNodeEventPriceForMembers,
        ),
        KeyboardActionsItem(
          focusNode: _focusNodeEventPriceForNonMembers,
        ),
        KeyboardActionsItem(
          focusNode: _focusNodeEventPriceForExtras,
        ),
        KeyboardActionsItem(
          focusNode: _focusNodeExtrasDescription,
        ),
        KeyboardActionsItem(
          focusNode: _focusNodeHares,
        ),

        // KeyboardActionsItem(
        //   focusNode: focusNodeDatetime,
        // ),
        KeyboardActionsItem(
          focusNode: _focusNodeLocationOneLineDesc,
        ),
      ],
    );
  }

  Widget _buildDetailsPage(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        disabledColor: Colors.grey,
        iconTheme: IconTheme.of(context).copyWith(
          color: Colors.red.shade700,
          size: 35,
        ),
      ),
      child: KeyboardActions(
        config: _buildConfig(context),
        tapOutsideBehavior: TapOutsideBehavior.none,
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
                      margin: const EdgeInsets.only(top: 25.0, bottom: 5.0),
                      padding: const EdgeInsets.only(top: 5.0, bottom: 5.0, left: 20.0, right: 20.0),
                      decoration: BoxDecoration(
                        color: Colors.yellow[100],
                        border: Border.all(width: 2.0),
                        borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                      ),
                      child: Text(
                          _eventAggregate.event.useFbRunDetails == 1
                              ? _eventAggregate.event.eventInboundIntegrationId >= integrationPlatformNames.length
                                  ? 'Run data from external source'
                                  : 'Run data from ${integrationPlatformNames[_eventAggregate.event.eventInboundIntegrationId]}'
                              : 'Run data from Harrier Central',
                          textAlign: TextAlign.center,
                          style: ts_headingBlack),
                    ),
                    Container(
                      color: _focusNodeEventName.hasFocus ? Colors.yellow.shade50 : Colors.white,
                      margin: const EdgeInsets.only(top: 20.0, bottom: 10.0, left: 25.0, right: 25.0),
                      child: TextFormField(
                        focusNode: _focusNodeEventName,
                        controller: _eventNameController,
                        minLines: 1,
                        maxLines: 2,
                        onChanged: (String text) {
                          //widget.EventName = text;
                        },
                        keyboardType: TextInputType.multiline,
                        validator: (String? val) {
                          if ((val ?? '').isEmpty) {
                            return 'Please provide an event name';
                          } else {
                            return null;
                          }
                        },
                        textCapitalization: TextCapitalization.sentences,
                        style: ts_titleMediumBlack,
                        decoration: InputDecoration(
                          labelText: 'Event name',
                          fillColor: Colors.red,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(),
                          ),
                          hintText: 'Event Name',
                          hintStyle: ts_titleMediumBlack,
                        ),
                      ),
                    ),
                    Container(
                      color: _focusNodeEventDescription.hasFocus ? Colors.yellow.shade50 : Colors.white,
                      margin: const EdgeInsets.only(top: 10.0, bottom: 10.0, left: 25.0, right: 25.0),
                      child: TextFormField(
                        onChanged: (String text) {
                          //widget.EventDescription = text;
                        },
                        maxLines: null,
                        focusNode: _focusNodeEventDescription,
                        controller: _eventDescriptionController,
                        validator: (String? val) {
                          if ((val ?? '').isEmpty) {
                            return 'Please provide an event description';
                          } else {
                            return null;
                          }
                        },
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        style: ts_titleMediumBlack,
                        decoration: InputDecoration(
                          labelText: 'Event Description',
                          fillColor: Colors.red,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(),
                          ),
                          hintText: 'Event Description',
                          hintStyle: ts_titleMediumBlack,
                        ),
                      ),
                    ),
                    Container(
                      color: _focusNodeLocationOneLineDesc.hasFocus ? Colors.yellow.shade50 : Colors.white,
                      margin: const EdgeInsets.only(top: 20.0, bottom: 10.0, left: 25.0, right: 25.0),
                      child: TextFormField(
                        focusNode: _focusNodeLocationOneLineDesc,
                        controller: _locationOneLineDescController,
                        minLines: 1,
                        maxLines: 2,
                        onChanged: (String text) {
                          //widget.EventName = text;
                        },
                        keyboardType: TextInputType.multiline,
                        validator: (String? val) {
                          if ((val ?? '').isEmpty) {
                            return 'Please provide a location description';
                          } else {
                            return null;
                          }
                        },
                        textCapitalization: TextCapitalization.sentences,
                        style: ts_titleMediumBlack,
                        decoration: InputDecoration(
                          labelText: 'Location one-line description',
                          fillColor: Colors.red,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(),
                          ),
                          hintText: 'Location description',
                          hintStyle: ts_titleMediumBlack,
                        ),
                      ),
                    ),
                    Container(
                      color: _focusNodeDatetime.hasFocus ? Colors.yellow.shade50 : Colors.white,
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
                          hintStyle: ts_titleMediumBlack,
                        ),
                        focusNode: _focusNodeDatetime,
                        controller: _eventDatetimeController,
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
                        // onChanged: (val) => //print(val),
                        validator: (String? val) {
                          //print(val);
                          return null;
                        },
                        //onSaved: (String val) => //print(val),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 25.0, bottom: 5.0),
                      padding: const EdgeInsets.only(top: 5.0, bottom: 5.0, left: 20.0, right: 20.0),
                      decoration: BoxDecoration(
                        color: Colors.yellow[100],
                        border: Border.all(width: 2.0),
                        borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                      ),
                      child: Text(
                          _eventAggregate.event.useFbRunDetails == 1
                              ? _eventAggregate.event.eventInboundIntegrationId >= integrationPlatformNames.length
                                  ? 'Run data from external source'
                                  : 'Run data from ${integrationPlatformNames[_eventAggregate.event.eventInboundIntegrationId]}'
                              : 'Run data from Harrier Central',
                          textAlign: TextAlign.center,
                          style: ts_headingBlack),
                    ),
                    const SizedBox(height: 20.0),
                    _isUpdating
                        ? const SizedBox(
                            height: 70.0,
                            width: 70.0,
                            child: HcCircularProgressIndicator(key: Key('112096562')),
                          )
                        : ElevatedButton(
                            child: Text(widget.isNewRun ? 'Next' : 'Save changes to Harrier Central', style: ts_button),
                            onPressed: () async {
                              if (_detailsFormKey.currentState?.validate() ?? false) {
                                await _updateRunDetails(true);

                                if (widget.isNewRun) {
                                  // this delay is required to ensure that the _isUpdating setState
                                  // to function properly
                                  _tabController.animateTo(1);
                                } else {
                                  final SnackBar snackBar = SnackBar(
                                    duration: const Duration(seconds: 3),
                                    content: Text(
                                      'Run details have been saved',
                                      textAlign: TextAlign.center,
                                      style: ts_titleCondensedBlack,
                                    ),
                                    backgroundColor: Colors.blue.shade700,
                                  );

                                  if (!mounted) return;
                                  ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(snackBar);
                                }
                                await Future<void>.delayed(const Duration(milliseconds: 500));
                                setState(() {
                                  _isUpdating = false;
                                });
                              }
                            },
                          ),
                    if ((_eventAggregate.event.eventFacebookId != null) && (!_isUpdating)) ...<Widget>[
                      ElevatedButton(
                        child: Text(
                            'Copy data from ${_eventAggregate.event.eventInboundIntegrationId >= integrationPlatformNames.length ? 'external source' : integrationPlatformNames[_eventAggregate.event.eventInboundIntegrationId]}',
                            style: ts_button),
                        onPressed: () {
                          setState(() {
                            _useExternalSourceDetails();
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 80.0),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePage() {
    return FutureBuilder<File?>(
        future: _imageFromGallery,
        builder: (BuildContext context, AsyncSnapshot<File?> snapshot) {
          if (snapshot.hasData) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(20.0),
                    child: Image.file(snapshot.data!, fit: BoxFit.scaleDown),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40), // double.infinity is the width and 30 is the height
                      ),
                      child: Text('Use this image', style: ts_button),
                      onPressed: () async {
                        if ((_eventAggregate.event.eventId.isNotEmpty) && (_eventAggregate.event.eventId != GUID_EMPTY)) {
                          final String fileName = _upload(snapshot.data!, _eventAggregate.event.eventId);

                          final EventsService nSvc = EventsService();
                          final String eventId = await nSvc.addEditEvent(
                            eventId: _eventAggregate.event.eventId,
                            eventImageUrl: BASE_EVENT_IMAGE_URL + fileName,
                            useFbImage: 0,
                          );

                          _eventAggregate = await widget.getUpdatedEventAggregate(eventId);

                          if (widget.isNewRun) {
                            setState(() {
                              _isUpdating = false;
                            });
                            await Future<void>.delayed(const Duration(milliseconds: 1000));
                            _tabController.animateTo(3);
                          } else {
                            setState(() {
                              _isUpdating = false;
                            });

                            final SnackBar snackBar = SnackBar(
                              duration: const Duration(seconds: 3),
                              content: Text(
                                'Event image has been updated',
                                textAlign: TextAlign.center,
                                style: ts_titleCondensedBlack,
                              ),
                              backgroundColor: Colors.blue.shade700,
                            );

                            if (!mounted) return;
                            ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(snackBar);
                          }
                        }
                      }),
                ),
                //const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40), // double.infinity is the width and 30 is the height
                    ),
                    child: Text('Select again from gallery', style: ts_button),
                    onPressed: () {
                      _getImageFromGallery(ImageSource.gallery);
                    },
                  ),
                ),
                if ((_eventAggregate.event.eventFacebookId != null) && (!_isUpdating)) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40), // double.infinity is the width and 30 is the height
                      ),
                      child: Text('Use image from ${integrationPlatformNames[_eventAggregate.event.eventInboundIntegrationId]}', style: ts_button),
                      onPressed: () async {
                        setState(() {
                          _isUpdating = true;
                        });
                        final EventsService nSvc = EventsService();
                        final String eventId = await nSvc.addEditEvent(
                          eventId: _eventAggregate.event.eventId,
                          useFbImage: 1,
                        );

                        _eventAggregate = await widget.getUpdatedEventAggregate(eventId);
                        setState(() {
                          _isUpdating = false;
                          final SnackBar snackBar = SnackBar(
                            duration: const Duration(seconds: 3),
                            content: Text(
                              'Image is being synced from ${integrationPlatformNames[_eventAggregate.event.eventInboundIntegrationId]}',
                              textAlign: TextAlign.center,
                              style: ts_titleCondensedBlack,
                            ),
                            backgroundColor: Colors.blue.shade700,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        });
                      },
                    ),
                  ),
                ],
                //const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40), // double.infinity is the width and 30 is the height
                    ),
                    child: Text('Use original image', style: ts_button),
                    onPressed: () {
                      setState(() {
                        _imageFromGallery = Future<File?>.value(null);
                      });
                    },
                  ),
                ),
                const SizedBox(height: 40),
              ],
            );
          } else {
            return _isUpdating
                ? const SizedBox(
                    height: 70.0,
                    width: 70.0,
                    child: HcCircularProgressIndicator(key: Key('6669001123')),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      if (_eventAggregate.event.eventImage != null) ...<Widget>[
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(20.0),
                            //height: G0<DeviceInfo>().deviceHeight - 235,
                            child: Column(
                              //mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Expanded(
                                  child: CachedNetworkImage(
                                    imageUrl: _eventAggregate.event.eventImage!,
                                    // errorWidget:
                                    //     (BuildContext context, String url, Exception error) =>
                                    //         const  Icon(Icons.error),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size(double.infinity, 40), // double.infinity is the width and 30 is the height
                                        ),
                                        child: Text('Select from gallery', style: ts_button),
                                        onPressed: () {
                                          _getImageFromGallery(ImageSource.gallery);
                                        },
                                      ),
                                    ),
                                    if ((_eventAggregate.event.eventFacebookId != null) && (!_isUpdating)) ...<Widget>[
                                      const SizedBox(height: 10),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            minimumSize: const Size(double.infinity, 40), // double.infinity is the width and 30 is the height
                                          ),
                                          child: Text(
                                              'Use ${_eventAggregate.event.eventInboundIntegrationId >= integrationPlatformNames.length ? 'external source' : integrationPlatformNames[_eventAggregate.event.eventInboundIntegrationId]}',
                                              style: ts_button),
                                          onPressed: () async {
                                            setState(() {
                                              _isUpdating = true;
                                            });
                                            final EventsService nSvc = EventsService();
                                            final String eventId = await nSvc.addEditEvent(
                                              eventId: _eventAggregate.event.eventId,
                                              useFbImage: 1,
                                            );

                                            _eventAggregate = await widget.getUpdatedEventAggregate(eventId);
                                            setState(() {
                                              _isUpdating = false;
                                              final SnackBar snackBar = SnackBar(
                                                duration: const Duration(seconds: 3),
                                                content: Text(
                                                  'Image is being synced from ${_eventAggregate.event.eventInboundIntegrationId >= integrationPlatformNames.length ? 'external source' : integrationPlatformNames[_eventAggregate.event.eventInboundIntegrationId]}',
                                                  textAlign: TextAlign.center,
                                                  style: ts_titleCondensedBlack,
                                                ),
                                                backgroundColor: Colors.blue.shade700,
                                              );
                                              ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (_eventAggregate.event.eventImage == null) ...<Widget>[
                        Text(
                          'No image provided',
                          textAlign: TextAlign.center,
                          style: ts_headingVeryLarge.copyWith(color: Colors.black),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 40), // double.infinity is the width and 30 is the height
                            ),
                            child: Text('Select from gallery', style: ts_button),
                            onPressed: () {
                              _getImageFromGallery(ImageSource.gallery);
                            },
                          ),
                        ),
                      ],
                      if (widget.isNewRun) ...<Widget>[
                        ElevatedButton(
                          child: Text(
                            'Skip',
                            style: ts_button,
                          ),
                          onPressed: () {
                            setState(() {
                              _tabController.animateTo(3);
                            });
                          },
                        ),
                        const SizedBox(width: 20.0),
                      ],
                    ],
                  );
          }
        });
  }

  String _upload(File imageFile, String eventId) {
    final String datetime = DateFormat('yyyyMMddkkmmss').format(DateTime.now());
    final String fileName = 'eventImage_${eventId}_$datetime.jpg';
    final Uri uri = Uri.parse(
        'https://harriercentral.blob.core.windows.net/event-images/$fileName?sv=2020-04-08&st=2021-09-15T14%3A03%3A04Z&se=2100-09-16T14%3A03%3A00Z&sr=c&sp=racwdxlt&sig=q%2BVTH8wcrKOlSZK1FH7cUoaoYFPtjGpblCAVUqA4WFY%3D');

    final Request request = Request('PUT', uri);

    final Map<String, String> headers = <String, String>{'content-type': 'image/jpeg', 'x-ms-blob-type': 'BlockBlob'};

    request.headers.addAll(headers);

    request.bodyBytes = imageFile.readAsBytesSync();
    request.send().then((StreamedResponse response) {
      //print('Avatar thumbnail upload response = ${response.statusCode}');
    });

    return fileName;
  }

  Future<void> _getImageFromGallery(ImageSource source) async {
    if ((_eventAggregate.event.eventId.isEmpty) || (_eventAggregate.event.eventId == GUID_EMPTY)) {
      await Utilities.showAlert(
        'Please save Details first',
        'Please fill in the run name and other information on the Details tab and save those details before saving other information on this tab.',
        'OK',
      );

      _tabController.animateTo(0);
    } else {
      final XFile? image = await ImagePicker().pickImage(source: source);

      if (image == null) {
        // setState(() {
        //   _selectedRadioValue = _previouslySelectedRadioValue;
        //   _imageTypeSelection = _previousImageTypeSelection;
        // });
      } else {
        final ImageCropper ic = ImageCropper();
        final CroppedFile? croppedFile = await ic.cropImage(
            sourcePath: image.path,
            //aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
            //aspectRatioPresets: <CropAspectRatioPreset>[CropAspectRatioPreset.square],
            maxWidth: 1000,
            maxHeight: 1000,
            compressFormat: ImageCompressFormat.jpg,
            compressQuality: 50);

        setState(() {
          if (croppedFile != null) {
            _imageFromGallery = Future<File>.value(File(croppedFile.path));
          }
        });
      }
    }
  }

  Widget _buildMapPage() {
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

              MyFlutterMap(
                _eventAggregate.extensions.latitude == null ? null : latlng.LatLng(_eventAggregate.extensions.latitude!, _eventAggregate.extensions.longitude!),
                _mapCenter,
                latlng.LatLng(_eventAggregate.extensions.kenlLat, _eventAggregate.extensions.kenlLon),
                1.0,
                18.0,
                14.0,
                _trueNorthLock,
                _mapKey,
                mapMoved: (latlng.LatLng newPosition) {
                  _mapCenter = newPosition;
                },
              ),
              if ((_mapCenter.latitude == CLEAR_LATLONG) || (_mapCenter.longitude == CLEAR_LATLONG)) ...<Widget>[
                GestureDetector(
                  onTapDown: (dynamic tapDownDetails) {
                    setState(() {
                      _mapCenter = latlng.LatLng(_eventAggregate.extensions.kenlLat, _eventAggregate.extensions.kenlLon);
                    });
                  },
                  child: Container(color: Colors.black54),
                ),
                IgnorePointer(
                  ignoring: true,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 60.0),
                    child: Text(
                      'No location selected',
                      textAlign: TextAlign.center,
                      style: ts_headingVeryLarge,
                    ),
                  ),
                ),
              ],
              if ((_mapCenter.latitude != CLEAR_LATLONG) || (_mapCenter.longitude != CLEAR_LATLONG)) ...<Widget>[
                IgnorePointer(
                  ignoring: true,
                  child: Image.asset('images/other/map_center_target.png', height: 300.0, width: 300.0),
                ),
              ],

              Positioned(
                left: 10.0,
                right: 10.0,
                bottom: 40.0,
                child: Container(
                  padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                  decoration: BoxDecoration(
                    color: Colors.yellow[100],
                    border: Border.all(width: 2.0),
                    borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                  ),
                  child: Text(
                      _eventAggregate.event.useFbLatLon == 1
                          ? 'Location from ${_eventAggregate.event.eventInboundIntegrationId >= integrationPlatformNames.length ? 'external source' : integrationPlatformNames[_eventAggregate.event.eventInboundIntegrationId]}'
                          : 'Location from Harrier Central',
                      textAlign: TextAlign.center,
                      style: ts_headingBlack),
                ),
              ),

              Positioned(
                right: 10.0,
                top: 10.0,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _mapCenter = const latlng.LatLng(CLEAR_LATLONG, CLEAR_LATLONG);
                    });
                  },
                  child: SizedBox(
                    height: 50.0,
                    width: 50.0,
                    child: Image.asset('images/other/set_map_to_no_location.png'),
                  ),
                ),
              ),

              if ((G0<DeviceInfo>().deviceLat != null) && (G0<DeviceInfo>().deviceLon != null)) ...<Widget>[
                Positioned(
                  right: 70.0,
                  top: 10.0,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _mapCenter = latlng.LatLng(G0<DeviceInfo>().deviceLat!, G0<DeviceInfo>().deviceLon!);
                      });
                    },
                    child: SizedBox(
                      height: 50.0,
                      width: 50.0,
                      child: Image.asset('images/other/set_map_to_current_location.png'),
                    ),
                  ),
                ),
              ],

              if (_eventAggregate.extensions.isMapAndDistanceValid ?? false) ...<Widget>[
                Positioned(
                  right: 130.0,
                  top: 10.0,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _mapCenter = latlng.LatLng(
                          _eventAggregate.extensions.latitude!,
                          _eventAggregate.extensions.longitude!,
                        );
                      });
                    },
                    child: SizedBox(
                      height: 50.0,
                      width: 50.0,
                      child: Image.asset('images/other/set_map_to_event_location.png'),
                    ),
                  ),
                ),
              ],
              Positioned(
                left: 10.0,
                top: 10.0,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _trueNorthLock = !_trueNorthLock;
                    });
                  },
                  child: SizedBox(
                    height: 50.0,
                    width: 50.0,
                    child: Image.asset(_trueNorthLock ? 'images/other/set_map_to_true_north_lock.png' : 'images/other/set_map_rotation_enabled.png'),
                  ),
                ),
              ),
              Positioned(
                left: 10.0,
                right: 10.0,
                bottom: 80.0,
                child: _isUpdating
                    ? const SizedBox(
                        height: 70.0,
                        width: 70.0,
                        child: HcCircularProgressIndicator(key: Key('655931031')),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          if (widget.isNewRun) ...<Widget>[
                            ElevatedButton(
                              child: Text(
                                'Skip',
                                style: ts_button,
                              ),
                              onPressed: () {
                                setState(() {
                                  _tabController.animateTo(2);
                                });
                              },
                            ),
                            const SizedBox(width: 20.0),
                          ],
                          ElevatedButton(
                            child: Text(
                              ((_mapCenter.latitude == CLEAR_LATLONG) && (_mapCenter.longitude == CLEAR_LATLONG)) ? 'Set no location' : 'Set Location',
                              style: ts_button,
                            ),
                            onPressed: () async {
                              if ((_eventAggregate.event.eventId.isEmpty) || (_eventAggregate.event.eventId == GUID_EMPTY)) {
                                await Utilities.showAlert(
                                  'Please save details first',
                                  'When creating a new event, please save the information on the Details tab before saving the location',
                                  'OK',
                                );

                                _tabController.animateTo(0);
                              } else {
                                setState(() {
                                  _isUpdating = true;
                                });
                                final EventsService nSvc = EventsService();
                                // check to see if "no location" is set. If so, don't overwrite it
                                if ((_mapCenter.latitude != CLEAR_LATLONG) && (_mapCenter.longitude != CLEAR_LATLONG) && (_mapKey.currentState?.mapController != null)) {
                                  _mapCenter = _mapKey.currentState!.mapController.camera.center;
                                }
                                final String eventId = await nSvc.addEditEvent(
                                  eventId: _eventAggregate.event.eventId,
                                  lat: _mapCenter.latitude,
                                  lon: _mapCenter.longitude,
                                  useFbLatLon: 0,
                                );
                                _eventAggregate = await widget.getUpdatedEventAggregate(eventId);

                                if (widget.isNewRun) {
                                  setState(() {
                                    _isUpdating = false;
                                  });
                                  await Future<void>.delayed(const Duration(milliseconds: 1000));
                                  _tabController.animateTo(2);
                                } else {
                                  final SnackBar snackBar = SnackBar(
                                    duration: const Duration(seconds: 3),
                                    content: Text(
                                      'Updated location saved in Harrier Central',
                                      textAlign: TextAlign.center,
                                      style: ts_titleCondensedBlack,
                                    ),
                                    backgroundColor: Colors.blue.shade700,
                                  );

                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                }

                                await Future<void>.delayed(const Duration(milliseconds: 500));
                                setState(() {
                                  _isUpdating = false;
                                });

                                //_showEventPopup(_calendarController.selectedDay);
                              }
                            },
                          ),
                          if ((_eventAggregate.event.eventFacebookId != null) && (!_isUpdating)) ...<Widget>[
                            const SizedBox(width: 20.0),
                            Expanded(
                              child: ElevatedButton(
                                child: AutoSizeText(
                                  'Use ${_eventAggregate.event.eventInboundIntegrationId >= integrationPlatformNames.length ? 'external source' : integrationPlatformNames[_eventAggregate.event.eventInboundIntegrationId]}',
                                  style: ts_button,
                                  minFontSize: 3.0,
                                  maxLines: 1,
                                  //overflow: TextOverflow.ellipsis,
                                ),
                                onPressed: () async {
                                  setState(() {
                                    _isUpdating = true;
                                  });
                                  final EventsService nSvc = EventsService();
                                  final String eventId = await nSvc.addEditEvent(
                                    eventId: _eventAggregate.event.eventId,
                                    useFbLatLon: 1,
                                  );

                                  _eventAggregate = await widget.getUpdatedEventAggregate(eventId);
                                  setState(() {
                                    if ((_eventAggregate.extensions.latitude == null) || (_eventAggregate.extensions.longitude == null)) {
                                      _mapCenter = latlng.LatLng(
                                        _eventAggregate.extensions.kenlLat,
                                        _eventAggregate.extensions.kenlLon,
                                      );
                                    } else {
                                      _mapCenter = latlng.LatLng(
                                        _eventAggregate.extensions.latitude!,
                                        _eventAggregate.extensions.longitude!,
                                      );
                                    }
                                    _isUpdating = false;
                                    final SnackBar snackBar = SnackBar(
                                      duration: const Duration(seconds: 3),
                                      content: Text(
                                        'Location is being synced from ${_eventAggregate.event.eventInboundIntegrationId >= integrationPlatformNames.length ? 'external source' : integrationPlatformNames[_eventAggregate.event.eventInboundIntegrationId]}',
                                        textAlign: TextAlign.center,
                                        style: ts_titleCondensedBlack,
                                      ),
                                      backgroundColor: Colors.blue.shade700,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
        ),
      ],
    );
  }

  Widget _buildOtherDetailsPage(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        disabledColor: Colors.grey,
        iconTheme: IconTheme.of(context).copyWith(
          color: Colors.red.shade700,
          size: 35,
        ),
      ),
      child: KeyboardActions(
        config: _buildConfig(context),
        tapOutsideBehavior: TapOutsideBehavior.none,
        child: SingleChildScrollView(
          child: Form(
            key: _otherDetailsFormKey,
            child: Wrap(
              children: <Widget>[
                Column(
                  //mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.only(top: 25.0, bottom: 5.0),
                      padding: const EdgeInsets.only(top: 5.0, bottom: 5.0, left: 20.0, right: 20.0),
                      decoration: BoxDecoration(
                        color: Colors.yellow[100],
                        border: Border.all(width: 2.0),
                        borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                      ),
                      child: Text('Run data from Harrier Central', textAlign: TextAlign.center, style: ts_headingBlack),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 20.0, bottom: 0.0, left: 30.0, right: 30.0),
                      child: Text(
                        'Enter hares here. These names will be presented in addition to anyone who has RSVPed as a Hare using the app',
                        style: ts_mediumBlack,
                      ),
                    ),
                    Container(
                      color: _focusNodeHares.hasFocus ? Colors.yellow.shade50 : Colors.white,
                      margin: const EdgeInsets.only(top: 10.0, bottom: 10.0, left: 25.0, right: 25.0),
                      child: TextFormField(
                        // onChanged: (String text) {
                        //   if ((text == null) || (text.isEmpty)) {
                        //     _absoluteEventNumberController.text = '<auto>';
                        //   } else if ((text.length > 6) && (text.contains('<auto>'))) {
                        //     _absoluteEventNumberController.text = _absoluteEventNumberController.text.replaceAll('<auto>', '');
                        //     _absoluteEventNumberController.selection = TextSelection.fromPosition(TextPosition(offset: _absoluteEventNumberController.text.length));
                        //   }
                        // },
                        maxLines: 1,
                        focusNode: _focusNodeHares,
                        controller: _haresController,
                        // validator: (String val) {
                        //   if (val.isEmpty) {
                        //     return 'Please provide an event number or leave blank for auto numbering';
                        //   } else {
                        //     return null;
                        //   }
                        // },
                        //keyboardType: const TextInputType.(),
                        textCapitalization: TextCapitalization.sentences,
                        style: ts_titleMediumBlack,
                        decoration: InputDecoration(
                          labelText: 'Hares',
                          fillColor: Colors.red,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(),
                          ),
                          hintText: '<enter Hares here>',
                          hintStyle: ts_titleMediumBlack,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 20.0, bottom: 0.0, left: 30.0, right: 30.0),
                      child: Text(
                        'Harrier Central automatically numbers runs. But if there is a reason to override this, you can manually enter a run number here.',
                        style: ts_mediumBlack,
                      ),
                    ),
                    Container(
                      color: _focusNodeAbsoluteEventNumber.hasFocus ? Colors.yellow.shade50 : Colors.white,
                      margin: const EdgeInsets.only(top: 10.0, bottom: 10.0, left: 25.0, right: 25.0),
                      child: TextFormField(
                        // onChanged: (String text) {
                        //   if ((text == null) || (text.isEmpty)) {
                        //     _absoluteEventNumberController.text = '<auto>';
                        //   } else if ((text.length > 6) && (text.contains('<auto>'))) {
                        //     _absoluteEventNumberController.text = _absoluteEventNumberController.text.replaceAll('<auto>', '');
                        //     _absoluteEventNumberController.selection = TextSelection.fromPosition(TextPosition(offset: _absoluteEventNumberController.text.length));
                        //   }
                        // },
                        maxLines: 1,
                        focusNode: _focusNodeAbsoluteEventNumber,
                        controller: _absoluteEventNumberController,
                        // validator: (String val) {
                        //   if (val.isEmpty) {
                        //     return 'Please provide an event number or leave blank for auto numbering';
                        //   } else {
                        //     return null;
                        //   }
                        // },
                        keyboardType: const TextInputType.numberWithOptions(),
                        textCapitalization: TextCapitalization.sentences,
                        style: ts_titleMediumBlack,
                        decoration: InputDecoration(
                          labelText: 'Event Number',
                          fillColor: Colors.red,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(),
                          ),
                          hintText: '<use auto numbering>',
                          hintStyle: ts_titleMediumBlack,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 20.0, bottom: 0.0, left: 30.0, right: 30.0),
                      child: Text(
                        'Enter in the hash cash amount here if it is different than the normal hash cash value.',
                        style: ts_mediumBlack,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 10.0, bottom: 10.0, left: 25.0, right: 25.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            flex: 1,
                            child: Container(
                              color: _focusNodeEventPriceForMembers.hasFocus ? Colors.yellow.shade50 : Colors.white,
                              margin: const EdgeInsets.only(right: 12.5),
                              child: TextFormField(
                                // onChanged: (String text) {
                                //   if ((text == null) || (text.isEmpty)) {
                                //     //_eventPriceForMembersController.text = '';
                                //   } else if ((text.length > 9) && (text.contains('<default>'))) {
                                //     // _eventPriceForMembersController.text = _eventPriceForMembersController.text.replaceAll('<default>', '');
                                //     // _eventPriceForMembersController.selection = TextSelection.fromPosition(TextPosition(offset: _eventPriceForMembersController.text.length));
                                //   }
                                // },
                                maxLines: 1,
                                focusNode: _focusNodeEventPriceForMembers,
                                controller: _eventPriceForMembersController,
                                keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: true),
                                textCapitalization: TextCapitalization.sentences,
                                style: ts_titleMediumBlack,
                                decoration: InputDecoration(
                                  labelText: 'Member price',
                                  fillColor: Colors.red,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(),
                                  ),
                                  hintText: '<use default>',
                                  hintStyle: ts_titleMediumBlack,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              color: _focusNodeEventPriceForNonMembers.hasFocus ? Colors.yellow.shade50 : Colors.white,
                              margin: const EdgeInsets.only(left: 12.5),
                              child: TextFormField(
                                // onChanged: (String text) {
                                //   if ((text == null) || (text.isEmpty)) {
                                //     //_eventPriceForNonMembersController.text = '<default>';
                                //   } else if ((text.length > 9) && (text.contains('<default>'))) {
                                //     _eventPriceForNonMembersController.text = _eventPriceForNonMembersController.text.replaceAll('<default>', '');
                                //     _eventPriceForNonMembersController.selection =
                                //         TextSelection.fromPosition(TextPosition(offset: _eventPriceForNonMembersController.text.length));
                                //   }
                                // },
                                maxLines: 1,
                                focusNode: _focusNodeEventPriceForNonMembers,
                                controller: _eventPriceForNonMembersController,
                                keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: true),
                                textCapitalization: TextCapitalization.sentences,
                                style: ts_titleMediumBlack,
                                decoration: InputDecoration(
                                  labelText: 'Non-member price',
                                  fillColor: Colors.red,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(),
                                  ),
                                  hintText: '<use default>',
                                  hintStyle: ts_titleMediumBlack,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 20.0, bottom: 0.0, left: 30.0, right: 30.0),
                      child: Text(
                        'If you have extra charges associated with your run, such as for dinner, you can put in the price and description here.',
                        style: ts_mediumBlack,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 10.0, bottom: 10.0, left: 25.0, right: 25.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            flex: 1,
                            child: Container(
                              color: _focusNodeEventPriceForExtras.hasFocus ? Colors.yellow.shade50 : Colors.white,
                              margin: const EdgeInsets.only(right: 12.5),
                              child: TextFormField(
                                // onChanged: (String text) {
                                //   if ((text == null) || (text.isEmpty)) {
                                //     _eventPriceForExtrasController.text = '<none>';
                                //   } else if ((text.length > 6) && (text.contains('<none>'))) {
                                //     _eventPriceForExtrasController.text = _eventPriceForExtrasController.text.replaceAll('<none>', '');
                                //     _eventPriceForExtrasController.selection = TextSelection.fromPosition(TextPosition(offset: _eventPriceForExtrasController.text.length));
                                //   }
                                // },
                                maxLines: 1,
                                focusNode: _focusNodeEventPriceForExtras,
                                controller: _eventPriceForExtrasController,
                                keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: true),
                                textCapitalization: TextCapitalization.sentences,
                                style: ts_titleMediumBlack,
                                decoration: InputDecoration(
                                  labelText: 'Price for extras',
                                  fillColor: Colors.red,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(),
                                  ),
                                  hintText: '<none>',
                                  hintStyle: ts_titleMediumBlack,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              color: _focusNodeExtrasDescription.hasFocus ? Colors.yellow.shade50 : Colors.white,
                              margin: const EdgeInsets.only(left: 12.5),
                              child: TextFormField(
                                // onChanged: (String text) {
                                //   if ((text == null) || (text.isEmpty)) {
                                //     _extrasDescriptionController.text = '<none>';
                                //   } else if ((text.length > 6) && (text.contains('<none>'))) {
                                //     _extrasDescriptionController.text = _extrasDescriptionController.text.replaceAll('<none>', '');
                                //     _extrasDescriptionController.selection = TextSelection.fromPosition(TextPosition(offset: _extrasDescriptionController.text.length));
                                //   }
                                // },
                                maxLines: 1,
                                focusNode: _focusNodeExtrasDescription,
                                controller: _extrasDescriptionController,
                                keyboardType: TextInputType.text,
                                textCapitalization: TextCapitalization.sentences,
                                style: ts_titleMediumBlack,
                                decoration: InputDecoration(
                                  labelText: 'Description',
                                  fillColor: Colors.red,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(),
                                  ),
                                  hintText: '<none>',
                                  hintStyle: ts_titleMediumBlack,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      //color: _focusNodeAbsoluteEventNumber.hasFocus ? Colors.yellow.shade50 : Colors.white,
                      margin: const EdgeInsets.only(top: 10.0, bottom: 10.0, left: 25.0, right: 25.0),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade500),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          )),
                      child: Column(
                        children: <Widget>[
                          CheckboxFormField(
                            title: const Text('Show run in Harrier Central'),
                            validator: (bool? result) {
                              _isVisible = result ?? false;
                              return null;
                            },
                            initialValue: _eventAggregate.event.isVisible == 1,
                          ),
                          CheckboxFormField(
                            title: const Text('Count this run'),
                            initialValue: _eventAggregate.event.isCountedRun == 1,
                            validator: (bool? result) {
                              _isCountedRun = result ?? false;
                              return null;
                            },
                          ),
                          CheckboxFormField(
                            title: const Text('Users can edit run history'),
                            initialValue: _eventAggregate.event.canEditRunAttendence == null ? false : _eventAggregate.event.canEditRunAttendence == 1,
                            tristate: true,
                            validator: (bool? result) {
                              if (result == null) {
                                _usersCanEditRunAttendence = -1;
                              } else {
                                _usersCanEditRunAttendence = result ? 1 : 0;
                              }

                              return null;
                            },
                          ),
                          CheckboxFormField(
                            title: const Text('Promote this run'),
                            initialValue: _eventAggregate.event.isPromotedEvent == 1,
                            validator: (bool? result) {
                              _isPromotedEvent = result ?? false;
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 20.0, bottom: 0.0, left: 30.0, right: 30.0),
                      child: Text(
                        'Let Hashers around the corner or around the world know about your run if it is interesting to them! By telling us the geographic scope of your run it will help us do a better job promoting it for you!',
                        style: ts_mediumBlack,
                      ),
                    ),
                    Container(
                      //color: _focusNodeAbsoluteEventNumber.hasFocus ? Colors.yellow.shade50 : Colors.white,
                      margin: const EdgeInsets.only(top: 10.0, bottom: 10.0, left: 25.0, right: 25.0),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade500),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          )),
                      child: Column(
                        children: <Widget>[
                          ListTile(
                            title: const Text('Local (normal run)'),
                            leading: Radio<int>(
                              value: 1,
                              groupValue: _eventGeographicScope,
                              onChanged: (int? value) {
                                setState(() {
                                  _eventGeographicScope = value ?? 0;
                                });
                              },
                            ),
                          ),
                          ListTile(
                            title: const Text('Local (special event)'),
                            leading: Radio<int>(
                              value: 2,
                              groupValue: _eventGeographicScope,
                              onChanged: (int? value) {
                                setState(() {
                                  _eventGeographicScope = value ?? 0;
                                });
                              },
                            ),
                          ),
                          ListTile(
                            title: const Text('Regional / State'),
                            leading: Radio<int>(
                              value: 3,
                              groupValue: _eventGeographicScope,
                              onChanged: (int? value) {
                                setState(() {
                                  _eventGeographicScope = value ?? 0;
                                });
                              },
                            ),
                          ),
                          ListTile(
                            title: const Text('Nash Hash (national)'),
                            leading: Radio<int>(
                              value: 4,
                              groupValue: _eventGeographicScope,
                              onChanged: (int? value) {
                                setState(() {
                                  _eventGeographicScope = value ?? 0;
                                });
                              },
                            ),
                          ),
                          ListTile(
                            title: const Text('Interhash / Continent'),
                            leading: Radio<int>(
                              value: 5,
                              groupValue: _eventGeographicScope,
                              onChanged: (int? value) {
                                setState(() {
                                  _eventGeographicScope = value ?? 0;
                                });
                              },
                            ),
                          ),
                          ListTile(
                            title: const Text('World Interhash / Global'),
                            leading: Radio<int>(
                              value: 6,
                              groupValue: _eventGeographicScope,
                              onChanged: (int? value) {
                                setState(() {
                                  _eventGeographicScope = value ?? 0;
                                });
                              },
                            ),
                          ),
                          ListTile(
                            title: const Text('Other'),
                            leading: Radio<int>(
                              value: 7,
                              groupValue: _eventGeographicScope,
                              onChanged: (int? value) {
                                setState(() {
                                  _eventGeographicScope = value ?? 0;
                                });
                              },
                            ),
                          ),
                          ListTile(
                            title: const Text('Not specified'),
                            leading: Radio<int>(
                              value: 0,
                              groupValue: _eventGeographicScope,
                              onChanged: (int? value) {
                                setState(() {
                                  _eventGeographicScope = value ?? 0;
                                });
                              },
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
                              ? const SizedBox(
                                  height: 70.0,
                                  width: 70.0,
                                  child: HcCircularProgressIndicator(key: Key('3444910299')),
                                )
                              : SizedBox(
                                  width: 300.0,
                                  child: ElevatedButton(
                                    child: Text(widget.isNewRun ? 'Finish' : 'Save Other Information', style: ts_button),
                                    onPressed: () async {
                                      setState(() {
                                        _isUpdating = true;
                                      });
                                      await _updateRunDetails(false);

                                      if (widget.isNewRun) {
                                        if (!mounted) return;
                                        Navigator.of(navigatorKey.currentContext!).pop();
                                      } else {
                                        final SnackBar snackBar = SnackBar(
                                          duration: const Duration(seconds: 3),
                                          content: Text(
                                            'Other info has been saved',
                                            textAlign: TextAlign.center,
                                            style: ts_titleCondensedBlack,
                                          ),
                                          backgroundColor: Colors.blue.shade700,
                                        );

                                        if (!mounted) return;
                                        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(snackBar);
                                      }
                                      setState(() {
                                        _isUpdating = false;
                                      });
                                    },
                                  ),
                                ),
                          // if ((_eventAggregate.event.eventFacebookId != null) && (!_isUpdating)) ...<Widget>[
                          //   const SizedBox(width: 10.0),
                          //   Container(
                          //     width: 162.0,
                          //     child: ElevatedButton(
                          //       child: Text('Use Facebook', style: buttonLabelStyleMedium),
                          //       onPressed: () {
                          //         setState(() {
                          //           _isUpdating = true;
                          //           _useFacebookDetails();
                          //         });
                          //       },
                          //     ),
                          //   ),
                          // ]
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CheckboxFormField extends FormField<bool> {
  CheckboxFormField({
    super.key,
    required Widget title,
    super.onSaved,
    super.validator,
    bool super.initialValue = false,
    bool tristate = false,
  }) : super(builder: (FormFieldState<bool> state) {
          return CheckboxListTile(
            dense: state.hasError,
            title: title,
            tristate: tristate,
            value: state.value,
            onChanged: state.didChange,
            subtitle: state.hasError
                ? Builder(
                    builder: (BuildContext context) => Text(
                      state.errorText ?? '',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  )
                : null,
            controlAffinity: ListTileControlAffinity.leading,
          );
        });
}
