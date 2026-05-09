# Tabbed UI Framework — Context for New Implementations

Load this skill at the start of any session that involves creating or modifying
a tabbed UI in the Flutter portal. It replaces the need to re-read the framework
source files.

---

## Framework Location

```
portal/lib/tabbed_ui/
  controller/tab_ui_controller.dart     ← Abstract base (303 lines)
  classes/tab_definition_data.dart      ← Tab metadata
  classes/ui_control_definition.dart    ← Form field definition + validation
  classes/sidebar_data.dart             ← Sidebar icon/title/description
  widgets/
    tab_page_standard_layout.dart       ← The main page chrome (sidebar + content + save/undo)
    responsive_tab_navigation.dart      ← Tab bar (wide) / hamburger menu (narrow/mobile)
    tab_with_icon.dart                  ← Individual tab with status icon
    editable_text_field.dart            ← Standard text input
    editable_dropdown_field.dart        ← Dropdown selector
    editable_image_field.dart           ← Image upload
    editable_override_text_field.dart   ← Text field with lookthrough/override button
    tri_state_checkbox_field.dart       ← Checkbox / toggle
    document_manager_field.dart         ← PDF upload
    lockable.dart                       ← Lock overlay widget
    row_column.dart                     ← Responsive row/column layout helper
    sidebar_hover_region.dart           ← Hover-to-update-sidebar wrapper
    text_dropdown_field.dart            ← Combined text + dropdown
    integration_source_selector.dart    ← Integration source picker
```

---

## Abstract Base: `TabUiController`

Extends `GetxController`. Subclasses must also mix in
`GetSingleTickerProviderStateMixin`.

### Reactive state (all inherited)

| Field | Type | Purpose |
|-------|------|---------|
| `currentIndex` | `RxInt` | Active tab index |
| `tabStatus` | `List<Rx<TabStatus>>` | Per-tab validation status |
| `tabLocked` | `List<Rx<TabLocked>>` | Per-tab lock state |
| `uiControls` | `Map<String, UiControlDefinition>` | All form field definitions |
| `focusNodes` | `Map<String, FocusNode>` | Focus management |
| `allTabs` | `List<TabDefinitionData>` | Tab metadata (drives tab bar) |
| `screenSize` | `Rx<EScreenSize>` | Mobile / narrow / normal |
| `isFormDirty` | `RxBool` | Unsaved changes flag |
| `allFieldsAreValid` | `RxBool` | Overall validity |
| `sidebarTitle/Icon/Description` | `Rx<String?>/Rx<IconData?>` | Dynamic sidebar content |

### Enums

```dart
enum TabStatus   { unknown, isCompleteAndValid, isEmpty, isInvalid, isInProgress }
enum TabLocked   { unknown, tabLocked, tabUnlocked }
enum ControlValidity { unknown, validEmpty, invalidEmpty, invalid, valid }
enum UiControlType   { string, intValue, dropdown, imageUpload, pdfUpload,
                       invisible, checkbox, button }
enum EScreenSize { isMobileScreen, isNarrowScreen, isNormalScreen }

// Breakpoints (constants on TabUiController)
static const int MOBILE_SCREEN_WIDTH = 650;
static const int NARROW_SCREEN_WIDTH = 900;
```

### Methods to call in `onInit()`

```dart
initTabs(
  vsync: this,
  tabs: _buildTabDefinitions(),          // returns List<TabDefinitionData>
  tabKeyBuilder: (i) => MyTabType.values[i].key,
  onTabIndexChanging: checkUiControlValidationStates,
  tabIndexChangingUpdateIds: const ['tabIcons'],
);

initTabStateBundle(
  length: MyTabType.values.length,
  initiallyEmptyIndex: 0,
  initialLockState: TabLocked.tabUnlocked,
);
```

### Abstract methods (must implement)

```dart
void checkIfFormIsDirty();     // compare originalData vs editedData, set isFormDirty
void undoChanges();            // reset editedData, call undo() on all uiControls, update()
void populateTextControllers();// sync editedData fields → textControllers
Future<void> save(bool showDialog);
Future<void> close();
```

