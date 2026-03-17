// import 'package:hcportal/imports.dart';
// import 'package:fleather/fleather.dart' as fleather;
// import 'package:hcportal/tabbed_ui_new/ui_control.dart';

// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/services.dart';
// // import 'package:parchment/parchment.dart';
// // import 'package:parchment_to_html/parachment_to_html.dart';

// // import 'package:hcportal/models/duns_company_lookup_model/duns_company_lookup_model.dart';

// import 'application_form_enums.dart';
// import 'application_form_sidebar_data.dart';
// part 'application_form_ui_definitions.dart';

// class ApplicationFormController extends GetxController
//     with GetSingleTickerProviderStateMixin {
//   ApplicationFormController(this.originalData) {
//     // Initialize controllers with initial data if available
//     setScreenSize();
//   }
//   int MOBILE_SCREEN_WIDTH = 650;
//   int NARROW_SCREEN_WIDTH = 900;

//   final RxBool allFieldsAreValid = true.obs;
//   RxInt currentIndex = 0.obs;
//   RxString dAndBtoken = ''.obs;
//   Rx<ApplicationModel?> editedData = Rx<ApplicationModel?>(null);
//   final Map<String, FocusNode> focusNodes = {};
//   final Map<String, RxBool> focusStates = {};
//   GlobalKey<FormState> formKey = GlobalKey<FormState>(
//     debugLabel: 'debug = ${DateTime.now().second}',
//   );

//   late TabController tabController;

//   RxDouble height = 0.0.obs;

//   // params and variables for Description tab
//   final appDescriptionTab_tcApplicationTitle = TextEditingController();
//   final appDescriptionTab_tcApplicationShortDescription =
//       TextEditingController();
//   Map<String, Rx<bool>> uploading = {};

//   //Rx<bool> uploadingDocument = false.obs;

//   // Reactive variable to track if form is dirty
//   RxBool isFormDirty = false.obs;

//   ApplicationModel originalData = ApplicationModel.empty();

//   final Rx<EScreenSize> screenSize = EScreenSize.isMobileScreen.obs;

//   final Rx<String?> sidebarDescription = Rx<String?>(null);
//   final Rx<IconData?> sidebarIcon = Rx<IconData?>(null);
//   final Rx<String?> sidebarTitle = Rx<String?>(null);

//   final List<Rx<TabStatus>> tabStatus = [];
//   final List<Rx<TabLocked>> tabLocked = [];
//   final Map<String, TextEditingController> textEditingController = {};
//   final RxDouble width = 0.0.obs;
//   final RxInt tabsSelectedCount = 0.obs;

//   @override
//   void onClose() {
//     tabController.dispose();
//     fleatherController.value.dispose();
//     _debounceFormText?.dispose();
//     dispose();
//     super.onClose();
//   }

//   final List<ControlValidity> tabValidResults = [];

//   int applicationFormMaxWordCount = AppFormTypes.formOverivew.maxFormWordCount;
//   int applicationFormMinWordCount = AppFormTypes.formOverivew.minFormWordCount;
//   final RxInt applicationFormWordCount = 0.obs;

//   final Rx<fleather.FleatherController> fleatherController =
//       fleather.FleatherController().obs;
//   FocusNode fleatherFocusNode = FocusNode();
//   final GlobalKey<fleather.EditorState> editorKey = GlobalKey();

//   RegExp wordRegExp = RegExp(r'\w+');
//   String fleatherPlainTextContent = '';
//   final RxString fleatherFormattedTextContent = ''.obs;

//   final RxInt activeFormIndex = 0.obs;

//   late Worker? _debounceFormText;

//   final Map<String, RxInt> tagsStatus = {};
//   final Map<String, AppExperienceTags> tags = {};

//   final RxBool doAutoSave = false.obs;
//   final RxInt autoSaveCounter = 0.obs;

//   final ScrollController allFieldsTabScrollController = ScrollController();

//   // Future<void> pasteFormattedText() async {
//   //   ClipboardData? clipboardData = await Clipboard.getData('image');

