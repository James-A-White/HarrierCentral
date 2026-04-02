/// Run Edit Page Controller
///
/// This controller manages the state and business logic for the run editing form.
/// It extends [TabUiController] to leverage tabbed UI functionality and validation.
///
/// Key responsibilities:
/// - Managing form state (edited vs original data)
/// - Auto-save functionality
/// - Form validation and dirty state tracking
/// - Tab state management
/// - API communication for saving changes

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hcportal/imports.dart';
import 'package:hcportal/admin_pages/kennel_page_new/kennel_page_new_enums.dart';
import 'package:hcportal/admin_pages/run_list_page_controller.dart';
import 'package:hcportal/models/azure_geo_model.dart';
import 'package:http/http.dart' as http;
import 'package:latlng/latlng.dart';
import 'package:map/map.dart' as geo_map;
import 'widgets/run_location_lookup_dialog.dart';

part 'pages/run_basic_info_page/controls.dart';
part 'pages/run_location_page/controls.dart';
part 'pages/run_image_page/controls.dart';
part 'pages/run_misc_page/controls.dart';
part 'pages/run_tags_page/controls.dart';
part 'pages/run_other_page/controls.dart';
part 'pages/run_payment_page/controls.dart';

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

/// Controller for the run editing form.
///
/// This controller manages:
/// - Form data state (original and edited versions)
/// - Auto-save timer and state
/// - Tab navigation and validation
/// - Text editing controllers for form fields
class RunEditPageController extends TabUiController
    with GetSingleTickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------

  RunEditPageController({
    required this.initialData,
    required this.kennelData,
    required this.isAddMode,
    this.lastRunDate,
  }) {
    originalData = initialData;
    setScreenSize();
  }

  /// Initial run data passed to the controller.
  final RunDetailsModel initialData;

  /// Kennel data for context.
  final HasherKennelsModel kennelData;

  /// Whether we are adding a new run (vs editing existing).
  /// This is set to `false` after the first successful save in add mode.
  bool isAddMode;

  /// The date of the last existing run, used to calculate the next run date.
  final DateTime? lastRunDate;

  // ---------------------------------------------------------------------------
  // State - Core Data
  // ---------------------------------------------------------------------------

  /// The original run data (used for comparison and undo).
  late RunDetailsModel originalData;

  /// The currently edited run data (reactive).
  final Rx<RunDetailsModel> editedData =
      Rx<RunDetailsModel>(RunDetailsModel.empty());

  // ---------------------------------------------------------------------------
  // State - UI Controllers
  // ---------------------------------------------------------------------------

  /// Text editing controllers mapped by field key.
  final Map<String, TextEditingController> textControllers = {};

  /// Form state key for validation.
  final GlobalKey<FormState> formKey = GlobalKey<FormState>(
    debugLabel: 'runFormKey_${DateTime.now().millisecondsSinceEpoch}',
  );

  /// Scroll controller for the all-fields tab.
  final ScrollController scrollController = ScrollController();

  /// Whether the location lookup dialog is currently loading.
  final RxBool isLookupLoading = false.obs;

  /// Tracks upload state for file fields.
  final Map<String, RxBool> uploadingState = {};

  /// Tracks detailed upload status for file fields ('selecting', 'uploading', or '').
  final Map<String, RxString> uploadStatusState = {};

  // ---------------------------------------------------------------------------
  // State - Auto-save
  // ---------------------------------------------------------------------------

  /// Whether auto-save is enabled.
  final RxBool doAutoSave = false.obs;

  /// Current auto-save countdown (seconds since last save, -1 = saving).
  final RxInt autoSaveCounter = 0.obs;

  /// Timer for auto-save interval.
  Timer? _autoSaveTimer;

  // ---------------------------------------------------------------------------
  // State - Integration Flags
  // ---------------------------------------------------------------------------

  /// Whether to use external data for basic info.
  final RxBool useExtRunDetails = false.obs;

  /// Whether to use external data for location.
  final RxBool useExtLocation = false.obs;

  /// Whether to use external data for lat/lon.
  final RxBool useExtLatLon = false.obs;

  /// Whether to use external image.
  final RxBool useExtImage = false.obs;

  /// Inbound integration ID (0 = no external source).
  final RxInt inboundIntegrationId = 0.obs;

  // ---------------------------------------------------------------------------
  // State - Form Options
  // ---------------------------------------------------------------------------

  /// Whether to auto-number runs.
  final RxBool autoNumberRuns = true.obs;

  /// Whether to use custom pricing.
  final RxBool useCustomPricing = false.obs;

  /// Whether to use extras pricing.
  final RxBool useExtrasPricing = false.obs;

  /// Whether to limit participation.
  final RxBool limitParticipation = false.obs;

  // ---------------------------------------------------------------------------
  // State - Publishing Options
  // ---------------------------------------------------------------------------

  /// Web publishing setting (evtDisseminateHashRunsDotOrg). -2 = Use Kennel Setting.
  final RxInt publishOnHashruns = (-2).obs;

  /// Run audience setting (evtDisseminationAudience). -2 = Use Kennel Setting.
  final RxInt runAudience = (-2).obs;

  /// Allow web link sharing (evtDisseminateAllowWebLinks). 2 = Use Kennel Setting.
  final RxInt allowWebLink = 2.obs;

  /// Can edit run attendance (canEditRunAttendence). -2 = Use Kennel Setting.
  final RxInt runAttendance = (-2).obs;

  // ---------------------------------------------------------------------------
  // State - Tags
  // ---------------------------------------------------------------------------

  /// Tag selection status (tags1, tags2, tags3 bit flags).
  final RxInt tags1 = 0.obs;
  final RxInt tags2 = 0.obs;
  final RxInt tags3 = 0.obs;

  /// Map of run tag keys to their selection status (0 = unselected, 1 = selected).
  final Map<String, RxInt> runTagSelectionStatus = {};

  /// Count of currently selected run tags.
  final RxInt selectedRunTagCount = 0.obs;

  // ---------------------------------------------------------------------------
  // State - Country Selection
  // ---------------------------------------------------------------------------

  /// Selected country name.
  final RxnString country = RxnString();

  /// Selected country ID.
  final RxnString countryId = RxnString();

  // ---------------------------------------------------------------------------
  // State - Image Upload
  // ---------------------------------------------------------------------------

  /// Uploaded image URL.
  final RxnString uploadedImage = RxnString();

  /// Whether an image is currently being uploaded.
  final RxBool uploadingPhoto = false.obs;

  // ---------------------------------------------------------------------------
  // State - Location / Map
  // ---------------------------------------------------------------------------

  /// Map controller for the location map (reactive for Obx).
  final Rxn<geo_map.MapController> mapController = Rxn<geo_map.MapController>();

  /// Trigger counter to force map rebuild when center changes programmatically.
  final RxInt mapRebuildTrigger = 0.obs;

  /// Drag start position for map panning.
  Offset dragStart = Offset.zero;

  /// Scale start value for pinch-to-zoom.
  double scaleStart = 1.0;

  /// Whether a geocoding operation is in progress.
  final RxBool isGeocoding = false.obs;

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  /// Debounce worker for screen size changes.
  Worker? _screenSizeDebouncer;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();

    _initializeTabs();
    _initializeAutoSave();
    _initializeTabStates();
    _initializeFormData();
    _initializeScreenSizeListener();
    _scheduleInitialValidation();
  }

  @override
  void onClose() {
    _screenSizeDebouncer?.dispose();
    _autoSaveTimer?.cancel();
    _disposeTextControllers();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Initialization Helpers
  // ---------------------------------------------------------------------------

  /// Initializes tab controller and tab definitions.
  void _initializeTabs() {
    initTabs(
      vsync: this,
      tabs: _buildTabDefinitions(),
      tabKeyBuilder: (index) => RunTabType.values[index].key,
      onTabIndexChanging: checkUiControlValidationStates,
      tabIndexChangingUpdateIds: const ['tabIcons', 'submissionTab'],
    );
  }

  /// Builds tab definitions from the enum.
  List<TabDefinitionData> _buildTabDefinitions() {
    return RunTabType.values.map((tab) {
      return TabDefinitionData(
        key: tab.key,
        title: tab.title,
        tabIndex: tab.index,
        hasCustomTabStatusFunction: false,
        showTabInSubmitSummary: true,
        isTabLockable: false,
        sidebarData: SideBarData(
          tab.title,
          tab.icon,
          tab.description,
        ),
      );
    }).toList();
  }

  /// Sets up the auto-save listener.
  void _initializeAutoSave() {
    ever(doAutoSave, _handleAutoSaveToggle);
  }

  /// Handles auto-save toggle changes.
  void _handleAutoSaveToggle(bool enabled) {
    if (enabled) {
      _startAutoSaveTimer();
    } else {
      _autoSaveTimer?.cancel();
      autoSaveCounter.value = 0;
    }
  }

  /// Starts the auto-save timer.
  void _startAutoSaveTimer() {
    autoSaveCounter.value = 0;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (autoSaveCounter.value >= AUTOSAVE_PERIOD_IN_SECONDS) {
        if (isFormDirty.value) {
          await save(false);
        }
        autoSaveCounter.value = 0;
      } else {
        autoSaveCounter.value++;
      }
    });
  }

  /// Initializes tab state bundle (status, locks, validation).
  void _initializeTabStates() {
    initTabStateBundle(
      length: RunTabType.values.length,
      initiallyEmptyIndex: 0,
      initialLockState: TabLocked.tabUnlocked,
    );
  }

  /// Initializes form data and UI controls.
  void _initializeFormData() {
    editedData.value = originalData.copyWith();

    // In add mode, derive the default start datetime from the kennel's
    // defaultRunStartTime which encodes the day-of-week (in the milliseconds
    // field, value / 100) and the hour/minute of the run.
    if (isAddMode) {
      var defaultStartDayOfWeek =
          kennelData.defaultRunStartTime.millisecond ~/ 100;

      if (defaultStartDayOfWeek < 1 || defaultStartDayOfWeek > 7) {
        defaultStartDayOfWeek = 1;
      }

      // Advance from the last run date (or today) until we land on the
      // correct day of the week
      var dt = lastRunDate ?? DateTime.now();
      while (true) {
        dt = dt.add(const Duration(days: 1));
        if (dt.weekday == defaultStartDayOfWeek) {
          break;
        }
      }

      // Combine the found date with the kennel's default hour and minute
      final defaultStart = DateTime(
        dt.year,
        dt.month,
        dt.day,
        kennelData.defaultRunStartTime.hour,
        kennelData.defaultRunStartTime.minute,
      );

      editedData.value =
          editedData.value.copyWith(eventStartDatetime: defaultStart);
      originalData = originalData.copyWith(eventStartDatetime: defaultStart);
    }

    // Initialize integration flags
    if (originalData.inboundIntegrationId != 0) {
      useExtLatLon.value = originalData.useFbLatLon != 0;
      useExtRunDetails.value = originalData.useFbRunDetails != 0;
      useExtImage.value = originalData.useFbImage != 0;
      useExtLocation.value = originalData.useFbLocation != 0;
    }
    inboundIntegrationId.value = originalData.inboundIntegrationId ?? 0;

    // Initialize form options
    autoNumberRuns.value = originalData.absoluteEventNumber == null;
    useCustomPricing.value = (originalData.eventPriceForMembers != null) ||
        (originalData.eventPriceForNonMembers != null);
    useExtrasPricing.value = originalData.eventPriceForExtras != null;
    limitParticipation.value =
        (originalData.maximumParticipantsAllowed != null) ||
            (originalData.minimumParticipantsRequired != null);

    // Initialize tags — seed from kennel defaults when adding a new run
    if (isAddMode) {
      tags1.value = kennelData.defaultTags1;
      tags2.value = kennelData.defaultTags2;
      tags3.value = kennelData.defaultTags3;
      editedData.value = editedData.value.copyWith(
        tags1: kennelData.defaultTags1,
        tags2: kennelData.defaultTags2,
        tags3: kennelData.defaultTags3,
      );
      originalData = originalData.copyWith(
        tags1: kennelData.defaultTags1,
        tags2: kennelData.defaultTags2,
        tags3: kennelData.defaultTags3,
      );
    } else {
      tags1.value = originalData.tags1;
      tags2.value = originalData.tags2;
      tags3.value = originalData.tags3;
    }

    // Initialize run tags from bit flags (for the new chip-based UI)
    initializeRunTagsFromBitFlags();

    // Initialize country
    country.value = originalData.countryName;
    countryId.value = originalData.countryId;

    // Initialize map controller for location tab
    initializeMapController();

    // Initialize UI controls for each tab
    initBasicInfoControls();
    initLocationControls();
    initImageControls();
    initMiscControls();
    initRunTagsControls();
    initOtherControls();
    initPaymentControls();

    populateTextControllers();
  }

  /// Sets up the screen size change listener.
  void _initializeScreenSizeListener() {
    _screenSizeDebouncer = debounce(
      width,
      (_) => setScreenSize(),
      time: const Duration(milliseconds: 50),
    );
  }

  /// Schedules initial validation after build completes.
  void _scheduleInitialValidation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkIfFormIsDirty();
      refreshTabStatuses();
    });
  }

  /// Disposes all text controllers.
  void _disposeTextControllers() {
    for (final controller in textControllers.values) {
      controller.dispose();
    }
    textControllers.clear();
  }

  // ---------------------------------------------------------------------------
  // Public Methods
  // ---------------------------------------------------------------------------

  /// Toggles auto-save on/off.
  void toggleAutoSave() {
    doAutoSave.toggle();
  }

  /// Saves the current form state.
  @override
  Future<void> save(bool showDialog) async {
    if (!isFormDirty.value) return;

    autoSaveCounter.value = -1; // Show "Saving..."

    try {
      final changes = _buildChanges();

      if (changes.isEmpty) {
        if (showDialog) {
          await IveCoreUtilities.showAlert(
            navigatorKey.currentContext!,
            'No changes',
            'No changes were made so nothing was saved.',
            'OK',
          );
        }
        autoSaveCounter.value = 0;
        return;
      }

      final deviceId = box.get(HIVE_DEVICE_ID) as String;
      final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
      final publicKennelId = normalizeUuid(
        originalData.publicKennelId.isNotEmpty
            ? originalData.publicKennelId
            : kennelData.publicKennelId,
      );
      final accessToken = Utilities.generateToken(
        deviceId,
        'hcportal_addEditEvent',
        paramString: deviceSecret,
      );

      final bodyJson = <String, dynamic>{
        'queryType': 'addEditEvent',
        'deviceId': deviceId,
        'accessToken': accessToken,
        'publicKennelId': publicKennelId,
      };

      if (!isAddMode &&
          originalData.publicEventId != null &&
          originalData.publicEventId!.length > 10) {
        bodyJson['publicEventId'] = normalizeUuid(originalData.publicEventId);
      }

      bodyJson.addAll(changes);

      final jsonResult =
          await ServiceCommon.sendHttpPostToHC6Api(bodyJson);
      debugPrint(jsonResult.startsWith(ERROR_PREFIX)
          ? 'SP 1 [addEditEvent] called — FAILED'
          : 'SP 1 [addEditEvent] called — success');
      final updateResult = ((jsonDecode(jsonResult) as List<dynamic>)[0]
          as List<dynamic>)[0] as Map<String, dynamic>;

      final resultForDisplay = updateResult['result'] as String?;

      // If we just created a new event, capture the returned EventId
      // and switch from add mode to edit mode so subsequent saves
      // update the existing event instead of creating a duplicate.
      if (isAddMode) {
        final returnedEventId = updateResult['publicEventId'] as String?;
        if (returnedEventId != null && returnedEventId.length > 10) {
          editedData.value = editedData.value.copyWith(
            publicEventId: returnedEventId,
          );
          isAddMode = false;
        }
      }

      // Update original data to reflect saved state
      originalData = editedData.value.copyWith();
      isFormDirty.value = false;

      if (showDialog) {
        await IveCoreUtilities.showAlert(
          navigatorKey.currentContext!,
          'Success',
          resultForDisplay ?? 'Changes were saved.',
          'Done',
        );
      }
    } catch (e) {
      if (showDialog) {
        await IveCoreUtilities.showAlert(
          navigatorKey.currentContext!,
          'Error',
          'Failed to save changes: $e',
          'OK',
        );
      }
    } finally {
      autoSaveCounter.value = 0;
    }
  }

  /// Undoes all changes since the last save.
  @override
  void undoChanges() {
    // Reset integration flags
    if (originalData.inboundIntegrationId != 0) {
      useExtLatLon.value = originalData.useFbLatLon != 0;
      useExtRunDetails.value = originalData.useFbRunDetails != 0;
      useExtImage.value = originalData.useFbImage != 0;
      useExtLocation.value = originalData.useFbLocation != 0;
    }

    // Reset form options
    autoNumberRuns.value = originalData.absoluteEventNumber == null;
    useCustomPricing.value = (originalData.eventPriceForMembers != null) ||
        (originalData.eventPriceForNonMembers != null);
    useExtrasPricing.value = originalData.eventPriceForExtras != null;
    limitParticipation.value =
        (originalData.maximumParticipantsAllowed != null) ||
            (originalData.minimumParticipantsRequired != null);

    // Reset publishing options
    publishOnHashruns.value = originalData.evtDisseminateHashRunsDotOrg ?? -2;
    runAudience.value = originalData.evtDisseminationAudience ?? -2;
    allowWebLink.value = originalData.evtDisseminateAllowWebLinks ?? 2;
    runAttendance.value = originalData.canEditRunAttendence ?? -2;

    // Reset tags
    tags1.value = originalData.tags1;
    tags2.value = originalData.tags2;
    tags3.value = originalData.tags3;

    // Reset run tag selection status (for chip-based UI)
    resetRunTagsToOriginal();

    // Reset country
    country.value = originalData.countryName;
    countryId.value = originalData.countryId;

    // Reset uploaded image
    uploadedImage.value = null;

    // Reset all UI controls to their original values
    for (final control in uiControls.values) {
      control.undo();
    }

    // Repopulate text controllers with original values
    populateTextControllers();

    // IMPORTANT: Reset editedData AFTER text controllers are populated
    // to avoid onChanged callbacks overwriting with incorrect values
    editedData.value = originalData.copyWith();

    // Center map on original coordinates and force rebuild
    if (mapController.value != null &&
        originalData.hcLatitude != null &&
        originalData.hcLongitude != null) {
      mapController.value!.center = LatLng(
        Angle.degree(originalData.hcLatitude!),
        Angle.degree(originalData.hcLongitude!),
      );
    }
    // Always increment trigger to force map rebuild (even if no coords)
    mapRebuildTrigger.value++;

    checkIfFormIsDirty();
  }

  /// Checks if the form has unsaved changes.
  @override
  void checkIfFormIsDirty() {
    // Compare edited data with original data
    isFormDirty.value = editedData.value != originalData ||
        tags1.value != originalData.tags1 ||
        tags2.value != originalData.tags2 ||
        tags3.value != originalData.tags3 ||
        uploadedImage.value != null ||
        countryId.value != originalData.countryId ||
        useExtRunDetails.value != (originalData.useFbRunDetails != 0) ||
        useExtLocation.value != (originalData.useFbLocation != 0) ||
        useExtLatLon.value != (originalData.useFbLatLon != 0) ||
        useExtImage.value != (originalData.useFbImage != 0);

    // Validate form and refresh tab indicators
    formKey.currentState?.validate();
    checkUiControlValidationStates();
  }

  /// Refreshes validation states for all UI controls and tabs.
  void checkUiControlValidationStates() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      allFieldsAreValid.value = refreshTabStatuses();
    });
  }

  /// Populates text controllers with current edited data values.
  @override
  void populateTextControllers() {
    for (final entry in uiControls.entries) {
      final control = entry.value;
      if (control.textController != null) {
        control.textController!.text = control.editedFieldValue ?? '';
      }
    }
  }

  /// Closes the editor and navigates back.
  @override
  Future<void> close() async {
    if (isFormDirty.value) {
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
              'You have unsaved changes. Are you sure you want to leave?'),
          actions: [
            TextButton(
              onPressed: () => Get.back<bool>(result: false),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () => Get.back<bool>(result: true),
              child: const Text('Leave'),
            ),
          ],
        ),
      );
      if (result != true) return;
    }
    // Delete the controller to ensure fresh data is loaded next time
    await Get.delete<RunEditPageController>(force: true);
    Get.back<void>();
  }

  /// Builds the map of changed fields for API submission.
  Map<String, dynamic> _buildChanges() {
    final changes = <String, dynamic>{};
    final edited = editedData.value;
    final original = originalData;

    // -------------------------------------------------------------------------
    // Basic Info Tab Fields
    // -------------------------------------------------------------------------

    // Run name
    if (isAddMode || edited.eventName != original.eventName) {
      changes['eventName'] = edited.eventName;
    }

    // Run description
    if (isAddMode || edited.eventDescription != original.eventDescription) {
      changes['eventDescription'] = edited.eventDescription;
    }

    // Start datetime
    if (isAddMode || edited.eventStartDatetime != original.eventStartDatetime) {
      changes['eventStartDatetime'] =
          edited.eventStartDatetime.toIso8601String();
    }

    // -------------------------------------------------------------------------
    // Location Tab Fields
    // -------------------------------------------------------------------------

    // Location one-line description
    if (isAddMode ||
        edited.locationOneLineDesc != original.locationOneLineDesc) {
      changes['locationOneLineDesc'] = edited.locationOneLineDesc;
    }

    // Location street
    if (isAddMode || edited.locationStreet != original.locationStreet) {
      changes['locationStreet'] = edited.locationStreet;
    }

    // Location city
    if (isAddMode || edited.locationCity != original.locationCity) {
      changes['locationCity'] = edited.locationCity;
    }

    // Location region
    if (isAddMode || edited.locationRegion != original.locationRegion) {
      changes['locationRegion'] = edited.locationRegion;
    }

    // Location post code
    if (isAddMode || edited.locationPostCode != original.locationPostCode) {
      changes['locationPostCode'] = edited.locationPostCode;
    }

    // Location country
    if (isAddMode || edited.locationCountry != original.locationCountry) {
      changes['locationCountry'] = edited.locationCountry;
    }

    // Latitude (hcLatitude)
    if (isAddMode || edited.hcLatitude != original.hcLatitude) {
      changes['hcLatitude'] = edited.hcLatitude;
    }

    // Longitude (hcLongitude)
    if (isAddMode || edited.hcLongitude != original.hcLongitude) {
      changes['hcLongitude'] = edited.hcLongitude;
    }

    // Country ID
    if (countryId.value != original.countryId) {
      changes['countryId'] = countryId.value;
    }

    // -------------------------------------------------------------------------
    // Image Tab Fields
    // -------------------------------------------------------------------------

    // Uploaded image
    if (uploadedImage.value != null) {
      changes['eventImage'] = uploadedImage.value;
    }

    // -------------------------------------------------------------------------
    // Misc Tab Fields
    // -------------------------------------------------------------------------

    // Visibility (isVisible)
    if (isAddMode || edited.isVisible != original.isVisible) {
      changes['isVisible'] = edited.isVisible;
    }

    // Is counted run
    if (isAddMode || edited.isCountedRun != original.isCountedRun) {
      changes['isCountedRun'] = edited.isCountedRun;
    }

    // Event number
    // Send SET_DB_NUMERIC_FIELD_TO_NULL to reset absoluteEventNumber to null in the database
    if (isAddMode ||
        edited.absoluteEventNumber != original.absoluteEventNumber) {
      changes['absoluteEventNumber'] =
          edited.absoluteEventNumber ?? SET_DB_NUMERIC_FIELD_TO_NULL;
    }

    // Hares
    if (isAddMode || edited.hares != original.hares) {
      changes['hares'] = edited.hares;
    }

    // Web publishing settings (evtDisseminateHashRunsDotOrg)
    if (isAddMode ||
        edited.evtDisseminateHashRunsDotOrg !=
            original.evtDisseminateHashRunsDotOrg) {
      changes['evtDisseminateHashRunsDotOrg'] =
          edited.evtDisseminateHashRunsDotOrg;
    }

    // Run audience (evtDisseminationAudience)
    if (isAddMode ||
        edited.evtDisseminationAudience != original.evtDisseminationAudience) {
      changes['evtDisseminationAudience'] = edited.evtDisseminationAudience;
    }

    // Allow web link sharing (evtDisseminateAllowWebLinks)
    if (isAddMode ||
        edited.evtDisseminateAllowWebLinks !=
            original.evtDisseminateAllowWebLinks) {
      changes['evtDisseminateAllowWebLinks'] =
          edited.evtDisseminateAllowWebLinks;
    }

    // Can edit run attendance (canEditRunAttendence)
    if (isAddMode ||
        edited.canEditRunAttendence != original.canEditRunAttendence) {
      changes['canEditRunAttendence'] = edited.canEditRunAttendence;
    }

    // -------------------------------------------------------------------------
    // Tags Tab Fields
    // -------------------------------------------------------------------------

    if (isAddMode || tags1.value != original.tags1) {
      changes['tags1'] = tags1.value;
    }
    if (isAddMode || tags2.value != original.tags2) {
      changes['tags2'] = tags2.value;
    }
    if (isAddMode || tags3.value != original.tags3) {
      changes['tags3'] = tags3.value;
    }

    // -------------------------------------------------------------------------
    // Other Tab Fields
    // -------------------------------------------------------------------------

    // Integration enabled
    if (isAddMode || edited.integrationEnabled != original.integrationEnabled) {
      changes['integrationEnabled'] = edited.integrationEnabled;
    }

    // -------------------------------------------------------------------------
    // Payment Tab Fields
    // -------------------------------------------------------------------------

    // Member price - send SET_DB_NUMERIC_FIELD_TO_NULL to reset to null
    if (isAddMode ||
        edited.eventPriceForMembers != original.eventPriceForMembers) {
      changes['eventPriceForMembers'] =
          edited.eventPriceForMembers ?? SET_DB_NUMERIC_FIELD_TO_NULL;
    }

    // Non-member price - send SET_DB_NUMERIC_FIELD_TO_NULL to reset to null
    if (isAddMode ||
        edited.eventPriceForNonMembers != original.eventPriceForNonMembers) {
      changes['eventPriceForNonMembers'] =
          edited.eventPriceForNonMembers ?? SET_DB_NUMERIC_FIELD_TO_NULL;
    }

    // Extras price - send SET_DB_NUMERIC_FIELD_TO_NULL to reset to null
    if (isAddMode ||
        edited.eventPriceForExtras != original.eventPriceForExtras) {
      changes['eventPriceForExtras'] =
          edited.eventPriceForExtras ?? SET_DB_NUMERIC_FIELD_TO_NULL;
    }

    // Extras description - send SET_DB_STRING_FIELD_TO_NULL to reset to null
    if (isAddMode || edited.extrasDescription != original.extrasDescription) {
      changes['extrasDescription'] =
          edited.extrasDescription ?? SET_DB_STRING_FIELD_TO_NULL;
    }

    // Extras RSVP required
    if (isAddMode || edited.extrasRsvpRequired != original.extrasRsvpRequired) {
      changes['extrasRsvpRequired'] = edited.extrasRsvpRequired;
    }

    // Participation limits
    if (isAddMode ||
        edited.maximumParticipantsAllowed !=
            original.maximumParticipantsAllowed) {
      changes['maximumParticipantsAllowed'] = edited.maximumParticipantsAllowed;
    }
    if (isAddMode ||
        edited.minimumParticipantsRequired !=
            original.minimumParticipantsRequired) {
      changes['minimumParticipantsRequired'] =
          edited.minimumParticipantsRequired;
    }

    // -------------------------------------------------------------------------
    // Integration Flags
    // -------------------------------------------------------------------------

    _addBoolChange(changes, 'useFbRunDetails', useExtRunDetails.value,
        original.useFbRunDetails != 0);
    _addBoolChange(changes, 'useFbLocation', useExtLocation.value,
        original.useFbLocation != 0);
    _addBoolChange(
        changes, 'useFbLatLon', useExtLatLon.value, original.useFbLatLon != 0);
    _addBoolChange(
        changes, 'useFbImage', useExtImage.value, original.useFbImage != 0);

    return changes;
  }

  /// Helper to add boolean changes to the map.
  void _addBoolChange(
    Map<String, dynamic> changes,
    String fieldName,
    bool currentValue,
    bool originalValue,
  ) {
    if (isAddMode || currentValue != originalValue) {
      changes[fieldName] = currentValue ? 1 : 0;
    }
  }

  /// Updates run tag selection state and recalculates form validity.
  ///
  /// This method:
  /// 1. Updates the selection status for the specified tag
  /// 2. Recalculates the count of selected tags
  /// 3. Converts selections back to bit flag format for the model
  /// 4. Updates form dirty state
  void updateRunTags({bool? isSelected, String? tagKey}) {
    if (tagKey != null && isSelected != null) {
      runTagSelectionStatus[tagKey]?.value = isSelected ? 1 : 0;
    }

    // Count selected tags and compute bit flags
    int count = 0;
    int newTags1 = 0;
    int newTags2 = 0;
    int newTags3 = 0;

    for (final tag in RunTag.values) {
      final selected = runTagSelectionStatus[tag.key]?.value == 1;
      if (selected) {
        count++;
        switch (tag.tagsInteger) {
          case 1:
            newTags1 |= tag.bitMask;
            break;
          case 2:
            newTags2 |= tag.bitMask;
            break;
          case 4:
            newTags3 |= tag.bitMask;
            break;
        }
      }
    }

    selectedRunTagCount.value = count;
    tags1.value = newTags1;
    tags2.value = newTags2;
    tags3.value = newTags3;

    // Update tags control validity
    final tagsControl = uiControls['${RunTabType.runTags.key}_runTags'];
    tagsControl?.editedFieldValue = count > 0 ? count.toString() : null;

    checkIfFormIsDirty();
  }

  /// Initializes run tag selection status from the model's bit flag values.
  void initializeRunTagsFromBitFlags() {
    final t1 = originalData.tags1;
    final t2 = originalData.tags2;
    final t3 = originalData.tags3;

    int count = 0;

    for (final tag in RunTag.values) {
      final isSelected = switch (tag.tagsInteger) {
        1 => (t1 & tag.bitMask) != 0,
        2 => (t2 & tag.bitMask) != 0,
        4 => (t3 & tag.bitMask) != 0,
        _ => false,
      };

      runTagSelectionStatus[tag.key] = (isSelected ? 1 : 0).obs;
      if (isSelected) count++;
    }

    selectedRunTagCount.value = count;
  }

  /// Resets run tag selections to their original values.
  void resetRunTagsToOriginal() {
    final t1 = originalData.tags1;
    final t2 = originalData.tags2;
    final t3 = originalData.tags3;

    int count = 0;

    for (final tag in RunTag.values) {
      final isSelected = switch (tag.tagsInteger) {
        1 => (t1 & tag.bitMask) != 0,
        2 => (t2 & tag.bitMask) != 0,
        4 => (t3 & tag.bitMask) != 0,
        _ => false,
      };

      runTagSelectionStatus[tag.key]?.value = isSelected ? 1 : 0;
      if (isSelected) count++;
    }

    selectedRunTagCount.value = count;
    tags1.value = t1;
    tags2.value = t2;
    tags3.value = t3;
  }

  // ---------------------------------------------------------------------------
  // Location / Map Methods
  // ---------------------------------------------------------------------------

  /// Initializes the map controller with the run, kennel, or city location.
  void initializeMapController() {

    double lat;
    double lon;

    if (originalData.hcLatitude != null && originalData.hcLatitude != 0.0) {
      lat = originalData.hcLatitude!;
      lon = originalData.hcLongitude ?? 0.0;

    } else if (kennelData.kennelLat != null && kennelData.kennelLat != 0.0) {
      lat = kennelData.kennelLat!;
      lon = kennelData.kennelLon ?? 0.0;
    } else if (kennelData.cityLat != 0.0) {
      lat = kennelData.cityLat;
      lon = kennelData.cityLon;
    } else {
      // Fallback to London
      lat = 51.5074;
      lon = -0.1278;
    }

    mapController.value = geo_map.MapController(
      location: LatLng(Angle.degree(lat), Angle.degree(lon)),
    );
  }

  /// Formats a coordinate value, truncating trailing zeros.
  /// e.g., 52.12000 → "52.12", 52.12345 → "52.12345"
  String formatCoordinate(double? value) {
    if (value == null) return '';
    // Use up to 5 decimal places, then remove trailing zeros
    final formatted = value.toStringAsFixed(5);
    // Remove trailing zeros and trailing decimal point
    return formatted
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  /// Opens the combined location lookup dialog and applies the selected result.
  ///
  /// This method is shared between the Basic Info page and the Location page
  /// so the same dialog can be launched from either place.
  Future<void> openLocationLookupDialog() async {
    isLookupLoading.value = true;

    try {
      // Get all events from the parent run list controller
      final RunListPageController? runListController;
      try {
        runListController = Get.find<RunListPageController>();
      } catch (_) {
        return; // controller not registered
      }

      final events = runListController.allEvents;
      if (events.isEmpty) return;

      // Determine kennel centre for map
      final kd = kennelData;
      final lat = kd.kennelLat ?? kd.cityLat;
      final lon = kd.kennelLon ?? kd.cityLon;

      // Get the current place description to pre-select a match
      final placeKey =
          '${RunTabType.basicInfo.key}_${RunBasicInfoField.placeDescription.name}';
      final currentPlaceDesc = textControllers[placeKey]?.text;

      // Allow the UI to show the loading state before opening dialog
      await Future<void>.delayed(Duration.zero);

      // Show the lookup dialog
      final result = await Get.dialog<LocationLookupResult>(
        RunLocationLookupDialog(
          events: events,
          kennelLat: lat,
          kennelLon: lon,
          kennelCountryCodes: kd.kennelCountryCodes,
          initialPlaceDescription: currentPlaceDesc,
        ),
        barrierDismissible: true,
      );

      if (result != null) {
        switch (result) {
          case PreviousRunResult(:final run):
            await populateFromPreviousRun(run.publicEventId);
          case GazetteerResult(:final result):
            populateFromGazetteerResult(result);
        }
      }
    } finally {
      isLookupLoading.value = false;
    }
  }

  /// Helper to update a single address field.
  void _updateAddressField(RunLocationField field, String value) {
    final fieldKey = '${RunTabType.location.key}_${field.name}';
    textControllers[fieldKey]?.text = value;
    uiControls[fieldKey]?.updateEditedValue(value.isEmpty ? null : value);
  }

  /// Builds a full street address from the geocoding result.
  /// Prefers streetNameAndNumber, falls back to streetNumber + streetName.
  String _buildStreetAddress(dynamic address) {
    // If we have the combined field, use it
    if (address.streetNameAndNumber != null &&
        (address.streetNameAndNumber as String).isNotEmpty) {
      return address.streetNameAndNumber as String;
    }

    // Otherwise, combine street number and street name
    final streetNumber = address.streetNumber as String? ?? '';
    final streetName = address.streetName as String? ?? '';

    if (streetNumber.isNotEmpty && streetName.isNotEmpty) {
      return '$streetNumber $streetName';
    } else if (streetName.isNotEmpty) {
      return streetName;
    } else if (streetNumber.isNotEmpty) {
      return streetNumber;
    }

    return '';
  }

  /// Populates location fields from a previously used run location.
  ///
  /// Fetches the full [RunDetailsModel] for the given [publicEventId] and
  /// copies all location-related fields (place description, address, lat/lon)
  /// into the current form. Also centres the map on the new coordinates.
  Future<void> populateFromPreviousRun(String publicEventId) async {
    publicEventId = normalizeUuid(publicEventId);
    final edr = await querySingleEvent(publicEventId);
    final source = edr.runDetails;

    // Use ext (external) field as fallback when the primary field is null.
    String _loc(String? primary, String? ext) =>
        (primary != null && primary.isNotEmpty) ? primary : (ext ?? '');
    final lat = source.hcLatitude ?? source.fbLatitude;
    final lon = source.hcLongitude ?? source.fbLongitude;

    // --- Place description (Basic Info tab) ---
    final placeDesc =
        _loc(source.locationOneLineDesc, source.extLocationOneLineDesc);
    final placeKey =
        '${RunTabType.basicInfo.key}_${RunBasicInfoField.placeDescription.name}';
    textControllers[placeKey]?.text = placeDesc;
    uiControls[placeKey]
        ?.updateEditedValue(placeDesc.isEmpty ? null : placeDesc);

    // --- Address fields (Location tab) ---
    _updateAddressField(RunLocationField.street,
        _loc(source.locationStreet, source.extLocationStreet));
    _updateAddressField(RunLocationField.city,
        _loc(source.locationCity, source.extLocationCity));
    _updateAddressField(RunLocationField.postcode,
        _loc(source.locationPostCode, source.extLocationPostCode));
    _updateAddressField(RunLocationField.region,
        _loc(source.locationRegion, source.extLocationRegion));
    _updateAddressField(RunLocationField.country,
        _loc(source.locationCountry, source.extLocationCountry));
    _updateAddressField(
        RunLocationField.phone, source.locationPhoneNumber ?? '');

    // --- Lat / Lon ---
    final latKey =
        '${RunTabType.location.key}_${RunLocationField.latitude.name}';
    final lonKey =
        '${RunTabType.location.key}_${RunLocationField.longitude.name}';

    textControllers[latKey]?.text = formatCoordinate(lat);
    textControllers[lonKey]?.text = formatCoordinate(lon);

    uiControls[latKey]?.updateEditedValue(formatCoordinate(lat));
    uiControls[lonKey]?.updateEditedValue(formatCoordinate(lon));

    // --- Centre map ---
    if (lat != null && lon != null) {
      mapController.value?.center = LatLng(
        Angle.degree(lat),
        Angle.degree(lon),
      );
      mapRebuildTrigger.value++;
    }

    checkIfFormIsDirty();
  }

  /// Populates location fields from a gazetteer search result.
  ///
  /// Operates on a single [Results] object returned from the lookup dialog
  /// and updates all location-related fields (place description, lat/lon,
  /// address) in the current form.
  void populateFromGazetteerResult(Results result) {
    final address = result.address;

    // --- Place description (Basic Info tab) ---
    final placeName = result.poi?.name ?? address?.freeformAddress ?? '';
    final placeKey =
        '${RunTabType.basicInfo.key}_${RunBasicInfoField.placeDescription.name}';
    textControllers[placeKey]?.text = placeName;
    uiControls[placeKey]
        ?.updateEditedValue(placeName.isEmpty ? null : placeName);

    // --- Lat / Lon ---
    if (result.position != null) {
      final latKey =
          '${RunTabType.location.key}_${RunLocationField.latitude.name}';
      final lonKey =
          '${RunTabType.location.key}_${RunLocationField.longitude.name}';

      final lat = result.position!.lat;
      final lon = result.position!.lon;

      textControllers[latKey]?.text = formatCoordinate(lat);
      textControllers[lonKey]?.text = formatCoordinate(lon);

      uiControls[latKey]?.updateEditedValue(formatCoordinate(lat));
      uiControls[lonKey]?.updateEditedValue(formatCoordinate(lon));

      // Centre map on the result
      if (mapController.value != null && lat != null && lon != null) {
        mapController.value!.center =
            LatLng(Angle.degree(lat), Angle.degree(lon));
        mapRebuildTrigger.value++;
      }
    }

    // --- Address fields (Location tab) ---
    if (!useExtLocation.value && address != null) {
      _updateAddressField(
          RunLocationField.street, _buildStreetAddress(address));
      _updateAddressField(RunLocationField.city, address.municipality ?? '');
      _updateAddressField(RunLocationField.postcode,
          address.extendedPostalCode ?? address.postalCode ?? '');
      _updateAddressField(
          RunLocationField.region, address.countrySubdivision ?? '');
      _updateAddressField(RunLocationField.country, address.country ?? '');
    }

    checkIfFormIsDirty();
  }

  /// Performs reverse geocoding to set address from current lat/lon.
  Future<void> reverseGeocode() async {
    final latKey =
        '${RunTabType.location.key}_${RunLocationField.latitude.name}';
    final lonKey =
        '${RunTabType.location.key}_${RunLocationField.longitude.name}';

    final latText = textControllers[latKey]?.text;
    final lonText = textControllers[lonKey]?.text;

    final lat = double.tryParse(latText ?? '');
    final lon = double.tryParse(lonText ?? '');

    if (lat == null || lon == null) return;

    isGeocoding.value = true;

    try {
      final hasherId = box.get(HIVE_HASHER_ID) as String;
      final paramString =
          '$hasherId:${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}';
      final accessToken = Utilities.generateToken(
        hasherId,
        'hcportal_reverseGeocode',
        paramString: paramString,
      );

      final body = <String, String>{
        'userId': hasherId,
        'accessToken': accessToken,
        'lat': lat.toString(),
        'lon': lon.toString(),
      };

      final url = Uri.parse(PORTAL_REVERSE_GEOCODE_API_URL);
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Accept': '*/*',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final azureAddress = AzureGeoAddress.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );

        if ((azureAddress.summary?.numResults ?? 0) > 0) {
          final address = azureAddress.addresses?[0].address;
          if (address != null) {
            _updateAddressField(
                RunLocationField.street, _buildStreetAddress(address));
            _updateAddressField(
                RunLocationField.city, address.municipality ?? '');
            _updateAddressField(RunLocationField.postcode,
                address.extendedPostalCode ?? address.postalCode ?? '');
            _updateAddressField(
                RunLocationField.region, address.countrySubdivision ?? '');
            _updateAddressField(
                RunLocationField.country, address.country ?? '');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Reverse geocode failed: $e');
    } finally {
      isGeocoding.value = false;
      checkIfFormIsDirty();
    }
  }

  /// Sets lat/lon fields from the current map center position.
  void setLatLonFromMap() {
    if (mapController.value == null) return;

    final lat = mapController.value!.center.latitude.degrees;
    final lon = mapController.value!.center.longitude.degrees;

    final latKey =
        '${RunTabType.location.key}_${RunLocationField.latitude.name}';
    final lonKey =
        '${RunTabType.location.key}_${RunLocationField.longitude.name}';

    textControllers[latKey]?.text = formatCoordinate(lat);
    textControllers[lonKey]?.text = formatCoordinate(lon);

    uiControls[latKey]?.updateEditedValue(formatCoordinate(lat));
    uiControls[lonKey]?.updateEditedValue(formatCoordinate(lon));

    checkIfFormIsDirty();
  }

  /// Centers the map on the current lat/lon field values.
  void centerMapOnLatLon() {
    if (mapController.value == null) return;

    final latKey =
        '${RunTabType.location.key}_${RunLocationField.latitude.name}';
    final lonKey =
        '${RunTabType.location.key}_${RunLocationField.longitude.name}';

    final lat = double.tryParse(textControllers[latKey]?.text ?? '');
    final lon = double.tryParse(textControllers[lonKey]?.text ?? '');

    if (lat != null && lon != null) {
      mapController.value!.center =
          LatLng(Angle.degree(lat), Angle.degree(lon));
      mapRebuildTrigger.value++;
    }
  }

  /// Copies address fields from external integration source.
  void copyAddressFromExternal() {
    _updateAddressField(
        RunLocationField.street, originalData.extLocationStreet ?? '');
    _updateAddressField(
        RunLocationField.city, originalData.extLocationCity ?? '');
    _updateAddressField(
        RunLocationField.postcode, originalData.extLocationPostCode ?? '');
    _updateAddressField(
        RunLocationField.region, originalData.extLocationRegion ?? '');
    _updateAddressField(
        RunLocationField.country, originalData.extLocationCountry ?? '');
    checkIfFormIsDirty();
  }

  /// Copies lat/lon from external integration source.
  void copyLatLonFromExternal() {
    final latKey =
        '${RunTabType.location.key}_${RunLocationField.latitude.name}';
    final lonKey =
        '${RunTabType.location.key}_${RunLocationField.longitude.name}';

    if (originalData.fbLatitude != null && originalData.fbLongitude != null) {
      textControllers[latKey]?.text = formatCoordinate(originalData.fbLatitude);
      textControllers[lonKey]?.text =
          formatCoordinate(originalData.fbLongitude);

      uiControls[latKey]
          ?.updateEditedValue(formatCoordinate(originalData.fbLatitude));
      uiControls[lonKey]
          ?.updateEditedValue(formatCoordinate(originalData.fbLongitude));

      // Also center map
      mapController.value?.center = LatLng(
        Angle.degree(originalData.fbLatitude!),
        Angle.degree(originalData.fbLongitude!),
      );
      mapRebuildTrigger.value++;
    }

    checkIfFormIsDirty();
  }
}
