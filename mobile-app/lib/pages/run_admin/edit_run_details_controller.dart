import 'package:harrier_central/data/models/azure_place_model.dart';
import 'package:harrier_central/imports.dart';
import 'package:harrier_central/pages/run_admin/gazetteer_bottom_sheet.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as latlng;

enum EditingTabEnum {
  details(0, 'Details', 1, 0), // use the kennel default setting
  address(1, 'Address', 2, 0), // use the kennel default setting
  map(2, 'Map', 3, 1), // always notify
  image(3, 'Image', 4, 2), // never notify
  other(4, 'Other', 4, 3); //

  final int value;
  final String label;
  final int next;
  final int previous;

  const EditingTabEnum(this.value, this.label, this.next, this.previous);

  static final Map<int, EditingTabEnum> _valueMap = <int, EditingTabEnum>{
    for (final EditingTabEnum state in EditingTabEnum.values)
      state.value: state,
  };

  static EditingTabEnum? fromInt(int value) => _valueMap[value];
}

/// Owns everything the run editor edits. The page is five tabs over one event,
/// and a save writes all of the form tabs at once, so the values have to live
/// somewhere that outlives the tab a user happens to be looking at —
/// `TabBarView` disposes tabs that are not adjacent to the current one.
class EditRunDetailsController extends GetxController
    with GetSingleTickerProviderStateMixin {
  EditRunDetailsController({
    required this.isNewRun,
    required RunAdminAggregate aggregate,
  }) : eventAggregate = aggregate;

  final bool isNewRun;

  RunAdminAggregate eventAggregate;

  final List<Tab> tabs = <Tab>[];
  late TabController tabController;

  final Rx<EditingTabEnum> currentTab = EditingTabEnum.details.obs;
  final RxBool isUpdating = false.obs;
  final RxBool isDirty = false.obs;

  late latlng.LatLng mapCenter;

  final GlobalKey<FormState> detailsFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> addressFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> otherDetailsFormKey = GlobalKey<FormState>();
  final GlobalKey<EditorMapState> mapKey = GlobalKey<EditorMapState>();

  final FocusNode focusNodeAbsoluteEventNumber = FocusNode();
  final FocusNode focusNodeEventPriceForMembers = FocusNode();
  final FocusNode focusNodeEventPriceForNonMembers = FocusNode();
  final FocusNode focusNodeEventPriceForExtras = FocusNode();
  final FocusNode focusNodeExtrasDescription = FocusNode();
  final FocusNode focusNodeDatetime = FocusNode();
  final FocusNode focusNodeEventName = FocusNode();
  final FocusNode focusNodeStreetAddress = FocusNode();
  final FocusNode focusNodeCity = FocusNode();
  final FocusNode focusNodeRegion = FocusNode();
  final FocusNode focusNodeSubRegion = FocusNode();
  final FocusNode focusNodePostCode = FocusNode();
  final FocusNode focusNodeCountry = FocusNode();
  final FocusNode focusNodeEventDescription = FocusNode();
  final FocusNode focusNodeLocationOneLineDesc = FocusNode();
  final FocusNode focusNodeHares = FocusNode();

  final TextEditingController eventDatetimeController = TextEditingController();
  final TextEditingController eventNameController = TextEditingController();
  final TextEditingController locationStreetController =
      TextEditingController();
  final TextEditingController locationCityController = TextEditingController();
  final TextEditingController locationRegionController =
      TextEditingController();
  final TextEditingController locationSubRegionController =
      TextEditingController();
  final TextEditingController locationPostCodeController =
      TextEditingController();
  final TextEditingController locationCountryController =
      TextEditingController();
  final TextEditingController eventDescriptionController =
      TextEditingController();
  final TextEditingController locationOneLineDescController =
      TextEditingController();
  final TextEditingController absoluteEventNumberController =
      TextEditingController();
  final TextEditingController eventPriceForMembersController =
      TextEditingController();
  final TextEditingController eventPriceForNonMembersController =
      TextEditingController();
  final TextEditingController eventPriceForExtrasController =
      TextEditingController();
  final TextEditingController extrasDescriptionController =
      TextEditingController();
  final TextEditingController haresController = TextEditingController();

  bool isVisible = true;
  bool isCountedRun = true;
  int usersCanEditRunAttendence = 0;
  bool isPromotedEvent = false;
  int eventGeographicScope = 1;
  bool trueNorthLock = true;

  Future<File?> imageFromGallery = Future<File?>.value(null);

  Map<String, String> _savedSnapshot = <String, String>{};

  @override
  void onInit() {
    super.onInit();

    _initTabs();
    tabController = TabController(vsync: this, length: tabs.length);
    tabController.addListener(() {
      // TabController notifies on every frame of the slide, so filter down to
      // the one notification where the tab actually changed.
      final EditingTabEnum next = EditingTabEnum.fromInt(tabController.index)!;
      if (next == currentTab.value) return;
      FocusManager.instance.primaryFocus?.unfocus();
      currentTab.value = next;
      update();
    });

    mapCenter = latlng.LatLng(
      eventAggregate.extensions.latitude ?? eventAggregate.extensions.kenlLat,
      eventAggregate.extensions.longitude ?? eventAggregate.extensions.kenlLon,
    );

    setTextFields();

    // Focus nodes drive the yellow highlight behind the focused field, so a
    // focus change has to repaint the tab.
    for (final FocusNode node in <FocusNode>[
      focusNodeEventName,
      focusNodeEventDescription,
      focusNodeDatetime,
      focusNodeLocationOneLineDesc,
      focusNodeAbsoluteEventNumber,
      focusNodeEventPriceForMembers,
      focusNodeEventPriceForNonMembers,
    ]) {
      node.addListener(update);
    }

    // The extras price and description show and hide parts of the Other tab,
    // so those two repaint as they are typed into. The rest only need to be
    // noticed by the save bar, which is why they recompute dirty and nothing
    // more — a keystroke must not rebuild five tabs and a map.
    eventPriceForExtrasController.addListener(update);
    extrasDescriptionController.addListener(update);

    for (final TextEditingController controller in <TextEditingController>[
      eventNameController,
      eventDatetimeController,
      eventDescriptionController,
      locationOneLineDescController,
      locationStreetController,
      locationCityController,
      locationRegionController,
      locationSubRegionController,
      locationPostCodeController,
      locationCountryController,
      absoluteEventNumberController,
      eventPriceForMembersController,
      eventPriceForNonMembersController,
      eventPriceForExtrasController,
      extrasDescriptionController,
      haresController,
    ]) {
      controller.addListener(recomputeDirty);
    }

    captureSavedSnapshot();
  }

  @override
  void onClose() {
    eventDatetimeController.dispose();
    eventNameController.dispose();
    locationStreetController.dispose();
    locationCityController.dispose();
    locationRegionController.dispose();
    locationSubRegionController.dispose();
    locationPostCodeController.dispose();
    locationCountryController.dispose();
    eventDescriptionController.dispose();
    locationOneLineDescController.dispose();
    absoluteEventNumberController.dispose();
    eventPriceForMembersController.dispose();
    eventPriceForNonMembersController.dispose();
    eventPriceForExtrasController.dispose();
    extrasDescriptionController.dispose();
    haresController.dispose();

    focusNodeDatetime.dispose();
    focusNodeEventName.dispose();
    focusNodeStreetAddress.dispose();
    focusNodeCity.dispose();
    focusNodeRegion.dispose();
    focusNodeSubRegion.dispose();
    focusNodePostCode.dispose();
    focusNodeCountry.dispose();
    focusNodeEventDescription.dispose();
    focusNodeLocationOneLineDesc.dispose();
    focusNodeAbsoluteEventNumber.dispose();
    focusNodeEventPriceForMembers.dispose();
    focusNodeEventPriceForNonMembers.dispose();
    focusNodeEventPriceForExtras.dispose();
    focusNodeExtrasDescription.dispose();
    focusNodeHares.dispose();

    tabController.dispose();
    super.onClose();
  }

  void _initTabs() {
    if (tabs.isEmpty) {
      tabs.add(const Tab(text: 'Details'));
      tabs.add(const Tab(text: 'Address'));
      tabs.add(const Tab(text: 'Map'));
      tabs.add(const Tab(text: 'Image'));
      tabs.add(const Tab(text: 'Other'));
    }
  }

  /// Applies a change and repaints the page. Stands in for the `setState` the
  /// page used before it had a controller, so a callback that mutates several
  /// fields at once still results in exactly one rebuild.
  void mutate(VoidCallback change) {
    // A save or an upload can outlive the page — the user is free to back out
    // while the request is in flight. Nothing after that point has anywhere to
    // paint, and update() on a disposed controller trips an assert in debug.
    if (isClosed) return;
    change();
    recomputeDirty();
    update();
  }

  void setTextFields() {
    eventNameController.text = eventAggregate.event.eventName;
    locationStreetController.text = eventAggregate.event.locationStreet ?? '';
    locationCityController.text = eventAggregate.event.locationCity ?? '';
    locationRegionController.text = eventAggregate.event.locationRegion ?? '';
    locationSubRegionController.text =
        eventAggregate.event.locationSubRegion ?? '';
    locationPostCodeController.text =
        eventAggregate.event.locationPostCode ?? '';
    locationCountryController.text = eventAggregate.event.locationCountry ?? '';
    eventDescriptionController.text =
        eventAggregate.event.eventDescription ?? '';
    eventDatetimeController.text = DateFormat(
      'E, d MMM, yyyy, h:mm a',
    ).format(eventAggregate.event.eventStartDatetime);
    locationOneLineDescController.text =
        eventAggregate.event.locationOneLineDesc ?? '';
    haresController.text = eventAggregate.event.hares ?? '';

    absoluteEventNumberController.text =
        eventAggregate.event.absoluteEventNumber?.toString() ?? '';
    eventPriceForMembersController.text =
        eventAggregate.event.eventPriceForMembers?.toStringAsFixed(
          eventAggregate.extensions.digAfterDec,
        ) ??
        '';
    eventPriceForNonMembersController.text =
        eventAggregate.event.eventPriceForNonMembers?.toStringAsFixed(
          eventAggregate.extensions.digAfterDec,
        ) ??
        '';
    eventPriceForExtrasController.text =
        eventAggregate.event.eventPriceForExtras?.toStringAsFixed(
          eventAggregate.extensions.digAfterDec,
        ) ??
        '';
    extrasDescriptionController.text =
        eventAggregate.event.extrasDescription ?? '';
    eventGeographicScope = eventAggregate.event.eventGeographicScope;

    // The four checkbox-backed fields are also assigned by their
    // CheckboxFormField validators, but those only run when the Other tab is
    // built. Seed them from the event so a save made from any tab sends the
    // event's real values rather than the field declaration defaults.
    isVisible = eventAggregate.event.isVisible == 1;
    isCountedRun = eventAggregate.event.isCountedRun == 1;
    isPromotedEvent = eventAggregate.event.isPromotedEvent == 1;
    // -1 means "explicitly clear" to the SP, which is how an unset value has to
    // round-trip — sending 0 would turn "inherit" into an explicit "no".
    usersCanEditRunAttendence =
        switch (eventAggregate.event.canEditRunAttendence) {
          null => -1,
          1 => 1,
          _ => 0,
        };
  }

  /// Every editable value across the Details, Address and Other tabs, flattened
  /// so the save bar can tell whether anything has changed since it was last
  /// loaded or saved.
  Map<String, String> _formSnapshot() => <String, String>{
    'eventName': eventNameController.text,
    'eventDatetime': eventDatetimeController.text,
    'eventDescription': eventDescriptionController.text,
    'locationOneLineDesc': locationOneLineDescController.text,
    'locationStreet': locationStreetController.text,
    'locationCity': locationCityController.text,
    'locationRegion': locationRegionController.text,
    'locationSubRegion': locationSubRegionController.text,
    'locationPostCode': locationPostCodeController.text,
    'locationCountry': locationCountryController.text,
    'absoluteEventNumber': absoluteEventNumberController.text,
    'eventPriceForMembers': eventPriceForMembersController.text,
    'eventPriceForNonMembers': eventPriceForNonMembersController.text,
    'eventPriceForExtras': eventPriceForExtrasController.text,
    'extrasDescription': extrasDescriptionController.text,
    'hares': haresController.text,
    'isVisible': '$isVisible',
    'isCountedRun': '$isCountedRun',
    'isPromotedEvent': '$isPromotedEvent',
    'usersCanEditRunAttendence': '$usersCanEditRunAttendence',
    'eventGeographicScope': '$eventGeographicScope',
  };

  void recomputeDirty() {
    final Map<String, String> current = _formSnapshot();
    for (final MapEntry<String, String> entry in current.entries) {
      if (_savedSnapshot[entry.key] != entry.value) {
        isDirty.value = true;
        return;
      }
    }
    isDirty.value = false;
  }

  void captureSavedSnapshot() {
    _savedSnapshot = _formSnapshot();
    isDirty.value = false;
  }

  static const List<String> _addressKeys = <String>[
    'locationStreet',
    'locationCity',
    'locationRegion',
    'locationSubRegion',
    'locationPostCode',
    'locationCountry',
  ];

  bool get addressChanged {
    final Map<String, String> current = _formSnapshot();
    return _addressKeys.any(
      (String key) => _savedSnapshot[key] != current[key],
    );
  }

  /// Validates the Details tab. The Address and Other tabs carry no validators,
  /// and the Details form may not be mounted (TabBarView disposes tabs that are
  /// not adjacent to the current one), so the same three "must not be empty"
  /// rules are repeated here in plain Dart.
  String? _validateForSave() {
    if (eventNameController.text.isEmpty) {
      return 'Please provide an event name';
    }
    if (eventDescriptionController.text.isEmpty) {
      return 'Please provide an event description';
    }
    if (locationOneLineDescController.text.isEmpty) {
      return 'Please provide a location description';
    }
    return null;
  }

  /// Single save for everything on the Details, Address and Other tabs. The Map
  /// and Image tabs keep their own buttons — they act on a picked point or an
  /// uploaded file rather than on form content.
  Future<bool> saveAll() async {
    final String? validationError = _validateForSave();
    if (validationError != null) {
      if (currentTab.value != EditingTabEnum.details) {
        tabController.animateTo(EditingTabEnum.details.value);
      }
      // Run the form's own validation too so the offending field shows its
      // error inline, once the tab it lives on has been built.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        detailsFormKey.currentState?.validate();
      });
      await Utilities.showAlert('Cannot save yet', validationError, 'OK');
      return false;
    }

    // Pulls the current checkbox values back into the state fields when the
    // Other tab happens to be built.
    otherDetailsFormKey.currentState?.validate();

    FocusManager.instance.primaryFocus?.unfocus();
    mutate(() {
      isUpdating.value = true;
    });

    final DateFormat formatter = DateFormat('E, d MMM, yyyy, h:mm a');
    final EventsService nSvc = EventsService();
    final String eventId = await nSvc.addEditEvent(
      eventId: eventAggregate.event.eventId,
      kennelId: eventAggregate.event.kennelId,
      eventName: eventNameController.text,
      eventStartDatetime: formatter.tryParse(eventDatetimeController.text),
      eventDescription: eventDescriptionController.text,
      locationOneLineDesc: locationOneLineDescController.text,
      useFbRunDetails: 0,
      locationStreet: locationStreetController.text,
      locationCity: locationCityController.text,
      locationRegion: locationRegionController.text,
      locationSubRegion: locationSubRegionController.text,
      locationPostCode: locationPostCodeController.text,
      locationCountry: locationCountryController.text,
      eventPriceForMembers: eventPriceForMembersController.text.isEmpty
          ? -2
          : double.tryParse(
              eventPriceForMembersController.text.replaceAll(',', '.'),
            ),
      eventPriceForNonMembers: eventPriceForNonMembersController.text.isEmpty
          ? -2
          : double.tryParse(
              eventPriceForNonMembersController.text.replaceAll(',', '.'),
            ),
      eventPriceForExtras: eventPriceForExtrasController.text.isEmpty
          ? -2
          : double.tryParse(
              eventPriceForExtrasController.text.replaceAll(',', '.'),
            ),
      // note for "auto" the value we send to the server is '0' because this will
      // remove any previous absoluteEventNumber that is stored there
      absoluteEventNumber: absoluteEventNumberController.text.isEmpty
          ? 0
          : int.tryParse(absoluteEventNumberController.text),
      extrasDescription: extrasDescriptionController.text.isEmpty
          ? '<none>'
          : extrasDescriptionController.text,
      hares: haresController.text,
      isCountedRun: isCountedRun,
      isVisible: isVisible,
      isPromotedEvent: isPromotedEvent,
      eventGeographicScope: eventGeographicScope,
      usersCanEditRunAttendence: usersCanEditRunAttendence,
    );

    await refreshAfterSave(eventId);
    mutate(() {
      isUpdating.value = false;
      captureSavedSnapshot();
    });
    return true;
  }

  Future<void> onSaveBarPressed() async {
    final bool didAddressChange = addressChanged;
    final bool saved = await saveAll();
    if (!saved) return;

    if (isNewRun) {
      if (currentTab.value == EditingTabEnum.other) {
        Navigator.of(navigatorKey.currentContext!).pop();
        return;
      }
      tabController.animateTo(currentTab.value.next);
      return;
    }

    final SnackBar snackBar = SnackBar(
      duration: const Duration(seconds: 3),
      content: Text(
        'Run details have been saved',
        textAlign: TextAlign.center,
        style: ts_titleCondensed,
      ),
      backgroundColor: hc_blue,
    );
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(snackBar);

    if (didAddressChange) {
      await _offerAutoLocateAfterAddressChange();
    }
  }

  /// A new address usually means the map pin is now wrong, so offer to move it.
  /// Only runs when the address actually changed in the save that just ran.
  Future<void> _offerAutoLocateAfterAddressChange() async {
    final bool hasEnoughAddress =
        locationPostCodeController.text.trim().isNotEmpty ||
        (locationStreetController.text.trim().isNotEmpty &&
            locationCityController.text.trim().isNotEmpty);

    if (hasEnoughAddress) {
      final bool? locate = await showDialog<bool>(
        context: navigatorKey.currentContext!,
        builder: (BuildContext ctx) => AlertDialog(
          title: const Text('Address saved'),
          content: const Text(
            'Would you like me to try to automatically find the map pin for the new address?',
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Not now'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: hc_blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Auto-locate'),
            ),
          ],
        ),
      );
      if (locate == true) {
        await geocodeAndNavigateToMap();
      }
      return;
    }

    await showDialog<void>(
      context: navigatorKey.currentContext!,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Pin location needed'),
        content: const Text(
          "The address isn't specific enough for automatic location — you'll need to set the pin manually on the Map tab.",
        ),
        actions: <Widget>[
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: hc_blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              tabController.animateTo(EditingTabEnum.map.value);
            },
            child: const Text('Go to Map'),
          ),
        ],
      ),
    );
  }

  /// Asked on the way out of the page, which is the only point where unsaved
  /// form content can actually be lost — moving between tabs keeps everything.
  Future<bool> confirmDiscardOnExit() async {
    if (!isDirty.value) return true;

    final bool? save = await Utilities.showAlert2(
      'Unsaved changes',
      'You have changes to this run that have not been saved. Save them now?',
      'Save',
      showCancelButton: true,
      cancelButtonText: 'Discard',
    );

    if (save == null) return false; // dismissed — stay on the page
    if (!save) return true; // discard and leave
    return saveAll();
  }

  Future<void> useExternalSourceDetails() async {
    mutate(() {
      isUpdating.value = true;
    });
    final EventsService nSvc = EventsService();
    final String eventId = await nSvc.addEditEvent(
      eventId: eventAggregate.event.eventId,
      kennelId: eventAggregate.event.kennelId,
      useFbRunDetails: 1,
    );

    await refreshAfterSave(eventId);
    mutate(() {
      isUpdating.value = false;
      setTextFields();
      // The fields now hold what the server holds, so the bar goes back to
      // disabled rather than showing the reload as a pending change.
      captureSavedSnapshot();
      final SnackBar snackBar = SnackBar(
        duration: const Duration(seconds: 3),
        content: Text(
          eventAggregate.event.eventInboundIntegrationId >=
                  integrationPlatformNames.length
              ? 'Run details being synced from external source'
              : 'Run details being synced from ${integrationPlatformNames[eventAggregate.event.eventInboundIntegrationId]}',
          textAlign: TextAlign.center,
          style: ts_titleCondensedBlack,
        ),
        backgroundColor: hc_blue,
      );
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(snackBar);
    });
  }

  Future<void> refreshAfterSave(String eventId) async {
    final String userId = getStringPref(StringPrefsEnum.userId) ?? '';
    final RunAdminAggregate? updated =
        await CommonQueries.getEventAdminInfoFromLocalCache(eventId, userId);
    if (updated != null) {
      eventAggregate = updated;
    }
    Get.find<DataChangeService>().notify(
      DataChangeEvent(type: DataChangeType.runUpdated, id: eventId),
    );
  }

  Future<void> openLocationLookup() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final String query = locationOneLineDescController.text.trim();

    await showModalBottomSheet<void>(
      context: navigatorKey.currentContext!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GazetteerBottomSheet(
        initialQuery: query,
        kennelLat: eventAggregate.extensions.kenlLat,
        kennelLon: eventAggregate.extensions.kenlLon,
        onResultSelected: applyGazetteerResult,
      ),
    );
  }

  void applyGazetteerResult(AzurePlaceResult result) {
    final AzurePlaceAddress? addr = result.address;
    mutate(() {
      locationStreetController.text =
          addr?.streetNameAndNumber ?? addr?.streetName ?? '';
      locationCityController.text = addr?.municipality ?? addr?.localName ?? '';
      locationRegionController.text = addr?.countrySubdivision ?? '';
      locationSubRegionController.text = '';
      locationPostCodeController.text = addr?.postalCode ?? '';
      locationCountryController.text = addr?.country ?? '';
      if (result.position?.lat != null && result.position?.lon != null) {
        mapCenter = latlng.LatLng(result.position!.lat!, result.position!.lon!);
      }
    });
    tabController.animateTo(EditingTabEnum.address.value);
  }

  Future<void> geocodeAndNavigateToMap() async {
    String country = locationCountryController.text.trim();
    if (country.isEmpty) {
      final List<Map<String, dynamic>> rows = await database.rawQuery(
        'SELECT ${tableModel.countriesTableHelper.colCountryName} '
        'FROM ${EnumDataTables.countries.commonTableName} '
        'WHERE ${tableModel.countriesTableHelper.colCountryId} = ? LIMIT 1',
        <String>[eventAggregate.kennel.countryId],
      );
      if (rows.isNotEmpty) {
        country =
            (rows[0][tableModel.countriesTableHelper.colCountryName]
                as String?) ??
            '';
      }
    }

    final List<String> parts = <String>[
      locationStreetController.text.trim(),
      locationCityController.text.trim(),
      locationRegionController.text.trim(),
      locationPostCodeController.text.trim(),
      country,
    ].where((String s) => s.isNotEmpty).toList();

    if (parts.isEmpty) return;

    mutate(() {
      isUpdating.value = true;
    });

    final Uri uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      <String, String>{'q': parts.join(', '), 'format': 'json', 'limit': '1'},
    );

    try {
      final Response response = await get(
        uri,
        headers: <String, String>{
          'User-Agent': 'HarrierCentral/2.5 (harrier-central-app)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> results =
            jsonDecode(response.body) as List<dynamic>;
        if (results.isNotEmpty) {
          final double? lat = double.tryParse(
            (results[0]['lat'] as String?) ?? '',
          );
          final double? lon = double.tryParse(
            (results[0]['lon'] as String?) ?? '',
          );
          if (lat != null && lon != null) {
            mutate(() {
              mapCenter = latlng.LatLng(lat, lon);
              isUpdating.value = false;
            });
            tabController.animateTo(EditingTabEnum.map.value);
            return;
          }
        }
      }
    } catch (_) {}

    mutate(() {
      isUpdating.value = false;
    });

    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Text(
          "Couldn't locate that address — set the pin manually on the Map tab",
          textAlign: TextAlign.center,
          style: ts_titleCondensed,
        ),
        backgroundColor: Colors.orange.shade700,
      ),
    );
  }

  Future<String> upload(File imageFile, String eventId) async {
    final String datetime = DateFormat('yyyyMMddkkmmss').format(DateTime.now());
    final String fileName = 'eventImage_${eventId}_$datetime.jpg';
    final Uri uri = Uri.parse(
      'https://harriercentral.blob.core.windows.net/event-images/$fileName?sv=2020-04-08&st=2021-09-15T14%3A03%3A04Z&se=2100-09-16T14%3A03%3A00Z&sr=c&sp=racwdxlt&sig=q%2BVTH8wcrKOlSZK1FH7cUoaoYFPtjGpblCAVUqA4WFY%3D',
    );

    final Request request = Request('PUT', uri);

    final Map<String, String> headers = <String, String>{
      'content-type': 'image/jpeg',
      'x-ms-blob-type': 'BlockBlob',
    };

    request.headers.addAll(headers);

    request.bodyBytes = imageFile.readAsBytesSync();

    await request.send();

    return fileName;
  }

  Future<void> getImageFromGallery(ImageSource source) async {
    if ((eventAggregate.event.eventId.isEmpty) ||
        (eventAggregate.event.eventId == GUID_EMPTY)) {
      await Utilities.showAlert(
        'Please save Details first',
        'Please fill in the run name and other information on the Details tab and save those details before saving other information on this tab.',
        'OK',
      );

      tabController.animateTo(EditingTabEnum.details.index);
    } else {
      final XFile? image = await ImagePicker().pickImage(source: source);

      if (image != null) {
        final ImageCropper ic = ImageCropper();
        final CroppedFile? croppedFile = await ic.cropImage(
          sourcePath: image.path,
          maxWidth: 1000,
          maxHeight: 1000,
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 50,
        );

        mutate(() {
          if (croppedFile != null) {
            imageFromGallery = Future<File>.value(File(croppedFile.path));
          }
        });
      }
    }
  }
}