//   //   if (clipboardData != null && clipboardData.text != null) {
//   //     final html = clipboardData.text!;
//   //     try {
//   //       // Convert HTML to Delta format
//   //       final delta = const ParchmentHtmlCodec().decode(html);
//   //       fleatherController.value.replaceText(
//   //         fleatherController.value.document.length - 1, // Insert at the end
//   //         0,
//   //         delta,
//   //       );
//   //     } catch (e) {
//   //       //print'Failed to convert HTML to Delta: $e');
//   //     }
//   //   }
//   // }

//   Timer? autoSaveTimer;

//   @override
//   void onInit() {
//     super.onInit();

//     tabController =
//         TabController(length: AppTabKeyEnums.values.length, vsync: this);
//     tabController.addListener(() {
//       currentIndex.value = tabController.index;
//       sidebarDescription.value = null;
//       sidebarTitle.value = null;
//       sidebarIcon.value = null;
//       if (tabController.indexIsChanging) {
//         checkUiControlValidationStates();
//         update(['tabIcons']);
//         update(['submissionTab']);
//       }
//     });

//     ever(activeFormIndex, (newValue) {
//       AppFormTypes formType = AppFormTypes.values[activeFormIndex.value];
//       applicationFormMinWordCount = formType.minFormWordCount;
//       applicationFormMaxWordCount = formType.maxFormWordCount;
//       _loadFleatherDoc(activeFormIndex.value);
//     });

//     ever(doAutoSave, (bool newValue) {
//       if (newValue) {
//         autoSaveCounter.value = 0;
//         autoSaveTimer = Timer.periodic(
//             const Duration(milliseconds: AUTOSAVE_INTERVAL_IN_MILLISECONDS),
//             (timer) async {
//           if (doAutoSave.value) {
//             autoSaveCounter.value +=
//                 (AUTOSAVE_INTERVAL_IN_MILLISECONDS ~/ 1000);
//             if (autoSaveCounter.value > AUTOSAVE_PERIOD_IN_SECONDS) {
//               autoSaveCounter.value = -1;
//               await save(showDialog: false);
//               await Future<void>.delayed(const Duration(milliseconds: 1500));
//               autoSaveCounter.value = 0;
//             }
//           }
//         });
//       } else {
//         autoSaveTimer?.cancel();
//       }
//     });

//     tabStatus.addAll(List<Rx<TabStatus>>.generate(
//         AppTabKeyEnums.values.length, (value) => TabStatus.unknown.obs));

//     tabValidResults.addAll(List<ControlValidity>.generate(
//         AppTabKeyEnums.values.length, (value) => ControlValidity.unknown));

//     tabStatus[0].value = TabStatus.isEmpty;

//     editedData.value = originalData.copyWith();

//     TabLocked initialTabLockedState = TabLocked.tabUnlocked;
//     if (originalData.isSubmitted == '1') {
//       initialTabLockedState = TabLocked.tabLocked;
//     }

//     tabLocked.addAll(List<Rx<TabLocked>>.generate(
//         AppTabKeyEnums.values.length, (value) => initialTabLockedState.obs));

//     tabAppDetails_buildControls();

//     setInitialValues();

//     _loadFleatherDoc(activeFormIndex.value);

//     _debounceFormText = debounce(
//       fleatherFormattedTextContent,
//       (_) {
//         switch (activeFormIndex.value) {
//           case 0:
//             editedData.value = editedData.value!
//                 .copyWith(formOverivew: fleatherFormattedTextContent.value);
//           case 1:
//             editedData.value = editedData.value!.copyWith(
//                 formTechnicalDescription: fleatherFormattedTextContent.value);
//           case 2:
//             editedData.value = editedData.value!.copyWith(
//                 formCommercialViability: fleatherFormattedTextContent.value);
//           case 3:
//             editedData.value = editedData.value!
//                 .copyWith(formProjectPlan: fleatherFormattedTextContent.value);
//         }

//         Iterable<Match> matches =
//             wordRegExp.allMatches(fleatherPlainTextContent);
//         applicationFormWordCount.value = matches.length;

//         AppFormTypes formType = AppFormTypes.values[activeFormIndex.value];

//         String formValidationKey =
//             '${AppTabKeyEnums.tabForms.key}_${formType.key}';

