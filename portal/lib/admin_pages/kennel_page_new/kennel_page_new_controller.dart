/// Kennel Page Form Controller
///
/// This controller manages the state and business logic for the kennel editing form.
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
import 'kennel_page_new_enums.dart';

part 'pages/kennel_info_page/controls.dart';
part 'pages/kennel_location_page/controls.dart';
part 'pages/kennel_tags_page/controls.dart';
part 'pages/kennel_other_page/controls.dart';
part 'pages/kennel_developer_page/controls.dart';
part 'pages/kennel_hash_cash_page/controls.dart';
part 'pages/kennel_songs_page/controls.dart';

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

/// Controller for the kennel editing form.
///
/// This controller manages:
/// - Form data state (original and edited versions)
/// - Auto-save timer and state
/// - Tab navigation and validation
/// - Text editing controllers for form fields
class KennelPageFormController extends TabUiController
    with GetSingleTickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------

  KennelPageFormController(this._initialData) {
    originalData = _initialData;
    setScreenSize();
  }

  /// Initial data passed to the controller.
  final KennelModel _initialData;

  // ---------------------------------------------------------------------------
  // State - Core Data
  // ---------------------------------------------------------------------------

  /// The original kennel data (used for comparison and undo).
  late KennelModel originalData;

  /// The currently edited kennel data (reactive).
  final Rx<KennelModel> editedData = Rx<KennelModel>(KennelModel.empty());

  /// D&B token for external integrations.
  final RxString dAndBToken = ''.obs;

  // ---------------------------------------------------------------------------
  // State - UI Controllers
  // ---------------------------------------------------------------------------

  /// Text editing controllers mapped by field key.
  final Map<String, TextEditingController> textControllers = {};

  /// Form state key for validation.
  final GlobalKey<FormState> formKey = GlobalKey<FormState>(
    debugLabel: 'kennelFormKey_${DateTime.now().millisecondsSinceEpoch}',
  );

  /// Scroll controller for the all-fields tab.
  final ScrollController scrollController = ScrollController();

  /// Tracks upload state for file fields.
  final Map<String, RxBool> uploadingState = {};

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
  // State - Form Tracking
  // ---------------------------------------------------------------------------

  /// Currently active form index (for multi-form tabs).
  final RxInt activeFormIndex = 0.obs;

  /// Word count for the current form.
  final RxInt formWordCount = 0.obs;

  /// Maximum word count for current form type.
  int maxWordCount = AppFormTypes.formOverivew.maxFormWordCount;

  /// Minimum word count for current form type.
  int minWordCount = AppFormTypes.formOverivew.minFormWordCount;

  // ---------------------------------------------------------------------------
  // State - Tags
  // ---------------------------------------------------------------------------

  /// Tag selection status by key (1 = selected, 0 = not selected).
  final Map<String, RxInt> runTagSelectionStatus = {};

  /// Count of currently selected run tags.
  final RxInt selectedRunTagCount = 0.obs;

  // ---------------------------------------------------------------------------
  // State - Location Preferences
  // ---------------------------------------------------------------------------

  /// Distance unit preference: -1 = country default, 0 = kilometers, 1 = miles.
  final RxInt distancePreference = (-1).obs;

  /// Kennel map pin color (0-8).
  final RxInt kennelPinColor = 0.obs;

  // ---------------------------------------------------------------------------
  // State - Other Tab Settings
  // ---------------------------------------------------------------------------

  /// Default run start time for the kennel.
  final Rx<DateTime> defaultRunStartTime =
      DateTime.fromMillisecondsSinceEpoch(0).obs;

  /// Show runs on Hashruns.org (0 = off, 5 = on).
  final RxBool disseminateHashRunsDotOrg = false.obs;

  /// Enable copy web link sharing.
  final RxBool disseminateAllowWebLinks = false.obs;

  /// Publish runs to Harrier Central Global Google Calendar.
  final RxBool disseminateOnGlobalGoogleCalendar = false.obs;

  /// Publish runs to custom Google Calendars.
  final RxBool publishToGoogleCalendar = false.obs;

  /// Allow users to edit their own run attendance.
  final RxBool canEditRunAttendence = false.obs;

  /// Exclude this kennel from the leaderboard.
  final RxBool excludeFromLeaderboard = false.obs;

  /// Google Calendar addresses validation flag.
  final RxBool googleCalendarAddressesValid = true.obs;

  // ---------------------------------------------------------------------------
  // State - Hash Cash Tab Settings
  // ---------------------------------------------------------------------------

  /// Default event price for members.
  final RxDouble defaultEventPriceForMembers = 0.0.obs;

  /// Default event price for non-members.
  final RxDouble defaultEventPriceForNonMembers = 0.0.obs;

  /// Allow negative credit balance for hashers.
  final RxBool allowNegativeCredit = false.obs;

  /// Allow hashers to mark themselves as paid.
  final RxBool allowSelfPayment = false.obs;

  // ---------------------------------------------------------------------------
  // State - Songs Tab
  // ---------------------------------------------------------------------------

  /// Whether songs are currently being loaded from the API.
  final RxBool songsLoading = false.obs;

  /// All songs returned from the API.
  final RxList<SongModel> allSongs = <SongModel>[].obs;

  /// Original song selections (snapshot from initial load).
  final Map<String, int> originalSongSelections = {};

  /// Current song selections: songId → RxInt (1 = in kennel, 0 = not).
  final Map<String, RxInt> songSelections = {};

  /// Currently selected song ID for the detail panel.
  final RxString selectedSongId = ''.obs;

  /// Search query for filtering the song list.
  final RxString songSearchQuery = ''.obs;

  /// Text controller for the song search field.
  final TextEditingController songSearchController = TextEditingController();

  /// Whether the "Add New Song" form is currently displayed.
  final RxBool isAddingSong = false.obs;

  /// Text controllers for the new song form.
  final TextEditingController newSongNameController = TextEditingController();
  final TextEditingController newSongTuneOfController = TextEditingController();
  final TextEditingController newSongLyricsController = TextEditingController();
  final TextEditingController newSongNotesController = TextEditingController();
  final TextEditingController newSongActionsController =
      TextEditingController();
  final TextEditingController newSongVariantsController =
      TextEditingController();
  final TextEditingController newSongTagsController = TextEditingController();

  /// Returns the list of songs filtered by the current search query.
  List<SongModel> get filteredSongs {
    final query = songSearchQuery.value.toLowerCase().trim();
    if (query.isEmpty) return allSongs;
    return allSongs.where((song) {
      return song.SongName.toLowerCase().contains(query) ||
          (song.TuneOf?.toLowerCase().contains(query) ?? false) ||
          (song.Tags?.toLowerCase().contains(query) ?? false) ||
          (song.Lyrics?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

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
    unawaited(_loadSongs());
  }

  @override
  void onClose() {
    _screenSizeDebouncer?.dispose();
    _autoSaveTimer?.cancel();
    songSearchController.dispose();
    newSongNameController.dispose();
    newSongTuneOfController.dispose();
    newSongLyricsController.dispose();
    newSongNotesController.dispose();
    newSongActionsController.dispose();
    newSongVariantsController.dispose();
    newSongTagsController.dispose();
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
      tabKeyBuilder: (index) => KennelTabType.values[index].key,
      onTabIndexChanging: checkUiControlValidationStates,
      tabIndexChangingUpdateIds: const ['tabIcons', 'submissionTab'],
    );
  }

  /// Sets up the auto-save listener.
  void _initializeAutoSave() {
    ever(doAutoSave, _handleAutoSaveToggle);
  }

  /// Initializes tab state bundle (status, locks, validation).
  void _initializeTabStates() {
    initTabStateBundle(
      length: KennelTabType.values.length,
      initiallyEmptyIndex: 0,
      initialLockState: TabLocked.tabUnlocked,
    );
  }

  /// Initializes form data and UI controls.
  void _initializeFormData() {
    editedData.value = originalData.copyWith();

    // Initialize location preferences from original data
    distancePreference.value = originalData.distancePreference ?? -1;
    kennelPinColor.value = originalData.kennelPinColor;

    // Initialize Other tab settings from original data
    _initializeOtherTabSettings();

    // Initialize Hash Cash tab settings from original data
    _initializeHashCashTabSettings();

    // Initialize run tags from bit flags
    _initializeRunTagsFromBitFlags();

    // Initialize UI controls for each tab (defined in part files)
    initKennelInfoControls();
    initKennelLocationControls();
    initKennelRunTagsControls();
    initKennelOtherControls();
    initKennelDeveloperControls();
    initKennelHashCashControls();
    initKennelSongsControls();

    populateTextControllers();
  }

  /// Initializes the Other tab reactive state from original data.
  void _initializeOtherTabSettings() {
    defaultRunStartTime.value = originalData.defaultRunStartTime;
    disseminateHashRunsDotOrg.value =
        originalData.disseminateHashRunsDotOrg > 0;
    disseminateAllowWebLinks.value = originalData.disseminateAllowWebLinks > 0;
    disseminateOnGlobalGoogleCalendar.value =
        originalData.disseminateOnGlobalGoogleCalendar > 0;
    publishToGoogleCalendar.value =
        (originalData.publishToGoogleCalendar ?? 0) > 0;
    canEditRunAttendence.value = originalData.canEditRunAttendence > 0;
    excludeFromLeaderboard.value = originalData.excludeFromLeaderboard > 0;
  }

  /// Initializes the Hash Cash tab reactive state from original data.
  void _initializeHashCashTabSettings() {
    defaultEventPriceForMembers.value =
        originalData.defaultEventPriceForMembers;
    defaultEventPriceForNonMembers.value =
        originalData.defaultEventPriceForNonMembers;
    allowNegativeCredit.value = originalData.allowNegativeCredit > 0;
    allowSelfPayment.value = originalData.allowSelfPayment > 0;
  }

  /// Initializes run tag selection status from the model's bit flag values.
  void _initializeRunTagsFromBitFlags() {
    final tags1 = originalData.defaultRunTags1;
    final tags2 = originalData.defaultRunTags2;
    final tags3 = originalData.defaultRunTags3;

    int count = 0;

    for (final tag in RunTag.values) {
      final isSelected = switch (tag.tagsInteger) {
        1 => (tags1 & tag.bitMask) != 0,
        2 => (tags2 & tag.bitMask) != 0,
        4 => (tags3 & tag.bitMask) != 0,
        _ => false,
      };

      runTagSelectionStatus[tag.key] = (isSelected ? 1 : 0).obs;
      if (isSelected) count++;
    }

    selectedRunTagCount.value = count;
  }

  /// Sets up screen size change listener with debounce.
  void _initializeScreenSizeListener() {
    _screenSizeDebouncer = debounce(
      width,
      (_) => setScreenSize(),
      time: const Duration(milliseconds: 50),
    );
  }

  /// Schedules initial validation after a brief delay.
  ///
  /// This ensures tabs show correct status when the page first loads.
  void _scheduleInitialValidation() {
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 100)).then((_) {
        checkUiControlValidationStates();
        update(['tabIcons']);
      }),
    );
  }

  /// Disposes all text editing controllers.
  void _disposeTextControllers() {
    for (final controller in textControllers.values) {
      controller.dispose();
    }
    textControllers.clear();
  }

  // ---------------------------------------------------------------------------
  // Auto-save
  // ---------------------------------------------------------------------------

  /// Toggles auto-save on/off.
  void toggleAutoSave() {
    doAutoSave.value = !doAutoSave.value;
  }

  /// Handles auto-save toggle changes.
  void _handleAutoSaveToggle(bool enabled) {
    if (enabled) {
      _startAutoSaveTimer();
    } else {
      _stopAutoSaveTimer();
    }
  }

  /// Starts the auto-save timer.
  void _startAutoSaveTimer() {
    autoSaveCounter.value = 0;
    _autoSaveTimer = Timer.periodic(
      const Duration(milliseconds: AUTOSAVE_INTERVAL_IN_MILLISECONDS),
      _onAutoSaveTimerTick,
    );
  }

  /// Stops the auto-save timer.
  void _stopAutoSaveTimer() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  /// Handles each auto-save timer tick.
  Future<void> _onAutoSaveTimerTick(Timer timer) async {
    if (!doAutoSave.value) return;

    autoSaveCounter.value += (AUTOSAVE_INTERVAL_IN_MILLISECONDS ~/ 1000);

    if (autoSaveCounter.value > AUTOSAVE_PERIOD_IN_SECONDS) {
      autoSaveCounter.value = -1; // Indicates saving in progress
      await save(false);
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      autoSaveCounter.value = 0;
    }
  }

  // ---------------------------------------------------------------------------
  // Form State Management
  // ---------------------------------------------------------------------------

  @override
  void checkIfFormIsDirty() {
    isFormDirty.value = (originalData != editedData.value);
    formKey.currentState?.validate();
    checkUiControlValidationStates();
  }

  @override
  void undoChanges() {
    // Reset edited data to original
    editedData.value = originalData.copyWith();

    // Reset all UI controls to their original values
    for (final control in uiControls.values) {
      control.undo();
    }

    // Trigger rebuild so field controllers detect the changes
    update(['kennelFormPageBuilder']);

    populateTextControllers();
    checkIfFormIsDirty();
  }

  @override
  void populateTextControllers() {
    for (final tab in allTabs) {
      _syncFieldsToControllers(keyPrefix: tab.key);
    }
  }

  /// Syncs UI control values to their text controllers.
  ///
  /// For fields with override buttons, this respects the lookthrough value
  /// when the field is not overridden.
  void _syncFieldsToControllers({required String keyPrefix}) {
    uiControls.forEach((key, control) {
      if (!key.startsWith(keyPrefix)) return;
      if (control.textController == null) return;

      // Determine the correct display value
      String displayValue;

      if (control.includeOverrideButton && control.lookthroughValue != null) {
        // For override fields: show lookthrough if not overridden
        final original = control.originalFieldValue;
        final isOverridden = original != null &&
            original.isNotEmpty &&
            original != control.lookthroughValue;

        displayValue = isOverridden ? original : control.lookthroughValue!;
      } else {
        // For regular fields: show the original value
        displayValue = control.originalFieldValue ?? '';
      }

      control.textController!.text = displayValue;
    });
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  @override
  Future<void> close() async {
    await save(false);
    Get.back(result: originalData);
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  @override
  Future<void> save(bool showDialog) async {
    final deviceId = box.get(HIVE_DEVICE_ID) as String;
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
    final accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_editKennel',
      paramString: deviceSecret,
    );

    final bodyParams = <String, dynamic>{
      'queryType': 'editKennel',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'publicKennelId': editedData.value.kennelPublicId.uuid,
    };

    // Build changed data payload (only include modified fields)
    final changedData = _buildChangedDataPayload();
    bodyParams.addAll(changedData);

    final jsonResult = await ServiceCommon.sendHttpPostToHC6Api(bodyParams);

    await _handleSaveResponse(jsonResult, showDialog);
  }

  /// Builds a map of only the changed fields for the API payload.
  Map<String, dynamic> _buildChangedDataPayload() {
    final editedJson = editedData.value.toJson();
    final originalJson = originalData.toJson();
    final changedData = <String, dynamic>{};

    editedJson.forEach((key, value) {
      if (editedJson[key] != originalJson[key]) {
        // Special handling for coordinates (use 999 as null indicator)
        if (key.toLowerCase() == 'latitude' ||
            key.toLowerCase() == 'longitude') {
          changedData[key] = editedJson[key] ?? 999;
        } else {
          changedData[key] = editedJson[key];
        }
      }
    });

    return changedData;
  }

  /// Handles the API response after saving.
  Future<void> _handleSaveResponse(String jsonResult, bool showDialog) async {
    if (jsonResult.startsWith(ERROR_PREFIX)) return;

    final decoded = json.decode(jsonResult) as List<dynamic>;
    final items = (decoded[0] as List<dynamic>)[0] as Map<String, dynamic>;
    final result = items['result'] as String;
    final resultCode = items['resultCode'] as int;

    if (resultCode == 1) {
      // Success - update original data to match edited
      originalData = editedData.value.copyWith();
      checkIfFormIsDirty();
    }

    if (showDialog) {
      await CoreUtilities.showAlert('Update result', result, 'OK');
    }
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  /// Refreshes validation states for all UI controls and tabs.
  void checkUiControlValidationStates() {
    allFieldsAreValid.value = refreshTabStatuses();
  }

  // ---------------------------------------------------------------------------
  // Run Tag Management
  // ---------------------------------------------------------------------------

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
    int tags1 = 0;
    int tags2 = 0;
    int tags3 = 0;

    for (final tag in RunTag.values) {
      final selected = runTagSelectionStatus[tag.key]?.value == 1;
      if (selected) {
        count++;
        switch (tag.tagsInteger) {
          case 1:
            tags1 |= tag.bitMask;
            break;
          case 2:
            tags2 |= tag.bitMask;
            break;
          case 4:
            tags3 |= tag.bitMask;
            break;
        }
      }
    }

    selectedRunTagCount.value = count;

    // Update the model with new bit flag values
    editedData.value = editedData.value.copyWith(
      defaultRunTags1: tags1,
      defaultRunTags2: tags2,
      defaultRunTags3: tags3,
    );

    // Update tags control validity
    final tagsControl = uiControls['${KennelTabType.tags.key}_runTags'];
    tagsControl?.editedFieldValue = count > 0 ? count.toString() : null;

    checkIfFormIsDirty();
  }

  /// Resets run tag selections to their original values.
  void resetRunTagsToOriginal() {
    final tags1 = originalData.defaultRunTags1;
    final tags2 = originalData.defaultRunTags2;
    final tags3 = originalData.defaultRunTags3;

    int count = 0;

    for (final tag in RunTag.values) {
      final isSelected = switch (tag.tagsInteger) {
        1 => (tags1 & tag.bitMask) != 0,
        2 => (tags2 & tag.bitMask) != 0,
        4 => (tags3 & tag.bitMask) != 0,
        _ => false,
      };

      runTagSelectionStatus[tag.key]?.value = isSelected ? 1 : 0;
      if (isSelected) count++;
    }

    selectedRunTagCount.value = count;

    // Update edited data to match original
    editedData.value = editedData.value.copyWith(
      defaultRunTags1: tags1,
      defaultRunTags2: tags2,
      defaultRunTags3: tags3,
    );
  }

  // ---------------------------------------------------------------------------
  // Song Management
  // ---------------------------------------------------------------------------

  /// Loads songs from the API for the current kennel.
  Future<void> _loadSongs() async {
    songsLoading.value = true;

    try {
      final kennelId = originalData.kennelPublicId.uuid;
      final songs = await queryKennelSongs(kennelId);

      allSongs.value = songs;

      // Build selection maps
      songSelections.clear();
      originalSongSelections.clear();

      for (final song in songs) {
        songSelections[song.id] = RxInt(song.isInKennel);
        originalSongSelections[song.id] = song.isInKennel;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('_loadSongs error: $e');
    } finally {
      songsLoading.value = false;
      _updateSongsTabStatus();
    }
  }

  /// Updates the Songs tab validity indicator.
  ///
  /// Shows a checkmark if at least one song is selected, otherwise an empty box.
  void _updateSongsTabStatus() {
    final int songsTabIndex = KennelTabType.songs.index;
    if (songsTabIndex < tabStatus.length) {
      final bool hasSongs = songSelections.values.any((rx) => rx.value == 1);
      tabStatus[songsTabIndex].value =
          hasSongs ? TabStatus.isCompleteAndValid : TabStatus.isEmpty;
    }
  }

  /// Toggles whether a song is included in this kennel.
  ///
  /// Optimistically updates the UI, then calls the API. If the API call
  /// fails, the selection is reverted.
  Future<void> toggleSongInKennel(String songId, bool isInKennel) async {
    // Optimistic UI update
    final previousValue = songSelections[songId]?.value ?? 0;
    songSelections[songId]?.value = isInKennel ? 1 : 0;

    try {
      final success = await toggleKennelSong(
        publicKennelId: originalData.kennelPublicId.uuid,
        songId: songId,
        isInKennel: isInKennel,
      );

      if (success) {
        // Update the original snapshot so this toggle is no longer "dirty"
        originalSongSelections[songId] = isInKennel ? 1 : 0;
      } else {
        // Revert on failure
        songSelections[songId]?.value = previousValue;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Song toggle failed: $e');
      songSelections[songId]?.value = previousValue;
    } finally {
      _updateSongsTabStatus();
    }
  }

  /// Selects a song to display its details in the right panel.
  void selectSong(String songId) {
    isAddingSong.value = false;
    selectedSongId.value = songId;
  }

  /// Resets song selections to their original state.
  void resetSongsToOriginal() {
    for (final entry in originalSongSelections.entries) {
      songSelections[entry.key]?.value = entry.value;
    }
    checkIfFormIsDirty();
  }

  /// Enters the "Add New Song" mode, showing the editable form.
  void startAddNewSong() {
    selectedSongId.value = '';
    isAddingSong.value = true;

    // Clear form fields
    newSongNameController.clear();
    newSongTuneOfController.clear();
    newSongLyricsController.clear();
    newSongNotesController.clear();
    newSongActionsController.clear();
    newSongVariantsController.clear();
    newSongTagsController.clear();
  }

  /// Cancels adding a new song and returns to the detail placeholder.
  void cancelAddNewSong() {
    isAddingSong.value = false;
  }

  /// Saves the new song via the API and refreshes the song list.
  Future<void> saveNewSong() async {
    final songName = newSongNameController.text.trim();
    if (songName.isEmpty) {
      await CoreUtilities.showAlert(
        'Validation',
        'Song name is required.',
        'OK',
      );
      return;
    }

    final publicHasherId = box.get(HIVE_HASHER_ID) as String;
    final accessToken = Utilities.generateToken(
      publicHasherId,
      'hcportal_addSong',
      paramString: originalData.kennelPublicId.uuid,
    );

    final body = <String, dynamic>{
      'queryType': 'addSong',
      'publicHasherId': publicHasherId,
      'accessToken': accessToken,
      'publicKennelId': originalData.kennelPublicId.uuid,
      'songName': songName,
      'tuneOf': newSongTuneOfController.text.trim(),
      'lyrics': newSongLyricsController.text.trim(),
      'notes': newSongNotesController.text.trim(),
      'actions': newSongActionsController.text.trim(),
      'variants': newSongVariantsController.text.trim(),
      'tags': newSongTagsController.text.trim(),
    };

    final jsonResult = await ServiceCommon.sendHttpPostToAzureFunctionApi(body);

    if (jsonResult.length > 10) {
      isAddingSong.value = false;

      // Reload songs to pick up the newly added one
      await _loadSongs();

      await CoreUtilities.showAlert(
        'Song Added',
        '$songName has been added successfully.',
        'OK',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Tab Configuration
  // ---------------------------------------------------------------------------

  /// Builds tab definitions from the [KennelTabType] enum.
  List<TabDefinitionData> _buildTabDefinitions() {
    return KennelTabType.values.map((tab) {
      return TabDefinitionData(
        key: tab.key,
        title: tab.title,
        tabIndex: tab.index,
        hasCustomTabStatusFunction: tab.hasCustomTabStatusFunction,
        showTabInSubmitSummary: tab.showTabInSubmitSummary,
        isTabLockable: tab.isTabLockable,
        sidebarData: SideBarData(tab.title, tab.icon, tab.description),
      );
    }).toList();
  }
}
