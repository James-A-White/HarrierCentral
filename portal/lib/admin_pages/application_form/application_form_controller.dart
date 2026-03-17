import 'package:hcportal/imports.dart';
import 'package:fleather/fleather.dart' as fleather;

// import 'package:flutter/foundation.dart';
// import 'package:flutter/services.dart';
// import 'package:parchment/parchment.dart';
// import 'package:parchment_to_html/parachment_to_html.dart';

// import 'package:hcportal/models/duns_company_lookup_model/duns_company_lookup_model.dart';

import 'application_form_enums.dart';
part 'application_form_ui_definitions.dart';

class ApplicationFormController extends TabUiController
    with GetSingleTickerProviderStateMixin {
  ApplicationFormController(this.originalData) {
    // Initialize controllers with initial data if available
    setScreenSize();
  }
  // Core state
  RxString dAndBtoken = ''.obs;
  Rx<ApplicationModel?> editedData = Rx<ApplicationModel?>(null);
  ApplicationModel originalData = ApplicationModel.empty();

  // UI state
  final Map<String, TextEditingController> textEditingController = {};

  final RxInt tabsSelectedCount = 0.obs;
  final ScrollController allFieldsTabScrollController = ScrollController();

  // Keys and controllers
  GlobalKey<FormState> formKey = GlobalKey<FormState>(
    debugLabel: 'debug = ${DateTime.now().second}',
  );
  final GlobalKey<fleather.EditorState> editorKey = GlobalKey();

  // @override
  // late TabController tabController;

  // Text editor state
  final Rx<fleather.FleatherController> fleatherController =
      fleather.FleatherController().obs;
  FocusNode fleatherFocusNode = FocusNode();
  RegExp wordRegExp = RegExp(r'\w+');
  String fleatherPlainTextContent = '';
  final RxString fleatherFormattedTextContent = ''.obs;

  // Form tabs state
  final RxInt activeFormIndex = 0.obs;
  int applicationFormMaxWordCount = AppFormTypes.formOverivew.maxFormWordCount;
  int applicationFormMinWordCount = AppFormTypes.formOverivew.minFormWordCount;
  final RxInt applicationFormWordCount = 0.obs;
  late Worker? _debounceFormText;

  // Tag state
  final Map<String, RxInt> tagsStatus = {};
  final Map<String, AppExperienceTags> tags = {};

  // Auto-save
  final RxBool doAutoSave = false.obs;
  final RxInt autoSaveCounter = 0.obs;
  Timer? autoSaveTimer;

  // params and variables for Description tab
  final appDescriptionTab_tcApplicationTitle = TextEditingController();
  final appDescriptionTab_tcApplicationShortDescription =
      TextEditingController();
  Map<String, RxBool> uploading = {};

  @override
  void onInit() {
    super.onInit();

    initTabs(
      vsync: this,
      tabs: _buildTabsFromEnum(),
      tabKeyBuilder: (index) => AppTabKeyEnums.values[index].key,
      onTabIndexChanging: () {
        checkUiControlValidationStates();
      },
      tabIndexChangingUpdateIds: const ['tabIcons', 'submissionTab'],
    );

    ever(activeFormIndex, (newValue) {
      AppFormTypes formType = AppFormTypes.values[activeFormIndex.value];
      applicationFormMinWordCount = formType.minFormWordCount;
      applicationFormMaxWordCount = formType.maxFormWordCount;
      _loadFleatherDoc(activeFormIndex.value);
    });

    ever(doAutoSave, (bool newValue) {
      if (newValue) {
        autoSaveCounter.value = 0;
        autoSaveTimer = Timer.periodic(
            const Duration(milliseconds: AUTOSAVE_INTERVAL_IN_MILLISECONDS),
            (timer) async {
          if (doAutoSave.value) {
            autoSaveCounter.value +=
                (AUTOSAVE_INTERVAL_IN_MILLISECONDS ~/ 1000);
            if (autoSaveCounter.value > AUTOSAVE_PERIOD_IN_SECONDS) {
              autoSaveCounter.value = -1;
              await save(false);
              await Future<void>.delayed(const Duration(milliseconds: 1500));
              autoSaveCounter.value = 0;
            }
          }
        });
      } else {
        autoSaveTimer?.cancel();
      }
    });

    TabLocked initialTabLockedState = TabLocked.tabUnlocked;
    if (originalData.isSubmitted == '1') {
      initialTabLockedState = TabLocked.tabLocked;
    }

    initTabStateBundle(
      length: AppTabKeyEnums.values.length,
      initiallyEmptyIndex: 0,
      initialLockState: initialTabLockedState,
    );

    editedData.value = originalData.copyWith();

    tabAppDetails_buildControls();

    setInitialValues();

    _loadFleatherDoc(activeFormIndex.value);

    _debounceFormText = debounce(
      fleatherFormattedTextContent,
      (_) {
        switch (activeFormIndex.value) {
          case 0:
            editedData.value = editedData.value!
                .copyWith(formOverivew: fleatherFormattedTextContent.value);
          case 1:
            editedData.value = editedData.value!.copyWith(
                formTechnicalDescription: fleatherFormattedTextContent.value);
          case 2:
            editedData.value = editedData.value!.copyWith(
                formCommercialViability: fleatherFormattedTextContent.value);
          case 3:
            editedData.value = editedData.value!
                .copyWith(formProjectPlan: fleatherFormattedTextContent.value);
        }

        Iterable<Match> matches =
            wordRegExp.allMatches(fleatherPlainTextContent);
        applicationFormWordCount.value = matches.length;

        AppFormTypes formType = AppFormTypes.values[activeFormIndex.value];

        String formValidationKey =
            '${AppTabKeyEnums.tabForms.key}_${formType.key}';

        bool isValid = true;
        if ((applicationFormWordCount.value < formType.minFormWordCount) ||
            (applicationFormWordCount.value > formType.maxFormWordCount)) {
          isValid = false;
        }
        uiControls[formValidationKey]!
            .updateEditedValue(applicationFormWordCount.value == 0
                ? ''
                : isValid
                    ? BOOL_TRUE
                    : BOOL_FALSE);

        checkIfFormIsDirty();
      },
      time: const Duration(milliseconds: 1000),
    );

    String tagKeys = originalData.tagKeys ?? '';
    for (var tag in AppExperienceTags.values) {
      tagsStatus[tag.key] = tagKeys.contains(tag.key) ? 1.obs : 0.obs;
      tags[tag.key] = tag;
    }
    updateTags();

    //TODO: This is a hack to ensure the tabs show up when the applicaiton page is open. One day we need
    // to take this out and find out why the tabs aren't initilizing properly
    unawaited(
        Future<void>.delayed(const Duration(milliseconds: 100)).then((value) {
      checkUiControlValidationStates();
      update(['tabIcons']);
      //gotoTab(1);
    }));
  }

  @override
  void populateTextControllers() {}

  @override
  void onClose() {
    fleatherController.value.dispose();
    _debounceFormText?.dispose();
    dispose();
    super.onClose();
  }

  // Check if any field differs from its initial value
  @override
  void checkIfFormIsDirty() {
    isFormDirty.value = (originalData != editedData.value);

    formKey.currentState?.validate();
    checkUiControlValidationStates();
  }

  @override
  void undoChanges() {
    editedData.value = originalData.copyWith();
    setInitialValues();
    uiControls.forEach((name, control) {
      control.undo();
    });
    checkIfFormIsDirty();
  }

  @override
  Future<void> close() async {
    await save(false);
    Get.back(result: originalData);
  }

  @override
  Future<void> save(
    bool showDialog,
  ) async {
    originalData = editedData.value!.copyWith();
    checkIfFormIsDirty();
    // await innovatorFormController.saveToCloud(
    //   showDialog: showDialog,
    //   application: originalData,
    // );
  }

  void updateTags({bool? tagSelected, String? entryKey}) {
    // entryKey will be set from the change notifier on individual tags when they have been clicked

    if ((entryKey != null) && (tagSelected != null)) {
      tagsStatus[entryKey]!.value = tagSelected ? 1 : 0;
    }

    StringBuffer tagKeys = StringBuffer();
    StringBuffer tagTitles = StringBuffer();

    int counter = 0;

    tagsStatus.forEach((key, selected) {
      if (selected.value == 1) {
        counter++;
        tagKeys.write('$key,');
        tagTitles.write('${tags[key]?.title ?? ''},');
      }
    });
    tabsSelectedCount.value = counter;

    uiControls['${AppTabKeyEnums.tabTags.key}_tags']!.updateEditedValue(
        (counter == 0)
            ? null
            : ((counter < MINIMUM_TAGS_REQUIRED) ||
                    (counter > MAXIMUM_TAGS_ALLOWWED))
                ? BOOL_FALSE
                : BOOL_TRUE);

    editedData.value = editedData.value!.copyWith(
      tagKeys: tagKeys.toString(),
      tagLabels: tagTitles.toString(),
    );
    checkIfFormIsDirty();
  }

  void _loadFleatherDoc(int idx) {
    fleather.ParchmentDocument? doc;

    fleatherController.value.dispose();

    String? sourceDocumentText;

    switch (idx) {
      case 0:
        sourceDocumentText = editedData.value!.formOverivew;
      case 1:
        sourceDocumentText = editedData.value!.formTechnicalDescription;
      case 2:
        sourceDocumentText = editedData.value!.formCommercialViability;
      case 3:
        sourceDocumentText = editedData.value!.formProjectPlan;
    }

    if (sourceDocumentText != null) {
      var jsonData = json.decode(sourceDocumentText);

      final heuristics = fleather.ParchmentHeuristics(
        formatRules: [],
        insertRules: [
          ForceNewlineForInsertsAroundInlineImageRule2(),
        ],
        deleteRules: [],
      ).merge(fleather.ParchmentHeuristics.fallback);

      doc = fleather.ParchmentDocument.fromJson(
        jsonData,
        heuristics: heuristics,
      );

      fleatherController.value = fleather.FleatherController(document: doc);
    } else {
      fleatherController.value = fleather.FleatherController(document: doc);
    }

    fleatherController.value.document.changes.listen((change) {
      fleatherPlainTextContent =
          fleatherController.value.document.toPlainText();
      fleatherFormattedTextContent.value =
          json.encode(fleatherController.value.document.toJson());

      checkIfFormIsDirty();
    });

    Iterable<Match> matches =
        wordRegExp.allMatches(fleatherController.value.document.toPlainText());
    applicationFormWordCount.value = matches.length;
  }

  List<TabDefinitionData> _buildTabsFromEnum() {
    return AppTabKeyEnums.values
        .map(
          (tab) => TabDefinitionData(
            key: tab.key,
            title: tab.title,
            tabIndex: tab.idx,
            hasCustomTabStatusFunction: tab.hasCustomTabStatusFunction,
            showTabInSubmitSummary: tab.showTabInSubmitSummary,
            isTabLockable: tab.isTabLockable,
            sidebarData: SideBarData(
              tab.title,
              tab.icon,
              tab.description,
            ),
          ),
        )
        .toList();
  }

  void setInitialValues() {
    String tabName = AppTabKeyEnums.tabDescription.key;

    textEditingController['${tabName}_title']!.text = originalData.title;
    textEditingController['${tabName}_shortDescription']!.text =
        originalData.shortDescription;

    tabName = AppTabKeyEnums.tabCvs.key;
    textEditingController['${tabName}_stakeholderNameCeo']!.text =
        originalData.nameCeo ?? '';
    textEditingController['${tabName}_stakeholderEmailCeo']!.text =
        originalData.emailCeo ?? '';

    textEditingController['${tabName}_stakeholderNameTech']!.text =
        originalData.nameTech ?? '';
    textEditingController['${tabName}_stakeholderEmailTech']!.text =
        originalData.emailTech ?? '';

    textEditingController['${tabName}_stakeholderNameComm']!.text =
        originalData.nameComm ?? '';
    textEditingController['${tabName}_stakeholderEmailComm']!.text =
        originalData.emailComm ?? '';

    textEditingController['${tabName}_stakeholderNameAdmin']!.text =
        originalData.nameAdmin ?? '';
    textEditingController['${tabName}_stakeholderEmailAdmin']!.text =
        originalData.emailAdmin ?? '';
  }

  void isTabValid(int index) {}

  Future<void> submit() async {
    editedData.value = editedData.value!.copyWith(
      isSubmitted: '1',
      isSubmittedDetails: '<user name>, ${DateTime.now()}',
      submissionDate: DateTime.now(),
    );

    await save(false);
    checkIfFormIsDirty();
    setAllTabLocks(TabLocked.tabLocked);

    update(['refreshApplicationFormBuilder']);

    await Utilities.showAlert(
      'Application submitted',
      'Your application has been submitted!\r\n\r\nIf you need to make any changes to this application you can recall it, make the changes, and then resubmit it.',
      'OK',
    );
  }

  Future<void> recall() async {
    editedData.value = editedData.value!.copyWith(
      isSubmitted: '0',
      isSubmittedDetails: '',
      submissionDate: null,
    );

    await save(false);
    checkIfFormIsDirty();
    setAllTabLocks(TabLocked.tabUnlocked);
    update(['refreshApplicationFormBuilder']);
    await Utilities.showAlert(
      'Application recalled',
      'Your application has been recalled.\r\n\r\nYou can continue to make edits, but you must submit\r\nthis application prior to the deadline for your application\r\nto be considered for the DIANA Challenge program.',
      'OK',
    );
  }

  void checkUiControlValidationStates() {
    final bool isSubmittable = refreshTabStatuses();

    originalData =
        originalData.copyWith(applicationIsSubmitable: isSubmittable);
    editedData.value =
        editedData.value!.copyWith(applicationIsSubmitable: isSubmittable);

    updateSubmitTabStatus(AppTabKeyEnums.tabSubmit.index, isSubmittable);
  }
}