//         bool isValid = true;
//         if ((applicationFormWordCount.value < formType.minFormWordCount) ||
//             (applicationFormWordCount.value > formType.maxFormWordCount)) {
//           isValid = false;
//         }
//         uiControls[formValidationKey]!
//             .updateEditedValue(applicationFormWordCount.value == 0
//                 ? ''
//                 : isValid
//                     ? BOOL_TRUE
//                     : BOOL_FALSE);

//         checkIfFormIsDirty();
//       },
//       time: const Duration(milliseconds: 1000),
//     );

//     String tagKeys = originalData.tagKeys ?? '';
//     for (var tag in AppExperienceTags.values) {
//       tagsStatus[tag.key] = tagKeys.contains(tag.key) ? 1.obs : 0.obs;
//       tags[tag.key] = tag;
//     }
//     updateTags();

//     //TODO: This is a hack to ensure the tabs show up when the applicaiton page is open. One day we need
//     // to take this out and find out why the tabs aren't initilizing properly
//     unawaited(
//         Future<void>.delayed(const Duration(milliseconds: 100)).then((value) {
//       checkUiControlValidationStates();
//       update(['tabIcons']);
//       //gotoTab(1);
//     }));
//   }

//   void updateTags({bool? tagSelected, String? entryKey}) {
//     // entryKey will be set from the change notifier on individual tags when they have been clicked

//     if ((entryKey != null) && (tagSelected != null)) {
//       tagsStatus[entryKey]!.value = tagSelected ? 1 : 0;
//     }

//     StringBuffer tagKeys = StringBuffer();
//     StringBuffer tagTitles = StringBuffer();

//     int counter = 0;

//     tagsStatus.forEach((key, selected) {
//       if (selected.value == 1) {
//         counter++;
//         tagKeys.write('$key,');
//         tagTitles.write('${tags[key]?.title ?? ''},');
//       }
//     });
//     tabsSelectedCount.value = counter;

//     uiControls['${AppTabKeyEnums.tabTags.key}_tags']!.updateEditedValue(
//         (counter == 0)
//             ? null
//             : ((counter < MINIMUM_TAGS_REQUIRED) ||
//                     (counter > MAXIMUM_TAGS_ALLOWWED))
//                 ? BOOL_FALSE
//                 : BOOL_TRUE);

//     editedData.value = editedData.value!.copyWith(
//       tagKeys: tagKeys.toString(),
//       tagLabels: tagTitles.toString(),
//     );
//     checkIfFormIsDirty();
//   }

//   void _loadFleatherDoc(int idx) {
//     fleather.ParchmentDocument? doc;

//     fleatherController.value.dispose();

//     String? sourceDocumentText;

//     switch (idx) {
//       case 0:
//         sourceDocumentText = editedData.value!.formOverivew;
//       case 1:
//         sourceDocumentText = editedData.value!.formTechnicalDescription;
//       case 2:
//         sourceDocumentText = editedData.value!.formCommercialViability;
//       case 3:
//         sourceDocumentText = editedData.value!.formProjectPlan;
//     }

//     if (sourceDocumentText != null) {
//       var jsonData = json.decode(sourceDocumentText);

//       final heuristics = fleather.ParchmentHeuristics(
//         formatRules: [],
//         insertRules: [
//           ForceNewlineForInsertsAroundInlineImageRule2(),
//         ],
//         deleteRules: [],
//       ).merge(fleather.ParchmentHeuristics.fallback);

//       doc = fleather.ParchmentDocument.fromJson(
//         jsonData,
//         heuristics: heuristics,
//       );

//       fleatherController.value = fleather.FleatherController(document: doc);
//     } else {
//       fleatherController.value = fleather.FleatherController(document: doc);
//     }

//     fleatherController.value.document.changes.listen((change) {
//       fleatherPlainTextContent =
//           fleatherController.value.document.toPlainText();
//       fleatherFormattedTextContent.value =
//           json.encode(fleatherController.value.document.toJson());

//       checkIfFormIsDirty();
//     });

//     Iterable<Match> matches =
//         wordRegExp.allMatches(fleatherController.value.document.toPlainText());
//     applicationFormWordCount.value = matches.length;
//   }

