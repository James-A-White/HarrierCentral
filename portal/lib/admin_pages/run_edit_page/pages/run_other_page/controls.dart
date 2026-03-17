/// Other Page Controls
///
/// This file defines the UI control configurations for the Other tab.

part of '../../run_edit_page_controller.dart';

// ---------------------------------------------------------------------------
// Control Initialization Extension
// ---------------------------------------------------------------------------

/// Extension that adds other tab control initialization to the controller.
extension OtherControlsExtension on RunEditPageController {
  /// Initializes all UI controls for the Other tab.
  void initOtherControls() {
    final tabKey = RunTabType.other.key;
    const tabIndex = 5;

    _registerRunEndDateControl(tabKey, tabIndex);
    _registerLimitParticipationControl(tabKey, tabIndex);
    _registerMinimumParticipationControl(tabKey, tabIndex);
    _registerMaximumParticipationControl(tabKey, tabIndex);
    _registerCountrySelectControl(tabKey, tabIndex);
  }

  // ---------------------------------------------------------------------------
  // Individual Control Registration
  // ---------------------------------------------------------------------------

  void _registerRunEndDateControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunOtherField.runEndDate.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Run End Date & Time',
        FontAwesome5Solid.calendar_check,
        'Set the date and time when this run is expected to end.\n\n'
            'This is optional but helpful for hashers planning their day.',
      ),
      editedFieldValue: editedData.value.eventEndDatetime?.toIso8601String(),
      originalFieldValue: originalData.eventEndDatetime?.toIso8601String(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Run end date & time',
      tabIndex: tabIndex,
      updateEditedValue: (dynamic value) {
        if (value is DateTime?) {
          editedData.value = editedData.value.copyWith(eventEndDatetime: value);
          uiControls[fieldKey]?.editedFieldValue = value?.toIso8601String();
        }
      },
    );
  }

  void _registerLimitParticipationControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunOtherField.limitParticipation.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.checkbox,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Limit Participation',
        FontAwesome5Solid.users,
        'Enable this to set minimum and maximum participant limits.\n\n'
            'Useful for runs with limited capacity or minimum attendance '
            'requirements.',
      ),
      editedFieldValue: limitParticipation.value.toString(),
      originalFieldValue: ((originalData.maximumParticipantsAllowed != null) ||
              (originalData.minimumParticipantsRequired != null))
          .toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Limit participation',
      tabIndex: tabIndex,
      updateEditedValue: (dynamic value) {
        if (value is bool) {
          limitParticipation.value = value;
          uiControls[fieldKey]?.editedFieldValue = value.toString();
        }
      },
    );
  }

  void _registerMinimumParticipationControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunOtherField.minimumParticipation.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.intValue,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Minimum Participants',
        FontAwesome5Solid.user_minus,
        'Set the minimum number of hashers required for this run.\n\n'
            'The run may be cancelled if this minimum is not reached.',
      ),
      editedFieldValue:
          editedData.value.minimumParticipantsRequired?.toString(),
      originalFieldValue: originalData.minimumParticipantsRequired?.toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Minimum participants',
      maxStringLength: 5,
      minStringLength: 0,
      maxLines: 1,
      includeOverrideButton: false,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        final num = int.tryParse(value ?? '');
        editedData.value =
            editedData.value.copyWith(minimumParticipantsRequired: num);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  void _registerMaximumParticipationControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunOtherField.maximumParticipation.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.intValue,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Maximum Participants',
        FontAwesome5Solid.user_plus,
        'Set the maximum number of hashers allowed for this run.\n\n'
            'Registration may be closed when this limit is reached.',
      ),
      editedFieldValue: editedData.value.maximumParticipantsAllowed?.toString(),
      originalFieldValue: originalData.maximumParticipantsAllowed?.toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Maximum participants',
      maxStringLength: 5,
      minStringLength: 0,
      maxLines: 1,
      includeOverrideButton: false,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        final num = int.tryParse(value ?? '');
        editedData.value =
            editedData.value.copyWith(maximumParticipantsAllowed: num);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  void _registerCountrySelectControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunOtherField.country.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.dropdown,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Country',
        FontAwesome5Solid.flag,
        'Select the country for statistics purposes.\n\n'
            'This helps categorize the run in regional statistics.',
      ),
      editedFieldValue: country.value,
      originalFieldValue: originalData.countryName,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Country (for statistics)',
      tabIndex: tabIndex,
      updateEditedValue: (dynamic value) {
        if (value is String?) {
          country.value = value;
          uiControls[fieldKey]?.editedFieldValue = value;
        }
      },
    );
  }
}