### Key utility methods

```dart
refreshTabStatuses()           // recomputes all tab statuses from uiControls validity
setSidebarData(key)            // updates sidebar from control or tab sidebarData
setScreenSize()                // call in constructor + debounced width listener
gotoTab(int index)
setAllTabLocks(TabLocked state)
```

---

## `TabDefinitionData` — Tab Metadata

```dart
TabDefinitionData(
  key: 'myTab',
  title: 'My Tab',
  tabIndex: 0,
  hasCustomTabStatusFunction: false,   // true = skip auto status calc for this tab
  showTabInSubmitSummary: true,
  isTabLockable: true,
  sidebarData: const SideBarData(
    'Tab Title',
    SomeIconPack.icon_name,
    'Description shown in sidebar when this tab is active.',
  ),
)
```

---

## `UiControlDefinition` — Field Registration

Control keys follow the convention: `'${tabKey}_${fieldEnum.name}'`

```dart
uiControls[fieldKey] = UiControlDefinition(
  controlType: UiControlType.string,       // or dropdown, checkbox, imageUpload, etc.
  tabIndex: 0,                             // which tab this control belongs to
  sidebarEntryKey: fieldKey,               // key that triggers this sidebar content
  sidebarExitKey: '${tabKey}_generic',     // key to fall back to tab-level sidebar
  sidebarData: const SideBarData(          // shown on focus enter
    'Field Title', SomeIcon.icon, 'Help text...',
  ),
  label: 'Display label',
  globalKey: GlobalKey<FormFieldState>(),
  editedFieldValue: editedData.value.someField,
  originalFieldValue: originalData.someField,
  textController: textControllers[fieldKey] = TextEditingController(),
  maxStringLength: 100,
  minStringLength: 3,
  maxLines: 1,
  allowEmpty: false,                       // true = optional field
  includeOverrideButton: false,            // true = lookthrough/override pattern
  lookthroughValue: null,                  // only when includeOverrideButton: true
  updateEditedValue: (String? value) {
    editedData.value = editedData.value.copyWith(someField: value!);
    uiControls[fieldKey]?.editedFieldValue = value;
  },
);
```

For **dropdown** controls, set `controlType: UiControlType.dropdown` and provide
`dropdownItems: Map<int, String>` plus an `onUndo` callback (dropdowns don't use
`textController`, they use `editedFieldValue` directly).

For **checkbox** controls, set `controlType: UiControlType.checkbox`.

---

## `SideBarData`

```dart
const SideBarData(title, icon, description)
// title: String, icon: IconData, description: String
```

---

## File Structure for a New Tabbed UI

Follow the same pattern as `kennel_page_new`:

```
portal/lib/admin_pages/<feature_name>/
  <feature>_controller.dart        ← extends TabUiController + GetSingleTickerProviderStateMixin
  <feature>_enums.dart             ← TabType enum + field enums per tab
  <feature>_ui.dart                ← GetView<Controller>, Scaffold, TabBarView
  pages/
    <tab_a>/
      controls.dart                ← part of '../../<feature>_controller.dart'
                                      extension <TabA>ControlsExtension on Controller
      layout.dart                  ← part of '../../<feature>_ui.dart'
                                      Widget _TabAContent(controller)
    <tab_b>/
      controls.dart
      layout.dart
    <feature>_widgets.dart         ← shared widgets, part of _ui.dart
```

---

## Controller `onInit()` Pattern