//   void gotoTab(int index) {
//     tabController.index = index;
//   }

//   void setScreenSize() {
//     if (Get.mediaQuery.size.width < MOBILE_SCREEN_WIDTH) {
//       screenSize.value = EScreenSize.isMobileScreen;
//       //print'size set to mobile');
//     } else if (Get.mediaQuery.size.width < NARROW_SCREEN_WIDTH) {
//       screenSize.value = EScreenSize.isNarrowScreen;
//       //print'size set to narrow');
//     } else {
//       screenSize.value = EScreenSize.isNormalScreen;
//       //print'size set to normal');
//     }
//   }

//   void setInitialValues() {
//     String tabName = AppTabKeyEnums.tabDescription.key;

//     textEditingController['${tabName}_title']!.text = originalData.title;
//     textEditingController['${tabName}_shortDescription']!.text =
//         originalData.shortDescription;

//     tabName = AppTabKeyEnums.tabCvs.key;
//     textEditingController['${tabName}_stakeholderNameCeo']!.text =
//         originalData.nameCeo ?? '';
//     textEditingController['${tabName}_stakeholderEmailCeo']!.text =
//         originalData.emailCeo ?? '';

//     textEditingController['${tabName}_stakeholderNameTech']!.text =
//         originalData.nameTech ?? '';
//     textEditingController['${tabName}_stakeholderEmailTech']!.text =
//         originalData.emailTech ?? '';

//     textEditingController['${tabName}_stakeholderNameComm']!.text =
//         originalData.nameComm ?? '';
//     textEditingController['${tabName}_stakeholderEmailComm']!.text =
//         originalData.emailComm ?? '';

//     textEditingController['${tabName}_stakeholderNameAdmin']!.text =
//         originalData.nameAdmin ?? '';
//     textEditingController['${tabName}_stakeholderEmailAdmin']!.text =
//         originalData.emailAdmin ?? '';
//   }

//   void updateSizeWithDebounce(double newWidth, double newHeight) {
//     if (width.value != newWidth) {
//       width.value = newWidth;
//     }
//     if (height.value != newHeight) {
//       height.value = newHeight;
//     }
//   }

//   void setSidebarData(
//     String key, {
//     String? shortDescription,
//     String? title,
//     IconData? icon,
//   }) {
//     if (shortDescription == null) {
//       if (key.isBlank ?? false) {
//         sidebarDescription.value = '';
//         sidebarTitle.value = '';
//         sidebarIcon.value = Ionicons.flag;
//       } else if (application_form_sidebar_data.containsKey(key)) {
//         sidebarDescription.value =
//             application_form_sidebar_data[key]!.description;
//         sidebarTitle.value = application_form_sidebar_data[key]!.title;
//         sidebarIcon.value = application_form_sidebar_data[key]!.icon;
//       }
//     } else {
//       sidebarDescription.value = shortDescription;
//       sidebarTitle.value = title;
//       sidebarIcon.value = icon;
//     }
//   }

//   void isTabValid(int index) {}

//   Map<String, UiControl> uiControls = {};

//   // Check if any field differs from its initial value
//   void checkIfFormIsDirty() {
//     isFormDirty.value = (originalData != editedData.value);

//     // //print'checkIfFormIsDirty called ${formKey.toString()}');
//     formKey.currentState?.validate();
//     checkUiControlValidationStates();
//   }

//   Future<void> submit() async {
//     editedData.value = editedData.value!.copyWith(
//       isSubmitted: '1',
//       isSubmittedDetails: '<user name>, ${DateTime.now()}',
//       submissionDate: DateTime.now(),
//     );

//     await save(showDialog: false);
//     checkIfFormIsDirty();
//     for (var rxTabLocked in tabLocked) {
//       rxTabLocked.value = TabLocked.tabLocked;
//     }

//     update(['refreshApplicationFormBuilder']);

//     await Utilities.showAlert(
//       'Application submitted',
//       'Your application has been submitted!\r\n\r\nIf you need to make any changes to this application you can recall it, make the changes, and then resubmit it.',
//       'OK',
//     );
//   }

