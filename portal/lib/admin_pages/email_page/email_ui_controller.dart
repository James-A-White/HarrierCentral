import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:fleather/fleather.dart' as fleather;
import 'package:hcportal/imports.dart';
import 'package:hcportal/models/email/email_model.dart';

part 'pages/email_ui_ad_hoc_email.dart';

class EmailTabbedUiController extends TabUiController
    with GetSingleTickerProviderStateMixin {
  GlobalKey<FormState> formKey = GlobalKey<FormState>(
    debugLabel: 'debug = ${DateTime.now().second}',
  );

  EmailModel originalData = EmailModel.empty();
  Rx<EmailModel> editedData = Rx<EmailModel>(EmailModel.empty());

  final Map<String, TextEditingController> textEditingController = {};
  final RxInt tabsSelectedCount = 0.obs;

  final tabDescription = TabDataAdHocEmail();

  final RxInt applicationFormWordCount = 0.obs;

  final Rx<fleather.FleatherController> fleatherController =
      fleather.FleatherController().obs;
  FocusNode fleatherFocusNode = FocusNode();
  final GlobalKey<fleather.EditorState> editorKey = GlobalKey();

  RegExp wordRegExp = RegExp(r'\w+');
  String fleatherPlainTextContent = '';
  final RxString fleatherFormattedTextContent = ''.obs;

  final RxInt activeFormIndex = 0.obs;

  Worker? _debounceFormText;

  final Map<String, RxInt> tagsStatus = {};
  final RxBool doAutoSave = false.obs;
  final RxInt autoSaveCounter = 0.obs;

  Map<String, Rx<bool>> uploading = {};

  final ScrollController allFieldsTabScrollController = ScrollController();

  Timer? autoSaveTimer;

  @override
  void onInit() {
    super.onInit();

    initTabs(
      vsync: this,
      tabs: [tabDescription],
      tabKeyBuilder: (i) => allTabs[i].key,
    );

    initTabStateBundle(
      length: allTabs.length,
      initiallyEmptyIndex: 0,
      initialLockState: TabLocked.tabUnlocked,
    );

    editedData.value = originalData.copyWith();

    tabAppDetails_buildControls();
    populateTextControllers();

    unawaited(onInitAsync());
  }

  @override
  void onClose() {
    fleatherController.value.dispose();
    _debounceFormText?.dispose();
    fleatherFocusNode.dispose();
    allFieldsTabScrollController.dispose();
    autoSaveTimer?.cancel();
    for (final tc in textEditingController.values) {
      tc.dispose();
    }
    super.onClose();
  }

  Future<void> onInitAsync() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    checkUiControlValidationStates();
  }

  void checkUiControlValidationStates() {
    refreshTabStatuses();
    if (kDebugMode) debugPrint('Email tab statuses refreshed');
  }

  @override
  void checkIfFormIsDirty() {}

  @override
  Future<void> close() async {
    await save(false);
  }

  @override
  Future<void> save(bool showDialog) async {}

  @override
  void undoChanges() {
    editedData.value = originalData.copyWith();
    uiControls.forEach((_, control) => control.undo());
    populateTextControllers();
    checkIfFormIsDirty();
  }

  @override
  void populateTextControllers() {
    uiControls.forEach((_, control) => control.populateTextEditingControl());
  }
}
