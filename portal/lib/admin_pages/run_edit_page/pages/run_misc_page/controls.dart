/// Misc Page Controls
///
/// This file defines the UI control configurations for the Misc tab.

part of '../../run_edit_page_controller.dart';

// ---------------------------------------------------------------------------
// Control Initialization Extension
// ---------------------------------------------------------------------------

/// Extension that adds misc control initialization to the controller.
extension MiscControlsExtension on RunEditPageController {
  /// Initializes all UI controls for the Misc tab.
  void initMiscControls() {
    final tabKey = RunTabType.misc.key;
    const tabIndex = 3;

    _registerIsVisibleControl(tabKey, tabIndex);
    _registerIsCountedControl(tabKey, tabIndex);
    _registerIsPromotedControl(tabKey, tabIndex);
    _registerGeographicScopeControl(tabKey, tabIndex);
    _registerAutoNumberControl(tabKey, tabIndex);
    _registerAbsoluteRunNumberControl(tabKey, tabIndex);
    _registerHaresControl(tabKey, tabIndex);
    _registerPublishOnHashrunsControl(tabKey, tabIndex);
    _registerRunAudienceControl(tabKey, tabIndex);
    _registerAllowWebLinkControl(tabKey, tabIndex);
    _registerRunAttendanceControl(tabKey, tabIndex);
  }

  // ---------------------------------------------------------------------------
  // Individual Control Registration
  // ---------------------------------------------------------------------------

