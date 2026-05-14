import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hcportal/imports.dart';
import 'kennel_website_page_enums.dart';

part 'pages/identity_tab/controls.dart';
part 'pages/appearance_tab/controls.dart';
part 'pages/images_tab/controls.dart';
part 'pages/content_tab/controls.dart';
part 'pages/seo_tab/controls.dart';
part 'pages/features_tab/controls.dart';
part 'pages/advanced_tab/controls.dart';

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

class KennelWebsiteController extends TabUiController
    with GetSingleTickerProviderStateMixin {
  KennelWebsiteController(
    this._initialData, {
    required this.publicKennelId,
    required this.kennelName,
    required this.kennelUniqueShortName,
  }) {
    originalData = _initialData;
    setScreenSize();
  }

  final KennelWebsiteModel _initialData;

  // ---------------------------------------------------------------------------
  // Identity passed from calling page
  // ---------------------------------------------------------------------------

  final String publicKennelId;
  final String kennelName;
  final String kennelUniqueShortName;

  // ---------------------------------------------------------------------------
  // Core data
  // ---------------------------------------------------------------------------

  late KennelWebsiteModel originalData;
  final Rx<KennelWebsiteModel> editedData =
      Rx<KennelWebsiteModel>(KennelWebsiteModel.empty());

  // ---------------------------------------------------------------------------
  // UI controllers
  // ---------------------------------------------------------------------------

  final Map<String, TextEditingController> textControllers = {};
  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>(debugLabel: 'websiteFormKey');

  /// Upload progress state per image field key.
  final Map<String, RxBool> uploadingState = {};

  /// Upload status text per image field key ('selecting', 'uploading', '').
  final Map<String, RxString> uploadStatusState = {};

  // ---------------------------------------------------------------------------
  // Appearance tab reactive state
  // ---------------------------------------------------------------------------

  /// 0 = dark, 1 = light
  final RxInt themeModeIndex = 0.obs;

  // ---------------------------------------------------------------------------
  // Features tab reactive state (mirrors pageFeaturesJson)
  // ---------------------------------------------------------------------------

  final RxBool featShowLanding  = true.obs;
  final RxBool featShowAbout    = true.obs;
  final RxBool featShowHistory  = true.obs;
  final RxBool featShowRuns     = true.obs;
  final RxBool featShowEvents   = false.obs;
  final RxBool featShowStats    = false.obs;
  final RxBool featShowSongs    = false.obs;
  final RxInt  featPastRunsCount = 12.obs;

  static const Map<int, String> themeModeItems = {0: 'Dark', 1: 'Light'};

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  Worker? _screenSizeDebouncer;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    _initializeTabs();
    _initializeTabStates();
    _initializeFormData();
    _initializeScreenSizeListener();
    _scheduleInitialValidation();
  }

  @override
  void onClose() {
    _screenSizeDebouncer?.dispose();
    for (final c in textControllers.values) {
      c.dispose();
    }
    textControllers.clear();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Init helpers
  // ---------------------------------------------------------------------------

  void _initializeTabs() {
    initTabs(
      vsync: this,
      tabs: _buildTabDefinitions(),
      tabKeyBuilder: (i) => KennelWebsiteTabType.values[i].key,
      onTabIndexChanging: checkUiControlValidationStates,
      tabIndexChangingUpdateIds: const ['tabIcons'],
    );
  }

  void _initializeTabStates() {
    initTabStateBundle(
      length: KennelWebsiteTabType.values.length,
      initiallyEmptyIndex: 0,
      initialLockState: TabLocked.tabUnlocked,
    );
  }

  void _initializeFormData() {
    editedData.value = originalData.copyWith();
    themeModeIndex.value = originalData.themeMode == 'light' ? 1 : 0;

    initIdentityControls();
    initAppearanceControls();
    initImagesControls();
    initContentControls();
    initSeoControls();
    initFeaturesControls();
    initAdvancedControls();

    populateTextControllers();
  }

  void _initializeScreenSizeListener() {
    _screenSizeDebouncer = debounce(
      width,
      (_) => setScreenSize(),
      time: const Duration(milliseconds: 50),
    );
  }

  void _scheduleInitialValidation() {
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 100)).then((_) {
        checkUiControlValidationStates();
        update(['tabIcons']);
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // TabUiController overrides
  // ---------------------------------------------------------------------------

  @override
  void checkIfFormIsDirty() {
    isFormDirty.value = originalData != editedData.value;
    formKey.currentState?.validate();
    checkUiControlValidationStates();
  }

  @override
  void undoChanges() {
    editedData.value = originalData.copyWith();
    themeModeIndex.value = originalData.themeMode == 'light' ? 1 : 0;
    undoFeaturesState();

    for (final control in uiControls.values) {
      control.undo();
    }

    update(['websitePageBuilder']);
    populateTextControllers();
    checkIfFormIsDirty();
  }

  @override
  void populateTextControllers() {
    uiControls.forEach((key, control) {
      if (control.textController == null) return;
      control.textController!.text = control.originalFieldValue ?? '';
    });
  }

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
      'hcportal_updateKennelWebsite',
      paramString: deviceSecret,
    );

    final body = <String, dynamic>{
      'queryType': 'updateKennelWebsite',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'publicKennelId': publicKennelId,
    };

    body.addAll(_buildChangedDataPayload());

    final jsonResult = await ServiceCommon.sendHttpPostToHC6Api(body);
    if (kDebugMode) {
      debugPrint(jsonResult.startsWith(ERROR_PREFIX)
          ? 'SP [updateKennelWebsite] — FAILED'
          : 'SP [updateKennelWebsite] — success');
    }

    await _handleSaveResponse(jsonResult, showDialog);
  }

  Map<String, dynamic> _buildChangedDataPayload() {
    final editedJson = editedData.value.toJson();
    final originalJson = originalData.toJson();
    final changed = <String, dynamic>{};

    editedJson.forEach((key, value) {
      if (editedJson[key] != originalJson[key]) {
        final v = editedJson[key];
        // BIT columns: send 0/1 integers — JSON booleans are unreliable through ADO.NET.
        // Empty string sentinel: deliberately-cleared string fields → SP sets column to NULL.
        if (v is bool) {
          changed[key] = v ? 1 : 0;
        } else {
          changed[key] = (v == null && originalJson[key] is String) ? '' : v;
        }
      }
    });

    return changed;
  }

  Future<void> _handleSaveResponse(String jsonResult, bool showDialog) async {
    if (jsonResult.startsWith(ERROR_PREFIX)) return;

    final decoded = json.decode(jsonResult) as List<dynamic>;
    final items = (decoded[0] as List<dynamic>)[0] as Map<String, dynamic>;

    // Response is either a SuccessResult (result/resultCode) or error envelope
    final resultCode = items['resultCode'] as int?;
    if (resultCode == 1) {
      originalData = editedData.value.copyWith();
      checkIfFormIsDirty();
    }

    if (showDialog) {
      final message =
          items['result'] as String? ?? items['ErrorMessage'] as String? ?? '';
      await CoreUtilities.showAlert('Update result', message, 'OK');
    }
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  void checkUiControlValidationStates() {
    allFieldsAreValid.value = refreshTabStatuses();
  }

  // ---------------------------------------------------------------------------
  // Tab configuration
  // ---------------------------------------------------------------------------

  List<TabDefinitionData> _buildTabDefinitions() {
    return KennelWebsiteTabType.values.map((tab) {
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