```dart
@override
void onInit() {
  super.onInit();
  _initializeTabs();
  _initializeTabStates();
  _initializeFormData();
  _initializeScreenSizeListener();
  _scheduleInitialValidation();
}

void _initializeTabs() {
  initTabs(
    vsync: this,
    tabs: _buildTabDefinitions(),
    tabKeyBuilder: (i) => MyTabType.values[i].key,
    onTabIndexChanging: checkUiControlValidationStates,
    tabIndexChangingUpdateIds: const ['tabIcons'],
  );
}

void _initializeTabStates() {
  initTabStateBundle(
    length: MyTabType.values.length,
    initiallyEmptyIndex: 0,
    initialLockState: TabLocked.tabUnlocked,
  );
}

void _initializeFormData() {
  editedData.value = originalData.copyWith();
  initMyTabAControls();     // each part file contributes one init method
  initMyTabBControls();
  populateTextControllers();
}

void _initializeScreenSizeListener() {
  _screenSizeDebouncer = debounce(width, (_) => setScreenSize(),
      time: const Duration(milliseconds: 50));
}

void _scheduleInitialValidation() {
  unawaited(Future<void>.delayed(const Duration(milliseconds: 100)).then((_) {
    checkUiControlValidationStates();
    update(['tabIcons']);
  }));
}
```

---

## UI Scaffold Pattern (`_ui.dart`)

```dart
class MyFeatureEditPage extends GetView<MyFeatureController> {
  const MyFeatureEditPage({required this.data, super.key});
  final MyModel data;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<MyFeatureController>()) {
      Get.put(MyFeatureController(data), permanent: true);
    }
    return GetBuilder<MyFeatureController>(
      id: 'myFeaturePageBuilder',
      builder: (_) => _MyFeatureScaffold(controller: controller),
    );
  }
}

class _MyFeatureScaffold extends StatelessWidget {
  const _MyFeatureScaffold({required this.controller});
  final MyFeatureController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: LayoutBuilder(builder: (context, constraints) {
        controller.updateSizeWithDebounce(constraints.maxWidth, constraints.maxHeight);
        return Scaffold(
          appBar: AppBar(
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: ResponsiveTabBar<MyFeatureController>(
                controller: controller,
                formKey: controller.formKey,
              ),
            ),
          ),
          body: TabBarView(
            controller: controller.tabController,
            children: [
              _TabAContent(controller),
              _TabBContent(controller),
            ],
          ),
        );
      }),
    );
  }
}
```

---

## Tab Layout Pattern (each `pages/<tab>/layout.dart`)

```dart
part of '../../<feature>_ui.dart';

class _TabAContent extends StatelessWidget {
  const _TabAContent(this.c);
  final MyFeatureController c;

  @override
  Widget build(BuildContext context) {
    return TabPageStandardLayout(
      formController: c,
      tabLocked: c.tabLocked[0],     // index matches tab
      title: MyTabType.tabA.title,
      icon: MyTabType.tabA.icon,
      description: MyTabType.tabA.description,
      child: Column(
        children: [
          // Use framework field widgets here:
          // EditableTextField, EditableDropdownField, etc.
        ],
      ),
    );
  }
}
```

---

## Existing Implementations (reference)

| Feature | Controller | Tabs | Notes |
|---------|-----------|------|-------|
| Edit Kennel | `kennel_page_new/kennel_page_new_controller.dart` | 8 | Has auto-save, songs, image upload |
| Edit Run | `run_edit_page/run_edit_page_controller.dart` | 7 | Has add/edit mode, location lookup |

---

## Key Conventions

- Control key format: `'${tabType.key}_${fieldEnum.name}'` — e.g. `'appearance_primaryColour'`
- `sidebarExitKey` is always `'${tabKey}_generic'` — falls back to tab-level sidebar when focus leaves a field
- `hasCustomTabStatusFunction: true` — use for tabs whose validity can't be computed purely from `uiControls` (e.g. list-based tabs like Songs)
- Dispose all `TextEditingController`s in `onClose()` — iterate `textControllers.values`
- `checkUiControlValidationStates()` is the public name used in `onTabIndexChanging` callbacks — it calls `refreshTabStatuses()` and `update(['tabIcons'])`
- `update(['kennelFormPageBuilder'])` (or your equivalent ID) forces a full rebuild of the page — call it in `undoChanges()` after resetting controllers