//   Future<void> recall() async {
//     editedData.value = editedData.value!.copyWith(
//       isSubmitted: '0',
//       isSubmittedDetails: '',
//       submissionDate: null,
//     );

//     await save(showDialog: false);
//     checkIfFormIsDirty();
//     for (var rxTabLocked in tabLocked) {
//       rxTabLocked.value = TabLocked.tabUnlocked;
//     }
//     update(['refreshApplicationFormBuilder']);
//     await Utilities.showAlert(
//       'Application recalled',
//       'Your application has been recalled.\r\n\r\nYou can continue to make edits, but you must submit\r\nthis application prior to the deadline for your application\r\nto be considered for the DIANA Challenge program.',
//       'OK',
//     );
//   }

//   void checkUiControlValidationStates() {
//     uiControls.forEach((name, control) {
//       control.updateValidity();
//     });

//     bool isSubmittable = true;

//     int totalEmptyStatus = 0;
//     int totalValidStatus = 0;
//     int totalInvalidStatus = 0;
//     int totalTotal = 0;

//     for (int i = 0; i < AppTabKeyEnums.values.length; i++) {
//       int emptyStatus = 0;
//       int validStatus = 0;
//       int invalidStatus = 0;
//       int total = 0;
//       if (!AppTabKeyEnums.values[i].hasCustomTabStatusFunction) {
//         uiControls.forEach(
//           (name, control) {
//             if (control.tabIndex == i) {
//               total++;
//               switch (control.controlValidity.validity) {
//                 case ControlValidity.validEmpty:
//                   emptyStatus++;
//                   validStatus++;
//                   break;
//                 case ControlValidity.valid:
//                   validStatus++;
//                   break;
//                 case ControlValidity.invalid:
//                   invalidStatus++;
//                   isSubmittable = false;
//                   break;
//                 case ControlValidity.invalidEmpty:
//                   //invalidStatus++;
//                   emptyStatus++;
//                   isSubmittable = false;
//                   break;
//                 case ControlValidity.unknown:
//                   break;
//               }
//             }
//           },
//         );

//         TabStatus newStatus = TabStatus.unknown;

//         if (validStatus == total) {
//           newStatus = TabStatus.isCompleteAndValid;
//         } else if (emptyStatus == total) {
//           newStatus = TabStatus.isEmpty;
//         } else if (invalidStatus > 0) {
//           newStatus = TabStatus.isInvalid;
//         } else if (emptyStatus == total) {
//           newStatus = TabStatus.isEmpty;
//         } else {
//           newStatus = TabStatus.isInProgress;
//         }

//         tabStatus[i].value = newStatus;

//         print('tab=${AppTabKeyEnums.values[i].title}, empty=$emptyStatus, valid=$validStatus, invalid=$invalidStatus, total=$total');

//         totalInvalidStatus += invalidStatus;
//         totalValidStatus += validStatus;
//         totalEmptyStatus += emptyStatus;
//         totalTotal += total;
//       }
//     }

//     print(
//         'empty=$totalEmptyStatus, valid=$totalValidStatus, invalid=$totalInvalidStatus, total=$totalTotal');

//     originalData =
//         originalData.copyWith(applicationIsSubmitable: isSubmittable);
//     editedData.value =
//         editedData.value!.copyWith(applicationIsSubmitable: isSubmittable);

//     tabStatus[AppTabKeyEnums.tabSubmit.index].value =
//         isSubmittable ? TabStatus.isCompleteAndValid : TabStatus.isEmpty;
//   }

//   void undoChanges() {
//     editedData.value = originalData.copyWith();
//     setInitialValues();
//     uiControls.forEach((name, control) {
//       control.undo();
//     });
//     checkIfFormIsDirty();
//     //update(['innovatorUiRoot']);
//   }

//   Future<void> close() async {
//     await save();
//     Get.back(result: originalData);
//   }

//   Future<void> save({
//     bool? showDialog = true,
//   }) async {
//     originalData = editedData.value!.copyWith();
//     checkIfFormIsDirty();
//     // await innovatorFormController.saveToCloud(
//     //   showDialog: showDialog,
//     //   application: originalData,
//     // );
//   }
// }