  void _registerIsVisibleControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunMiscField.isVisible.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.checkbox,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Is Visible',
        FontAwesome5Solid.eye,
        'When enabled, this run will be visible to hashers.\n\n'
            'Disable this to hide the run from public view while you are '
            'still setting it up.',
      ),
      editedFieldValue: (editedData.value.isVisible != 0).toString(),
      originalFieldValue: (originalData.isVisible != 0).toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Is visible',
      tabIndex: tabIndex,
      updateEditedValue: (dynamic value) {
        if (value is bool) {
          editedData.value =
              editedData.value.copyWith(isVisible: value ? 1 : 0);
          uiControls[fieldKey]?.editedFieldValue = value.toString();
        }
      },
    );
  }

  void _registerIsCountedControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunMiscField.isCounted.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.checkbox,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Is Counted Run',
        FontAwesome5Solid.hashtag,
        'When enabled, this run counts towards hasher statistics.\n\n'
            'Disable this for special events that should not be counted.',
      ),
      editedFieldValue: (editedData.value.isCountedRun != 0).toString(),
      originalFieldValue: (originalData.isCountedRun != 0).toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Is counted run',
      tabIndex: tabIndex,
      updateEditedValue: (dynamic value) {
        if (value is bool) {
          editedData.value =
              editedData.value.copyWith(isCountedRun: value ? 1 : 0);
          uiControls[fieldKey]?.editedFieldValue = value.toString();
        }
      },
    );
  }

  void _registerIsPromotedControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunMiscField.isPromoted.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.checkbox,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Is Promoted Event',
        FontAwesome5Solid.star,
        'When enabled, this run is marked as a promoted/special event.\n\n'
            'Promoted events may be highlighted in listings.',
      ),
      editedFieldValue: (editedData.value.isPromotedEvent != 0).toString(),
      originalFieldValue: (originalData.isPromotedEvent != 0).toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Is promoted event',
      tabIndex: tabIndex,
      updateEditedValue: (dynamic value) {
        if (value is bool) {
          editedData.value =
              editedData.value.copyWith(isPromotedEvent: value ? 1 : 0);
          uiControls[fieldKey]?.editedFieldValue = value.toString();
        }
      },
    );
  }

  void _registerGeographicScopeControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunMiscField.geographicScope.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.dropdown,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Geographic Scope',
        FontAwesome5Solid.globe,
        'Select the geographic scope of this run.\n\n'
            'This helps categorize the event and may affect how it is '
            'displayed in listings.',
      ),
      editedFieldValue: editedData.value.eventGeographicScope.toString(),
      originalFieldValue: originalData.eventGeographicScope.toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Geographic scope',
      tabIndex: tabIndex,
      updateEditedValue: (dynamic value) {
        if (value is int) {
          editedData.value =
              editedData.value.copyWith(eventGeographicScope: value);
          uiControls[fieldKey]?.editedFieldValue = value.toString();
        }
      },
    );
  }

  void _registerAutoNumberControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunMiscField.autoNumber.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.checkbox,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Auto Number Run',
        MaterialCommunityIcons.numeric,
        'When enabled, the system will automatically assign a run number.\n\n'
            'Disable this to manually specify the run number.',
      ),
      editedFieldValue: autoNumberRuns.value.toString(),
      originalFieldValue: (originalData.absoluteEventNumber == null).toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Auto number run',
      tabIndex: tabIndex,
      updateEditedValue: (dynamic value) {
        if (value is bool) {
          autoNumberRuns.value = value;
          uiControls[fieldKey]?.editedFieldValue = value.toString();

          // When enabling auto-number, clear the manual run number
          // Setting to null in editedData; controller will send -1 to database
          if (value) {
            editedData.value =
                editedData.value.copyWith(absoluteEventNumber: null);
            final runNumberKey =
                '${tabKey}_${RunMiscField.absoluteRunNumber.name}';
            uiControls[runNumberKey]?.editedFieldValue = null;
            uiControls[runNumberKey]?.textController?.text = '';
          }
          checkIfFormIsDirty();
        }
      },
    );
  }

  void _registerAbsoluteRunNumberControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunMiscField.absoluteRunNumber.name}';

    // Determine if run number is overridden:
    // - absoluteEventNumber != null means it's overridden
    // - absoluteEventNumber == null means use auto-generated (eventNumber)
    final isOverridden = originalData.absoluteEventNumber != null;

    // The auto-generated run number (eventNumber) is always available as lookthrough
    final autoGeneratedNumber = originalData.eventNumber;

    // The override value (if any)
    final overrideValue = originalData.absoluteEventNumber?.toString();

    // Use contextual labels:
    // - New run (eventNumber == 0): number isn't known until save
    // - Existing run: show the current auto-generated number
    final lookthroughDisplay =
        autoGeneratedNumber == 0 ? '' : autoGeneratedNumber.toString();
    final lookthroughLabelText = autoGeneratedNumber == 0
        ? 'Run number auto-assigned on save'
        : 'Run number (auto)';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.intValue,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Run Number',
        FontAwesome5Solid.list_ol,
        'The run number for this event.\n\n'
            'By default, the run number is automatically assigned based on '
            'the run date when saved. Use the pencil icon to manually '
            'specify a different run number.',
      ),
      editedFieldValue: overrideValue,
      originalFieldValue: overrideValue,
      lookthroughValue: lookthroughDisplay,
      lookthroughLabel: lookthroughLabelText,
      isOverridden: isOverridden,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Run number',
      maxStringLength: 10,
      minStringLength: 0,
      maxLines: 1,
      includeOverrideButton: true,
      regex: r'^[1-9]\d*$',
      regexErrorString: 'Please enter a valid positive integer',
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        // Handle reset to lookthrough (auto-generated) value
        if (value == RESET_TO_LOOKTHROUGH_VALUE) {
          editedData.value =
              editedData.value.copyWith(absoluteEventNumber: null);
          uiControls[fieldKey]?.editedFieldValue = null;
          uiControls[fieldKey]?.isOverridden = false;
          autoNumberRuns.value = true;
          final autoNumberKey = '${tabKey}_${RunMiscField.autoNumber.name}';
          uiControls[autoNumberKey]?.editedFieldValue = 'true';
          checkIfFormIsDirty();
          return;
        }

        final num = int.tryParse(value ?? '');
        editedData.value = editedData.value.copyWith(absoluteEventNumber: num);
        uiControls[fieldKey]?.editedFieldValue = value;

        // Update the isOverridden flag based on whether a manual number is set
        uiControls[fieldKey]?.isOverridden = (num != null);

        // Update autoNumberRuns based on whether a manual number is set
        autoNumberRuns.value = (num == null);
        final autoNumberKey = '${tabKey}_${RunMiscField.autoNumber.name}';
        uiControls[autoNumberKey]?.editedFieldValue = (num == null).toString();

        checkIfFormIsDirty();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Publishing Controls
  // ---------------------------------------------------------------------------

  /// Converts a nullable-int-keyed map to a non-nullable-int-keyed map.
  static Map<int, String> _toNonNullableKeys(Map<int?, String> source) {
    return {
      for (final e in source.entries)
        if (e.key != null) e.key!: e.value
    };
  }

  void _registerPublishOnHashrunsControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunMiscField.publishOnHashruns.name}';
    final initialValue = editedData.value.evtDisseminateHashRunsDotOrg ?? -2;
    publishOnHashruns.value = initialValue;

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.dropdown,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Web Publishing',
        FontAwesome5Solid.globe_americas,
        'Controls whether this run is published on hashruns.org.\n\n'
            'Select "Use Kennel Setting" to inherit the default from your '
            'kennel configuration.',
      ),
      dropdownItems: _toNonNullableKeys(HASH_RUNS_DOT_ORG_SETTINGS),
      editedFieldValue: initialValue.toString(),
      originalFieldValue:
          (originalData.evtDisseminateHashRunsDotOrg ?? -2).toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Web publishing settings',
      tabIndex: tabIndex,
      onUndo: () {
        publishOnHashruns.value =
            originalData.evtDisseminateHashRunsDotOrg ?? -2;
      },
      updateEditedValue: (dynamic value) {
        final intVal = int.tryParse(value.toString()) ?? -2;
        publishOnHashruns.value = intVal;
        editedData.value = editedData.value.copyWith(
          evtDisseminateHashRunsDotOrg: intVal,
        );
        uiControls[fieldKey]?.editedFieldValue = intVal.toString();
      },
    );
  }

  void _registerRunAudienceControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunMiscField.runAudience.name}';
    final initialValue = editedData.value.evtDisseminationAudience ?? -2;
    runAudience.value = initialValue;

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.dropdown,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Run Audience',
        FontAwesome5Solid.users,
        'Controls who can see this run or event.\n\n'
            'Select "Use Kennel Setting" to inherit the default from your '
            'kennel configuration.',
      ),
      dropdownItems: _toNonNullableKeys(RUN_AUDIENCE),
      editedFieldValue: initialValue.toString(),
      originalFieldValue:
          (originalData.evtDisseminationAudience ?? -2).toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Who can see this run / event',
      tabIndex: tabIndex,
      onUndo: () {
        runAudience.value = originalData.evtDisseminationAudience ?? -2;
      },
      updateEditedValue: (dynamic value) {
        final intVal = int.tryParse(value.toString()) ?? -2;
        runAudience.value = intVal;
        editedData.value = editedData.value.copyWith(
          evtDisseminationAudience: intVal,
        );
        uiControls[fieldKey]?.editedFieldValue = intVal.toString();
      },
    );
  }

  void _registerAllowWebLinkControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunMiscField.allowWebLink.name}';
    final initialValue = editedData.value.evtDisseminateAllowWebLinks ?? 2;
    allowWebLink.value = initialValue;

    // YES_NO_INHERIT is Map<String, int> — convert to Map<int, String>
    final items = <int, String>{
      for (final e in YES_NO_INHERIT.entries) e.value: e.key,
    };

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.dropdown,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Allow Web Link',
        FontAwesome5Solid.link,
        'Controls whether this run can be shared by URL.\n\n'
            'Select "Use Kennel setting" to inherit the default from your '
            'kennel configuration.',
      ),
      dropdownItems: items,
      editedFieldValue: initialValue.toString(),
      originalFieldValue:
          (originalData.evtDisseminateAllowWebLinks ?? 2).toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Allow run to be shared by URL',
      tabIndex: tabIndex,
      onUndo: () {
        allowWebLink.value = originalData.evtDisseminateAllowWebLinks ?? 2;
      },
      updateEditedValue: (dynamic value) {
        final intVal = int.tryParse(value.toString()) ?? 2;
        allowWebLink.value = intVal;
        editedData.value = editedData.value.copyWith(
          evtDisseminateAllowWebLinks: intVal,
        );
        uiControls[fieldKey]?.editedFieldValue = intVal.toString();
      },
    );
  }

  void _registerRunAttendanceControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunMiscField.runAttendance.name}';
    final initialValue = editedData.value.canEditRunAttendence ?? -2;
    runAttendance.value = initialValue;

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.dropdown,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Edit Run Attendance',
        FontAwesome5Solid.users,
        'Controls who can edit attendance for this run after it has taken place.\n\n'
            'Select "Use Kennel Setting" to inherit the default from your '
            'kennel configuration.',
      ),
      dropdownItems: CAN_EDIT_RUN_ATTENDANCE_OPTIONS,
      editedFieldValue: initialValue.toString(),
      originalFieldValue: (originalData.canEditRunAttendence ?? -2).toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Can edit run attendance',
      tabIndex: tabIndex,
      onUndo: () {
        runAttendance.value = originalData.canEditRunAttendence ?? -2;
      },
      updateEditedValue: (dynamic value) {
        final intVal = int.tryParse(value.toString()) ?? -2;
        runAttendance.value = intVal;
        editedData.value = editedData.value.copyWith(
          canEditRunAttendence: intVal,
        );
        uiControls[fieldKey]?.editedFieldValue = intVal.toString();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Other Controls
  // ---------------------------------------------------------------------------

  void _registerHaresControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunMiscField.hares.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Hares',
        FontAwesome5Solid.running,
        'Enter the names of the hares for this run.\n\n'
            'Separate multiple names with commas.',
      ),
      editedFieldValue: editedData.value.hares,
      originalFieldValue: originalData.hares,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Hares',
      maxStringLength: 500,
      minStringLength: 0,
      maxLines: 1,
      includeOverrideButton: false,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value.copyWith(hares: value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }
}
