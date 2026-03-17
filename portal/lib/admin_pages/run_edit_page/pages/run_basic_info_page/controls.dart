/// Basic Info Page Controls
///
/// This file defines the UI control configurations for the Basic Info tab.

part of '../../run_edit_page_controller.dart';

// ---------------------------------------------------------------------------
// Control Initialization Extension
// ---------------------------------------------------------------------------

/// Extension that adds basic info control initialization to the controller.
/// Key for the location lookup button control.
const String basicInfoLookupButtonKey = 'basicInfo_lookupButton';

extension BasicInfoControlsExtension on RunEditPageController {
  /// Initializes all UI controls for the Basic Info tab.
  void initBasicInfoControls() {
    final tabKey = RunTabType.basicInfo.key;
    const tabIndex = 0;

    _registerRunNameControl(tabKey, tabIndex);
    _registerRunStartDateControl(tabKey, tabIndex);
    _registerPlaceDescriptionControl(tabKey, tabIndex);
    _registerLookupButton(tabKey, tabIndex);
    _registerRunDescriptionControl(tabKey, tabIndex);
  }

  // ---------------------------------------------------------------------------
  // Individual Control Registration
  // ---------------------------------------------------------------------------

  /// Registers the run name control.
  void _registerRunNameControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunBasicInfoField.runName.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Run Name',
        MaterialCommunityIcons.format_title,
        'Enter a descriptive name for this run. This will be displayed in '
            'run listings and calendars.\n\n'
            'Good examples: "Red Dress Run 2024", "Annual Pub Crawl", '
            '"Monthly Full Moon Hash".',
      ),
      editedFieldValue: editedData.value.eventName,
      originalFieldValue: originalData.eventName,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Run name',
      maxStringLength: 200,
      minStringLength: 3,
      maxLines: 1,
      includeOverrideButton: false,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value.copyWith(eventName: value ?? '');
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  /// Registers the run start date control.
  void _registerRunStartDateControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunBasicInfoField.runStartDate.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Run Start Date & Time',
        FontAwesome5Solid.calendar_alt,
        'Set the date and time when this run will begin.\n\n'
            'Be sure to include both the date and the start time so '
            'hashers know when to arrive.',
      ),
      editedFieldValue: editedData.value.eventStartDatetime.toIso8601String(),
      originalFieldValue: originalData.eventStartDatetime.toIso8601String(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Run start date & time',
      tabIndex: tabIndex,
      updateEditedValue: (dynamic value) {
        if (value is DateTime) {
          editedData.value =
              editedData.value.copyWith(eventStartDatetime: value);
          uiControls[fieldKey]?.editedFieldValue = value.toIso8601String();
        }
      },
    );
  }

  /// Registers the place description control.
  void _registerPlaceDescriptionControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunBasicInfoField.placeDescription.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Place Description',
        FontAwesome5Solid.map_marker_alt,
        'Enter a brief description of the meeting place.\n\n'
            'This is typically the name of a pub, park, or landmark where '
            'hashers should gather before the run.',
      ),
      editedFieldValue: editedData.value.locationOneLineDesc,
      originalFieldValue: originalData.locationOneLineDesc,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Place description',
      maxStringLength: 500,
      minStringLength: 0,
      maxLines: 1,
      includeOverrideButton: false,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value =
            editedData.value.copyWith(locationOneLineDesc: value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  /// Registers the location lookup button control.
  void _registerLookupButton(String tabKey, int tabIndex) {
    uiControls[basicInfoLookupButtonKey] = UiControlDefinition(
      controlType: UiControlType.button,
      sidebarEntryKey: basicInfoLookupButtonKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Lookup Location',
        FontAwesome5Solid.map_marker_alt,
        'Search previous run locations and re-use one for this run.\n\n'
            'Opens a dialog showing all unique locations from past and future '
            'runs, with a map and type-ahead search. Selecting a location will '
            'populate the place description, address fields, and lat/lon.',
      ),
      editedFieldValue: null,
      originalFieldValue: null,
      globalKey: GlobalKey(),
      label: 'Lookup',
      tabIndex: tabIndex,
      updateEditedValue: (_) {},
      buttonIcon: FontAwesome5Solid.map_marker_alt,
    );
  }

  /// Registers the run description control.
  void _registerRunDescriptionControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunBasicInfoField.runDescription.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Run Description',
        MaterialCommunityIcons.text_box_outline,
        'Provide a detailed description of this run.\n\n'
            'Include relevant details like what to expect, special instructions, '
            'what to bring, and any other important information for attendees.',
      ),
      editedFieldValue: editedData.value.eventDescription,
      originalFieldValue: originalData.eventDescription,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Run description',
      maxStringLength: 5000,
      minStringLength: 0,
      maxLines: 10,
      includeOverrideButton: false,
      expandToFillSpace: true,
      minHeight: 300,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value =
            editedData.value.copyWith(eventDescription: value ?? '');
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }
}
